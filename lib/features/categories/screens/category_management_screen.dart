import 'package:flow_expense/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../models/category.dart';
import '../widgets/category_form_sheet.dart';

const Color _kCardColor = Color(0xFF1B2935);
const Color _kDividerColor = Color(0xFF263747);
const Radius _kCardRadius = Radius.circular(24);

/// Categories screen: one reorderable list per type. Tap a category to show
/// its sub-categories and actions; drag the handle to change the order.
class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  CategoryType _type = CategoryType.expense;
  final Set<String> _expandedIds = {};

  void _openForm({Category? category, String? parentId}) {
    AppHaptics.selectionClick();
    CategoryFormSheet.show(
      context,
      initialCategory: category,
      parentId: parentId,
      type: _type,
    );
  }

  void _reorder(List<Category> mains, int oldIndex, int newIndex) {
    AppHaptics.selectionClick();
    final ordered = [...mains];
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    ref
        .read(categoriesProvider.notifier)
        .reorderCategories(ordered.map((c) => c.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final mains = categories
        .where((c) => c.type == _type && !c.isSubCategory)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: IconButton.filled(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1C2B3A),
                        foregroundColor: AppColors.textPrimary,
                        fixedSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Text(
                      'Categories',
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTypeTabs(),
                  ),
                  const SizedBox(height: 16),
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
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            buildDefaultDragHandles: false,
                            itemCount: mains.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                _reorder(mains, oldIndex, newIndex),
                            proxyDecorator: (child, _, _) => Material(
                              color: Colors.transparent,
                              elevation: 8,
                              borderRadius:
                                  const BorderRadius.all(_kCardRadius),
                              child: child,
                            ),
                            itemBuilder: (context, index) => _buildItem(
                              mains[index],
                              index,
                              mains.length,
                              categories
                                  .where((c) => c.parentId == mains[index].id)
                                  .toList(),
                            ),
                          ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Material(
                    color: const Color(0xFFE8EEF4),
                    shape: const StadiumBorder(),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => _openForm(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 15,
                        ),
                        child: Text(
                          'New category',
                          style: AppTypography.bodyLarge.copyWith(
                            color: const Color(0xFF0D1620),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF121C26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2B3F54)),
      ),
      child: Row(
        children: [
          for (final type in CategoryType.values)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() => _type = type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: type == _type
                        ? const Color(0xFF263A4D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    switch (type) {
                      CategoryType.expense => 'Expense',
                      CategoryType.income => 'Income',
                      CategoryType.transfer => 'Transfer',
                    },
                    style: AppTypography.bodyMedium.copyWith(
                      color: type == _type
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight:
                          type == _type ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(
    Category main,
    int index,
    int count,
    List<Category> subcategories,
  ) {
    final isExpanded = _expandedIds.contains(main.id);

    return Material(
      key: ValueKey(main.id),
      color: _kCardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: index == 0 ? _kCardRadius : Radius.zero,
          bottom: index == count - 1 ? _kCardRadius : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          if (index > 0)
            const Divider(height: 1, thickness: 1, color: _kDividerColor),
          InkWell(
            onTap: () {
              AppHaptics.selectionClick();
              setState(() {
                isExpanded
                    ? _expandedIds.remove(main.id)
                    : _expandedIds.add(main.id);
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                children: [
                  CategoryIconBadge(
                    iconOrEmoji: main.iconOrEmoji,
                    colorValue: main.color,
                    size: 46,
                    fontSize: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      main.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (subcategories.isNotEmpty)
                    Text(
                      '${subcategories.length}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _buildSubPanel(main, subcategories)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildSubPanel(Category main, List<Category> subcategories) {
    return Column(
      children: [
        for (final sub in subcategories)
          InkWell(
            onTap: () => _openForm(category: sub),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(72, 10, 20, 10),
              child: Row(
                children: [
                  Text(sub.iconOrEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(62, 0, 12, 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => _openForm(parentId: main.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Sub-category'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentCyan,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openForm(category: main),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
