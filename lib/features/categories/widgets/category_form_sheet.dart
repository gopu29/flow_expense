import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/category.dart';

const List<int> _kPaletteColors = [
  0xFF6366F1,
  0xFF10B981,
  0xFFEC4899,
  0xFFF59E0B,
  0xFF3B82F6,
  0xFF8B5CF6,
  0xFF14B8A6,
  0xFFEF4444,
  0xFFF97316,
  0xFF06B6D4,
];

const List<String> _kEmojis = [
  '🏠', '🍽️', '🍔', '🍕', '☕', '🛒', '💡', '🚗', '⛽', '🚌',
  '✈️', '🛍️', '👕', '🎮', '🎬', '🍿', '🍻', '💊', '🏥', '📚',
  '🎓', '📱', '💻', '🎁', '🐾', '👶', '💇', '🏋️', '⚽', '🎵',
  '💰', '💵', '🏦', '📈', '💳', '🧾', '🔧', '🧹', '🌱', '🏷️',
];

const double _kControlHeight = 56;

/// Small sheet to add or edit a category or sub-category: name, emoji, color.
class CategoryFormSheet extends ConsumerStatefulWidget {
  final Category? initialCategory;
  final String? parentId;
  final CategoryType type;

  const CategoryFormSheet({
    super.key,
    this.initialCategory,
    this.parentId,
    required this.type,
  });

  /// Closes with the saved category, or null when cancelled or deleted.
  static Future<Category?> show(
    BuildContext context, {
    Category? initialCategory,
    String? parentId,
    required CategoryType type,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(
        initialCategory: initialCategory,
        parentId: parentId ?? initialCategory?.parentId,
        type: initialCategory?.type ?? type,
      ),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialCategory?.name ?? '');
  late String _emoji = widget.initialCategory?.iconOrEmoji ?? '🏷️';
  late int _color;

  bool get _isEditing => widget.initialCategory != null;

  Category? get _parent {
    final parentId = widget.parentId;
    if (parentId == null) return null;
    for (final c in ref.read(categoriesProvider).value ?? const <Category>[]) {
      if (c.id == parentId) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _color = widget.initialCategory?.color ??
        _parent?.color ??
        _kPaletteColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _title {
    final parent = _parent;
    if (_isEditing) {
      return parent == null ? 'Edit category' : 'Edit sub-category';
    }
    if (parent != null) return 'New sub-category in ${parent.name}';
    final typeLabel = switch (widget.type) {
      CategoryType.expense => 'expense',
      CategoryType.income => 'income',
      CategoryType.transfer => 'transfer',
    };
    return 'New $typeLabel category';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();

    final notifier = ref.read(categoriesProvider.notifier);
    final initial = widget.initialCategory;
    final Category saved;
    if (initial != null) {
      saved = initial.copyWith(name: name, iconOrEmoji: _emoji, color: _color);
      await notifier.updateCategory(saved);
    } else {
      final siblings = (ref.read(categoriesProvider).value ?? const <Category>[])
          .where((c) => c.type == widget.type && c.parentId == widget.parentId);
      final nextOrder = siblings.fold<int>(
        0,
        (highest, c) => c.sortOrder >= highest ? c.sortOrder + 1 : highest,
      );
      saved = Category(
        id: const Uuid().v4(),
        parentId: widget.parentId,
        name: name,
        iconOrEmoji: _emoji,
        color: _color,
        type: widget.type,
        sortOrder: nextOrder,
      );
      await notifier.addCategory(saved);
    }
    if (mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _delete() async {
    final category = widget.initialCategory!;
    final hasSubcategories = (ref.read(categoriesProvider).value ?? const [])
        .any((c) => c.parentId == category.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          category.isSubCategory ? 'Delete sub-category?' : 'Delete category?',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          hasSubcategories
              ? 'Deleting "${category.name}" also deletes its sub-categories.'
              : 'Delete "${category.name}"?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickEmoji() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EmojiPickerSheet(),
    );
    if (picked != null && mounted) setState(() => _emoji = picked);
  }

  Future<void> _pickColor() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ColorPickerSheet(selected: _color),
    );
    if (picked != null && mounted) setState(() => _color = picked);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final hasName = _nameController.text.trim().isNotEmpty;

    return _SheetFrame(
      bottomPadding: media.viewInsets.bottom + media.padding.bottom + 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Category name',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1C2B3A),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 17,
                    ),
                    enabledBorder: _pillBorder(const Color(0xFF2B3F54)),
                    focusedBorder: _pillBorder(AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _RoundChoiceButton(
                label: 'Choose emoji',
                onTap: _pickEmoji,
                child: Text(_emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 8),
              _RoundChoiceButton(
                label: 'Choose color',
                onTap: _pickColor,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Color(_color),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: hasName ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE8EEF4),
              foregroundColor: const Color(0xFF0D1620),
              disabledBackgroundColor: const Color(0xFF2B3A48),
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              textStyle: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(_isEditing ? 'Save' : 'Add'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF43F5E),
              ),
              child: const Text('Delete'),
            ),
          ],
        ],
      ),
    );
  }

  static OutlineInputBorder _pillBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kControlHeight / 2),
        borderSide: BorderSide(color: color, width: 1.4),
      );
}

class _SheetFrame extends StatelessWidget {
  final double bottomPadding;
  final Widget child;

  const _SheetFrame({required this.bottomPadding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF162330),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2B3F54), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _RoundChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _RoundChoiceButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: _kControlHeight,
          height: _kControlHeight,
          decoration: const BoxDecoration(
            color: Color(0xFF1C2B3A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return _SheetFrame(
      bottomPadding: media.viewInsets.bottom + media.padding.bottom + 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final emoji in _kEmojis)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final emoji = value.trim();
              if (emoji.isNotEmpty) Navigator.of(context).pop(emoji);
            },
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Or type any emoji',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: const Color(0xFF1C2B3A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_kControlHeight / 2),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  final int selected;

  const _ColorPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      bottomPadding: MediaQuery.paddingOf(context).bottom + 16,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final color in _kPaletteColors)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(color),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(color),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == selected
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
