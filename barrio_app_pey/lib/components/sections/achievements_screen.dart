import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../models/achievement.dart';
import '../../theme.dart';
import '../shared/barrio_icon.dart';
import '../shared/barrio_surface.dart';

enum _AchievementFilter { all, earned, pending }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static final _achievements = DemoAchievements.build();
  _AchievementFilter _filter = _AchievementFilter.all;
  String? _alcaldia;
  double _scrollOffset = 0;

  int get _earnedCount => _achievements.where((item) => item.unlocked).length;

  List<Achievement> get _visibleAchievements => _achievements.where((item) {
        final statusMatches = switch (_filter) {
          _AchievementFilter.all => true,
          _AchievementFilter.earned => item.unlocked,
          _AchievementFilter.pending => !item.unlocked,
        };
        final boroughMatches = _alcaldia == null || item.alcaldia == _alcaldia;
        return statusMatches && boroughMatches;
      }).toList(growable: false);

  void _updateParallax(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        MediaQuery.of(context).disableAnimations) return;
    final nextOffset =
        (notification.metrics.pixels * .07).clamp(0, 18).toDouble();
    if ((nextOffset - _scrollOffset).abs() >= 1.5) {
      setState(() => _scrollOffset = nextOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _earnedCount;
    final total = _achievements.length;
    return Scaffold(
      backgroundColor: BarrioColors.crema,
      body: SafeArea(
        child: BarrioBackdrop(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _updateParallax(notification);
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                Transform.translate(
                  offset: Offset(0, -_scrollOffset),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Logros del barrio',
                                style: TextStyle(
                                    color: BarrioColors.marino,
                                    fontSize: 29,
                                    height: 1.08,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5)),
                            SizedBox(height: 6),
                            Text('Cada vuelta cuenta.',
                                style: TextStyle(
                                    color: BarrioColors.gris, fontSize: 16)),
                          ],
                        ),
                      ),
                      Transform.rotate(
                        angle: _scrollOffset / 300,
                        child: const BarrioIcon(asset: 'medal-gold', size: 70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _Dashboard(unlocked: unlocked, total: total),
                const SizedBox(height: 24),
                const _FilterLabel(title: 'Ver'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'Todos (${_achievements.length})',
                      selected: _filter == _AchievementFilter.all,
                      onTap: () =>
                          setState(() => _filter = _AchievementFilter.all),
                    ),
                    _StatusChip(
                      label: 'Conseguidos ($unlocked)',
                      selected: _filter == _AchievementFilter.earned,
                      onTap: () =>
                          setState(() => _filter = _AchievementFilter.earned),
                    ),
                    _StatusChip(
                      label: 'Por lograr (${total - unlocked})',
                      selected: _filter == _AchievementFilter.pending,
                      onTap: () =>
                          setState(() => _filter = _AchievementFilter.pending),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _FilterLabel(title: 'Filtrar por alcaldía'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _StatusChip(
                        label: 'Todas',
                        selected: _alcaldia == null,
                        onTap: () => setState(() => _alcaldia = null),
                      ),
                      for (final alcaldia in I18n.alcaldiasCdmx)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _StatusChip(
                            label: alcaldia,
                            selected: _alcaldia == alcaldia,
                            onTap: () => setState(() => _alcaldia = alcaldia),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Tu lista',
                          style: TextStyle(
                              color: BarrioColors.marino,
                              fontSize: 21,
                              fontWeight: FontWeight.w800)),
                    ),
                    Text('${_visibleAchievements.length} logros',
                        style: const TextStyle(
                            color: BarrioColors.gris, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                if (_visibleAchievements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text('No hay logros en este filtro.',
                        style: TextStyle(color: BarrioColors.gris)),
                  )
                else
                  for (var index = 0;
                      index < _visibleAchievements.length;
                      index++) ...[
                    if (index == 0)
                      const Divider(
                          color: BarrioColors.marino, thickness: 2, height: 2),
                    _AchievementRow(
                      achievement: _visibleAchievements[index],
                      onTap: () => _showCoupon(_visibleAchievements[index]),
                    ),
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

  void _showCoupon(Achievement achievement) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CouponSheet(achievement: achievement),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.unlocked, required this.total});
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BarrioColors.blanco,
        border: Border.all(color: BarrioColors.marino, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$unlocked',
                  style: const TextStyle(
                      color: BarrioColors.marino,
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w800)),
              Padding(
                padding: const EdgeInsets.only(left: 7, bottom: 3),
                child: Text('de $total logros',
                    style: const TextStyle(
                        color: BarrioColors.gris,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              const BarrioIcon(asset: 'achievements', size: 36),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: BarrioColors.niebla,
              valueColor: const AlwaysStoppedAnimation(BarrioColors.mango),
            ),
          ),
          const SizedBox(height: 8),
          Text('${total - unlocked} por lograr · descuentos de muestra',
              style: const TextStyle(color: BarrioColors.gris, fontSize: 14)),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          color: BarrioColors.marino,
          fontSize: 16,
          fontWeight: FontWeight.w700));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected ? BarrioColors.marino : BarrioColors.crema,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: selected ? BarrioColors.marino : BarrioColors.crema,
                border: Border.all(color: BarrioColors.marino, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selected ? '✓ $label' : label,
                style: TextStyle(
                  color: selected ? BarrioColors.crema : BarrioColors.marino,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.onTap});
  final Achievement achievement;
  final VoidCallback onTap;

  static const _grayMatrix = <double>[
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.unlocked;
    final icon = BarrioIcon(asset: achievement.tier.iconAsset, size: 52);
    return Semantics(
      button: true,
      label: '${achievement.tier.label}: ${achievement.title}. '
          '${isUnlocked ? 'Conseguido' : 'Por lograr'}. Abre cupón de muestra.',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUnlocked)
                icon
              else
                Opacity(
                  opacity: .6,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_grayMatrix),
                    child: icon,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${achievement.tier.label.toUpperCase()} · ${achievement.title}',
                        style: TextStyle(
                            color: isUnlocked
                                ? BarrioColors.marino
                                : BarrioColors.gris,
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(achievement.description,
                        style: TextStyle(
                            color: isUnlocked
                                ? BarrioColors.tinta
                                : BarrioColors.gris,
                            fontSize: 14,
                            height: 1.35)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: achievement.fraction,
                              minHeight: 5,
                              backgroundColor: BarrioColors.niebla,
                              valueColor: AlwaysStoppedAnimation(isUnlocked
                                  ? BarrioColors.mango
                                  : BarrioColors.gris),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text('${achievement.progress}/${achievement.target}',
                            style: TextStyle(
                                color: isUnlocked
                                    ? BarrioColors.marino
                                    : BarrioColors.gris,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const BarrioIcon(asset: 'chevron-right', size: 23),
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponSheet extends StatelessWidget {
  const _CouponSheet({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          decoration: const BoxDecoration(
            color: BarrioColors.crema,
            border:
                Border(top: BorderSide(color: BarrioColors.marino, width: 3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BarrioIcon(asset: achievement.tier.iconAsset, size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            achievement.unlocked
                                ? 'Logro conseguido'
                                : 'Sigue la ruta',
                            style: const TextStyle(
                                color: BarrioColors.gris,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(achievement.title,
                            style: const TextStyle(
                                color: BarrioColors.marino,
                                fontSize: 21,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BarrioColors.blanco,
                  border: Border.all(color: BarrioColors.marino, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const BarrioIcon(asset: 'coupon', size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${achievement.discountPercent}% de descuento',
                              style: const TextStyle(
                                  color: BarrioColors.marino,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          Text('Lo asigna ${achievement.couponBusiness}',
                              style: const TextStyle(
                                  color: BarrioColors.tinta, fontSize: 14)),
                          const SizedBox(height: 8),
                          SelectableText(achievement.couponCode,
                              style: const TextStyle(
                                  color: BarrioColors.marino,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                achievement.unlocked
                    ? 'Cupón de muestra. No se puede canjear todavía.'
                    : 'Desbloquea el logro para conseguir este cupón de muestra.',
                style: const TextStyle(color: BarrioColors.gris, fontSize: 14),
              ),
            ],
          ),
        ),
      );
}
