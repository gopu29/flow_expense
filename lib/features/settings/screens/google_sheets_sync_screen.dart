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
  int _selectedTabIndex = 0; // 0 = Google Account, 1 = Apps Script Webhook
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

  // ---------------------------------------------------------------------------
  // Google Account Sync (Direct OAuth + Drive API)
  // ---------------------------------------------------------------------------

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(googleAuthStateProvider.notifier).signIn();
      if (user != null) {
        _setMessage('Signed in as ${user.email}. Sheet ready.');
      } else {
        _setMessage('Sign in was canceled.', isSuccess: false);
      }
    } catch (e) {
      _setMessage('Sign in error: $e\n(Make sure Google Cloud OAuth client IDs are registered).', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignOut() async {
    await ref.read(googleAuthStateProvider.notifier).signOut();
    _setMessage('Signed out of Google account.');
  }

  Future<void> _exportGoogleAccount({String mode = 'append'}) async {
    setState(() => _isLoading = true);
    final service = ref.read(googleDriveSheetsServiceProvider);
    final txs = await ref.read(transactionsProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    final accounts = await ref.read(accountsProvider.future);

    final result = await service.exportTransactions(
      transactions: txs,
      categories: categories,
      accounts: accounts,
      mode: mode,
    );

    setState(() => _isLoading = false);
    _setMessage(result.message, isSuccess: result.isSuccess);
  }

  Future<void> _importGoogleAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Import from Google Sheet', style: AppTypography.titleMedium),
        content: Text(
          'Transactions from "Flow Expense Tracker" in your Google Drive will be merged into your local database. '
          'Duplicates with matching IDs will be skipped automatically.',
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
    final service = ref.read(googleDriveSheetsServiceProvider);
    final existingTxs = await ref.read(transactionsProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    final accounts = await ref.read(accountsProvider.future);

    final existingIds = existingTxs.map((t) => t.id).toSet();

    final res = await service.importTransactions(
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

  // ---------------------------------------------------------------------------
  // Apps Script Webhook Sync (Anonymous Macro)
  // ---------------------------------------------------------------------------

  Future<void> _saveUrl(String url) async {
    await ref.read(googleSheetsWebhookUrlProvider.notifier).setUrl(url);
    _setMessage('Web App URL saved successfully.');
  }

  Future<void> _exportWebhook(String url, {String mode = 'append'}) async {
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

  Future<void> _importWebhook(String url) async {
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
    final googleUser = ref.watch(googleAuthStateProvider).value;
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
            // Mode Selector: Google Account vs Custom Macro
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Google Account (Auto)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 0 ? Colors.black : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Apps Script (Macro)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 1 ? Colors.black : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Status message
            if (_statusMessage != null) ...[
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
              const SizedBox(height: 14),
            ],

            if (_selectedTabIndex == 0) ...[
              // ===============================================================
              // TAB 0: Direct Google Account Sync (Auto create in Drive)
              // ===============================================================
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF4285F4), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1-Tap Cloud Sync', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(
                            'Sign in once. The app automatically creates a "Flow Expense Tracker" spreadsheet in your Google Drive.',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SettingsSectionLabel('Google Account'),
              SettingsGroup(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceHover,
                        child: Icon(
                          googleUser != null ? Icons.account_circle : Icons.person_outline,
                          color: googleUser != null ? AppColors.income : AppColors.textTertiary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              googleUser != null ? (googleUser.displayName ?? 'Google User') : 'Not Connected',
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              googleUser != null ? googleUser.email : 'Sign in to automate your sheet',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (googleUser != null ? _handleGoogleSignOut : _handleGoogleSignIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: googleUser != null ? AppColors.expense : AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          googleUser != null ? 'Sign Out' : 'Sign In',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: googleUser != null ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              if (googleUser != null) ...[
                const SettingsSectionLabel('Drive Actions'),
                SettingsGroup(children: [
                  SettingsNavTile(
                    icon: Icons.upload_rounded,
                    title: 'Export to My Google Sheet (Append)',
                    onTap: _isLoading ? () {} : () => _exportGoogleAccount(mode: 'append'),
                  ),
                  SettingsNavTile(
                    icon: Icons.sync_rounded,
                    title: 'Export to My Google Sheet (Replace All)',
                    onTap: _isLoading ? () {} : () => _exportGoogleAccount(mode: 'replace'),
                  ),
                  SettingsNavTile(
                    icon: Icons.download_rounded,
                    title: 'Import from My Google Sheet',
                    onTap: _isLoading ? () {} : _importGoogleAccount,
                  ),
                ]),
              ],
            ] else ...[
              // ===============================================================
              // TAB 1: Manual Apps Script Macro Webhook
              // ===============================================================
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
                          Text('Two-Way Sheets Macro', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(
                            'Connect using an anonymous Apps Script macro URL without configuring Google Cloud Console OAuth.',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
                            child: const Text('Save URL', style: TextStyle(fontSize: 13, color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),

              const SettingsSectionLabel('Macro Actions'),
              SettingsGroup(children: [
                SettingsNavTile(
                  icon: Icons.upload_rounded,
                  title: 'Export to Sheet (Append)',
                  onTap: _isLoading ? () {} : () => _exportWebhook(savedUrl, mode: 'append'),
                ),
                SettingsNavTile(
                  icon: Icons.sync_rounded,
                  title: 'Export to Sheet (Replace All)',
                  onTap: _isLoading ? () {} : () => _exportWebhook(savedUrl, mode: 'replace'),
                ),
                SettingsNavTile(
                  icon: Icons.download_rounded,
                  title: 'Import from Sheet',
                  onTap: _isLoading ? () {} : () => _importWebhook(savedUrl),
                ),
              ]),

              const SettingsSectionLabel('Macro Setup Instructions'),
              SettingsGroup(children: [
                SettingsNavTile(
                  icon: Icons.code_rounded,
                  title: 'View & Copy Apps Script Code',
                  onTap: _showCodeDialog,
                ),
              ]),
            ],

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
          ],
        ),
      ),
    );
  }
}
