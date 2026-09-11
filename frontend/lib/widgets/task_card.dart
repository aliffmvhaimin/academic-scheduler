/// Neo-Brutalist Task Card widget displaying academic task metadata.
///
/// Follows AGENTS.md §15 (thick borders, hard offset shadows, high contrast badges).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineFormatted =
        DateFormat('EEE, d MMM yyyy • HH:mm').format(task.deadline);
    final isPastDeadline = task.deadline.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: AppTheme.thickBorder,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: AppTheme.hardShadow,
      ),
      child: InkWell(
        onTap: onTap ?? onEdit,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Task Name & Actions ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.taskName,
                      style: AppTypography.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.black,
                      tooltip: 'Edit Task',
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error,
                      tooltip: 'Delete Task',
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Metadata Badges ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    label: '${task.creditWeight} CREDITS',
                    backgroundColor: AppColors.primary,
                  ),
                  _Badge(
                    label: 'DIFF: ${task.difficultyScore}/10',
                    backgroundColor: task.difficultyScore >= 7
                        ? AppColors.secondary
                        : AppColors.tertiary,
                  ),
                  _Badge(
                    label:
                        '${task.studyDurationHours.toStringAsFixed(task.studyDurationHours.truncateToDouble() == task.studyDurationHours ? 1 : 2)}h (${task.requiredBlocks} blks)',
                    backgroundColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Deadline Row ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPastDeadline
                      ? AppColors.secondary.withOpacity(0.2)
                      : AppColors.background,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPastDeadline
                          ? Icons.warning_amber_rounded
                          : Icons.access_time_filled,
                      size: 16,
                      color: isPastDeadline
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      deadlineFormatted,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPastDeadline
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neo-Brutalist chip badge with border and solid background.
class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _Badge({
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
