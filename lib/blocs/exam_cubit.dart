import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache_service.dart';
part 'exam_state.dart';

class ExamCubit extends Cubit<ExamState> {
  ExamCubit() : super(ExamInitial());

  final List<int> _wrongQuestionIds = [];

  Future<void> loadExam(BuildContext context, int examId) async {
    emit(ExamLoading());

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
              backgroundColor: Colors.blue[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        debugPrint("⚠ Corrupted cache for exam_$examId");
      }
    }

    // 2️⃣ Try fetching fresh data in background
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:3333/exam-attempts/$examId'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString("exam_$examId", jsonEncode(data));

        emit(ExamLoaded(examData: data, selectedAnswers: {}));
        debugPrint(" Exam $examId refreshed from network");
      } else {
        if (state is! ExamLoaded) {
          emit(ExamError("Failed to fetch exam: ${response.statusCode}"));
        }
      }
    } on TimeoutException {
      if (state is! ExamLoaded) {
        emit(ExamError("Request timed out. Please check your connection."));
      } else {
        debugPrint("️ Timeout ignored because cache was already loaded");
      }
    } catch (e) {
      if (state is! ExamLoaded) {
        emit(ExamError("Failed to load exam: $e"));
      } else {
        debugPrint("⚠ Network error ignored (using cache)");
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
        debugPrint(" Corrupted previous mistakes data for $examKey, resetting.");
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
      " Saved persistent 'Previous Mistakes ($examKey)' with "
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
      String examKey,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("exam_previous_mistakes_$examKey");

    if (saved == null) return;

    final existing = jsonDecode(saved);
    final questions = List<Map<String, dynamic>>.from(existing["questions"]);

    final updatedQuestions = <Map<String, dynamic>>[];

    for (final q in questions) {
      final qid = q["questionId"] as int?;

      if (qid == null) continue;

      final selected = selectedAnswers[qid];
      final correct = (q["correctAnswer"] ??
          q["correct_answer_id"] ??
          q["correct_option_id"]) as int?;

      // If the user didn't answer or answered wrong → keep it
      if (selected == null || correct == null || selected != correct) {
        updatedQuestions.add(q);
      } else {
        debugPrint(" Removing question $qid (answered correctly)");
      }
    }

    Future<int> loadGeneralKnowledgeCount() async {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString("exam_1"); // or exam_general
      if (cached == null) return 0;

      try {
        final data = jsonDecode(cached);
        final questions = data["questions"] as List?;
        return questions?.length ?? 0;
      } catch (_) {
        return 0;
      }
    }


    // If all are correct → delete mistakes exam entirely
    if (updatedQuestions.isEmpty) {
      await prefs.remove("exam_previous_mistakes_$examKey");
      debugPrint(" All mistakes fixed for '$examKey' — exam removed.");
    } else {
      // Otherwise, save only remaining wrongs
      final updatedExam = {
        "id": existing["id"],
        "title": existing["title"],
        "questions": updatedQuestions,
      };

      await prefs.setString(
        "exam_previous_mistakes_$examKey",
        jsonEncode(updatedExam),
      );

      debugPrint(" Cleaned '$examKey' mistakes exam — now ${updatedQuestions.length} remain.");
    }
  }
  Map<int, int?> get selectedAnswers {
    if (state is ExamLoaded) {
      return Map<int, int?>.from((state as ExamLoaded).selectedAnswers);
    }
    return {};
  }

  Future<void> clearAllSavedExams(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    // Only remove keys related to exams or mistakes
    final removed = <String>[];
    for (final key in allKeys) {
      if (key.startsWith("exam_") || key.startsWith("exam_previous_mistakes_")) {
        await prefs.remove(key);
        removed.add(key);
      }
    }

    debugPrint(" Cleared ${removed.length} saved exam entries.");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cleared ${removed.length} saved exams and mistakes."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> loadFromLocalJson(Map<String, dynamic> examData) async {
    emit(ExamLoaded(examData: examData, selectedAnswers: {}));
  }


}
