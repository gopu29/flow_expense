import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/expense_providers.dart';
import '../../categories/screens/category_management_screen.dart';
import 'back_tap_guide_screen.dart';

/// Settings and preferences screen matching Quanto.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hideBalances = false;
  String _selectedCurrency = 'INR (₹)';

  final List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'JPY (¥)',
  ];

  void _exportTransactionsCsv() {
    final txs = ref.read(transactionsProvider).value ?? [];
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID,Amount,Type,CategoryID,AccountID,Date,Note');
    for (final t in txs) {
      buffer.writeln(
        '${t.id},${t.amount},${t.type.name},${t.categoryId},${t.accountId},${t.date.toIso8601String()},"${t.note ?? ''}"',
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('CSV Export Ready', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${txs.length} transactions converted to CSV format.', style: AppTypography.caption),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  buffer.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings & Preferences', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: ListView(
            children: [
              const SizedBox(height: 12),

              // Flagship Back Tap Banner
              GlassCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackTapGuideScreen()),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.touch_app_rounded, color: AppColors.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'iOS Back Tap Setup',
                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Configure double-tap shortcut logging',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Preferences Section
              Text('Preferences', style: AppTypography.titleMedium),
              const SizedBox(height: 10),

              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.accent),
                      title: Text('Primary Currency', style: AppTypography.bodyLarge),
                      trailing: DropdownButton<String>(
                        value: _selectedCurrency,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.surface,
                        style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                        items: _currencies.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.surfaceBorder),
                    SwitchListTile(
                      secondary: const Icon(Icons.visibility_off_outlined, color: AppColors.accent),
                      title: Text('Hide Balances', style: AppTypography.bodyLarge),
                      subtitle: Text(
                        'Mask total net worth and amounts on launch',
                        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                      ),
                      value: _hideBalances,
                      activeThumbColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() => _hideBalances = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Categories & Organization
              Text('Organization', style: AppTypography.titleMedium),
              const SizedBox(height: 10),

              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.category_rounded, color: AppColors.accent),
                  title: Text('Categories & Subcategories', style: AppTypography.bodyLarge),
                  subtitle: Text(
                    'Customize spending icons, colors, and hierarchies',
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Data Management
              Text('Data & Backups', style: AppTypography.titleMedium),
              const SizedBox(height: 10),

              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: _exportTransactionsCsv,
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.income),
                  title: Text('Export to CSV', style: AppTypography.bodyLarge),
                  subtitle: Text(
                    'Download all transactions in standard CSV table',
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 20),

              // App Info Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text('⚡', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text('v1.0.0 (Build 1) • 100% Offline Local SQLite', style: AppTypography.caption),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
