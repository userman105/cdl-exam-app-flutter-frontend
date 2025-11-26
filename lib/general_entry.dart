import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/exam_cubit.dart';
import '../widgets/unit_button.dart';
import 'general_bank_screen.dart';
import 'general_study_tab.dart';
class GeneralKnowledgeExtraTab extends StatefulWidget {
  const GeneralKnowledgeExtraTab({Key? key}) : super(key: key);

  @override
  State<GeneralKnowledgeExtraTab> createState() =>
      _GeneralKnowledgeExtraTabState();
}

class _GeneralKnowledgeExtraTabState extends State<GeneralKnowledgeExtraTab> {
  final Map<String, double> _progressExtraUnits = {};

  @override
  void initState() {
    super.initState();
    _loadProgressExtra();
  }

  Future<void> _loadProgressExtra() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("extra_units_progress");
    if (saved != null) {
      setState(() {
        _progressExtraUnits
            .addAll(Map<String, double>.from(jsonDecode(saved)));
      });
    }
  }

  Future<void> _saveProgressExtra() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "extra_units_progress",
      jsonEncode(_progressExtraUnits),
    );
  }

  void _updateProgress(String key, double progress) {
    setState(() => _progressExtraUnits[key] = progress);
    _saveProgressExtra();
  }

  /// Show resume/start dialog
  Future<bool?> _showResumeDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('progress_questionsbank') ?? 0;

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
    final savedPage = prefs.getInt('progress_questionsbank') ?? 0;

    final examState = context.read<ExamCubit>().state;
    if (examState is ExamLoaded) {
      final totalQuestions = examState.examData["totalQuestions"] ?? 1;
      return savedPage / totalQuestions;
    }

    return 0.0;
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
                      builder: (_) => GeneralKnowledgeQuestionsTab(
                        resumeFromLast: resume == true,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          UnitButton(
            title: "اسئلة بالأجوبة",
            questionCount: totalQuestions,
            progress: _progressExtraUnits["progress_placeholder_b"] ?? 0.0,
            iconAsset: "assets/icons/unit_button_icon.png",
            onTap: () {
              _updateProgress("progress_placeholder_b", 0.1);

            Navigator.push(context,
                MaterialPageRoute(builder: (_)=>GeneralKnowledgeStudyTab( resumeFromLast:true)));
            },
          ),
        ],
      ),
    );
  }
}
