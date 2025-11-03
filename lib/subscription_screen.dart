import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arabic_font/arabic_font.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPlan = 'monthly';

  Widget _buildPlanButton(String planType, String whiteIcon, String highlightedIcon) {
    final bool isSelected = selectedPlan == planType;

    return GestureDetector(
      onTap: () => setState(() => selectedPlan = planType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Image.asset(
          isSelected ? highlightedIcon : whiteIcon,
          height: 80,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "عروض الشراء",
                        style: ArabicTextStyle(
                          arabicFont: ArabicFont.dubai,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "مميزات كل عرض",
                        style: ArabicTextStyle(
                          arabicFont: ArabicFont.dubai,
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 🔘 Plan Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPlanButton(
                  'weekly',
                  'assets/icons/weekly_white.png',
                  'assets/icons/weekly_highlighted.png',
                ),
                _buildPlanButton(
                  'monthly',
                  'assets/icons/monthly_white.png',
                  'assets/icons/monthly_highlighted.png',
                ),
                _buildPlanButton(
                  'yearly',
                  'assets/icons/yearly_white.png',
                  'assets/icons/yearly_highlighted.png',
                ),
              ],
            ),

            const SizedBox(height: 50),

            // ✅ Subscription Benefits
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _feature("Full access to the question banks tab"),
                _feature("Previous mistakes access"),
                _feature("Unlimited exam trials"),
              ],
            ),

            const Spacer(),

            // 🟦 Confirm Purchase Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3298CB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // TODO: Trigger Google IAP here
                  debugPrint('Buying $selectedPlan plan...');
                },
                child: Text(
                  "Confirm Purchase",
                  style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.robotoSlab(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
