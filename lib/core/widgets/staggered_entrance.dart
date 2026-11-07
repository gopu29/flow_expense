import 'package:flutter/material.dart';

/// Staggered micro-entrance animation that reveals list items with a fluid fade & slide.
class StaggeredEntrance extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Duration duration;
  final Offset slideOffset;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 30),
    this.duration = const Duration(milliseconds: 380),
    this.slideOffset = const Offset(0.0, 0.08),
  });

  @override
  Widget build(BuildContext context) {
    final clampedIndex = index.clamp(0, 15);
    final totalDelay = delayPerItem * clampedIndex;

    return FutureBuilder<bool>(
      future: Future.delayed(totalDelay, () => true),
      initialData: false,
      builder: (context, snapshot) {
        final ready = snapshot.data ?? false;
        return AnimatedOpacity(
          opacity: ready ? 1.0 : 0.0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: ready ? Offset.zero : slideOffset,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: child,
          ),
        );
      },
    );
  }
}

