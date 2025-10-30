import 'package:cdl_flutter/verify_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'blocs/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailValid = true;

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: BlocListener is placed INSIDE the Scaffold body so the listener's context can find a ScaffoldMessenger.
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            // debug print so you can verify listener is triggered
            debugPrint('Auth state changed in RegisterScreen listener: $state');

            if (state is AuthNeedsVerification) {
              // navigate to OTP screen (use push)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyOtpScreen(
                    email: state.email,
                    password: state.password,
                  ),
                ),
              );
            } else if (state is AuthAuthenticated) {
              // show welcome message
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text("this email is already registered"),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
            } else if (state is AuthError) {
              // show a styled floating snack bar for errors
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 3),
                  ),
                );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/icons/cdl_blue.png",
                  height: 180,
                  width: 180,
                ),
                const SizedBox(height: 16),
                Text(
                  "Create an Account",
                  style: GoogleFonts.robotoSlab(
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Sign up now and get started with an account',
                  style: GoogleFonts.robotoSlab(
                    fontSize: 16,
                    fontWeight: FontWeight.w100,
                  ),
                ),

                // --- Google sign-in button ---
                const SizedBox(height: 12),
                Center(
                  child: IconButton(
                    icon: Image.asset(
                      "assets/icons/google_icon.png",
                      height: 70,
                      width: 70,
                    ),
                    onPressed: () {
                      // Call registerWithGoogle in cubit
                      final authCubit = context.read<AuthCubit>();
                      authCubit.registerWithGoogle();
                    },
                  ),
                ),
                const SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First + Last Name side by side
                      Row(
                        children: [
                          Expanded(
                            child: _buildLabeledField(
                              label: "First Name",
                              controller: firstNameController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLabeledField(
                              label: "Last Name",
                              controller: lastNameController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email Field with hint + validation
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, right: 8),
                            child: Text(
                              "Email",
                              style: GoogleFonts.robotoSlab(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "Cannot be changed later",
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                const BorderSide(color: Color(0xFF3298CB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _isEmailValid
                                        ? const Color(0xFF3298CB)
                                        : Colors.red),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _isEmailValid
                                      ? const Color(0xFF3298CB)
                                      : Colors.red,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isEmailValid = _validateEmail(value);
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email cannot be empty";
                              }
                              if (!_validateEmail(value)) {
                                return "Enter a valid email address";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildLabeledField(
                        label: "Password",
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabeledField(
                        label: "Confirm Password",
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3298CB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final authCubit = context.read<AuthCubit>();

                        // Combine first + last name into userName
                        final combinedUserName =
                            "${firstNameController.text.trim()} ${lastNameController.text.trim()}";

                        final result = await authCubit.registerUser(
                          fName: firstNameController.text.trim(),
                          lName: lastNameController.text.trim(),
                          userName: combinedUserName,
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          mobileNumber: "",
                        );

                        if (result["success"] == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerifyOtpScreen(
                                email: emailController.text.trim(),
                                password: passwordController.text,
                              ),
                            ),
                          );
                        } else {
                          debugPrint("Registration failed result: $result");
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(result["error"] ?? "Registration failed"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        }
                      }
                    },
                    child: Text(
                      "Next",
                      style: GoogleFonts.robotoSlab(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, right: 8),
          child: Text(
            label,
            style: GoogleFonts.robotoSlab(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3298CB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3298CB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF3298CB), width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "$label cannot be empty";
            }
            if (label == "Confirm Password" && value != passwordController.text) {
              return "Passwords do not match";
            }
            return null;
          },
        ),
      ],
    );
  }
}
