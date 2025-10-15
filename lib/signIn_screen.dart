import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cdl_flutter/first_screen.dart';
import 'package:cdl_flutter/home_screen.dart';
import 'package:cdl_flutter/verify_otp_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../blocs/auth_cubit.dart';
import 'password_recovery.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isEmailValid = true;

  /// Email validation
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  /// Google Sign-In (unchanged)
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();

      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return;

      final response = await http.post(
        Uri.parse("http://10.0.2.2:3333/auth/google/callback"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_token": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final username = data["user"]["userName"] ?? "User";
        final token = data["token"]["token"];

        context.read<AuthCubit>().googleLogin(username, token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google login failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Email/password login
  void _loginWithBackend(BuildContext context) {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!_validateEmail(email)) {
      setState(() => _isEmailValid = false);
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    context.read<AuthCubit>().login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoginEnabled =
        _validateEmail(emailController.text.trim()) &&
            passwordController.text.isNotEmpty;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            const storage = FlutterSecureStorage();
            if (_rememberMe) {
              await storage.write(key: "auth_token", value: state.token);
              await storage.write(key: "username", value: state.username);
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthNeedsVerification) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyOtpScreen(
                    email: state.email,
                    password: state.password,
                  ),
                ),
              );
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),

              Center(
                child: Image.asset(
                  "assets/icons/cdl_blue.png",
                  height: 175,
                  width: 175,
                ),
              ),

              Center(
                child: Text(
                  "Log into your account",
                  style: GoogleFonts.robotoSlab(
                      fontSize: 26, fontWeight: FontWeight.w200),
                ),
              ),
              Center(
                child: Text(
                  "Welcome please enter your details",
                  style: GoogleFonts.robotoSlab(
                      fontSize: 20, fontWeight: FontWeight.w100),
                ),
              ),
              const SizedBox(height: 30),

              // Google Sign-In button
              Center(
                child: IconButton(
                  onPressed: () => _signInWithGoogle(context),
                  icon: Image.asset(
                    "assets/icons/google_icon.png",
                    height: 70,
                    width: 70,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Email field
              TextField(
                controller: emailController,
                onChanged: (val) {
                  setState(() {
                    _isEmailValid = _validateEmail(val.trim());
                  });
                },
                decoration: InputDecoration(
                  labelText: "Email",
                  errorText: _isEmailValid ? null : "Invalid email",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Password field
              TextField(
                controller: passwordController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 12),

              // Remember Me
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? false;
                      });
                    },
                  ),
                  Text(
                    "Remember me",
                    style: GoogleFonts.robotoSlab(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Login button
              ElevatedButton(
                onPressed:
                isLoginEnabled ? () => _loginWithBackend(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3298CB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "Login",
                  style: GoogleFonts.robotoSlab(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Sign up + Forgot password stacked center
              Column(
                children: [
                  RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign up",
                          style: GoogleFonts.robotoSlab(
                            fontSize: 14,
                            color: const Color(0xFF3298CB),
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SplashScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecoverPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot password?",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 14,
                        color: const Color(0xFF3298CB),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
