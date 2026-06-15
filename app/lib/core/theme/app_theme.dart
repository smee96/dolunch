import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFF0457E);
  static const accent = Color(0xFFFF8A3D);
  static const deep = Color(0xFF9B2F6B);
  static const base = Color(0xFFFFF6F0);
  static const sub = Color(0xFF9B7E89);
  static const ink = Color(0xFF241019);
  static const line = Color(0xFFF0E6E6);
  static const success = Color(0xFF1FA86B);
  static const danger = Color(0xFFDD1144);
  static const star = Color(0xFFFFB23E);
  static const darkBg = Color(0xFF15090F);

  static const glamGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [accent, primary, deep],
    stops: [0.0, 0.55, 1.0],
  );

  static const profileCoverGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.5, 1),
    colors: [accent, primary, Color(0xFF6A2150)],
    stops: [0.0, 0.5, 1.0],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: AppColors.base,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.base,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.base,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFFC3B2B8),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      fillColor: Colors.white,
      filled: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Pretendard'),
      ),
    ),
  );
}
