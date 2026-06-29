import 'package:flutter/material.dart';

/// Application theme definitions for both Light and Dark modes.
class AppTheme {
  AppTheme._();

  /// Dark theme configuration.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1115),
    cardColor: const Color(0xFF1A1D24),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1115),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1A1D24),
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00BCD4),
      secondary: Color(0xFF00BCD4),
      surface: Color(0xFF1A1D24),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFF9E9E9E)),
    ),
  );

  /// Light theme configuration.
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F9FC),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0288D1),
      secondary: Color(0xFF0288D1),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1A1A1A),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: TextStyle(color: Color(0xFF757575)),
    ),
  );
}
