import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/amount_expression.dart';

const String _kLastRateKey = 'last_conversion_rate';

/// Converts a foreign amount with a rate the user enters, so it works offline.
/// Closes with the converted amount, or null if cancelled.
class CurrencyConverterSheet extends StatefulWidget {
  const CurrencyConverterSheet({super.key});

  static Future<double?> show(BuildContext context) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CurrencyConverterSheet(),
    );
  }

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  final TextEditingController _foreignController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  double? get _converted {
    final foreign = double.tryParse(_foreignController.text);
    final rate = double.tryParse(_rateController.text);
    if (foreign == null || rate == null || foreign <= 0 || rate <= 0) {
      return null;
    }
    return (foreign * rate * 100).roundToDouble() / 100;
  }

  @override
  void initState() {
    super.initState();
    _loadLastRate();
  }

  @override
  void dispose() {
    _foreignController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadLastRate() async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble(_kLastRateKey);
    if (rate != null && mounted && _rateController.text.isEmpty) {
      setState(() => _rateController.text = rate.toString());
    }
  }

  Future<void> _apply(double converted) async {
    final rate = double.parse(_rateController.text);
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLastRateKey, rate);
    navigator.pop(converted);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final converted = _converted;
    const symbol = AppConstants.currencySymbol;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF162330),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2B3F54), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        media.viewInsets.bottom + media.padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Currency converter',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your own rate. It is remembered for next time.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _foreignController,
              label: 'Amount in other currency',
              autofocus: true,
            ),
            const SizedBox(height: 10),
            _buildField(
              controller: _rateController,
              label: 'Rate: 1 unit = $symbol',
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: converted == null ? null : () => _apply(converted),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                converted == null
                    ? 'Enter amount and rate'
                    : 'Use $symbol${formatAmountInput(converted)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
    );
  }
}
