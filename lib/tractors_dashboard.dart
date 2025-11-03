import 'dart:async';
import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/auth_cubit.dart';
import 'report_card.dart';
import 'blocs/exam_cubit.dart';
import 'package:arabic_font/arabic_font.dart';
import 'widgets/widgets.dart';
import 'constants/constants.dart';
import 'services/report_storage.dart';
import 'package:cdl_flutter/subscription_screen.dart';
import 'register_screen.dart';
import 'services/trial_manager.dart';
// =====================
// Main Dashboard
// =====================
class TractorsDashboard extends StatefulWidget {
  final int initialTabIndex;

  const TractorsDashboard({super.key, this.initialTabIndex = 0});

  @override
  State<TractorsDashboard> createState() => _TractorsDashboardState();
}

class _TractorsDashboardState extends State<TractorsDashboard>
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
          "الجرار و المقطورات",
          style: ArabicTextStyle(arabicFont: ArabicFont.dubai  ,fontWeight: FontWeight.w500, fontSize: 23),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              "assets/icons/subscription.png",
              width: 132,
              height: 132,
            ),
            onPressed: () {
              final authState = context.read<AuthCubit>().state;

              // Case 1: Guest user → show dialog urging to register
              if (authState is AuthGuest) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("تسجيل الحساب"),
                      content: const Text("يجب عليك إنشاء حساب أولاً للاستفادة من العروض."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), // cancel
                          child: const Text("إلغاء"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text("تسجيل"),
                        ),
                      ],
                    );
                  },
                );
              }
              // Case 2: Authenticated user → go to subscription screen
              else if (authState is AuthAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              }
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
                QuestionsBankTab(),
                UnitsTab(),
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
            text: "بنك الاسئلة",
            isActive: _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
            underlineWidth: 86,
          ),
          const SizedBox(width: 12),
          CustomTabButton(
            text: "الأمتحانات",
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
// Questions Bank Tab
// =====================
class QuestionsBankTab extends StatefulWidget {
  const QuestionsBankTab({Key? key}) : super(key: key);

  @override
  State<QuestionsBankTab> createState() => _QuestionsBankTabState();
}

class _QuestionsBankTabState extends State<QuestionsBankTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAnswer = false;
  int _getCorrectAnswerIdForTrailersAndTractors(int questionId) {
    // For Airbrakes questions:
    // correct = (q)
    return  questionId;
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
              // --- inside build() ---
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) {
                    final authState = context.read<AuthCubit>().state;
                    final bool isLimitedUser = authState is AuthGuest ||
                        (authState is AuthAuthenticated &&
                            (authState.subscribed == null || authState.subscribed == false));

                    // Prevent going past 20 if limited
                    if (isLimitedUser && i >= 20) {
                      _showUpgradeSnackbar();
                      _pageController.jumpToPage(19);
                      return;
                    }

                    setState(() {
                      _currentPage = i;
                      _showAnswer = false;
                    });
                  },
                  itemCount: questions.length,
                  itemBuilder: (context, index) =>
                      _buildQuestionPage(questions, index, state),
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
                      correctAnswerId: _getCorrectAnswerIdForTrailersAndTractors(questionId),
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
                      correctAnswerId: _getCorrectAnswerIdForTrailersAndTractors(questionId),
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
    final authState = context.read<AuthCubit>().state;
    final bool isLimitedUser = authState is AuthGuest ||
        (authState is AuthAuthenticated &&
            (authState.subscribed == null || authState.subscribed == false));

    //  Block show answer beyond 20
    if (isLimitedUser && index >= 20) {
      _showUpgradeSnackbar();
      return;
    }

    setState(() => _showAnswer = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_questionsbank', _currentPage);

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
    final authState = context.read<AuthCubit>().state;

    // check if user is guest or not subscribed
    final bool isLimitedUser = authState is AuthGuest ||
        (authState is AuthAuthenticated &&
            (authState.subscribed == null || authState.subscribed == false));

    // if limited, cap the questions to 20
    final int allowedQuestions = isLimitedUser ? 20 : totalQuestions;
    final int maxPage = allowedQuestions - 1;

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
              value: _currentPage.clamp(0, maxPage).toDouble(),
              min: 0,
              max: maxPage.toDouble(),
              divisions: maxPage,
              label: "Q${_currentPage + 1}",
              onChanged: (val) {
                if (isLimitedUser && val.toInt() >= 20) {
                  _showUpgradeSnackbar();
                } else {
                  _pageController.jumpToPage(val.toInt());
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (_currentPage < maxPage)
                ? () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
                : () {
              if (isLimitedUser) _showUpgradeSnackbar();
            },
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
  void _showUpgradeSnackbar() {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'اشترك الآن واستمتع بكل المزايا!',
        message: 'قم بالترقية للوصول إلى جميع الأسئلة والمحاولات غير المحدودة!',
        contentType: ContentType.warning,
      ),
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

}

// =====================
// Units Tab
// =====================
class UnitsTab extends StatefulWidget {
  const UnitsTab({Key? key}) : super(key: key);

  @override
  State<UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<UnitsTab> {
  final Map<String, double> _unitProgress = {};
  late Future<Map<String, dynamic>?> _mistakesExamFuture;
  int _remainingTrials = 0;
  bool _isSubscribed = false;


  @override
  void initState() {
    super.initState();
    _loadProgress();
    _mistakesExamFuture = context.read<ExamCubit>().getPreviousMistakesExamData("tractors");
    _initTrials();
  }



  Future<void> _initTrials() async {
    final attempts = await TrialManager.getRemaining();
    final authState = context.read<AuthCubit>().state;
    setState(() {
      _remainingTrials = attempts;
      _isSubscribed = authState is AuthAuthenticated && authState.subscribed == true;
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mistakesExamFuture = context.read<ExamCubit>().getPreviousMistakesExamData("tractors");

  }


  // 🔹 Save progress persistently
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("unit_progress", jsonEncode(_unitProgress));
    debugPrint(" Saved unit progress: $_unitProgress");
  }

  // 🔹 Load saved progress
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("unit_progress");
    if (saved != null) {
      setState(() => _unitProgress.addAll(Map<String, double>.from(jsonDecode(saved))));
      debugPrint(" Loaded unit progress: $_unitProgress");
    } else {
      debugPrint("ℹ No saved progress found.");
    }
  }

  void _updateProgress(String title, double progress) {
    setState(() => _unitProgress[title] = progress);
    _saveProgress(); //  persist immediately
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamCubit, ExamState>(
      builder: (context, state) {
        if (state is! ExamLoaded) {
          return const Center(child: Text("Load an exam to see units"));
        }

        final questions = state.examData["questions"] as List<dynamic>?;
        if (questions == null || questions.isEmpty) {
          return const Center(child: Text("No tractor questions available."));
        }

        final total = questions.length;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [

                if (!_isSubscribed) ...[
                  Text(
                    "المحاولات المتبقية اليوم: $_remainingTrials / 10",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                ],

                FutureBuilder<Map<String, dynamic>?>(
                  future: _mistakesExamFuture,
                  builder: (context, snapshot) {
                    // Show nothing while loading
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final exam = snapshot.data;
                    // Check if data exists and has questions
                    if (exam != null && (exam["questions"] as List?)?.isNotEmpty == true) {
                      // Pass the loaded exam data to the build method
                      return _buildPreviousMistakesUnit(context, exam);
                    }
                    // Hide if no data is found
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "الأساسيات", questions, 0, 30.clamp(0, total)),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "رخصة قيادة تجارية: جرارات", questions, 30, 64.clamp(0, total)),
                const SizedBox(height: 20),
                _buildTimeAttackUnit(context, questions),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNormalUnit(
      BuildContext context,
      String title,
      List<dynamic> allQuestions,
      int start,
      int end,
      ) {
    final count = end - start;
    if (count <= 0) return const SizedBox.shrink();

    return UnitButton(
      title: title,
      questionCount: count,
      progress: _unitProgress[title] ?? 0.0,
      iconAsset: "assets/icons/unit_button_icon.png",
      onTap: () =>
          _navigateToUnit(context, title, allQuestions.sublist(start, end), start, end),
    );
  }

  Widget _buildTimeAttackUnit(BuildContext context, List<dynamic> allQuestions) {
    return UnitButton(
      title: "امتحان ضد الزمن",
      questionCount: AppConstants.timeAttackQuestions,
      progress: 0,
      iconAsset: "assets/icons/unit_button_icon.png",
      onTap: () => _startTimeAttack(context, allQuestions),
    );
  }

  Widget _buildPreviousMistakesUnit(BuildContext context, Map<String, dynamic> exam) {
    final questions = (exam["questions"] ?? []) as List<dynamic>;
    if (questions.isEmpty) return const SizedBox.shrink();

    final locked = !_isSubscribed;

    return UnitButton(
      title: exam["title"] ?? "Previous Mistakes",
      questionCount: questions.length,
      progress: _unitProgress[exam["title"]] ?? 0.0,
      accentColor: locked ? Colors.grey : kErrorColor,
      icon: Icons.error_outline,
      onTap: locked
          ? () => _showUpgradeDialog(context)
          : () {
        context.read<ExamCubit>().loadMistakesExamIntoState(exam);
        _navigateToUnit(context, exam["title"], questions, 0, questions.length);
      },
    );
  }


  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("محتوى مقفل"),
        content: const Text("قم بالترقية للوصول إلى الأخطاء السابقة."),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // In UnitsTab (around line 168 in original file)

  Future<void> _startTimeAttack(BuildContext context, List<dynamic> allQuestions) async {
    // ... (dialog logic remains the same)

    final randomized = List<dynamic>.from(allQuestions)..shuffle();
    final selected = randomized.take(AppConstants.timeAttackQuestions).toList();

    // FIX: Change the expected return type from <double> to <Map<String, dynamic>>
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => UnitQuestionsScreen(
          title: "⚡ Time Attack",
          questions: selected,
          startIndex: 0,
          endIndex: selected.length,
          isTimed: true,
          dashboardName: "Tractors",
        ),
      ),
    );

    // NEW: Logic to process the returned map, similar to _navigateToUnit
    if (!mounted || result == null) return;

    final progress = result["progress"] as double;
    // The selectedAnswers are not strictly needed for Time Attack progress update,
    // but keeping the structure consistent is good practice.
    // final answers = result["selectedAnswers"] as Map<int, int?>;

    // Assuming you want to track progress for Time Attack under its title
    _updateProgress("امتحان ضد الزمن", progress);
  }


  Future<void> _navigateToUnit(
      BuildContext context,
      String title,
      List<dynamic> questions,
      int start,
      int end,
      ) async {
    if (!_isSubscribed) {
      final remaining = await TrialManager.useOne();
      setState(() => _remainingTrials = remaining);
      if (remaining <= 0) {
        _showUpgradeDialog(context);
        return;
      }
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => UnitQuestionsScreen(
          title: title,
          questions: questions,
          startIndex: start,
          endIndex: end,
          dashboardName: "Tractors",
        ),
      ),
    );

    if (!mounted || result == null) return;

    final progress = result["progress"] as double;
    final answers = result["selectedAnswers"] as Map<int, int?>;
    _updateProgress(title, progress);

    // 🧹 If this was a Previous Mistakes exam, clean it up
    if (title.contains("Previous Mistakes") || title.contains("الأخطاء السابقة")) {
      final examCubit = context.read<ExamCubit>();
      await examCubit.updatePreviousMistakesAfterExam(
        answers,
        questions,
        "tractors",
      );
      debugPrint("✅ Cleaned up mistakes after finishing the exam");

      // Force reload of mistakes section
      setState(() {
        _mistakesExamFuture =
            examCubit.getPreviousMistakesExamData("tractors");
      });
    }
  }


}


// =====================
// Unit Questions Screen
// =====================

class UnitQuestionsScreen extends StatefulWidget {

  static List<dynamic> _mistakeCache = [];
  static List<dynamic> get mistakeCache => _mistakeCache;
  final mistakes = UnitQuestionsScreen.mistakeCache;
  final String dashboardName;

  static Future<void> loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith("exam_previous_mistakes_"))
        .toList();

    _mistakeCache.clear();

    for (final key in keys) {
      final saved = prefs.getString(key);
      if (saved != null) {
        try {
          final decoded = jsonDecode(saved);
          _mistakeCache.add(decoded);
        } catch (e) {
          debugPrint(" Skipped invalid cache entry $key: $e");
        }
      }
    }

    debugPrint(" Loaded ${_mistakeCache.length} cached mistake exams at startup.");
  }

  final String title;
  final List<dynamic> questions;
  final int startIndex;
  final int endIndex;
  final bool isTimed; // 🔹 for Time Attack mode

   UnitQuestionsScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.startIndex,
    required this.endIndex,
    this.isTimed = false,
    required this.dashboardName,
  });

  @override
  State<UnitQuestionsScreen> createState() => _UnitQuestionsScreenState();
}

class _UnitQuestionsScreenState extends State<UnitQuestionsScreen> {
  late DateTime _startTime;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _showAnswer = false;
  bool _isArabicExpanded = false;
  int? _selectedAnswerId;
  final FlutterTts _flutterTts = FlutterTts();

  static List<Map<String, dynamic>> _mistakeCache = [];

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

  Future<void> _saveMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("previous_mistakes", jsonEncode(_mistakeCache));
  }



  Future<void> _recordMistake(Map<String, dynamic> question) async {
    final exists = _mistakeCache.any((q) => q["questionId"] == question["questionId"]);
    if (!exists) {
      _mistakeCache.add(question);
      if (_mistakeCache.length > 64) {
        _mistakeCache = _mistakeCache.sublist(_mistakeCache.length - 64);
      }
      await _saveMistakes();

      if (_mistakeCache.length >= 10) {
        _createMistakeExam("tractors");
      }
    }
  }

  Future<void> _createMistakeExam([String examKey = "tractors"]) async {
    final prefs = await SharedPreferences.getInstance();
    final mistakeExam = {
      "title": "الأخطاء السابقة",
      "questions": _mistakeCache,
      "total": _mistakeCache.length,
    };
    await prefs.setString("exam_previous_mistakes_$examKey", jsonEncode(mistakeExam));
    debugPrint(" Saved Previous Mistakes for $examKey with ${_mistakeCache.length} questions");
  }


  void _startTimer(Map<String, dynamic> question) {
    if (!widget.isTimed) return;
    _questionTimer?.cancel();
    _remainingSeconds = 10;

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (!_showAnswer) {
          _submitAnswer(question); // auto-submit
        }
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _speakQuestion(Map<String, dynamic> question) async {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Text to Speech',
        message: 'Commencing text-to-speech for this question...',
        contentType: ContentType.help,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    final text = StringBuffer();
    text.writeln(question["questionText"]);
    for (var ans in question["answers"]) {
      text.writeln(ans["answerText"]);
    }

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(text.toString());
  }

  void _speakArabic(Map<String, dynamic> question) async {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'قراءة بالعربية',
        message: 'تشغيل الصوت للنص العربي...',
        contentType: ContentType.help,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    final text = StringBuffer();
    text.writeln(question["questionTextAr"]);
    for (var ans in question["answers"]) {
      text.writeln(ans["answerTextAr"]);
    }

    await _flutterTts.setLanguage("ar-SA");
    await _flutterTts.speak(text.toString());
  }

  void _submitAnswer(Map<String, dynamic> question) async {
    final correctAnswerId = question["questionId"];
    if (_selectedAnswerId == null) return;

    setState(() {
      _showAnswer = true;
      if (_selectedAnswerId == correctAnswerId) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    _questionTimer?.cancel();
    if (_selectedAnswerId != correctAnswerId) {
      await _recordMistake(question);
    }
  }

  void _nextQuestion() async {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerId = null;
        _showAnswer = false;
      });
      _startTimer(widget.questions[_currentIndex]);
    } else {
      _questionTimer?.cancel();
      final totalTime = DateTime.now().difference(_startTime);
      final totalQuestions = widget.questions.length;
      final percentage = (_correctCount / totalQuestions) * 100;

      final reportCard = ReportCard(
        correctAnswers: _correctCount,
        wrongAnswers: _wrongCount,
        timeElapsed: totalTime,
        percentage: percentage,
        dashboardName: widget.dashboardName, // Use the new field
        unitName: widget.title,              // Use the existing title
      );
      // 2. SAVE the ReportCard instance
      await ReportCardPersistence.saveReportCard(reportCard);

      // 3. Show final report dialog (using the created instance)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => reportCard, // Pass the created instance
      );

      if (!mounted) return;

      final progress = (_currentIndex + 1) / totalQuestions;
      await Future.delayed(const Duration(milliseconds: 300));
      //  Delay pop safely to avoid navigator lock
      Future.microtask(() {
        if (mounted) {
          Navigator.pop(context, {
            "progress": progress,
            "selectedAnswers": context.read<ExamCubit>().selectedAnswers,
          });
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final answers = question["answers"] as List<dynamic>;

    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("تحذير"),
            content: const Text("هل أنت متأكد أنك تريد مغادرة الامتحان؟ لن يتم حفظ التقدم."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("لا")),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("نعم")),
            ],
          ),
        );

        if (confirm != true) return false;

        final progress = (_currentIndex + 1) / widget.questions.length;
        Navigator.of(context).pop({
          "progress": progress,
          "selectedAnswers": context.read<ExamCubit>().state is ExamLoaded
              ? (context.read<ExamCubit>().state as ExamLoaded).selectedAnswers
              : <int, int?>{},
        });
        return false;
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title,
              style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w600, fontSize: 16)),
          backgroundColor: Colors.blue[700],
        ),
        backgroundColor: const Color(0xFFF9FAFC),
        body: Column(
          children: [
            _headerStatusBox(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildArabicCard(question, answers),
                      const SizedBox(height: 12),
                      _buildEnglishCard(question, answers),
                    ],
                  ),
              ),
            ),
          ],
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
              final isCorrect = _showAnswer && ans["answerId"] == question["questionId"];
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
                      _showAnswer ? "التالي" : "تأكيد",
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
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF64B2EF)),
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


