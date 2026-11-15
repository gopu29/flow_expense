import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../core/providers/google_sheets_provider.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../widgets/settings_tiles.dart';

class GoogleSheetsSyncScreen extends ConsumerStatefulWidget {
  const GoogleSheetsSyncScreen({super.key});

  @override
  ConsumerState<GoogleSheetsSyncScreen> createState() => _GoogleSheetsSyncScreenState();
}

class _GoogleSheetsSyncScreenState extends ConsumerState<GoogleSheetsSyncScreen> {
  late TextEditingController _urlController;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccessMessage = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _setMessage(String message, {bool isSuccess = true}) {
    setState(() {
      _statusMessage = message;
      _isSuccessMessage = isSuccess;
    });
  }

  Future<void> _saveUrl(String url) async {
    await ref.read(googleSheetsWebhookUrlProvider.notifier).setUrl(url);
    _setMessage('Web App URL saved successfully.');
  }

  Future<void> _export(String url, {String mode = 'append'}) async {
    if (url.trim().isEmpty) {
      _setMessage('Please enter and save your Google Apps Script URL first.', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);
    final service = ref.read(googleSheetsServiceProvider);
    final txs = await ref.read(transactionsProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    final accounts = await ref.read(accountsProvider.future);

    final result = await service.exportTransactions(
      webhookUrl: url,
      transactions: txs,
      categories: categories,
      accounts: accounts,
      mode: mode,
    );

    setState(() => _isLoading = false);
    _setMessage(result.message, isSuccess: result.isSuccess);
  }

  Future<void> _import(String url) async {
    if (url.trim().isEmpty) {
      _setMessage('Please enter and save your Google Apps Script URL first.', isSuccess: false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Import from Google Sheet', style: AppTypography.titleMedium),
        content: Text(
          'Transactions from your Google Sheet will be added to your local database. '
          'Existing transactions with matching IDs will not be duplicated.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final service = ref.read(googleSheetsServiceProvider);
    final existingTxs = await ref.read(transactionsProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    final accounts = await ref.read(accountsProvider.future);

    final existingIds = existingTxs.map((t) => t.id).toSet();

    final res = await service.importTransactions(
      webhookUrl: url,
      existingTransactionIds: existingIds,
      categories: categories,
      accounts: accounts,
    );

    if (res.result.isSuccess && res.newTransactions.isNotEmpty) {
      await ref.read(transactionsProvider.notifier).addTransactions(res.newTransactions);
    }

    setState(() => _isLoading = false);
    _setMessage(res.result.message, isSuccess: res.result.isSuccess);
  }

  void _showCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Google Apps Script Code', style: AppTypography.titleMedium),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy and paste this code into your Google Sheet: Extensions > Apps Script.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const SingleChildScrollView(
                  child: SelectableText(
                    GoogleSheetsService.appsScriptTemplate,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: GoogleSheetsService.appsScriptTemplate),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Apps Script code copied to clipboard!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Copy Code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urlAsync = ref.watch(googleSheetsWebhookUrlProvider);
    final savedUrl = urlAsync.value ?? '';

    if (_urlController.text.isEmpty && savedUrl.isNotEmpty) {
      _urlController.text = savedUrl;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Google Sheets Sync', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppConstants.horizontalPadding,
            8,
            AppConstants.horizontalPadding,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Two-Way Sheets Sync', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                          'Export local transactions or restore backups directly from your Google Sheet using a free macro.',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSuccessMessage
                      ? AppColors.income.withValues(alpha: 0.15)
                      : AppColors.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccessMessage ? AppColors.income : AppColors.expense,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccessMessage ? Icons.check_circle_outline : Icons.error_outline,
                      color: _isSuccessMessage ? AppColors.income : AppColors.expense,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: AppTypography.caption.copyWith(
                          color: _isSuccessMessage ? AppColors.income : AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SettingsSectionLabel('Web App URL'),
            SettingsGroup(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _urlController,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'https://script.google.com/macros/s/.../exec',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surfaceHover,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.surfaceBorder),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded, size: 20),
                          tooltip: 'Paste from clipboard',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _urlController.text = data!.text!.trim();
                              await _saveUrl(_urlController.text);
                            }
                          },
                        ),
                      ),
                      onSubmitted: _saveUrl,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          savedUrl.isNotEmpty ? 'URL is configured' : 'Not configured',
                          style: AppTypography.caption.copyWith(
                            color: savedUrl.isNotEmpty ? AppColors.income : AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _saveUrl(_urlController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save URL', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),

            const SettingsSectionLabel('Actions'),
            SettingsGroup(children: [
              SettingsNavTile(
                icon: Icons.upload_rounded,
                title: 'Export to Google Sheet (Append)',
                onTap: _isLoading ? () {} : () => _export(savedUrl, mode: 'append'),
              ),
              SettingsNavTile(
                icon: Icons.sync_rounded,
                title: 'Export to Google Sheet (Replace All)',
                onTap: _isLoading ? () {} : () => _export(savedUrl, mode: 'replace'),
              ),
              SettingsNavTile(
                icon: Icons.download_rounded,
                title: 'Import from Google Sheet',
                onTap: _isLoading ? () {} : () => _import(savedUrl),
              ),
            ]),

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ],

            const SettingsSectionLabel('Setup Instructions'),
            SettingsGroup(children: [
              SettingsNavTile(
                icon: Icons.code_rounded,
                title: 'View & Copy Apps Script Code',
                onTap: _showCodeDialog,
              ),
            ]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick 4-step setup:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('1. Open your Google Sheet ➔ Extensions ➔ Apps Script.', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text('2. Paste the code above and click Save (Ctrl+S / Cmd+S).', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text('3. Click Deploy ➔ New deployment ➔ Web app ➔ Who has access: "Anyone".', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text('4. Copy the Web app URL and paste it in the field above.', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
