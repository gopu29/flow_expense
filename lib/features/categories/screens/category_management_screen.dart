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

  void _openAddCategory({String? parentId}) {
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent),
            tooltip: 'Add Category',
            onPressed: () => _openAddCategory(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Switcher
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
                vertical: 8,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    _buildTabItem('Expense', CategoryType.expense),
                    _buildTabItem('Income', CategoryType.income),
                    _buildTabItem('Transfer', CategoryType.transfer),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Content List
            Expanded(
              child: categoriesAsync.when(
                data: (allCategories) {
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

                      return GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Parent Category Row
                            Row(
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
                                      Text(
                                        subcategories.isEmpty
                                            ? 'Main category'
                                            : '${subcategories.length} subcategor${subcategories.length == 1 ? 'y' : 'ies'}',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
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

                            // Subcategories list
                            if (subcategories.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(
                                height: 1,
                                color: AppColors.surfaceBorder,
                              ),
                              const SizedBox(height: 8),
                              ...subcategories.map((sub) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
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
                                        onPressed: () =>
                                            _confirmDeleteCategory(sub),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    },
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

  Widget _buildTabItem(String label, CategoryType type) {
    final isSel = _activeTab == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? AppColors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
              color: isSel ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
