import 'dart:ui';
import 'package:flutter/material.dart';

/// Frosted insights teaser card matching Quanto IMG_6030.PNG & IMG_6031.PNG.
class InsightsTeaserCard extends StatelessWidget {
  final String buttonText;
  final String title;
  final String description;
  final bool showBarGraphic;

  const InsightsTeaserCard({
    super.key,
    required this.buttonText,
    required this.title,
    required this.description,
    this.showBarGraphic = false,
  });

  void _showUnlockSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF2DD4BF),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      decoration: BoxDecoration(
        color: const Color(0xFF131D26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1F2E3E),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred atmospheric backdrop matching IMG_6031.PNG
          Positioned.fill(
            child: showBarGraphic
                ? _buildBlurredBarsBackground()
                : _buildBlurredGlowBackground(),
          ),

          // Frosted glass overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: const Color(0xFF0F1A24).withValues(alpha: 0.35),
              ),
            ),
          ),

          // Centered Lock Icon & Pill Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => _showUnlockSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2DD4BF), // Light Teal
                        Color(0xFF0D9488), // Deep Teal
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredGlowBackground() {
    return Stack(
      children: [
        Positioned(
          top: 30,
          left: 50,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurredBarsBackground() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(6, (index) {
          final heights = [100.0, 150.0, 130.0, 170.0, 140.0, 160.0];
          return Container(
            width: 28,
            height: heights[index % heights.length],
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                  const Color(0xFF0D9488).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
          );
        }),
      ),
    );
  }
}
