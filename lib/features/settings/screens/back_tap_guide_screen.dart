import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/constants/app_constants.dart';

/// Step-by-step interactive setup screen for iOS Back Tap and Quanto Log shortcut.
/// Matches Quanto reference IMG_00f1d6e4:
/// - "Back tap" header with back button
/// - Step 1: "Add the Quanto Log shortcut" with one-tap "Add shortcut" button launching iCloud shortcut
/// - Visual mini-mockup of the native iOS "+ Add Shortcut" sheet
/// - Step 2: "How to set up" linking to iOS Accessibility Settings
class BackTapGuideScreen extends StatefulWidget {
  const BackTapGuideScreen({super.key});

  @override
  State<BackTapGuideScreen> createState() => _BackTapGuideScreenState();
}

class _BackTapGuideScreenState extends State<BackTapGuideScreen> {
  static const _channel = MethodChannel('com.quanto.flow_expense/app_intent');
  static const _shortcutUrl =
      'https://www.icloud.com/shortcuts/f603c841b6ec48ecbb819675e3a5e70f';

  bool _step1Expanded = true;
  bool _step2Expanded = true;

  Future<void> _openShortcutLink() async {
    AppHaptics.mediumImpact();
    try {
      await _channel.invokeMethod('openURL', _shortcutUrl);
    } catch (e) {
      debugPrint('Failed to open shortcut URL: $e');
    }
  }

  Future<void> _openSettings() async {
    AppHaptics.lightImpact();
    try {
      await _channel.invokeMethod('openSettings');
    } catch (e) {
      debugPrint('Failed to open settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1118),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Back tap',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF162330),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
            vertical: 12,
          ),
          children: [
            // STEP 1 CARD: Add the Quanto Log shortcut
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141F2B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF223142),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1 Header
                  InkWell(
                    onTap: () => setState(() => _step1Expanded = !_step1Expanded),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E2D3D),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Add the Flow Expense Log shortcut',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            _step1Expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF8E9BAE),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_step1Expanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Tap the button below, then tap Add Shortcut to install Flow Expense Log.',
                        style: TextStyle(
                          color: const Color(0xFF8E9BAE),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Big "Add shortcut" Pill Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _openShortcutLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE2E8F0),
                            foregroundColor: const Color(0xFF0F172A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Add shortcut',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Visual Mockup Card matching reference screenshot
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D151E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF223142)),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            // Mockup top bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.close, color: Colors.white70, size: 20),
                                const Text(
                                  'Flow Expense Log',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(Icons.ios_share, color: Colors.white70, size: 20),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Shared shortcut ready to install',
                              style: TextStyle(color: Color(0xFF6B7F96), fontSize: 12),
                            ),
                            const SizedBox(height: 16),

                            // Shortcut Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2C3B),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD9B77E).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.bolt_rounded,
                                      color: Color(0xFFD9B77E),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text(
                                      'Flow Expense Log',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.more_horiz, color: Colors.white38),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Mini preview button
                            Container(
                              width: double.infinity,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Shortcut',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // STEP 2 CARD: How to set up Back Tap
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141F2B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF223142),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _step2Expanded = !_step2Expanded),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E2D3D),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'How to set up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            _step2Expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF8E9BAE),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_step2Expanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInstructionRow('A', 'Open Settings > Accessibility > Touch'),
                          _buildInstructionRow('B', 'Scroll down and tap "Back Tap"'),
                          _buildInstructionRow('C', 'Select "Double Tap" or "Triple Tap"'),
                          _buildInstructionRow('D', 'Under SHORTCUTS, select "Flow Expense Log"'),
                          const SizedBox(height: 16),

                          // Open Settings button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _openSettings,
                              icon: const Icon(Icons.settings, size: 18),
                              label: const Text(
                                'Open iPhone Settings',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD9B77E),
                                side: const BorderSide(color: Color(0xFF2E4057)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2D3D),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(
                color: Color(0xFFD9B77E),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
