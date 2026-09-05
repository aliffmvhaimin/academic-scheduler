/// Neo-Brutalist loading indicator widget.
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class BrutalistLoadingIndicator extends StatelessWidget {
  final String message;

  const BrutalistLoadingIndicator({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
