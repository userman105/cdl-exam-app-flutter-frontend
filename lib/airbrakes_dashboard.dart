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
import  'package:arabic_font/arabic_font.dart';
import 'blocs/auth_cubit.dart';
import 'services/report_storage.dart';
import 'subscription_screen.dart';
import 'register_screen.dart';
import 'services/trial_manager.dart';
import 'services/trial_manager.dart';
import 'airbrakes_bank_screen.dart';
import 'airbrakes_entry.dart';
import 'package:animate_do/animate_do.dart';

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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,

        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ---------------- LEFT: Subscription ----------------
            IconButton(
              icon: Image.asset(
                "assets/icons/subscription.png",
                width: 115,
                height: 115,
              ),
              onPressed: () {
                final authState = context.read<AuthCubit>().state;

                if (authState is AuthGuest) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("تسجيل الحساب"),
                      content: const Text(
                          "يجب عليك إنشاء حساب أولاً للاستفادة من العروض."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("إلغاء"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
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
                    ),
                  );
                } else if (authState is AuthAuthenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                }
              },
            ),

            // ---------------- CENTER: Title ----------------
            Text(
              "الفرامل الهوائية",
              textDirection: TextDirection.rtl,
              style: ArabicTextStyle(
                arabicFont: ArabicFont.dubai,
                fontWeight: FontWeight.w500,
                fontSize: 23,
              ),
            ),

            // ---------------- RIGHT: Back Arrow ----------------
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          _buildShadowDivider(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                AirBrakesExtraTab(),
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

  Widget _buildTabBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    child: Column(
      children: [



        const SizedBox(height: 10),

        // TABS (RIGHT ALIGNED)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CustomTabButton(
              text: "بنك الاسئلة",
              isActive: _tabController.index == 0,
              onTap: () => _tabController.animateTo(0),
            ),
            const SizedBox(width: 28),
            CustomTabButton(
              text: "التمارين",
              isActive: _tabController.index == 1,
              onTap: () => _tabController.animateTo(1),
            ),
          ],
        ),

        const SizedBox(height: 10),


      ],
    ),
  );


}

// =====================
// Airbrakes Questions Tab
// =====================

// =====================
// Airbrakes Units Tab
// =====================

class AirbrakesUnitsTab extends StatefulWidget {
  const AirbrakesUnitsTab({Key? key}) : super(key: key);

  @override
  State<AirbrakesUnitsTab> createState() => _AirbrakesUnitsTabState();
}

class _AirbrakesUnitsTabState extends State<AirbrakesUnitsTab> {
  int _remainingTrials = 0;
  bool _isSubscribed = false; // Will come from your auth state
  final Map<String, double> _unitProgressAirbrakes = {};
  late Future<Map<String, dynamic>?> _mistakesExamFuture;
  final String _examKey = "airbrakes";

  @override
  void initState() {
    super.initState();
    _loadProgressAirbrakes();
    _mistakesExamFuture =
        context.read<ExamCubit>().getPreviousMistakesExamData("airbrakes");
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
    _mistakesExamFuture =
        context.read<ExamCubit>().getPreviousMistakesExamData("airbrakes");

  }

  // 🔹 Save Airbrakes progress persistently
  Future<void> _saveProgressAirbrakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        "unit_progress_airbrakes", jsonEncode(_unitProgressAirbrakes));
    debugPrint(" Saved Airbrakes unit progress: $_unitProgressAirbrakes");
  }

  // 🔹 Load saved Airbrakes progress
  Future<void> _loadProgressAirbrakes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("unit_progress_airbrakes");
    if (saved != null) {
      setState(() =>
          _unitProgressAirbrakes.addAll(Map<String, double>.from(jsonDecode(saved))));
      debugPrint(" Loaded Airbrakes unit progress: $_unitProgressAirbrakes");
    } else {
      debugPrint("ℹ No saved Airbrakes progress found.");
    }
  }

  void _updateProgressAirbrakes(String title, double progress) {
    setState(() => _unitProgressAirbrakes[title] = progress);
    _saveProgressAirbrakes(); // 🔹 persist immediately
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final exam = snapshot.data;
                    if (exam != null && (exam["questions"] as List?)?.isNotEmpty == true) {
                      return _buildPreviousMistakesUnit(context, exam);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "الاساسيات", questions, 0, 25.clamp(0, total)),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "أنظمة المكابح", questions, 25, 50.clamp(0, total)),
                const SizedBox(height: 20),
                _buildNormalUnit(context, "اسوء السيناريوهات", questions, 50, 71.clamp(0, total)),
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
      BuildContext context, String title, List<dynamic> allQuestions, int start, int end) {
    final count = end - start;
    if (count <= 0) return const SizedBox.shrink();

    return UnitButton(
      title: title,
      questionCount: count,
      progress: _unitProgressAirbrakes[title] ?? 0.0,
      iconAsset: "assets/icons/unit_button_icon.png",
      onTap: () =>
          _navigateToUnit(context, title, allQuestions.sublist(start, end), start, end),
    );
  }

  Widget _buildTimeAttackUnit(BuildContext context, List<dynamic> allQuestions) {
    return UnitButton(
      title: "امتحان ضد الزمن",
      questionCount: 20,
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
      progress: _unitProgressAirbrakes[exam["title"]] ?? 0.0,
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

  Future<void> _startTimeAttack(BuildContext context, List<dynamic> allQuestions) async {
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("امتحان ضد الوقت"),
        content: const Text("لديك عشر ثواني لاجابة كل سؤال"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Start")),
        ],
      ),
    );

    if (start != true) return;

    final randomized = List<dynamic>.from(allQuestions)..shuffle();
    final selected = randomized.take(20).toList();

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AirbrakesUnitQuestionsScreen(
          title: "⚡ Time Attack",
          questions: selected,
          startIndex: 0,
          endIndex: selected.length,
          isTimed: true,
          dashboardName: 'Airbrakes',
        ),
      ),
    );

    if (!context.mounted) return;

    if (result != null) {
      final progress = result["progress"] as double? ?? 0.0;
      final selectedAnswers = result["selectedAnswers"] as Map<int, int?>?;

      _updateProgressAirbrakes("Time Attack", progress);

      debugPrint("Time Attack progress: $progress");
      debugPrint("Selected answers: $selectedAnswers");
    }
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
        builder: (_) => AirbrakesUnitQuestionsScreen(
          title: title,
          questions: questions,
          startIndex: start,
          endIndex: end,
          dashboardName: "Airbrakes",
        ),
      ),
    );

    if (!context.mounted) return;

    if (result != null) {
      final progress = result["progress"] as double? ?? 0.0;
      final selectedAnswers = result["selectedAnswers"] as Map<int, int?>?;

      _updateProgressAirbrakes(title, progress);

      debugPrint("Airbrakes unit finished with progress: $progress");
      debugPrint("Selected answers: $selectedAnswers");
    }

    // Refresh previous mistakes after returning
    setState(() {
      _mistakesExamFuture =
          context.read<ExamCubit>().getPreviousMistakesExamData(_examKey);
    });
  }


}

//-----------------------------
//--------UNIT-QUESTIONSCREEN (No changes needed for persistence fix)
//----------------------------

class AirbrakesUnitQuestionsScreen extends StatefulWidget {
  final String dashboardName;
  final String title;
  final List<dynamic> questions;
  final int startIndex;
  final int endIndex;
  final bool isTimed;
  static List<dynamic> _mistakeCache = [];
  static List<dynamic> get mistakeCache => _mistakeCache;

  const AirbrakesUnitQuestionsScreen({
    Key? key,
    required this.dashboardName,
    required this.title,
    required this.questions,
    required this.startIndex,
    required this.endIndex,
    this.isTimed = false,
  }) : super(key: key);


  static Future<void> loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("previous_mistakes_airbrakes");
    if (stored != null) {
      _mistakeCache = List<Map<String, dynamic>>.from(jsonDecode(stored));
    }
  }

  @override
  State<AirbrakesUnitQuestionsScreen> createState() =>
      _AirbrakesUnitQuestionsScreenState();
}

class _AirbrakesUnitQuestionsScreenState
    extends State<AirbrakesUnitQuestionsScreen> {
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

  ///  Airbrakes-specific correct answer formula
  int _getCorrectAnswerIdForAirbrakes(int questionId) {
    return 193 + (questionId - 65);
  }

  Future<void> _saveMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "previous_mistakes_airbrakes",
      jsonEncode(_mistakeCache),
    );
  }


  Future<void> _recordMistake(Map<String, dynamic> question) async {
    final prefs = await SharedPreferences.getInstance();
    const examKey = "airbrakes";
    const key = "exam_previous_mistakes_$examKey"; // match cubit key

    // Load existing mistakes
    List<dynamic> existing = [];
    final saved = prefs.getString(key);
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved);
        existing = (decoded["questions"] as List?) ?? [];
      } catch (_) {
        debugPrint(" Corrupted mistakes data for $examKey, resetting.");
      }
    }

    // Avoid duplicates
    final exists = existing.any((q) => q["questionId"] == question["questionId"]);
    if (!exists) {
      existing.add(question);

      final updatedExam = {
        "id": "mistakes_$examKey",
        "title": "الاخطاء السابقة",
        "questions": existing.take(71).toList(),
      };

      await prefs.setString(key, jsonEncode(updatedExam));
      debugPrint("Recorded mistake for Airbrakes: ${question["questionText"]}");
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

    final isCorrect =
        _selectedAnswerId == _getCorrectAnswerIdForAirbrakes(question["questionId"]);

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

    // Small safe delay + microtask to avoid Navigator locking asserts
    await Future.delayed(const Duration(milliseconds: 120));
    Future.microtask(() {
      if (!mounted) return;
      Navigator.pop(context, {
        "progress": progress,
        "selectedAnswers": context.read<ExamCubit>().selectedAnswers,
      });
    });
  }

  @override
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
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("لا"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("نعم"),
              ),
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

        return false; // prevent default pop, since we manually handled it
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _headerStatusBox(),
              const SizedBox(height: 16),
              _buildEnglishCard(question, answers),
              const SizedBox(height: 16),
              _buildArabicCard(question, answers),
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



  Widget _buildArabicCard(
      Map<String, dynamic> question,
      List<dynamic> answers,
      ) {
    final int correctAnswerId =
    _getCorrectAnswerIdForAirbrakes(question["questionId"]);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ---------------- Question ----------------
            Text(
              question["questionTextAr"] ?? "",
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            // ---------------- Answers ----------------
            ...answers.map((ans) {
              final int answerId = ans["answerId"];

              final bool isSelected = _selectedAnswerId == answerId;
              final bool isCorrect =
                  _showAnswer && answerId == correctAnswerId;
              final bool isWrong =
                  _showAnswer && isSelected && !isCorrect;

              final Color bgColor = isCorrect
                  ? Colors.green
                  : isWrong
                  ? Colors.red
                  : isSelected
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.white;

              final Color borderColor = isCorrect
                  ? Colors.green
                  : isWrong
                  ? Colors.red
                  : isSelected
                  ? Colors.blue
                  : Colors.grey.shade300;

              final Color textColor =
              (isCorrect || isWrong) ? Colors.white : Colors.black;

              final Widget answerTile = Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
                        ans["answerTextAr"] ?? "",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: (isCorrect || isWrong)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),

                    if (isCorrect)
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 26),

                    if (isWrong)
                      const Icon(Icons.cancel,
                          color: Colors.white, size: 26),
                  ],
                ),
              );

              return GestureDetector(
                onTap: !_showAnswer
                    ? () => setState(() => _selectedAnswerId = answerId)
                    : null,
                child: (_showAnswer && (isCorrect || isWrong))
                    ? BounceIn(child: answerTile)
                    : answerTile,
              );
            }),

            const SizedBox(height: 18),

            // ---------------- Bottom Buttons ----------------
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