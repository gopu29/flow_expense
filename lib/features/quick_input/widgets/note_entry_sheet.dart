import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Small keyboard sheet that edits the transaction note in [controller],
/// so typed text is kept however the sheet is closed.
class NoteEntrySheet extends StatelessWidget {
  final TextEditingController controller;

  const NoteEntrySheet({super.key, required this.controller});

  static Future<void> show(
    BuildContext context, {
    required TextEditingController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEntrySheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF162330),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2B3F54), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        media.viewInsets.bottom + media.padding.bottom + 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.of(context).pop(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Name this transaction',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Done',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }
}
