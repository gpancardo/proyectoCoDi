import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'services/barrio_api.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.example');
  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final publishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
  if (supabaseUrl.isEmpty || publishableKey.isEmpty) {
    throw StateError('Configura SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY.');
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: publishableKey);
  final preferences = await SharedPreferences.getInstance();
  final state = AppState(preferences);
  final api = BarrioApi();
  final auth = Supabase.instance.client.auth;
  final currentSession = auth.currentSession;
  if (currentSession != null) {
    await state.saveSession(
        currentSession.accessToken, currentSession.refreshToken ?? '');
  }
  auth.onAuthStateChange.listen((event) async {
    final session = event.session;
    if (session == null) {
      await state.signOut();
    } else {
      await state.saveSession(session.accessToken, session.refreshToken ?? '');
    }
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
}
