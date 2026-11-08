import 'package:flutter/material.dart';

import 'barrio_icon.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.iconAsset = 'check',
  });

  final String label;
  final VoidCallback? onPressed;
  final String iconAsset;

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        onPressed: onPressed,
        icon: BarrioIcon(asset: iconAsset, size: 24),
        label: Text(label),
      );
}
