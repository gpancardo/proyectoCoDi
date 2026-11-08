import 'package:flutter/material.dart';

abstract final class BarrioColors {
  static const marino = Color(0xFF0B2545);
  static const mango = Color(0xFFF5A524);
  static const mangoPressed = Color(0xFFDB8E12);
  static const crema = Color(0xFFFFF8EC);
  static const teal = Color(0xFF0F7C75);
  static const tinta = Color(0xFF1A1F2B);
  static const gris = Color(0xFF5B6472);
  static const rojo = Color(0xFFC2392B);
  static const blanco = Color(0xFFFFFFFF);
  static const borde = Color(0xFFE8DFCF);
  static const trazo = Color(0xFF7D7666);
  static const niebla = Color(0xFFE8EDF4);
}

abstract final class BarrioTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: BarrioColors.marino,
      primary: BarrioColors.marino,
      secondary: BarrioColors.mango,
      surface: BarrioColors.blanco,
      error: BarrioColors.rojo,
    );
    return ThemeData(
      useMaterial3: false,
      primaryColor: BarrioColors.marino,
      colorScheme: scheme,
      scaffoldBackgroundColor: BarrioColors.crema,
      fontFamily: 'Archivo',
      appBarTheme: const AppBarTheme(
        backgroundColor: BarrioColors.crema,
        foregroundColor: BarrioColors.marino,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: BarrioColors.marino),
        titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BarrioColors.marino),
        bodyLarge: TextStyle(fontSize: 17, color: BarrioColors.tinta),
        bodyMedium: TextStyle(fontSize: 15, color: BarrioColors.tinta),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BarrioColors.blanco,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: BarrioColors.trazo, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: BarrioColors.trazo, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: BarrioColors.marino, width: 2)),
        hintStyle: const TextStyle(color: BarrioColors.gris),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BarrioColors.mango,
          foregroundColor: BarrioColors.marino,
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          side: const BorderSide(color: BarrioColors.marino, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: BarrioColors.blanco,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: BarrioColors.marino, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
