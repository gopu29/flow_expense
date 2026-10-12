import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/category.dart';

/// Modal dialog for adding or editing a category or subcategory.
class CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? initialCategory;
  final String? initialParentId;
  final CategoryType initialType;

  const CategoryFormDialog({
    super.key,
    this.initialCategory,
    this.initialParentId,
    this.initialType = CategoryType.expense,
  });

  static Future<Category?> show(
    BuildContext context, {
    Category? initialCategory,
    String? initialParentId,
    CategoryType initialType = CategoryType.expense,
  }) {
    return showDialog<Category>(
      context: context,
      builder: (ctx) => CategoryFormDialog(
        initialCategory: initialCategory,
        initialParentId: initialParentId,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  late final TextEditingController _nameController;
  late CategoryType _selectedType;
  String? _selectedParentId;
  late String _selectedEmoji;
  late int _selectedColor;

  static const List<String> _popularEmojis = [
    '🍔', '☕', '🍕', '🛒', '🚗', '✈️', '⛽', '🏥',
    '💊', '🎮', '🍿', '📱', '💻', '📚', '🏋️', '🎁',
    '👕', '🏠', '⚡', '💼', '💰', '📈', '💸', '🪙',
    '💳', '🏦', '🎟️', '🐕', '🎓', '💈', '🛠️', '👶',
  ];

  static const List<int> _paletteColors = [
    0xFF6366F1, // Indigo
    0xFF10B981, // Emerald
    0xFFEC4899, // Pink
    0xFFF59E0B, // Amber
    0xFF3B82F6, // Blue
    0xFF8B5CF6, // Purple
    0xFF14B8A6, // Teal
    0xFFEF4444, // Red
    0xFFF97316, // Orange
    0xFF06B6D4, // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategory?.name ?? '',
    );
    _selectedType = widget.initialCategory?.type ?? widget.initialType;
    _selectedParentId =
        widget.initialCategory?.parentId ?? widget.initialParentId;
    _selectedEmoji = widget.initialCategory?.iconOrEmoji ?? '🍔';

    // If adding a subcategory, inherit parent color & type
    final allCats = ref.read(categoriesProvider).value ?? [];
    Category? parent;
    if (_selectedParentId != null) {
      for (final c in allCats) {
        if (c.id == _selectedParentId) {
          parent = c;
          break;
        }
      }
    }

    if (parent != null) {
      _selectedType = parent.type;
      _selectedColor = widget.initialCategory?.color ?? parent.color;
    } else {
      _selectedColor = widget.initialCategory?.color ?? _paletteColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final category = Category(
      id: widget.initialCategory?.id ?? const Uuid().v4(),
      parentId: _selectedParentId,
      name: name,
      iconOrEmoji: _selectedEmoji,
      color: _selectedColor,
      type: _selectedType,
    );

    if (widget.initialCategory == null) {
      await ref.read(categoriesProvider.notifier).addCategory(category);
    } else {
      await ref.read(categoriesProvider.notifier).updateCategory(category);
    }

    if (mounted) {
      Navigator.of(context).pop(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoriesProvider).value ?? [];
    Category? parentCategory;
    if (_selectedParentId != null) {
      for (final c in allCategories) {
        if (c.id == _selectedParentId) {
          parentCategory = c;
          break;
        }
      }
    }

    final isSubcategory = _selectedParentId != null;
    final isEditing = widget.initialCategory != null;

    final String dialogTitle;
    if (isEditing) {
      dialogTitle = isSubcategory ? 'Edit Subcategory' : 'Edit Category';
    } else {
      dialogTitle = isSubcategory ? 'New Subcategory' : 'New Category';
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dialogTitle,
                    style: AppTypography.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textTertiary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // If adding a subcategory: Show clear parent category badge
              if (isSubcategory && parentCategory != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(parentCategory.color).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(parentCategory.color).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(parentCategory.color).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          parentCategory.iconOrEmoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Subcategory of ${parentCategory.name}',
                        style: TextStyle(
                          color: Color(parentCategory.color),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Preview Icon Badge & Name Input
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Color(_selectedColor).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(_selectedColor),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: AppTypography.bodyLarge,
                      autofocus: !isEditing,
                      decoration: InputDecoration(
                        hintText: isSubcategory
                            ? 'Subcategory Name (e.g. Groceries)'
                            : 'Category Name (e.g. Shopping)',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceHover,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Category Type Selector (only shown for Main Categories)
              if (!isSubcategory) ...[
                Text('Type', style: AppTypography.caption),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildTypeOption('Expense', CategoryType.expense),
                      _buildTypeOption('Income', CategoryType.income),
                      _buildTypeOption('Transfer', CategoryType.transfer),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Emoji Selection
              Text('Icon / Emoji', style: AppTypography.caption),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _popularEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _popularEmojis[index];
                    final isSel = _selectedEmoji == emoji;
                    return InkWell(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.accent.withValues(alpha: 0.25)
                              : AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? AppColors.accent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Color Palette Selection
              Text('Accent Color', style: AppTypography.caption),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _paletteColors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final colorVal = _paletteColors[index];
                    final isSel = _selectedColor == colorVal;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorVal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: Color(colorVal).withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: isSel
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing
                        ? 'Save Changes'
                        : (isSubcategory ? 'Create Subcategory' : 'Create Category'),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildTypeOption(String label, CategoryType type) {
    final isSel = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedParentId = null; // reset parent when changing type
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
              color: isSel ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
