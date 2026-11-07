import { calcularInsignias, cotizar, mejorCupon, MINUTOS, puede } from './pedidos.js';
import { iniciarCobro, liberarCupon } from './pagos.js';

class Fallo extends Error { constructor(status, code, message, field) { super(message); Object.assign(this, { status, code, field }); } }
const q = encodeURIComponent;
const exigir = (cond, status, code, message, field) => { if (!cond) throw new Fallo(status, code, message, field); };
const ahoraIso = () => new Date().toISOString();
const publica = (o, esComprador) => ({ id: o.id, negocio_id: o.negocio_id, estado: o.estado, items: o.items, total_minor: Math.round(o.monto * 100), descuento_minor: o.descuento_minor, notas: o.notas, creado: o.creado,
  ...(esComprador && ['pagada', 'lista'].includes(o.estado) ? { codigo: o.codigo } : {}) });

// Transición atómica: solo cambia si el estado previo sigue siendo el esperado.
async function mover(db, orden, a, extra = {}) {
  exigir(puede(orden.estado, a), 409, 'INVALID_STATE', 'Ese pedido ya no puede cambiar así.');
  const [nueva] = await db.actualizar('ordenes', `id=eq.${orden.id}&estado=eq.${orden.estado}`, { estado: a, actualizado: ahoraIso(), ...extra });
  exigir(nueva, 409, 'INVALID_STATE', 'El pedido cambió. Revísalo de nuevo.');
  return nueva;
}
async function pedidoDe(db, id, auth) {
  exigir(Number.isInteger(id), 404, 'NOT_FOUND', 'No encontramos ese pedido.');
  const [o] = await db.get('ordenes', `id=eq.${id}&limit=1`);
  const suyo = o && ((auth.comprador && o.comprador_id === auth.comprador.id) || (auth.negocio && o.negocio_id === auth.negocio.id));
  exigir(suyo, 404, 'NOT_FOUND', 'No encontramos ese pedido.'); // no revela pedidos ajenos
  return { o, esComprador: auth.comprador?.id === o.comprador_id };
}
async function cobrarPedido(db, o) {
  const [[comprador], [negocio]] = await Promise.all([db.get('compradores', `id=eq.${o.comprador_id}&select=id,telefono`), db.get('negocios', `id=eq.${o.negocio_id}&select=id,nombre,pey_bank_account_id`)]);
  return iniciarCobro(db, o, comprador, negocio, `orden-${o.id}-${Date.now()}`);
}

// Devuelve true si atendió la ruta. `auth` = { comprador?, negocio? } o null.
export async function manejar({ db, req, res, url, auth, cuerpo, enviar }) {
  const m = req.method; const ruta = url.pathname.replace('/api/v1', '');
  const comp = () => { exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.'); exigir(auth.comprador, 403, 'FORBIDDEN', 'Esta acción es para compradores.'); return auth.comprador; };
  const neg = () => { exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.'); exigir(auth.negocio, 403, 'FORBIDDEN', 'Esta acción es para negocios.'); return auth.negocio; };
  const ok = (status, data) => { enviar(res, status, { data }); return true; };
  let p;

  if (m === 'POST' && ruta === '/me') { // alta/actualización del comprador de esta sesión
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const b = await cuerpo();
    exigir(!b.telefono || /^[0-9]{10}$/.test(b.telefono), 422, 'INVALID_PHONE', 'Escribe 10 dígitos.', 'telefono');
    const [c] = await db.crearComprador({ sujeto_auth: auth.session.id, telefono: b.telefono ?? null, nombre: b.nombre ? String(b.nombre).slice(0, 80) : null, zona: b.zona ?? null });
    return ok(200, { id: c.id, nombre: c.nombre, zona: c.zona });
  }
  if (m === 'GET' && ruta === '/me/profile') { // insignias: avance y premios obtenidos
    const c = comp();
    const pagados = await db.get('ordenes', `comprador_id=eq.${c.id}&estado=in.(pagada,lista)&select=negocio_id`);
    const ids = [...new Set(pagados.map((o) => o.negocio_id))];
    const negocios = ids.length ? await db.get('negocios', `id=in.(${ids.join(',')})&select=id,nombre,colonia,zona`) : [];
    const porId = new Map(negocios.map((n) => [n.id, n]));
    const insignias = calcularInsignias(pagados.map((o) => { const n = porId.get(o.negocio_id) ?? {}; return { negocio_id: o.negocio_id, negocio_nombre: n.nombre, colonia: n.colonia, zona: n.zona }; }));
    return ok(200, { nombre: c.nombre, pedidos_pagados: pagados.length, insignias });
  }
  if (m === 'GET' && ruta === '/me/notifications') {
    const c = comp();
    const filas = await db.get('notificaciones', `comprador_id=eq.${c.id}&order=creado.desc&limit=50&select=id,tipo,titulo,cupon_id,leida,creado`);
    return ok(200, filas);
  }
  if (m === 'POST' && (p = ruta.match(/^\/coupons\/(\d+)\/(accept|decline)$/))) {
    const c = comp();
    const [canje] = await db.actualizar('cupon_canjes', `cupon_id=eq.${p[1]}&comprador_id=eq.${c.id}&estado=eq.ofrecido`, { estado: p[2] === 'accept' ? 'aceptado' : 'rechazado', actualizado: ahoraIso() });
    exigir(canje, 409, 'COUPON_UNAVAILABLE', 'Ese cupón ya no está disponible.');
    await db.actualizar('notificaciones', `comprador_id=eq.${c.id}&cupon_id=eq.${p[1]}`, { leida: true });
    return ok(200, { estado: canje.estado });
  }

  // ----- compra -----
  if (m === 'POST' && ruta === '/orders/quotes') {
    const c = comp(); const b = await cuerpo();
    const [n] = await db.get('negocios', `id=eq.${q(Number(b.business_id))}&verificado=eq.true&abierto=eq.true&select=id,nombre,productos&limit=1`);
    exigir(n, 422, 'BUSINESS_UNAVAILABLE', 'Este negocio no recibe pedidos ahora.', 'business_id');
    const r = cotizar(n.productos, b.items);
    exigir(!r.error, 422, 'INVALID_ITEMS', r.error, 'items');
    // cupones aceptados por esta persona para este negocio, autoaplicados al total
    const canjes = await db.get('cupon_canjes', `comprador_id=eq.${c.id}&estado=eq.aceptado&select=id,cupones!inner(id,negocio_id,tipo,valor,min_compra_minor,vence,activo,titulo)&cupones.negocio_id=eq.${n.id}`);
    const mejor = mejorCupon(canjes.map((x) => ({ ...x.cupones, canje_id: x.id })), r.subtotal_minor);
    const descuento_minor = mejor?.descuento_minor ?? 0;
    const [cot] = await db.insertar('cotizaciones', { comprador_id: c.id, negocio_id: n.id, items: r.items, subtotal_minor: r.subtotal_minor, descuento_minor, total_minor: r.subtotal_minor - descuento_minor, canje_id: mejor?.cupon.canje_id ?? null, expira: new Date(Date.now() + MINUTOS.cotizacion * 60_000).toISOString() });
    return ok(201, { quote_id: cot.id, business: { id: n.id, nombre: n.nombre }, items: cot.items, subtotal_minor: cot.subtotal_minor, descuento_minor, coupon: mejor ? { titulo: mejor.cupon.titulo } : null, total_minor: cot.total_minor, expires_at: cot.expira });
  }
  if (m === 'POST' && ruta === '/orders') {
    const c = comp(); const b = await cuerpo();
    const clave = req.headers['idempotency-key'];
    exigir(clave && clave.length >= 8 && clave.length <= 80, 400, 'IDEMPOTENCY_KEY_REQUIRED', 'Falta Idempotency-Key.');
    const [previa] = await db.get('ordenes', `comprador_id=eq.${c.id}&idempotency_key=eq.${q(clave)}&limit=1`);
    if (previa) return ok(200, publica(previa, true));
    const [cot] = await db.get('cotizaciones', `id=eq.${q(String(b.quote_id))}&comprador_id=eq.${c.id}&limit=1`);
    exigir(cot, 404, 'QUOTE_NOT_FOUND', 'No encontramos esa cotización.', 'quote_id');
    exigir(new Date(cot.expira) > new Date(), 409, 'QUOTE_EXPIRED', 'La cuenta venció. Vuelve a pedirla.');
    exigir(b.confirmed_total_minor === cot.total_minor, 422, 'NOT_CONFIRMED', 'Confirma el total que viste.', 'confirmed_total_minor');
    const [n] = await db.get('negocios', `id=eq.${cot.negocio_id}&verificado=eq.true&abierto=eq.true&select=id,auto_aceptar&limit=1`);
    exigir(n, 409, 'BUSINESS_UNAVAILABLE', 'Este negocio ya no recibe pedidos.');
    if (cot.canje_id) { // el cupón se reserva con la misma regla de estado previo
      const [canje] = await db.actualizar('cupon_canjes', `id=eq.${cot.canje_id}&estado=eq.aceptado`, { estado: 'usado', actualizado: ahoraIso() });
      exigir(canje, 409, 'COUPON_UNAVAILABLE', 'El cupón ya se usó. Pide la cuenta otra vez.');
    }
    let o;
    try {
      [o] = await db.insertar('ordenes', { comprador_id: c.id, negocio_id: cot.negocio_id, items: cot.items, notas: b.notes ? String(b.notes).slice(0, 300) : null, monto: cot.total_minor / 100, descuento_minor: cot.descuento_minor, canje_id: cot.canje_id, cotizacion_id: cot.id, idempotency_key: clave });
    } catch (e) {
      if (cot.canje_id) await db.actualizar('cupon_canjes', `id=eq.${cot.canje_id}&estado=eq.usado`, { estado: 'aceptado', actualizado: ahoraIso() });
      exigir(e.status !== 409, 409, 'QUOTE_USED', 'Esa cuenta ya se pidió.');
      throw e;
    }
    if (n.auto_aceptar) { o = await mover(db, o, 'aceptada'); await cobrarPedido(db, o); [o] = await db.get('ordenes', `id=eq.${o.id}`); }
    return ok(201, publica(o, true));
  }
  if (m === 'GET' && ruta === '/orders') { // mis pedidos (comprador) o pedidos del negocio
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const quien = auth.negocio ? `negocio_id=eq.${auth.negocio.id}` : `comprador_id=eq.${comp().id}`;
    const estado = url.searchParams.get('status');
    const filas = await db.get('ordenes', `${quien}${estado ? `&estado=eq.${q(estado)}` : ''}&order=id.desc&limit=50`);
    return ok(200, filas.map((o) => publica(o, !auth.negocio)));
  }
  if (m === 'GET' && (p = ruta.match(/^\/orders\/(\d+)$/))) {
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const { o, esComprador } = await pedidoDe(db, Number(p[1]), auth);
    return ok(200, publica(o, esComprador));
  }
  if (m === 'POST' && (p = ruta.match(/^\/orders\/(\d+)\/(cancel|accept|reject|ready|payments)$/))) {
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const { o, esComprador } = await pedidoDe(db, Number(p[1]), auth);
    const accion = p[2];
    if (accion === 'cancel') { // solo el comprador, antes de pagar
      exigir(esComprador, 403, 'FORBIDDEN', 'Solo quien pidió puede cancelar.');
      exigir(['pendiente', 'aceptada', 'vencida'].includes(o.estado), 409, 'INVALID_STATE', 'Ese pedido ya no se puede cancelar.');
      const nueva = await mover(db, o, 'cancelada'); await liberarCupon(db, nueva);
      return ok(200, publica(nueva, true));
    }
    if (accion === 'payments') { // nuevo intento: solo si el anterior venció (o aún no hay uno)
      exigir(esComprador, 403, 'FORBIDDEN', 'Solo quien pidió puede pagar.');
      exigir(['aceptada', 'vencida', 'cobrada'].includes(o.estado), 409, 'INVALID_STATE', 'Ese pedido no está listo para cobrar.');
      const r = await cobrarPedido(db, o);
      exigir(r.intento, 503, 'PAYMENT_UNAVAILABLE', r.error);
      const i = r.intento; return ok(r.repetido ? 200 : 201, { payment_id: i.id, via: i.via, estado: i.estado, vence: i.vence, link: r.url ?? null, qr_image: r.qr_image ?? null, amount_minor: i.monto_minor });
    }
    exigir(!esComprador, 403, 'FORBIDDEN', 'Solo el negocio del pedido puede hacer esto.');
    if (accion === 'accept') { const nueva = await mover(db, o, 'aceptada'); await cobrarPedido(db, nueva); return ok(200, publica((await db.get('ordenes', `id=eq.${o.id}`))[0], false)); }
    if (accion === 'reject') { const nueva = await mover(db, o, 'rechazada'); await liberarCupon(db, nueva); return ok(200, publica(nueva, false)); }
    return ok(200, publica(await mover(db, o, 'lista'), false)); // ready
  }
  if (m === 'GET' && (p = ruta.match(/^\/orders\/(\d+)\/payments\/current$/))) {
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const { o } = await pedidoDe(db, Number(p[1]), auth);
    const [i] = await db.get('intentos_cobro', `orden_id=eq.${o.id}&order=id.desc&limit=1&select=id,via,estado,vence,monto_minor`);
    exigir(i, 404, 'NOT_FOUND', 'Todavía no hay cobro.');
    return ok(200, i);
  }

  // ----- promociones del negocio -----
  if (ruta === '/business/coupons' && m === 'GET') {
    const n = neg();
    return ok(200, await db.get('cupones', `negocio_id=eq.${n.id}&order=id.desc&limit=50`));
  }
  if (ruta === '/business/coupons' && m === 'POST') {
    const n = neg(); const b = await cuerpo();
    const valor = Number(b.value); const min = Number(b.min_amount_minor ?? 0); const vence = new Date(b.expires_at);
    exigir(['porcentaje', 'monto'].includes(b.type), 422, 'INVALID_COUPON', 'Elige porcentaje o monto.', 'type');
    exigir(Number.isInteger(valor) && valor > 0 && (b.type === 'monto' || valor <= 100), 422, 'INVALID_COUPON', 'El valor no es válido.', 'value');
    exigir(Number.isInteger(min) && min >= 0, 422, 'INVALID_COUPON', 'La compra mínima no es válida.', 'min_amount_minor');
    exigir(vence > new Date(), 422, 'INVALID_COUPON', 'La fecha debe ser futura.', 'expires_at');
    exigir(typeof b.title === 'string' && b.title.trim().length >= 3 && b.title.length <= 80, 422, 'INVALID_COUPON', 'Escribe un título corto.', 'title');
    const [cupon] = await db.insertar('cupones', { negocio_id: n.id, titulo: b.title.trim(), tipo: b.type, valor, min_compra_minor: min, vence: vence.toISOString() });
    // avisa solo a quienes ya compraron aquí (pedido pagado)
    const clientes = [...new Set((await db.get('ordenes', `negocio_id=eq.${n.id}&estado=in.(pagada,lista)&select=comprador_id`)).map((o) => o.comprador_id))];
    if (clientes.length) {
      await db.insertar('cupon_canjes', clientes.map((comprador_id) => ({ cupon_id: cupon.id, comprador_id })));
      await db.insertar('notificaciones', clientes.map((comprador_id) => ({ comprador_id, tipo: 'cupon', titulo: `${n.nombre}: ${cupon.titulo}`, cupon_id: cupon.id })));
    }
    return ok(201, { ...cupon, notificados: clientes.length });
  }
  if (m === 'DELETE' && (p = ruta.match(/^\/business\/coupons\/(\d+)$/))) {
    const n = neg();
    const [c] = await db.actualizar('cupones', `id=eq.${p[1]}&negocio_id=eq.${n.id}`, { activo: false });
    exigir(c, 404, 'NOT_FOUND', 'No encontramos ese cupón.');
    return ok(200, c);
  }
  return false;
}

export { Fallo };
