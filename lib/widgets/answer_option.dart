import 'package:flutter/material.dart';

class AnswerOption extends StatelessWidget {
  final dynamic answer;
  final int questionId;
  final int? selectedAnswer;
  final bool showAnswer;
  final VoidCallback? onTap;

  const AnswerOption({
    Key? key,
    required this.answer,
    required this.questionId,
    required this.selectedAnswer,
    required this.showAnswer,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final answerId = answer["answerId"];
    final isCorrect = answerId == questionId;
    final isSelected = selectedAnswer == answerId;

    Color? backgroundColor;
    Color textColor = Colors.black;

    if (showAnswer && isCorrect) {
      backgroundColor = Colors.green.withOpacity(0.85);
      textColor = Colors.white;
    } else if (showAnswer && isSelected && !isCorrect) {
      backgroundColor = Colors.red.withOpacity(0.85);
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: RadioListTile<int>(
        title: Text(
          answer["answerText"],
          style: TextStyle(color: textColor),
        ),
        value: answerId,
        groupValue: selectedAnswer,
        onChanged: onTap != null ? (_) => onTap!() : null,
      ),
    );
  }
}
