import test from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { calcularCiudad, calcularInsignias, cotizar, cuponesPorOfrecer, descuentoCupon, mejorCupon, pagoConfirmado, puede, resumenNegocio, TEMAS_ALCALDIA, verificarFirma } from '../src/pedidos.js';

const menu = [{ nombre: 'Taco de canasta', precio: 12 }, { nombre: 'Refresco', precio: '18.5' }, { nombre: 'Malo', precio: -5 }];

test('cotiza en centavos desde el catálogo y rechaza lo inválido', () => {
  assert.equal(cotizar(menu, [{ nombre: 'taco de canasta', cantidad: 10 }, { nombre: 'Refresco', cantidad: 2 }]).subtotal_minor, 15700);
  assert.deepEqual(cotizar(menu, [{ nombre: 'Refresco', cantidad: 1 }, { nombre: 'refresco', cantidad: 2 }]).items, [{ nombre: 'Refresco', precio_minor: 1850, cantidad: 3 }]);
  for (const p of [[{ nombre: 'Malo', cantidad: 1 }], [{ nombre: 'Pizza', cantidad: 1 }], [{ nombre: 'Refresco', cantidad: 0 }], [{ nombre: 'Refresco', cantidad: 1.5 }], [], null]) assert.ok(cotizar(menu, p).error);
});

test('cupones: porcentaje, monto, mínimo, vencimiento y total nunca en cero', () => {
  const futuro = new Date(Date.now() + 1e6).toISOString();
  const pct = { activo: true, tipo: 'porcentaje', valor: 10, min_compra_minor: 5000, vence: futuro };
  assert.equal(descuentoCupon(pct, 15700), 1570);
  assert.equal(descuentoCupon(pct, 4000), 0); // no llega al mínimo
  assert.equal(descuentoCupon({ ...pct, vence: new Date(0).toISOString() }, 15700), 0);
  assert.equal(descuentoCupon({ ...pct, activo: false }, 15700), 0);
  assert.equal(descuentoCupon({ ...pct, tipo: 'monto', valor: 99999, min_compra_minor: 0 }, 1200), 1100); // deja mínimo $1
  assert.equal(mejorCupon([pct, { ...pct, tipo: 'monto', valor: 3000 }], 15700).descuento_minor, 3000);
  assert.equal(mejorCupon([], 15700), null);
  const gratis = { activo: true, tipo: 'producto_gratis', valor: 1, producto_regalo: 'Refresco', min_compra_minor: 0, vence: futuro };
  assert.equal(descuentoCupon(gratis, 15700, [{ nombre: 'Refresco', precio_minor: 1850, cantidad: 2 }]), 1850);
});

test('sellos: siempre cuatro, personalizados y sin depender de comida', () => {
  const p = (negocio_id, negocio_nombre, colonia, categoria) => ({ negocio_id, negocio_nombre, colonia, categoria });
  const nivel = (r, n) => r.find((x) => x.nivel === n);
  const vacio = calcularInsignias([]);
  assert.equal(vacio.length, 4); assert.ok(vacio.every((x) => !x.obtenida && x.avance === 0));
  const r = calcularInsignias([p(1, 'La Espiga', 'Clavería', 'Panadería'), p(2, 'Miranda', 'Clavería', 'Papelería'), p(1, 'La Espiga', 'Clavería', 'Panadería'), p(3, 'San Miguel', 'Clavería', 'Ferretería'), p(1, 'La Espiga', 'Clavería', 'Panadería')]);
  assert.match(nivel(r, 'primera').detalle, /La Espiga/);
  assert.ok(nivel(r, 'bronce').obtenida); assert.equal(nivel(r, 'bronce').nombre, 'Ya te conocen en La Espiga');
  assert.ok(nivel(r, 'plata').obtenida); assert.equal(nivel(r, 'plata').nombre, 'Conoces Clavería');
  assert.ok(!nivel(r, 'oro').obtenida); assert.equal(nivel(r, 'oro').avance, 3);
  const mismoNombre = calcularInsignias([p(1, 'Tacos', 'A', 'x'), p(2, 'Tacos', 'A', 'x'), p(3, 'Tacos', 'A', 'x')]);
  assert.ok(!nivel(mismoNombre, 'bronce').obtenida); // dos negocios con el mismo nombre no se suman
  assert.equal(nivel(calcularInsignias([p(1, 'x', 'A', 'a'), p(1, 'x', 'A', 'a'), p(1, 'x', 'A', 'a'), p(1, 'x', 'A', 'a')]), 'bronce').avance, 3); // no rebasa la meta
});

test('promociones sin código: solo se ofrecen una vez a quien ya pagó', () => {
  assert.deepEqual(cuponesPorOfrecer([{ id: 1 }, { id: 2 }], [{ cupon_id: 1 }], 9), [{ cupon_id: 2, comprador_id: 9, estado: 'aceptado' }]);
  assert.deepEqual(cuponesPorOfrecer([{ id: 1 }], [{ cupon_id: 1 }], 9), []);
});

test('sellos de ciudad: 16 alcaldías con niveles y la ciudad vale la más floja', () => {
  const zonas = Object.keys(TEMAS_ALCALDIA);
  assert.equal(zonas.length, 16);
  const pedidosEn = (zona, n) => Array.from({ length: n }, () => ({ zona }));
  const uno = calcularCiudad(pedidosEn('Coyoacán', 3));
  const coyo = uno.alcaldias.find((a) => a.zona === 'Coyoacán');
  assert.equal(coyo.nivel, 'plata'); assert.equal(coyo.meta, 5);
  assert.equal(uno.alcaldias.find((a) => a.zona === 'Tlalpan').nivel, null);
  assert.equal(uno.cdmx.nivel, null); assert.equal(uno.cdmx.avance, 1); assert.equal(uno.cdmx.meta, 16);
  const bronce = calcularCiudad(zonas.flatMap((z) => pedidosEn(z, 1)));
  assert.equal(bronce.cdmx.nivel, 'bronce'); assert.equal(bronce.cdmx.avance, 0); // rumbo a plata: ninguna lleva 3
  const oro = calcularCiudad(zonas.flatMap((z) => pedidosEn(z, 5)));
  assert.equal(oro.cdmx.nivel, 'oro'); assert.equal(oro.alcaldias[0].avance, 5);
  assert.equal(calcularCiudad(pedidosEn('Narnia', 9)).cdmx.nivel, null);
  // los sellos que dibujamos cubren exactamente estas alcaldías
  assert.equal(new Set(Object.values(TEMAS_ALCALDIA).map(([id]) => id)).size, 16);
});

test('tablero del negocio: suma solo lo cobrado y separa días en hora de CDMX', () => {
  const ahora = new Date('2026-11-08T18:00:00Z');
  const item = (cantidad, precio_minor, nombre = 'Pluma') => ({ nombre, cantidad, precio_minor });
  const o = (estado, monto, creado, comprador_id, items = [], descuento_minor = 0) => ({ estado, monto, creado, comprador_id, items, descuento_minor });
  const r = resumenNegocio([
    o('pagada', 100, '2026-11-08T17:00:00Z', 1, [item(2, 5000)]),
    o('entregada', 50.5, '2026-11-08T07:00:00Z', 2, [item(1, 5050, 'Copia')], 500), // 01:00 en CDMX: sigue siendo hoy
    o('lista', 30, '2026-11-08T05:00:00Z', 1, [item(1, 3000, 'Copia')]), // 23:00 del 7 en CDMX: ayer
    o('pendiente', 999, '2026-11-08T17:00:00Z', 3), o('rechazada', 999, '2026-11-08T17:00:00Z', 3),
  ], ahora);
  assert.deepEqual(r.hoy, { ventas_minor: 15050, cobros: 2, ticket_minor: 7525 });
  assert.equal(r.ayer_minor, 3000);
  assert.equal(r.semana.length, 7); assert.equal(r.semana[6].dia, '2026-11-08'); assert.equal(r.semana[5].ventas_minor, 3000);
  assert.deepEqual(r.por_atender, { responder: 1, preparar: 1, recoger: 1 });
  assert.equal(r.productos[0].nombre, 'Pluma'); assert.equal(r.productos[0].cantidad, 2);
  assert.deepEqual(r.clientes, { total: 2, regresan: 1 });
  assert.equal(r.mes.descuentos_minor, 500);
  assert.equal(resumenNegocio([], ahora).hoy.ticket_minor, 0);
});

test('máquina de estados', () => {
  assert.ok(puede('pendiente', 'aceptada') && puede('vencida', 'cobrada') && puede('pagada', 'lista') && puede('lista', 'entregada'));
  assert.ok(!puede('pagada', 'cancelada') && !puede('lista', 'pendiente') && !puede('cobrada', 'cancelada'));
});

test('pago confirmado exige monto completo', () => {
  const paga = (base) => ({ status: 'PAID', amount: base, amountBreakdown: { base }, metadata: { trackingKey: 'K1' } });
  assert.deepEqual(pagoConfirmado('push', paga(120), 12000), { rastreo: 'K1' });
  assert.equal(pagoConfirmado('push', paga(100), 12000), null);
  assert.equal(pagoConfirmado('push', { status: 'PENDING', amount: 120 }, 12000), null);
  assert.ok(pagoConfirmado('push', paga(0.1 + 0.2), 30));
  assert.ok(pagoConfirmado('link', { status: 'paid', transactions: [{ amount: 100 }, { amount: 20 }] }, 12000));
  assert.equal(pagoConfirmado('link', { status: 'partial', transactions: [{ amount: 100 }] }, 12000), null);
  assert.equal(pagoConfirmado('qr', { items: [] }, 500), null);
});

test('firma del webhook: válida, alterada y repetida fuera de ventana', () => {
  const secreto = 'whsec_' + Buffer.from('clave-de-prueba').toString('base64');
  const cuerpo = '{"type":"codi.pn.payment_received"}'; const ts = Math.floor(Date.now() / 1000);
  const firma = 'v1,' + createHmac('sha256', Buffer.from('clave-de-prueba')).update(`msg_1.${ts}.${cuerpo}`).digest('base64');
  const h = { 'webhook-id': 'msg_1', 'webhook-timestamp': String(ts), 'webhook-signature': firma };
  assert.ok(verificarFirma(secreto, cuerpo, h));
  assert.ok(!verificarFirma(secreto, cuerpo + ' ', h));
  assert.ok(!verificarFirma(secreto, cuerpo, h, Date.now() + 10 * 60_000));
  assert.ok(!verificarFirma(secreto, cuerpo, { ...h, 'webhook-signature': 'v1,AAAA' }));
  assert.ok(!verificarFirma('', cuerpo, h));
});
