import 'package:flutter/material.dart';

import '../../theme.dart';
import '../shared/barrio_icon.dart';
import 'achievements_screen.dart';
import 'chat_screen.dart';
import 'marketplace_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialSection = 1});
  final int initialSection;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _section = widget.initialSection;

  static const _sections = <_SectionItem>[
    _SectionItem(label: 'Mercado', icon: 'marketplace'),
    _SectionItem(label: 'Buscar', icon: 'chat'),
    _SectionItem(label: 'Logros', icon: 'achievements'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BarrioColors.crema,
        body: IndexedStack(
          index: _section,
          children: const [
            MarketplaceScreen(),
            ChatScreen(),
            AchievementsScreen(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 68,
            decoration: const BoxDecoration(
              color: BarrioColors.crema,
              border:
                  Border(top: BorderSide(color: BarrioColors.marino, width: 2)),
            ),
            child: Row(
              children: [
                for (var index = 0; index < _sections.length; index++)
                  Expanded(
                    child: _NavigationItem(
                      item: _sections[index],
                      selected: _section == index,
                      onTap: () => setState(() => _section = index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _SectionItem {
  const _SectionItem({required this.label, required this.icon});
  final String label;
  final String icon;
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem(
      {required this.item, required this.selected, required this.onTap});
  final _SectionItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? BarrioColors.mango : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: selected ? 1 : .65,
                  child: BarrioIcon(asset: item.icon, size: 30),
                ),
                const SizedBox(height: 2),
                Text(item.label,
                    style: TextStyle(
                        color: BarrioColors.marino,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}
