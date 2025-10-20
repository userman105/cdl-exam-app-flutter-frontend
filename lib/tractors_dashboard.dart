import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/exam_cubit.dart';
import 'first_screen.dart';
import 'blocs/auth_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final FlutterTts flutterTts = FlutterTts();


Future<void> speak(
    String text,
    BuildContext context, {
      String langCode = "en-US",
    }) async {
  try {
    // Check connectivity first
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      // Show awesome snackbar for no internet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            title: 'No Internet!',
            message: 'Text-to-Speech requires an internet connection.',
            contentType: ContentType.failure,
          ),
        ),
      );
      return;
    }

    await flutterTts.setLanguage(langCode);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  } catch (e) {
    debugPrint("TTS Error: $e");
  }
}


class TractorsDashboard extends StatefulWidget {
  const TractorsDashboard({super.key});

  @override
  State<TractorsDashboard> createState() => _TractorsDashboardState();
}

class _TractorsDashboardState extends State<TractorsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Refresh when tab changes
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {return Scaffold(
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
            "assets/icons/subscription.png", // replace with your image
            width: 130,
            height: 130,
          ),
          onPressed: () {
            // TODO: Implement image button functionality
          },
        ),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            color: Colors.black12,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.9),
                blurRadius: 8,
                offset: const Offset(0, 7),
              ),
            ],
          ),
        ),
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

                // Questions Bank button + underline
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _tabController.animateTo(0),
                      child: Text(
                        "Questions Bank",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_tabController.index == 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        height: 3,
                        width: 80,
                        color: Colors.black,
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Exams button + underline
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: Text(
                        "Exams",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_tabController.index == 1)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        height: 3,
                        width: 50,
                        color: Colors.black,
                      ),
                  ],
                ),
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
  void dispose() {
    flutterTts.stop();
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
                                              final _ = selected == answerId;

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

                                          speak(enText,context, langCode: "en-US");
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
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: const Text(
                                "Show Arabic Translation",  // 👈 fixed title
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
                                          contentType: ContentType.help,
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

                                      speak(arText, context, langCode: "ar-SA");
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

  Widget _buildUnitButton(
      BuildContext context, String title, List<dynamic> questions) {
    final questionCount = questions.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    UnitQuestionsScreen(title: title, questions: questions),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + title + chevron
                Row(
                  children: [
                    Image.asset(
                      "assets/icons/unit_button_icon.png",
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF878C9F), // greyish color
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom row: no. of questions + progress bar
                Row(
                  children: [
                    Text(
                      "$questionCount Questions",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.0, // TODO: bind to actual progress
                          minHeight: 10,
                          backgroundColor: const Color(0xFFD9D9D9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
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

/// ----------------------
/// Unit Questions Screen
/// ----------------------
class UnitQuestionsScreen extends StatefulWidget {
  final String title;
  final List<dynamic> questions;

  const UnitQuestionsScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  State<UnitQuestionsScreen> createState() => _UnitQuestionsScreenState();
}

class _UnitQuestionsScreenState extends State<UnitQuestionsScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: BlocBuilder<ExamCubit, ExamState>(
        builder: (context, examState) {
          if (examState is! ExamLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = widget.questions;

          return PageView.builder(
            controller: _pageController,
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index] as Map<String, dynamic>;
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
                                groupValue: examState.selectedAnswers[questionId],
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
                              final authState = context.read<AuthCubit>().state;
                              final isGuest = authState is AuthGuest;

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
                                // await context.read<ExamCubit>().submitAnswer(questionId);

                                // Go to next question
                                if (index < questions.length - 1) {
                                  _pageController.jumpToPage(index + 1);
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
