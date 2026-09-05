/// Neo-Brutalist error display widget.
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';

class BrutalistErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const BrutalistErrorView({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: AppTheme.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: AppTheme.thickBorder,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: AppTheme.hardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('RETRY'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
