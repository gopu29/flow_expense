import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/category.dart';

const double _kRowHeight = 52;
const double _kMenuWidth = 236;
const double _kMaxVisibleRows = 5.5;
const double _kMenuGap = 8;
const double _kScreenMargin = 12;
const double _kAutoScrollZone = 36;
const double _kAutoScrollStep = 4;
const double _kDragSideSlack = 48;

/// Wraps a category so that holding it opens a list of its sub-categories.
///
/// The menu supports both ways of choosing: slide the held finger onto a row
/// and release to select it, or release first, then scroll and tap a row.
/// Holding a category that has no sub-categories simply selects it.
class SubcategoryHoldMenu extends StatefulWidget {
  final Category category;
  final List<Category> subcategories;
  final String? selectedId;
  final VoidCallback onTap;
  final ValueChanged<Category> onSelected;
  final Widget child;

  const SubcategoryHoldMenu({
    super.key,
    required this.category,
    required this.subcategories,
    required this.selectedId,
    required this.onTap,
    required this.onSelected,
    required this.child,
  });

  @override
  State<SubcategoryHoldMenu> createState() => _SubcategoryHoldMenuState();
}

class _SubcategoryHoldMenuState extends State<SubcategoryHoldMenu> {
  final GlobalKey<_MenuOverlayState> _menuKey = GlobalKey<_MenuOverlayState>();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _removeMenu() {
    _entry?.remove();
    _entry = null;
  }

  void _select(Category category) {
    _removeMenu();
    HapticFeedback.selectionClick();
    widget.onSelected(category);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    if (widget.subcategories.isEmpty) {
      widget.onSelected(widget.category);
      return;
    }

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final anchorBox = context.findRenderObject() as RenderBox;
    final topLeft = anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final topInset = MediaQuery.viewPaddingOf(context).top;

    _entry = OverlayEntry(
      builder: (_) => _MenuOverlay(
        key: _menuKey,
        anchor: topLeft & anchorBox.size,
        overlaySize: overlayBox.size,
        topInset: topInset,
        rows: [widget.category, ...widget.subcategories],
        parentId: widget.category.id,
        selectedId: widget.selectedId,
        onDismiss: _removeMenu,
        onSelected: _select,
      ),
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: (details) =>
          _menuKey.currentState?.handleDragUpdate(details.globalPosition),
      onLongPressEnd: (_) => _menuKey.currentState?.handleDragEnd(),
      child: widget.child,
    );
  }
}

class _MenuOverlay extends StatefulWidget {
  final Rect anchor;
  final Size overlaySize;
  final double topInset;
  final List<Category> rows;
  final String parentId;
  final String? selectedId;
  final VoidCallback onDismiss;
  final ValueChanged<Category> onSelected;

  const _MenuOverlay({
    super.key,
    required this.anchor,
    required this.overlaySize,
    required this.topInset,
    required this.rows,
    required this.parentId,
    required this.selectedId,
    required this.onDismiss,
    required this.onSelected,
  });

  @override
  State<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<_MenuOverlay> {
  final GlobalKey _listKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Offset? _lastFinger;
  bool _isMovingDown = false;
  int? _hoveredIndex;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Highlights the row under the held finger and scrolls near the list edges.
  void handleDragUpdate(Offset globalPosition) {
    final previousFinger = _lastFinger;
    if (previousFinger != null && globalPosition.dy != previousFinger.dy) {
      _isMovingDown = globalPosition.dy > previousFinger.dy;
    }
    _lastFinger = globalPosition;
    _updateHover();
    _updateAutoScroll();
  }

  /// Selects the highlighted row, or leaves the menu open to scroll and tap.
  void handleDragEnd() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    final index = _hoveredIndex;
    if (index != null) {
      widget.onSelected(widget.rows[index]);
    }
  }

  Offset? _fingerInList() {
    final finger = _lastFinger;
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (finger == null || box == null) return null;
    final local = box.globalToLocal(finger);
    final isInside = local.dx >= -_kDragSideSlack &&
        local.dx <= box.size.width + _kDragSideSlack &&
        local.dy >= 0 &&
        local.dy <= box.size.height;
    return isInside ? local : null;
  }

  void _updateHover() {
    final local = _fingerInList();
    int? nextIndex;
    if (local != null && _scrollController.hasClients) {
      final index = (local.dy + _scrollController.offset) ~/ _kRowHeight;
      if (index >= 0 && index < widget.rows.length) nextIndex = index;
    }
    if (nextIndex != _hoveredIndex) {
      if (nextIndex != null) HapticFeedback.selectionClick();
      setState(() => _hoveredIndex = nextIndex);
    }
  }

  void _updateAutoScroll() {
    final local = _fingerInList();
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    // Scrolls only toward the finger's travel, so that a finger entering the
    // list across one edge does not push the first rows out of view.
    final isNearTravelEdge = local != null &&
        box != null &&
        (_isMovingDown
            ? local.dy > box.size.height - _kAutoScrollZone
            : local.dy < _kAutoScrollZone);

    if (!isNearTravelEdge) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
      return;
    }
    _autoScrollTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScrollTick(),
    );
  }

  void _autoScrollTick() {
    if (_fingerInList() == null || !_scrollController.hasClients) return;
    final direction = _isMovingDown ? 1 : -1;
    final position = _scrollController.position;
    final target = (position.pixels + direction * _kAutoScrollStep)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _scrollController.jumpTo(target);
    _updateHover();
  }

  @override
  Widget build(BuildContext context) {
    final listHeight = _kRowHeight *
        (widget.rows.length.toDouble().clamp(1, _kMaxVisibleRows));
    final menuHeight = listHeight + 2;
    final spaceAbove = widget.anchor.top - widget.topInset - _kScreenMargin;
    final opensAbove = spaceAbove >= menuHeight + _kMenuGap;
    final top = opensAbove
        ? widget.anchor.top - menuHeight - _kMenuGap
        : widget.anchor.bottom + _kMenuGap;
    final left = (widget.anchor.center.dx - _kMenuWidth / 2).clamp(
      _kScreenMargin,
      widget.overlaySize.width - _kMenuWidth - _kScreenMargin,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
          ),
        ),
        Positioned(
          top: top,
          left: left,
          width: _kMenuWidth,
          height: menuHeight,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              alignment:
                  opensAbove ? Alignment.bottomCenter : Alignment.topCenter,
              child: Opacity(
                opacity: ((value - 0.92) / 0.08).clamp(0.0, 1.0),
                child: child,
              ),
            ),
            child: _buildPanel(listHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(double listHeight) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B2935),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2F4457)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          key: _listKey,
          height: listHeight,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            itemExtent: _kRowHeight,
            itemCount: widget.rows.length,
            itemBuilder: (context, index) => _buildRow(index),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int index) {
    final row = widget.rows[index];
    final isParent = row.id == widget.parentId;
    final isSelected = row.id == widget.selectedId;
    final isHovered = index == _hoveredIndex;

    return InkWell(
      onTap: () => widget.onSelected(row),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: isHovered ? const Color(0xFF2C4256) : Colors.transparent,
        child: Row(
          children: [
            Text(row.iconOrEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isParent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.accentCyan,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
