import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_haptics.dart';

/// One choice in a [showSettingsOptionSheet] list.
class SettingsOption<T> {
  final T value;
  final String label;
  final String? leading;

  const SettingsOption({required this.value, required this.label, this.leading});
}

/// Bottom sheet listing [options]; tapping one selects it and closes the sheet.
Future<void> showSettingsOptionSheet<T>({
  required BuildContext context,
  required String title,
  required T selected,
  required List<SettingsOption<T>> options,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(title, style: AppTypography.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: 12 + MediaQuery.paddingOf(ctx).bottom),
                children: [
                  for (final option in options)
                    ListTile(
                      title: Text(option.label, style: AppTypography.bodyLarge),
                      leading: option.leading == null
                          ? null
                          : SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  option.leading!,
                                  style: AppTypography.bodyLarge
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                      trailing: option.value == selected
                          ? const Icon(Icons.check_rounded, color: AppColors.income)
                          : null,
                      onTap: () {
                        AppHaptics.selectionClick();
                        Navigator.pop(ctx);
                        onSelected(option.value);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
