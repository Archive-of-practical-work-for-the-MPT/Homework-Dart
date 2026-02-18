import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  const primaryColor = Color(0xFF6750A4);
  const secondaryColor = Color(0xFF03DAC5);
  const backgroundColor = Color(0xFFF5F2FF);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
    ),
  );

  final textTheme = GoogleFonts.rubikTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
  );
}

