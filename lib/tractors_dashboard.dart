import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/exam_cubit.dart';
import 'first_screen.dart';
import 'blocs/auth_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';


final FlutterTts flutterTts = FlutterTts();

Future<void> _speak(String text, {String langCode = "en-US"}) async {
  try {
    await flutterTts.setLanguage(langCode);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  } catch (e) {
    debugPrint("TTS Error: $e");
  }
}


void _showTtsDialog(BuildContext context, Map<String, dynamic> q) {
  final answers = q["answers"] as List<dynamic>;

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Read Aloud"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => _speak("Question: ${q['questionText']}"),
              child: const Text("Q"),
            ),
            ...answers.asMap().entries.map((entry) {
              final idx = entry.key + 1; // 1,2,3...
              final ans = entry.value;
              return ElevatedButton(
                onPressed: () => _speak("Answer $idx: ${ans['answerText']}"),
                child: Text(idx.toString()),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}

class TractorsDashboard extends StatelessWidget {
  const TractorsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tractors and Trailers"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Questions Bank"),
              Tab(text: "Exams"),
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
                      _showAnswer = false;
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

                                            // English answers
                                            ...answers.map((ans) {
                                              final answerId = ans["answerId"];
                                              final isCorrect = answerId == questionId;
                                              final isSelected = selected == answerId;

                                              return Container(
                                                margin: const EdgeInsets.symmetric(vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _showAnswer && isCorrect
                                                      ? Colors.green.withOpacity(0.8)
                                                      : null,
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                                child: RadioListTile<int>(
                                                  title: Text(
                                                    ans["answerText"],
                                                    style: TextStyle(
                                                      color: _showAnswer && isCorrect
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  value: answerId,
                                                  groupValue: selected,
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      context.read<ExamCubit>().selectAnswer(
                                                        questionId,
                                                        val,
                                                      );
                                                    }
                                                  },
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // TTS Button (English)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: SvgPicture.asset(
                                          "assets/icons/tts.svg",
                                          width: 32,
                                          height: 32,
                                        ),
                                        onPressed: () {
                                          // Snackbar before TTS
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

                                          // Build English text
                                          final enText =
                                              "Q${index + 1}: ${q['questionText']}. ${answers.asMap().entries.map((e) {
                                            return "${e.key + 1}. ${e.value['answerText']}";
                                          }).join(", ")}";

                                          _speak(enText, langCode: "en-US");
                                        },
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: 4,
                            color:Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                q["questionTextAr"] ?? "",
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: [
                                const Divider(height: 20),
                                ...answers.map((ans) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        ans["answerTextAr"] ?? "",
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(fontSize: 14, color: Colors.black54),
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
                                    onPressed: () {
                                      // Show Awesome Snackbar
                                      final snackBar = SnackBar(
                                        elevation: 0,
                                        backgroundColor: Colors.transparent,
                                        behavior: SnackBarBehavior.floating,
                                        content: AwesomeSnackbarContent(
                                          title: 'Text-to-Speech',
                                          message: 'Commencing text to speech...',
                                          contentType: ContentType.help, // you can use success/warning/failure too
                                        ),
                                      );

                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(snackBar);

                                      // Construct text and call TTS
                                      final arText =
                                          "${q['questionTextAr']}. ${answers.asMap().entries.map((e) {
                                        return "${e.key + 1}. ${e.value['answerTextAr']}";
                                      }).join("، ")}";
                                      _speak(arText, langCode: "ar-SA");
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // =====================
                        // Show Answer Button
                        // =====================
                        Padding(
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
                              onPressed: () {
                                setState(() {
                                  _showAnswer = true;
                                });
                              },
                              child:  Text(
                                "Show Answer",
                                style: GoogleFonts.robotoSlab(  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // =====================
              // Navigation
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
              ),
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
