// App web de Barrio: comprador y negocio sobre la API. Todo texto de personas entra como texto (h()), nunca como HTML.
const { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY: KEY, API_URL } = window.BARRIO
const ZONAS = ['Álvaro Obregón', 'Azcapotzalco', 'Benito Juárez', 'Coyoacán', 'Cuajimalpa', 'Cuauhtémoc', 'Gustavo A. Madero', 'Iztacalco', 'Iztapalapa', 'Magdalena Contreras', 'Miguel Hidalgo', 'Milpa Alta', 'Tláhuac', 'Tlalpan', 'Venustiano Carranza', 'Xochimilco']
const ESTADOS = { pendiente: 'Esperando al negocio', aceptada: 'Aceptado', cobrada: 'Falta tu pago', pagada: '✅ ¡Pagado!', lista: 'Listo para recoger', rechazada: 'El negocio no lo aceptó', expirada: 'El negocio no contestó', vencida: 'El cobro venció', cancelada: 'Cancelado' }

const h = (tag, props = {}, ...hijos) => {
  const e = document.createElement(tag)
  for (const [k, v] of Object.entries(props ?? {})) {
    if (k === 'class') e.className = v
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v)
    else if (v !== false && v != null) e.setAttribute(k, v === true ? '' : v)
  }
  e.append(...hijos.flat(9).filter((x) => x != null && x !== false))
  return e
}
const pesos = (m) => '$' + (m / 100).toLocaleString('es-MX', { minimumFractionDigits: m % 100 ? 2 : 0, maximumFractionDigits: 2 })
const $app = document.getElementById('app'), $nav = document.getElementById('nav'), $aviso = document.getElementById('aviso')
let timer = null, avisoT = null
const limpiar = () => { clearInterval(timer); timer = null }
const pantalla = (...nodos) => { limpiar(); $app.replaceChildren(...nodos.flat()); $app.focus() }
function avisar(texto, malo) { $aviso.hidden = false; $aviso.className = malo ? 'aviso malo' : 'aviso'; $aviso.textContent = texto; clearTimeout(avisoT); avisoT = setTimeout(() => { $aviso.hidden = true }, 5000) }
const intentar = (fn) => async (...a) => { try { await fn(...a) } catch (e) { avisar(e.message, true) } }

// ---------- sesión (Supabase Auth por REST) ----------
const SK = 'barrio.sesion'
let sesion = null
try { sesion = JSON.parse(localStorage.getItem(SK)) } catch { /* sin almacenamiento: la sesión dura la pestaña */ }
const guardar = () => { try { sesion ? localStorage.setItem(SK, JSON.stringify(sesion)) : localStorage.removeItem(SK) } catch { /* igual */ } }
async function authRest(ruta, cuerpo, query = '') {
  const r = await fetch(`${SUPABASE_URL}/auth/v1/${ruta}${query}`, { method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' }, body: JSON.stringify(cuerpo) }).catch(() => null)
  if (!r) throw new Error('Sin señal. Revisa tu conexión.')
  return { ok: r.ok, data: await r.json().catch(() => ({})) }
}
function tomar(d) {
  if (!d.access_token) return false
  sesion = { access_token: d.access_token, refresh_token: d.refresh_token, expira: Date.now() + (d.expires_in - 60) * 1000 }
  guardar(); return true
}
async function token() {
  if (!sesion) return null
  if (Date.now() > sesion.expira) {
    const r = await authRest('token', { refresh_token: sesion.refresh_token }, '?grant_type=refresh_token')
    if (!tomar(r.data)) { sesion = null; guardar(); return null }
  }
  return sesion.access_token
}
async function api(metodo, ruta, cuerpo, extra = {}) {
  const t = await token()
  const r = await fetch(`${API_URL}/api/v1${ruta}`, { method: metodo, headers: { 'Content-Type': 'application/json', apikey: KEY, ...(t ? { Authorization: `Bearer ${t}` } : {}), ...extra }, body: cuerpo ? JSON.stringify(cuerpo) : undefined }).catch(() => null)
  if (!r) throw new Error('Sin señal. Revisa tu conexión.')
  const j = await r.json().catch(() => ({}))
  if (!r.ok) throw Object.assign(new Error(j.error?.message ?? 'No pudimos hacerlo. Inténtalo de nuevo en un momento.'), { code: j.error?.code, status: r.status })
  return j.data
}

// ---------- entrada ----------
let yo = null // { comprador, negocio }
async function iniciar() {
  if (!(await token())) return pantallaAuth()
  try { yo = await api('GET', '/me') } catch (e) { if (e.status === 401) { sesion = null; guardar(); return pantallaAuth() } return pantalla(h('p', { class: 'mensaje malo' }, e.message)) }
  yo.negocio ? vistaNegocio('pedidos') : vistaComprador('descubrir')
}
const nav = (items, actual) => $nav.replaceChildren(...items.map(([id, texto, fn]) => h('button', { type: 'button', 'aria-current': id === actual ? 'page' : null, onclick: fn }, texto)), h('button', { type: 'button', onclick: salir }, 'Salir'))
const salir = () => { sesion = null; guardar(); yo = null; pantallaAuth() }

function pantallaAuth(modo = 'entrar') {
  $nav.replaceChildren()
  const f = h('form', { class: 'formulario auth-caja', novalidate: true },
    h('h1', { style: 'font-size:2rem' }, modo === 'entrar' ? 'Entra a Barrio' : 'Crea tu cuenta'),
    modo === 'crear' ? h('label', {}, 'Tu nombre', h('input', { name: 'nombre', autocomplete: 'given-name', maxlength: 80 })) : null,
    h('label', {}, 'Correo', h('input', { name: 'email', type: 'email', autocomplete: 'email', required: true })),
    h('label', {}, 'Contraseña', h('input', { name: 'password', type: 'password', autocomplete: modo === 'entrar' ? 'current-password' : 'new-password', minlength: 8, required: true }), modo === 'crear' ? h('span', { class: 'ayuda' }, 'Mínimo 8 caracteres.') : null),
    h('button', { class: 'btn' }, modo === 'entrar' ? 'Entrar' : 'Crear cuenta'),
    h('button', { type: 'button', class: 'btn btn-texto', onclick: () => pantallaAuth(modo === 'entrar' ? 'crear' : 'entrar') }, modo === 'entrar' ? 'No tengo cuenta' : 'Ya tengo cuenta'),
    h('p', { class: 'ayuda' }, 'Con la misma cuenta pides como comprador o registras tu negocio.'))
  f.addEventListener('submit', intentar(async (e) => {
    e.preventDefault()
    const d = Object.fromEntries(new FormData(f))
    if (!d.email || d.password.length < 8) return avisar('Escribe tu correo y una contraseña de al menos 8 caracteres.', true)
    const r = modo === 'entrar'
      ? await authRest('token', { email: d.email, password: d.password }, '?grant_type=password')
      : await authRest('signup', { email: d.email, password: d.password, data: { nombre: d.nombre ?? '' } }, `?redirect_to=${encodeURIComponent(location.origin + location.pathname)}`)
    if (!r.ok) return avisar(modo === 'entrar' ? 'Correo o contraseña incorrectos.' : (r.data.msg ?? 'No pudimos crear tu cuenta. Revisa los datos.'), true)
    if (!tomar(r.data)) return avisar('Te mandamos un correo para confirmar tu cuenta. Después entra aquí.')
    iniciar()
  }))
  pantalla(f)
}

// ---------- comprador ----------
function menuComprador(actual) {
  nav([['descubrir', 'Descubrir', () => vistaComprador('descubrir')], ['pedidos', 'Mis pedidos', () => vistaComprador('pedidos')], ['avisos', 'Avisos', () => vistaComprador('avisos')], ['perfil', 'Mi perfil', () => vistaComprador('perfil')], ['negocio', 'Tengo un negocio', formNegocio]], actual)
}
const vistaComprador = intentar(async (v) => {
  menuComprador(v)
  if (v === 'descubrir') return descubrir()
  if (v === 'pedidos') return misPedidos()
  if (v === 'avisos') return avisos()
  return perfil()
})

function descubrir() {
  const q = h('input', { type: 'search', placeholder: 'Tacos, pan, farmacia…', 'aria-label': 'Qué buscas' })
  const zona = h('select', { 'aria-label': 'Alcaldía' }, h('option', { value: '' }, 'Toda la ciudad'), ZONAS.map((z) => h('option', {}, z)))
  const lista = h('div', { class: 'rejilla' }), nota = h('p', { class: 'ayuda', role: 'status' })
  const mostrar = (negocios) => lista.replaceChildren(...(negocios.length ? negocios.map(tarjetaNegocio) : [h('p', { class: 'vacio' }, 'No encontramos negocios con eso. Prueba con otra palabra o quita la alcaldía.')]))
  const buscar = intentar(async () => {
    const p = new URLSearchParams({ open_now: 'true' }); if (q.value.trim()) p.set('q', q.value.trim()); if (zona.value) p.set('zone', zona.value)
    nota.textContent = ''; mostrar(await api('GET', `/catalog/search?${p}`))
  })
  const conBarrio = intentar(async () => {
    if (!q.value.trim()) return avisar('Cuéntale a Barrio qué se te antoja.', true)
    const r = await fetch(`${API_URL}/api/v1/search/agent`, { method: 'POST', headers: { 'Content-Type': 'application/json', apikey: KEY, ...(await token() ? { Authorization: `Bearer ${await token()}` } : {}) }, body: JSON.stringify({ query: q.value.trim(), filters: zona.value ? { zone: zona.value } : {} }) })
    const j = await r.json(); if (!r.ok) throw new Error(j.error?.message ?? 'No pudimos buscar ahora.')
    nota.textContent = j.meta?.answer ?? ''; mostrar(j.data)
  })
  q.addEventListener('keydown', (e) => { if (e.key === 'Enter') buscar() })
  pantalla(h('h1', { style: 'font-size:2rem;margin-top:16px' }, 'Qué se te antoja hoy'),
    h('div', { class: 'buscador' }, q, zona),
    h('div', { class: 'barra-btns' }, h('button', { class: 'btn btn-chico', onclick: buscar }, 'Buscar'), h('button', { class: 'btn btn-sec btn-chico', onclick: conBarrio }, 'Buscar con Barrio')),
    nota, lista)
  buscar()
}
const tarjetaNegocio = (n) => h('article', { class: 'tarjeta' },
  h('h3', {}, n.nombre), h('p', {}, h('span', { class: 'chip' }, n.categoria), h('span', { class: 'chip' }, n.zona)),
  h('p', { class: 'ayuda' }, (n.match_reasons ?? []).join(' · ')),
  h('button', { class: 'btn btn-sec btn-chico', onclick: () => verNegocio(n.id) }, 'Ver menú'))

const verNegocio = intentar(async (id) => {
  const n = await api('GET', `/businesses/${id}`)
  const cant = new Map()
  const resumen = h('div')
  const lineas = (n.productos ?? []).map((p) => {
    const out = h('output', {}, '0')
    const poner = (d) => { const c = Math.max(0, Math.min(100, (cant.get(p.nombre) ?? 0) + d)); cant.set(p.nombre, c); out.textContent = c }
    return h('div', { class: 'linea' }, h('div', {}, h('strong', {}, p.nombre), h('br'), h('span', { class: 'monto' }, pesos(Math.round(p.precio * 100)))),
      h('span', { class: 'cant' }, h('button', { type: 'button', 'aria-label': `Quitar ${p.nombre}`, onclick: () => poner(-1) }, '−'), out, h('button', { type: 'button', 'aria-label': `Agregar ${p.nombre}`, onclick: () => poner(1) }, '+')))
  })
  const verCuenta = intentar(async () => {
    const items = [...cant].filter(([, c]) => c > 0).map(([nombre, cantidad]) => ({ nombre, cantidad }))
    if (!items.length) return avisar('Agrega al menos un producto.', true)
    if (!yo.comprador?.telefono) return pedirTelefono(() => verCuenta())
    const c = await api('POST', '/orders/quotes', { business_id: n.id, items })
    resumen.replaceChildren(h('div', { class: 'tarjeta' }, h('h3', {}, 'Tu cuenta'),
      c.items.map((i) => h('p', {}, `${i.cantidad} × ${i.nombre} — `, h('span', { class: 'monto' }, pesos(i.precio_minor * i.cantidad)))),
      c.descuento_minor ? h('p', {}, `${c.coupon?.titulo ?? 'Cupón'}: −`, h('span', { class: 'monto' }, pesos(c.descuento_minor))) : null,
      h('p', { class: 'total' }, 'Total: ', h('span', { class: 'monto' }, pesos(c.total_minor))),
      h('p', { class: 'ayuda' }, `Recoges en ${n.direccion}. Si el negocio acepta, te llega el cobro a tu banco.`),
      h('button', { class: 'btn', onclick: intentar(async () => {
        const o = await api('POST', '/orders', { quote_id: c.quote_id, confirmed_total_minor: c.total_minor }, { 'Idempotency-Key': crypto.randomUUID() })
        vistaPedido(o.id)
      }) }, `Sí, pedir por ${pesos(c.total_minor)}`)))
    resumen.scrollIntoView({ behavior: 'smooth' })
  })
  pantalla(h('button', { class: 'btn btn-texto', onclick: () => vistaComprador('descubrir') }, '← Volver'),
    h('h1', { style: 'font-size:2rem' }, n.nombre), h('p', {}, n.descripcion ?? ''), h('p', { class: 'ayuda' }, `${n.direccion} · ${n.zona}`),
    lineas, h('div', { class: 'acciones' }, h('button', { class: 'btn', onclick: verCuenta }, 'Ver mi cuenta')), resumen)
})

function pedirTelefono(despues) {
  const f = h('form', { class: 'formulario' }, h('h3', {}, 'Tu celular para el cobro'), h('label', {}, 'Celular (10 números, sin +52)', h('input', { name: 'tel', inputmode: 'numeric', maxlength: 14, autocomplete: 'tel-national' })), h('p', { class: 'ayuda' }, 'Con CoDi te llega el cobro a la app de tu banco.'), h('button', { class: 'btn' }, 'Guardar'))
  f.addEventListener('submit', intentar(async (e) => {
    e.preventDefault(); const tel = f.tel.value.replace(/\D/g, '')
    if (tel.length !== 10) return avisar('Tu celular debe tener 10 números, sin +52.', true)
    const c = await api('POST', '/me', { telefono: tel, nombre: yo.comprador?.nombre })
    yo.comprador = { ...yo.comprador, ...c, telefono: tel }; despues()
  }))
  $app.prepend(f); f.scrollIntoView(); f.tel.focus()
}

const vistaPedido = intentar(async (id) => {
  menuComprador('pedidos')
  const caja = h('div'); pantalla(h('button', { class: 'btn btn-texto', onclick: () => vistaComprador('pedidos') }, '← Mis pedidos'), caja)
  const pintar = intentar(async () => {
    const o = await api('GET', `/orders/${id}`)
    const pago = o.estado === 'cobrada' ? await api('GET', `/orders/${id}/payments/current`).catch(() => null) : null
    const o2 = pago?.estado === 'pagado' ? await api('GET', `/orders/${id}`) : o
    const nodos = [h('h1', { style: 'font-size:2rem' }, `Pedido ${o2.id}`), h('p', {}, h('span', { class: `chip ${['pagada', 'lista'].includes(o2.estado) ? 'ok' : ['rechazada', 'expirada', 'vencida', 'cancelada'].includes(o2.estado) ? 'mal' : ''}` }, ESTADOS[o2.estado] ?? o2.estado)),
      o2.items.map((i) => h('p', {}, `${i.cantidad} × ${i.nombre}`)), h('p', { class: 'total' }, 'Total: ', h('span', { class: 'monto' }, pesos(o2.total_minor)))]
    if (o2.estado === 'cobrada' && pago) nodos.push(instruccionesPago(pago))
    if (['pagada', 'lista'].includes(o2.estado)) nodos.push(h('div', { class: 'pagado' }, o2.estado === 'lista' ? 'Tu pedido está listo.' : '✅ ¡Pagado!', h('br'), 'Tu código para recoger:', h('div', { class: 'codigo' }, o2.codigo ?? '')))
    if (o2.estado === 'vencida') nodos.push(h('button', { class: 'btn', onclick: intentar(async () => { await api('POST', `/orders/${id}/payments`); pintar() }) }, 'Mandar otro cobro'))
    if (['pendiente', 'aceptada', 'vencida'].includes(o2.estado)) nodos.push(h('button', { class: 'btn btn-sec', style: 'margin-top:12px', onclick: intentar(async () => { await api('POST', `/orders/${id}/cancel`); pintar() }) }, 'Cancelar pedido'))
    caja.replaceChildren(...nodos)
    if (['lista', 'rechazada', 'expirada', 'cancelada'].includes(o2.estado)) limpiar()
  })
  await pintar(); timer = setInterval(pintar, 4000)
})
function instruccionesPago(p) {
  const seguro = p.link && /^https:\/\//.test(p.link)
  return h('div', { class: 'tarjeta', style: 'margin:12px 0' },
    p.via === 'push' ? [h('h3', {}, 'Te llegó un cobro a tu banco'), h('p', {}, `Ábrelo y apruébalo por ${pesos(p.monto_minor)}. Vence en 15 minutos.`)]
      : p.via === 'link' ? [h('h3', {}, 'Paga con CoDi'), seguro ? h('a', { class: 'btn', href: p.link, target: '_blank', rel: 'noopener noreferrer' }, 'Ir a pagar') : null]
        : [h('h3', {}, 'Escanea con CoDi en la app de tu banco'), p.qr_image ? h('img', { class: 'qr', alt: 'Código QR de CoDi para pagar', src: `data:image/png;base64,${p.qr_image.replace(/[^A-Za-z0-9+/=]/g, '')}` }) : null],
    h('p', { class: 'ayuda' }, 'Cuando pagues, esta pantalla se actualiza sola.'))
}
const misPedidos = async () => {
  const os = await api('GET', '/orders')
  pantalla(h('h1', { style: 'font-size:2rem;margin-top:16px' }, 'Mis pedidos'),
    os.length ? h('div', { class: 'rejilla' }, os.map((o) => h('article', { class: 'tarjeta' }, h('h3', {}, `Pedido ${o.id}`), h('p', {}, h('span', { class: 'chip' }, ESTADOS[o.estado] ?? o.estado)), h('p', { class: 'total' }, h('span', { class: 'monto' }, pesos(o.total_minor))), h('button', { class: 'btn btn-sec btn-chico', onclick: () => vistaPedido(o.id) }, 'Ver')))) : h('p', { class: 'vacio' }, 'Aún no has pedido. Busca algo rico en Descubrir.'))
}
const avisos = async () => {
  const ns = await api('GET', '/me/notifications')
  const responder = (n, accion) => intentar(async () => { await api('POST', `/coupons/${n.cupon_id}/${accion}`); avisar(accion === 'accept' ? 'Listo. Se descuenta solo en tu siguiente pedido.' : 'Cupón descartado.'); avisos() })
  pantalla(h('h1', { style: 'font-size:2rem;margin-top:16px' }, 'Avisos'),
    ns.length ? h('div', { class: 'rejilla' }, ns.map((n) => h('article', { class: 'tarjeta' }, h('h3', {}, n.titulo), n.leida ? h('p', { class: 'ayuda' }, 'Ya respondiste.') : h('div', { class: 'barra-btns' }, h('button', { class: 'btn btn-chico', onclick: responder(n, 'accept') }, 'Aceptar cupón'), h('button', { class: 'btn btn-sec btn-chico', onclick: responder(n, 'decline') }, 'No, gracias'))))) : h('p', { class: 'vacio' }, 'Cuando un negocio donde ya compraste publique un cupón, te avisamos aquí.'))
}
const perfil = async () => {
  const p = await api('GET', '/me/profile')
  pantalla(h('h1', { style: 'font-size:2rem;margin-top:16px' }, p.nombre ? `Hola, ${p.nombre}` : 'Mi perfil'), h('p', {}, `${p.pedidos_pagados} pedido(s) pagado(s). Compra seguido en tu colonia, tu alcaldía o tu negocio favorito y gana insignias.`),
    p.insignias.length ? h('div', { class: 'rejilla' }, p.insignias.map((b) => h('article', { class: 'tarjeta' }, h('h3', {}, b.nombre), h('p', {}, h('span', { class: `chip ${b.obtenida ? 'ok' : ''}` }, b.obtenida ? 'Ganada' : `${b.pedidos_pagados} de ${b.meta}`)), h('div', { class: 'progreso', 'aria-hidden': 'true' }, h('span', { style: `width:${Math.min(100, b.pedidos_pagados / b.meta * 100)}%` }))))) : h('p', { class: 'vacio' }, 'Tus insignias aparecen con tu primer pedido pagado.'))
}

// ---------- negocio ----------
function formNegocio() {
  $nav.replaceChildren(h('button', { type: 'button', onclick: () => vistaComprador('descubrir') }, '← Volver'))
  const filas = h('div'); const fila = (n = '', pr = '') => { const d = h('div', { class: 'fila' }, h('input', { class: 'p-nombre', maxlength: 60, 'aria-label': 'Nombre del producto', placeholder: 'Taco de canasta', value: n }), h('input', { class: 'p-precio', inputmode: 'decimal', 'aria-label': 'Precio en pesos', placeholder: '12', value: pr }), h('button', { type: 'button', class: 'quitar', 'aria-label': 'Quitar este producto', onclick: () => d.remove() }, '×')); filas.append(d) }
  fila(); fila()
  const f = h('form', { class: 'formulario', novalidate: true }, h('h1', { style: 'font-size:2rem' }, 'Registra tu negocio'),
    h('label', {}, 'Nombre del negocio', h('input', { name: 'nombre', maxlength: 60 })),
    h('label', {}, 'Celular del negocio', h('input', { name: 'telefono', inputmode: 'numeric', maxlength: 14 })),
    h('label', {}, 'Alcaldía', h('select', { name: 'zona' }, h('option', { value: '' }, 'Elige tu alcaldía'), ZONAS.map((z) => h('option', {}, z)))),
    h('label', {}, 'Colonia', h('input', { name: 'colonia', maxlength: 80 })),
    h('label', {}, 'Dirección donde te recogen', h('input', { name: 'direccion', maxlength: 200 })),
    h('label', {}, 'Tipo de negocio', h('input', { name: 'categoria', maxlength: 60, placeholder: 'Taquería, panadería, abarrotes…' })),
    h('fieldset', {}, h('legend', {}, 'Tus precios'), filas, h('button', { type: 'button', class: 'btn btn-texto', onclick: () => fila() }, '+ Agregar otro producto')),
    h('label', { class: 'check' }, h('input', { type: 'checkbox', name: 'auto_aceptar' }), h('span', {}, 'Aceptar pedidos en automático')),
    h('button', { class: 'btn' }, 'Registrar mi negocio'))
  f.addEventListener('submit', intentar(async (e) => {
    e.preventDefault(); const d = Object.fromEntries(new FormData(f))
    const productos = [...filas.children].map((r) => ({ nombre: r.querySelector('.p-nombre').value.trim(), precio: Number(r.querySelector('.p-precio').value.replace(/[$\s,]/g, '')) })).filter((p) => p.nombre)
    await api('POST', '/businesses', { ...d, productos, auto_aceptar: !!d.auto_aceptar })
    avisar('Listo. Tu negocio ya está activo y recibe pedidos mientras estés abierto.')
    yo = await api('GET', '/me'); vistaNegocio('pedidos')
  }))
  pantalla(f)
}
const vistaNegocio = intentar(async (v) => {
  nav([['pedidos', 'Pedidos', () => vistaNegocio('pedidos')], ['promos', 'Promociones', () => vistaNegocio('promos')], ['menu', 'Mi menú', () => vistaNegocio('menu')]], v)
  yo = await api('GET', '/me'); const n = yo.negocio
  const cab = [h('h1', { style: 'font-size:2rem;margin-top:16px' }, n.nombre),
    h('div', { class: 'barra-btns' },
      h('button', { class: 'btn btn-chico', onclick: intentar(async () => { await api('PATCH', '/business', { abierto: !n.abierto }); vistaNegocio(v) }) }, n.abierto ? 'Estás abierto · Cerrar' : 'Estás cerrado · Abrir'),
      h('button', { class: 'btn btn-sec btn-chico', onclick: intentar(async () => { await api('PATCH', '/business', { auto_aceptar: !n.auto_aceptar }); vistaNegocio(v) }) }, n.auto_aceptar ? 'Aceptas en automático · Cambiar' : 'Aceptas a mano · Cambiar'))]
  if (v === 'pedidos') return pedidosNegocio(cab)
  if (v === 'promos') return promosNegocio(cab)
  return menuNegocio(cab, n)
})
const pedidosNegocio = async (cab) => {
  const caja = h('div'); pantalla(cab, h('h2', {}, 'Pedidos'), caja)
  const pintar = intentar(async () => {
    const os = (await api('GET', '/orders')).filter((o) => !['cancelada', 'expirada', 'rechazada'].includes(o.estado) || Date.now() - new Date(o.creado) < 36e5)
    const acc = (o, ruta, texto, sec) => h('button', { class: `btn ${sec ? 'btn-sec' : ''} btn-chico`, onclick: intentar(async () => { await api('POST', `/orders/${o.id}/${ruta}`); pintar() }) }, texto)
    caja.replaceChildren(...(os.length ? [h('div', { class: 'rejilla' }, os.map((o) => h('article', { class: 'tarjeta' }, h('h3', {}, `Pedido ${o.id}`), h('p', {}, h('span', { class: 'chip' }, ESTADOS[o.estado] ?? o.estado)), o.items.map((i) => h('p', {}, `${i.cantidad} × ${i.nombre}`)), o.notas ? h('p', { class: 'ayuda' }, `Nota: ${o.notas}`) : null, h('p', { class: 'total' }, h('span', { class: 'monto' }, pesos(o.total_minor))),
      h('div', { class: 'barra-btns' }, o.estado === 'pendiente' ? [acc(o, 'accept', 'Aceptar'), acc(o, 'reject', 'Rechazar', true)] : null, o.estado === 'pagada' ? acc(o, 'ready', 'Marcar listo') : null)))) ] : [h('p', { class: 'vacio' }, 'Cuando alguien te pida, aparece aquí.')]))
  })
  await pintar(); timer = setInterval(pintar, 5000)
}
const promosNegocio = async (cab) => {
  const cs = await api('GET', '/business/coupons')
  const f = h('form', { class: 'formulario', novalidate: true }, h('h3', {}, 'Nuevo cupón'),
    h('p', { class: 'ayuda' }, 'Les avisamos a quienes ya te compraron. Si lo aceptan, se descuenta solo al cobrar.'),
    h('label', {}, 'Título', h('input', { name: 'title', maxlength: 80, placeholder: '10% en tu siguiente pedido' })),
    h('label', {}, 'Tipo', h('select', { name: 'type' }, h('option', { value: 'porcentaje' }, 'Porcentaje'), h('option', { value: 'monto' }, 'Monto en pesos'), h('option', { value: 'producto_gratis' }, 'Producto gratis'))),
    h('label', {}, 'Valor (10 = 10% o $10)', h('input', { name: 'value', inputmode: 'numeric' })),
    h('label', {}, 'Código (opcional)', h('input', { name: 'code', maxlength: 24, placeholder: 'VECINOS10' })),
    h('label', {}, 'Producto gratis (si aplica)', h('input', { name: 'free_product', maxlength: 60, placeholder: 'Agua de horchata' })),
    h('label', {}, 'Compra mínima en pesos (opcional)', h('input', { name: 'min', inputmode: 'numeric' })),
    h('label', {}, 'Vence', h('input', { name: 'vence', type: 'date' })),
    h('button', { class: 'btn' }, 'Publicar cupón'))
  f.addEventListener('submit', intentar(async (e) => {
    e.preventDefault(); const d = Object.fromEntries(new FormData(f))
    const valor = Number(d.value); const fin = new Date(`${d.vence}T23:59:59`)
    const r = await api('POST', '/business/coupons', { title: d.title, type: d.type, value: d.type === 'producto_gratis' ? 1 : d.type === 'monto' ? Math.round(valor * 100) : valor, code: d.code, free_product: d.free_product, min_amount_minor: Math.round(Number(d.min || 0) * 100), expires_at: fin.toISOString() })
    avisar(`Cupón publicado. Avisamos a ${r.notificados} cliente(s).`); promosNegocio(cab)
  }))
  pantalla(cab, h('h2', {}, 'Promociones'), f, h('div', { class: 'rejilla' }, cs.map((c) => h('article', { class: 'tarjeta' }, h('h3', {}, c.titulo), h('p', {}, h('span', { class: `chip ${c.activo ? 'ok' : ''}` }, c.activo ? 'Activo' : 'Apagado'), h('span', { class: 'chip' }, c.tipo === 'porcentaje' ? `${c.valor}%` : pesos(c.valor))), h('p', { class: 'ayuda' }, `Vence ${new Date(c.vence).toLocaleDateString('es-MX')}`), c.activo ? h('button', { class: 'btn btn-sec btn-chico', onclick: intentar(async () => { await api('DELETE', `/business/coupons/${c.id}`); promosNegocio(cab) }) }, 'Apagar') : null))))
}
const menuNegocio = (cab, n) => {
  const filas = h('div'); const fila = (nombre = '', precio = '') => { const d = h('div', { class: 'fila' }, h('input', { class: 'p-nombre', maxlength: 60, 'aria-label': 'Nombre del producto', value: nombre }), h('input', { class: 'p-precio', inputmode: 'decimal', 'aria-label': 'Precio en pesos', value: precio }), h('button', { type: 'button', class: 'quitar', 'aria-label': 'Quitar este producto', onclick: () => d.remove() }, '×')); filas.append(d) }
  ;(n.productos ?? []).forEach((p) => fila(p.nombre, p.precio))
  const f = h('form', { class: 'formulario' }, h('h3', {}, 'Tu menú y precios'), filas, h('button', { type: 'button', class: 'btn btn-texto', onclick: () => fila() }, '+ Agregar otro producto'), h('button', { class: 'btn' }, 'Guardar menú'))
  f.addEventListener('submit', intentar(async (e) => {
    e.preventDefault()
    const productos = [...filas.children].map((r) => ({ nombre: r.querySelector('.p-nombre').value.trim(), precio: Number(r.querySelector('.p-precio').value.replace(/[$\s,]/g, '')) })).filter((p) => p.nombre)
    await api('PATCH', '/business', { productos }); avisar('Menú guardado.')
  }))
  pantalla(cab, h('h2', {}, 'Mi menú'), f)
}

iniciar()
