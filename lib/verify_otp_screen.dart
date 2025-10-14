import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'blocs/auth_cubit.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String password;

  const VerifyOtpScreen({super.key, required this.email, required this.password});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final otpController = TextEditingController();
  late String currentEmail;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    currentEmail = widget.email;
    _sendOtp(); // send automatically on entry
  }


  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _sendOtp() async {
    final authCubit = context.read<AuthCubit>();
    final messenger = ScaffoldMessenger.of(context);


    _startTimer();

    final result = await authCubit.requestOtp(newEmail: currentEmail, oldEmail: '');
    if (!mounted) return;

    if (result["success"] == true) {
      messenger.showSnackBar(
        SnackBar(content: Text("OTP sent to $currentEmail")),
      );

    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result["error"] ?? "Failed to send OTP")),
      );

      _timer?.cancel();
      setState(() => _canResend = true);
    }
  }


  Future<void> _changeEmail() async {
    final newEmailController = TextEditingController();

    final newEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Email"),
        content: TextField(
          controller: newEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: "Enter new email"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, newEmailController.text.trim()),
            child: const Text("Update"),
          ),
        ],
      ),
    );

    if (newEmail != null && newEmail.isNotEmpty) {
      final authCubit = context.read<AuthCubit>();
      final result = await authCubit.updateEmail(
        oldEmail: currentEmail,
        newEmail: newEmail,
      );

      if (result["success"] == true) {
        setState(() => currentEmail = newEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email updated. Sending new OTP...")),
        );

        //
        await _sendOtp();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["error"] ?? "Failed to update email")),
        );
      }
    }
  }



  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/icons/cdl_blue.png", height: 180, width: 180),
              const SizedBox(height: 16),

              Text(
                "Verify Your Email",
                style: GoogleFonts.robotoSlab(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                ),
              ),
              Text(
                "Enter the OTP sent to $currentEmail",
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoSlab(
                  fontSize: 16,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Enter OTP",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3298CB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFF3298CB), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Resend Code Button
                  TextButton(
                    onPressed: _canResend ? _sendOtp : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _canResend ? const Color(0xFF3298CB) : Colors.grey,
                    ),
                    child: Text(
                      _canResend
                          ? "Resend Code"
                          : "Resend in $_secondsRemaining s",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),


                  TextButton(
                    onPressed: _changeEmail,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3298CB),
                    ),
                    child: Text(
                      "Change Email",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
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
                    final authCubit = context.read<AuthCubit>();
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);

                    final result = await authCubit.verifyEmail(
                      email: currentEmail,
                      otp: otpController.text,
                    );

                    if (!mounted) return;

                    if (result["success"] == true) {
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text("Email verified! Logging you in...")),
                      );

                      await authCubit.login(currentEmail, widget.password);
                      if (!mounted) return;

                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(result["error"] ??
                              "Invalid OTP, please try again"),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Verify",
                    style: GoogleFonts.robotoSlab(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
