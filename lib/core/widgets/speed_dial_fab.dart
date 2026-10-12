import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DragTargetAction { none, scan, voice }

/// Floating Action Button on the bottom-right matching Quanto (IMG_6026.PNG).
/// - Default: Only the '+' button is visible.
/// - Quick tap on '+': Opens Quick Input numpad modal.
/// - Hold on '+': Reveals Voice AI Logger and Receipt Scanner buttons.
/// - Hold & Drag / Swipe: User can drag their finger directly to the Audio or Scan button
///   and release to activate it with tactile haptic feedback.
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

  final GlobalKey _voiceKey = GlobalKey();
  final GlobalKey _scanKey = GlobalKey();

  bool _isOpen = false;
  bool _isHolding = false;
  DragTargetAction _hoveredAction = DragTargetAction.none;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
      value: 0.0, // Hidden by default! Only shows on hold/reveal
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openMenu() {
    if (!_isOpen) {
      HapticFeedback.mediumImpact();
      setState(() => _isOpen = true);
      _controller.forward();
    }
  }

  void _closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _hoveredAction = DragTargetAction.none;
      });
      _controller.reverse();
    }
  }

  DragTargetAction _checkHover(Offset globalPosition) {
    // Check Voice button hit area (with generous touch radius)
    final voiceBox = _voiceKey.currentContext?.findRenderObject() as RenderBox?;
    if (voiceBox != null && voiceBox.hasSize) {
      final local = voiceBox.globalToLocal(globalPosition);
      final rect = Rect.fromLTWH(
        -14,
        -14,
        voiceBox.size.width + 28,
        voiceBox.size.height + 28,
      );
      if (rect.contains(local)) return DragTargetAction.voice;
    }

    // Check Scan button hit area (with generous touch radius)
    final scanBox = _scanKey.currentContext?.findRenderObject() as RenderBox?;
    if (scanBox != null && scanBox.hasSize) {
      final local = scanBox.globalToLocal(globalPosition);
      final rect = Rect.fromLTWH(
        -14,
        -14,
        scanBox.size.width + 28,
        scanBox.size.height + 28,
      );
      if (rect.contains(local)) return DragTargetAction.scan;
    }

    return DragTargetAction.none;
  }

  void _onPointerDown(PointerDownEvent event) {
    _isHolding = false;
    _hoveredAction = DragTargetAction.none;

    // Start timer: if held for > 200ms, reveal secondary buttons & enable drag/swipe!
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 200), () {
      _isHolding = true;
      _openMenu();
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isOpen || _isHolding) {
      final newHover = _checkHover(event.position);
      if (newHover != _hoveredAction) {
        if (newHover != DragTargetAction.none) {
          HapticFeedback.selectionClick();
        }
        setState(() => _hoveredAction = newHover);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final wasHolding = _isHolding;
    _holdTimer?.cancel();
    _isHolding = false;

    if (wasHolding && _isOpen) {
      // User held and swiped/dragged
      final target = _hoveredAction != DragTargetAction.none
          ? _hoveredAction
          : _checkHover(event.position);

      if (target == DragTargetAction.voice) {
        HapticFeedback.mediumImpact();
        _closeMenu();
        widget.onVoiceLog();
        return;
      } else if (target == DragTargetAction.scan) {
        HapticFeedback.mediumImpact();
        _closeMenu();
        widget.onScanReceipt();
        return;
      } else {
        // Released outside: smoothly close
        _closeMenu();
        return;
      }
    }

    // Quick tap released before hold threshold -> open Quick Input!
    if (!_isOpen) {
      HapticFeedback.lightImpact();
      widget.onQuickAdd();
    } else {
      _closeMenu();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _holdTimer?.cancel();
    _isHolding = false;
    _closeMenu();
  }

  @override
  Widget build(BuildContext context) {
    final isHoveringVoice = _hoveredAction == DragTargetAction.voice;
    final isHoveringScan = _hoveredAction == DragTargetAction.scan;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. Voice AI Logger Button (Revealed on hold)
          ScaleTransition(
            scale: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hover Label Badge
                  if (isHoveringVoice)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2834).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8)),
                      ),
                      child: const Text(
                        'Voice AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Button Icon
                  AnimatedScale(
                    key: _voiceKey,
                    duration: const Duration(milliseconds: 140),
                    scale: isHoveringVoice ? 1.22 : 1.0,
                    child: GestureDetector(
                      onTap: () {
                        _closeMenu();
                        widget.onVoiceLog();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isHoveringVoice
                              ? const Color(0xFF27384A)
                              : const Color(0xFF1B2834),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isHoveringVoice
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF2B3D4E),
                            width: isHoveringVoice ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isHoveringVoice
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.35),
                              blurRadius: isHoveringVoice ? 14 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: isHoveringVoice
                              ? Colors.white
                              : const Color(0xFFE2E8F0),
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. AI Receipt Scanner Button (Revealed on hold)
          ScaleTransition(
            scale: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hover Label Badge
                  if (isHoveringScan)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2834).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Text(
                        'Scan Receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Button Icon
                  AnimatedScale(
                    key: _scanKey,
                    duration: const Duration(milliseconds: 140),
                    scale: isHoveringScan ? 1.22 : 1.0,
                    child: GestureDetector(
                      onTap: () {
                        _closeMenu();
                        widget.onScanReceipt();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isHoveringScan
                              ? const Color(0xFF1D3A32)
                              : const Color(0xFF1B2834),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isHoveringScan
                                ? const Color(0xFF10B981)
                                : const Color(0xFF2B3D4E),
                            width: isHoveringScan ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isHoveringScan
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.35),
                              blurRadius: isHoveringScan ? 14 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.crop_free_rounded,
                          color: isHoveringScan
                              ? Colors.white
                              : const Color(0xFFE2E8F0),
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Primary '+' Floating Button (Off-white circle matching IMG_6026.PNG)
          AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: _isOpen ? 0.94 : 1.0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EDF5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF0D1620),
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
