import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/widgets.dart';
import '../constants/constants.dart';
import '../blocs/exam_cubit.dart';
import 'blocs/auth_cubit.dart';

class GeneralKnowledgeQuestionsTab extends StatefulWidget {
  final bool resumeFromLast;
  final int? questionLimit;


  const GeneralKnowledgeQuestionsTab({Key? key, this.resumeFromLast = false, this.questionLimit})
      : super(key: key);

  @override
  State<GeneralKnowledgeQuestionsTab> createState() =>
      _GeneralKnowledgeQuestionsTabState();
}

class _GeneralKnowledgeQuestionsTabState
    extends State<GeneralKnowledgeQuestionsTab> {
  // Progress map for this tab — note: key persisted uses "unit_progress_questions_tab"
  final Map<String, double> _unitProgressQuestionsTab = {};

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAnswer = false;

  int _getCorrectAnswerIdForGeneral(int questionId) {
    return 406 + (questionId - 136);
  }

  @override
  void initState() {
    super.initState();

    if (widget.resumeFromLast) {
      // Restore progress with dialog
      _restoreProgress();
    } else {
      // Wait for first frame, then jump to 0
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(0);
        setState(() => _currentPage = 0);
      });
    }
  }

  @override
  void dispose() {
    TTSService.stop();
    _pageController.dispose();
    super.dispose();
  }

  // ----------------------
  // Build
  // ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ensures no black background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // remove shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ExamCubit, ExamState>(
        builder: (context, state) {
          if (state is ExamLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExamError) {
            return Center(child: Text("Error: ${state.message}"));
          }

          if (state is ExamLoaded) {
            final questions = state.examData["questions"] as List<dynamic>;
            final realTotalQuestions = state.examData["totalQuestions"] as int;

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) async {

                      // ------------------------------------------------------
                      // 🔒 Restrict forward navigation if opened from Button C
                      // ------------------------------------------------------
                      if (widget.questionLimit != null) {
                        if (i >= widget.questionLimit!) {
                          // User tried going past the limit → stop them
                          _pageController.jumpToPage(widget.questionLimit! - 1);
                          return;
                        }
                      }

                      // ------------------------------------------------------
                      // 🔒 Free version restriction (your existing logic)
                      // ------------------------------------------------------
                      final authState = context.read<AuthCubit>().state;
                      final bool isLimitedUser = authState is AuthGuest ||
                          (authState is AuthAuthenticated &&
                              (authState.subscribed == null ||
                                  authState.subscribed == false));

                      if (isLimitedUser && i >= 7) {
                        _showUpgradeSnackbar();
                        _pageController.jumpToPage(6);
                        return;
                      }

                      // ------------------------------------------------------
                      // Save progress (NORMAL behavior)
                      // ------------------------------------------------------
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('progress_questionsbank', i);

                      // ------------------------------------------------------
                      // Update UI
                      // ------------------------------------------------------
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
                _buildNavigationBar(realTotalQuestions),
              ],
            );
          }

          return const Center(child: Text("No exam loaded"));
        },
      ),
    );
  }



  // ----------------------
  // Question page
  // ----------------------
  Widget _buildQuestionPage(
      List<dynamic> questions, int index, ExamLoaded examState) {
    final question = questions[index];
    final answers = question["answers"] as List<dynamic>;
    final questionId = question["questionId"];
    final selected = examState.selectedAnswers[questionId];

    return Column(
      children: [
        // Arabic / main interactive card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
            _buildArabicQuestionCard(question, answers, questionId, selected),
          ),
        ),

        // English expansion
        EnglishExpansionCard(
          question: question,
          answers: answers,
          onTTSTap: () => _speakEnglish(question, answers),
        ),

        // Show answer button
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    ...answers.map(
                          (ans) => AnswerOption(
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TTS button
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    ...answers.map((ans) {
                      final isSelected = selected == ans["answerId"];
                      final correctAnswerId = _getCorrectAnswerIdForGeneral(qid);
                      final isCorrect = _showAnswer && ans["answerId"] == correctAnswerId;
                      final isWrong = _showAnswer && isSelected && !isCorrect;

                      return GestureDetector(
                        onTap: !_showAnswer
                            ? () => context
                            .read<ExamCubit>()
                            .selectAnswer(qid, ans["answerId"])
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

            // English TTS
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

  // ----------------------
  // Show Answer button
  // ----------------------
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

    // SAME BEHAVIOR AS QuestionsBankTab:
    // Limited users can ONLY access first 7 questions
    final int allowedQuestions = isLimitedUser ? 7 : questions.length;

    if (isLimitedUser && index >= allowedQuestions) {
      _showUpgradeSnackbar();
      return;
    }

    // Show the answer temporarily
    setState(() => _showAnswer = true);

    // Save progress
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_questionsbank', _currentPage);

    // Match the 1-second answer reveal like previous class
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _showAnswer = false);

    // Auto-next (exactly like previous class)
    if (index < allowedQuestions - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last accessible question reached
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have reached the last question")),
      );
    }
  }


  // ----------------------
  // Navigation bar (uses realTotalQuestions for display and validation)
  // ----------------------
  Widget _buildNavigationBar(int realTotalQuestions) {
    final authState = context.read<AuthCubit>().state;

    final bool isLimitedUser = authState is AuthGuest ||
        (authState is AuthAuthenticated &&
            (authState.subscribed == null || authState.subscribed == false));

    // ----- NEW: PROGRESS-BASED LIMIT -----
    final prefs = SharedPreferences.getInstance();

    return FutureBuilder<SharedPreferences>(
      future: prefs,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final savedProgress = snapshot.data!.getInt('progress_questionsbank') ?? 0;

        // The user can access everything they already reached in button A
        final int progressLimit = savedProgress + 1;

        // ---- Final accessible count ----
        // Apply subscription limit AND progress limit together
        final int accessibleQuestions = isLimitedUser
            ? min(7, progressLimit)
            : progressLimit;

        final int maxPage = (accessibleQuestions > 0)
            ? accessibleQuestions - 1
            : 0;

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
                child: GestureDetector(
                  onTap: () => _showJumpDialog(
                    accessibleQuestions: accessibleQuestions,
                    realTotalQuestions: realTotalQuestions,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Center(
                      child: Text(
                        "${_currentPage + 1} / $realTotalQuestions",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final savedProgress = prefs.getInt('progress_questionsbank') ?? 0;

                  final authState = context.read<AuthCubit>().state;
                  final bool isLimitedUser = authState is AuthGuest ||
                      (authState is AuthAuthenticated &&
                          (authState.subscribed == null || authState.subscribed == false));

                  // FINAL computed limit (must match onPageChanged!)
                  final int progressLimit = savedProgress + 1;
                  final int allowedBySub = isLimitedUser ? 7 : progressLimit;
                  final int maxPage = allowedBySub - 1;

                  // ----- Button C limit (must also match onPageChanged)
                  if (widget.questionLimit != null) {
                    final int limitC = widget.questionLimit! - 1;
                    if (_currentPage >= limitC) {
                      _showUpgradeSnackbar();
                      return;
                    }
                  }

                  // ----- Free user subscription limit
                  if (_currentPage >= maxPage) {
                    _showUpgradeSnackbar();
                    return;
                  }

                  // ----- Advance (safe)
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),

            ],
          ),
        );
      },
    );
  }


  // ----------------------
  // Jump dialog (validates both accessible and real total)
  // ----------------------
  void _showJumpDialog({
    required int accessibleQuestions,
    required int realTotalQuestions,
  }) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("اذهب إلى سؤال"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "رقم السؤال...",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("إلغاء"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("اذهب"),
              onPressed: () {
                final raw = controller.text.trim();
                if (raw.isEmpty) {
                  _showError("الرجاء إدخال رقم.");
                  return;
                }

                final value = int.tryParse(raw);
                if (value == null) {
                  _showError("الرجاء إدخال رقم صحيح.");
                  return;
                }

                if (value <= 0) {
                  _showError("رقم السؤال يجب أن يكون 1 أو أكبر.");
                  return;
                }

                if (value > accessibleQuestions) {
                  _showError(
                      "لا يمكنك تخطي السؤال $accessibleQuestions لأنك مستخدم محدود.");
                  return;
                }

                if (value > realTotalQuestions) {
                  _showError("لا يوجد سؤال رقم $value.");
                  return;
                }

                _pageController.jumpToPage(value - 1);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ----------------------
  // TTS helpers
  // ----------------------
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

  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('progress_questionsbank') ?? 0;

    if (savedPage == 0) return; // No previous progress → nothing to ask

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool? resume = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("استكمال التقدم؟"),
            content: const Text("هل تريد الرجوع لنفس السؤال الذي توقفت عنده؟"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false); // Restart from question 1
                },
                child: const Text("ابدأ من جديد"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true); // Resume
                },
                child: const Text("استكمال"),
              ),
            ],
          );
        },
      );

      if (resume == true) {
        // Jump to saved page
        _pageController.jumpToPage(savedPage);
        setState(() => _currentPage = savedPage);
      } else {
        // Reset to page 0
        _pageController.jumpToPage(0);
        await prefs.setInt('progress_questionsbank', 0);
        setState(() => _currentPage = 0);
      }
    });
  }


}
