import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordResetConfirmationScreen extends StatelessWidget {
  const PasswordResetConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Top splash background image
            Center(
              child: Image.asset(
                "assets/images/password_reset_spalsh.png",
                width: MediaQuery.of(context).size.width * 1.7,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 2),

            // Foreground success image
            Center(
              child: Image.asset(
                "assets/images/password_resets_ok.png",
                width: MediaQuery.of(context).size.width * 0.4,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),

            // Success text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Your password has been changed successfully.",
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoSlab(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Button to go back to first screen (e.g. Login)
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3298CB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                "Go to Login",
                style: GoogleFonts.robotoSlab(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
