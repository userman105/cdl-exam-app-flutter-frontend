part of 'exam_cubit.dart';

abstract class ExamState {}

class ExamInitial extends ExamState {}

class ExamLoading extends ExamState {}

class ExamLoaded extends ExamState {
  final Map<String, dynamic> examData;
  final Map<int, int?> selectedAnswers;

  ExamLoaded({
    required this.examData,
    required this.selectedAnswers,
  });

  ExamLoaded copyWith({
    Map<String, dynamic>? examData,
    Map<int, int?>? selectedAnswers,
  }) {
    return ExamLoaded(
      examData: examData ?? this.examData,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    );
  }
}

class ExamError extends ExamState {
  final String message;
  ExamError(this.message);
}
