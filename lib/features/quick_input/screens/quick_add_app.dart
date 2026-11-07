import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../core/services/android_shortcuts_service.dart';
import '../../../core/theme/app_theme.dart';
import 'quick_input_modal.dart';

/// Stand-alone app for Android shortcuts. It shows only the add-expense
/// sheet over a see-through window and closes when the sheet closes.
class QuickAddApp extends StatelessWidget {
  const QuickAddApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      color: Colors.transparent,
      home: const _QuickAddHost(),
    );
  }
}

class _QuickAddHost extends ConsumerStatefulWidget {
  const _QuickAddHost();

  @override
  ConsumerState<_QuickAddHost> createState() => _QuickAddHostState();
}

class _QuickAddHostState extends ConsumerState<_QuickAddHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    await QuickInputModal.show(context);
    // Refresh the widgets with the new totals before closing.
    final txs = await ref.read(transactionsProvider.future);
    await updateAndroidWidgets(txs);
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}
