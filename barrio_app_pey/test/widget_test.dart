import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barrio_app_pey/app.dart';
import 'package:barrio_app_pey/services/barrio_api.dart';
import 'package:barrio_app_pey/state/app_state.dart';

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
}
