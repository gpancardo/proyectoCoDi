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
