// Evalúa la búsqueda con modelo contra la API desplegada: ¿el negocio esperado queda entre los primeros 3?
// Uso: node scripts/eval-rag.mjs [URL_BASE]   (por defecto la Edge Function de producción). Requiere el catálogo de demo (supabase/seed.sql).
const BASE = process.argv[2] ?? 'https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api';
const CASOS = [
  ['algo barato para desayunar', ['Fonda Doña Carmen', 'Café de la Barranca']], ['necesito copias para la escuela', ['Papelería Miranda']],
  ['se me fundió un foco', ['Ferretería San Miguel']], ['flores para regalar', ['Flores de Cuemanco']], ['arreglar mi coche', ['Taller Hermanos Ruiz']],
  ['me duele la cabeza', ['Farmacia del Barrio']], ['pan dulce recién hecho', ['Panadería La Espiga']], ['tacos de canasta en coyoacán', ['Tacos Doña Lupe']],
  ['lavar mi ropa', ['Lavandería La Burbuja']], ['cortarme el pelo', ['Estética Alma']], ['fruta fresca del mercado', ['Frutas y Verduras Jamaica']],
  ['nopales y mole', ['Productos de Milpa Alta']], ['algo para la tienda de la esquina', ['Abarrotes Los Dos Hermanos']],
];
let acierta = 0;
for (const [q, esperados] of CASOS) {
  const r = await fetch(`${BASE}/api/v1/search/agent`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query: q }) }).then((x) => x.json());
  const top = (r.data ?? []).slice(0, 3).map((n) => n.nombre);
  const ok = esperados.some((e) => top.includes(e)); if (ok) acierta++;
  console.log(`${ok ? '✔' : '✘'} ${q.padEnd(36)} ${r.meta?.mode?.padEnd(18)} ${top.join(' | ') || '(sin resultados)'}`);
}
console.log(`\nAcierto en top 3: ${acierta}/${CASOS.length}`);
process.exitCode = acierta === CASOS.length ? 0 : 1;
