import 'package:flutter/material.dart';

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
    final color = accentColor ?? const Color(0xFF878C9F);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: accentColor == null ? Colors.white : const Color(0xFFF9F9FF),
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
                Row(
                  children: [
                    if (icon != null)
                      Icon(icon, color: color, size: 28)
                    else if (iconAsset != null)
                      Image.asset(iconAsset!, width: 28, height: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "$questionCount Questions",
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFD9D9D9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor ?? Colors.blueAccent,
                          ),
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
