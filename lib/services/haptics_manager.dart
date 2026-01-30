import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticsManager {
  static const String _key = 'haptics_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true; // default ON
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static Future<void> heavyImpact() async {
    if (await isEnabled()) {
      HapticFeedback.heavyImpact();
    }
  }

  static Future<void> mediumImpact() async {
    if (await isEnabled()) {
      HapticFeedback.mediumImpact();
    }
  }

  static Future<void> lightImpact() async {
    if (await isEnabled()) {
      HapticFeedback.lightImpact();
    }
  }
}
