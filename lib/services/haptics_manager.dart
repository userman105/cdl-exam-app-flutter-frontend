import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticsManager {
  static const String _key = 'haptics_enabled';
  static bool? _cachedValue;

  static Future<bool> isEnabled() async {
    if (_cachedValue != null) return _cachedValue!;
    final prefs = await SharedPreferences.getInstance();
    _cachedValue = prefs.getBool(_key) ?? true;
    return _cachedValue!;
  }

  static Future<void> setEnabled(bool value) async {
    _cachedValue = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static void heavyImpact() {
    if (_cachedValue ?? true) {
      HapticFeedback.heavyImpact();
    }
  }

  static void mediumImpact() {
    if (_cachedValue ?? true) {
      HapticFeedback.mediumImpact();
    }
  }

  static void lightImpact() {
    if (_cachedValue ?? true) {
      HapticFeedback.lightImpact();
    }
  }
}
