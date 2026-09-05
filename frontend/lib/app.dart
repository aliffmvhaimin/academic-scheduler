/// Root application widget with Neo-Brutalist theme and navigation.
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'navigation/main_navigation_shell.dart';

class AcademicSchedulerApp extends StatelessWidget {
  const AcademicSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Scheduler',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainNavigationShell(),
    );
  }
}
