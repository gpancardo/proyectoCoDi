// Prueba de punta a punta contra Supabase REAL (pey en mock). Escribe y borra datos de prueba en el negocio indicado.
// Uso: E2E_CONFIRM=1 E2E_NEGOCIO_ID=7 npm run e2e:live   (requiere backend/.env y el negocio demo del seed)
import { readFileSync } from 'node:fs';
import { createHmac } from 'node:crypto';
import assert from 'node:assert/strict';
for (const l of readFileSync(new URL('../.env', import.meta.url), 'utf8').split('\n')) { const m = l.match(/^([A-Z_]+)=(.*)$/); if (m) process.env[m[1]] = m[2]; }
process.env.PEY_MOCK = '1'; // el cobro real ya se probó; aquí no se vuelve a cobrar
if (process.env.E2E_CONFIRM !== '1') { console.error('Escribe en la base real. Repite con E2E_CONFIRM=1.'); process.exit(1); }
const B = new URL('../src/', import.meta.url).href;
const { Supabase } = await import(B + 'supabase.js'); const { manejar, Fallo } = await import(B + 'rutas.js'); const { recibirWebhook } = await import(B + 'pagos.js');
const db = new Supabase({ url: process.env.SUPABASE_URL, serviceKey: process.env.SUPABASE_SERVICE_ROLE_KEY, anonKey: process.env.SUPABASE_ANON_KEY });
const NEG_ID = Number(process.env.E2E_NEGOCIO_ID ?? 7); const ids = { ordenes: [], cupones: [] };
const [negocio] = await db.get('negocios', `id=eq.${NEG_ID}&select=id,nombre`);
// El comprador demo cobra por push a este celular (el de quien prueba); telefono ya no es único.
const TEL_DEMO = process.env.E2E_PHONE ?? '5615156164';
let [comprador] = await db.get('compradores', 'nombre=eq.E2E prueba&select=id,nombre,telefono');
if (!comprador) [comprador] = await db.insertar('compradores', { nombre: 'E2E prueba', telefono: TEL_DEMO });
else if (comprador.telefono !== TEL_DEMO) await db.actualizar('compradores', `id=eq.${comprador.id}`, { telefono: TEL_DEMO });
const llamar = async (auth, method, path, body, headers = {}) => {
  let out; const res = {}; const req = { method, headers: { ...headers } };
  try { const ok = await manejar({ db, req, res, url: new URL('http://x/api/v1' + path), auth, cuerpo: async () => body ?? {}, enviar: (_r, status, b) => { out = { status, ...b }; } }); assert.ok(ok, 'ruta ' + path); }
  catch (e) { if (e instanceof Fallo) out = { status: e.status, error: e.code }; else throw e; }
  return out;
};
const buyer = { comprador }; const biz = { negocio };
const firma = (id, cuerpo) => { const ts = Math.floor(Date.now() / 1000); const sec = process.env.PEY_WEBHOOK_SECRET; return { 'webhook-id': id, 'webhook-timestamp': String(ts), 'webhook-signature': 'v1,' + createHmac('sha256', Buffer.from(sec.replace(/^whsec_/, ''), 'base64')).update(`${id}.${ts}.${cuerpo}`).digest('base64') }; };
const pasos = [];
const ok = (n) => { pasos.push('✔ ' + n); };
try {
  // 1. cotizar y pedir
  const q1 = await llamar(buyer, 'POST', '/orders/quotes', { business_id: NEG_ID, items: [{ nombre: 'Taco de prueba', cantidad: 1 }] });
  assert.equal(q1.status, 201); assert.equal(q1.data.total_minor, 1); ok('cotización $0.01 desde el catálogo');
  assert.equal((await llamar(buyer, 'POST', '/orders', { quote_id: q1.data.quote_id, confirmed_total_minor: 999 }, { 'idempotency-key': 'e2e-key-0001' })).error, 'NOT_CONFIRMED'); ok('rechaza total no confirmado');
  const o1 = await llamar(buyer, 'POST', '/orders', { quote_id: q1.data.quote_id, confirmed_total_minor: 1 }, { 'idempotency-key': 'e2e-key-0001' });
  assert.equal(o1.status, 201); assert.equal(o1.data.estado, 'pendiente'); ids.ordenes.push(o1.data.id); ok('pedido creado (pendiente)');
  const rep = await llamar(buyer, 'POST', '/orders', { quote_id: q1.data.quote_id, confirmed_total_minor: 1 }, { 'idempotency-key': 'e2e-key-0001' });
  assert.equal(rep.data.id, o1.data.id); ok('Idempotency-Key devuelve el mismo pedido');
  // 2. negocio acepta → cobro
  assert.equal((await llamar(buyer, 'POST', `/orders/${o1.data.id}/accept`)).status, 403); ok('el comprador no puede aceptar');
  const ac = await llamar(biz, 'POST', `/orders/${o1.data.id}/accept`); assert.equal(ac.data.estado, 'cobrada'); ok('negocio acepta → cobro creado (cobrada)');
  assert.equal((await llamar(biz, 'POST', `/orders/${o1.data.id}/accept`)).error, 'INVALID_STATE'); ok('doble aceptación bloqueada');
  const pay = await llamar(buyer, 'POST', `/orders/${o1.data.id}/payments`); assert.equal(pay.status, 200); ok('segundo cobro vigente no se crea');
  const [intento] = await db.get('intentos_cobro', `orden_id=eq.${o1.data.id}&order=id.desc&limit=1`); assert.equal(intento.estado, 'vigente');
  // 3. webhook
  const ev = JSON.stringify({ type: 'codi.pn.payment_received', transactionId: intento.pey_ref, amount: 0.01, metadata: { trackingKey: 'E2E-RASTREO' } });
  assert.equal((await recibirWebhook(db, process.env.PEY_WEBHOOK_SECRET, ev, { ...firma('e2e-evt-1', ev), 'webhook-signature': 'v1,AAAA' }))[0], 401); ok('firma inválida → 401');
  const bajo = JSON.stringify({ ...JSON.parse(ev), amount: 0.001 }); const h0 = firma('e2e-evt-0', bajo);
  assert.equal((await recibirWebhook(db, process.env.PEY_WEBHOOK_SECRET, bajo, h0))[1], 'monto incompleto'); ok('monto insuficiente no confirma');
  const h1 = firma('e2e-evt-1', ev); assert.deepEqual(await recibirWebhook(db, process.env.PEY_WEBHOOK_SECRET, ev, h1), [200, 'ok']);
  assert.deepEqual(await recibirWebhook(db, process.env.PEY_WEBHOOK_SECRET, ev, h1), [200, 'repetido']); ok('webhook firmado confirma y es idempotente');
  const [pagada] = await db.get('ordenes', `id=eq.${o1.data.id}`); assert.equal(pagada.estado, 'pagada'); assert.ok(pagada.pagada_en); ok('pedido pagado');
  const det = await llamar(buyer, 'GET', `/orders/${o1.data.id}`); assert.match(det.data.codigo, /^[0-9]{4}$/); assert.equal((await llamar(biz, 'GET', `/orders/${o1.data.id}`)).data.codigo, undefined); ok('código de recogida solo para el comprador');
  assert.equal((await llamar(biz, 'POST', `/orders/${o1.data.id}/ready`)).data.estado, 'lista'); ok('negocio marca listo');
  // 4. cupón → aviso → aceptar → autoaplicado
  const cu = await llamar(biz, 'POST', '/business/coupons', { title: 'E2E 10% de regreso', type: 'porcentaje', value: 10, expires_at: new Date(Date.now() + 864e5).toISOString() });
  assert.equal(cu.status, 201); assert.ok(cu.data.notificados >= 1); ids.cupones.push(cu.data.id); ok(`cupón publicado y avisado a ${cu.data.notificados} cliente(s)`);
  const nots = await llamar(buyer, 'GET', '/me/notifications'); assert.ok(nots.data.some((n) => n.cupon_id === cu.data.id)); ok('aviso en notificaciones');
  const qSin = await llamar(buyer, 'POST', '/orders/quotes', { business_id: NEG_ID, items: [{ nombre: 'Taco de canasta', cantidad: 2 }] }); assert.equal(qSin.data.descuento_minor, 0); ok('sin aceptar, no hay descuento');
  assert.equal((await llamar(buyer, 'POST', `/coupons/${cu.data.id}/accept`)).data.estado, 'aceptado');
  const q2 = await llamar(buyer, 'POST', '/orders/quotes', { business_id: NEG_ID, items: [{ nombre: 'Taco de canasta', cantidad: 2 }] }); assert.equal(q2.data.descuento_minor, 240); assert.equal(q2.data.total_minor, 2160); ok('cupón aceptado se autoaplica ($24 − 10% = $21.60)');
  const o2 = await llamar(buyer, 'POST', '/orders', { quote_id: q2.data.quote_id, confirmed_total_minor: 2160 }, { 'idempotency-key': 'e2e-key-0002' }); assert.equal(o2.status, 201); ids.ordenes.push(o2.data.id);
  const q3 = await llamar(buyer, 'POST', '/orders/quotes', { business_id: NEG_ID, items: [{ nombre: 'Taco de canasta', cantidad: 2 }] }); assert.equal(q3.data.descuento_minor, 0); ok('cupón usado no se reaplica');
  assert.equal((await llamar(buyer, 'POST', `/orders/${o2.data.id}/cancel`)).data.estado, 'cancelada');
  const q4 = await llamar(buyer, 'POST', '/orders/quotes', { business_id: NEG_ID, items: [{ nombre: 'Taco de canasta', cantidad: 2 }] }); assert.equal(q4.data.descuento_minor, 240); ok('cancelar devuelve el cupón');
  // 5. perfil con insignias
  const pf = await llamar(buyer, 'GET', '/me/profile'); assert.equal(pf.status, 200); assert.ok(pf.data.insignias.length >= 1); ok(`perfil: ${pf.data.pedidos_pagados} pagado(s), ${pf.data.insignias.length} insignia(s) en progreso`);
  // 6. autorización por objeto
  const otro = { comprador: { id: -1 } }; assert.equal((await llamar(otro, 'GET', `/orders/${o1.data.id}`)).status, 404); ok('pedido ajeno no se revela');
  // 7. barrido SQL (RPC real)
  await db.request('/rest/v1/rpc/barrido_sql', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }); ok('barrido_sql() ejecuta');
} catch (e) { console.log(pasos.join('\n')); console.error('✘ FALLÓ:', e.message, e.stack?.split('\n')[1]); process.exitCode = 1; }
finally {
  const inList = (a) => `in.(${a.join(',')})`;
  if (ids.ordenes.length) {
    for (const t of ['intentos_cobro']) await db.request(`/rest/v1/${t}?orden_id=${inList(ids.ordenes)}`, { method: 'DELETE' });
    await db.request(`/rest/v1/ordenes?id=${inList(ids.ordenes)}`, { method: 'DELETE' });
  }
  await db.request(`/rest/v1/cotizaciones?comprador_id=eq.${comprador.id}`, { method: 'DELETE' });
  if (ids.cupones.length) for (const t of ['notificaciones', 'cupon_canjes']) await db.request(`/rest/v1/${t}?cupon_id=${inList(ids.cupones)}`, { method: 'DELETE' });
  if (ids.cupones.length) await db.request(`/rest/v1/cupones?id=${inList(ids.cupones)}`, { method: 'DELETE' });
  await db.request(`/rest/v1/eventos_webhook?id=like.e2e-evt-*`, { method: 'DELETE' });
  await db.request(`/rest/v1/eventos_descubrimiento?comprador_id=eq.${comprador.id}`, { method: 'DELETE' });
  await db.request(`/rest/v1/perfiles_descubrimiento?comprador_id=eq.${comprador.id}`, { method: 'DELETE' });
  await db.request(`/rest/v1/compradores?id=eq.${comprador.id}`, { method: 'DELETE' });
  if (!process.exitCode) console.log(pasos.join('\n') + '\n(datos de prueba borrados)');
}
