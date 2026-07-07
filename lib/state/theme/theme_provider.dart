import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents the available themes in the application.
enum AppThemeMode {
  light,
  dark,
}

/// State management provider for handling application theme changes.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_preference';

  AppThemeMode _currentTheme;

  /// Creates a [ThemeProvider] with an optional initial theme.
  /// Defaults to [AppThemeMode.dark] if no preference is supplied.
  ThemeProvider({AppThemeMode? initialTheme})
      : _currentTheme = initialTheme ?? AppThemeMode.dark;

  /// Gets the current theme mode.
  AppThemeMode get currentTheme => _currentTheme;

  /// Returns true if the current theme is dark mode.
  bool get isDarkMode => _currentTheme == AppThemeMode.dark;

  /// Saves the theme preference asynchronously.
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _currentTheme.name);
  }

  /// Toggles between light and dark theme modes.
  void toggleTheme() {
    _currentTheme = _currentTheme == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  /// Sets the theme to dark mode.
  void setDarkMode() {
    _currentTheme = AppThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  /// Sets the theme to light mode.
  void setLightMode() {
    _currentTheme = AppThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  /// Resets the theme to the default dark mode.
  void resetTheme() {
    _currentTheme = AppThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }
}
