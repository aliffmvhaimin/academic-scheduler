/// Neo-Brutalist Slot Card widget displaying a configured study time window.
///
/// Follows AGENTS.md §15 (thick borders, hard offset shadows, high contrast badges).
import 'package:flutter/material.dart';
import '../models/free_slot.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';

class SlotCard extends StatelessWidget {
  final FreeSlot slot;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SlotCard({
    super.key,
    required this.slot,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2.5),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Time range icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.access_time_filled,
                size: 20,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 12),

            // Time range text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.start} – ${slot.end}',
                    style: AppTypography.h3.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          border:
                              Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${slot.durationHours.toStringAsFixed(slot.durationHours.truncateToDouble() == slot.durationHours ? 1 : 2)}h • ${slot.blockCount} blocks',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.black,
                tooltip: 'Edit Slot',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                tooltip: 'Delete Slot',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
