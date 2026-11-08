import 'package:flutter/material.dart';

import '../../theme.dart';
import '../shared/barrio_surface.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BarrioColors.crema,
        body: BarrioBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: [
                      const BarrioMark(size: 48),
                      const SizedBox(width: 12),
                      Text('Mercado',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );
}
