import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArabicExpansionCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final List<dynamic> answers;
  final VoidCallback onTTSTap;

  const ArabicExpansionCard({
    Key? key,
    required this.question,
    required this.answers,
    required this.onTTSTap,
  }) : super(key: key);

  @override
  State<ArabicExpansionCard> createState() => _ArabicExpansionCardState();
}

class _ArabicExpansionCardState extends State<ArabicExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: widget.onTTSTap,
                ),
                Expanded(
                  child: Text(
                    "العربية",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.iconTheme.color,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
            AnimatedCrossFade(
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox.shrink(),
              secondChild: _buildArabicContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.question["questionTextAr"] ?? "",
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          Divider(
            height: 20,
            color: theme.dividerColor,
          ),
          ...widget.answers.map(
                (ans) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ans["answerTextAr"] ?? "",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

