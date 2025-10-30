import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static Future<void> saveJson(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode({
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  static Future<Map<String, dynamic>?> loadJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString);
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<bool> isCacheValid(String key, {Duration maxAge = const Duration(days: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return false;
    try {
      final decoded = jsonDecode(jsonString);
      final cachedAt = DateTime.tryParse(decoded['timestamp']);
      if (cachedAt == null) return false;
      return DateTime.now().difference(cachedAt) < maxAge;
    } catch (_) {
      return false;
    }
  }
}
