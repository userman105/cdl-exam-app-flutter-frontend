import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'exam_state.dart';

class ExamCubit extends Cubit<ExamState> {
  ExamCubit() : super(ExamInitial());

  Future<void> loadExam(BuildContext context, int examId) async {
    emit(ExamLoading());
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:3333/exam-attempts/$examId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Cache exam data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("exam_$examId", jsonEncode(data));

        emit(ExamLoaded(examData: data, selectedAnswers: {}));
      } else {
        throw Exception("Failed to fetch exam: ${response.statusCode}");
      }
    } catch (e) {
      // Try loading cached data
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString("exam_$examId");

      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          emit(ExamLoaded(examData: data, selectedAnswers: {}));

          // Show snackbar if UI context provided
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Loaded from cache "),
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
}
