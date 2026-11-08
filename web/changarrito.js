// El changarrito de la portada: geometría procedural en Three.js, sin modelos descargados.
// Se monta sobre el dibujo SVG de respaldo y solo dibuja cuando la portada está a la vista.
import * as THREE from 'three'

const C = {
  marino: 0x0B2545, mango: 0xF5A524, mangoOscuro: 0xDB8E12, crema: 0xFFF8EC,
  blanco: 0xFFFFFF, teal: 0x0F7C75, rojo: 0xC2392B, borde: 0xE8DFCF,
}

// Sombreado de cartel: tres tonos planos, sin degradado suave
function rampa() {
  const datos = new Uint8Array([150, 150, 150, 255, 215, 215, 215, 255, 255, 255, 255, 255])
  const t = new THREE.DataTexture(datos, 3, 1, THREE.RGBAFormat)
  t.minFilter = t.magFilter = THREE.NearestFilter
  t.needsUpdate = true
  return t
}

export async function montarChangarrito(lienzo, { quieto = false } = {}) {
  const renderer = new THREE.WebGLRenderer({ canvas: lienzo, antialias: true, alpha: true, powerPreference: 'low-power' })
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2))
  renderer.outputColorSpace = THREE.SRGBColorSpace
  renderer.shadowMap.enabled = true
  renderer.shadowMap.type = THREE.PCFSoftShadowMap

  const escena = new THREE.Scene()
  const camara = new THREE.PerspectiveCamera(28, 1, 0.1, 100)
  const gradiente = rampa()
  const mat = (color) => new THREE.MeshToonMaterial({ color, gradientMap: gradiente })
  const M = Object.fromEntries(Object.entries(C).map(([k, v]) => [k, mat(v)]))

  // Contorno de calcomanía: copia por dentro, en marino, un poco más grande
  const contorno = new THREE.MeshBasicMaterial({ color: C.marino, side: THREE.BackSide })
  const pieza = (geo, material, { x = 0, y = 0, z = 0, borde = 0.025, padre } = {}) => {
    const m = new THREE.Mesh(geo, material)
    m.position.set(x, y, z)
    m.castShadow = true
    m.receiveShadow = true
    if (borde) {
      const o = new THREE.Mesh(geo, contorno)
      geo.computeBoundingBox()
      const s = geo.boundingBox.getSize(new THREE.Vector3())
      o.scale.set(1 + borde / Math.max(s.x, 0.05) * 2, 1 + borde / Math.max(s.y, 0.05) * 2, 1 + borde / Math.max(s.z, 0.05) * 2)
      m.add(o)
    }
    ;(padre ?? carrito).add(m)
    return m
  }

  const carrito = new THREE.Group()
  escena.add(carrito)

  // Caja del puesto: marino con el frente en mango y el rótulo pintado
  const caja = new THREE.BoxGeometry(2.4, 1.05, 1.1)
  pieza(caja, M.marino, { y: 0.95 })
  await document.fonts.load('800 120px Archivo').catch(() => {})
  // Rótulo pintado a mano, como los de las fondas y puestos de CDMX: tablero blanco, letra alta y apretada con bandas de color,
  // contorno blanco y marino, sombra pintada, un dibujo del producto y una estrella roja con el precio.
  const rotulo = document.createElement('canvas')
  rotulo.width = 2048; rotulo.height = 800
  const g = rotulo.getContext('2d')
  let semillaR = 11
  const azarR = () => ((semillaR = (semillaR * 9301 + 49297) % 233280) / 233280 - 0.5)
  const MARINO = '#0B2545', MANGO = '#F5A524', OSCURO = '#DB8E12', ROJO = '#C2392B', BLANCO = '#FFFFFF'
  g.fillStyle = BLANCO; g.fillRect(0, 0, 2048, 800)
  g.strokeStyle = MARINO; g.lineWidth = 24; g.strokeRect(26, 26, 1996, 748)

  // Letra rotulada: cada letra con su pequeña inclinación, como pintada a pulso
  function rotular(texto, x, y, alto, { bandas = null, relleno = MARINO, cond = 0.78, grosor = 0.15, sombra = true, giro = 0 } = {}) {
    g.save(); g.translate(x, y); g.rotate(giro); g.scale(cond, 1)
    g.font = `800 ${alto}px Archivo, sans-serif`; g.textBaseline = 'alphabetic'; g.lineJoin = 'round'
    let cx = 0
    for (const c of texto) {
      const w = g.measureText(c).width
      g.save(); g.translate(cx + w / 2, azarR() * alto * 0.05); g.rotate(azarR() * 0.06); g.translate(-w / 2, 0)
      if (sombra) { g.fillStyle = MARINO; g.fillText(c, alto * 0.05, alto * 0.06) }
      g.strokeStyle = MARINO; g.lineWidth = alto * grosor; g.strokeText(c, 0, 0)
      g.strokeStyle = BLANCO; g.lineWidth = alto * grosor * 0.5; g.strokeText(c, 0, 0)
      if (bandas) {
        const gr = g.createLinearGradient(0, -alto * 0.75, 0, 0)
        bandas.forEach(([p, col]) => { gr.addColorStop(p[0], col); gr.addColorStop(p[1], col) })
        g.fillStyle = gr
      } else g.fillStyle = relleno
      g.fillText(c, 0, 0)
      g.restore()
      cx += w + alto * 0.02
    }
    g.restore()
  }
  // Destello de cuatro puntas, de los que dibujan los rotulistas para dar brillo
  const brillo = (x, y, r) => {
    g.save(); g.translate(x, y); g.fillStyle = BLANCO; g.strokeStyle = MARINO; g.lineWidth = 6; g.beginPath()
    for (let i = 0; i < 8; i++) { const rr = i % 2 ? r * 0.22 : r; const t = (i * Math.PI) / 4; g.lineTo(Math.cos(t) * rr, Math.sin(t) * rr) }
    g.closePath(); g.fill(); g.stroke(); g.restore()
  }

  // 1. nombre del negocio, en cursiva roja arriba
  g.save(); g.transform(1, 0, -0.18, 1, 0, 0)
  rotular('doña lupe', 150, 190, 140, { relleno: ROJO, cond: 0.9, grosor: 0.12, giro: -0.02 })
  g.restore()
  // 2. palabra grande con bandas de fuego: mango, oscuro y rojo
  rotular('TACOS', 78, 470, 310, { bandas: [[[0, 0.34], MANGO], [[0.34, 0.66], OSCURO], [[0.66, 1], ROJO]], cond: 0.74, grosor: 0.12 })
  // 3. renglón de abajo
  rotular('DE CANASTA', 96, 590, 112, { relleno: MARINO, cond: 0.8, grosor: 0.10, sombra: false })
  brillo(1010, 130, 50); brillo(1130, 330, 34); brillo(520, 235, 26)

  // 4. dibujo: canasta con manta y tacos asomando
  const trazo = (relleno) => { g.fillStyle = relleno; g.fill(); g.lineWidth = 14; g.strokeStyle = MARINO; g.lineJoin = 'round'; g.stroke() }
  g.beginPath(); g.moveTo(1300, 470); g.lineTo(1860, 470); g.lineTo(1790, 700); g.lineTo(1370, 700); g.closePath(); trazo(OSCURO)
  g.lineWidth = 8; g.strokeStyle = MARINO
  for (let i = 1; i < 6; i++) { g.beginPath(); g.moveTo(1300 + i * 93 - 10 + (i < 3 ? 12 : 0), 478); g.lineTo(1372 + i * 70, 694); g.stroke() }
  for (const [cx, rot] of [[1450, -0.25], [1640, 0.05], [1790, 0.3]]) {         // tacos: medias lunas de mango con relleno
    g.save(); g.translate(cx, 440); g.rotate(rot)
    g.beginPath(); g.arc(0, 0, 110, Math.PI, 0); g.closePath(); trazo(MANGO)
    g.fillStyle = '#0F7C75'; for (const dx of [-60, -20, 25, 62]) { g.beginPath(); g.arc(dx, -22 - Math.abs(dx) * 0.12, 13, 0, Math.PI * 2); g.fill() }
    g.fillStyle = ROJO; for (const dx of [-35, 40]) { g.beginPath(); g.arc(dx, -52, 11, 0, Math.PI * 2); g.fill() }
    g.restore()
  }
  g.beginPath(); g.moveTo(1270, 520); g.quadraticCurveTo(1580, 400, 1890, 520); g.lineTo(1880, 560); g.quadraticCurveTo(1580, 470, 1280, 560); g.closePath(); trazo(BLANCO)   // manta
  // 5. estrella roja con el precio
  g.save(); g.translate(1780, 205); g.beginPath()
  for (let i = 0; i < 24; i++) { const rr = i % 2 ? 108 : 168; const t = (i * Math.PI) / 12 - Math.PI / 2; g.lineTo(Math.cos(t) * rr, Math.sin(t) * rr) }
  g.closePath(); g.fillStyle = ROJO; g.fill(); g.lineWidth = 12; g.strokeStyle = MARINO; g.lineJoin = 'round'; g.stroke()
  g.fillStyle = BLANCO; g.textAlign = 'center'; g.font = '800 130px Archivo, sans-serif'; g.fillText('$12', 0, 38)
  g.restore()
  const texRotulo = new THREE.CanvasTexture(rotulo)
  texRotulo.colorSpace = THREE.SRGBColorSpace
  texRotulo.anisotropy = 8
  const frente = new THREE.Mesh(new THREE.PlaneGeometry(2.2, 0.86), new THREE.MeshToonMaterial({ map: texRotulo, gradientMap: gradiente }))
  frente.position.set(0, 0.95, 0.556)
  carrito.add(frente)

  // Mostrador de lámina blanca
  pieza(new THREE.BoxGeometry(2.6, 0.08, 1.3), M.blanco, { y: 1.52 })

  // Ruedas: llanta blanca lisa con tapa mango, contorno marino
  const llanta = new THREE.CylinderGeometry(0.36, 0.36, 0.13, 40)
  llanta.rotateX(Math.PI / 2)
  for (const z of [-0.62, 0.62]) {
    pieza(llanta, M.blanco, { x: -0.7, y: 0.37, z, borde: 0.03 })
    pieza(new THREE.CylinderGeometry(0.13, 0.13, 0.17, 24).rotateX(Math.PI / 2), M.mango, { x: -0.7, y: 0.37, z, borde: 0.02 })
    // aro del rin en marino (una sola línea, sin rayos)
    for (const dz of [-0.067, 0.067]) {
      const aro = new THREE.Mesh(new THREE.TorusGeometry(0.25, 0.018, 8, 40), contorno)
      aro.position.set(-0.7, 0.37, z + dz)
      carrito.add(aro)
    }
  }
  pieza(new THREE.BoxGeometry(0.1, 0.42, 0.1), M.marino, { x: 1.0, y: 0.21, z: 0.4 })
  pieza(new THREE.BoxGeometry(0.1, 0.42, 0.1), M.marino, { x: 1.0, y: 0.21, z: -0.4 })
  pieza(new THREE.CylinderGeometry(0.035, 0.035, 0.9, 12).rotateZ(Math.PI / 2), M.marino, { x: 1.55, y: 1.25, z: 0.3, borde: 0 })
  pieza(new THREE.CylinderGeometry(0.035, 0.035, 0.9, 12).rotateZ(Math.PI / 2), M.marino, { x: 1.55, y: 1.25, z: -0.3, borde: 0 })

  // Postes del toldo
  const poste = new THREE.CylinderGeometry(0.04, 0.04, 1.55, 12)
  for (const [x, z] of [[-1.15, 0.55], [1.15, 0.55], [-1.15, -0.55], [1.15, -0.55]]) pieza(poste, M.marino, { x, y: 2.3, z, borde: 0 })

  // Toldo: franjas mango y blanco, inclinado hacia el frente, con faldón ondulado
  const toldo = new THREE.Group()
  toldo.position.set(0, 3.1, 0.05)
  toldo.rotation.x = 0.32
  carrito.add(toldo)
  const franjas = 8, ancho = 2.9 / franjas
  for (let i = 0; i < franjas; i++) {
    const color = i % 2 ? M.blanco : M.mango
    pieza(new THREE.BoxGeometry(ancho + 0.002, 0.05, 1.6), color, { x: -1.45 + ancho / 2 + i * ancho, padre: toldo, borde: 0 })
    const ola = new THREE.CylinderGeometry(ancho / 2, ancho / 2, 0.05, 24, 1, false, 0, Math.PI)
    ola.rotateX(Math.PI / 2).rotateZ(Math.PI)
    pieza(new THREE.BoxGeometry(ancho + 0.002, 0.2, 0.04), color, { x: -1.45 + ancho / 2 + i * ancho, y: -0.1, z: 0.8, padre: toldo, borde: 0 })
    pieza(ola, color, { x: -1.45 + ancho / 2 + i * ancho, y: -0.2, z: 0.8, padre: toldo, borde: 0 })
  }
  const filo = new THREE.Mesh(new THREE.BoxGeometry(2.96, 0.03, 1.66), contorno)
  filo.position.y = -0.02
  toldo.add(filo)

  // Sobre el mostrador: canasta con manta, jarra de horchata, refrescos y el letrero de cobro
  const sobre = 1.56
  pieza(new THREE.CylinderGeometry(0.42, 0.32, 0.42, 28), M.mangoOscuro, { x: -0.65, y: sobre + 0.21 })
  pieza(new THREE.SphereGeometry(0.4, 24, 12, 0, Math.PI * 2, 0, Math.PI / 2).scale(1, 0.45, 1), M.blanco, { x: -0.65, y: sobre + 0.41, borde: 0.02 })
  pieza(new THREE.TorusGeometry(0.42, 0.03, 8, 32).rotateX(Math.PI / 2), M.marino, { x: -0.65, y: sobre + 0.42, borde: 0 })

  pieza(new THREE.CylinderGeometry(0.2, 0.2, 0.6, 24), M.blanco, { x: 0.15, y: sobre + 0.3 })
  pieza(new THREE.CylinderGeometry(0.21, 0.21, 0.07, 24), M.marino, { x: 0.15, y: sobre + 0.63, borde: 0 })

  for (const [i, x] of [0.62, 0.8, 0.98].entries()) {
    const z = i === 1 ? -0.18 : 0.08
    pieza(new THREE.CylinderGeometry(0.075, 0.08, 0.4, 16), M.teal, { x, y: sobre + 0.2, z, borde: 0.018 })
    pieza(new THREE.CylinderGeometry(0.035, 0.06, 0.12, 12), M.teal, { x, y: sobre + 0.46, z, borde: 0 })
    pieza(new THREE.CylinderGeometry(0.04, 0.04, 0.04, 12), M.rojo, { x, y: sobre + 0.54, z, borde: 0 })
  }

  // Letrero "paga con CoDi": un patrón tipo QR genérico (no es un código real)
  const qr = document.createElement('canvas')
  qr.width = qr.height = 256
  const q = qr.getContext('2d')
  q.fillStyle = '#FFFFFF'; q.fillRect(0, 0, 256, 256)
  q.fillStyle = '#0B2545'
  let semilla = 7
  const azar = () => ((semilla = (semilla * 9301 + 49297) % 233280) / 233280)
  for (let y = 0; y < 21; y++) for (let x = 0; x < 21; x++) if (azar() > 0.55) q.fillRect(23 + x * 10, 23 + y * 10, 10, 10)
  for (const [x, y] of [[23, 23], [163, 23], [23, 163]]) {
    q.fillRect(x, y, 70, 70); q.fillStyle = '#FFFFFF'; q.fillRect(x + 10, y + 10, 50, 50)
    q.fillStyle = '#0B2545'; q.fillRect(x + 20, y + 20, 30, 30)
  }
  const texQr = new THREE.CanvasTexture(qr)
  texQr.colorSpace = THREE.SRGBColorSpace
  texQr.magFilter = THREE.NearestFilter
  const letrero = new THREE.Group()
  letrero.position.set(1.0, sobre, -0.35)
  letrero.rotation.y = -0.35
  carrito.add(letrero)
  pieza(new THREE.BoxGeometry(0.5, 0.62, 0.04), M.marino, { y: 0.31, padre: letrero, borde: 0 })
  const cara = new THREE.Mesh(new THREE.PlaneGeometry(0.42, 0.42), new THREE.MeshBasicMaterial({ map: texQr }))
  cara.position.set(0, 0.36, 0.021)
  letrero.add(cara)

  // Luz: cielo crema, rebote marino y un sol de mediodía que deja sombra de contacto
  escena.add(new THREE.HemisphereLight(C.crema, C.marino, 1.6))
  const sol = new THREE.DirectionalLight(0xffffff, 2.2)
  sol.position.set(3, 6, 4)
  sol.castShadow = true
  sol.shadow.mapSize.set(1024, 1024)
  Object.assign(sol.shadow.camera, { left: -5, right: 5, top: 5, bottom: -5, near: 1, far: 20 })
  sol.shadow.radius = 4
  escena.add(sol)
  const piso = new THREE.Mesh(new THREE.PlaneGeometry(12, 12), new THREE.ShadowMaterial({ color: C.marino, opacity: 0.3 }))
  piso.rotation.x = -Math.PI / 2
  piso.receiveShadow = true
  escena.add(piso)

  carrito.position.y = 0
  carrito.rotation.y = -0.55

  // Cámara y tamaño
  const ajustar = () => {
    const { width, height } = lienzo.getBoundingClientRect()
    if (!width || !height) return
    renderer.setSize(width, height, false)
    camara.aspect = width / height
    // Encuadre que no corta el toldo en pantallas angostas
    const d = Math.max(10, 2.7 / (Math.tan(THREE.MathUtils.degToRad(camara.fov / 2)) * camara.aspect))
    camara.position.set(0, 2.8, d)
    camara.lookAt(0, 1.75, 0)
    camara.updateProjectionMatrix()
  }
  new ResizeObserver(ajustar).observe(lienzo)
  ajustar()

  // Movimiento: el puesto gira con el scroll (parallax) y se inclina hacia el dedo o el cursor
  let avance = 0, apuntar = 0, giro = -0.55, inclina = 0, visible = true, pidio = false
  const portada = lienzo.closest('section') ?? document.body
  const leerScroll = () => {
    const r = portada.getBoundingClientRect()
    avance = Math.min(1, Math.max(0, -r.top / Math.max(1, r.height)))
    pedir()
  }
  addEventListener('scroll', leerScroll, { passive: true })
  if (!quieto) {
    addEventListener('pointermove', (e) => { apuntar = (e.clientX / innerWidth - 0.5); pedir() }, { passive: true })
  }
  new IntersectionObserver(([e]) => { visible = e.isIntersecting; pedir() }).observe(lienzo)

  function cuadro() {
    pidio = false
    const meta = quieto ? -0.55 : -0.55 + avance * 0.9 + apuntar * 0.25
    giro += (meta - giro) * 0.08
    inclina += ((quieto ? 0 : apuntar * 0.06) - inclina) * 0.08
    carrito.rotation.y = giro
    carrito.rotation.z = inclina * 0.3
    camara.position.y = 2.8 - avance * 0.9
    camara.lookAt(0, 1.75 - avance * 0.4, 0)
    renderer.render(escena, camara)
    if (Math.abs(meta - giro) > 0.0005) pedir() // dibuja solo mientras algo se mueve
  }
  function pedir() {
    if (pidio || !visible || document.hidden) return
    pidio = true
    requestAnimationFrame(cuadro)
  }
  document.addEventListener('visibilitychange', pedir)
  leerScroll()
  cuadro()
}
