// ignore_for_file: invalid_use_of_visible_for_testing_member, depend_on_referenced_packages
// Genera docs/capturas/*.png recorriendo la app real con una API falsa y datos de muestra.
// Uso: flutter test tool/capturas_test.dart --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barrio_app_pey/app.dart';
import 'package:barrio_app_pey/services/barrio_api.dart';
import 'package:barrio_app_pey/state/app_state.dart';

final negocios = [
  {
    'id': 5,
    'nombre': 'Papelería Miranda',
    'categoria': 'Papelería',
    'colonia': 'Narvarte',
    'direccion': 'Av. Universidad 340, Narvarte',
    'match_reasons': ['Vende cuadernos', 'Abierto ahora'],
    'productos': [
      {'nombre': 'Cuaderno profesional', 'precio': 38},
      {'nombre': 'Copia', 'precio': 1},
      {'nombre': 'Pluma', 'precio': 8},
      {'nombre': 'Cartulina', 'precio': 10},
    ],
  },
  {
    'id': 6,
    'nombre': 'Ferretería San Miguel',
    'categoria': 'Ferretería',
    'colonia': 'Lindavista',
    'match_reasons': ['Abierto ahora'],
    'productos': [
      {'nombre': 'Foco LED', 'precio': 45},
    ],
  },
  {
    'id': 7,
    'nombre': 'Tacos Doña Lupe',
    'categoria': 'Antojitos',
    'colonia': 'San Lucas',
    'match_reasons': ['Abierto ahora'],
    'productos': [
      {'nombre': 'Taco de canasta', 'precio': 12},
    ],
  },
];

const zonas = {
  'alvaro-obregon': ['Álvaro Obregón', 'Entre barrancas', null, 0],
  'azcapotzalco': ['Azcapotzalco', 'El hormiguero', 'plata', 3],
  'benito-juarez': ['Benito Juárez', 'Los Venados', 'oro', 6],
  'coyoacan': ['Coyoacán', 'Lugar de coyotes', 'oro', 5],
  'cuajimalpa': ['Cuajimalpa', 'Donde se labra la madera', null, 0],
  'cuauhtemoc': ['Cuauhtémoc', 'Águila que desciende', 'plata', 4],
  'gustavo-a-madero': ['Gustavo A. Madero', 'Al pie de la sierra', 'bronce', 1],
  'iztacalco': ['Iztacalco', 'Casa de la sal', null, 0],
  'iztapalapa': ['Iztapalapa', 'Agua sobre lajas', 'bronce', 2],
  'magdalena-contreras': ['Magdalena Contreras', 'Los Dinamos', null, 0],
  'miguel-hidalgo': ['Miguel Hidalgo', 'Cerro del chapulín', 'bronce', 1],
  'milpa-alta': ['Milpa Alta', 'Tierra de nopal', null, 0],
  'tlahuac': ['Tláhuac', 'Canoa y lago', null, 0],
  'tlalpan': ['Tlalpan', 'Tierra firme', 'bronce', 2],
  'venustiano-carranza': [
    'Venustiano Carranza',
    'Balanza de mercado',
    'bronce',
    1
  ],
  'xochimilco': ['Xochimilco', 'Campo de flores', 'plata', 3],
};

final perfil = {
  'nombre': 'Lupita',
  'pedidos_pagados': 28,
  'premio': {
    'negocio_id': 5,
    'negocio': 'Papelería Miranda',
    'titulo': '10% en tu siguiente compra',
    'min_compra_minor': 5000,
  },
  'insignias': [
    {
      'nivel': 'primera',
      'nombre': 'Primera compra',
      'detalle': 'La hiciste en Papelería Miranda.',
      'avance': 1,
      'meta': 1,
      'obtenida': true
    },
    {
      'nivel': 'bronce',
      'nombre': 'Ya te conocen en Papelería Miranda',
      'detalle': 'Tres compras en el mismo negocio.',
      'avance': 3,
      'meta': 3,
      'obtenida': true
    },
    {
      'nivel': 'plata',
      'nombre': 'Conoces Narvarte',
      'detalle': 'Tres negocios distintos de una misma colonia.',
      'avance': 3,
      'meta': 3,
      'obtenida': true
    },
    {
      'nivel': 'oro',
      'nombre': 'De todo en tu barrio',
      'detalle':
          'Cuatro tipos de negocio: papelería, ferretería, lo que ocupes.',
      'avance': 3,
      'meta': 4,
      'obtenida': false
    },
  ],
  'cdmx': {
    'id': 'cdmx',
    'nombre': 'Toda la ciudad',
    'nivel': null,
    'avance': 10,
    'meta': 16
  },
  'alcaldias': [
    for (final e in zonas.entries)
      {
        'id': e.key,
        'zona': e.value[0],
        'nombre': e.value[1],
        'nivel': e.value[2],
        'avance': e.value[3],
        'meta': 5
      },
  ],
};

final tablero = {
  'hoy': {'ventas_minor': 124000, 'cobros': 38, 'ticket_minor': 3263},
  'ayer_minor': 98000,
  'semana': [
    for (final (i, v)
        in [61000, 74000, 52000, 88000, 131000, 98000, 124000].indexed)
      {'dia': '2026-11-0${i + 2}', 'ventas_minor': v, 'cobros': v ~/ 3200},
  ],
  'por_atender': {'responder': 1, 'preparar': 1, 'recoger': 0},
  'productos': [
    {'nombre': 'Copia', 'cantidad': 412, 'ventas_minor': 41200},
    {'nombre': 'Cuaderno profesional', 'cantidad': 86, 'ventas_minor': 326800},
    {'nombre': 'Pluma', 'cantidad': 64, 'ventas_minor': 51200},
  ],
  'clientes': {'total': 74, 'regresan': 31},
  'mes': {'ventas_minor': 2184000, 'cobros': 668, 'descuentos_minor': 41000},
};

final pedidosNegocio = [
  {
    'id': 21,
    'estado': 'pendiente',
    'total_minor': 8400,
    'notas': 'Sin engrapar',
    'items': [
      {'cantidad': 2, 'nombre': 'Cuaderno profesional'},
      {'cantidad': 1, 'nombre': 'Pluma'}
    ],
    'comprador_logros': [
      {'nombre': 'Cliente frecuente'},
      {'nombre': 'Conoce la colonia'}
    ]
  },
  {
    'id': 20,
    'estado': 'pagada',
    'total_minor': 3800,
    'items': [
      {'cantidad': 1, 'nombre': 'Cuaderno profesional'}
    ],
    'comprador_logros': [
      {'nombre': 'Primera compra'}
    ]
  },
  {
    'id': 19,
    'estado': 'cobrada',
    'total_minor': 800,
    'items': [
      {'cantidad': 1, 'nombre': 'Pluma'}
    ],
    'comprador_logros': []
  },
];

final cupones = [
  {
    'id': 1,
    'titulo': '10% en tu siguiente compra',
    'codigo': null,
    'activo': true,
    'vence': '2030-01-01T00:00:00Z'
  },
  {
    'id': 2,
    'titulo': 'Regreso a clases',
    'codigo': 'VECINOS10',
    'activo': true,
    'vence': '2030-01-01T00:00:00Z'
  },
];

var estado = 'cobrada';
var conNegocio = true;

Object? responde(http.BaseRequest r) {
  final ruta = r.url.path.split('/api/v1').last;
  final pedido = {
    'id': 31,
    'negocio_id': 5,
    'estado': estado,
    'total_minor': 6840,
    'codigo': '4821',
    'items': [
      {'cantidad': 2, 'nombre': 'Cuaderno profesional'}
    ],
  };
  if (ruta == '/me') {
    return {
      'comprador': {'id': 1},
      'negocio': conNegocio
          ? {...negocios[0], 'abierto': true, 'auto_aceptar': false}
          : null
    };
  }
  if (ruta == '/me/profile') return perfil;
  if (ruta == '/discovery') {
    return {
      'sections': [
        {'title': 'Abierto cerca de ti', 'items': negocios},
        {'title': 'Para resolver hoy', 'items': negocios.reversed.toList()},
      ]
    };
  }
  if (ruta == '/search/agent') {
    final conHistorial =
        (jsonDecode((r as http.Request).body)['history'] as List).isNotEmpty;
    return conHistorial
        ? negocios.where((n) => n['colonia'] == 'San Lucas').toList()
        : negocios;
  }
  if (ruta.startsWith('/businesses/')) return negocios[0];
  if (ruta == '/business/dashboard') return tablero;
  if (ruta == '/business/coupons') return cupones;
  if (ruta == '/orders/quotes') {
    return {
      'quote_id': 'c1',
      'items': [
        {'cantidad': 2, 'nombre': 'Cuaderno profesional', 'precio_minor': 3800}
      ],
      'subtotal_minor': 7600,
      'descuento_minor': 760,
      'coupon': {'titulo': '10% en tu siguiente compra'},
      'total_minor': 6840,
    };
  }
  if (ruta == '/orders' && r.method == 'POST') return pedido;
  if (ruta == '/orders') {
    return r.url.query.contains('comprador')
        ? [
            pedido,
            {...pedido, 'id': 30, 'estado': 'entregada', 'total_minor': 4500},
            {...pedido, 'id': 29, 'estado': 'entregada', 'total_minor': 12000},
          ]
        : pedidosNegocio;
  }
  if (ruta.endsWith('/payments/current')) {
    return {'via': 'push', 'estado': 'vigente', 'monto_minor': 6840};
  }
  if (ruta.startsWith('/orders/')) return pedido;
  return <String, dynamic>{};
}

// Primera vuelta: Barrio pregunta. Con historial, ya no.
Map<String, dynamic>? metaChat(http.BaseRequest r) {
  if (!r.url.path.endsWith('/search/agent')) return null;
  final historial = jsonDecode((r as http.Request).body)['history'] as List;
  return historial.isEmpty
      ? {
          'answer': 'Busco papelerías abiertas para ti.',
          'follow_up': {
            'question': '¿Por qué zona te queda mejor?',
            'options': ['Benito Juárez', 'Coyoacán', 'En toda la ciudad'],
          }
        }
      : {'answer': 'Esto encontré por Coyoacán.', 'follow_up': null};
}

Future<void> fuentes() async {
  final archivo = FontLoader('Archivo');
  for (final n in ['Regular', 'Medium', 'Bold', 'ExtraBold']) {
    archivo.addFont(rootBundle.load('assets/fonts/Archivo-$n.ttf'));
  }
  await archivo.load();
  final iconos = File(
          '../.tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
      .readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(iconos))))
      .load();
}

Future<void> asentar(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await t.pump(const Duration(milliseconds: 400));
  }
}

Future<void> foto(WidgetTester t, String nombre) async {
  await asentar(t);
  await expectLater(find.byType(BarrioApp),
      matchesGoldenFile('../../docs/capturas/$nombre.png'));
}

Future<void> abrir(WidgetTester t, Map<String, Object> prefs) async {
  t.view.physicalSize = const Size(780, 1600);
  t.view.devicePixelRatio = 2;
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  await t.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider.value(value: AppState(p)),
    Provider(
        create: (_) => BarrioApi(
            client: MockClient((r) async => http.Response.bytes(
                utf8.encode(jsonEncode({'data': responde(r), 'meta': metaChat(r)})),
                200,
                headers: {'content-type': 'application/json'})))),
  ], child: const BarrioApp()));
  await asentar(t);
}

const conSesion = <String, Object>{'session_access_token': 'x'};
const lista = <String, Object>{
  ...conSesion,
  'has_completed_onboarding': true,
  'profile_name': 'Lupita',
  'profile_phone': '5512345678',
  'profile_zone': 'Benito Juárez',
  'profile_neighborhood': 'Narvarte',
};

Future<void> seccion(WidgetTester t, String nombre) async {
  await t.tap(find.byTooltip('Open navigation menu'));
  await asentar(t);
  await t.tap(find.text(nombre).last);
  await asentar(t);
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.prueba');
    await fuentes();
  });

  testWidgets('entrada', (t) async {
    await abrir(t, {});
    await foto(t, '01-acceso');
    await t.pumpWidget(const SizedBox());
    await abrir(t, conSesion);
    await foto(t, '02-bienvenida');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('compra', (t) async {
    estado = 'cobrada';
    await abrir(t, lista);
    await foto(t, '03-buscar');
    await t.enterText(
        find.byType(TextField).first, 'un cuaderno cerca de aquí');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await foto(t, '04-resultados');
    await t.tap(find.text('Coyoacán'));
    await foto(t, '22-chat-seguimiento');
    await t.tap(find.byTooltip('Open navigation menu'));
    await foto(t, '23-menu');
    t.state<NavigatorState>(find.byType(Navigator).last).pop();
    await asentar(t);
    await seccion(t, 'Descubrir');
    await foto(t, '05-descubrir');
    await t.tap(find.text('Papelería Miranda').first);
    await asentar(t);
    await t.tap(find.byIcon(Icons.add).first);
    await t.pump();
    await t.tap(find.byIcon(Icons.add).first);
    await foto(t, '06-negocio');
    await t.ensureVisible(find.text('Ver mi cuenta'));
    await t.pump();
    await t.tap(find.text('Ver mi cuenta'));
    await foto(t, '07-cuenta');
    await t.tap(find.text('Confirmar pedido'));
    await asentar(t);
    await foto(t, '08-cobro-codi');
    estado = 'pagada';
    await t.pump(const Duration(seconds: 5));
    await foto(t, '09-pagado');
    estado = 'lista';
    await t.pump(const Duration(seconds: 5));
    await foto(t, '10-pedido-listo');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('cuenta y sellos', (t) async {
    await abrir(t, lista);
    await seccion(t, 'Mis pedidos');
    await foto(t, '11-mis-pedidos');
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await asentar(t);
    await seccion(t, 'Perfil');
    await foto(t, '12-perfil');
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await asentar(t);
    await seccion(t, 'Logros');
    await foto(t, '13-sellos');
    for (var i = 0; i < 3; i++) {
      await t.drag(find.byType(ListView).last, const Offset(0, -600));
      await t.pump(const Duration(milliseconds: 300));
    }
    await foto(t, '14-sellos-ciudad');
    await t.tap(find.text('Xochimilco'));
    await foto(t, '15-sello-alcaldia');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('negocio', (t) async {
    conNegocio = false;
    await abrir(t, lista);
    await seccion(t, 'Tu negocio');
    await foto(t, '16-alta-negocio');
    await t.pumpWidget(const SizedBox());
    conNegocio = true;
    await abrir(t, lista);
    await seccion(t, 'Tu negocio');
    await foto(t, '17-panel-resumen');
    await t.tap(find.textContaining('Pedidos'));
    await foto(t, '18-panel-pedidos');
    await t.tap(find.text('Menú'));
    await foto(t, '19-panel-menu');
    await t.tap(find.text('Promos'));
    await foto(t, '20-panel-promociones');
    await t.tap(find.text('Crear promoción'));
    await foto(t, '21-nueva-promocion');
    await t.pumpWidget(const SizedBox());
  });
}
