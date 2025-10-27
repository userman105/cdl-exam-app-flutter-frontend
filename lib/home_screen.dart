import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/exam_cubit.dart';
import 'tractors_dashboard.dart';
import 'first_screen.dart';
import 'profile_edit.dart';
import 'airbrakes_dashboard.dart';
import 'general_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showSpinner(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;

    if (authState is AuthGuest) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
      );
      return false;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Do you really want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      context.read<AuthCubit>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
      );
      return false;
    }

    return false;
  }


  Future<void> _loadExamAndNavigate({
    required BuildContext context,
    required int examId,
    required Widget Function() destinationBuilder,
  }) async {
    final examCubit = context.read<ExamCubit>();

    unawaited(_showSpinner(context));

    try {
      unawaited(examCubit.loadExam(context, examId));

      final state = await examCubit.stream
          .firstWhere((s) => s is ExamLoaded || s is ExamError)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => ExamError("Exam loading timed out. Please try again."),
      );

      if (context.mounted) Navigator.of(context).pop();

      if (state is ExamLoaded) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destinationBuilder()),
        );
      } else if (state is ExamError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load exam: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background photo with fade
            SizedBox(
              height: size.height * 0.30,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    "assets/images/pngwing.png",
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile button
            Positioned(
              top: 40,
              right: 20,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const ProfileEdit(),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset("assets/icons/profile.svg"),
                ),
              ),
            ),

            // Buttons
            Align(
              alignment: const FractionalOffset(0.5, 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildButton(
                    label: "General information",
                    iconPath: "assets/icons/general.svg",
                    onTap: () => _loadExamAndNavigate(
                      context: context,
                      examId: 3,
                      destinationBuilder: () =>
                          GeneralKnowledgeDashboard(initialTabIndex: 1),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildButton(
                    label: "Air brakes",
                    iconPath: "assets/icons/air_brakes.svg",
                    onTap: () => _loadExamAndNavigate(
                      context: context,
                      examId: 2,
                      destinationBuilder: () =>
                          AirbrakesDashboard(initialTabIndex: 1),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildButton(
                    label: "Tractors and trailers",
                    iconPath: "assets/icons/tractors_and_trailers.svg",
                    onTap: () => _loadExamAndNavigate(
                      context: context,
                      examId: 1,
                      destinationBuilder: () =>
                          TractorsDashboard(initialTabIndex: 1),
                    ),
                  ),
                  const SizedBox(height: 200),

                  // Guest register prompt
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthGuest) {
                        return OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SplashScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side:
                            const BorderSide(color: Colors.blue, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 15,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/exclamation_blue.svg",
                                height: 22,
                                width: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Register now and enjoy all features',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF003087),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(iconPath, height: 50, width: 50),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
