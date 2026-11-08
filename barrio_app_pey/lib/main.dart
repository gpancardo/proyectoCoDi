import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/avisos.dart';
import 'services/barrio_api.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.example');
  final preferences = await SharedPreferences.getInstance();
  final state = AppState(preferences);
  final api = BarrioApi();

  // La sesión dura una hora: se renueva al abrir, al volver a la app y cada 45 min.
  Future<void> renovar() async {
    final refresh = preferences.getString('session_refresh_token') ?? '';
    if (refresh.isEmpty) return;
    try {
      final data = await api.refresh(refresh);
      await state.saveSession(
          data['access_token'].toString(), data['refresh_token'].toString());
    } on BarrioApiException {
      await state.signOut(); // la sesión ya no sirve: que vuelva a entrar
    } catch (_) {/* sin señal: se intenta en la siguiente vuelta */}
  }

  await renovar().timeout(const Duration(seconds: 5), onTimeout: () {});
  Timer.periodic(const Duration(minutes: 45), (_) => renovar());
  final avisos = AvisosPedidos(state, api);
  AppLifecycleListener(onResume: () {
    renovar();
    avisos.revisar();
  });
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        Provider.value(value: api),
      ],
      child: const BarrioApp(),
    ),
  );
  avisos.iniciar();
}
