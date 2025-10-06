import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/exam_cubit.dart';
import 'first_screen.dart';
import 'blocs/auth_cubit.dart';
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
class _QuestionsBankTab extends StatelessWidget {
  const _QuestionsBankTab();

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

          return PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final answers = q["answers"] as List<dynamic>;
              final questionId = q["questionId"];

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        // English question
                        Text(
                          "Q${index + 1}: ${q['questionText']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Arabic question
                        Text(
                          q["questionTextAr"] ?? "",
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const Divider(height: 24),

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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
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
