import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'exam_state.dart';

class ExamCubit extends Cubit<ExamState> {
  ExamCubit() : super(ExamInitial());

  // Track wrong questions
  final List<int> _wrongQuestionIds = [];

  Future<void> loadExam(BuildContext context, int examId) async {
    emit(ExamLoading());
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:3333/exam-attempts/$examId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("exam_$examId", jsonEncode(data));

        emit(ExamLoaded(examData: data, selectedAnswers: {}));
      } else {
        throw Exception("Failed to fetch exam: ${response.statusCode}");
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString("exam_$examId");

      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          emit(ExamLoaded(examData: data, selectedAnswers: {}));

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Loaded exam from cache"),
                backgroundColor: Colors.orange[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (_) {
          emit(ExamError("Cache corrupted, please reconnect to the internet."));
        }
      } else {
        emit(ExamError("No cached exam found and failed to fetch online."));
      }
    }
  }

  void selectAnswer(int questionId, int answerId) {
    if (state is ExamLoaded) {
      final current = state as ExamLoaded;
      final updatedAnswers = Map<int, int?>.from(current.selectedAnswers);
      updatedAnswers[questionId] = answerId;
      emit(current.copyWith(selectedAnswers: updatedAnswers));
    }
  }

  Future<void> markAnswerResult(
      Map<String, dynamic> question, bool isCorrect) async {
    final questionId = question["questionId"] as int;

    if (!isCorrect && !_wrongQuestionIds.contains(questionId)) {
      _wrongQuestionIds.add(questionId);
    }

    // Create "Previous Mistakes" exam when user hits 10 wrong answers
    if (_wrongQuestionIds.length == 10) {
      await _createMistakesExam();
    }
  }

  Future<void> _createMistakesExam() async {
    if (state is! ExamLoaded) return;
    final current = state as ExamLoaded;
    final allQuestions = current.examData["questions"] as List;

    final mistakeQuestions = allQuestions
        .where((q) => _wrongQuestionIds.contains(q["questionId"]))
        .take(64)
        .toList();

    final mistakesExam = {
      "id": "mistakes_${DateTime.now().millisecondsSinceEpoch}",
      "title": "Previous Mistakes",
      "questions": mistakeQuestions,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("exam_previous_mistakes", jsonEncode(mistakesExam));

    debugPrint("✅ Created 'Previous Mistakes' exam with ${mistakeQuestions.length} questions");
  }

  Future<Map<String, dynamic>?> loadPreviousMistakesExam() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("exam_previous_mistakes");
    if (saved != null) {
      return jsonDecode(saved);
    }
    return null;
  }

  void clearMistakes() {
    _wrongQuestionIds.clear();
  }

  // 🆕 New: Remove correctly answered questions from the mistakes list
  Future<void> updatePreviousMistakesAfterExam(
      Map<int, int?> selectedAnswers, List<dynamic> allQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("exam_previous_mistakes");

    if (saved == null) return;

    final existing = jsonDecode(saved);
    final questions = List<Map<String, dynamic>>.from(existing["questions"]);

    // Keep only those that were NOT correctly answered in the recent exam
    final updatedQuestions = questions.where((q) {
      final qid = q["questionId"];
      final selected = selectedAnswers[qid];
      final correct = q["correctAnswer"];
      return selected != correct;
    }).toList();

    final updatedExam = {
      "id": existing["id"],
      "title": "Previous Mistakes",
      "questions": updatedQuestions,
    };

    await prefs.setString("exam_previous_mistakes", jsonEncode(updatedExam));

    debugPrint(
        "🧹 Cleaned 'Previous Mistakes' exam: now ${updatedQuestions.length} questions remain");
  }
}
