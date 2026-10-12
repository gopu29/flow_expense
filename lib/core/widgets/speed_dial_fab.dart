import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Floating Action Button on the bottom-right.
/// - Regular tap: opens quick transaction numpad.
/// - Hold / long-press: reveals Voice AI Logger and Receipt Scanner buttons
///   with smooth spring micro-animations.
class SpeedDialFab extends StatefulWidget {
  final VoidCallback onQuickAdd;
  final VoidCallback onVoiceLog;
  final VoidCallback onScanReceipt;

  const SpeedDialFab({
    super.key,
    required this.onQuickAdd,
    required this.onVoiceLog,
    required this.onScanReceipt,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  void _handleTap() {
    if (_isOpen) {
      _close();
    } else {
      widget.onQuickAdd();
    }
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Revealing Action 1: AI Receipt Scanner
        _buildActionItem(
          label: 'Scan Receipt',
          icon: Icons.document_scanner_rounded,
          accentGradient: const [Color(0xFF10B981), Color(0xFF059669)],
          onPressed: () {
            _close();
            widget.onScanReceipt();
          },
          delayFactor: 0.6,
        ),
        const SizedBox(height: 12),

        // Revealing Action 2: Voice AI Logger
        _buildActionItem(
          label: 'Voice AI Logger',
          icon: Icons.mic_rounded,
          accentGradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          onPressed: () {
            _close();
            widget.onVoiceLog();
          },
          delayFactor: 0.3,
        ),
        const SizedBox(height: 12),

        // Primary Floating Button
        GestureDetector(
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentHover],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String label,
    required IconData icon,
    required List<Color> accentGradient,
    required VoidCallback onPressed,
    required double delayFactor,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        if (progress == 0.0) return const SizedBox.shrink();

        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.7 + (0.3 * progress),
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text Label badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surfaceBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Action mini-FAB
                GestureDetector(
                  onTap: onPressed,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentGradient.first.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
