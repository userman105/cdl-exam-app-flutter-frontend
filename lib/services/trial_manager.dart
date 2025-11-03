import 'package:shared_preferences/shared_preferences.dart';

class TrialManager {
  static const _keyAttempts = "available_trials";
  static const _keyLastReset = "last_trial_reset";
  static const int _dailyMax = 10;

  /// Get current remaining attempts and reset if it's a new day
  static Future<int> getRemaining() async {
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

  /// Decrement one attempt and return the updated count
  static Future<int> useOne() async {
    final prefs = await SharedPreferences.getInstance();
    int left = prefs.getInt(_keyAttempts) ?? _dailyMax;
    if (left > 0) {
      left--;
      await prefs.setInt(_keyAttempts, left);
    }
    return left;
  }

  /// Reset to full 10 attempts
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAttempts, _dailyMax);
    await prefs.setString(_keyLastReset, DateTime.now().toIso8601String());
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
