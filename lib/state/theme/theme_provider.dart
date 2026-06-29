import 'package:flutter/material.dart';

/// Represents the available themes in the application.
enum AppThemeMode {
  light,
  dark,
}

/// State management provider for handling application theme changes.
class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentTheme = AppThemeMode.dark;

  /// Gets the current theme mode.
  AppThemeMode get currentTheme => _currentTheme;

  /// Returns true if the current theme is dark mode.
  bool get isDarkMode => _currentTheme == AppThemeMode.dark;

  /// Toggles between light and dark theme modes.
  void toggleTheme() {
    _currentTheme = _currentTheme == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    notifyListeners();
  }

  /// Sets the theme to dark mode.
  void setDarkMode() {
    _currentTheme = AppThemeMode.dark;
    notifyListeners();
  }

  /// Sets the theme to light mode.
  void setLightMode() {
    _currentTheme = AppThemeMode.light;
    notifyListeners();
  }

  /// Resets the theme to the default dark mode.
  void resetTheme() {
    _currentTheme = AppThemeMode.dark;
    notifyListeners();
  }
}
