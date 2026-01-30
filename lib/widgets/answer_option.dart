import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cdl_flutter/constants/constants.dart';
import 'package:flutter/services.dart';
import '../services/haptics_manager.dart';

import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cdl_flutter/services/haptics_manager.dart';
import 'package:animate_do/animate_do.dart';

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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final error = theme.colorScheme.error;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    final int answerId = answer["answerId"];
    final bool isSelected = selectedAnswer == answerId;
    final bool isCorrect = showAnswer && answerId == correctAnswerId;
    final bool isWrong = showAnswer && isSelected && answerId != correctAnswerId;

    // ---------- COLORS ----------
    final Color bgColor = isCorrect
        ? Colors.green
        : isWrong
        ? Colors.red
        : isSelected
        ? primary.withOpacity(0.15)
        : surface;

    final Color borderColor = isCorrect
        ? Colors.green
        : isWrong
        ? error
        : isSelected
        ? primary
        : theme.dividerColor;

    final Color textColor =
    (isCorrect || isWrong) ? Colors.white : onSurface;

    // ---------- CONTENT ----------
    final Widget content = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: (isCorrect || isWrong)
            ? [
          BoxShadow(
            color: bgColor.withOpacity(0.6),
            blurRadius: 14,
            spreadRadius: 1,
          )
        ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              answer["answerText"] ?? "",
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: (isCorrect || isWrong) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Colors.white, size: 26),
          if (isWrong)
            const Icon(Icons.cancel, color: Colors.white, size: 26),
        ],
      ),
    );

    // ---------- ANIMATION ----------
    return GestureDetector(
      onTap: !showAnswer
          ? () {
        final bool isWrongSelection = correctAnswerId != null && answerId != correctAnswerId;
        if (isWrongSelection) HapticsManager.heavyImpact();
        onTap?.call();
      }
          : null,
      child: showAnswer && (isCorrect || isWrong)
          ? BounceIn(child: content)
          : content,
    );
  }
}

