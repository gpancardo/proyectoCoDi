import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/app_button.dart';
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
    final cityAll = profile['cdmx'] as Map<String, dynamic>?;
    final city = (profile['alcaldias'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList()
      ?..sort((a, b) =>
          (a['nivel'] == null ? 1 : 0) - (b['nivel'] == null ? 1 : 0));
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
                if (city != null && cityAll != null) ...[
                  const SizedBox(height: 28),
                  const Text('Tu ciudad',
                      style: TextStyle(
                          color: BarrioColors.marino,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                      'Un sello por alcaldía. Bronce con 1 compra, plata con 3, oro con 5.',
                      style: TextStyle(color: BarrioColors.gris, fontSize: 16)),
                  const SizedBox(height: 12),
                  _CityTotal(data: cityAll),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: .68,
                    children: [
                      for (final place in city) _CityCell(place: place),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _cityAsset(Map<String, dynamic> place) {
  final level = place['nivel']?.toString() ?? 'bronce';
  return place['id'] == 'cdmx'
      ? 'cdmx-$level'
      : 'alcaldia-${place['id']}-$level';
}

String _levelName(Object? level) => _labels[level] ?? 'Sin sello';

void _openCity(BuildContext context, Map<String, dynamic> place) {
  final isCity = place['id'] == 'cdmx';
  final count = (place['avance'] as num? ?? 0).toInt();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: BarrioColors.crema,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _SealImage(
              name: _cityAsset(place),
              earned: place['nivel'] != null,
              size: 168),
          const SizedBox(height: 12),
          Text(place['nombre'].toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: BarrioColors.marino,
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w800)),
          Text(
              isCity ? 'Las 16 alcaldías de la CDMX' : place['zona'].toString(),
              style: const TextStyle(color: BarrioColors.gris, fontSize: 16)),
          const SizedBox(height: 12),
          Text(
              isCity
                  ? 'Vale lo que tu alcaldía con menos compras. Llevas $count de 16 rumbo al siguiente nivel.'
                  : count == 1
                      ? 'Llevas 1 compra aquí.'
                      : 'Llevas $count compras aquí.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: BarrioColors.tinta, fontSize: 17)),
          const SizedBox(height: 4),
          Text(_levelName(place['nivel']),
              style: const TextStyle(
                  color: BarrioColors.teal,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

class _SealImage extends StatelessWidget {
  const _SealImage(
      {required this.name, required this.earned, required this.size});
  final String name;
  final bool earned;
  final double size;

  static const _gray = ColorFilter.matrix(<double>[
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset('assets/sellos/$name.svg',
        width: size, height: size, excludeFromSemantics: true);
    return earned
        ? image
        : Opacity(
            opacity: .45,
            child: ColorFiltered(colorFilter: _gray, child: image));
  }
}

class _CityTotal extends StatelessWidget {
  const _CityTotal({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => _openCity(context, data),
        child: Row(children: [
          _SealImage(
              name: _cityAsset(data), earned: data['nivel'] != null, size: 88),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_levelName(data['nivel']),
                  style: const TextStyle(
                      color: BarrioColors.gris,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Text(data['nombre'].toString(),
                  style: const TextStyle(
                      color: BarrioColors.marino,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
              const Text('Las 16 alcaldías en un mismo nivel.',
                  style: TextStyle(color: BarrioColors.tinta, fontSize: 16)),
            ]),
          ),
        ]),
      );
}

class _CityCell extends StatelessWidget {
  const _CityCell({required this.place});
  final Map<String, dynamic> place;

  @override
  Widget build(BuildContext context) {
    final earned = place['nivel'] != null;
    return Semantics(
      button: true,
      label:
          '${place['zona']}, ${place['nombre']}, ${_levelName(place['nivel'])}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => _openCity(context, place),
          child: Column(children: [
            AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                    builder: (_, box) => _SealImage(
                        name: _cityAsset(place),
                        earned: earned,
                        size: box.maxWidth))),
            const SizedBox(height: 4),
            Text(place['zona'].toString(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: earned ? BarrioColors.marino : BarrioColors.gris,
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

const _labels = {
  'primera': 'Para empezar',
  'bronce': 'Bronce',
  'plata': 'Plata',
  'oro': 'Oro',
};

class _SealRow extends StatelessWidget {
  const _SealRow({required this.seal});
  final Map<String, dynamic> seal;

  @override
  Widget build(BuildContext context) {
    final level = seal['nivel']?.toString() ?? 'bronce';
    final earned = seal['obtenida'] == true;
    final progress = seal['avance'] ?? seal['pedidos_pagados'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SealImage(name: level, earned: earned, size: 72),
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
