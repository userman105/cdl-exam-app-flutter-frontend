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
  State<EnglishExpansionCard> createState() => _EnglishExpansionCardState();
}

class _EnglishExpansionCardState extends State<EnglishExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: Colors.blueAccent),
                  onPressed: widget.onTTSTap,
                ),
                Expanded(
                  child: Text(
                    "English",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
            AnimatedCrossFade(
              crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox.shrink(),
              secondChild: _buildEnglishContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnglishContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question["questionText"] ?? "",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          ...widget.answers.map((ans) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              ans["answerText"] ?? "",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          )),
        ],
      ),
    );
  }
}
