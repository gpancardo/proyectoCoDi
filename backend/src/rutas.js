import { calcularCiudad, calcularInsignias, cotizar, cuponesPorOfrecer, mejorCupon, MINUTOS, puede, resumenNegocio, SELLO_PUBLICO } from './pedidos.js';
import { iniciarCobro, liberarCupon, reconciliar } from './pagos.js';
import { ZONAS, normalizar } from './text.js';

class Fallo extends Error { constructor(status, code, message, field) { super(message); Object.assign(this, { status, code, field }); } }
const q = encodeURIComponent;
const exigir = (cond, status, code, message, field) => { if (!cond) throw new Fallo(status, code, message, field); };
const ahoraIso = () => new Date().toISOString();
const publica = (o, esComprador) => ({ id: o.id, negocio_id: o.negocio_id, estado: o.estado, items: o.items, total_minor: Math.round(o.monto * 100), descuento_minor: o.descuento_minor, notas: o.notas, creado: o.creado,
  ...(esComprador && ['pagada', 'lista', 'entregada'].includes(o.estado) ? { codigo: o.codigo } : {}) });

// Transición atómica: solo cambia si el estado previo sigue siendo el esperado.
async function mover(db, orden, a, extra = {}) {
  exigir(puede(orden.estado, a), 409, 'INVALID_STATE', 'Ese pedido ya no puede cambiar así.');
  const [nueva] = await db.actualizar('ordenes', `id=eq.${orden.id}&estado=eq.${orden.estado}`, { estado: a, actualizado: ahoraIso(), ...extra });
  exigir(nueva, 409, 'INVALID_STATE', 'El pedido cambió. Revísalo de nuevo.');
  return nueva;
}
// Demo: Doña Lupe (negocio semilla, sin dueño) acepta sola, 15 s después, los pedidos que traen el taco de prueba, para probar el cobro a mano.
// ponytail: espera en memoria (waitUntil en Edge); si la función se recicla antes, el pedido queda pendiente y vence. Mejora: columna aceptar_en + barrido.
const ESPERA_DEMO_MS = 15_000;
export const esPruebaDemo = (n, o) => String(n.semilla ?? '').startsWith('demo-seed') && o.items?.some((i) => i.nombre === 'Taco de prueba');
function aceptarDespues(db, id) {
  const tarea = new Promise((r) => setTimeout(r, ESPERA_DEMO_MS)).then(async () => {
    const [o] = await db.get('ordenes', `id=eq.${id}&estado=eq.pendiente&limit=1`); // si ya la cancelaron, no se toca
    if (o) await cobrarPedido(db, await mover(db, o, 'aceptada'));
  }).catch((e) => console.error('auto-aceptar demo:', e.message));
  globalThis.EdgeRuntime?.waitUntil(tarea);
}
async function pedidoDe(db, id, auth) {
  exigir(Number.isInteger(id), 404, 'NOT_FOUND', 'No encontramos ese pedido.');
  const [o] = await db.get('ordenes', `id=eq.${id}&limit=1`);
  const suyo = o && ((auth.comprador && o.comprador_id === auth.comprador.id) || (auth.negocio && o.negocio_id === auth.negocio.id));
  exigir(suyo, 404, 'NOT_FOUND', 'No encontramos ese pedido.'); // no revela pedidos ajenos
  return { o, esComprador: auth.comprador?.id === o.comprador_id, esNegocio: auth.negocio?.id === o.negocio_id }; // una misma cuenta puede ser ambos
}
async function cobrarPedido(db, o) {
  const [[comprador], [negocio]] = await Promise.all([db.get('compradores', `id=eq.${o.comprador_id}&select=id,telefono`), db.get('negocios', `id=eq.${o.negocio_id}&select=id,nombre,pey_bank_account_id`)]);
  return iniciarCobro(db, o, comprador, negocio, `orden-${o.id}-${Date.now()}`);
}

// Ubicación opcional: ambas coordenadas o ninguna.
function coords(b) {
  if (b.latitude == null && b.longitude == null) return {};
  const [lat, lng] = [Number(b.latitude), Number(b.longitude)];
  exigir(Math.abs(lat) <= 90 && Math.abs(lng) <= 180, 422, 'INVALID_LOCATION', 'La ubicación no es válida.', 'latitude');
  return { latitud: lat, longitud: lng };
}

function productosValidos(p) {
  exigir(Array.isArray(p) && p.length >= 1 && p.length <= 60, 422, 'INVALID_PRODUCTS', 'Agrega de 1 a 60 productos.', 'productos');
  return p.map((x) => {
    const nombre = String(x?.nombre ?? '').trim(); const precio = Number(x?.precio);
    exigir(nombre.length >= 1 && nombre.length <= 60 && precio > 0 && precio <= 100000, 422, 'INVALID_PRODUCTS', 'Cada producto necesita nombre y un precio mayor a 0.', 'productos');
    return { nombre, precio: Math.round(precio * 100) / 100 };
  });
}
const sinSecretos = 'id,nombre,descripcion,imagen_url,zona,colonia,direccion,latitud,longitud,categoria,productos,abierto,verificado';
const cuerpoInvalido = (e) => { if (e.status === 409) throw new Fallo(409, 'BUSINESS_EXISTS', 'Ese celular o esta cuenta ya tiene un negocio.'); if (e.status === 400) throw new Fallo(422, 'INVALID_BUSINESS', 'Revisa los datos del negocio.'); throw e; };

// Devuelve true si atendió la ruta. `auth` = { comprador?, negocio? } o null.
export async function manejar({ db, req, res, url, auth, cuerpo, enviar }) {
  const m = req.method; const ruta = url.pathname.replace('/api/v1', '');
  const comp = () => { exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.'); exigir(auth.comprador, 403, 'FORBIDDEN', 'Esta acción es para compradores.'); return auth.comprador; };
  const neg = () => { exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.'); exigir(auth.negocio, 403, 'FORBIDDEN', 'Esta acción es para negocios.'); return auth.negocio; };
  const ok = (status, data) => { enviar(res, status, { data }); return true; };
  let p;

  if (m === 'GET' && (p = ruta.match(/^\/businesses\/(\d+)$/))) { // perfil público: sin teléfono ni datos de cobro
    const [n] = await db.get('negocios', `id=eq.${p[1]}&verificado=eq.true&select=${sinSecretos}&limit=1`);
    exigir(n, 404, 'NOT_FOUND', 'No encontramos ese negocio.');
    return ok(200, n);
  }
  if (m === 'GET' && ruta === '/me') {
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    return ok(200, { comprador: auth.comprador, negocio: auth.negocio });
  }
  if (m === 'POST' && ruta === '/businesses') { // alta de negocio de esta sesión; queda activo
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const b = await cuerpo(); const tel = String(b.telefono ?? '').replace(/\D/g, '');
    exigir(String(b.nombre ?? '').trim().length >= 2, 422, 'INVALID_BUSINESS', 'Escribe el nombre de tu negocio.', 'nombre');
    exigir(tel.length === 10, 422, 'INVALID_PHONE', 'Tu celular debe tener 10 números, sin +52.', 'telefono');
    exigir(ZONAS.includes(b.zona), 422, 'INVALID_BUSINESS', 'Elige tu alcaldía.', 'zona');
    exigir(String(b.direccion ?? '').trim().length >= 5, 422, 'INVALID_BUSINESS', 'Escribe la dirección donde te recogen.', 'direccion');
    exigir(String(b.categoria ?? '').trim().length >= 2, 422, 'INVALID_BUSINESS', 'Dinos qué tipo de negocio es.', 'categoria');
    const productos = productosValidos(b.productos);
    try {
      const [n] = await db.insertar('negocios', { nombre: b.nombre.trim().slice(0, 60), telefono: tel, zona: b.zona, colonia: b.colonia ? String(b.colonia).trim().slice(0, 80) : null, direccion: b.direccion.trim().slice(0, 200),
        categoria: b.categoria.trim().slice(0, 60), descripcion: b.descripcion ? String(b.descripcion).trim().slice(0, 300) : null, productos, auto_aceptar: !!b.auto_aceptar, sujeto_auth: auth.session.id, verificado: true }); // sin verificación manual: la cuenta con dueño activa el negocio
      return ok(201, { id: n.id, nombre: n.nombre, verificado: n.verificado });
    } catch (e) { cuerpoInvalido(e); }
  }
  if (m === 'PATCH' && ruta === '/business') { // abrir/cerrar, aceptar en automático, menú y descripción
    const n = neg(); const b = await cuerpo(); const cambios = {};
    if ('abierto' in b) cambios.abierto = !!b.abierto;
    if ('auto_aceptar' in b) cambios.auto_aceptar = !!b.auto_aceptar;
    if ('descripcion' in b) cambios.descripcion = b.descripcion ? String(b.descripcion).trim().slice(0, 300) : null;
    if ('productos' in b) cambios.productos = productosValidos(b.productos);
    exigir(Object.keys(cambios).length, 422, 'NOTHING_TO_UPDATE', 'No hay cambios.');
    try { const [nuevo] = await db.actualizar('negocios', `id=eq.${n.id}`, cambios); return ok(200, nuevo); } catch (e) { cuerpoInvalido(e); }
  }
  if (m === 'POST' && ruta === '/me') { // alta/actualización del comprador de esta sesión
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const b = await cuerpo();
    exigir(!b.telefono || /^[0-9]{10}$/.test(b.telefono), 422, 'INVALID_PHONE', 'Escribe 10 dígitos.', 'telefono');
    const [c] = await db.crearComprador({ sujeto_auth: auth.session.id, telefono: b.telefono ?? null, nombre: b.nombre ? String(b.nombre).slice(0, 80) : null, zona: b.zona ?? null, colonia: b.colonia ? String(b.colonia).slice(0, 80) : null, ...coords(b) });
    return ok(200, { id: c.id, nombre: c.nombre, zona: c.zona, colonia: c.colonia });
  }
  if (m === 'GET' && ruta === '/me/profile') { // insignias: avance y premios obtenidos
    const c = comp();
    const pagados = await db.get('ordenes', `comprador_id=eq.${c.id}&estado=in.(pagada,lista,entregada)&select=negocio_id&order=id.asc`);
    const ids = [...new Set(pagados.map((o) => o.negocio_id))];
    const negocios = ids.length ? await db.get('negocios', `id=in.(${ids.join(',')})&select=id,nombre,colonia,categoria,zona`) : [];
    const porId = new Map(negocios.map((n) => [n.id, n]));
    const insignias = calcularInsignias(pagados.map((o) => { const n = porId.get(o.negocio_id) ?? {}; return { negocio_id: o.negocio_id, negocio_nombre: n.nombre, colonia: n.colonia, categoria: n.categoria }; }));
    // premio del sello de primera compra: la promoción sin código del negocio donde compró
    let premio = null;
    if (pagados.length) {
      const id = pagados[0].negocio_id;
      const [cupon] = await db.get('cupones', `negocio_id=eq.${id}&activo=eq.true&codigo=is.null&vence=gt.${q(ahoraIso())}&order=id.asc&limit=1&select=id,titulo,min_compra_minor`);
      const usado = cupon && (await db.get('cupon_canjes', `cupon_id=eq.${cupon.id}&comprador_id=eq.${c.id}&estado=eq.usado&select=id&limit=1`)).length;
      if (cupon && !usado) premio = { negocio_id: id, negocio: porId.get(id)?.nombre ?? null, titulo: cupon.titulo, min_compra_minor: cupon.min_compra_minor };
    }
    return ok(200, { nombre: c.nombre, pedidos_pagados: pagados.length, insignias, premio, ...calcularCiudad(pagados.map((o) => ({ zona: porId.get(o.negocio_id)?.zona }))) });
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
    const [yaPago] = await db.get('ordenes', `comprador_id=eq.${c.id}&negocio_id=eq.${n.id}&estado=in.(pagada,lista,entregada)&select=id&limit=1`);
    if (yaPago) {
      const abiertos = await db.get('cupones', `negocio_id=eq.${n.id}&activo=eq.true&codigo=is.null&vence=gt.${q(ahoraIso())}&select=id`);
      const nuevos = cuponesPorOfrecer(abiertos, await db.get('cupon_canjes', `comprador_id=eq.${c.id}&select=cupon_id`), c.id);
      if (nuevos.length) await db.insertar('cupon_canjes', nuevos).catch(() => {}); // otra cuenta simultánea ya lo creó
    }
    // cupones aceptados por esta persona para este negocio, autoaplicados al total
    const canjes = await db.get('cupon_canjes', `comprador_id=eq.${c.id}&estado=eq.aceptado&select=id,cupones!inner(id,negocio_id,tipo,valor,min_compra_minor,vence,activo,titulo,producto_regalo)&cupones.negocio_id=eq.${n.id}`);
    const codigo = String(b.coupon_code ?? '').trim().toUpperCase();
    if (codigo) {
      exigir(/^[A-Z0-9-]{3,24}$/.test(codigo), 422, 'INVALID_COUPON', 'El código no es válido.', 'coupon_code');
      const [cupon] = await db.get('cupones', `negocio_id=eq.${n.id}&codigo=eq.${q(codigo)}&activo=eq.true&select=id,negocio_id,tipo,valor,min_compra_minor,vence,activo,titulo,producto_regalo&limit=1`);
      exigir(cupon, 422, 'INVALID_COUPON', 'Ese código no aplica aquí.', 'coupon_code');
      let [canje] = await db.get('cupon_canjes', `cupon_id=eq.${cupon.id}&comprador_id=eq.${c.id}&limit=1`);
      if (!canje) { try { [canje] = await db.insertar('cupon_canjes', { cupon_id: cupon.id, comprador_id: c.id, estado: 'aceptado' }); } catch { [canje] = await db.get('cupon_canjes', `cupon_id=eq.${cupon.id}&comprador_id=eq.${c.id}&limit=1`); } }
      if (canje?.estado === 'ofrecido') [canje] = await db.actualizar('cupon_canjes', `id=eq.${canje.id}&estado=eq.ofrecido`, { estado: 'aceptado', actualizado: ahoraIso() });
      exigir(canje?.estado === 'aceptado', 409, 'COUPON_UNAVAILABLE', 'Ese código ya no está disponible.');
      canjes.push({ id: canje.id, cupones: cupon });
    }
    const mejor = mejorCupon(canjes.map((x) => ({ ...x.cupones, canje_id: x.id })), r.subtotal_minor, r.items);
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
    const [n] = await db.get('negocios', `id=eq.${cot.negocio_id}&verificado=eq.true&abierto=eq.true&select=id,auto_aceptar,semilla&limit=1`);
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
    else if (esPruebaDemo(n, o)) aceptarDespues(db, o.id);
    return ok(201, publica(o, true));
  }
  if (m === 'GET' && ruta === '/orders') { // mis pedidos (comprador) o pedidos del negocio
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const comoNegocio = auth.negocio && url.searchParams.get('as') !== 'comprador'; // quien tiene negocio también compra
    const quien = comoNegocio ? `negocio_id=eq.${auth.negocio.id}` : `comprador_id=eq.${comp().id}`;
    const estado = url.searchParams.get('status');
    const filas = await db.get('ordenes', `${quien}${estado ? `&estado=eq.${q(estado)}` : ''}&order=id.desc&limit=50`);
    if (!comoNegocio) return ok(200, filas.map((o) => publica(o, true)));
    const compradores = [...new Set(filas.map((o) => o.comprador_id))];
    const pagados = compradores.length ? await db.get('ordenes', `comprador_id=in.(${compradores.join(',')})&estado=in.(pagada,lista,entregada)&select=comprador_id,negocio_id`) : [];
    const negocioIds = [...new Set(pagados.map((o) => o.negocio_id))];
    const negocios = negocioIds.length ? await db.get('negocios', `id=in.(${negocioIds.join(',')})&select=id,nombre,colonia,categoria`) : [];
    const porNegocio = new Map(negocios.map((n) => [n.id, n])); const logros = new Map();
    for (const compradorId of compradores) logros.set(compradorId, calcularInsignias(pagados.filter((o) => o.comprador_id === compradorId).map((o) => { const n = porNegocio.get(o.negocio_id) ?? {}; return { negocio_id: o.negocio_id, negocio_nombre: n.nombre, colonia: n.colonia, categoria: n.categoria }; })).filter((b) => b.obtenida).map((b) => ({ id: b.id, nivel: b.nivel, nombre: SELLO_PUBLICO[b.nivel] })));
    return ok(200, filas.map((o) => ({ ...publica(o, false), comprador_logros: logros.get(o.comprador_id) ?? [] })));
  }
  if (m === 'GET' && (p = ruta.match(/^\/orders\/(\d+)$/))) {
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const { o, esComprador } = await pedidoDe(db, Number(p[1]), auth);
    return ok(200, publica(o, esComprador));
  }
  if (m === 'POST' && (p = ruta.match(/^\/orders\/(\d+)\/(cancel|accept|reject|ready|received|payments)$/))) {
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const { o, esComprador, esNegocio } = await pedidoDe(db, Number(p[1]), auth);
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
      const i = r.intento; return ok(r.repetido ? 200 : 201, { payment_id: i.id, via: i.via, estado: i.estado, vence: i.vence, link: r.url ?? i.instrucciones?.link ?? null, qr_image: r.qr_image ?? i.instrucciones?.qr_image ?? null, amount_minor: i.monto_minor });
    }
    if (accion === 'received') {
      exigir(esComprador, 403, 'FORBIDDEN', 'Solo quien pidió puede confirmar la entrega.');
      return ok(200, publica(await mover(db, o, 'entregada'), true));
    }
    exigir(esNegocio, 403, 'FORBIDDEN', 'Solo el negocio del pedido puede hacer esto.');
    if (accion === 'accept') { const nueva = await mover(db, o, 'aceptada'); await cobrarPedido(db, nueva); return ok(200, publica((await db.get('ordenes', `id=eq.${o.id}`))[0], false)); }
    if (accion === 'reject') { const nueva = await mover(db, o, 'rechazada'); await liberarCupon(db, nueva); return ok(200, publica(nueva, false)); }
    return ok(200, publica(await mover(db, o, 'lista'), false)); // ready
  }
  if (m === 'GET' && (p = ruta.match(/^\/orders\/(\d+)\/payments\/current$/))) {
    exigir(auth, 401, 'UNAUTHENTICATED', 'Inicia sesión para continuar.');
    const { o, esComprador } = await pedidoDe(db, Number(p[1]), auth);
    const [i] = await db.get('intentos_cobro', `orden_id=eq.${o.id}&order=id.desc&limit=1&select=id,orden_id,via,pey_ref,estado,vence,monto_minor,instrucciones`);
    exigir(i, 404, 'NOT_FOUND', 'Todavía no hay cobro.');
    if (await reconciliar(db, i)) i.estado = 'pagado'; // respaldo del webhook, solo para este intento
    delete i.pey_ref; delete i.orden_id;
    const { instrucciones, ...resto } = i; // link y QR son para quien paga, no para el negocio
    return ok(200, esComprador ? { ...resto, link: instrucciones?.link ?? null, qr_image: instrucciones?.qr_image ?? null } : resto);
  }

  if (ruta === '/business/dashboard' && m === 'GET') {
    const n = neg();
    // ponytail: últimos 30 días y hasta 1000 pedidos; una vista agregada en SQL si un negocio rebasa eso
    const desde = new Date(Date.now() - 30 * 864e5).toISOString();
    const ordenes = await db.get('ordenes', `negocio_id=eq.${n.id}&creado=gte.${q(desde)}&order=id.desc&limit=1000&select=estado,monto,items,comprador_id,creado,pagada_en,descuento_minor`);
    return ok(200, resumenNegocio(ordenes));
  }

  // ----- promociones del negocio -----
  if (ruta === '/business/coupons' && m === 'GET') {
    const n = neg();
    return ok(200, await db.get('cupones', `negocio_id=eq.${n.id}&order=id.desc&limit=50`));
  }
  if (ruta === '/business/coupons' && m === 'POST') {
    const n = neg(); const b = await cuerpo();
    const valor = Number(b.value); const min = Number(b.min_amount_minor ?? 0); const vence = new Date(b.expires_at);
    exigir(['porcentaje', 'monto', 'producto_gratis'].includes(b.type), 422, 'INVALID_COUPON', 'Elige porcentaje, monto o producto gratis.', 'type');
    exigir(Number.isInteger(valor) && valor > 0 && (b.type === 'monto' || valor <= 100), 422, 'INVALID_COUPON', 'El valor no es válido.', 'value');
    exigir(Number.isInteger(min) && min >= 0, 422, 'INVALID_COUPON', 'La compra mínima no es válida.', 'min_amount_minor');
    exigir(vence > new Date(), 422, 'INVALID_COUPON', 'La fecha debe ser futura.', 'expires_at');
    exigir(typeof b.title === 'string' && b.title.trim().length >= 3 && b.title.length <= 80, 422, 'INVALID_COUPON', 'Escribe un título corto.', 'title');
    const codigo = b.code ? String(b.code).trim().toUpperCase() : null;
    exigir(!codigo || /^[A-Z0-9-]{3,24}$/.test(codigo), 422, 'INVALID_COUPON', 'El código usa letras, números y guiones.', 'code');
    const regalo = b.type === 'producto_gratis' ? String(b.free_product ?? '').trim() : null;
    exigir(b.type !== 'producto_gratis' || (regalo && n.productos?.some((p) => normalizar(p.nombre) === normalizar(regalo))), 422, 'INVALID_COUPON', 'Elige un producto de tu menú para regalar.', 'free_product');
    const [cupon] = await db.insertar('cupones', { negocio_id: n.id, titulo: b.title.trim(), tipo: b.type, valor: b.type === 'producto_gratis' ? 1 : valor, codigo, producto_regalo: regalo, min_compra_minor: min, vence: vence.toISOString() });
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
