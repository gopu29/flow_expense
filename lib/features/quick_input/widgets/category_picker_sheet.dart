import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/category.dart';
import '../../categories/screens/category_management_screen.dart';
import 'subcategory_hold_menu.dart';

const int _kGridColumns = 4;
const double _kSheetHeightFactor = 0.78;

/// Full category grid opened from the add modal's four-dot button.
/// Holding a tile opens its sub-categories, the same as on the rail.
class CategoryPickerSheet extends ConsumerStatefulWidget {
  final CategoryType initialType;
  final Category? selected;

  const CategoryPickerSheet({
    super.key,
    required this.initialType,
    required this.selected,
  });

  static Future<Category?> show(
    BuildContext context, {
    required CategoryType initialType,
    required Category? selected,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => CategoryPickerSheet(
        initialType: initialType,
        selected: selected,
      ),
    );
  }

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  late CategoryType _type = widget.initialType;

  void _select(Category category) => Navigator.of(context).pop(category);

  void _openCategoryManager() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CategoryManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final ofType = categories.where((c) => c.type == _type).toList();
    final mains = ofType.where((c) => !c.isSubCategory).toList();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FractionallySizedBox(
      heightFactor: _kSheetHeightFactor,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162330), Color(0xFF0F1722)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF2B3F54), width: 1.5),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            _buildHeader(),
            const SizedBox(height: 18),
            Expanded(
              child: mains.isEmpty
                  ? Center(
                      child: Text(
                        'No categories yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16 + bottomInset,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _kGridColumns,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: mains.length,
                      itemBuilder: (context, index) =>
                          _buildTile(mains[index], ofType),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final types = [
      CategoryType.expense,
      CategoryType.income,
      if (widget.initialType == CategoryType.transfer) CategoryType.transfer,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF121C26),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2B3F54)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final type in types) _buildTypeTab(type)],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'Manage categories',
              child: GestureDetector(
                onTap: _openCategoryManager,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF263A4D),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF34495E)),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab(CategoryType type) {
    final isActive = type == _type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _type = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF263A4D) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          switch (type) {
            CategoryType.expense => 'Expense',
            CategoryType.income => 'Income',
            CategoryType.transfer => 'Transfer',
          },
          style: AppTypography.bodyMedium.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTile(Category main, List<Category> ofType) {
    final subcategories = ofType.where((c) => c.parentId == main.id).toList();
    final selected = widget.selected;
    final isSelected =
        selected != null && (selected.parentId ?? selected.id) == main.id;

    return SubcategoryHoldMenu(
      category: main,
      subcategories: subcategories,
      selectedId: selected?.id,
      onTap: () {
        HapticFeedback.selectionClick();
        _select(main);
      },
      onSelected: _select,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2935),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : const Color(0xFF263747),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        main.iconOrEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  main.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (subcategories.isNotEmpty)
              const Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
