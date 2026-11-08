import 'package:flutter/material.dart';

import '../../services/barrio_api.dart';
import '../../theme.dart';
import 'app_button.dart';
import 'barrio_icon.dart';

class BarrioBackdrop extends StatelessWidget {
  const BarrioBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: BarrioColors
            .crema, // Material y no ColoredBox: deja ver el toque en filas y switches
        child: child,
      );
}

class BarrioPanel extends StatelessWidget {
  const BarrioPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 6,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: BarrioColors.blanco,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: BarrioColors.marino, width: 2),
        ),
        child: child,
      );
}

class BarrioMark extends StatelessWidget {
  const BarrioMark({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) => BarrioIcon(
        asset: 'brand',
        size: size,
        label: 'Toldo de Barrio',
      );
}

/// Toldo de la ficha del negocio: franjas mango y blanco con regla marino.
class BarrioToldo extends StatelessWidget {
  const BarrioToldo({super.key, this.height = 16});
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          height: height,
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: BarrioColors.marino, width: 2))),
          child: Row(children: [
            for (var i = 0; i < 12; i++)
              Expanded(
                  child: ColoredBox(
                      color:
                          i.isEven ? BarrioColors.mango : BarrioColors.blanco,
                      child: const SizedBox.expand())),
          ]),
        ),
      );
}

/// Qué pasó y qué hacer: mensaje corto con salida (voz de marca §2.5).
class BarrioProblema extends StatelessWidget {
  const BarrioProblema({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BarrioPanel(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Semantics(
                  liveRegion: true,
                  child: Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17, color: BarrioColors.tinta))),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                AppButton(label: 'Intentar de nuevo', onPressed: onRetry),
              ],
            ]),
          ),
        ),
      );
}

/// Mensaje de error de red o de la API, en palabras de la voz de marca.
String mensajeDe(Object error) => error is BarrioApiException
    ? error.message
    : 'Sin señal. Revisa tu conexión e inténtalo de nuevo.';
