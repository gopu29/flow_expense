import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/settings_tiles.dart';

/// How to reach quick add on Android: every route opens the same
/// add-expense sheet over the app you are in.
class AndroidShortcutsGuideScreen extends StatelessWidget {
  const AndroidShortcutsGuideScreen({super.key});

  static const _guides = <(IconData, String, String)>[
    (
      Icons.touch_app_outlined,
      'Back tap (Samsung)',
      'Install Good Lock from the Galaxy Store, open RegiStar, turn on '
          'Back-Tap action, and choose App shortcut › Flow Expense › Add expense.',
    ),
    (
      Icons.widgets_outlined,
      'Home screen widgets',
      'Long-press the home screen, tap Widgets, and pick Flow Expense. '
          '"Add expense" is a one-tap button; "Monthly spend" shows this '
          "month's and today's spend with an add button.",
    ),
    (
      Icons.view_module_outlined,
      'Quick Settings tile',
      'Swipe down twice, tap the pencil or ⋮ › Edit buttons, and drag '
          '"Add expense" into your tiles.',
    ),
    (
      Icons.apps_rounded,
      'App icon shortcut',
      'Long-press the Flow Expense icon and tap "Add expense". Drag it out '
          'to pin it as its own home screen icon.',
    ),
    (
      Icons.notifications_none_rounded,
      'Notification shortcut',
      'Turn on "Notification shortcut" in Settings. A quiet notification '
          'with an Add expense button stays in your notification shade.',
    ),
    (
      Icons.accessibility_new_rounded,
      'Accessibility button',
      'Settings › Accessibility › Installed apps › Add expense. Turn on '
          'its shortcut and choose the accessibility button or gesture. '
          'Android warns that it can see your screen; this app reads nothing '
          'and only opens quick add.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Widgets & shortcuts', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding,
          8,
          AppConstants.horizontalPadding,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'Each of these opens the add-expense sheet on top of the app '
            "you're using. Save, and you're back where you were.",
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          for (final (icon, title, body) in _guides) ...[
            SettingsSectionLabel(title),
            SettingsGroup(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.accent, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(body, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
