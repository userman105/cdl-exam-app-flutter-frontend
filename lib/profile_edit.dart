import 'dart:io';
import 'package:cdl_flutter/first_screen.dart';
import 'package:cdl_flutter/signIn_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'saved_reports.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/exam_cubit.dart';
import 'subscription_screen.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  void _openSettingsDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Update Username"),
              onTap: () {
                Navigator.pop(context);
                _showTextInputDialog(
                  context,
                  "Enter new username",
                      (newName) async {
                    await context.read<AuthCubit>().updateProfile(userName: newName);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Update Mobile Number"),
              onTap: () {
                Navigator.pop(context);
                _showTextInputDialog(
                  context,
                  "Enter new mobile number",
                      (newMobile) async {
                    await context.read<AuthCubit>().updateProfile(mobileNumber: newMobile);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final bool isGuest = authState is AuthGuest;
    final String? photoUrl =
    !isGuest && authState is AuthAuthenticated ? authState.photoUrl : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Profile header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/hex.svg",
                        width: 120,
                        height: 120,
                      ),
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? SvgPicture.asset(
                          "assets/icons/profile.svg",
                          width: 70,
                          height: 70,
                        )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuest
                              ? "Welcome Guest!"
                              : "Welcome back, ${(authState as AuthAuthenticated).username}!",
                          style: GoogleFonts.robotoSlab(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (!isGuest)
                          Text(
                            "Glad to see you again",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Options buttons
              _buildOption(
                label: "Profile",
                iconPath: "assets/icons/profile.svg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              _buildOption(
                label: "More Settings",
                iconPath: "assets/icons/gear.svg",
                onTap: () {
                  if (authState is AuthAuthenticated) {
                    _openSettingsDrawer(context);
                  } else if (authState is AuthGuest) {
                    _showErrorSnack(context, "This option is not available in guest mode");
                  } else {
                    _showErrorSnack(context, "Error");
                  }
                },
              ),
              const SizedBox(height: 28),
              _buildOption(
                label: "Clear Past Exams",
                iconPath: "assets/icons/gear.svg",
                labelColor: Colors.redAccent,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      title: const Text("Confirm Reset"),
                      content: const Text(
                          "Are you sure you want to clear all saved exams and mistakes?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await context.read<ExamCubit>().clearAllSavedExams(context);
                  }
                },
              ),
              const SizedBox(height: 28),
              _buildOption(
                label: "Logout",
                iconPath: "assets/icons/logout.svg",
                labelColor: Colors.red,
                onTap: () async {
                  final authCubit = context.read<AuthCubit>();
                  final state = authCubit.state;
                  if (state is AuthGuest) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                    );
                  } else if (state is AuthAuthenticated) {
                    await authCubit.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                    );
                  }
                },
              ),

              const Spacer(),

// ✅ Current Plan section
              if (authState is AuthAuthenticated) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Current Plan: ",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      authState.subscribed == true ? "Premium" : "Basic",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: authState.subscribed == true
                            ? const Color(0xFF3298CB)
                            : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (authState.subscribed == false)
                      GestureDetector(
                        onTap: () {
                          // ✅ Navigate to your Google IAP screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen(), // <- replace with your screen
                            ),
                          );
                        },
                        child: Text(
                          "Upgrade",
                          style: GoogleFonts.robotoSlab(
                            fontSize: 16,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3298CB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "OK",
                    style: GoogleFonts.robotoSlab(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required String iconPath,
    required VoidCallback onTap,
    Color labelColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.robotoSlab(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: AwesomeSnackbarContent(
        title: "Error",
        message: message,
        contentType: ContentType.failure,
        color: Colors.red,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _showTextInputDialog(
      BuildContext context,
      String hint,
      Future<void> Function(String) onSubmit,
      ) async {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hint),
          content: TextField(
            controller: controller,
            obscureText: hint.toLowerCase().contains("password"),
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  await onSubmit(text);
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
