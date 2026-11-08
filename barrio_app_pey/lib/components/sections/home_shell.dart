import 'package:flutter/material.dart';

import '../../theme.dart';
import 'achievements_screen.dart';
import 'chat_screen.dart';
import 'marketplace_screen.dart';
import 'seller_screen.dart';
import 'profile_screen.dart';
import 'orders_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialSection = 0});
  final int initialSection;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _section = widget.initialSection;

  static const _sections = <_SectionItem>[
    _SectionItem(label: 'Buscar con Barrio'),
    _SectionItem(label: 'Descubrir'),
    _SectionItem(label: 'Logros'),
    _SectionItem(label: 'Tu negocio'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BarrioColors.crema,
        appBar: AppBar(
          toolbarHeight: 56,
          title: Text(_sections[_section].label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          bottom: const PreferredSize(preferredSize: Size.fromHeight(2), child: Divider(height: 2, thickness: 2, color: BarrioColors.marino)),
        ),
        drawer: Drawer(
          shape: const RoundedRectangleBorder(),
          child: SafeArea(child: ColoredBox(color: BarrioColors.crema, child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              const Text('barrio', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: BarrioColors.marino)),
              const SizedBox(height: 28),
              for (var index = 0; index < _sections.length; index++)
                ListTile(
                  title: Text(_sections[index].label, style: TextStyle(fontWeight: _section == index ? FontWeight.w800 : FontWeight.w500)),
                  selected: _section == index,
                  selectedColor: BarrioColors.marino,
                  onTap: () { Navigator.pop(context); setState(() => _section = index); },
                ),
              const Divider(color: BarrioColors.marino, thickness: 2),
              ListTile(title: const Text('Perfil'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); }),
              ListTile(title: const Text('Mis pedidos'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())); }),
            ],
          ))),
        ),
        body: IndexedStack(index: _section, children: const [ChatScreen(), MarketplaceScreen(), AchievementsScreen(), SellerScreen()]),
      );
}

class _SectionItem {
  const _SectionItem({required this.label});
  final String label;
}
