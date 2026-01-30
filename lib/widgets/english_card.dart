import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnglishExpansionCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final List<dynamic> answers;
  final VoidCallback onTTSTap;

  const EnglishExpansionCard({
    Key? key,
    required this.question,
    required this.answers,
    required this.onTTSTap,
  }) : super(key: key);

  @override
  State<EnglishExpansionCard> createState() =>
      _EnglishExpansionCardState();
}

class _EnglishExpansionCardState extends State<EnglishExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    "English",
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
              secondChild: _buildEnglishContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnglishContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question["questionText"] ?? "",
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
              child: Text(
                ans["answerText"] ?? "",
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

