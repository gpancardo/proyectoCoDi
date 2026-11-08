import test from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { calcularInsignias, cotizar, cuponesPorOfrecer, descuentoCupon, mejorCupon, pagoConfirmado, puede, verificarFirma } from '../src/pedidos.js';

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
