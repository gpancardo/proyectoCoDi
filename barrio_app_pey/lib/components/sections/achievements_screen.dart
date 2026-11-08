import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/app_button.dart';
import '../shared/barrio_icon.dart';
import '../shared/barrio_surface.dart';
import 'business_screen.dart';

/// Sellos del comprador. Los calcula la API con sus pedidos pagados.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Map<String, dynamic>? _profile;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<BarrioApi>().get('/me/profile',
          token: context.read<AppState>().accessToken) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _profile = data;
          _problem = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _problem = mensajeDe(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_problem != null && _profile == null) {
      return Scaffold(body: BarrioProblema(message: _problem!, onRetry: _load));
    }
    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final seals = (profile['insignias'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final bought = (profile['pedidos_pagados'] as num? ?? 0).toInt();
    final reward = profile['premio'] as Map<String, dynamic>?;
    return Scaffold(
      body: BarrioBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                const Text('Tus sellos',
                    style: TextStyle(
                        color: BarrioColors.marino,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                    bought == 0
                        ? 'Se ganan comprando en tu barrio.'
                        : bought == 1
                            ? 'Llevas 1 compra en tu barrio.'
                            : 'Llevas $bought compras en tu barrio.',
                    style: const TextStyle(
                        color: BarrioColors.gris, fontSize: 16)),
                const SizedBox(height: 16),
                const Divider(
                    color: BarrioColors.marino, thickness: 2, height: 2),
                for (final seal in seals) ...[
                  _SealRow(seal: seal),
                  if (seal['nivel'] == 'primera' &&
                      seal['obtenida'] == true &&
                      reward != null)
                    _Reward(reward: reward),
                  const Divider(
                      color: BarrioColors.marino, thickness: 2, height: 2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _labels = {
  'primera': 'Primera compra',
  'bronce': 'Bronce',
  'plata': 'Plata',
  'oro': 'Oro',
};
const _assets = {
  'primera': 'medal-first',
  'bronce': 'medal-bronze',
  'plata': 'medal-silver',
  'oro': 'medal-gold',
};

class _SealRow extends StatelessWidget {
  const _SealRow({required this.seal});
  final Map<String, dynamic> seal;

  static const _gray = ColorFilter.matrix(<double>[
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final level = seal['nivel']?.toString() ?? 'bronce';
    final earned = seal['obtenida'] == true;
    final icon = BarrioIcon(asset: _assets[level] ?? 'medal-bronze', size: 72);
    final progress = seal['avance'] ?? seal['pedidos_pagados'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        earned
            ? icon
            : Opacity(
                opacity: .55,
                child: ColorFiltered(colorFilter: _gray, child: icon)),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_labels[level] ?? level,
                style: const TextStyle(
                    color: BarrioColors.gris,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            Text(seal['nombre'].toString(),
                style: const TextStyle(
                    color: BarrioColors.marino,
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(seal['detalle']?.toString() ?? '',
                style:
                    const TextStyle(color: BarrioColors.tinta, fontSize: 16)),
            const SizedBox(height: 6),
            Text(earned ? 'Conseguido' : '$progress de ${seal['meta']}',
                style: TextStyle(
                    color: earned ? BarrioColors.teal : BarrioColors.gris,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

/// El premio es un objeto real: por eso aquí sí va como ticket.
class _Reward extends StatelessWidget {
  const _Reward({required this.reward});
  final Map<String, dynamic> reward;

  @override
  Widget build(BuildContext context) {
    final minimum = (reward['min_compra_minor'] as num? ?? 0);
    final business = reward['negocio']?.toString() ?? 'ese negocio';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BarrioPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(reward['titulo'].toString(),
              style: const TextStyle(
                  color: BarrioColors.marino,
                  fontSize: 21,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              minimum > 0
                  ? 'En $business, con compra de ${formatMoney(minimum)} o más. Se descuenta solo.'
                  : 'En $business. Se descuenta solo.',
              style: const TextStyle(color: BarrioColors.tinta, fontSize: 16)),
          const SizedBox(height: 12),
          AppButton(
              label: 'Pedir otra vez',
              iconAsset: 'chevron-right',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BusinessScreen(
                      businessId: (reward['negocio_id'] as num).toInt())))),
        ]),
      ),
    );
  }
}
