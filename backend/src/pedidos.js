import { createHmac, timingSafeEqual } from 'node:crypto';
import { normalizar } from './text.js';

// Todo el dinero va en centavos enteros; el cliente y el modelo nunca aportan precios ni totales.
export const MINUTOS = { cotizacion: 10, cobro: 15, negocioSinResponder: 8 };

// Transiciones permitidas; cada UPDATE exige el estado previo (compare-and-set).
export const TRANSICIONES = {
  pendiente: ['aceptada', 'rechazada', 'expirada', 'cancelada'],
  aceptada: ['cobrada', 'cancelada'],
  cobrada: ['pagada', 'vencida'],
  vencida: ['cobrada', 'cancelada'],
  pagada: ['lista'],
  lista: ['entregada'],
};
export const puede = (de, a) => TRANSICIONES[de]?.includes(a) ?? false;

export function cotizar(productos, pedido) {
  if (!Array.isArray(pedido) || !pedido.length || pedido.length > 30) return { error: 'Agrega al menos un artículo.' };
  const items = [];
  for (const { nombre, cantidad } of pedido) {
    const p = (productos ?? []).find((x) => normalizar(x.nombre) === normalizar(nombre));
    if (!p) return { error: `“${nombre}” no está en el menú.` };
    const precio_minor = Math.round(Number(p.precio) * 100);
    if (!Number.isInteger(precio_minor) || precio_minor <= 0) return { error: `“${p.nombre}” no tiene precio válido.` };
    if (!Number.isInteger(cantidad) || cantidad < 1 || cantidad > 100) return { error: `Cantidad inválida para ${p.nombre} (de 1 a 100).` };
    const ya = items.find((i) => i.nombre === p.nombre);
    if (ya) ya.cantidad += cantidad; else items.push({ nombre: p.nombre, precio_minor, cantidad });
  }
  const subtotal_minor = items.reduce((s, i) => s + i.precio_minor * i.cantidad, 0);
  if (subtotal_minor > 100_000_000) return { error: 'El total no es válido.' };
  return { items, subtotal_minor };
}

// Descuento de un cupón; nunca deja el total en cero (mínimo un peso).
export function descuentoCupon(cupon, subtotal_minor, items = [], ahora = new Date()) {
  if (!Array.isArray(items)) { ahora = items; items = []; } // compatibilidad de llamada: (cupón, subtotal, ahora)
  if (!cupon?.activo || new Date(cupon.vence) <= ahora || subtotal_minor < cupon.min_compra_minor) return 0;
  const regalo = (items ?? []).find((item) => normalizar(item.nombre) === normalizar(cupon.producto_regalo ?? ''));
  const bruto = cupon.tipo === 'porcentaje' ? Math.floor(subtotal_minor * cupon.valor / 100)
    : cupon.tipo === 'producto_gratis' ? (regalo?.precio_minor ?? 0) : cupon.valor;
  return Math.max(0, Math.min(bruto, subtotal_minor - 100));
}

export function mejorCupon(cupones, subtotal_minor, items = [], ahora) {
  let mejor = null;
  for (const c of cupones) {
    const d = descuentoCupon(c, subtotal_minor, items, ahora);
    if (d > (mejor?.descuento_minor ?? 0)) mejor = { cupon: c, descuento_minor: d };
  }
  return mejor;
}

// Sellos derivados de pedidos pagados: no se guardan, así no hay premios desincronizados. Siempre son cuatro.
export const METAS_SELLOS = { primera: 1, bronce: 3, plata: 3, oro: 4 };
// Lo que ve un negocio: nunca el nombre de otros negocios ni dónde más compra su cliente.
export const SELLO_PUBLICO = { primera: 'Primera compra', bronce: 'Cliente frecuente', plata: 'Conoce la colonia', oro: 'Compra de todo' };
export function calcularInsignias(pedidos) { // en orden de compra: [{ negocio_id, negocio_nombre, colonia, categoria }]
  const porNegocio = new Map(); const porColonia = new Map(); const giros = new Map();
  for (const p of pedidos) {
    if (p.negocio_id != null) { const v = porNegocio.get(p.negocio_id) ?? { nombre: p.negocio_nombre, compras: 0 }; v.compras += 1; porNegocio.set(p.negocio_id, v); }
    if (p.colonia) { const k = normalizar(p.colonia); const v = porColonia.get(k) ?? { nombre: p.colonia, negocios: new Set() }; v.negocios.add(p.negocio_id); porColonia.set(k, v); }
    if (p.categoria) giros.set(normalizar(p.categoria), p.categoria.toLowerCase());
  }
  const casa = [...porNegocio.values()].sort((a, b) => b.compras - a.compras)[0];
  const colonia = [...porColonia.values()].sort((a, b) => b.negocios.size - a.negocios.size)[0];
  const sello = (nivel, nombre, detalle, avance) => ({ id: nivel, nivel, nombre, detalle, avance: Math.min(avance, METAS_SELLOS[nivel]), meta: METAS_SELLOS[nivel], obtenida: avance >= METAS_SELLOS[nivel] });
  return [
    sello('primera', 'Primera compra', pedidos.length ? `La hiciste en ${pedidos[0].negocio_nombre ?? 'tu barrio'}.` : 'Tu primer pedido pagado en Barrio.', pedidos.length),
    sello('bronce', casa ? `Ya te conocen en ${casa.nombre}` : 'Ya te conocen', 'Tres compras en el mismo negocio.', casa?.compras ?? 0),
    sello('plata', colonia ? `Conoces ${colonia.nombre}` : 'Conoces tu colonia', 'Tres negocios distintos de una misma colonia.', colonia?.negocios.size ?? 0),
    sello('oro', 'De todo en tu barrio', giros.size >= METAS_SELLOS.oro ? `Compraste en ${[...giros.values()].slice(0, 4).join(', ')}.` : 'Cuatro tipos de negocio: papelería, ferretería, lo que ocupes.', giros.size),
  ];
}

// Sellos de ciudad: uno por alcaldía y uno por completar las 16, con los mismos niveles. Documentados en docs/LOGROS.md.
export const NIVELES_ALCALDIA = [['bronce', 1], ['plata', 3], ['oro', 5]]; // compras pagadas en esa alcaldía
export const TEMAS_ALCALDIA = {
  'Álvaro Obregón': ['alvaro-obregon', 'Entre barrancas'],
  Azcapotzalco: ['azcapotzalco', 'El hormiguero'],
  'Benito Juárez': ['benito-juarez', 'Los Venados'],
  Coyoacán: ['coyoacan', 'Lugar de coyotes'],
  Cuajimalpa: ['cuajimalpa', 'Donde se labra la madera'],
  Cuauhtémoc: ['cuauhtemoc', 'Águila que desciende'],
  'Gustavo A. Madero': ['gustavo-a-madero', 'Al pie de la sierra'],
  Iztacalco: ['iztacalco', 'Casa de la sal'],
  Iztapalapa: ['iztapalapa', 'Agua sobre lajas'],
  'Magdalena Contreras': ['magdalena-contreras', 'Los Dinamos'],
  'Miguel Hidalgo': ['miguel-hidalgo', 'Cerro del chapulín'],
  'Milpa Alta': ['milpa-alta', 'Tierra de nopal'],
  Tláhuac: ['tlahuac', 'Canoa y lago'],
  Tlalpan: ['tlalpan', 'Tierra firme'],
  'Venustiano Carranza': ['venustiano-carranza', 'Balanza de mercado'],
  Xochimilco: ['xochimilco', 'Campo de flores'],
};
const nivelDe = (compras) => NIVELES_ALCALDIA.filter(([, meta]) => compras >= meta).at(-1)?.[0] ?? null;
const metaSiguiente = (compras) => (NIVELES_ALCALDIA.find(([, meta]) => compras < meta) ?? NIVELES_ALCALDIA.at(-1))[1];
export function calcularCiudad(pedidos) { // [{ zona }]
  const compras = new Map();
  for (const p of pedidos) if (p.zona) compras.set(p.zona, (compras.get(p.zona) ?? 0) + 1);
  const alcaldias = Object.entries(TEMAS_ALCALDIA).map(([zona, [id, nombre]]) => {
    const n = compras.get(zona) ?? 0;
    return { id, zona, nombre, nivel: nivelDe(n), avance: n, meta: metaSiguiente(n) };
  });
  // el sello de la ciudad vale lo que la alcaldía más floja: oro solo con las 16 en oro
  const peor = Math.min(...alcaldias.map((a) => a.avance));
  const siguiente = (NIVELES_ALCALDIA.find(([, meta]) => peor < meta) ?? NIVELES_ALCALDIA.at(-1))[1];
  const cdmx = { id: 'cdmx', nombre: 'Toda la ciudad', nivel: nivelDe(peor), avance: alcaldias.filter((a) => a.avance >= siguiente).length, meta: alcaldias.length };
  return { alcaldias, cdmx };
}

const ESTADOS_COBRADOS = new Set(['pagada', 'lista', 'entregada']);
const diaCdmx = (fecha) => new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Mexico_City' }).format(new Date(fecha)); // AAAA-MM-DD

// Tablero del negocio. ordenes: [{ estado, monto, items, comprador_id, creado, pagada_en, descuento_minor }]
export function resumenNegocio(ordenes, ahora = new Date()) {
  const cobradas = ordenes.filter((o) => ESTADOS_COBRADOS.has(o.estado));
  const totalDe = (lista) => lista.reduce((s, o) => s + Math.round(Number(o.monto) * 100), 0);
  const delDia = (dia) => cobradas.filter((o) => diaCdmx(o.pagada_en ?? o.creado) === dia);
  const hoy = diaCdmx(ahora);
  const dias = Array.from({ length: 7 }, (_, i) => diaCdmx(ahora.getTime() - (6 - i) * 864e5));
  const ayer = delDia(diaCdmx(ahora.getTime() - 864e5));
  const productos = new Map(); const compras = new Map();
  for (const o of cobradas) {
    compras.set(o.comprador_id, (compras.get(o.comprador_id) ?? 0) + 1);
    for (const i of o.items ?? []) { const v = productos.get(i.nombre) ?? { nombre: i.nombre, cantidad: 0, ventas_minor: 0 }; v.cantidad += i.cantidad; v.ventas_minor += i.cantidad * i.precio_minor; productos.set(i.nombre, v); }
  }
  const deHoy = delDia(hoy);
  const cuenta = (estados) => ordenes.filter((o) => estados.includes(o.estado)).length;
  return {
    hoy: { ventas_minor: totalDe(deHoy), cobros: deHoy.length, ticket_minor: deHoy.length ? Math.round(totalDe(deHoy) / deHoy.length) : 0 },
    ayer_minor: totalDe(ayer),
    semana: dias.map((dia) => ({ dia, ventas_minor: totalDe(delDia(dia)), cobros: delDia(dia).length })),
    por_atender: { responder: cuenta(['pendiente']), preparar: cuenta(['pagada']), recoger: cuenta(['lista']) },
    productos: [...productos.values()].sort((a, b) => b.cantidad - a.cantidad || b.ventas_minor - a.ventas_minor).slice(0, 5),
    clientes: { total: compras.size, regresan: [...compras.values()].filter((n) => n > 1).length },
    mes: { ventas_minor: totalDe(cobradas), cobros: cobradas.length, descuentos_minor: cobradas.reduce((s, o) => s + (o.descuento_minor ?? 0), 0) },
  };
}

// Quien ya pagó aquí recibe las promociones sin código que aún no tiene: se descuentan solas en su siguiente cuenta.
export const cuponesPorOfrecer = (cupones, canjes, comprador_id) => {
  const ya = new Set(canjes.map((x) => x.cupon_id));
  return cupones.filter((c) => !ya.has(c.id)).map((c) => ({ cupon_id: c.id, comprador_id, estado: 'aceptado' }));
};

// ¿pey confirma que el cobro se pagó completo? Cuenta el monto base (sin propina ni comisión).
export function pagoConfirmado(via, r, monto_minor) {
  const pagadas = via === 'link' ? (r?.status === 'paid' ? r.transactions ?? [] : [])
    : (via === 'qr' ? r?.items ?? [] : [r]).filter((t) => t?.status === 'PAID');
  const cobrado = pagadas.reduce((s, t) => s + Math.round(Number(t.amountBreakdown?.base ?? t.amount ?? 0) * 100), 0);
  return pagadas.length && cobrado >= monto_minor ? { rastreo: pagadas[0].metadata?.trackingKey ?? null } : null;
}

// Standard Webhooks (HMAC-SHA256 sobre `${id}.${timestamp}.${cuerpo crudo}`), tolerancia de 5 min contra repetición.
export function verificarFirma(secreto, cuerpo, h, ahora = Date.now()) {
  const id = h['webhook-id']; const ts = Number(h['webhook-timestamp']); const firmas = h['webhook-signature'];
  if (!secreto || !id || !firmas || !Number.isFinite(ts) || Math.abs(ahora / 1000 - ts) > 300) return false;
  const esperada = createHmac('sha256', Buffer.from(secreto.replace(/^whsec_/, ''), 'base64')).update(`${id}.${ts}.${cuerpo}`).digest();
  return String(firmas).split(' ').some((f) => {
    const dado = Buffer.from(f.replace(/^v1,/, ''), 'base64');
    return f.startsWith('v1,') && dado.length === esperada.length && timingSafeEqual(dado, esperada);
  });
}
