import 'package:shared_preferences/shared_preferences.dart';

class TrialManager {
  static const bool enabled = false;
  static const _keyAttempts = "available_trials";
  static const _keyLastReset = "last_trial_reset";
  static const int _dailyMax = 10;


  static Future<int> getRemaining() async {
    if (!enabled) {
      return _dailyMax; // unlimited / always full
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final lastResetStr = prefs.getString(_keyLastReset);
    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      if (!_isSameDay(now, lastReset)) {
        await reset();
      }
    } else {
      await reset();
    }

    return prefs.getInt(_keyAttempts) ?? _dailyMax;
  }


  static Future<int> useOne() async {
    if (!enabled) {
      return _dailyMax; // never decreases
    }

    final prefs = await SharedPreferences.getInstance();
    int left = prefs.getInt(_keyAttempts) ?? _dailyMax;
    if (left > 0) {
      left--;
      await prefs.setInt(_keyAttempts, left);
    }
    return left;
  }

  static Future<void> reset() async {
    if (!enabled) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAttempts, _dailyMax);
    await prefs.setString(_keyLastReset, DateTime.now().toIso8601String());
  }


  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
