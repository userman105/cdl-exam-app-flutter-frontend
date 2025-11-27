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

class QuestionsBankStudyTab extends StatefulWidget {
  final bool resumeFromLast;

  const QuestionsBankStudyTab({Key? key, this.resumeFromLast = false})
      : super(key: key);

  @override
  State<QuestionsBankStudyTab> createState() => _QuestionsBankStudyTabState();
}

class _QuestionsBankStudyTabState extends State<QuestionsBankStudyTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Keep your original correct answer formula
  int _getCorrectAnswerIdForTrailersAndTractors(int questionId) {
    return questionId;
  }

  @override
  void initState() {
    super.initState();
    if (widget.resumeFromLast) _restoreProgress();
  }

  @override
  void dispose() {
    TTSService.stop();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('tractors_progress_questionsbank_study') ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(savedPage);
      setState(() => _currentPage = savedPage);
    });
  }

  Future<void> _saveProgress(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tractors_progress_questionsbank_study', page);
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
                              (authState.subscribed == null ||
                                  authState.subscribed == false));

                      // optional limited questions
                      if (isLimitedUser && i >= 20) {
                        _showUpgradeSnackbar();
                        _pageController.jumpToPage(19);
                        return;
                      }

                      await _saveProgress(i);
                      setState(() => _currentPage = i);
                    },
                    itemCount: questions.length,
                    itemBuilder: (context, index) => _buildQuestionPage(questions, index),
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

  Widget _buildQuestionPage(List<dynamic> questions, int index) {
    final question = questions[index];
    final answers = question["answers"] as List<dynamic>;
    final questionId = question["questionId"];
    final correctId = _getCorrectAnswerIdForTrailersAndTractors(questionId);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
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
                            ...answers.where((ans) => ans["answerId"] == correctId).map(
                                  (ans) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Text(
                                  ans["answerTextAr"],
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
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
            ),
          ),
        ),
        EnglishExpansionCard(
          question: question,
          answers: answers,
          onTTSTap: () => _speakEnglish(question, answers),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(int totalQuestions) {
    final authState = context.read<AuthCubit>().state;
    final bool isLimitedUser = authState is AuthGuest ||
        (authState is AuthAuthenticated &&
            (authState.subscribed == null || authState.subscribed == false));

    final int accessibleQuestions = isLimitedUser ? 20 : totalQuestions;
    final int maxPage = (accessibleQuestions > 0) ? accessibleQuestions - 1 : 0;

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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Center(
                child: Text(
                  "${_currentPage + 1} / $totalQuestions",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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