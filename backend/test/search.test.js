import test from 'node:test';
import assert from 'node:assert/strict';
import { buscarConPista, buscarDeterminista, seccionesDescubrimiento, validarFiltros } from '../src/search.js';
import { combinarFiltros } from '../src/agent.js';

const negocios = [
  { id: 2, nombre: 'Tacos Coyoacán', zona: 'Coyoacán', categoria: 'comida', verificado: true, abierto: true, productos: [{ nombre: 'Taco de canasta', precio: 12 }] },
  { id: 1, nombre: 'Pan de barrio', zona: 'Coyoacán', categoria: 'panaderia', verificado: true, abierto: true, productos: [{ nombre: 'Concha', precio: 18 }] },
  { id: 3, nombre: 'Tacos cerrados', zona: 'Coyoacán', categoria: 'comida', verificado: true, abierto: false, productos: [{ nombre: 'Taco', precio: 10 }] },
];

test('la búsqueda no requiere agente y explica la coincidencia', () => {
  const r = buscarDeterminista(negocios, { q: 'tacos', zone: 'Coyoacán', open_now: true }, { categorias: { comida: 3 } });
  assert.equal(r.length, 1); assert.equal(r[0].negocio.id, 2); assert.ok(r[0].match_reasons.includes('Está en tu zona'));
});
test('los filtros explícitos tienen prioridad sobre el agente', () => {
  const r = combinarFiltros({ zone: 'Coyoacán', q: 'pan' }, { zone: 'Tlalpan', q: 'tacos', open_now: true });
  assert.equal(r.zone, 'Coyoacán'); assert.equal(r.q, 'pan'); assert.equal(r.open_now, true);
});
test('rechaza rangos de precio invertidos', () => assert.throws(() => validarFiltros({ min_amount_minor: 500, max_amount_minor: 10 })));
test('descubrimiento ordena primero afinidades explícitas', () => {
  const r = seccionesDescubrimiento(negocios, { categorias: { comida: 4 } });
  assert.equal(r.sections[0].id, 'comida');
});

test('la categoría del modelo es una pista; la de la app es estricta', () => {
  const taqueria = [{ id: 7, nombre: 'Tacos Doña Lupe', zona: 'Coyoacán', categoria: 'Taquería', verificado: true, abierto: true, productos: [{ nombre: 'Taco de canasta', precio: 12 }] }];
  assert.equal(buscarDeterminista(taqueria, { q: 'tacos', category: 'antojitos' }).length, 0);
  assert.equal(buscarConPista(taqueria, { q: 'tacos', category: 'antojitos' }, null, {}).length, 1);
  assert.equal(buscarConPista(taqueria, { q: 'tacos', category: 'antojitos' }, null, { category: 'antojitos' }).length, 0);
});
