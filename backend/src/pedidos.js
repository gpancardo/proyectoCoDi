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
