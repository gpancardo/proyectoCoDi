import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/sections/chat_screen.dart';
import 'components/sections/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

class BarrioApp extends StatelessWidget {
  const BarrioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barrio',
      debugShowCheckedModeBanner: false,
      theme: BarrioTheme.light,
      home: Consumer<AppState>(
        builder: (context, state, _) => state.isFirstVisit
            ? const OnboardingScreen()
            : const ChatScreen(),
      ),
    );
  }
}
