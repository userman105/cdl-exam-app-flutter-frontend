import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';


class UnitButton extends StatelessWidget {
  final String title;
  final int questionCount;
  final double progress;
  final VoidCallback onTap;
  final Color? accentColor;
  final IconData? icon;
  final String? iconAsset;

  const UnitButton({
    Key? key,
    required this.title,
    required this.questionCount,
    required this.progress,
    required this.onTap,
    this.accentColor,
    this.icon,
    this.iconAsset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color effectiveAccent = accentColor ?? theme.colorScheme.primary;
    final Color surfaceColor = accentColor == null
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceVariant;
    final Color textColor = accentColor == null
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------ TOP ROW ------------------
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Icon (right side)
                    if (icon != null)
                      Icon(icon, color: effectiveAccent, size: 28)
                    else if (iconAsset != null)
                      Image.asset(iconAsset!, width: 28, height: 28),

                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        style: ArabicTextStyle(
                          arabicFont: ArabicFont.dubai,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: effectiveAccent,
                        ),
                      ),
                    ),

                    // Chevron arrow (forces to left)
                    Icon(Icons.chevron_left, color: theme.iconTheme.color),
                  ],
                ),

                const SizedBox(height: 12),

                // ------------------ BOTTOM ROW ------------------
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      "$questionCount سؤال ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: theme.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(effectiveAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

