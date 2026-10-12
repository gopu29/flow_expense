import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'routes/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FlowExpenseApp(),
    ),
  );
}

class FlowExpenseApp extends StatelessWidget {
  const FlowExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
