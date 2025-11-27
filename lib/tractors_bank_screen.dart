import 'dart:async';
import 'dart:convert';

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

class QuestionsBankTab extends StatefulWidget {
  final bool resumeFromLast;

  final int? questionLimit;

  const QuestionsBankTab({Key? key, this.resumeFromLast = false, this.questionLimit}) : super(key: key);

  @override
  State<QuestionsBankTab> createState() => _QuestionsBankTabState();
}


class _QuestionsBankTabState extends State<QuestionsBankTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAnswer = false;

  // Keep your existing correct-answer logic
  int _getCorrectAnswerIdForTrailersAndTractors(int questionId) {
    return questionId;
  }

  @override
  void initState() {
    super.initState();
    if (widget.resumeFromLast) _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('tractors_progress_questionsbank') ?? 0;
    if (savedPage == 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(savedPage);
      setState(() => _currentPage = savedPage);
    });
  }

  @override
  void dispose() {
    TTSService.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Questions Bank",
          style: GoogleFonts.robotoSlab(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<ExamCubit, ExamState>(
        builder: (context, state) {
          if (state is ExamLoading) return const Center(child: CircularProgressIndicator());
          if (state is ExamError) return Center(child: Text("Error: ${state.message}"));
          if (state is ExamLoaded) {
            final questions = state.examData["questions"] as List<dynamic>;
            final totalQuestions = questions.length;

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) async {
                      final authState = context.read<AuthCubit>().state;
                      final bool isLimitedUser = authState is AuthGuest ||
                          (authState is AuthAuthenticated &&
                              (authState.subscribed == null || authState.subscribed == false));
                      final int allowedQuestions = isLimitedUser ? 20 : totalQuestions;

                      if (isLimitedUser && i >= allowedQuestions) {
                        _showUpgradeSnackbar();
                        _pageController.jumpToPage(allowedQuestions - 1);
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('tractors_progress_questionsbank', i);

                      setState(() {
                        _currentPage = i;
                        _showAnswer = false;
                      });
                    },
                    itemCount: widget.questionLimit ?? questions.length,
                    itemBuilder: (context, index) =>
                        _buildQuestionPage(questions, index, state),
                  ),
                ),
                _buildNavigationBar(totalQuestions),
              ],
            );
          }

          return const Center(child: Text("No exam loaded"));
        },
      ),
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
            child: _buildArabicQuestionCard(question, answers, questionId, selected),
          ),
        ),
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
      int? selected) {
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
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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

    if (isLimitedUser && index >= 20) {
      _showUpgradeSnackbar();
      return;
    }

    setState(() => _showAnswer = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _showAnswer = false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tractors_progress_questionsbank', _currentPage);

    if (index < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildNavigationBar(int totalQuestions) {
    final authState = context.read<AuthCubit>().state;
    final bool isLimitedUser = authState is AuthGuest ||
        (authState is AuthAuthenticated &&
            (authState.subscribed == null || authState.subscribed == false));
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
            child: GestureDetector(
              onTap: () => _showJumpDialog(totalQuestions, allowedQuestions),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Center(
                  child: Text("${_currentPage + 1} / $totalQuestions",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (_currentPage < maxPage)
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

  void _showJumpDialog(int realTotalQuestions, int accessibleQuestions) {
    final controller = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("اذهب إلى سؤال"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "رقم السؤال..."),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء")),
            TextButton(
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value == null ||
                      value <= 0 ||
                      value > accessibleQuestions ||
                      value > realTotalQuestions) {
                    _showError("رقم السؤال غير صالح.");
                    return;
                  }
                  _pageController.jumpToPage(value - 1);
                  Navigator.pop(context);
                },
                child: const Text("اذهب")),
          ],
        ));
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _speakEnglish(Map<String, dynamic> question, List<dynamic> answers) {
    final text = "Q${_currentPage + 1}: ${question['questionText']}. "
        "${answers.map((a) => a['answerText']).join(', ')}";
    TTSService.speak(text, context, langCode: "en-US");
  }

  void _speakArabic(Map<String, dynamic> question, List<dynamic> answers) {
    final text = "${question['questionTextAr']}. "
        "${answers.map((a) => a['answerTextAr']).join('، ')}";
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