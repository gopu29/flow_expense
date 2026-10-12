import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/activity/screens/activity_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlowExpenseApp());
}

class FlowExpenseApp extends StatelessWidget {
  const FlowExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ActivityScreen(),
    );
  }
}
