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

    expect(find.text('Primero, cuéntanos de ti'), findsOneWidget);
  });
}
