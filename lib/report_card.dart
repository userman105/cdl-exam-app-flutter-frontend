import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ReportCard extends StatefulWidget {
  final int correctAnswers;
  final int wrongAnswers;
  final Duration timeElapsed;
  final double percentage;

  const ReportCard({
    super.key,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timeElapsed,
    required this.percentage,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.percentage >= 60; // Passing threshold
    final bgColor = Colors.white;
    final statusText = passed ? "PASSED" : "FAILED";
    final statusColor = passed ? Colors.green[700] : Colors.red[700];

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Exam Report",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRow("Correct Answers", widget.correctAnswers.toString()),
                    const SizedBox(height: 8),
                    _buildRow("Wrong Answers", widget.wrongAnswers.toString()),
                    const SizedBox(height: 8),
                    _buildRow("Time Elapsed", _formatDuration(widget.timeElapsed)),
                    const SizedBox(height: 8),
                    _buildRow(
                        "Percentage", "${widget.percentage.toStringAsFixed(1)}%"),
                    const SizedBox(height: 20),
                    Text(
                      statusText,
                      style: GoogleFonts.robotoSlab(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 120,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B2EF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "OK",
                          style: GoogleFonts.robotoSlab(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.robotoSlab(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.robotoSlab(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
