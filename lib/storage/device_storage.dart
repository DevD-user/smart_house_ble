import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence utility for storing custom device aliases.
class DeviceStorage {
  static const String _aliasesKey = 'device_aliases';

  /// Retrieves the map of stored device aliases (deviceId -> alias).
  static Future<Map<String, String>> getAliases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_aliasesKey);
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {
      // Safely fallback on read errors
    }
    return {};
  }

  /// Persists a custom alias for a device.
  static Future<void> saveAlias(String deviceId, String alias) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getAliases();
      current[deviceId] = alias;
      await prefs.setString(_aliasesKey, json.encode(current));
    } catch (_) {}
  }

  /// Removes the custom alias configuration for a device.
  static Future<void> removeAlias(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getAliases();
      if (current.containsKey(deviceId)) {
        current.remove(deviceId);
        await prefs.setString(_aliasesKey, json.encode(current));
      }
    } catch (_) {}
  }
}
