import 'package:flow_expense/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/category.dart';
import 'subcategory_hold_menu.dart';

const double _kRailHeight = 56;

/// Horizontal rail of main categories with a button for the full picker.
/// Tapping selects a main category; holding opens its sub-categories.
class CategoryRail extends StatefulWidget {
  /// Every category of the active transaction type, including sub-categories.
  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onSelected;
  final VoidCallback onOpenPicker;

  const CategoryRail({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.onOpenPicker,
  });

  @override
  State<CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<CategoryRail> {
  final Map<String, GlobalKey> _pillKeys = {};

  String? get _selectedMainId =>
      widget.selected?.parentId ?? widget.selected?.id;

  @override
  void didUpdateWidget(CategoryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMainId = oldWidget.selected?.parentId ?? oldWidget.selected?.id;
    if (oldMainId != _selectedMainId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  void _revealSelected() {
    final pillContext = _pillKeys[_selectedMainId]?.currentContext;
    if (!mounted || pillContext == null) return;
    Scrollable.ensureVisible(
      pillContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mains = widget.categories.where((c) => !c.isSubCategory).toList();

    return Row(
      children: [
        Expanded(
          child: Container(
            height: _kRailHeight,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF121C26),
              borderRadius: BorderRadius.circular(_kRailHeight / 2),
              border: Border.all(color: const Color(0xFF2B3F54)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_kRailHeight / 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [for (final main in mains) _buildPill(main)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _FourDotButton(onTap: widget.onOpenPicker),
      ],
    );
  }

  Widget _buildPill(Category main) {
    final subcategories =
        widget.categories.where((c) => c.parentId == main.id).toList();
    final isSelected = _selectedMainId == main.id;
    // The pill shows the chosen sub-category so the selection stays visible.
    final shown = isSelected ? widget.selected! : main;

    return SubcategoryHoldMenu(
      key: _pillKeys.putIfAbsent(main.id, GlobalKey.new),
      category: main,
      subcategories: subcategories,
      selectedId: widget.selected?.id,
      onTap: () {
        AppHaptics.selectionClick();
        widget.onSelected(main);
      },
      onSelected: widget.onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF263A4D) : Colors.transparent,
          borderRadius: BorderRadius.circular(_kRailHeight / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shown.iconOrEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              shown.name,
              style: AppTypography.bodyMedium.copyWith(
                color:
                    isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (subcategories.isNotEmpty)
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: isSelected
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _FourDotButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FourDotButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'All categories',
      child: GestureDetector(
        onTap: () {
          AppHaptics.selectionClick();
          onTap();
        },
        child: Container(
          width: _kRailHeight,
          height: _kRailHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF121C26),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2B3F54)),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_Dot(), _Dot()],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_Dot(), _Dot()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textSecondary, width: 1.6),
      ),
    );
  }
}
