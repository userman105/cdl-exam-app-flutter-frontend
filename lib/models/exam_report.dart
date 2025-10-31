import 'dart:convert';

class ExamReport {
  final String examName;
  final String dashboardName;
  final int correctAnswers;
  final int wrongAnswers;
  final double percentage;
  final String timeElapsed;
  final DateTime createdAt;

  ExamReport({
    required this.examName,
    required this.dashboardName,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.timeElapsed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    "examName": examName,
    "dashboardName": dashboardName,
    "correctAnswers": correctAnswers,
    "wrongAnswers": wrongAnswers,
    "percentage": percentage,
    "timeElapsed": timeElapsed,
    "createdAt": createdAt.toIso8601String(),
  };

  factory ExamReport.fromJson(Map<String, dynamic> json) => ExamReport(
    examName: json["examName"],
    dashboardName: json["dashboardName"],
    correctAnswers: json["correctAnswers"],
    wrongAnswers: json["wrongAnswers"],
    percentage: json["percentage"],
    timeElapsed: json["timeElapsed"],
    createdAt: DateTime.parse(json["createdAt"]),
  );
}
