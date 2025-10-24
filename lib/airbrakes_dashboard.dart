import 'dart:async';
import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/widgets.dart';
import '../constants/constants.dart';
import '../blocs/exam_cubit.dart';
import 'report_card.dart';

// =====================
// Main Dashboard
// =====================
class AirbrakesDashboard extends StatefulWidget {
  final int initialTabIndex;

  const AirbrakesDashboard({super.key, this.initialTabIndex = 0});

  @override
  State<AirbrakesDashboard> createState() => _AirbrakesDashboardState();
}

class _AirbrakesDashboardState extends State<AirbrakesDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Air Brakes",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Image.asset("assets/icons/subscription.png", width: 132, height: 132),
            onPressed: () {
              // TODO: Implement subscription
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildShadowDivider(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                AirbrakesQuestionsTab(),
                AirbrakesUnitsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        color: Colors.black12,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 7),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset("assets/icons/the_star.png", width: 40, height: 40),
          const SizedBox(width: 12),
          CustomTabButton(
            text: "Questions Bank",
            isActive: _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
            underlineWidth: 86,
          ),
          const SizedBox(width: 12),
          CustomTabButton(
            text: "Exams",
            isActive: _tabController.index == 1,
            onTap: () => _tabController.animateTo(1),
            underlineWidth: 50,
          ),
        ],
      ),
    );
  }
}

// =====================
// Airbrakes Questions Tab
// =====================
class AirbrakesQuestionsTab extends StatefulWidget {
  const AirbrakesQuestionsTab({Key? key}) : super(key: key);

  @override
  State<AirbrakesQuestionsTab> createState() => _AirbrakesQuestionsTabState();
}

class _AirbrakesQuestionsTabState extends State<AirbrakesQuestionsTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAnswer = false;

  @override
  void dispose() {
    TTSService.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamCubit, ExamState>(
      builder: (context, state) {
        if (state is ExamLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ExamError) {
          return Center(child: Text("Error: ${state.message}"));
        }

        if (state is ExamLoaded) {
          final questions = state.examData["questions"] as List<dynamic>;

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() {
                      _currentPage = i;
                      _showAnswer = false;
                    });
                  },
                  itemCount: questions.length,
                  itemBuilder: (context, index) => _buildQuestionPage(questions, index, state),
                ),
              ),
              _buildNavigationBar(questions.length),
            ],
          );
        }

        return const Center(child: Text("No exam loaded"));
      },
    );
  }

  Widget _buildQuestionPage(List<dynamic> questions, int index, ExamLoaded state) {
    final question = questions[index];
    final answers = question["answers"] as List<dynamic>;
    final questionId = question["questionId"];
    final selected = state.selectedAnswers[questionId];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildEnglishQuestionCard(question, answers, questionId, selected),
          ),
        ),
        ArabicExpansionCard(
          question: question,
          answers: answers,
          onTTSTap: () => _speakArabic(question, answers),
        ),
        _buildShowAnswerButton(questions, index),
      ],
    );
  }

  Widget _buildEnglishQuestionCard(
      Map<String, dynamic> question,
      List<dynamic> answers,
      int questionId,
      int? selected,
      ) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${_currentPage + 1}: ${question['questionText']}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    ...answers.map((ans) => AnswerOption(
                      answer: ans,
                      questionId: questionId,
                      selectedAnswer: selected,
                      showAnswer: _showAnswer,
                      onTap: !_showAnswer
                          ? () => context.read<ExamCubit>().selectAnswer(questionId, ans["answerId"])
                          : null,
                    )),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: SvgPicture.asset("assets/icons/tts.svg", width: 32, height: 32),
                onPressed: () => _speakEnglish(question, answers),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton(List<dynamic> questions, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kSecondaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () => _handleShowAnswer(questions, index),
          child: Text(
            "Show Answer",
            style: GoogleFonts.robotoSlab(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleShowAnswer(List<dynamic> questions, int index) async {
    setState(() => _showAnswer = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_airbrakes_questionsbank', _currentPage);

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _showAnswer = false);

      if (index < questions.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have reached the last question")),
        );
      }
    }
  }

  Widget _buildNavigationBar(int totalQuestions) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 0
                ? () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
                : null,
          ),
          Expanded(
            child: Slider(
              value: _currentPage.toDouble(),
              min: 0,
              max: (totalQuestions - 1).toDouble(),
              divisions: totalQuestions - 1,
              label: "Q${_currentPage + 1}",
              onChanged: (val) => _pageController.jumpToPage(val.toInt()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < totalQuestions - 1
                ? () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
                : null,
          ),
        ],
      ),
    );
  }

  void _speakEnglish(Map<String, dynamic> question, List<dynamic> answers) {
    TTSService.showSnackBar(
      context,
      'Text-to-Speech',
      'Commencing text to speech...',
      ContentType.help,
    );

    final text = "Q${_currentPage + 1}: ${question['questionText']}. "
        "${answers.asMap().entries.map((e) => "${e.key + 1}. ${e.value['answerText']}").join(", ")}";

    TTSService.speak(text, context, langCode: "en-US");
  }

  void _speakArabic(Map<String, dynamic> question, List<dynamic> answers) {
    TTSService.showSnackBar(
      context,
      'Text-to-Speech',
      'Commencing text to speech...',
      ContentType.help,
    );

    final text = "${question['questionTextAr']}. "
        "${answers.asMap().entries.map((e) => "${e.key + 1}. ${e.value['answerTextAr']}").join("، ")}";

    TTSService.speak(text, context, langCode: "ar-SA");
  }
}
//--------------------------
//------UNITS-TAB-----------
//--------------------------

class AirbrakesUnitsTab extends StatefulWidget {
  const AirbrakesUnitsTab({Key? key}) : super(key: key);

  @override
  State<AirbrakesUnitsTab> createState() => _AirbrakesUnitsTabState();
}

class _AirbrakesUnitsTabState extends State<AirbrakesUnitsTab> {
  Map<String, dynamic>? _previousMistakesExam;

  @override
  void initState() {
    super.initState();
    _loadPreviousMistakesExam();
  }

  Future<void> _loadPreviousMistakesExam() async {
    final examCubit = context.read<ExamCubit>();
    final mistakesExam = await examCubit.loadPreviousMistakesExam();
    if (mounted && mistakesExam != null) {
      setState(() {
        _previousMistakesExam = mistakesExam;
      });
    }
  }

  Widget _buildUnitButton(BuildContext context, String title, List<dynamic> questions, int start, int end) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AirbrakesUnitQuestionsScreen(
              unitName: title,
              questions: questions.sublist(start, end),
            ),
          ),
        );
      },
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTimeAttackUnit(BuildContext context, List<dynamic> questions) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kSecondaryColor, width: 2),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AirbrakesUnitQuestionsScreen(
              unitName: "Time Attack",
              questions: questions.take(AppConstants.timeAttackQuestions).toList(),
              timeLimitSeconds: AppConstants.timeAttackSeconds,
            ),
          ),
        );
      },
      child: const Text(
        "⏱ Time Attack",
        style: TextStyle(fontSize: 18, color: kSecondaryColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPreviousMistakesUnit(BuildContext context) {
    final mistakes = _previousMistakesExam?["questions"] as List<dynamic>;
    return Column(
      children: [
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kErrorColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AirbrakesUnitQuestionsScreen(
                  unitName: "Previous Mistakes",
                  questions: mistakes,
                ),
              ),
            );
          },
          child: const Text(
            " Previous Mistakes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamCubit, ExamState>(
      builder: (context, state) {
        if (state is! ExamLoaded) {
          return const Center(child: Text("Load an exam to see units"));
        }

        final questions = state.examData["questions"] as List<dynamic>;
        final total = questions.length;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildUnitButton(context, "Basics", questions, 0, 30.clamp(0, total)),
                const SizedBox(height: 20),
                _buildUnitButton(context, "Unit 2 (Q31–60)", questions, 30, 64.clamp(0, total)),
                const SizedBox(height: 20),
                _buildTimeAttackUnit(context, questions),
                if (_previousMistakesExam != null) _buildPreviousMistakesUnit(context),
              ],
            ),
          ),
        );
      },
    );
  }
}
//-----------------------------
//--------UNIT-QUESTIONSCREEN
//----------------------------

class AirbrakesUnitQuestionsScreen extends StatefulWidget {
  final String unitName;
  final List<dynamic> questions;
  final int? timeLimitSeconds;

  const AirbrakesUnitQuestionsScreen({
    Key? key,
    required this.unitName,
    required this.questions,
    this.timeLimitSeconds,
  }) : super(key: key);

  @override
  State<AirbrakesUnitQuestionsScreen> createState() => _AirbrakesUnitQuestionsScreenState();
}

class _AirbrakesUnitQuestionsScreenState extends State<AirbrakesUnitQuestionsScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(widget.unitName),
        backgroundColor: kPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / widget.questions.length,
              color: kSecondaryColor,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              "Question ${currentIndex + 1}/${widget.questions.length}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  question["question_text"] ?? "No question text",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (currentIndex < widget.questions.length - 1) {
                  setState(() => currentIndex++);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(
                currentIndex == widget.questions.length - 1 ? "Finish" : "Next",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

