import 'package:flutter/material.dart';

import '../../theme.dart';
import 'barrio_icon.dart';

class BarrioBackdrop extends StatelessWidget {
  const BarrioBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: BarrioColors.crema,
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
        asset: 'marketplace',
        size: size,
        label: 'Toldo de Barrio',
      );
}
