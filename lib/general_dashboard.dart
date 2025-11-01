import 'dart:async';
import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cdl_flutter/report_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/widgets.dart';
import '../constants/constants.dart';
import '../blocs/exam_cubit.dart';
import 'package:arabic_font/arabic_font.dart';
import 'services/report_storage.dart';
// =====================
// General Knowledge Dashboard
// =====================
class GeneralKnowledgeDashboard extends StatefulWidget {
  final int initialTabIndex;

  const GeneralKnowledgeDashboard({super.key, this.initialTabIndex = 0});

  @override
  State<GeneralKnowledgeDashboard> createState() =>
      _GeneralKnowledgeDashboardState();
}

class _GeneralKnowledgeDashboardState extends State<GeneralKnowledgeDashboard>
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
          "معلومات عامة",
          style: ArabicTextStyle(arabicFont: ArabicFont.dubai,fontWeight: FontWeight.w500, fontSize: 23),
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
                GeneralKnowledgeQuestionsTab(),
                GeneralKnowledgeUnitsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowDivider() => Container(
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

  Widget _buildTabBar() => Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset("assets/icons/the_star.png", width: 40, height: 40),
        const SizedBox(width: 12),
        CustomTabButton(
          text: "بنك الاسئلة",
          isActive: _tabController.index == 0,
          onTap: () => _tabController.animateTo(0),
          underlineWidth: 86,
        ),
        const SizedBox(width: 12),
        CustomTabButton(
          text: "الامتحانات",
          isActive: _tabController.index == 1,
          onTap: () => _tabController.animateTo(1),
          underlineWidth: 50,
        ),
      ],
    ),
  );
}


// =====================
// General Knowledge Questions Tab
// =====================
class GeneralKnowledgeQuestionsTab extends StatefulWidget {
  const GeneralKnowledgeQuestionsTab({Key? key}) : super(key: key);

  @override
  State<GeneralKnowledgeQuestionsTab> createState() =>
      _GeneralKnowledgeQuestionsTabState();
}

class _GeneralKnowledgeQuestionsTabState extends State<GeneralKnowledgeQuestionsTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAnswer = false;

  int _getCorrectAnswerIdForGeneral(int questionId) {
    return 406 + (questionId - 136);
  }

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
                  onPageChanged: (i) => setState(() {
                    _currentPage = i;
                    _showAnswer = false;
                  }),
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
        // 🇴🇲 Arabic comes FIRST (main interactive card)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildArabicQuestionCard(question, answers, questionId, selected),
          ),
        ),

        // 🇺🇸 English is now the secondary expansion card
        EnglishExpansionCard(
          question: question,
          answers: answers,
          onTTSTap: () => _speakEnglish(question, answers),
        ),

        _buildShowAnswerButton(questions, index),
      ],
    );
  }

  Widget _buildArabicQuestionCard(
      Map<String, dynamic> question,
      List<dynamic> answers,
      int questionId,
      int? selected,
      ) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "س${_currentPage + 1}: ${question['questionTextAr'] ?? ''}",
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    ...answers.map((ans) => AnswerOption(
                      answer: {
                        "answerId": ans["answerId"],
                        "answerText": ans["answerTextAr"]
                      },
                      questionId: questionId,
                      selectedAnswer: selected,
                      showAnswer: _showAnswer,
                      correctAnswerId: _getCorrectAnswerIdForGeneral(questionId),
                      onTap: !_showAnswer
                          ? () => context
                          .read<ExamCubit>()
                          .selectAnswer(questionId, ans["answerId"])
                          : null,
                    )),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Colors.blueAccent),
                onPressed: () => _speakArabic(question, answers),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEnglishQuestionCard(
      Map<String, dynamic> question,
      List<dynamic> answers,
      int qid,
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
                    ...answers.map((ans) {
                      final isSelected = selected == ans["answerId"];
                      final correctAnswerId = _getCorrectAnswerIdForGeneral(qid);
                      final isCorrect = _showAnswer && ans["answerId"] == correctAnswerId;
                      final isWrong = _showAnswer && isSelected && !isCorrect;

                      return GestureDetector(
                        onTap: !_showAnswer
                            ? () => context.read<ExamCubit>().selectAnswer(qid, ans["answerId"])
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green[100]
                                : isWrong
                                ? Colors.red[100]
                                : isSelected
                                ? Colors.blue[100]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCorrect
                                  ? Colors.green
                                  : isWrong
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            ans["answerText"],
                            style: GoogleFonts.robotoSlab(fontSize: 16),
                          ),
                        ),
                      );
                    }),
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
    await prefs.setInt('progress_general_questionsbank', _currentPage);

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

  Widget _buildNavigationBar(int total) => Padding(
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
            max: (total - 1).toDouble(),
            divisions: total - 1,
            label: "Q${_currentPage + 1}",
            onChanged: (v) => _pageController.jumpToPage(v.toInt()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentPage < total - 1
              ? () => _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
              : null,
        ),
      ],
    ),
  );

  void _speakEnglish(Map<String, dynamic> question, List<dynamic> answers) {
    TTSService.showSnackBar(context, 'TTS', 'Commencing speech...', ContentType.help);
    final text =
        "Q${_currentPage + 1}: ${question['questionText']}. ${answers.map((a) => a['answerText']).join(', ')}";
    TTSService.speak(text, context, langCode: "en-US");
  }

  void _speakArabic(Map<String, dynamic> question, List<dynamic> answers) {
    TTSService.showSnackBar(context, 'TTS', 'Commencing speech...', ContentType.help);
    final text =
        "${question['questionTextAr']}. ${answers.map((a) => a['answerTextAr']).join('، ')}";
    TTSService.speak(text, context, langCode: "ar-SA");
  }
}

// =====================
// General Knowledge Units Tab
// =====================
class GeneralKnowledgeUnitsTab extends StatefulWidget {
  const GeneralKnowledgeUnitsTab({Key? key}) : super(key: key);

  @override
  State<GeneralKnowledgeUnitsTab> createState() =>
      _GeneralKnowledgeUnitsTabState();
}

class _GeneralKnowledgeUnitsTabState extends State<GeneralKnowledgeUnitsTab> {
  final Map<String, double> _unitProgressGeneral = {};
  late Future<Map<String, dynamic>?> _mistakesExamFuture;
  final String _examKey = "general_knowledge";

  @override
  void initState() {
    super.initState();
    _loadProgressGeneral();
    _mistakesExamFuture =
        context.read<ExamCubit>().getPreviousMistakesExamData(_examKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mistakesExamFuture =
        context.read<ExamCubit>().getPreviousMistakesExamData(_examKey);
  }

  // 🔹 Load saved General progress
  Future<void> _loadProgressGeneral() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("unit_progress_general");
    if (saved != null) {
      setState(() => _unitProgressGeneral
          .addAll(Map<String, double>.from(jsonDecode(saved))));
      debugPrint(" Loaded General Knowledge unit progress: $_unitProgressGeneral");
    } else {
      debugPrint("ℹ No saved General Knowledge progress found.");
    }
  }

  // 🔹 Save General progress persistently
  Future<void> _saveProgressGeneral() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        "unit_progress_general", jsonEncode(_unitProgressGeneral));
    debugPrint(" Saved General Knowledge unit progress: $_unitProgressGeneral");
  }



  void _updateProgressGeneral(String title, double progress) {
    setState(() => _unitProgressGeneral[title] = progress);
    _saveProgressGeneral(); //  persist immediately
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamCubit, ExamState>(
      builder: (context, state) {
        if (state is! ExamLoaded) {
          return const Center(child: Text("Load an exam to see units"));
        }

        final questions = state.examData["questions"] as List<dynamic>? ?? [];
        final total = questions.length;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                //  Show previous mistakes (if any)
                FutureBuilder<Map<String, dynamic>?>(
                  future: _mistakesExamFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final exam = snapshot.data;
                    if (exam != null &&
                        (exam["questions"] as List?)?.isNotEmpty == true) {
                      return _buildPreviousMistakesUnit(context, exam);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),

                //  Dynamic Units
                _buildNormalUnit(context, "الاساسيات", questions, 0, 25.clamp(0, total)),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "اخطاء شائعة", questions, 25, 50.clamp(0, total)),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "اسئلة متقدمة", questions, 50, 71.clamp(0, total)),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "اسؤء السيناريوهات", questions, 71, 95.clamp(0, total)),
                const SizedBox(height: 20),

                _buildTimeAttackUnit(context, questions),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Standard Unit
  Widget _buildNormalUnit(BuildContext context, String title,
      List<dynamic> allQuestions, int start, int end) {
    final count = (end - start).clamp(0, allQuestions.length);
    if (count <= 0) return const SizedBox.shrink();

    return UnitButton(
      title: title,
      questionCount: count,
      progress: _unitProgressGeneral[title] ?? 0.0,
      iconAsset: "assets/icons/unit_button_icon.png",
      onTap: () async {
        final unitQuestions = allQuestions.sublist(start, end);

        //  Apply correct answer formula for general knowledge
        for (int i = 0; i < unitQuestions.length; i++) {
          final qIndex = start + i + 136; // general base
          unitQuestions[i]["correctAnswerId"] = 406 + (qIndex - 136);
        }

        await _navigateToUnit(context, title, unitQuestions, start, end);
      },
    );
  }

  //  Time Attack Unit
  Widget _buildTimeAttackUnit(BuildContext context, List<dynamic> allQuestions) {
    if (allQuestions.isEmpty) return const SizedBox.shrink();

    return UnitButton(
      title: "امتحان ضد الزمن",
      questionCount: 20,
      progress: _unitProgressGeneral["Time Attack"] ?? 0.0,
      accentColor: kPrimaryColor,
      icon: Icons.timer_outlined,
      onTap: () async {
        final start = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("امتحان ضدالوقت"),
            content: const Text(
              "لديك عشر ثواني لاجابة كل سؤال",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Start")),
            ],
          ),
        );

        if (start != true) return;

        final randomized = List<dynamic>.from(allQuestions)..shuffle();
        final selected = randomized.take(20).toList();

        // ✅ Apply formula
        for (int i = 0; i < selected.length; i++) {
          final qIndex = i + 136;
          selected[i]["correctAnswerId"] = 406 + (qIndex - 136);
        }

        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) => GeneralKnowledgeUnitQuestionsScreen(
              title: "⚡ Time Attack",
              questions: selected,
              startIndex: 0,
              endIndex: selected.length,
              isTimed: true,
              dashboardName: 'General',
            ),
          ),
        );

// Optional: handle result after exam ends
        if (result != null) {
          final progress = result["progress"] as double? ?? 0.0;
          final selectedAnswers = result["selectedAnswers"] as Map<int, int?>?;

          // You can use these values to update progress tracking or analytics
          debugPrint("Progress: $progress");
          debugPrint("Selected answers: $selectedAnswers");
        }

      },
    );
  }

  // 🔹 Previous Mistakes Unit
  Widget _buildPreviousMistakesUnit(
      BuildContext context, Map<String, dynamic> exam) {
    final questions = (exam["questions"] ?? []) as List<dynamic>;
    if (questions.isEmpty) return const SizedBox.shrink();

    return UnitButton(
      title: exam["title"] ?? "Previous Mistakes",
      questionCount: questions.length,
      progress: _unitProgressGeneral[exam["title"]] ?? 0.0,
      accentColor: kErrorColor,
      icon: Icons.error_outline,
      onTap: () {
        context.read<ExamCubit>().loadMistakesExamIntoState(exam);
        _navigateToUnit(context, exam["title"], questions, 0, questions.length);
      },
    );
  }

  // 🔹 Unified Navigation Handler
  Future<void> _navigateToUnit(
      BuildContext context,
      String title,
      List<dynamic> questions,
      int start,
      int end,
      ) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => GeneralKnowledgeUnitQuestionsScreen(
          title: title,
          questions: questions,
          startIndex: start,
          endIndex: end,
          dashboardName: 'General',
        ),
      ),
    );

    if (!context.mounted) return;

    if (result != null) {
      final progress = result["progress"] as double? ?? 0.0;
      final selectedAnswers = result["selectedAnswers"] as Map<int, int?>?;

      // Update progress using the extracted progress value
      _updateProgressGeneral(title, progress);

      // (Optional) You can use selectedAnswers for analytics, report logs, etc.
      debugPrint("Unit finished with progress: $progress");
      debugPrint("Selected answers: $selectedAnswers");
    }

    // Refresh previous mistakes after returning
    setState(() {
      _mistakesExamFuture =
          context.read<ExamCubit>().getPreviousMistakesExamData(_examKey);
    });
  }

}
// =====================
// General Knowledge Unit Question Screen
// =====================


class GeneralKnowledgeUnitQuestionsScreen extends StatefulWidget {
  final String title;
  final List<dynamic> questions;
  final int startIndex;
  final int endIndex;
  final bool isTimed;
  final String dashboardName;

  static List<dynamic> _mistakeCache = [];
  static List<dynamic> get mistakeCache => _mistakeCache;

  const GeneralKnowledgeUnitQuestionsScreen({
    Key? key,
    required this.title,
    required this.questions,
    required this.startIndex,
    required this.endIndex,
    required this.dashboardName,
    this.isTimed = false,
  }) : super(key: key);

  static Future<void> loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("previous_mistakes_general");
    if (stored != null) {
      _mistakeCache = List<Map<String, dynamic>>.from(jsonDecode(stored));
    }
  }

  @override
  State<GeneralKnowledgeUnitQuestionsScreen> createState() =>
      _GeneralKnowledgeUnitQuestionsScreenState();
}

class _GeneralKnowledgeUnitQuestionsScreenState
    extends State<GeneralKnowledgeUnitQuestionsScreen> {
  late DateTime _startTime;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _showAnswer = false;
  bool _isArabicExpanded = false;
  int? _selectedAnswerId;
  final FlutterTts _flutterTts = FlutterTts();

  Timer? _questionTimer;
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    if (widget.isTimed) _startTimer(widget.questions[_currentIndex]);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _questionTimer?.cancel();
    super.dispose();
  }

  int _getCorrectAnswerId(int questionId) {
    return 406 + (questionId - 136);
  }


  Future<void> _recordMistake(Map<String, dynamic> question) async {
    final prefs = await SharedPreferences.getInstance();
    const examKey = "general_knowledge";
    const key = "exam_previous_mistakes_$examKey";

    List<dynamic> existing = [];
    final saved = prefs.getString(key);
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved);
        existing = (decoded["questions"] as List?) ?? [];
      } catch (_) {
        debugPrint("Corrupted mistakes data for $examKey, resetting.");
      }
    }

    final exists = existing.any((q) => q["questionId"] == question["questionId"]);
    if (!exists) {
      existing.add(question);
      final updatedExam = {
        "id": "mistakes_$examKey",
        "title": "الاخطاء السابقة",
        "questions": existing.take(71).toList(),
      };
      await prefs.setString(key, jsonEncode(updatedExam));
      debugPrint("Recorded mistake for General Knowledge: ${question["questionText"]}");
    }
  }

  void _startTimer(Map<String, dynamic> question) {
    if (!widget.isTimed) return;
    _questionTimer?.cancel();
    _remainingSeconds = 10;

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (!_showAnswer) _submitAnswer(question);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _speakQuestion(Map<String, dynamic> question) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'Text to Speech',
          message: 'Commencing text-to-speech for this question...',
          contentType: ContentType.help,
        ),
      ),
    );

    final text = StringBuffer()
      ..writeln(question["questionText"])
      ..writeAll(question["answers"].map((a) => a["answerText"]), "\n");

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(text.toString());
  }

  void _speakArabic(Map<String, dynamic> question) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'Text to Speech',
          message: 'Commencing Arabic text-to-speech...',
          contentType: ContentType.help,
        ),
      ),
    );

    final text = StringBuffer()
      ..writeln(question["questionTextAr"])
      ..writeAll(question["answers"].map((a) => a["answerTextAr"]), "\n");

    await _flutterTts.setLanguage("ar-SA");
    await _flutterTts.speak(text.toString());
  }

  void _submitAnswer(Map<String, dynamic> question) {
    if (_selectedAnswerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an answer first."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _questionTimer?.cancel();
    final isCorrect = _selectedAnswerId == _getCorrectAnswerId(question["questionId"]);



    if (isCorrect) {
      _correctCount++;
    } else {
      _wrongCount++;
      _recordMistake(question);
    }

    setState(() => _showAnswer = true);
  }

  Future<void> _nextQuestion() async {
    // Reset per-question transient UI state
    _showAnswer = false;
    _selectedAnswerId = null;
    _isArabicExpanded = false;
    _remainingSeconds = 10;

    // If there are remaining questions -> advance
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerId = null;
        _showAnswer = false;
      });

      // restart timer for the new question if timed mode
      if (widget.isTimed) {
        _startTimer(widget.questions[_currentIndex]);
      }

      return;
    }

    // Otherwise we've reached the end -> finish exam
    _questionTimer?.cancel();

    final totalTime = DateTime.now().difference(_startTime);
    final totalQuestions = widget.questions.length;
    final percentage = (totalQuestions > 0) ? (_correctCount / totalQuestions) * 100 : 0.0;

    // Create the report card instance (use your dashboard/unit fields)
    final reportCard = ReportCard(
      correctAnswers: _correctCount,
      wrongAnswers: _wrongCount,
      timeElapsed: totalTime,
      percentage: percentage,
      // These fields depend on your ReportCard constructor names;
      // use the correct param names you implemented (dashboardName/unitName or examName).
      dashboardName: widget.dashboardName,
      unitName: widget.title,
    );

    // Persist the report (your persistence helper)
    await ReportCardPersistence.saveReportCard(reportCard);

    // Show final report dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => reportCard,
    );

    if (!mounted) return;
    final progress = (_currentIndex + 1) / totalQuestions;

// Ensure safe pop after dialog is fully dismissed
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).maybePop({
          "progress": progress,
          "selectedAnswers": context.read<ExamCubit>().selectedAnswers,
        });
      }
    });

  }


  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final answers = question["answers"] as List<dynamic>;

    return WillPopScope(
      onWillPop: () async {
        final progress = (_currentIndex + 1) / widget.questions.length;

        // ✅ Pop immediately with the progress data
        Navigator.of(context).pop({
          "progress": progress,
          "selectedAnswers": context.read<ExamCubit>().state is ExamLoaded
              ? (context.read<ExamCubit>().state as ExamLoaded).selectedAnswers
              : <int, int?>{},
        });

        // Return false to prevent default back behavior since we already popped
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _headerStatusBox(),
              const SizedBox(height: 16),
              _buildArabicCard(question, answers),
              const SizedBox(height: 16),
              _buildEnglishCard(question, answers),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEnglishCard(Map<String, dynamic> question, List<dynamic> answers) {
    return Card(
      elevation: 4,
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
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF64B2EF)),
                  onPressed: () => _speakQuestion(question),
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
                    turns: _isArabicExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  onPressed: () => setState(() => _isArabicExpanded = !_isArabicExpanded),
                ),
              ],
            ),
            AnimatedCrossFade(
              crossFadeState: _isArabicExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question["questionText"] ?? "",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    ...answers.map((ans) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        ans["answerText"] ?? "",
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildArabicCard(Map<String, dynamic> question, List<dynamic> answers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              question["questionTextAr"] ?? "",
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...answers.map((ans) {
              final isSelected = _selectedAnswerId == ans["answerId"];
              final isCorrect = _showAnswer && ans["answerId"] ==_getCorrectAnswerId(question["questionId"]);
              final isWrong = _showAnswer && isSelected && !isCorrect;

              return GestureDetector(
                onTap: !_showAnswer
                    ? () => setState(() => _selectedAnswerId = ans["answerId"])
                    : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green[100]
                        : isWrong
                        ? Colors.red[100]
                        : isSelected
                        ? Colors.blue[100]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green
                          : isWrong
                          ? Colors.red
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      ans["answerTextAr"] ?? "",
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _speakArabic(question),
                  icon: const Icon(Icons.volume_up),
                  label: const Text("استمع"),
                ),
                SizedBox(
                  width: 160,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B2EF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                    _showAnswer ? _nextQuestion : () => _submitAnswer(question),
                    child: Text(
                      _showAnswer ? "التالي" : "تاكيد",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _headerStatusBox() {
    final progress = (_currentIndex + 1) / widget.questions.length;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Q${_currentIndex + 1}/${widget.questions.length}",
              style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold)),
          if (widget.isTimed)
            Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  '$_remainingSeconds s',
                  style: GoogleFonts.robotoSlab(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFD9D9D9),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF64B2EF),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Text("$_correctCount",
                  style: GoogleFonts.robotoSlab(color: Colors.green[700])),
              const SizedBox(width: 10),
              Text("$_wrongCount",
                  style: GoogleFonts.robotoSlab(color: Colors.red[700])),
            ],
          ),
        ],
      ),
    );
  }
}