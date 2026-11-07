import test from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { calcularInsignias, cotizar, descuentoCupon, mejorCupon, pagoConfirmado, puede, verificarFirma } from '../src/pedidos.js';

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
});

test('insignias por colonia, alcaldía y negocio', () => {
  const p = (negocio_nombre, colonia, zona) => ({ negocio_nombre, colonia, zona });
  const r = calcularInsignias([p('Tacos Lupe', 'San Lucas', 'Coyoacán'), p('Pan Beto', 'San Lucas', 'Coyoacán'), p('Tacos Lupe', 'San Lucas', 'Coyoacán'), p('Tacos Lupe', 'San Lucas', 'Coyoacán')]);
  const ganadas = r.filter((x) => x.obtenida).map((x) => x.nombre).sort();
  assert.deepEqual(ganadas, ['De la casa: Tacos Lupe', 'Vecino de San Lucas']); // alcaldía pide 5 y lleva 4
  assert.equal(r.find((x) => x.alcance === 'alcaldia').pedidos_pagados, 4);
  assert.deepEqual(calcularInsignias([]), []);
});

test('máquina de estados', () => {
  assert.ok(puede('pendiente', 'aceptada') && puede('vencida', 'cobrada') && puede('pagada', 'lista'));
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
