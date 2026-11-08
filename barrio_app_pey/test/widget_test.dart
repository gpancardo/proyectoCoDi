import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barrio_app_pey/app.dart';
import 'package:barrio_app_pey/state/app_state.dart';

void main() {
  testWidgets('muestra el alta en la primera visita', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(preferences),
        child: const BarrioApp(),
      ),
    );

    expect(find.text('Lo bueno empieza cerca'), findsOneWidget);
  });

  testWidgets('abre el perfil y guarda los cambios del comprador',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'profile_name': 'Lupita',
      'profile_phone': '5512345678',
      'profile_zone': 'Coyoacán',
      'profile_neighborhood': 'Del Valle',
    });
    final preferences = await SharedPreferences.getInstance();
    final profile = AppState(preferences);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: profile,
        child: const BarrioApp(),
      ),
    );
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
