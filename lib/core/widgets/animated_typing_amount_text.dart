import 'package:flutter/material.dart';

/// Animated number display that mimics physical typewriter / keypad typing and erasing.
/// When typing: newly added digits slide up with an elastic pop-in and fade.
/// When erasing: deleted digits slide down and smoothly dissolve.
class AnimatedTypingAmountText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final String? prefix;
  final TextStyle? prefixStyle;
  final double spacing;

  const AnimatedTypingAmountText({
    super.key,
    required this.text,
    required this.style,
    this.prefix,
    this.prefixStyle,
    this.spacing = 1.0,
  });

  @override
  State<AnimatedTypingAmountText> createState() => _AnimatedTypingAmountTextState();
}

class _DigitItem {
  final int id;
  final String char;
  bool isExiting = false;

  _DigitItem({
    required this.id,
    required this.char,
  });
}

class _AnimatedTypingAmountTextState extends State<AnimatedTypingAmountText> {
  int _nextId = 0;
  List<_DigitItem> _items = [];

  @override
  void initState() {
    super.initState();
    _rebuildFromText(widget.text);
  }

  void _rebuildFromText(String text) {
    _items = [
      for (int i = 0; i < text.length; i++)
        _DigitItem(id: _nextId++, char: text[i])
    ];
  }

  @override
  void didUpdateWidget(AnimatedTypingAmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _applyTextTransition(oldWidget.text, widget.text);
    }
  }

  void _applyTextTransition(String oldText, String newText) {
    // 1. If newly typed: newText extends oldText
    if (newText.startsWith(oldText) && newText.length > oldText.length) {
      // Remove any previously exiting items immediately
      _items.removeWhere((item) => item.isExiting);

      final addedChars = newText.substring(oldText.length);
      for (int i = 0; i < addedChars.length; i++) {
        _items.add(_DigitItem(id: _nextId++, char: addedChars[i]));
      }
      setState(() {});
      return;
    }

    // 2. If backspaced/erased: oldText starts with newText
    if (oldText.startsWith(newText) && newText.length < oldText.length) {
      _items.removeWhere((item) => item.isExiting);

      // Mark deleted trailing items as exiting
      for (int i = newText.length; i < _items.length; i++) {
        _items[i].isExiting = true;
      }
      setState(() {});
      return;
    }

    // 3. Fallback: Full replacement (e.g. from '0' to '5' or vice versa)
    _rebuildFromText(newText);
    setState(() {});
  }

  void _onItemExitComplete(int id) {
    if (mounted) {
      setState(() {
        _items.removeWhere((item) => item.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (widget.prefix != null) ...[
            Text(
              widget.prefix!,
              style: widget.prefixStyle ?? widget.style,
            ),
            const SizedBox(width: 4),
          ],
          for (final item in _items)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing),
              child: _SingleDigitView(
                key: ValueKey<int>(item.id),
                item: item,
                style: widget.style,
                onExitComplete: () => _onItemExitComplete(item.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _SingleDigitView extends StatefulWidget {
  final _DigitItem item;
  final TextStyle style;
  final VoidCallback onExitComplete;

  const _SingleDigitView({
    super.key,
    required this.item,
    required this.style,
    required this.onExitComplete,
  });

  @override
  State<_SingleDigitView> createState() => _SingleDigitViewState();
}

class _SingleDigitViewState extends State<_SingleDigitView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // Keystroke entrance animation: pop up from bottom with spring bounce
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(_SingleDigitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Erase animation: slide downward & dissolve
    if (widget.item.isExiting && !oldWidget.item.isExiting) {
      _controller.duration = const Duration(milliseconds: 110);
      _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );
      _scale = Tween<double>(begin: 1.0, end: 0.75).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );
      _slide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.0, 0.35),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
      );

      _controller.forward(from: 0.0).then((_) {
        widget.onExitComplete();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style.fontSize ?? 44.0;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: Transform.translate(
              offset: Offset(0, _slide.value.dy * fontSize * 0.4),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        widget.item.char,
        style: widget.style,
      ),
    );
  }
}
