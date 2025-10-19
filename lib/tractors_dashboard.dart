import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/exam_cubit.dart';
import 'first_screen.dart';
import 'blocs/auth_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
class TractorsDashboard extends StatelessWidget {
  const TractorsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tractors Dashboard"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Questions Bank"),
              Tab(text: "Units"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _QuestionsBankTab(),
            _UnitsTab(),
          ],
        ),
      ),
    );
  }
}

/// ----------------------
/// Questions Bank Tab
/// ----------------------
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
                      _showAnswer = false; // reset when moving
                    });
                  },
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final answers = q["answers"] as List<dynamic>;
                    final questionId = q["questionId"];
                    final selected = state.selectedAnswers[questionId];

                    return Column(
                      children: [
                        // =====================
                        // Top English Card
                        // =====================
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
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Q${index + 1}: ${q['questionText']}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                            const Divider(height: 24),

                                            // English answers
                                            ...answers.map((ans) {
                                              final answerId = ans["answerId"];
                                              final isCorrect =
                                                  answerId == questionId;
                                              final isSelected =
                                                  selected == answerId;

                                              return
                                                Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _showAnswer && isCorrect
                                                        ? Colors.green.withOpacity(0.8)
                                                        : null,
                                                    borderRadius: BorderRadius.circular(18),
                                                  ),
                                                  child: RadioListTile<int>(
                                                    title: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            ans["answerText"],
                                                            style: TextStyle(
                                                              fontFamily: 'Roboto',
                                                              color: _showAnswer && isCorrect
                                                                  ? Colors.white  // White text when correct answer shown
                                                                  : Colors.black,  // Default black text
                                                              fontWeight: _showAnswer && isCorrect
                                                                  ? FontWeight.bold  // Optional: make it bold too
                                                                  : FontWeight.normal,
                                                            ),
                                                          ),
                                                        ),
                                                        if (_showAnswer && isCorrect)
                                                          const Icon(
                                                            Icons.check_circle,
                                                            color: Colors.white,  // Changed from green to white
                                                          ),
                                                      ],
                                                    ),
                                                    value: answerId,
                                                    groupValue: selected,
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        context
                                                            .read<ExamCubit>()
                                                            .selectAnswer(questionId, val);
                                                      }
                                                    },
                                                  ),
                                                );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Sticky Show Answer
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF64B2EF),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          elevation: 4,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showAnswer = true;
                                          });
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // =====================
                        // Bottom Arabic Card
                        // =====================
                        Card(
                          margin: const EdgeInsets.all(8),
                          elevation: 3,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            title: const Text(
                              "عرض السؤال بالعربية",
                              textDirection: TextDirection.rtl,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Arabic question
                                    Text(
                                      q["questionTextAr"] ?? "",
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Divider(height: 20),

                                    // Arabic answers
                                    ...answers.map((ans) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
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
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // =====================
              // Bottom navigation + slider
              // =====================
              Padding(
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
                      child: SliderTheme(

                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 14, // 🔵 make circle bigger (default is 10)
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 24, // halo effect when dragging
                          ),
                          activeTrackColor: const Color(0xFF64B2EF), // match your theme
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: const Color(0xFF64B2EF),
                          valueIndicatorColor: const Color(0xFF64B2EF),
                        ),

                        child: Slider(
                        value: _currentPage.toDouble(),
                        min: 0,
                        max: (questions.length - 1).toDouble(),
                        divisions: questions.length - 1,
                        label: "Q${_currentPage + 1}",
                        onChanged: (val) {
                        _pageController.jumpToPage(val.toInt());
                        },
                        ),
                        ),
                      ),

                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentPage < questions.length - 1
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
              )
            ],
          );
        }
        return const Center(child: Text("No exam loaded"));
      },
    );
  }
}


/// ----------------------
/// Units Tab
/// ----------------------
class _UnitsTab extends StatelessWidget {
  const _UnitsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamCubit, ExamState>(
      builder: (context, state) {
        if (state is! ExamLoaded) {
          return const Center(child: Text("Load an exam to see units"));
        }

        final questions = state.examData["questions"] as List<dynamic>;
        final unit1 = questions.take(30).toList();
        final unit2 = questions.skip(30).take(30).toList();
        final unit3 = questions.skip(60).toList();

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildUnitButton(context, "Unit 1 (Q1–30)", unit1),
              const SizedBox(height: 20),
              _buildUnitButton(context, "Unit 2 (Q31–60)", unit2),
              const SizedBox(height: 20),
              _buildUnitButton(context, "Unit 3 (Q61–64)", unit3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnitButton(BuildContext context, String title, List<dynamic> questions) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnitQuestionsScreen(title: title, questions: questions),
          ),
        );
      },
      child: Text(title, style: const TextStyle(fontSize: 16)),
    );
  }
}

/// ----------------------
/// Unit Questions Screen
/// ----------------------
class UnitQuestionsScreen extends StatelessWidget {
  final String title;
  final List<dynamic> questions;

  const UnitQuestionsScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocBuilder<ExamCubit, ExamState>(
        builder: (context, state) {
          if (state is! ExamLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return PageView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final answers = q["answers"] as List<dynamic>;
              final questionId = q["questionId"];

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // English question
                        Text(
                          "Q${index + 1}: ${q['questionText']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Arabic question
                        Text(
                          q["questionTextAr"] ?? "",
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const Divider(height: 20),

                        // Answers
                        ...answers.map((ans) {
                          final answerId = ans["answerId"];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RadioListTile<int>(
                                title: Text(ans["answerText"]),
                                value: answerId,
                                groupValue: state.selectedAnswers[questionId],
                                onChanged: (val) {
                                  if (val != null) {
                                    context.read<ExamCubit>().selectAnswer(questionId, val);
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 50, bottom: 8),
                                child: Text(
                                  ans["answerTextAr"] ?? "",
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                              ),
                            ],
                          );
                        }),

                        const Spacer(),

                        // Submit Button
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              final state = context.read<AuthCubit>().state;
                              final isGuest = state is AuthGuest;

                              if (isGuest) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Register to access this feature"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx); // close dialog
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const SplashScreen()),
                                          );
                                        },
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                // TODO: Send JSON request here
                                // Example:
                                // await context.read<ExamCubit>().submitAnswer(questionId);

                                // Go to next question
                                if (index < questions.length - 1) {
                                  PageController().jumpToPage(index + 1);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("You have completed this unit!")),
                                  );
                                }
                              }
                            },
                            child: const Text("Submit"),
                          ),

                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
