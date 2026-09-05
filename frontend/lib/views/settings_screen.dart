/// Settings screen placeholder.
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: AppTypography.h1),
          const SizedBox(height: 24),
          Container(
            padding: AppTheme.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: AppTheme.thickBorder,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              boxShadow: AppTheme.hardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About', style: AppTypography.h3),
                const SizedBox(height: 8),
                Text(
                  'Academic Task Scheduling Mobile Application\nUsing Genetic Algorithm',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Version 1.0.0',
                  style: AppTypography.label,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
