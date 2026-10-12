import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/category.dart';
import '../widgets/category_form_dialog.dart';

/// Screen for managing categories and nested subcategories.
class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  CategoryType _activeTab = CategoryType.expense;
  CategoryType _previousTab = CategoryType.expense;
  final Set<String> _expandedCategoryIds = {};

  int _tabIndex(CategoryType type) {
    switch (type) {
      case CategoryType.expense:
        return 0;
      case CategoryType.income:
        return 1;
      case CategoryType.transfer:
        return 2;
    }
  }

  void _changeTab(CategoryType newTab) {
    if (newTab == _activeTab) return;
    setState(() {
      _previousTab = _activeTab;
      _activeTab = newTab;
    });
  }

  void _toggleExpandCategory(String categoryId) {
    setState(() {
      if (_expandedCategoryIds.contains(categoryId)) {
        _expandedCategoryIds.remove(categoryId);
      } else {
        _expandedCategoryIds.add(categoryId);
      }
    });
  }

  void _openAddCategory({String? parentId}) {
    if (parentId != null) {
      setState(() {
        _expandedCategoryIds.add(parentId);
      });
    }
    CategoryFormDialog.show(
      context,
      initialParentId: parentId,
      initialType: _activeTab,
    );
  }

  void _openEditCategory(Category category) {
    CategoryFormDialog.show(
      context,
      initialCategory: category,
      initialType: category.type,
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final hasSubcategories = (ref.read(categoriesProvider).value ?? [])
        .any((c) => c.parentId == category.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          category.parentId == null ? 'Delete Category?' : 'Delete Subcategory?',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          hasSubcategories
              ? 'Deleting "${category.name}" will also delete all of its subcategories. Continue?'
              : 'Are you sure you want to delete "${category.name}"?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${category.name}"'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Categories & Subcategories', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Switcher with smooth sliding indicator pill
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
                vertical: 8,
              ),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Stack(
                  children: [
                    // Smooth sliding selection pill
                    AnimatedAlign(
                      alignment: _activeTab == CategoryType.expense
                          ? Alignment.centerLeft
                          : _activeTab == CategoryType.income
                              ? Alignment.center
                              : Alignment.centerRight,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: FractionallySizedBox(
                        widthFactor: 1 / 3,
                        heightFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF202E3B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF33475A),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab labels
                    Row(
                      children: [
                        _buildTabItem('Expense', CategoryType.expense),
                        _buildTabItem('Income', CategoryType.income),
                        _buildTabItem('Transfer', CategoryType.transfer),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Content List with smooth directional slide and fade animation
            Expanded(
              child: categoriesAsync.when(
                data: (allCategories) {
                  final isForward = _tabIndex(_activeTab) >= _tabIndex(_previousTab);

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topLeft,
                        children: <Widget>[
                          ...previousChildren,
                          ?currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final isNewChild = (child.key as ValueKey<CategoryType>?)?.value == _activeTab;
                      final beginOffset = isNewChild
                          ? Offset(isForward ? 0.08 : -0.08, 0.0)
                          : Offset(isForward ? -0.08 : 0.08, 0.0);

                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: beginOffset,
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<CategoryType>(_activeTab),
                      child: _buildCategoryListForTab(allCategories),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddCategory(),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildCategoryListForTab(List<Category> allCategories) {
    final currentTabCategories =
        allCategories.where((c) => c.type == _activeTab).toList();
    final parentCategories =
        currentTabCategories.where((c) => c.parentId == null).toList();

    if (parentCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text('No categories yet', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Create categories and subcategories to organize your cashflow.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _openAddCategory(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        6,
        AppConstants.horizontalPadding,
        80,
      ),
      itemCount: parentCategories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final parent = parentCategories[index];
        final subcategories = currentTabCategories
            .where((c) => c.parentId == parent.id)
            .toList();
        final hasSubcategories = subcategories.isNotEmpty;
        final isExpanded = _expandedCategoryIds.contains(parent.id);

        return GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parent Category Row - Tap to expand/collapse if has subcategories
              InkWell(
                onTap: hasSubcategories
                    ? () => _toggleExpandCategory(parent.id)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    CategoryIconBadge(
                      iconOrEmoji: parent.iconOrEmoji,
                      colorValue: parent.color,
                      size: 42,
                      fontSize: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parent.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                subcategories.isEmpty
                                    ? 'Main category'
                                    : '${subcategories.length} subcategor${subcategories.length == 1 ? 'y' : 'ies'}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              if (hasSubcategories) ...[
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 19,
                        color: AppColors.accent,
                      ),
                      tooltip: 'Add Subcategory',
                      onPressed: () =>
                          _openAddCategory(parentId: parent.id),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Edit',
                      onPressed: () => _openEditCategory(parent),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.expense,
                      ),
                      tooltip: 'Delete',
                      onPressed: () =>
                          _confirmDeleteCategory(parent),
                    ),
                  ],
                ),
              ),

              // Expandable subcategories list
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: isExpanded && hasSubcategories
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const Divider(
                              height: 1,
                              color: AppColors.surfaceBorder,
                            ),
                            const SizedBox(height: 8),
                            ...subcategories.map((sub) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 14,
                                  top: 6,
                                  bottom: 6,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '↳',
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Color(sub.color).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        sub.iconOrEmoji,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sub.name,
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: AppColors.textTertiary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Edit Subcategory',
                                      onPressed: () => _openEditCategory(sub),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: AppColors.expense,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Delete Subcategory',
                                      onPressed: () =>
                                          _confirmDeleteCategory(sub),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem(String label, CategoryType type) {
    final isSel = _activeTab == type;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _changeTab(type),
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
              color: isSel ? Colors.white : AppColors.textTertiary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
