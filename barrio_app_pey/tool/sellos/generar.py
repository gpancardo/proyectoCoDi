#!/usr/bin/env python3
"""Genera los sellos de logros en PNG. Uso: python3 tool/sellos/generar.py [salida]

Una tinta por sello, fondo transparente. Estilo: sello estampado + trazo de códice.
Reglas y significado de cada motivo en docs/LOGROS.md.
Necesita google-chrome (solo para rasterizar el SVG) y Pillow.
"""
import math
import os
import subprocess
import sys
import tempfile

from PIL import Image

LADO = 320  # 88 dp a 3x con margen
TINTAS = {'grana': '#9B1B4B', 'bronce': '#9A5B2A', 'plata': '#66727F', 'oro': '#AD7B00'}
W, K = '#fff', '#000'  # en la máscara: blanco = tinta, negro = hueco


def path(d, c=W):
    return f'<path d="{d}" fill="{c}"/>'


def linea(d, w=14, c=W):
    return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'


def circulo(x, y, r, c=W):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'


def elipse(x, y, rx, ry, rot=0, c=W):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{c}" transform="rotate({rot} {x} {y})"/>'


def caja(x, y, w, h, r=0, c=W):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{c}"/>'


def grupo(transform, *piezas):
    return f'<g transform="{transform}">{"".join(piezas)}</g>'


def agua(y, x0=120, x1=392, w=14, paso=68, alto=20, c=W):
    """Oleaje de códice: una línea de ondas redondas."""
    d = f'M{x0} {y}'
    x = x0
    while x < x1:
        d += f' q{paso / 4} {-alto} {paso / 2} 0 t{paso / 2} 0'
        x += paso
    return linea(d, w, c)


def cerro(x, y, a, h, c=W):
    """Cerro de topónimo: campana con base curvada; (x, y) es el centro de la base."""
    m = a / 2
    return path(
        f'M{x - m} {y} C{x - m} {y - h * .12} {x - m * .68} {y - h * .1} {x - m * .62} {y - h * .3} '
        f'C{x - m * .5} {y - h * .7} {x - m * .34} {y - h} {x} {y - h} '
        f'C{x + m * .34} {y - h} {x + m * .5} {y - h * .7} {x + m * .62} {y - h * .3} '
        f'C{x + m * .68} {y - h * .1} {x + m} {y - h * .12} {x + m} {y} Z', c)


def pie(x, y, rot, s=1, c=W, espejo=False):
    dedos = ''.join(circulo(a, b, r, c) for a, b, r in [(-27, -71, 13), (-5, -80, 10), (12, -78, 9), (27, -71, 8), (39, -59, 7)])
    planta = path('M-30 -38 C-38 -66 38 -68 36 -32 C34 -8 18 6 20 34 C22 70 -24 72 -24 34 C-22 8 -24 -14 -30 -38Z', c)
    return grupo(f'translate({x} {y}) rotate({rot}) scale({-s if espejo else s} {s})', planta, dedos)


def casa(x, y, s=1, c=W, hueco=K):
    """Casa de códice: muros, puerta y dintel escalonado. (x, y) es el centro de la base."""
    return grupo(f'translate({x} {y}) scale({s})',
                 caja(-70, -112, 140, 112, 0, c), caja(-92, -142, 184, 36, 6, c), caja(-60, -172, 120, 34, 6, c),
                 caja(-30, -84, 60, 96, 0, hueco))


# ---------------- motivos: cada uno dibuja dentro del círculo interior ----------------

def primera():
    return pie(182, 352, 16, .82) + pie(300, 268, 16, .82, W, True) + pie(214, 150, 16, .82)


def bronce():
    return casa(226, 408, 1.42) + linea('M356 206 C402 188 424 138 390 108 C360 84 318 108 334 142 C344 164 374 154 368 134', 22)


def plata():
    return (cerro(256, 396, 340, 262)
            + grupo('translate(256 290) scale(.46)', casa(0, 0, 1, K, W))
            + grupo('translate(190 370) scale(.46)', casa(0, 0, 1, K, W))
            + grupo('translate(322 370) scale(.46)', casa(0, 0, 1, K, W))
            + linea('M256 134 C256 104 292 96 300 118', 18))


def oro():
    martillo = grupo('translate(182 180) rotate(-45) scale(.84)', caja(-11, -48, 22, 104, 8), caja(-46, -74, 92, 44, 8))
    libro = grupo('translate(332 184) scale(.84)', path('M-62 -44 L0 -30 L62 -44 L62 42 L0 56 L-62 42 Z'), linea('M0 -30 L0 56', 9, K), linea('M-44 -18 L-16 -12 M-44 6 L-16 12 M44 -18 L16 -12 M44 6 L16 12', 7, K))
    flor = ''.join(grupo(f'rotate({g} 182 332)', elipse(182, 301, 17, 28)) for g in range(0, 360, 60)) + circulo(182, 332, 21, K) + circulo(182, 332, 12)
    canasta = grupo('translate(332 330) scale(.84)', linea('M-44 -14 C-40 -74 40 -74 44 -14', 13), path('M-66 -16 L66 -16 L50 56 L-50 56 Z'), linea('M-58 12 L58 12 M-26 -16 L-20 56 M26 -16 L20 56', 8, K))
    return linea('M256 92 L256 420 M92 256 L420 256', 16) + martillo + libro + flor + canasta


def azcapotzalco():
    patas = ''.join(linea(d, 15) for d in [
        'M236 232 L170 196 L136 134', 'M276 232 L342 196 L376 134',
        'M232 262 L150 262 L102 236', 'M280 262 L362 262 L410 236',
        'M236 292 L172 348 L150 410', 'M276 292 L340 348 L362 410'])
    antenas = linea('M240 138 C224 106 192 104 170 92', 12) + linea('M272 138 C288 106 320 104 342 92', 12)
    return patas + antenas + elipse(256, 156, 46, 42) + elipse(256, 248, 32, 54) + elipse(256, 354, 60, 74) + circulo(238, 148, 9, K) + circulo(274, 148, 9, K) + linea('M204 342 L308 342 M212 376 L300 376', 9, K)


def coyoacan():
    cabeza = path('M138 416 C136 340 150 282 196 240 L176 118 L250 172 L322 112 L322 200 C344 216 390 234 430 262 C442 272 438 292 420 296 L340 306 C332 346 332 386 340 416 Z')
    return (cabeza + path('M204 150 L212 206 L240 186 Z', K) + path('M300 150 L300 200 L272 186 Z', K)
            + circulo(292, 244, 26, K) + circulo(292, 244, 13) + linea('M430 296 C396 318 366 322 340 316', 10, K)
            + linea('M176 300 C168 340 168 372 174 402 M224 312 C216 346 216 376 222 402 M272 330 C268 356 268 382 272 402', 13, K))


def benito_juarez():
    astas = linea('M228 196 C204 150 176 128 132 112 M186 142 C186 116 178 96 164 82 M162 128 C146 126 124 138 108 160', 17) + linea('M274 192 C300 146 336 128 380 112 M326 140 C326 114 334 96 348 82 M350 126 C366 124 388 136 404 158', 17)
    cabeza = path('M204 210 C226 186 286 186 308 210 C326 240 316 284 302 326 C298 372 288 404 256 414 C224 404 214 372 210 326 C196 284 186 240 204 210 Z')
    orejas = elipse(168, 226, 48, 22, 22) + elipse(344, 226, 48, 22, -22)
    return astas + orejas + cabeza + circulo(224, 258, 17, K) + circulo(224, 258, 8) + circulo(288, 258, 17, K) + circulo(288, 258, 8) + elipse(256, 384, 24, 15, 0, K) + linea('M256 306 L256 362', 10, K)


def cuajimalpa():
    tronco = circulo(196, 318, 96) + linea('M196 318 m-64 0 a64 64 0 1 0 128 0 a64 64 0 1 0 -128 0', 11, K) + linea('M196 318 m-34 0 a34 34 0 1 0 68 0 a34 34 0 1 0 -68 0', 11, K) + circulo(196, 318, 10, K)
    cabeza = path('M8 -120 C52 -112 84 -138 98 -166 C120 -118 120 -46 98 2 C84 -26 52 -50 8 -46 Z') + path('M-8 -120 C-34 -116 -54 -130 -64 -146 C-76 -116 -76 -76 -64 -46 C-54 -60 -34 -52 -8 -46 Z')
    hacha = grupo('translate(286 242) rotate(36) scale(.88)', caja(-34, -150, 68, 340, 0, K), caja(-14, -144, 28, 322, 13), cabeza)
    astillas = path('M92 196 L146 176 L132 232 Z') + path('M340 392 L392 366 L388 420 Z')
    return tronco + hacha + astillas


def cuauhtemoc():
    ala = ''.join(grupo(f'rotate({g} 240 186)', caja(92, 171, 150, 30, 15)) for g in (40, 27, 14, 1, -12, -25)) + elipse(192, 178, 56, 40, 8)
    alas = ala + grupo('translate(512 0) scale(-1 1)', ala)
    cola = ''.join(grupo(f'rotate({g} 256 186)', caja(242, 84, 28, 110, 14)) for g in (-20, 0, 20))
    cuerpo = path('M220 170 C232 150 280 150 292 170 C304 232 296 290 284 330 C296 362 288 394 262 420 C254 428 244 420 248 410 C224 392 216 362 228 330 C216 290 208 232 220 170 Z')
    return cola + alas + cuerpo + circulo(244, 354, 14, K) + circulo(244, 354, 6) + linea('M286 378 C276 392 264 402 252 406', 9, K) + linea('M256 190 L256 300', 9, K)


def gustavo_a_madero():
    puntos = ''.join(circulo(x, 366, 12, K) for x in (190, 223, 256, 289, 322))
    return grupo('translate(0 -10)', cerro(150, 402, 204, 180), cerro(362, 402, 204, 180), cerro(256, 402, 262, 290, K), cerro(256, 402, 232, 268), linea('M256 136 C256 106 292 98 300 120', 18), puntos, linea('M196 322 C226 306 286 306 316 322', 12, K))


def iztacalco():
    sal = ''.join(path(f'M{x} {y - 16} L{x + 16} {y} L{x} {y + 16} L{x - 16} {y} Z') for x, y in [(256, 98), (222, 132), (290, 132), (188, 166), (256, 166), (324, 166)])
    return casa(256, 416, 1.36) + sal


def iztapalapa():
    lajas = caja(142, 124, 228, 48, 12) + caja(106, 186, 300, 50, 12) + caja(160, 250, 192, 46, 12) + linea('M204 124 L190 172 M314 124 L300 172 M178 186 L168 236 M270 186 L260 236 M350 186 L340 236 M254 250 L244 296', 10, K)
    return lajas + agua(336, 118, 380, 17) + agua(376, 136, 362, 17) + agua(412, 176, 330, 14)


def magdalena_contreras():
    dientes = ''.join(grupo(f'rotate({g} 256 212)', caja(232, 76, 48, 48, 8)) for g in range(0, 360, 36))
    engrane = dientes + circulo(256, 212, 112) + circulo(256, 212, 58, K) + circulo(256, 212, 28)
    radios = ''.join(grupo(f'rotate({g} 256 212)', caja(246, 118, 20, 40, 2, K)) for g in range(0, 360, 60))
    return engrane + radios + agua(376, 118, 380, 19) + agua(416, 166, 332, 16)


def miguel_hidalgo():
    cuerpo = path('M130 236 C142 190 214 170 282 182 C334 192 388 218 392 244 C394 260 368 268 326 266 C252 264 166 270 142 262 C130 258 126 250 130 236 Z')
    muslo = path('M238 232 L166 122 C156 106 130 114 134 134 L170 252 Z')
    espinilla = linea('M144 124 L88 226', 17) + linea('M88 226 L66 232', 13)
    delante = linea('M316 262 L334 312 M272 262 L262 314', 15)
    antena = linea('M372 208 C392 176 410 164 426 160', 11)
    return cerro(256, 414, 300, 98) + linea('M176 396 C212 378 300 378 336 396', 12, K) + espinilla + muslo + cuerpo + linea('M192 196 L192 258 M238 186 L238 260 M284 188 L284 262', 9, K) + circulo(358, 230, 15, K) + circulo(358, 230, 7) + delante + antena


def milpa_alta():
    pencas = elipse(256, 300, 88, 112) + elipse(150, 196, 56, 76, -32) + elipse(362, 196, 56, 76, 32) + elipse(256, 132, 44, 58)
    espinas = ''.join(linea(f'M{x - 8} {y - 8} L{x + 8} {y + 8} M{x + 8} {y - 8} L{x - 8} {y + 8}', 7, K) for x, y in [(256, 244), (216, 294), (296, 294), (256, 346), (150, 196), (362, 196), (256, 132)])
    tunas = elipse(118, 118, 22, 28, -28) + elipse(394, 118, 22, 28, 28)
    return grupo('translate(256 262) scale(.9) translate(-256 -262)', pencas, espinas, tunas, caja(138, 404, 236, 18, 9))


def tlahuac():
    casco = path('M104 288 C176 310 336 310 408 288 C396 342 344 366 256 366 C168 366 116 342 104 288 Z')
    garrocha = linea('M196 334 L338 88', 15)
    tules = ''.join(linea(f'M{x} 312 C{x} 262 {x + d} 214 {x + 2 * d} 180', 12) + elipse(x + 2 * d, 168, 11, 30, d * 2) for x, d in [(132, -6), (164, 3), (382, 6), (350, -3)])
    return grupo('translate(0 -16)', tules, garrocha, casco, linea('M144 316 C216 332 296 332 368 316', 9, K), agua(392, 116, 378, 17), agua(430, 180, 320, 14))


def tlalpan():
    return pie(256, 256, 0, 1.68) + linea('M124 378 C176 352 214 398 256 372 C298 398 336 352 388 378', 17) + linea('M148 416 C188 396 220 428 256 408 C292 428 324 396 364 416', 15)


def venustiano_carranza():
    platillo = lambda x: linea(f'M{x - 56} 280 L{x} 150 L{x + 56} 280', 9) + path(f'M{x - 74} 276 L{x + 74} 276 C{x + 66} 332 {x - 66} 332 {x - 74} 276 Z')
    return (caja(244, 112, 24, 276, 6) + caja(112, 134, 288, 24, 12) + circulo(256, 118, 24) + circulo(256, 118, 10, K) + platillo(144) + platillo(368)
            + path('M186 416 C186 386 326 386 326 416 Z') + caja(170, 408, 172, 18, 9))


def xochimilco():
    petalos = ''.join(grupo(f'rotate({g} 256 226)', elipse(256, 150, 36, 64)) for g in range(0, 360, 45))
    centro = circulo(256, 226, 52, K) + circulo(256, 226, 36) + circulo(256, 226, 13, K)
    return petalos + centro + caja(112, 366, 288, 24, 8) + linea('M170 366 L170 390 M256 366 L256 390 M342 366 L342 390', 9, K) + agua(420, 158, 354, 14)


def cdmx():
    rayos = ''.join(grupo(f'rotate({g * 22.5} 256 256)', path('M238 148 C238 108 274 108 274 148 L268 196 L244 196 Z')) for g in range(16))
    aro = linea('M256 256 m-66 0 a66 66 0 1 0 132 0 a66 66 0 1 0 -132 0', 13)
    centro = caja(216, 216, 80, 80, 6) + caja(238, 196, 36, 120, 4) + caja(196, 238, 120, 36, 4) + circulo(256, 256, 17, K)
    return rayos + aro + centro


# ---------------- marco ----------------

def marco(tinta):
    dientes = ''.join(circulo(round(256 + 232 * math.cos(2 * math.pi * i / 28), 2), round(256 + 232 * math.sin(2 * math.pi * i / 28), 2), 21) for i in range(28))
    s = circulo(256, 256, 232) + dientes + circulo(256, 256, 200, K)
    if tinta in ('plata', 'oro'):  # no depende solo del color: la plata lleva doble anillo
        s += linea('M256 256 m-186 0 a186 186 0 1 0 372 0 a186 186 0 1 0 -372 0', 6)
    if tinta == 'oro':  # y el oro, además, los 16 puntos de la cuenta
        s += ''.join(circulo(round(256 + 218 * math.cos(2 * math.pi * i / 16), 2), round(256 + 218 * math.sin(2 * math.pi * i / 16), 2), 7, K) for i in range(16))
    return s


def svg(motivo, tinta):
    interior = grupo('translate(256 256) scale(.84) translate(-256 -256)', motivo)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{LADO}" height="{LADO}" viewBox="0 0 512 512">'
            '<mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="512" height="512" style="mask-type:luminance">'
            f'<rect width="512" height="512" fill="#000"/>{marco(tinta)}{interior}</mask>'
            f'<rect width="512" height="512" fill="{TINTAS[tinta]}" mask="url(#m)"/></svg>')


ALCALDIAS = {
    'alvaro-obregon': None, 'azcapotzalco': azcapotzalco, 'benito-juarez': benito_juarez, 'coyoacan': coyoacan,
    'cuajimalpa': cuajimalpa, 'cuauhtemoc': cuauhtemoc, 'gustavo-a-madero': gustavo_a_madero, 'iztacalco': iztacalco,
    'iztapalapa': iztapalapa, 'magdalena-contreras': magdalena_contreras, 'miguel-hidalgo': miguel_hidalgo,
    'milpa-alta': milpa_alta, 'tlahuac': tlahuac, 'tlalpan': tlalpan, 'venustiano-carranza': venustiano_carranza,
    'xochimilco': xochimilco,
}


def alvaro_obregon():
    izquierda = path('M104 150 L176 150 L176 212 L216 212 L216 288 L240 288 L240 388 L104 388 Z')
    derecha = path('M408 118 L340 118 L340 186 L302 186 L302 262 L272 262 L272 388 L408 388 Z')
    return izquierda + derecha + linea('M216 250 L132 250 M240 330 L128 330 M302 226 L380 226 M272 320 L384 320', 10, K) + agua(418, 136, 360, 17)


ALCALDIAS['alvaro-obregon'] = alvaro_obregon


def trabajos():
    yield 'primera', primera, 'grana'
    yield 'bronce', bronce, 'bronce'
    yield 'plata', plata, 'plata'
    yield 'oro', oro, 'oro'
    for nivel in ('bronce', 'plata', 'oro'):
        yield f'cdmx-{nivel}', cdmx, nivel
        for nombre, motivo in ALCALDIAS.items():
            yield f'alcaldia-{nombre}-{nivel}', motivo, nivel


def main():
    salida = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '../../assets/sellos')
    os.makedirs(salida, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for nombre, motivo, tinta in trabajos():
            fuente, destino = os.path.join(tmp, nombre + '.svg'), os.path.abspath(os.path.join(salida, nombre + '.png'))
            with open(fuente, 'w') as f:
                f.write(svg(motivo(), tinta))
            subprocess.run(['google-chrome', '--headless=new', '--disable-gpu', '--hide-scrollbars', '--default-background-color=00000000',
                            f'--window-size={LADO},{LADO}', f'--screenshot={destino}', 'file://' + fuente], check=True, capture_output=True)
            Image.open(destino).save(destino, optimize=True)
    print('listo:', salida)


if __name__ == '__main__':
    main()
