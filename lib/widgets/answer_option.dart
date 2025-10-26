import 'package:flutter/material.dart';
import 'package:cdl_flutter/constants/constants.dart';

class AnswerOption extends StatelessWidget {
  final Map<String, dynamic> answer;
  final int questionId;
  final int? selectedAnswer;
  final bool showAnswer;
  final int? correctAnswerId;
  final VoidCallback? onTap;

  const AnswerOption({
    Key? key,
    required this.answer,
    required this.questionId,
    required this.selectedAnswer,
    required this.showAnswer,
    required this.correctAnswerId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final answerId = answer["answerId"];
    Color borderColor = Colors.grey.shade300;
    Color? fillColor;
    Color textColor = Colors.black;

    if (showAnswer) {
      if (answerId == correctAnswerId) {
        borderColor = Colors.green;
        fillColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade900;
      } else if (selectedAnswer == answerId && answerId != correctAnswerId) {
        borderColor = kErrorColor;
        fillColor = kErrorColor.withOpacity(0.1);
        textColor = Colors.red.shade900;
      }
    } else if (selectedAnswer == answerId) {
      borderColor = kPrimaryColor;
      fillColor = kPrimaryColor.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fillColor ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          answer["answerText"] ?? "",
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ),
    );
  }
}
