import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'exam_state.dart';

class ExamCubit extends Cubit<ExamState> {
  ExamCubit() : super(ExamInitial());

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
        emit(ExamError("Failed to fetch exam: ${response.statusCode}"));
      }
    } on TimeoutException {
      emit(ExamError("Request timed out. Please check your internet connection."));
    } catch (e) {
      debugPrint("loadExam failed: $e");

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
      Map<String, dynamic> question, bool isCorrect, String examKey) async {
    final questionId = question["questionId"] as int;

    if (!isCorrect && !_wrongQuestionIds.contains(questionId)) {
      _wrongQuestionIds.add(questionId);
      debugPrint("❌ Added wrong answer (total now ${_wrongQuestionIds.length})");
    }

    // Only create when session ends or after 10+
    if (_wrongQuestionIds.length >= 10) {
      await _createMistakesExam(examKey);
    }
  }

  Future<void> _createMistakesExam(String examKey) async {
    if (state is! ExamLoaded) return;

    final current = state as ExamLoaded;
    final allQuestions = current.examData["questions"] as List?;

    if (allQuestions == null || allQuestions.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // Load existing mistakes if any
    List<dynamic> existingMistakes = [];
    final saved = prefs.getString("exam_previous_mistakes_$examKey");
    if (saved != null) {
      try {
        final existing = jsonDecode(saved);
        existingMistakes = (existing["questions"] as List?) ?? [];
      } catch (_) {
        debugPrint("⚠️ Corrupted previous mistakes data for $examKey, resetting.");
      }
    }

    // Add new unique mistakes
    final newMistakes = allQuestions
        .where((q) => _wrongQuestionIds.contains(q["questionId"]))
        .toList();

    // Merge and remove duplicates by questionId
    final merged = {
      for (var q in [...existingMistakes, ...newMistakes])
        q["questionId"]: q
    }.values.toList();

    final mergedQuestions = merged.take(64).toList();

    final mistakesExam = {
      "id": "mistakes_$examKey",
      "title": "Previous Mistakes ($examKey)",
      "questions": mergedQuestions,
    };

    await prefs.setString(
      "exam_previous_mistakes_$examKey",
      jsonEncode(mistakesExam),
    );

    debugPrint(
      "✅ Saved persistent 'Previous Mistakes ($examKey)' with "
          "${mergedQuestions.length} questions.",
    );
  }

  Future<Map<String, dynamic>?> getPreviousMistakesExamData(String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("exam_previous_mistakes_$examKey");
    if (data == null) {
      debugPrint(" No previous mistakes exam found for '$examKey'");
      return null;
    }

    try {
      final decoded = jsonDecode(data);
      debugPrint(" Loaded persistent mistakes exam data for button '$examKey' "
          "(${(decoded["questions"] as List?)?.length ?? 0} questions)");
      return decoded;
    } catch (e) {
      debugPrint(" Failed to decode mistakes exam for '$examKey': $e");
      return null;
    }
  }

  Future<void> loadMistakesExamIntoState(Map<String, dynamic> mistakesExam) async {
    emit(ExamLoaded(examData: mistakesExam, selectedAnswers: {}));
  }
  Future<void> updatePreviousMistakesAfterExam(
      Map<int, int?> selectedAnswers,
      List<dynamic> allQuestions,
      String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("exam_previous_mistakes_$examKey");

    if (saved == null) return;

    final existing = jsonDecode(saved);
    final questions = List<Map<String, dynamic>>.from(existing["questions"]);

    final updatedQuestions = questions.where((q) {
      final qid = q["questionId"];
      final selected = selectedAnswers[qid];
      final correct = q["correctAnswer"];
      return selected != correct;
    }).toList();

    final updatedExam = {
      "id": existing["id"],
      "title": "Previous Mistakes ($examKey)",
      "questions": updatedQuestions,
    };

    await prefs.setString("exam_previous_mistakes_$examKey", jsonEncode(updatedExam));

    debugPrint("🧹 Cleaned '$examKey' mistakes exam — now ${updatedQuestions.length} remain.");
  }

}
