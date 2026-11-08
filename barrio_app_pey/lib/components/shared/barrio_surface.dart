import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme.dart';

class BarrioBackdrop extends StatelessWidget {
  const BarrioBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BarrioBackdropPainter(),
        child: child,
      );
}

class BarrioGlassPanel extends StatelessWidget {
  const BarrioGlassPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: BarrioColors.blanco.withOpacity(.78),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: BarrioColors.blanco.withOpacity(.96), width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x170B2545),
                    blurRadius: 22,
                    offset: Offset(0, 8)),
              ],
            ),
            child: child,
          ),
        ),
      );
}

class BarrioMark extends StatelessWidget {
  const BarrioMark({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _AwningMarkPainter()),
      );
}

class _BarrioBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(BarrioColors.crema, BlendMode.src);
    final glow = Paint()..color = BarrioColors.mango.withOpacity(.10);
    canvas.drawCircle(Offset(size.width * .96, 90), size.width * .35, glow);
    final tile = Paint()
      ..color = BarrioColors.marino.withOpacity(.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = size.width * .68; x < size.width + 32; x += 32) {
      for (var y = size.height - 176; y < size.height + 32; y += 32) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 20, 20), const Radius.circular(5)),
            tile);
      }
    }
    final awning = Paint();
    const start = Offset(0, 0);
    for (var i = 0; i < 8; i++) {
      awning.color = i.isEven
          ? BarrioColors.mango.withOpacity(.12)
          : BarrioColors.blanco.withOpacity(.44);
      canvas.drawRect(
          Rect.fromLTWH(start.dx + i * 24, start.dy, 24, 9), awning);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AwningMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 54;
    canvas.save();
    canvas.scale(scale);
    final ink = Paint()..color = BarrioColors.marino;
    final mango = Paint()..color = BarrioColors.mango;
    final cream = Paint()..color = BarrioColors.blanco;
    final border = Paint()
      ..color = BarrioColors.marino
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 6, 46, 15), const Radius.circular(5)),
        ink);
    for (var i = 0; i < 5; i++) {
      final paint = i.isEven ? mango : cream;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(7 + i * 9, 8, 8, 10), const Radius.circular(2)),
          paint);
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(9, 22, 36, 28), const Radius.circular(7)),
        cream);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(9, 22, 36, 28), const Radius.circular(7)),
        border);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(17, 29, 20, 14), const Radius.circular(3)),
        mango);
    canvas.drawRect(const Rect.fromLTWH(24, 29, 2, 14), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
