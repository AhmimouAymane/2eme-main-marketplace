import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for local data persistence (JSON caching).
/// Useful for "Stale-While-Revalidate" patterns to achieve instant UI.
class CacheService {
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  /// Saves a list of objects as a JSON string.
  Future<void> saveList(String key, List<dynamic> list) async {
    try {
      final String jsonStr = jsonEncode(list);
      await _prefs.setString(key, jsonStr);
    } catch (e) {
      print('CacheService: Error saving list for key $key: $e');
    }
  }

  /// Retrieves a list of objects from a JSON string.
  List<T> getList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final String? jsonStr = _prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      print('CacheService: Error getting list for key $key: $e');
      return [];
    }
  }

  /// Removes data for a specific key.
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Clears all cached data (useful for logout).
  Future<void> clearAll() async {
    // Only clear keys owned by this service if needed, or clear all for full reset.
    // For simplicity, we can just clear matching keys or everything.
    await _prefs.clear();
  }
}
