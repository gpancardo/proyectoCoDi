import { randomUUID } from 'node:crypto';
import { MINUTOS, pagoConfirmado, verificarFirma } from './pedidos.js';

const MOCK = process.env.PEY_MOCK === '1'; // sin API key: cobros falsos; para pagar, marca el intento con el webhook de prueba
const PNG_1X1 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
const quitarAcentos = (t) => t.normalize('NFD').replace(/[^\x20-\x7e]/g, '').slice(0, 40);

async function pey(ruta, body) { // con body: POST; sin body: GET
  if (MOCK) {
    const id = `mock-${randomUUID()}`;
    return ruta === '/codi/qr' ? { id, qrImage: PNG_1X1 } : ruta === '/payment-link/create' ? { id, url: 'https://pey.mx' } : { transactionId: id };
  }
  const r = await fetch(`https://api.pey.mx${ruta}`, {
    method: body ? 'POST' : 'GET',
    headers: { Authorization: `Bearer ${process.env.PEY_API_KEY}`, ...(body && { 'Content-Type': 'application/json' }) },
    body: body && JSON.stringify(body), signal: AbortSignal.timeout(20_000),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(`pey ${ruta}: ${j.error?.type ?? r.status}`);
  return j;
}

// Mismas rutas de consulta que usaba el bot: push, link y QR.
const rutaConsulta = (via, ref) => ({ link: `/payment-link/${ref}`, qr: `/transaction/codi/qr/${ref}` }[via] ?? `/transaction/${ref}`);

// Marca pagado el intento y la orden. Ambas transiciones condicionadas: reintentos y carreras no cambian nada.
export async function confirmarPago(db, intento, rastreo) {
  const [ganado] = await db.actualizar('intentos_cobro', `id=eq.${intento.id}&estado=eq.vigente`, { estado: 'pagado', rastreo });
  if (!ganado) return false;
  const ahora = new Date().toISOString();
  const [orden] = await db.actualizar('ordenes', `id=eq.${intento.orden_id}&estado=eq.cobrada`, { estado: 'pagada', pagada_en: ahora, actualizado: ahora, rastreo });
  if (orden) {
    const [n] = await db.get('negocios', `id=eq.${orden.negocio_id}&select=categoria`);
    await db.evento({ p_comprador_id: orden.comprador_id, p_tipo: 'order', p_categoria: n?.categoria ?? null, p_consulta: null, p_negocio_id: orden.negocio_id }).catch(() => {});
  }
  return true;
}

// Crea el cobro. La restricción parcial de la base reserva el único intento vigente ANTES de llamar a pey.
export async function iniciarCobro(db, orden, comprador, negocio, clave = randomUUID()) {
  const vence = new Date(Date.now() + MINUTOS.cobro * 60_000).toISOString();
  await db.actualizar('intentos_cobro', `orden_id=eq.${orden.id}&estado=eq.vigente&vence=lt.${encodeURIComponent(new Date().toISOString())}`, { estado: 'vencido' });
  let intento;
  try {
    [intento] = await db.insertar('intentos_cobro', { orden_id: orden.id, monto_minor: Math.round(orden.monto * 100), vence, idempotency_key: clave });
  } catch (e) {
    if (e.status === 409) { // misma clave o ya hay uno vigente: devolver el existente
      const [actual] = await db.get('intentos_cobro', `orden_id=eq.${orden.id}&order=id.desc&limit=1`);
      return { intento: actual, repetido: true };
    }
    throw e;
  }
  const base = {
    amount: intento.monto_minor / 100, concept: quitarAcentos(`${negocio.nombre} pedido ${orden.id}`), numRef: String(orden.id % 1e7),
    expiration: MINUTOS.cobro * 60, metadata: { orden_id: orden.id, intento_id: intento.id },
    ...(negocio.pey_bank_account_id && { bankAccountId: negocio.pey_bank_account_id }),
  };
  const retorno = process.env.APP_RETURN_URL ?? 'https://barrio.app';
  const vias = [
    ...(comprador.telefono ? [async () => ({ via: 'push', ref: (await pey('/codi/pn', { ...base, phoneNumber: comprador.telefono })).transactionId })] : []),
    async () => { const l = await pey('/payment-link/create', { amount: base.amount, successUrl: retorno, backUrl: retorno, clientReferenceId: String(orden.id), metadata: base.metadata }); return { via: 'link', ref: l.id, url: l.url }; },
    async () => { const q = await pey('/codi/qr', { ...base, generateImage: true }); if (!q.qrImage) throw new Error('sin imagen de QR'); return { via: 'qr', ref: q.id, qr_image: q.qrImage }; },
  ];
  for (const via of vias) {
    try {
      const { via: v, ref, ...extra } = await via();
      const [guardado] = await db.actualizar('intentos_cobro', `id=eq.${intento.id}&estado=eq.vigente`, { via: v, pey_ref: ref, instrucciones: { link: extra.url ?? null, qr_image: extra.qr_image ?? null } });
      // aceptada o vencida → cobrada; si otra petición ya lo movió, no se toca
      await db.actualizar('ordenes', `id=eq.${orden.id}&estado=in.(aceptada,vencida)`, { estado: 'cobrada', actualizado: new Date().toISOString() });
      return { intento: guardado, ...extra };
    } catch (e) { console.error('cobro', orden.id, e.message); }
  }
  await db.actualizar('intentos_cobro', `id=eq.${intento.id}`, { estado: 'fallido' }); // libera el cupo del intento vigente
  return { intento: null, error: 'No pudimos mandarte el cobro. Intenta otra vez.' };
}

// Webhook de pey: firma → dedupe por webhook-id → referencia → monto → transición condicionada.
export async function recibirWebhook(db, secreto, cuerpo, headers) {
  if (!verificarFirma(secreto, cuerpo, headers)) return [401, 'firma inválida'];
  const ev = JSON.parse(cuerpo);
  if (!String(ev.type).endsWith('.payment_received')) return [200, 'ignorado'];
  try { await db.insertar('eventos_webhook', { id: headers['webhook-id'] }); } catch (e) { return e.status === 409 ? [200, 'repetido'] : [500, 'error de base']; }
  const refs = [ev.transactionId, ev.codiQrId, ev.id].filter(Boolean).map(encodeURIComponent);
  const intentoId = Number(ev.metadata?.externalMetadata?.intento_id ?? ev.metadata?.intento_id);
  let [intento] = refs.length ? await db.get('intentos_cobro', `pey_ref=in.(${refs.join(',')})&limit=1`) : [];
  if (!intento && Number.isInteger(intentoId)) [intento] = await db.get('intentos_cobro', `id=eq.${intentoId}&limit=1`);
  if (!intento) { await db.request(`/rest/v1/eventos_webhook?id=eq.${encodeURIComponent(headers['webhook-id'])}`, { method: 'DELETE' }); return [404, 'intento no encontrado']; } // pey reintenta con la referencia ya guardada
  if (Math.round(Number(ev.amount) * 100) < intento.monto_minor) { console.error('monto incompleto', intento.id); return [200, 'monto incompleto']; }
  if (intento.estado === 'vencido') { await db.actualizar('intentos_cobro', `id=eq.${intento.id}&estado=eq.vencido`, { estado: 'revision', rastreo: ev.metadata?.trackingKey ?? null }); return [200, 'revisión']; }
  await confirmarPago(db, intento, ev.metadata?.trackingKey ?? null);
  return [200, 'ok'];
}

// Reconciliación puntual: pregunta a pey por UN intento vigente (la app la dispara al consultar el cobro; no depende de cron).
export async function reconciliar(db, intento) {
  if (intento?.estado !== 'vigente' || !intento.pey_ref) return false;
  try {
    const pago = pagoConfirmado(intento.via, await pey(rutaConsulta(intento.via, intento.pey_ref)), intento.monto_minor);
    return pago ? await confirmarPago(db, intento, pago.rastreo) : false;
  } catch (e) { console.error('consulta a pey', intento.id, e.message); return false; }
}

// Barrido periódico: reconcilia con pey, vence cobros, cancela pedidos sin respuesta y libera cupones.
export async function barrido(db) {
  const ahora = new Date(); const iso = (min = 0) => encodeURIComponent(new Date(ahora - min * 60_000).toISOString());
  for (const i of await db.get('intentos_cobro', 'estado=eq.vigente&pey_ref=not.is.null&limit=200')) {
    try {
      const pago = pagoConfirmado(i.via, await pey(rutaConsulta(i.via, i.pey_ref)), i.monto_minor);
      if (pago) await confirmarPago(db, i, pago.rastreo);
    } catch (e) { console.error('consulta a pey', i.id, e.message); }
  }
  for (const i of await db.actualizar('intentos_cobro', `estado=eq.vigente&vence=lt.${iso()}`, { estado: 'vencido' })) {
    await db.actualizar('ordenes', `id=eq.${i.orden_id}&estado=eq.cobrada`, { estado: 'vencida', actualizado: ahora.toISOString() });
  }
  const sinResponder = await db.actualizar('ordenes', `estado=eq.pendiente&creado=lt.${iso(MINUTOS.negocioSinResponder)}`, { estado: 'expirada', actualizado: ahora.toISOString() });
  await Promise.all(sinResponder.map((o) => liberarCupon(db, o)));
  await db.request('/rest/v1/rpc/limpiar_efimeros', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
}

// Un pedido que no se cobra devuelve el cupón a "aceptado" para el siguiente intento.
export const liberarCupon = (db, orden) => orden.canje_id ? db.actualizar('cupon_canjes', `id=eq.${orden.canje_id}&estado=eq.usado`, { estado: 'aceptado', actualizado: new Date().toISOString() }) : null;
