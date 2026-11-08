// Demo de "arma tu cuenta" en la landing. Catálogo y precios de muestra.
// ponytail: parser local solo para la demo; en la app el total lo calcula el backend
// (POST /orders/quotes) con el menú vigente. No reutilizar esto para cobrar.

export const NEGOCIOS = [
  { nombre: 'Tacos Doña Lupe', lugar: 'Av. Hidalgo 128, Coyoacán', distancia: '350 m',
    productos: [
      { nombre: 'Taco de canasta', precio: 12, alias: ['taco', 'taco de canasta', 'tacos de canasta', 'canasta'] },
      { nombre: 'Agua de horchata', precio: 25, alias: ['horchata', 'agua de horchata'] },
    ] },
  { nombre: 'Tortillería La Esperanza', lugar: 'Calle Allende 41, Coyoacán', distancia: '600 m',
    productos: [
      { nombre: 'Tortillas de maíz (kilo)', precio: 24, alias: ['tortilla', 'tortillas', 'kilo de tortillas', 'kilo de tortilla'] },
      { nombre: 'Totopos (bolsa)', precio: 30, alias: ['totopo', 'totopos'] },
    ] },
  { nombre: 'Tamales Don Chuy', lugar: 'Calle Tres Cruces 9, Coyoacán', distancia: '900 m',
    productos: [
      { nombre: 'Tamal de rajas', precio: 18, alias: ['tamal de rajas', 'tamales de rajas', 'rajas'] },
      { nombre: 'Tamal verde', precio: 18, alias: ['tamal verde', 'tamales verdes', 'verde'] },
      { nombre: 'Atole de vainilla', precio: 20, alias: ['atole', 'atoles'] },
    ] },
  { nombre: 'Abarrotes Don Beto', lugar: 'Calle Carrillo Puerto 70, Coyoacán', distancia: '450 m',
    productos: [
      { nombre: 'Refresco 600 ml', precio: 22, alias: ['refresco', 'refrescos', 'coca', 'cocas'] },
      { nombre: 'Agua natural 1 l', precio: 15, alias: ['agua natural', 'agua', 'aguas'] },
    ] },
]

const NUMEROS = { un: 1, una: 1, uno: 1, dos: 2, tres: 3, cuatro: 4, cinco: 5, seis: 6, siete: 7,
  ocho: 8, nueve: 9, diez: 10, once: 11, doce: 12, docena: 12, quince: 15, veinte: 20 }

const normal = (t) => t.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/\s+/g, ' ').trim()

// Alias de más largo a más corto: "agua de horchata" gana a "agua"
const ALIAS = NEGOCIOS.flatMap((n) => n.productos.flatMap((p) => p.alias.map((a) => ({ a: normal(a), n, p }))))
  .sort((x, y) => y.a.length - x.a.length)

// Palabras de cortesía antes de la cantidad: "quiero 2 aguas", "dame tres tamales"
const RELLENO = /^(quiero|quisiera|me das|me da|dame|deme|ponme|porfa|por favor|tambien|ademas)\s+/

function cantidadDe(trozo) {
  while (RELLENO.test(trozo)) trozo = trozo.replace(RELLENO, '')
  if (/^media docena\b/.test(trozo)) return [6, trozo.slice(12).trim()]
  const m = trozo.match(/^(\d{1,3}|[a-z]+)\s+(.*)$/)
  if (m && /^\d+$/.test(m[1])) return [Number(m[1]), m[2]]
  if (m && NUMEROS[m[1]]) return [NUMEROS[m[1]], m[2].replace(/^de /, '')]
  return [1, trozo]
}

// "10 tacos de canasta y 2 horchatas" → cuentas agrupadas por negocio, con total en pesos enteros
export function armarCuenta(texto) {
  const cuentas = new Map()
  const sinMatch = []
  for (const crudo of normal(texto).split(/,| y | con /)) {
    if (!crudo.trim()) continue
    const [cantidad, resto] = cantidadDe(crudo.trim())
    const quitarPlural = resto.replace(/(es|s)\b/g, '')
    const hit = ALIAS.find(({ a }) => (` ${resto} `).includes(` ${a} `) || (` ${quitarPlural} `).includes(` ${a.replace(/(es|s)\b/g, '')} `))
    if (!hit || cantidad < 1 || cantidad > 99) { sinMatch.push(crudo.trim()); continue }
    const c = cuentas.get(hit.n) ?? { negocio: hit.n, renglones: [], total: 0 }
    const r = c.renglones.find((x) => x.producto === hit.p)
    if (r) r.cantidad += cantidad
    else c.renglones.push({ producto: hit.p, cantidad })
    cuentas.set(hit.n, c)
  }
  for (const c of cuentas.values()) c.total = c.renglones.reduce((s, r) => s + r.cantidad * r.producto.precio, 0)
  return { cuentas: [...cuentas.values()], sinMatch }
}
