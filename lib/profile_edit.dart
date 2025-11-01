import 'dart:convert';
import 'dart:io';
import 'package:cdl_flutter/first_screen.dart';
import 'package:cdl_flutter/signIn_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'blocs/auth_cubit.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'saved_reports.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      context.read<AuthCubit>().updateProfilePhoto(pickedFile.path);
    }
  }

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
            // ListTile(
            //   leading: const Icon(Icons.lock),
            //   title: const Text("Update Password"),
            //   onTap: () {
            //     Navigator.pop(context);
            //     // step 1: ask for old password
            //     _showTextInputDialog(
            //       context,
            //       "Enter old password",
            //           (oldPass) async {
            //         // step 2: ask for new password
            //         _showTextInputDialog(
            //           context,
            //           "Enter new password",
            //               (newPass) async {
            //             await context.read<AuthCubit>().updateProfile(
            //               oldPassword: oldPass,
            //               newPassword: newPass,
            //             );
            //           },
            //         );
            //       },
            //     );
            //   },
            // ),

          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    final bool isGuest = authState is AuthGuest;
    final String? profilePath =
    !isGuest && authState is AuthAuthenticated ? authState.profilePath : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [

            Positioned(
              top: 146,
              left: 25, // moved to the left
              child: InkWell(
                onTap: () {
                  if (!isGuest) {
                    _pickImage(context);
                  }
                },
                borderRadius: BorderRadius.circular(40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/icons/hex.svg",
                          width: 130,
                          height: 130,
                        ),
                        CircleAvatar(
                          radius: 36,
                          backgroundImage:
                          profilePath != null ? FileImage(File(profilePath)) : null,
                          child: profilePath == null
                              ? SvgPicture.asset(
                            "assets/icons/profile.svg",
                            width: 80,
                            height: 80,
                          )
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(width: 16), // spacing between avatar and text

                    // Text separate
                    Text(
                      isGuest ? "Welcome Guest!" : "Welcome Back!",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            )
            ,

            // Options in center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOption(
                    label: "Profile",
                    iconPath: "assets/icons/profile.svg",
                    onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_)=>ReportHistoryScreen()));
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildOption(
                    label: "More Settings",
                    iconPath: "assets/icons/gear.svg",
                      onTap: () {
                        if (authState is AuthAuthenticated) {
                          _openSettingsDrawer(context);
                        } else if (authState is AuthGuest) {
                          _showErrorSnack(context, "this option is not available in guest mode");
                        } else {
                          // If it's AuthError or AuthLoading but we *were* authenticated,
                          // don’t block user. Just open drawer.
                          if (authState is! AuthInitial) {
                            _openSettingsDrawer(context);
                          } else {
                            _showErrorSnack(context, "error");
                          }
                        }
                      },

                  ),
                  const SizedBox(height: 24),
                  _buildOption(
                    label: "Logout",
                    iconPath: "assets/icons/logout.svg",
                    labelColor: Colors.red,
                    onTap: () async {
                      print("AuthState: $authState");

                      final authCubit = context.read<AuthCubit>();
                      final state = authCubit.state;

                      if (state is AuthGuest) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                        );
                      } else if (state is AuthAuthenticated) {
                        await authCubit.logout();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Save button at bottom
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
            ),
          ],
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
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
  Future<String?> _showJsonInputDialog(BuildContext context, String hint) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter JSON"),
          content: TextField(
            controller: controller,
            maxLines: 6,
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
              onPressed: () => Navigator.pop(context, controller.text),
            ),
          ],
        );
      },
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
