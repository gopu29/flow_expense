import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/category.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';

/// AI Receipt Scanner Modal Sheet matching Quanto (IMG_6036.PNG).
class ReceiptScannerSheet extends ConsumerStatefulWidget {
  const ReceiptScannerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ReceiptScannerSheet(),
    );
  }

  @override
  ConsumerState<ReceiptScannerSheet> createState() =>
      _ReceiptScannerSheetState();
}

class _ReceiptScannerSheetState extends ConsumerState<ReceiptScannerSheet> {
  bool _isScanning = false;
  bool _hasResult = false;

  String _merchantName = 'Starbucks Coffee';
  double _detectedAmount = 380.0;
  final DateTime _detectedDate = DateTime.now();
  Category? _selectedCategory;
  Account? _selectedAccount;

  final List<Map<String, dynamic>> _mockReceipts = [
    {
      'merchant': 'Starbucks Coffee',
      'amount': 380.0,
      'category': 'Food',
      'items': ['1x Caramel Macchiato', '1x Butter Croissant'],
    },
    {
      'merchant': 'Shell Petrol Pump',
      'amount': 1450.0,
      'category': 'Transport',
      'items': ['Premium Fuel 14.5L'],
    },
    {
      'merchant': 'Nature Basket Supermarket',
      'amount': 2240.50,
      'category': 'Shopping',
      'items': ['Fresh Produce', 'Dairy Milk', 'Olive Oil'],
    },
    {
      'merchant': 'Apollo Pharmacy',
      'amount': 590.0,
      'category': 'Healthcare',
      'items': ['Vitamins', 'Prescription Meds'],
    },
  ];

  void _triggerScan() {
    setState(() {
      _isScanning = true;
      _hasResult = false;
    });

    final categories = ref.read(categoriesProvider).value ?? [];
    final accounts = ref.read(accountsProvider).value ?? [];
    if (_selectedAccount == null && accounts.isNotEmpty) {
      _selectedAccount = accounts.first;
    }

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        final mock = (_mockReceipts..shuffle()).first;
        final matchedCat = categories.firstWhere(
          (c) => c.name.toLowerCase() == (mock['category'] as String).toLowerCase(),
          orElse: () => categories.isNotEmpty
              ? categories.first
              : const Category(id: 'food', name: 'Food', iconOrEmoji: '🍔'),
        );

        setState(() {
          _isScanning = false;
          _hasResult = true;
          _merchantName = mock['merchant'] as String;
          _detectedAmount = mock['amount'] as double;
          _selectedCategory = matchedCat;
        });
      }
    });
  }

  Future<void> _saveReceiptExpense() async {
    if (_selectedCategory == null || _selectedAccount == null) return;

    final tx = Transaction(
      id: const Uuid().v4(),
      amount: _detectedAmount,
      type: TransactionType.expense,
      categoryId: _selectedCategory!.id,
      accountId: _selectedAccount!.id,
      date: _detectedDate,
      note: 'Receipt: $_merchantName',
      createdAt: DateTime.now(),
    );

    await ref.read(transactionsProvider.notifier).addTransaction(tx);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt from $_merchantName logged (${AppFormatters.currency(_detectedAmount)})!'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'AI OCR SCANNER',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'AI Receipt Scanner',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan or upload any paper or digital bill',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // Scanner Viewfinder Card
              GestureDetector(
                onTap: _isScanning ? null : _triggerScan,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isScanning
                          ? AppColors.accentCyan
                          : AppColors.surfaceBorder,
                      width: _isScanning ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isScanning)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Analyzing receipt text & totals...',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.accentCyan),
                            ),
                          ],
                        )
                      else if (!_hasResult)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.document_scanner_outlined,
                                color: AppColors.accentCyan,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to Scan or Pick Receipt',
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supports photos, invoices, and screenshot bills',
                              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        )
                      else
                        // Scanned preview graphic
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 32),
                            const SizedBox(width: 10),
                            Text(
                              'Receipt Parsed Successfully',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.income,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Parsed Receipt Data Card
              if (_hasResult) ...[
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Merchant', style: AppTypography.caption),
                          Text('Parsed Total', style: AppTypography.caption),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _merchantName,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppFormatters.currency(_detectedAmount),
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.surfaceBorder),
                      const SizedBox(height: 14),

                      // Category and Account match
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Category', style: AppTypography.caption),
                                const SizedBox(height: 6),
                                if (_selectedCategory != null)
                                  Row(
                                    children: [
                                      CategoryIconBadge(
                                        iconOrEmoji: _selectedCategory!.iconOrEmoji,
                                        colorValue: _selectedCategory!.color,
                                        size: 28,
                                        fontSize: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(_selectedCategory!.name, style: AppTypography.bodyMedium),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Account', style: AppTypography.caption),
                                const SizedBox(height: 6),
                                accountsAsync.maybeWhen(
                                  data: (accounts) {
                                    if (_selectedAccount == null && accounts.isNotEmpty) {
                                      _selectedAccount = accounts.first;
                                    }
                                    return Text(
                                      '${_selectedAccount?.icon ?? '🏦'} ${_selectedAccount?.name ?? 'Main'}',
                                      style: AppTypography.bodyMedium,
                                    );
                                  },
                                  orElse: () => const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveReceiptExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Log Receipt Expense',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
