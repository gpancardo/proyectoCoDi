# Barrio · app Flutter

Aplicación Android-first de Barrio. Es la superficie principal para comprar o gestionar un negocio con la misma cuenta.

## Qué hace

- **Buscar con Barrio:** conversación y dictado en español México; la API traduce la intención a filtros seguros.
- **Descubrir:** categorías, carruseles y búsqueda de negocios abiertos.
- **Comprar:** menú, cotización de servidor, promociones, confirmación, CoDi por push y código de recogida.
- **Cerrar el pedido:** confirmar entrega o abrir un correo de ayuda con el contexto del pedido.
- **Vender:** disponibilidad, pedidos, promociones y logros visibles del comprador.

La app nunca calcula precios finales, no consulta tablas de Supabase directamente y no contiene secretos de servidor.

## Arranque

```bash
flutter pub get
flutter analyze
flutter run
```

Configura los valores públicos en `.env.example` antes de ejecutar. Para Android, el dictado requiere permiso de micrófono y un dispositivo con reconocimiento de voz disponible. La interfaz tiene fallback escrito cuando no hay micrófono o reconocimiento.

## Verificación

```bash
flutter analyze
```

Usa Android físico para validar el permiso y el dictado real. Chrome sirve para revisar navegación y layout, pero no sustituye esa prueba nativa.

## Diseño

La referencia es [`../docs/DESIGN.md`](../docs/DESIGN.md): Archivo, marino `#0B2545`, mango `#F5A524`, crema `#FFF8EC` y teal `#0F7C75`. No agregues componentes genéricos, sombras pesadas ni textos fuera de [`../docs/VOZ-DE-MARCA.md`](../docs/VOZ-DE-MARCA.md).
