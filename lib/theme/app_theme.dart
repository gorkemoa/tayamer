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
    displayLarge: TextStyle(fontSize: 20), // H1
    displayMedium: TextStyle(fontSize: 18), // H2
    displaySmall: TextStyle(fontSize: 16), // H3
    headlineLarge: TextStyle(fontSize: 15), // H4
    headlineMedium: TextStyle(fontSize: 14), // H5
    headlineSmall: TextStyle(fontSize: 12), // H6
    titleLarge: TextStyle(fontSize: 13), // Title
    bodyLarge: TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)), // Body 1
    bodyMedium: TextStyle(fontSize: 12, color: Color(0xFF4A4A4A)), // Body 2
    labelLarge: TextStyle(fontSize: 12), // Button
    labelMedium: TextStyle(fontSize: 10), // Caption
    labelSmall: TextStyle(fontSize: 9), // Overline
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0C588C),
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(size: 20),
    toolbarHeight: 50,
  ),
  iconTheme: const IconThemeData(
    size: 20,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  useMaterial3: true,
);
