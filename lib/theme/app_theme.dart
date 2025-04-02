import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0C588C),
    primary: const Color(0xFF0C588C),
    secondary: const Color(0xFFE0622C),
    tertiary: const Color(0xFF6DA544),
  ),
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF4A4A4A)),
    bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0C588C),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  useMaterial3: true,
);
