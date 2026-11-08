# Logros de Barrio

Los calcula la API con los pedidos pagados (`pagada`, `lista`, `entregada`). No hay tabla ni datos en la app. Reglas en `backend/src/pedidos.js`; imágenes en `barrio_app_pey/assets/sellos/`.

## Sellos personales

| Sello | Nombre que ve la persona | Se gana con | Archivo |
|---|---|---|---|
| Primera compra | Primera compra | 1 compra | `primera.png` |
| Bronce | Ya te conocen en (negocio) | 3 compras en un negocio | `bronce.png` |
| Plata | Conoces (colonia) | 3 negocios de una colonia | `plata.png` |
| Oro | De todo en tu barrio | 4 tipos de negocio | `oro.png` |

**Premio de primera compra:** la promoción sin código activa del negocio donde compró. Se descuenta sola en la siguiente cuenta ahí, una vez por persona. La paga el negocio, que es quien la publicó; si no tiene promoción, no se promete nada.

**Privacidad:** el negocio solo ve «Primera compra», «Cliente frecuente», «Conoce la colonia» o «Compra de todo». Nunca dónde más compra su cliente.

## Sellos de ciudad

Uno por alcaldía, por compras pagadas en esa alcaldía: **bronce con 1, plata con 3, oro con 5**. Archivo: `alcaldia-(id)-(nivel).png`.

**Toda la ciudad** (`cdmx-(nivel).png`) usa los mismos niveles y vale lo que la alcaldía con menos compras: bronce con las 16 en bronce, oro con las 16 en oro.

| Alcaldía | Nombre del sello | Motivo | De dónde sale |
|---|---|---|---|
| Álvaro Obregón | Entre barrancas | Cantiles y río | La alcaldía está cruzada por barrancas |
| Azcapotzalco | El hormiguero | Hormiga | El nombre significa «en el hormiguero» |
| Benito Juárez | Los Venados | Venado | Parque de los Venados, punto de encuentro de la zona |
| Coyoacán | Lugar de coyotes | Coyote | Así se interpreta su nombre |
| Cuajimalpa | Donde se labra la madera | Hacha y tronco | Sentido atribuido a Cuauhximalpan |
| Cuauhtémoc | Águila que desciende | Águila en picada | Significado del nombre |
| Gustavo A. Madero | Al pie de la sierra | Sierra de tres cerros | Sierra de Guadalupe; se evita el motivo religioso |
| Iztacalco | Casa de la sal | Casa y cristales | Así se interpreta su nombre |
| Iztapalapa | Agua sobre lajas | Lajas y oleaje | Así se interpreta su nombre; se evitan motivos rituales |
| Magdalena Contreras | Los Dinamos | Engrane y río | Río Magdalena y su pasado fabril |
| Miguel Hidalgo | Cerro del chapulín | Chapulín en cerro | Significado de Chapultepec |
| Milpa Alta | Tierra de nopal | Nopal con tunas | Principal productora de nopal en la ciudad |
| Tláhuac | Canoa y lago | Canoa, tule y agua | Zona lacustre y de chinampas |
| Tlalpan | Tierra firme | Pie sobre la tierra | Así se interpreta su nombre |
| Venustiano Carranza | Balanza de mercado | Balanza | La Merced, Sonora y Jamaica: mercados de la ciudad |
| Xochimilco | Campo de flores | Flor y chinampa | Así se interpreta su nombre |

Antes de publicarlos fuera de la demo, confirmar las interpretaciones de cada topónimo con una fuente especializada: varían según el autor.

## Estilo de los sellos

Mezcla de sello universitario (círculo dentado, doble anillo) y dibujo de códice (figura plana, contorno grueso, sin perspectiva). Una tinta sobre fondo transparente.

| Nivel | Tinta | Además del color |
|---|---|---|
| Primera compra | Grana `#9B1B4B` | |
| Bronce | `#9A5B2A` | Anillo simple |
| Plata | `#66727F` | Doble anillo |
| Oro | `#AD7B00` | Doble anillo y 16 puntos, uno por alcaldía |

PNG de 320 × 320 con alfa. Se regeneran con `python3 tool/sellos/generar.py` desde `barrio_app_pey/`. Por lograr: la app los pinta en gris.

**Cuidado cultural.** Son inspiración gráfica, no adorno. Nada de deidades, escenas rituales, calendario sagrado ni tocados. Ningún signo se copia de un códice o de una ilustración: todos se dibujaron de nuevo. Nombres en español. Antes de un lanzamiento formal los debe revisar y acreditar una persona especialista nahua, con pago por su trabajo. Ver [`../pendientes/`](../pendientes/README.md).
