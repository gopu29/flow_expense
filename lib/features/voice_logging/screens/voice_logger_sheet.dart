import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/transaction.dart';
import '../utils/voice_parser.dart';
import '../widgets/voice_waveform_mic.dart';

/// Modal bottom sheet for multi-transaction voice speech logging matching Quanto.
class VoiceLoggerSheet extends ConsumerStatefulWidget {
  const VoiceLoggerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VoiceLoggerSheet(),
    );
  }

  @override
  ConsumerState<VoiceLoggerSheet> createState() => _VoiceLoggerSheetState();
}

class _VoiceLoggerSheetState extends ConsumerState<VoiceLoggerSheet> {
  final TextEditingController _speechController = TextEditingController();
  bool _isListening = false;
  List<ParsedTransactionProposal> _proposals = [];

  final List<String> _samplePrompts = [
    'Spent 250 on lunch and 120 for coffee',
    'Paid 800 for fuel at Shell and 1500 for groceries',
    'Received salary of 50000',
    'Spent 450 on movie tickets and 180 for popcorn',
  ];

  @override
  void initState() {
    super.initState();
    _speechController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _speechController.removeListener(_onTextChanged);
    _speechController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _parseCurrentText();
  }

  void _parseCurrentText() {
    final categories = ref.read(categoriesProvider).value ?? [];
    final accounts = ref.read(accountsProvider).value ?? [];

    final parsed = VoiceTransactionParser.parse(
      speechText: _speechController.text,
      availableCategories: categories,
      availableAccounts: accounts,
    );

    setState(() {
      _proposals = parsed;
    });
  }

  void _simulateListening() {
    setState(() {
      _isListening = true;
    });

    // Pick a sample prompt for seamless demonstration
    final sample = (_samplePrompts..shuffle()).first;

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _speechController.text = sample;
          _isListening = false;
        });
      }
    });
  }

  Future<void> _logAllTransactions() async {
    if (_proposals.isEmpty) return;

    for (final prop in _proposals) {
      await ref.read(transactionsProvider.notifier).addTransaction(prop.toTransaction());
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_proposals.length} transactions logged via Voice AI!'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Pill handle
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

              // Title and Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'AI ASSISTANT',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Voice AI Logger',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Mention transactions in one go',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Animated Waveform and Mic
              VoiceWaveformMic(
                isListening: _isListening,
                onToggle: () {
                  if (_isListening) {
                    setState(() => _isListening = false);
                  } else {
                    _simulateListening();
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                _isListening ? 'Listening...' : 'Tap mic to speak or type below',
                style: AppTypography.caption.copyWith(
                  color: _isListening ? AppColors.accent : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 14),

              // Text Field transcript
              TextField(
                controller: _speechController,
                maxLines: 2,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'e.g. Spent 250 for lunch and 80 for coffee',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Sample Prompts chips
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _samplePrompts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prompt = _samplePrompts[index];
                    return GestureDetector(
                      onTap: () {
                        _speechController.text = prompt;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          prompt,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Parsed Cards Preview
              if (_proposals.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Detected Transactions (${_proposals.length})', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    Text('Auto-Categorized', style: AppTypography.caption.copyWith(color: AppColors.income)),
                  ],
                ),
                const SizedBox(height: 8),
                ..._proposals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final prop = entry.value;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        CategoryIconBadge(
                          iconOrEmoji: prop.category.iconOrEmoji,
                          colorValue: prop.category.color,
                          size: 38,
                          fontSize: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    prop.category.name,
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHover,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      prop.account.name,
                                      style: AppTypography.caption.copyWith(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                prop.note,
                                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${prop.type == TransactionType.income ? '+' : '-'}${AppFormatters.currency(prop.amount)}',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: prop.type == TransactionType.income ? AppColors.income : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _proposals.removeAt(index);
                            });
                          },
                          child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Commit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _logAllTransactions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Log All (${_proposals.length}) Transactions',
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
