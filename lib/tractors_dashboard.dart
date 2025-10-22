import 'dart:convert';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/exam_cubit.dart';


// =====================
// Global TTS Instance
// =====================
final FlutterTts flutterTts = FlutterTts();

Future<void> speak(
    String text,
    BuildContext context, {
      String langCode = "en-US",
    }) async {
  try {
    await flutterTts.setLanguage(langCode);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  } catch (e) {
    debugPrint("TTS Error: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            title: 'TTS Error',
            message: 'Unable to play text-to-speech.',
            contentType: ContentType.failure,
          ),
        ),
      );
    }
  }
}

// =====================
// Main Dashboard
// =====================
class TractorsDashboard extends StatefulWidget {
  const TractorsDashboard({super.key});

  @override
  State<TractorsDashboard> createState() => _TractorsDashboardState();
}

class _TractorsDashboardState extends State<TractorsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _unitCurrentIndex = 0;
  int _unitTotal = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadHeaderProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHeaderProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('progress_A Real Exam') ?? 0;

    setState(() {
      _unitCurrentIndex = saved;
    });

    final examState = context.read<ExamCubit>().state;
    if (examState is ExamLoaded) {
      final questions = examState.examData['questions'] as List<dynamic>;
      final unit1 = questions.take(30).toList();
      _unitTotal = unit1.length;

      final selectedMap = examState.selectedAnswers;
      var correct = 0;
      var wrong = 0;

      for (var q in unit1) {
        final qid = q['questionId'];
        final sel = selectedMap[qid];
        if (sel != null) {
          if (sel == qid) {
            correct++;
          } else {
            wrong++;
          }
        }
      }

      setState(() {
        _correctCount = correct;
        _wrongCount = wrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExamCubit, ExamState>(
      listenWhen: (_, __) => true,
      listener: (_, __) => _loadHeaderProgress(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Tractors and Trailers",
            style: GoogleFonts.robotoSlab(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              icon: Image.asset(
                "assets/icons/subscription.png",
                width: 134,
                height: 134,
              ),
              onPressed: () {
                // TODO: Implement subscription functionality
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top border shadow
            Container(
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
            ),

            // Tab buttons row
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    "assets/icons/the_star.png",
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  _buildTabButton("Questions Bank", 0, 86),
                  const SizedBox(width: 12),
                  _buildTabButton("Exams", 1, 50),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _QuestionsBankTab(),
                  _UnitsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index, double underlineWidth) {
    final isActive = _tabController.index == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _tabController.animateTo(index),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 4,
            width: underlineWidth,
            color: Colors.black,
          ),
      ],
    );
  }
}

// =====================
// Questions Bank Tab
// =====================
class _QuestionsBankTab extends StatefulWidget {
  const _QuestionsBankTab();

  @override
  State<_QuestionsBankTab> createState() => _QuestionsBankTabState();
}

class _QuestionsBankTabState extends State<_QuestionsBankTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAnswer = false;

  @override
  void dispose() {
    flutterTts.stop();
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
                  itemBuilder: (context, index) {
                    return _buildQuestionPage(
                      context,
                      questions,
                      index,
                      state,
                    );
                  },
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

  Widget _buildQuestionPage(
      BuildContext context,
      List<dynamic> questions,
      int index,
      ExamLoaded state,
      ) {
    final q = questions[index];
    final answers = q["answers"] as List<dynamic>;
    final questionId = q["questionId"];
    final selected = state.selectedAnswers[questionId];

    return Column(
      children: [
        // English Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
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
                              "Q${index + 1}: ${q['questionText']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 24),
                            ...answers.map((ans) => _buildAnswerOption(
                              ans,
                              questionId,
                              selected,
                              context,
                            )),
                          ],
                        ),
                      ),
                    ),
                    // TTS Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: SvgPicture.asset(
                          "assets/icons/tts.svg",
                          width: 32,
                          height: 32,
                        ),
                        onPressed: () => _playEnglishTTS(context, q, answers, index),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Arabic Card
        _buildArabicCard(q, answers, index),

        // Show Answer Button
        _buildShowAnswerButton(context, questions, index),
      ],
    );
  }

  Widget _buildAnswerOption(
      dynamic ans,
      int questionId,
      int? selected,
      BuildContext context,
      ) {
    final answerId = ans["answerId"];
    final isCorrect = answerId == questionId;
    final isSelected = selected == answerId;

    Color? bg;
    Color textColor = Colors.black;

    if (_showAnswer && isCorrect) {
      bg = Colors.green.withOpacity(0.85);
      textColor = Colors.white;
    } else if (_showAnswer && isSelected && !isCorrect) {
      bg = Colors.red.withOpacity(0.85);
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: RadioListTile<int>(
        title: Text(
          ans["answerText"],
          style: TextStyle(color: textColor),
        ),
        value: answerId,
        groupValue: selected,
        onChanged: (val) {
          if (val != null && !_showAnswer) {
            context.read<ExamCubit>().selectAnswer(questionId, val);
          }
        },
      ),
    );
  }

  Widget _buildArabicCard(dynamic q, List<dynamic> answers, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: const Text(
            "Show Arabic Translation",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            const Divider(height: 20),
            // Arabic Question
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  q["questionTextAr"] ?? "",
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Arabic Answers
            ...answers.map((ans) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    ans["answerTextAr"] ?? "",
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              );
            }),
            // Arabic TTS button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: SvgPicture.asset(
                  "assets/icons/tts.svg",
                  width: 32,
                  height: 32,
                ),
                onPressed: () => _playArabicTTS(context, q, answers),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton(
      BuildContext context,
      List<dynamic> questions,
      int index,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64B2EF),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: () async {
            setState(() {
              _showAnswer = true;
            });

            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('progress_questionsbank', _currentPage);

            await Future.delayed(const Duration(seconds: 1));

            if (mounted) {
              setState(() {
                _showAnswer = false;
              });

              if (index < questions.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You have reached the last question"),
                  ),
                );
              }
            }
          },
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

  Widget _buildNavigationBar(int totalQuestions) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 0
                ? () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
          ),
          Expanded(
            child: Slider(
              value: _currentPage.toDouble(),
              min: 0,
              max: (totalQuestions - 1).toDouble(),
              divisions: totalQuestions - 1,
              label: "Q${_currentPage + 1}",
              onChanged: (val) {
                _pageController.jumpToPage(val.toInt());
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < totalQuestions - 1
                ? () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
          ),
        ],
      ),
    );
  }

  void _playEnglishTTS(
      BuildContext context,
      dynamic q,
      List<dynamic> answers,
      int index,
      ) {
    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      content: AwesomeSnackbarContent(
        title: 'Text-to-Speech',
        message: 'Commencing text to speech...',
        contentType: ContentType.help,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);

    final enText = "Q${index + 1}: ${q['questionText']}. ${answers.asMap().entries.map((e) {
      return "${e.key + 1}. ${e.value['answerText']}";
    }).join(", ")}";

    speak(enText, context, langCode: "en-US");
  }

  void _playArabicTTS(
      BuildContext context,
      dynamic q,
      List<dynamic> answers,
      ) {
    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      content: AwesomeSnackbarContent(
        title: 'Text-to-Speech',
        message: 'Commencing text to speech...',
        contentType: ContentType.help,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);

    final arText = "${q['questionTextAr']}. ${answers.asMap().entries.map((e) {
      return "${e.key + 1}. ${e.value['answerTextAr']}";
    }).join("، ")}";

    speak(arText, context, langCode: "ar-SA");
  }
}

// =====================
// Units Tab
// =====================
class _UnitsTab extends StatefulWidget {
  const _UnitsTab();

  @override
  State<_UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<_UnitsTab> {
  final Map<String, double> _unitProgress = {};
  Map<String, dynamic>? _previousMistakesExam;

  void _updateProgress(String title, double progress) {
    setState(() => _unitProgress[title] = progress);
  }

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
                _buildUnitButton(context, "CDL trailers", questions, 30, 64.clamp(0, total)),
                const SizedBox(height: 20),
                if (_previousMistakesExam != null)
                  _buildPreviousMistakesButton(context, _previousMistakesExam!),
              ],
            ),
          ),
        );
      },
    );
  }

  // Normal unit button builder (unchanged)
  Widget _buildUnitButton(
      BuildContext context,
      String title,
      List<dynamic> allQuestions,
      int startIndex,
      int endIndex,
      ) {
    final count = endIndex - startIndex;
    if (count <= 0) return const SizedBox.shrink();

    final progress = _unitProgress[title] ?? 0.0;
    final unitQuestions = allQuestions.sublist(startIndex, endIndex);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push<double>(
              context,
              MaterialPageRoute(
                builder: (_) => UnitQuestionsScreen(
                  title: title,
                  questions: unitQuestions,
                  startIndex: startIndex,
                  endIndex: endIndex,
                ),
              ),
            );
            if (result != null) _updateProgress(title, result);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset("assets/icons/unit_button_icon.png", width: 28, height: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF878C9F),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("$count Questions",
                        style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFD9D9D9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF64B2EF)),
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

  // ✅ Special button for “Previous Mistakes”
  Widget _buildPreviousMistakesButton(BuildContext context, Map<String, dynamic> mistakesExam) {
    final title = mistakesExam["title"] ?? "Previous Mistakes";
    final questions = (mistakesExam["questions"] ?? []) as List<dynamic>;
    final count = questions.length;
    final progress = _unitProgress[title] ?? 0.0;

    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push<double>(
              context,
              MaterialPageRoute(
                builder: (_) => UnitQuestionsScreen(
                  title: title,
                  questions: questions,
                  startIndex: 0,
                  endIndex: count,
                ),
              ),
            );
            if (result != null) _updateProgress(title, result);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF6461), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF6461),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("$count Questions",
                        style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFD9D9D9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF6461)),
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




// =====================
// Unit Questions Screen
// =====================


class UnitQuestionsScreen extends StatefulWidget {
  final String title;
  final List<dynamic> questions;
  final int startIndex;
  final int endIndex;

  const UnitQuestionsScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  State<UnitQuestionsScreen> createState() => _UnitQuestionsScreenState();
}

class _UnitQuestionsScreenState extends State<UnitQuestionsScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _showAnswer = false;
  bool _isArabicExpanded = false;
  final FlutterTts _flutterTts = FlutterTts();
  int? _selectedAnswerId;

  // 🔹 Static list to store all mistakes globally
  static List<Map<String, dynamic>> _mistakeCache = [];

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // 🔹 Save mistakes persistently
  Future<void> _saveMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("previous_mistakes", jsonEncode(_mistakeCache));
  }

  // 🔹 Load mistakes (optional if you want to persist across sessions)
  static Future<void> loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("previous_mistakes");
    if (stored != null) {
      _mistakeCache = List<Map<String, dynamic>>.from(jsonDecode(stored));
    }
  }

  // 🔹 Add a new mistake safely
  Future<void> _recordMistake(Map<String, dynamic> question) async {
    final exists = _mistakeCache.any((q) => q["questionId"] == question["questionId"]);
    if (!exists) {
      _mistakeCache.add(question);
      if (_mistakeCache.length > 64) {
        _mistakeCache = _mistakeCache.sublist(_mistakeCache.length - 64); // keep last 64
      }
      await _saveMistakes();

      if (_mistakeCache.length >= 10) {
        _createMistakeExam();
      }
    }
  }

  // 🔹 Create the “Previous Mistakes” exam
  Future<void> _createMistakeExam() async {
    final prefs = await SharedPreferences.getInstance();
    final mistakeExam = {
      "title": "Previous Mistakes",
      "questions": _mistakeCache,
      "total": _mistakeCache.length,
    };
    await prefs.setString("exam_previous_mistakes", jsonEncode(mistakeExam));
  }

  // 🔹 English TTS
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

  // 🔹 Arabic TTS
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

  // 🔹 Submit answer
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

    // Record mistake if wrong
    if (_selectedAnswerId != correctAnswerId) {
      await _recordMistake(question);
    }
  }

  // 🔹 Move to next question
  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerId = null;
        _showAnswer = false;
      });
    } else {
      final progress = (_currentIndex + 1) / widget.questions.length;
      Navigator.pop(context, progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final answers = question["answers"] as List<dynamic>;

    return WillPopScope(
      onWillPop: () async {
        final progress = (_currentIndex + 1) / widget.questions.length;
        Navigator.pop(context, progress);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title,
              style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.w600, fontSize: 16)),
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
                    _buildEnglishCard(question, answers),
                    const SizedBox(height: 12),
                    _buildArabicCard(question, answers),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Build English Question Card
  Widget _buildEnglishCard(Map<String, dynamic> question, List<dynamic> answers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question["questionText"],
                style: GoogleFonts.robotoSlab(
                    fontSize: 18, fontWeight: FontWeight.w600)),
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
                  child: Text(ans["answerText"],
                      style: GoogleFonts.robotoSlab(fontSize: 16)),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _speakQuestion(question),
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Read"),
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
                    onPressed: _showAnswer
                        ? _nextQuestion
                        : () => _submitAnswer(question),
                    child: Text(
                      _showAnswer ? "Next" : "Submit",
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

  // 🔹 Build Arabic Card
  Widget _buildArabicCard(Map<String, dynamic> question, List<dynamic> answers) {
    return Card(
      elevation: 4,
      color: Colors.white,
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
                  icon: const Icon(Icons.volume_up_rounded,
                      color: Color(0xFF64B2EF)),
                  onPressed: () => _speakArabic(question),
                ),
                Expanded(
                  child: Text(
                    "العربية",
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
                  onPressed: () =>
                      setState(() => _isArabicExpanded = !_isArabicExpanded),
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(question["questionTextAr"],
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    ...answers.map((ans) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(ans["answerTextAr"],
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54)),
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

  /// 🔹 Status header
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
          Text(
            "Q${_currentIndex + 1}/${widget.questions.length}",
            style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
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
              Text("✓ $_correctCount",
                  style: GoogleFonts.robotoSlab(color: Colors.green[700])),
              const SizedBox(width: 10),
              Text("✕ $_wrongCount",
                  style: GoogleFonts.robotoSlab(color: Colors.red[700])),
            ],
          ),
        ],
      ),
    );
  }
}
