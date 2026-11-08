import { createServer } from 'node:http';
import { Supabase } from './supabase.js';
import { buscarDeterminista, buscarHibrido, seccionesDescubrimiento } from './search.js';
import { indexarPendientes } from './indexar.js';
import { manejar, Fallo } from './rutas.js';
import { barrido, recibirWebhook } from './pagos.js';
import { combinarFiltros, embeddingConsulta, explicarCandidatos, interpretarConsulta } from './agent.js';

const env = process.env;
const port = Number(env.PORT ?? 3000);
const db = env.SUPABASE_URL && env.SUPABASE_SERVICE_ROLE_KEY && env.SUPABASE_ANON_KEY
  ? new Supabase({ url: env.SUPABASE_URL, serviceKey: env.SUPABASE_SERVICE_ROLE_KEY, anonKey: env.SUPABASE_ANON_KEY }) : null;

// Auth por cabecera Bearer (sin cookies): '*' es seguro; ALLOWED_ORIGINS=https://a.com,https://b.com lo restringe.
const origenes = (env.ALLOWED_ORIGINS ?? '*').split(',').map((o) => o.trim());
const cors = (req) => ({ 'Access-Control-Allow-Origin': origenes.includes('*') ? '*' : (origenes.includes(req?.headers?.origin) ? req.headers.origin : origenes[0]), 'Vary': 'Origin', 'Access-Control-Allow-Headers': 'authorization, content-type, idempotency-key, apikey', 'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS', 'Access-Control-Max-Age': '86400' });
const enviar = (res, status, body) => { res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', ...(res.cors ?? {}) }); res.end(JSON.stringify(body)); };
const fallo = (res, status, code, message, field) => enviar(res, status, { error: { code, message, ...(field ? { field } : {}) } });
async function cuerpo(req) { let raw = ''; for await (const parte of req) { raw += parte; if (raw.length > 30_000) throw new Error('Cuerpo demasiado grande'); } return raw ? JSON.parse(raw) : {}; }
function filtros(url) { return Object.fromEntries(url.searchParams.entries()); }
async function persona(req) {
  const header = req.headers.authorization;
  if (!db || !header?.startsWith('Bearer ')) return null;
  const session = await db.sesion(header.slice(7));
  if (!session?.id) return null;
  const [comprador, negocio] = await Promise.all([db.get('compradores', `sujeto_auth=eq.${session.id}&select=id,nombre,telefono,zona,colonia&limit=1`), db.get('negocios', `sujeto_auth=eq.${session.id}&select=id,nombre,descripcion,zona,colonia,direccion,categoria,productos,auto_aceptar,abierto,verificado&limit=1`)]);
  return { session, comprador: comprador[0] ?? null, negocio: negocio[0] ?? null };
}
async function contexto(req) {
  if (!db) throw new Error('API sin configurar');
  const auth = await persona(req);
  return { negocios: await db.negocios(), auth, perfil: auth?.comprador ? await db.perfil(auth.comprador.id) : null };
}

const manejarPeticion = async (req, res) => {
  let m;
  try {
    res.cors = cors(req);
    if (req.method === 'OPTIONS') { res.writeHead(204, res.cors); return res.end(); }
    const url = new URL(req.url, `http://${req.headers.host}`);
    if (req.method === 'GET' && url.pathname === '/health') return enviar(res, 200, { ok: true });
    if (req.method === 'GET' && url.pathname === '/api/v1/discovery') {
      const { negocios, perfil } = await contexto(req);
      return enviar(res, 200, { data: seccionesDescubrimiento(negocios, perfil) });
    }
    if (req.method === 'GET' && url.pathname === '/api/v1/catalog/search') {
      const { negocios, perfil } = await contexto(req);
      const matches = buscarDeterminista(negocios, filtros(url), perfil);
      return enviar(res, 200, { data: matches.map(({ negocio, score, match_reasons }) => ({ ...negocio, score, match_reasons })), meta: { mode: 'deterministic' } });
    }
    if (req.method === 'POST' && url.pathname === '/api/v1/search/agent') {
      const entrada = await cuerpo(req); const { negocios, perfil } = await contexto(req);
      const consulta = String(entrada.query ?? '').slice(0, 200);
      const modelo = env.OPENAI_MODEL ?? 'gpt-4o-mini'; const modeloEmb = env.OPENAI_EMBEDDING_MODEL ?? 'text-embedding-3-small';
      let interpretacion = null;
      let similitudes = new Map();
      try { interpretacion = await interpretarConsulta({ apiKey: env.OPENAI_API_KEY, model: modelo, query: consulta }); } catch { /* el fallback es parte del contrato */ }
      try {
        await indexarPendientes(db, { apiKey: env.OPENAI_API_KEY, model: modeloEmb, limite: 3 }).catch(() => {}); // catálogo cambiado → vector al día
        const embedding = await embeddingConsulta({ apiKey: env.OPENAI_API_KEY, model: modeloEmb, query: consulta });
        if (embedding) similitudes = new Map((await db.documentos(embedding)).map((d) => [Number(d.negocio_id), Number(d.similitud)]));
      } catch { /* sin vectores: solo reglas exactas */ }
      const search = combinarFiltros(entrada.filters ?? {}, interpretacion);
      let matches = buscarHibrido(negocios, search, perfil, similitudes, entrada.filters ?? {}).slice(0, 12);
      let explicacion = null;
      if (interpretacion && similitudes.size) {
        try { explicacion = await explicarCandidatos({ apiKey: env.OPENAI_API_KEY, model: modelo, query: consulta, candidatos: matches }); } catch { /* el orden híbrido permanece */ }
      }
      if (explicacion?.business_ids.length) {
        const posiciones = new Map(explicacion.business_ids.map((id, i) => [Number(id), i]));
        matches = [...matches].sort((a, b) => (posiciones.get(Number(a.negocio.id)) ?? 99) - (posiciones.get(Number(b.negocio.id)) ?? 99));
      }
      const modo = interpretacion && similitudes.size ? 'agent_rag' : interpretacion ? 'agent' : similitudes.size ? 'rag' : 'deterministic_fallback';
      return enviar(res, 200, { data: matches.map(({ negocio, score, match_reasons }) => ({ ...negocio, score, match_reasons })), meta: { mode: modo, retrieved: similitudes.size, filters: search, answer: explicacion?.answer ?? interpretacion?.answer ?? 'Te muestro coincidencias del catálogo disponible.' } });
    }
    if (req.method === 'POST' && url.pathname === '/api/v1/discovery/events') {
      const auth = await persona(req); if (!auth?.comprador) return fallo(res, 401, 'UNAUTHENTICATED', 'Inicia sesión para guardar tus preferencias.');
      const entrada = await cuerpo(req);
      const permitidos = ['search', 'view', 'save', 'order'];
      if (!permitidos.includes(entrada.type)) return fallo(res, 422, 'INVALID_EVENT', 'Ese evento no está permitido.', 'type');
      await db.evento({ p_comprador_id: auth.comprador.id, p_tipo: entrada.type, p_categoria: entrada.category ?? null, p_consulta: String(entrada.query ?? '').slice(0, 160) || null, p_negocio_id: Number.isInteger(entrada.business_id) ? entrada.business_id : null });
      return enviar(res, 202, { data: { accepted: true } });
    }
    if (req.method === 'POST' && url.pathname === '/webhooks/pey') { // cuerpo crudo: la firma se calcula sobre él
      let raw = ''; for await (const parte of req) { raw += parte; if (raw.length > 100_000) { res.writeHead(413); return res.end(); } }
      if (!db || !env.PEY_WEBHOOK_SECRET) { res.writeHead(500); return res.end('webhook sin configurar'); }
      const [status, texto] = await recibirWebhook(db, env.PEY_WEBHOOK_SECRET, raw, req.headers);
      res.writeHead(status); return res.end(texto);
    }
    if (req.method === 'POST' && url.pathname === '/internal/sweep') { // respaldo de cron externo
      if (!env.CRON_SECRET || req.headers.authorization !== `Bearer ${env.CRON_SECRET}`) return fallo(res, 401, 'UNAUTHENTICATED', 'No autorizado.');
      await barrido(db); return enviar(res, 200, { data: { ok: true } });
    }
    if (url.pathname.startsWith('/api/v1/') && db && await manejar({ db, req, res, url, auth: await persona(req), cuerpo: () => cuerpo(req), enviar })) return;
    return fallo(res, 404, 'NOT_FOUND', 'No encontramos esa ruta.');
  } catch (error) {
    if (error instanceof Fallo) return fallo(res, error.status, error.code, error.message, error.field);
    if (error instanceof SyntaxError) return fallo(res, 400, 'INVALID_JSON', 'El cuerpo debe ser JSON válido.');
    if (/demasiado grande/.test(error.message)) return fallo(res, 413, 'PAYLOAD_TOO_LARGE', error.message);
    if (/rango de precio|amount_minor/.test(error.message)) return fallo(res, 422, 'INVALID_FILTER', error.message);
    console.error(error.message);
    return fallo(res, 503, 'SERVICE_UNAVAILABLE', 'No pudimos buscar en este momento.');
  }
};
const app = createServer(manejarPeticion);

if (process.env.NODE_ENV !== 'test' && typeof Deno === 'undefined') { // en Edge Functions (Deno) arranca edge/api.js
  app.listen(port, () => console.log(`Barrio API lista en :${port}`));
  // ponytail: barrido en el mismo proceso cada minuto; con varias instancias moverlo a un cron único (/internal/sweep)
  if (db) setInterval(() => barrido(db).catch((e) => console.error('barrido', e.message)), 60_000).unref();
}
export { app, manejarPeticion };
