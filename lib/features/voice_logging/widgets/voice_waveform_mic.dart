import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Animated glowing microphone and audio waveform bars widget.
class VoiceWaveformMic extends StatefulWidget {
  final bool isListening;
  final VoidCallback onToggle;

  const VoiceWaveformMic({
    super.key,
    required this.isListening,
    required this.onToggle,
  });

  @override
  State<VoiceWaveformMic> createState() => _VoiceWaveformMicState();
}

class _VoiceWaveformMicState extends State<VoiceWaveformMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform bars
        if (widget.isListening) ...[
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(16, (index) {
                    final factor = sin((index / 16) * pi + (_animController.value * pi));
                    final height = (factor * 32).abs().clamp(6.0, 42.0);

                    return Container(
                      width: 4,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.4 + (factor.abs() * 0.6)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 20),

        // Glowing Pulsing Mic Button
        GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final scale = widget.isListening
                  ? 1.0 + (_animController.value * 0.08)
                  : 1.0;
              final glowAlpha = widget.isListening
                  ? 0.3 + (_animController.value * 0.4)
                  : 0.15;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isListening
                          ? [AppColors.expense, AppColors.chartOrange]
                          : [AppColors.accent, AppColors.accentHover],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isListening ? AppColors.expense : AppColors.accent)
                            .withValues(alpha: glowAlpha),
                        blurRadius: widget.isListening ? 28 : 16,
                        spreadRadius: widget.isListening ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
