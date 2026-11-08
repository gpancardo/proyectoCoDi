import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barrio_app_pey/app.dart';
import 'package:barrio_app_pey/components/sections/achievements_screen.dart';
import 'package:barrio_app_pey/components/sections/seller_screen.dart';
import 'package:barrio_app_pey/components/sections/seller_setup.dart';
import 'package:barrio_app_pey/services/barrio_api.dart';
import 'package:barrio_app_pey/state/app_state.dart';
import 'package:barrio_app_pey/utils/money.dart';

Widget _app(AppState state) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        Provider(
            create: (_) => BarrioApi(
                client: MockClient(
                    (_) async => http.Response('{"data":{}}', 200)))),
      ],
      child: const BarrioApp(),
    );

void main() {
  setUpAll(() =>
      dotenv.loadFromString(envString: 'API_BASE_URL=https://api.prueba'));

  testWidgets('muestra el alta en la primera visita', (tester) async {
    SharedPreferences.setMockInitialValues({'session_access_token': 'prueba'});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(_app(AppState(preferences)));

    expect(find.text('Lo bueno empieza cerca'), findsOneWidget);
  });

  testWidgets('abre el perfil y guarda los cambios del comprador',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'session_access_token': 'prueba',
      'has_completed_onboarding': true,
      'profile_name': 'Lupita',
      'profile_phone': '5512345678',
      'profile_zone': 'Coyoacán',
      'profile_neighborhood': 'Del Valle',
    });
    final preferences = await SharedPreferences.getInstance();
    final profile = AppState(preferences);

    await tester.pumpWidget(_app(profile));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('profileAction')));
    await tester.pumpAndSettle();

    expect(find.text('Tu perfil'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Lupita Ramírez');
    await tester.enterText(find.byType(TextFormField).at(1), '5587654321');
    await tester.enterText(find.byType(TextFormField).at(2), 'Roma Norte');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(profile.name, 'Lupita Ramírez');
    expect(profile.phone, '5587654321');
    expect(profile.neighborhood, 'Roma Norte');
  });

  Future<void> pumpWith(
      WidgetTester tester, Widget child, Map<String, String> routes) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({'session_access_token': 'prueba'});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppState(preferences)),
        Provider(
            create: (_) => BarrioApi(
                client: MockClient((request) async => http.Response(
                        routes[request.url.path.split('/api/v1').last] ??
                            '{"data":[]}',
                        200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8'
                        })))),
      ],
      child: MaterialApp(home: child),
    ));
    await tester.pumpAndSettle();
  }

  test('dinero: centavos reales y miles', () {
    expect(formatMoney(1), r'$0.01');
    expect(formatMoney(5500), r'$55');
    expect(formatMoney(124000), r'$1,240');
    expect(formatMoney(123456789), r'$1,234,567.89');
  });

  test('precio del menú', () {
    expect(parsePrecio('12.5'), 12.5);
    expect(parsePrecio('12,5'), 12.5);
    expect(parsePrecio('0'), isNull);
    expect(parsePrecio('abc'), isNull);
  });

  testWidgets('sin negocio pide el alta', (tester) async {
    await pumpWith(
        tester, const SellerScreen(), {'/me': '{"data":{"negocio":null}}'});
    expect(find.text('Registra tu negocio'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con negocio muestra pedidos y acciones', (tester) async {
    await pumpWith(tester, const SellerScreen(), {
      '/me':
          '{"data":{"negocio":{"id":1,"nombre":"Papelería Miranda","abierto":true,"productos":[{"nombre":"Pluma","precio":8}]}}}',
      '/orders':
          '{"data":[{"id":5,"estado":"pendiente","total_minor":800,"items":[{"cantidad":1,"nombre":"Pluma"}],"comprador_logros":[{"nombre":"Primera compra"}]}]}',
    });
    expect(find.text('Pedidos (1)'), findsOneWidget);
    await tester.tap(find.text('Pedidos (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Aceptar pedido'), findsOneWidget);
    expect(find.text('Sellos de tu cliente: Primera compra'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('los sellos vienen de la API y muestran el premio',
      (tester) async {
    await pumpWith(tester, const AchievementsScreen(), {
      '/me/profile':
          '{"data":{"pedidos_pagados":1,"premio":{"negocio_id":7,"negocio":"La Espiga","titulo":"10% en tu siguiente compra","min_compra_minor":5000},"insignias":[{"nivel":"primera","nombre":"Primera compra","detalle":"La hiciste en La Espiga.","avance":1,"meta":1,"obtenida":true},{"nivel":"oro","nombre":"De todo en tu barrio","detalle":"Cuatro tipos.","avance":1,"meta":4,"obtenida":false}],"cdmx":{"id":"cdmx","nombre":"Toda la ciudad","nivel":null,"avance":1,"meta":16},"alcaldias":[{"id":"coyoacan","zona":"Coyoacán","nombre":"Lugar de coyotes","nivel":"plata","avance":3,"meta":5}]}}',
    });
    expect(find.text('Llevas 1 compra en tu barrio.'), findsOneWidget);
    expect(find.text('10% en tu siguiente compra'), findsOneWidget);
    expect(find.text('1 de 4'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Coyoacán'), 200);
    expect(find.text('Coyoacán'), findsOneWidget);
  });
}
