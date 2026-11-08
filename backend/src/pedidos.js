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

// Insignias derivadas de pedidos pagados: no se guardan, así no hay premios desincronizados.
export const REGLAS_INSIGNIAS = { colonia: 3, alcaldia: 5, negocio: 3 };
export function calcularInsignias(pedidos) { // pedidos: [{ negocio_id, negocio_nombre, colonia, zona }]
  const cuenta = (llave) => pedidos.reduce((m, p) => { const k = llave(p); if (k) m.set(k, (m.get(k) ?? 0) + 1); return m; }, new Map());
  const nombres = { colonia: (k) => `Vecino de ${k}`, alcaldia: (k) => `Fiel a ${k}`, negocio: (k) => `De la casa: ${k}` };
  const grupos = {
    colonia: cuenta((p) => p.colonia), alcaldia: cuenta((p) => p.zona),
    negocio: cuenta((p) => p.negocio_nombre),
  };
  return Object.entries(grupos).flatMap(([alcance, mapa]) => [...mapa].map(([ref, pedidos_pagados]) => {
    const meta = REGLAS_INSIGNIAS[alcance];
    return { id: `${alcance}:${normalizar(ref)}`, alcance, nombre: nombres[alcance](ref), pedidos_pagados, meta, obtenida: pedidos_pagados >= meta };
  })).sort((a, b) => Number(b.obtenida) - Number(a.obtenida) || b.pedidos_pagados - a.pedidos_pagados || a.id.localeCompare(b.id));
}

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
