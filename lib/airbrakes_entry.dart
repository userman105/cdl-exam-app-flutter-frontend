import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/unit_button.dart';
import 'blocs/exam_cubit.dart';
import 'airbrakes_study_tab.dart';
import 'airbrakes_bank_screen.dart';


class AirBrakesExtraTab extends StatefulWidget {
  const AirBrakesExtraTab({Key? key}) : super(key: key);

  @override
  State<AirBrakesExtraTab> createState() => _AirBrakesExtraTabState();
}

class _AirBrakesExtraTabState extends State<AirBrakesExtraTab> {
  final Map<String, double> _progressExtraUnitsAirbrakes = {};

  @override
  void initState() {
    super.initState();
    _loadProgressExtra();
  }

  Future<void> _loadProgressExtra() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("airbrakes_extra_units_progress");
    if (saved != null) {
      setState(() {
        _progressExtraUnitsAirbrakes
            .addAll(Map<String, double>.from(jsonDecode(saved)));
      });
    }
  }

  /// Show resume/start dialog
  Future<bool?> _showResumeDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('airbrakes_progress_questionsbank') ?? 0;

    if (savedPage == 0) return false; // No dialog needed

    return showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("استكمال التقدم؟"),
          content: const Text("هل تريد الرجوع لنفس السؤال الذي توقفت عنده؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("ابدأ من جديد"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("استكمال"),
            ),
          ],
        );
      },
    );
  }

  /// Get dynamic progress percentage based on last saved question
  Future<double> _getProgressPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('airbrakes_progress_questionsbank') ?? 0;

    final examState = context.read<ExamCubit>().state;
    if (examState is ExamLoaded) {
      final totalQuestions = examState.examData["totalQuestions"] ?? 1;
      return savedPage / totalQuestions;
    }

    return 0.0;
  }

  Future<double> _getProgressPercentageStudy() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('airbrakes_progress_questionsbank_study') ?? 0;

    final examState = context.read<ExamCubit>().state;
    if (examState is ExamLoaded) {
      final total = examState.examData["totalQuestions"] ?? 1;
      return savedPage / total;
    }

    return 0.0;
  }

  Future<int?> _getQuestionsProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('airbrakes_progress_questionsbank')) {
      return null; // user never opened questions tab
    }
    return prefs.getInt('airbrakes_progress_questionsbank');
  }

  @override
  Widget build(BuildContext context) {
    final examState = context.watch<ExamCubit>().state;

    int totalQuestions = 0;
    if (examState is ExamLoaded) {
      totalQuestions = examState.examData["totalQuestions"] ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          // ------------------------------------------------
          // 🔵 BUTTON A — MCQ QUESTIONS
          // ------------------------------------------------
          FutureBuilder<double>(
            future: _getProgressPercentage(),
            builder: (context, snapshot) {
              final progress = snapshot.data ?? 0.0;

              return UnitButton(
                title: "اسئلة بالاختيارات",
                questionCount: totalQuestions,
                progress: progress,
                iconAsset: "assets/icons/unit_button_icon.png",
                onTap: () async {
                  bool? resume = await _showResumeDialog(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AirbrakesQuestionsTab(
                        resumeFromLast: resume == true,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------
          // 🟢 BUTTON B — STUDY MODE
          // ------------------------------------------------
          FutureBuilder<double>(
            future: _getProgressPercentageStudy(),
            builder: (context, snapshot) {
              final studyProgress = snapshot.data ?? 0.0;

              return UnitButton(
                title: "اسئلة بالأجوبة",
                questionCount: totalQuestions,
                progress: studyProgress,
                iconAsset: "assets/icons/unit_button_icon.png",
                onTap: () async {
                  bool? resume = await _showResumeDialog(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AirBrakesStudyTab(
                        resumeFromLast: resume == true,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------
          // 🟧 BUTTON C — TRACKS MCQ PROGRESS ONLY
          // ------------------------------------------------
          FutureBuilder<int?>(
            future: _getQuestionsProgress(),
            builder: (context, snapshot) {
              final progress = snapshot.data;

              return UnitButton(
                title: "امتحان فعلي",
                questionCount: progress != null ? progress + 1 : 0,
                progress: progress != null ? (progress + 1) / totalQuestions : 0.0,
                iconAsset: "assets/icons/unit_button_icon.png",
                onTap: () async {
                  if (progress == null) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("لا يوجد تقدم"),
                        content: const Text("يبدو أنك لم تبدأ حل الأسئلة بعد."),
                        actions: [
                          TextButton(
                            child: const Text("حسناً"),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AirbrakesQuestionsTab(
                        resumeFromLast: true,
                        questionLimit: progress + 1,
                      ),
                    ),
                  );
                },
              );
            },
          ),

        ],
      ),
    );
  }
}