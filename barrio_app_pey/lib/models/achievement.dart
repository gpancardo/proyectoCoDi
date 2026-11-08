import '../i18n.dart';

enum MedalTier { bronze, silver, gold }

extension MedalTierPresentation on MedalTier {
  String get label => switch (this) {
        MedalTier.bronze => 'Bronce',
        MedalTier.silver => 'Plata',
        MedalTier.gold => 'Oro',
      };

  String get iconAsset => switch (this) {
        MedalTier.bronze => 'medal-bronze',
        MedalTier.silver => 'medal-silver',
        MedalTier.gold => 'medal-gold',
      };

  int get discountPercent => switch (this) {
        MedalTier.bronze => 10,
        MedalTier.silver => 15,
        MedalTier.gold => 20,
      };
}

enum AchievementKind {
  repeatVisits,
  neighborhoodShops,
  boroughsExplored,
  boroughShops
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.tier,
    required this.progress,
    required this.target,
    required this.couponBusiness,
    required this.alcaldia,
  });

  final String id;
  final String title;
  final String description;
  final AchievementKind kind;
  final MedalTier tier;
  final int progress;
  final int target;
  final String couponBusiness;
  final String? alcaldia;

  bool get unlocked => progress >= target;
  double get fraction => (progress / target).clamp(0, 1).toDouble();
  int get discountPercent => tier.discountPercent;
  String get couponCode =>
      'BARRIO-${id.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '-')}';
}

abstract final class DemoAchievements {
  static const _boroughShopCounts = <String, int>{
    'Benito Juárez': 4,
    'Coyoacán': 2,
    'Cuauhtémoc': 1,
    'Miguel Hidalgo': 1,
  };

  static const _boroughTitleStems = <String, List<String>>{
    'Álvaro Obregón': [
      'Primera vuelta en Álvaro Obregón',
      'Rutas de Álvaro Obregón',
      'De casa en Álvaro Obregón'
    ],
    'Azcapotzalco': [
      'Primera vuelta chintolola',
      'Rutas de Azcapotzalco',
      'De casa en Azcapotzalco'
    ],
    'Benito Juárez': [
      'Explorador Benito Juárez',
      'Rutas de Benito Juárez',
      'De casa en Benito Juárez'
    ],
    'Coyoacán': [
      'Catadora de Coyoacán',
      'Rutas de Coyoacán',
      'De casa en Coyoacán'
    ],
    'Cuajimalpa de Morelos': [
      'Primera vuelta en Cuajimalpa',
      'Rutas de Cuajimalpa',
      'De casa en Cuajimalpa'
    ],
    'Cuauhtémoc': [
      'Mesa en el Centro',
      'Rutas de Cuauhtémoc',
      'De casa en Cuauhtémoc'
    ],
    'Gustavo A. Madero': [
      'Primera vuelta en la GAM',
      'Rutas de la GAM',
      'De casa en la GAM'
    ],
    'Iztacalco': [
      'Antojo en Iztacalco',
      'Rutas de Iztacalco',
      'De casa en Iztacalco'
    ],
    'Iztapalapa': [
      'Sabores de Iztapalapa',
      'Rutas de Iztapalapa',
      'De casa en Iztapalapa'
    ],
    'La Magdalena Contreras': [
      'Primera vuelta en Contreras',
      'Rutas de Contreras',
      'De casa en Contreras'
    ],
    'Miguel Hidalgo': [
      'Rumbo a Miguel Hidalgo',
      'Rutas de Miguel Hidalgo',
      'De casa en Miguel Hidalgo'
    ],
    'Milpa Alta': [
      'Primer antojo en Milpa Alta',
      'Rutas de Milpa Alta',
      'De casa en Milpa Alta'
    ],
    'Tláhuac': [
      'Primera vuelta en Tláhuac',
      'Rutas de Tláhuac',
      'De casa en Tláhuac'
    ],
    'Tlalpan': ['Sabores de Tlalpan', 'Rutas de Tlalpan', 'De casa en Tlalpan'],
    'Venustiano Carranza': [
      'Primera vuelta en Carranza',
      'Rutas de Venustiano Carranza',
      'De casa en Carranza'
    ],
    'Xochimilco': [
      'Paseo por Xochimilco',
      'Rutas de Xochimilco',
      'De casa en Xochimilco'
    ],
  };

  static const _tiers = <(MedalTier, int)>[
    (MedalTier.bronze, 1),
    (MedalTier.silver, 4),
    (MedalTier.gold, 8),
  ];

  static List<Achievement> build() {
    final achievements = <Achievement>[];

    void addTiered({
      required String idPrefix,
      required AchievementKind kind,
      required List<String> titles,
      required List<String> descriptions,
      required List<int> targets,
      required int progress,
      required String couponBusiness,
      String? alcaldia,
    }) {
      for (var index = 0; index < 3; index++) {
        final (tier, _) = _tiers[index];
        final target = targets[index];
        achievements.add(Achievement(
          id: '$idPrefix-${tier.name}',
          title: titles[index],
          description: descriptions[index],
          kind: kind,
          tier: tier,
          progress: progress,
          target: target,
          couponBusiness: couponBusiness,
          alcaldia: alcaldia,
        ));
      }
    }

    addTiered(
      idPrefix: 'cafecito',
      kind: AchievementKind.repeatVisits,
      titles: const ['Café de siempre', 'De la casa', 'Mesa favorita'],
      descriptions: const [
        'Visita 3 veces el mismo negocio.',
        'Vuelve 8 veces a un negocio que te gusta.',
        'Haz 20 visitas a tu negocio favorito.',
      ],
      targets: const [3, 8, 20],
      progress: 12,
      couponBusiness: 'Cafetería La Taza (muestra)',
    );
    addTiered(
      idPrefix: 'colonia',
      kind: AchievementKind.neighborhoodShops,
      titles: const [
        'Fiel a tu cuadra',
        'Manos del barrio',
        'Orgullo de la colonia'
      ],
      descriptions: const [
        'Compra en 3 tiendas distintas de tu colonia.',
        'Conoce 6 negocios distintos de tu colonia.',
        'Apoya 12 negocios distintos de tu colonia.',
      ],
      targets: const [3, 6, 12],
      progress: 6,
      couponBusiness: 'Panadería La Esquina (muestra)',
    );
    addTiered(
      idPrefix: 'cdmx',
      kind: AchievementKind.boroughsExplored,
      titles: const [
        'Rumbo chilango',
        'Ciudad a tus pies',
        'Mapa de la ciudad'
      ],
      descriptions: const [
        'Compra en negocios de 3 alcaldías distintas.',
        'Compra en negocios de 8 alcaldías distintas.',
        'Compra en las 16 alcaldías de la CDMX.',
      ],
      targets: const [3, 8, 16],
      progress: 5,
      couponBusiness: 'Fonda Las Jacarandas (muestra)',
    );

    for (final alcaldia in I18n.alcaldiasCdmx) {
      final titles = _boroughTitleStems[alcaldia]!;
      final count = _boroughShopCounts[alcaldia] ?? 0;
      addTiered(
        idPrefix:
            'alcaldia-${alcaldia.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
        kind: AchievementKind.boroughShops,
        titles: titles,
        descriptions: [
          'Compra en 1 negocio de $alcaldia.',
          'Compra en 4 negocios distintos de $alcaldia.',
          'Compra en 8 negocios distintos de $alcaldia.',
        ],
        targets: const [1, 4, 8],
        progress: count,
        couponBusiness: 'Negocio de $alcaldia (muestra)',
        alcaldia: alcaldia,
      );
    }
    return achievements;
  }
}
