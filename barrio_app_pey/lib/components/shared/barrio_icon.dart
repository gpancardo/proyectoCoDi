import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BarrioIcon extends StatelessWidget {
  const BarrioIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.label,
    this.fit = BoxFit.contain,
    this.rotation = 0,
  });

  final String asset;
  final double size;
  final String? label;
  final BoxFit fit;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(
      'assets/icons/$asset.svg',
      width: size,
      height: size,
      fit: fit,
      semanticsLabel: label,
    );
    final rotated =
        rotation == 0 ? image : Transform.rotate(angle: rotation, child: image);
    return label == null ? ExcludeSemantics(child: rotated) : rotated;
  }
}
