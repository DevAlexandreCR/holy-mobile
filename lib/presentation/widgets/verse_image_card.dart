import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget that renders a verse in a shareable image format.
/// This widget is designed to be captured as an image and shared.
class VerseImageCard extends StatelessWidget {
  const VerseImageCard({required this.verse, super.key});

  final VerseOfTheDay verse;

  /// Calculate dynamic font size based on text length
  double _calculateFontSize() {
    final textLength = verse.text.length;
    if (textLength < 50) return 30.0;
    if (textLength < 100) return 26.0;
    if (textLength < 150) return 22.0;
    if (textLength < 200) return 20.0;
    if (textLength < 250) return 18.0;
    if (textLength < 300) return 16.0;
    return 15.0;
  }

  double _calculateReferenceFontSize() {
    final fontSize = _calculateFontSize();
    return fontSize * 0.85; // Reference is 85% of verse font size
  }

  @override
  Widget build(BuildContext context) {
    final verseFontSize = _calculateFontSize();
    final referenceFontSize = _calculateReferenceFontSize();

    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.midnightFaithDark,
            AppColors.midnightFaith,
            AppColors.midnightFaith.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.holyGold.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.holyGold.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content with card - 3/4 of height (1440px)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40, // Padding mínimo
                vertical: 240, // (1920 - 1440) / 2 = 240 para centrar
              ),
              child: Container(
                height: 1440, // Exactamente 3/4 de 1920
                width: 1000, // Ancho máximo con padding mínimo
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.midnightFaith.withValues(alpha: 0.4),
                      AppColors.midnightFaithDark.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.pureWhite.withValues(alpha: 0.1),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date at top (if exists)
                    if (verse.date.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          verse.date,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.softMist.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Verse text - centered section
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '"${verse.text}"',
                                style: GoogleFonts.inter(
                                  fontSize: verseFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pureWhite,
                                  height: 1.4,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: verseFontSize * 0.8),
                              // Reference
                              Text(
                                verse.reference,
                                style: GoogleFonts.inter(
                                  fontSize: referenceFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.holyGold,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.holyGold.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // HolyVerso logo floating outside card - bottom right
          Positioned(
            bottom: 220, // Just below the card
            right: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.midnightFaith.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.pureWhite.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.holyGold,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'HolyVerso',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
