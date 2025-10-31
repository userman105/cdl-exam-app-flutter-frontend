import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_report.dart';

class ReportStorage {
  static const _key = "saved_reports";

  static Future<void> saveReport(ExamReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await loadReports();

    reports.add(report);
    final encoded = jsonEncode(reports.map((r) => r.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<List<ExamReport>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final decoded = jsonDecode(jsonString) as List;
    return decoded.map((e) => ExamReport.fromJson(e)).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }


}
Future<void> saveReport({
  required String examName,
  required String dashboardName,
  required int correctAnswers,
  required int wrongAnswers,
  required double percentage,
  required Duration duration,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final reports = prefs.getStringList('saved_reports') ?? [];

  final report = jsonEncode({
    "examName": examName,
    "dashboardName": dashboardName,
    "correct": correctAnswers,
    "wrong": wrongAnswers,
    "percentage": percentage,
    "time": duration.inSeconds,
    "timestamp": DateTime.now().toIso8601String(),
  });

  reports.add(report);
  await prefs.setStringList('saved_reports', reports);

  debugPrint("✅ Saved report for $examName (${percentage.toStringAsFixed(1)}%)");
}

