import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../report_card.dart'; // Assuming the updated ReportCard is in this file

class ReportCardPersistence {
  static const String _key = 'exam_report_cards';

  // Saves a single ReportCard instance to SharedPreferences
  static Future<void> saveReportCard(ReportCard reportCard) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get the existing list of reports (as JSON strings)
    final List<String> reportsJson = prefs.getStringList(_key) ?? [];

    // 2. Convert the new ReportCard to a JSON string
    final newReportJson = jsonEncode(reportCard.toJson());

    // 3. Add the new report to the list
    reportsJson.add(newReportJson);

    // 4. Save the updated list back to SharedPreferences
    await prefs.setStringList(_key, reportsJson);
  }

  // Loads all saved ReportCard instances
  // Loads all saved ReportCard instances
  static Future<List<Map<String, dynamic>>> loadAllReportCards() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> reportsJson = prefs.getStringList(_key) ?? [];

    return reportsJson.map((jsonString) {
      try {
        final decoded = jsonDecode(jsonString);

        // FIX: Explicitly cast the map keys to String
        return Map<String, dynamic>.from(decoded);

      } catch (e) {
        print('Error decoding report card JSON: $e');
        return <String, dynamic>{};
      }
    }).toList();
  }


  // Utility to clear all saved reports (for testing/cleanup)
  static Future<void> clearAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
