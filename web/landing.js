import { armarCuenta } from './cuenta.mjs'

const $ = (s) => document.querySelector(s)
const quieto = matchMedia('(prefers-reduced-motion: reduce)').matches

// El botón principal lleva a la app configurada (app.html por defecto)
if (window.BARRIO?.APP_URL) $('#app').href = window.BARRIO.APP_URL

// Arma tu cuenta: lo que escribes se vuelve ticket con total
const entrada = $('#pedido')
const salida = $('#tickets')
const pesos = (n) => '$' + n.toLocaleString('es-MX')

function pintar() {
  const { cuentas, sinMatch } = armarCuenta(entrada.value)
  salida.replaceChildren()
  if (!cuentas.length) {
    const p = document.createElement('p')
    p.className = 'sin-match'
    p.textContent = entrada.value.trim() ? 'No encontré eso por tu zona. Prueba con otra palabra.' : 'Escribe lo que se te antoja.'
    salida.append(p)
    return
  }
  for (const c of cuentas.slice(0, 2)) {
    const t = document.createElement('article')
    t.className = 'ticket'
    t.setAttribute('data-ui', '')
    t.innerHTML = `<header><strong></strong><span class="lugar"></span><span class="abierto">Abierto · <span class="dist"></span></span></header>
      <ul></ul><p class="total"><span>Total</span><span class="monto"></span></p>`
    t.querySelector('strong').textContent = c.negocio.nombre
    t.querySelector('.lugar').textContent = c.negocio.lugar
    t.querySelector('.dist').textContent = c.negocio.distancia
    for (const r of c.renglones) {
      const li = document.createElement('li')
      li.innerHTML = '<span><span class="prod"></span><small></small></span><span class="monto"></span>'
      li.querySelector('.prod').textContent = r.producto.nombre
      li.querySelector('small').textContent = `${r.cantidad} × ${pesos(r.producto.precio)}`
      li.querySelector('.monto').textContent = pesos(r.cantidad * r.producto.precio)
      t.querySelector('ul').append(li)
    }
    t.querySelector('.total .monto').textContent = pesos(c.total)
    salida.append(t)
  }
  if (sinMatch.length) {
    const p = document.createElement('p')
    p.className = 'sin-match'
    p.textContent = `No encontré: ${sinMatch.join(', ')}.`
    salida.append(p)
  }
}

// El titular-campo crece hasta dos renglones y luego achica la letra: nunca recorta lo que escribes.
function ajustar() {
  entrada.style.fontSize = ''
  entrada.style.height = 'auto'
  const max = parseFloat(getComputedStyle(entrada).fontSize)
  const min = Math.min(28, max)
  let t = max
  while (t > min && entrada.scrollHeight > t * 2.3) { t -= 2; entrada.style.fontSize = `${t}px` }
  entrada.style.height = `${entrada.scrollHeight}px`
}

if (entrada) {
  entrada.addEventListener('input', () => {
    if (entrada.value.includes('\n')) entrada.value = entrada.value.replace(/\s*\n\s*/g, ' ') // pegado con saltos
    ajustar(); pintar()
  })
  entrada.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); entrada.blur() } })
  for (const b of document.querySelectorAll('[data-ejemplo]')) {
    b.addEventListener('click', () => { entrada.value = b.dataset.ejemplo; ajustar(); pintar(); entrada.focus() })
  }
  addEventListener('resize', ajustar)
  document.fonts?.ready.then(ajustar)
  ajustar(); pintar()
}

// El changarrito 3D: se carga después de pintar la página y solo si hay WebGL
const lienzo = $('#changarrito')
function cargar3d() {
  const prueba = document.createElement('canvas')
  if (!lienzo || !(prueba.getContext('webgl2') || prueba.getContext('webgl'))) return
  import('./changarrito.js')
    .then(({ montarChangarrito }) => montarChangarrito(lienzo, { quieto }))
    .then(() => lienzo.closest('.escena').classList.add('lista'))
    .catch(() => {}) // se queda el dibujo de respaldo
}
if ('requestIdleCallback' in window) requestIdleCallback(cargar3d, { timeout: 1500 })
else setTimeout(cargar3d, 300)
