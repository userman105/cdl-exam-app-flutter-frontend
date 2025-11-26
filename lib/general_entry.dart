import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/unit_button.dart';
import 'general_bank_screen.dart';

class GeneralKnowledgeExtraTab extends StatefulWidget {
  const GeneralKnowledgeExtraTab({Key? key}) : super(key: key);

  @override
  State<GeneralKnowledgeExtraTab> createState() =>
      _GeneralKnowledgeExtraTabState();
}

class _GeneralKnowledgeExtraTabState extends State<GeneralKnowledgeExtraTab> {
  final Map<String, double> _progressExtraUnits = {};

  @override
  void initState() {
    super.initState();
    _loadProgressExtra();
  }

  Future<void> _loadProgressExtra() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("extra_units_progress");
    if (saved != null) {
      setState(() {
        _progressExtraUnits
            .addAll(Map<String, double>.from(jsonDecode(saved)));
      });
    }
  }

  Future<void> _saveProgressExtra() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "extra_units_progress",
      jsonEncode(_progressExtraUnits),
    );
  }

  void _updateProgress(String key, double progress) {
    setState(() => _progressExtraUnits[key] = progress);
    _saveProgressExtra();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          UnitButton(
            title: "Placeholder A",
            questionCount: 50,
            progress: _progressExtraUnits["progress_placeholder_a"] ?? 0.0,
            iconAsset: "assets/icons/unit_button_icon.png",
            onTap: () {
              _updateProgress("progress_placeholder_a", 0.2);

              // Navigate to questions tab, without adding a new AppBar
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GeneralKnowledgeQuestionsTab(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          UnitButton(
            title: "Placeholder B",
            questionCount: 30,
            progress: _progressExtraUnits["progress_placeholder_b"] ?? 0.0,
            iconAsset: "assets/icons/unit_button_icon.png",
            onTap: () {
              _updateProgress("progress_placeholder_b", 0.1);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Button B tapped")),
              );
            },
          ),
        ],
      ),
    );
  }
}

