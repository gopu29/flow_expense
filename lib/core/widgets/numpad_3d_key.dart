import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flagship 3D tactile keypad keycap with realistic physical depth,
/// a push-down click animation, top chamfer highlight, and bottom extrusion ledge.
class Numpad3DKey extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final bool isAction;
  final double height;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const Numpad3DKey({
    super.key,
    this.label,
    this.icon,
    this.isAction = false,
    this.height = 56.0,
    this.expanded = true,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<Numpad3DKey> createState() => _Numpad3DKeyState();
}

class _Numpad3DKeyState extends State<Numpad3DKey> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.isAction) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // Physical 3D extrusion dimensions
    const double ledgeHeight = 4.0;
    const double pressedLedge = 0.5;
    const double pressedTranslate = ledgeHeight - pressedLedge;

    final Widget buttonBody = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 65),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(
          top: _isPressed ? pressedTranslate : 0.0,
          bottom: _isPressed ? pressedLedge : ledgeHeight,
        ),
        height: widget.height,
        decoration: BoxDecoration(
          // Dual-tone top-to-bottom surface gradient simulating light reflection
          gradient: widget.isAction
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isPressed
                      ? const [Color(0xFF0369A1), Color(0xFF075985)]
                      : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isPressed
                      ? const [Color(0xFF192533), Color(0xFF111923)]
                      : const [Color(0xFF223243), Color(0xFF141F2B)],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isAction
                ? (_isPressed
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.6))
                : (_isPressed
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                    : const Color(0xFF344A61)),
            width: 1.2,
          ),
          boxShadow: widget.isAction
              ? [
                  // 3D physical extrusion ledge (zero blur = solid bevel edge)
                  BoxShadow(
                    color: const Color(0xFF075985),
                    offset: Offset(0, _isPressed ? pressedLedge : ledgeHeight),
                    blurRadius: 0,
                  ),
                  // Ambient cyan glow
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(
                      alpha: _isPressed ? 0.2 : 0.38,
                    ),
                    offset: Offset(0, _isPressed ? 2 : 5),
                    blurRadius: _isPressed ? 3 : 9,
                  ),
                ]
              : [
                  // 3D physical extrusion ledge (crisp shelf under the key)
                  BoxShadow(
                    color: const Color(0xFF080F16),
                    offset: Offset(0, _isPressed ? pressedLedge : ledgeHeight),
                    blurRadius: 0,
                  ),
                  // Ambient drop shadow
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isPressed ? 0.25 : 0.45,
                    ),
                    offset: Offset(0, _isPressed ? 2 : 5),
                    blurRadius: _isPressed ? 2 : 7,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: widget.icon != null
            ? Icon(
                widget.icon,
                color: Colors.white,
                size: 22,
              )
            : Text(
                widget.label ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
      ),
    );

    if (widget.expanded) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: buttonBody,
        ),
      );
    }

    return buttonBody;
  }
}

