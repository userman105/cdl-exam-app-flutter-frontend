import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(
      String text,
      BuildContext context, {
        String langCode = "en-US",
      }) async {
    try {
      await _tts.setLanguage(langCode);
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
      if (context.mounted) {
        showSnackBar(context, 'TTS Error', 'Unable to play text-to-speech.', ContentType.failure);
      }
    }
  }

  static Future<void> stop() => _tts.stop();

  static void showSnackBar(BuildContext context, String title, String message, ContentType type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: type,
        ),
      ),
    );
  }
}
