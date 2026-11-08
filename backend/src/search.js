import { normalizar, palabras } from './text.js';

const incluye = (texto, termino) => normalizar(texto).includes(termino);
const productos = (negocio) => Array.isArray(negocio.productos) ? negocio.productos : [];

export function validarFiltros(entrada = {}) {
  const q = String(entrada.q ?? '').trim().slice(0, 160);
  const zone = entrada.zone ? String(entrada.zone).trim().slice(0, 80) : null;
  const category = entrada.category ? normalizar(entrada.category).slice(0, 60) : null;
  const openNow = entrada.open_now === true || entrada.open_now === 'true';
  const minAmount = entrada.min_amount_minor == null ? null : Number(entrada.min_amount_minor);
  const maxAmount = entrada.max_amount_minor == null ? null : Number(entrada.max_amount_minor);
  if (!Number.isInteger(minAmount) && minAmount !== null) throw new Error('min_amount_minor debe ser un entero');
  if (!Number.isInteger(maxAmount) && maxAmount !== null) throw new Error('max_amount_minor debe ser un entero');
  if (minAmount !== null && minAmount < 0) throw new Error('min_amount_minor no puede ser negativo');
  if (maxAmount !== null && maxAmount < 0) throw new Error('max_amount_minor no puede ser negativo');
  if (minAmount !== null && maxAmount !== null && minAmount > maxAmount) throw new Error('El rango de precio no es válido');
  return { q, zone, category, openNow, minAmount, maxAmount };
}

function afinidad(perfil, categoria) {
  const valor = perfil?.categorias?.[normalizar(categoria)];
  return Number.isFinite(Number(valor)) ? Math.min(Number(valor), 8) : 0;
}

export function buscarDeterminista(negocios, entrada, perfil = null) {
  const filtros = validarFiltros(entrada);
  const terminos = palabras(filtros.q);
  return negocios
    .filter((n) => n.verificado && (!filtros.openNow || n.abierto))
    .filter((n) => !filtros.zone || normalizar(n.zona) === normalizar(filtros.zone))
    .filter((n) => !filtros.category || normalizar(n.categoria) === filtros.category)
    .map((n) => {
      const razones = [];
      const textoNegocio = `${n.nombre} ${n.categoria} ${productos(n).map((p) => p.nombre).join(' ')}`;
      let score = n.abierto ? 30 : 0;
      if (filtros.zone && normalizar(n.zona) === normalizar(filtros.zone)) { score += 20; razones.push('Está en tu zona'); }
      if (filtros.category && normalizar(n.categoria) === filtros.category) { score += 25; razones.push('Coincide con la categoría'); }
      const coincidencias = terminos.filter((t) => incluye(textoNegocio, t));
      if (terminos.length && !coincidencias.length) return null;
      if (coincidencias.length) { score += coincidencias.length * 18; razones.push(`Coincide con “${coincidencias.join(' ')}”`); }
      const precios = productos(n).map((p) => Math.round(Number(p.precio) * 100)).filter(Number.isFinite);
      const precioCoincide = !precios.length || ((filtros.minAmount === null || precios.some((p) => p >= filtros.minAmount)) && (filtros.maxAmount === null || precios.some((p) => p <= filtros.maxAmount)));
      if (!precioCoincide) return null;
      score += afinidad(perfil, n.categoria) * 2;
      if (afinidad(perfil, n.categoria) > 0) razones.push('Va con lo que sueles explorar');
      return { negocio: n, score, match_reasons: razones.length ? razones : ['Negocio disponible'] };
    })
    .filter(Boolean)
    .sort((a, b) => b.score - a.score || Number(a.negocio.id) - Number(b.negocio.id));
}

// La categoría que infiere el modelo es una pista, no una regla: los negocios guardan categorías libres ("Taquería") y el modelo
// elige de una lista corta ("antojitos"). Si con ella no hay resultados, se reintenta sin ella; la que manda la app sí es estricta.
export function buscarConPista(negocios, filtros, perfil, explicitos = {}) {
  const r = buscarDeterminista(negocios, filtros, perfil);
  if (r.length || !filtros.category || explicitos.category) return r;
  return buscarDeterminista(negocios, { ...filtros, category: null }, perfil);
}

// Filtros que no se negocian: negocio activo, abierto si se pide, zona, rango de precio y, solo si lo manda la app, categoría.
function pasaDuros(n, f, explicitos) {
  if (!n.verificado || (f.openNow && !n.abierto)) return false;
  if (f.zone && normalizar(n.zona) !== normalizar(f.zone)) return false;
  if (f.category && explicitos.category && normalizar(n.categoria) !== f.category) return false;
  const precios = productos(n).map((p) => Math.round(Number(p.precio) * 100)).filter(Number.isFinite);
  return !precios.length || ((f.minAmount === null || precios.some((p) => p >= f.minAmount)) && (f.maxAmount === null || precios.some((p) => p <= f.maxAmount)));
}

export const SIMILITUD_MINIMA = 0.22; // por debajo, un vecino vectorial es ruido
export const CORTE_RELATIVO = 0.7;    // y solo se conservan los que quedan cerca del mejor (si no, entra todo el catálogo)

// Búsqueda híbrida (RAG): las reglas exactas y los vecinos semánticos del catálogo se fusionan con Reciprocal Rank Fusion.
// "taco" sigue encontrando "Tacos Doña Lupe" por texto, y "algo para desayunar" encuentra la fonda aunque no diga "desayunar".
// Los filtros duros aplican a ambos lados; el modelo nunca agrega negocios que no estén en el catálogo.
export function buscarHibrido(negocios, entrada, perfil, similitudes = new Map(), explicitos = {}) {
  const f = validarFiltros(entrada);
  const lex = buscarConPista(negocios, entrada, perfil, explicitos);
  const sem = negocios.filter((n) => pasaDuros(n, f, explicitos))
    .map((n) => [n, similitudes.get(Number(n.id)) ?? 0]).filter(([, s]) => s >= SIMILITUD_MINIMA)
    .sort((a, b) => b[1] - a[1] || Number(a[0].id) - Number(b[0].id))
    .filter((x, _i, todos) => x[1] >= todos[0][1] * CORTE_RELATIVO);
  const K = 60; const fusion = new Map();
  lex.forEach((m, i) => fusion.set(Number(m.negocio.id), { negocio: m.negocio, score: 1 / (K + i + 1), razones: m.match_reasons.filter((r) => r !== 'Negocio disponible'), sem: false }));
  sem.forEach(([n, s], i) => {
    const e = fusion.get(Number(n.id)) ?? { negocio: n, score: 0, razones: [], sem: false };
    e.score += 1 / (K + i + 1); e.sem = true; e.sim = s;
    fusion.set(Number(n.id), e);
  });
  return [...fusion.values()]
    .sort((a, b) => b.score - a.score || Number(a.negocio.id) - Number(b.negocio.id))
    .map((e) => ({ negocio: e.negocio, score: Math.round(e.score * 100000) / 100,
      match_reasons: [...e.razones, ...(e.sem ? ['Se parece a lo que buscas'] : [])].concat(!e.razones.length && !e.sem ? ['Negocio disponible'] : []) }));
}

export function seccionesDescubrimiento(negocios, perfil) {
  const abiertos = negocios.filter((n) => n.verificado && n.abierto);
  const porCategoria = new Map();
  for (const negocio of abiertos) {
    const llave = normalizar(negocio.categoria);
    if (!porCategoria.has(llave)) porCategoria.set(llave, []);
    porCategoria.get(llave).push(negocio);
  }
  const favoritas = [...porCategoria.entries()]
    .sort((a, b) => afinidad(perfil, b[0]) - afinidad(perfil, a[0]) || a[0].localeCompare(b[0], 'es'))
    .slice(0, 6)
    .map(([categoria, items]) => ({ id: categoria, title: categoria === 'comida' ? 'Para comer hoy' : categoria, items: items.slice(0, 12) }));
  return { sections: favoritas, categories: [...porCategoria.keys()].sort() };
}
