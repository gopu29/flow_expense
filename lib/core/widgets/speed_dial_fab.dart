import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating Action Button on the bottom-right matching Quanto (IMG_6026.PNG).
/// - Prominent off-white '+' button with dark icon.
/// - Floating Voice AI Logger & Receipt Scanner buttons.
/// - Tap '+' to log instantly, hold/toggle to reveal secondary action buttons.
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
  bool _isOpen = true; // Revealed by default matching IMG_6026.PNG!

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0, // Open initially matching IMG_6026.PNG
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Voice AI Logger Button (Dark circle matching IMG_6026.PNG)
        ScaleTransition(
          scale: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onVoiceLog();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2834),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2B3D4E),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFFE2E8F0),
                  size: 21,
                ),
              ),
            ),
          ),
        ),

        // AI Receipt Scanner Button (Dark circle matching IMG_6026.PNG)
        ScaleTransition(
          scale: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onScanReceipt();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2834),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2B3D4E),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.crop_free_rounded,
                  color: Color(0xFFE2E8F0),
                  size: 21,
                ),
              ),
            ),
          ),
        ),

        // Primary '+' Floating Button (Off-white circle matching IMG_6026.PNG)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onQuickAdd();
          },
          onLongPress: _toggle,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EDF5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF0D1620),
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}
