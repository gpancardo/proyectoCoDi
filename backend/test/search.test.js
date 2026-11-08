import test from 'node:test';
import assert from 'node:assert/strict';
import { buscarConPista, buscarDeterminista, buscarHibrido, seccionesDescubrimiento, validarFiltros } from '../src/search.js';
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

test('híbrido: lo semántico aparece aunque no comparta palabras, y los filtros duros mandan', () => {
  const fonda = { id: 2, nombre: 'Fonda Doña Carmen', zona: 'Iztapalapa', categoria: 'Comida', verificado: true, abierto: true, productos: [{ nombre: 'Chilaquiles con huevo', precio: 65 }] };
  const taqueria = { id: 7, nombre: 'Tacos Doña Lupe', zona: 'Coyoacán', categoria: 'Antojitos', verificado: true, abierto: true, productos: [{ nombre: 'Taco de canasta', precio: 12 }] };
  const cerrada = { ...fonda, id: 3, nombre: 'Fonda cerrada', abierto: false };
  const todos = [fonda, taqueria, cerrada];
  const sim = new Map([[2, 0.62], [3, 0.6], [7, 0.1]]);
  // "desayunar" no está en ningún nombre ni producto: solo la similitud lo encuentra
  const r = buscarHibrido(todos, { q: 'desayunar barato', open_now: true }, null, sim, {});
  assert.deepEqual(r.map((x) => x.negocio.id), [2]);                       // cerrada filtrada; taquería bajo el umbral
  assert.ok(r[0].match_reasons.includes('Se parece a lo que buscas'));
  // lo que coincide por texto y por significado sube al primero
  const r2 = buscarHibrido(todos, { q: 'tacos' }, null, new Map([[7, 0.5], [2, 0.45]]), {});
  assert.equal(r2[0].negocio.id, 7); assert.ok(r2.some((x) => x.negocio.id === 2));
  // sin vectores: se comporta como la búsqueda determinista
  assert.deepEqual(buscarHibrido(todos, { q: 'tacos' }, null, new Map(), {}).map((x) => x.negocio.id), [7]);
  // zona explícita descarta vecinos de otra zona
  assert.deepEqual(buscarHibrido(todos, { q: 'comer', zone: 'Coyoacán' }, null, new Map([[2, 0.9], [7, 0.4]]), {}).map((x) => x.negocio.id), [7]);
});

test('híbrido: el corte relativo deja fuera el ruido del catálogo', () => {
  const mk = (id, nombre) => ({ id, nombre, zona: 'Coyoacán', categoria: 'Comida', verificado: true, abierto: true, productos: [{ nombre: 'x', precio: 10 }] });
  const todos = [mk(1, 'Papelería'), mk(2, 'Taller'), mk(3, 'Fonda')];
  const r = buscarHibrido(todos, { q: 'copias' }, null, new Map([[1, 0.45], [2, 0.26], [3, 0.24]]), {});
  assert.deepEqual(r.map((x) => x.negocio.id), [1]);                       // 0.26 y 0.24 < 0.45 × 0.7
  assert.deepEqual(buscarHibrido(todos, { q: 'xyzzy' }, null, new Map([[1, 0.16], [2, 0.12]]), {}), []); // todo bajo el mínimo
});
