// Recibe codi.pn.payment_received / codi.qr.payment_received de pey y marca la orden como pagada.
// Deploy: supabase functions deploy pey-webhook   (verify_jwt = false está en supabase/config.toml)
// Secrets: PEY_WEBHOOK_SECRET=whsec_...  (Supabase inyecta SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY)
import { Webhook } from "npm:standardwebhooks@1.1.1";
import { createClient } from "npm:@supabase/supabase-js@2.119.0";

const responder = (status: number, texto: string) => new Response(texto, { status });

// Se crean al primer pago, no al arrancar: si falta el secreto, la función sigue arriba y avisa claro en el log.
let cliente: { wh: Webhook; db: ReturnType<typeof createClient> } | null = null;
function conectar() {
  if (cliente) return cliente;
  const secreto = Deno.env.get("PEY_WEBHOOK_SECRET");
  const url = Deno.env.get("SUPABASE_URL");
  const llave = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!secreto || !url || !llave) {
    console.error("Falta configuración:", { PEY_WEBHOOK_SECRET: !!secreto, SUPABASE_URL: !!url, SUPABASE_SERVICE_ROLE_KEY: !!llave });
    return null;
  }
  cliente = { wh: new Webhook(secreto), db: createClient(url, llave) };
  return cliente;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return responder(405, "solo POST");
  const c = conectar();
  if (!c) return responder(500, "webhook sin configurar"); // pey reintenta cuando ya esté el secreto
  const { wh, db } = c;

  const body = await req.text(); // la firma se calcula sobre el body crudo
  let ev: any;
  try {
    ev = wh.verify(body, Object.fromEntries(req.headers));
  } catch {
    return responder(401, "firma inválida");
  }
  if (!String(ev.type).endsWith(".payment_received")) return responder(200, "ignorado");

  // Por referencia de pey; si el pago llegó antes de que el bot guardara la referencia, por el id que mandamos en metadata.
  const refs = [ev.transactionId, ev.codiQrId].filter(Boolean);
  let { data: orden } = refs.length
    ? await db.from("ordenes").select("id, monto, estado").in("pey_ref", refs).maybeSingle()
    : { data: null };
  const ordenId = Number(ev.metadata?.externalMetadata?.orden_id ?? ev.metadata?.orden_id);
  if (!orden && Number.isInteger(ordenId)) {
    ({ data: orden } = await db.from("ordenes").select("id, monto, estado").eq("id", ordenId).maybeSingle());
  }
  if (!orden) {
    console.error("pago sin orden", body);
    return responder(404, "orden no encontrada"); // pey reintenta; para entonces la referencia ya estará guardada
  }
  if (Number(ev.amount) < Number(orden.monto)) {
    console.error("monto incompleto", orden.id, ev.amount, orden.monto);
    return responder(200, "monto incompleto"); // 200: reintentar no cambia el monto; queda en el log para revisión
  }

  const ahora = new Date().toISOString();
  // Idempotente: solo desde estados con cobro; reintentos de pey no cambian nada.
  const { error } = await db.from("ordenes")
    .update({ estado: "pagada", pagada_en: ahora, actualizado: ahora, rastreo: ev.metadata?.trackingKey ?? null })
    .eq("id", orden.id).in("estado", ["aceptada", "cobrada", "vencida"]);
  if (error) return responder(500, "error de base"); // pey reintenta
  return responder(200, "ok");
});
