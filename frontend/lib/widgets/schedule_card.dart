/// Neo-Brutalist Schedule Card widget displaying a scheduled study session or block.
///
/// Follows AGENTS.md §15 (thick borders, hard offset shadows, high contrast badges).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/schedule.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../viewmodels/schedule_view_model.dart';

class ScheduleCard extends StatelessWidget {
  final ContiguousStudySession session;
  final Task? task;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.session,
    this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskName = task?.taskName ?? 'Task: ${session.taskId}';
    final hasTask = task != null;

    // Deadline & urgency calculations
    String? deadlineLabel;
    bool isPastDeadline = false;
    if (hasTask) {
      final hoursUntil = task!.deadline.difference(session.end).inHours;
      isPastDeadline = hoursUntil < 0;
      if (isPastDeadline) {
        deadlineLabel = 'OVERDUE';
      } else if (hoursUntil <= 24) {
        deadlineLabel = 'DUE IN ${hoursUntil}H';
      } else {
        final days = (hoursUntil / 24).ceil();
        deadlineLabel = 'DUE IN ${days}D';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: AppTheme.thickBorder,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Time range & Block badge ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          border:
                              Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        session.timeRangeFormatted,
                        style: AppTypography.h3.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${session.durationHours.toStringAsFixed(session.durationHours.truncateToDouble() == session.durationHours ? 1 : 2)}h • ${session.blockCount} blocks',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Task Name ──
              Text(
                taskName,
                style: AppTypography.h3.copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ── Metadata & Urgency Badges ──
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (hasTask) ...[
                    _Badge(
                      label: '${task!.creditWeight} CREDITS',
                      backgroundColor: AppColors.primary,
                    ),
                    _Badge(
                      label: 'DIFF: ${task!.difficultyScore}/10',
                      backgroundColor: task!.difficultyScore >= 7
                          ? AppColors.secondary
                          : AppColors.tertiary,
                    ),
                    if (deadlineLabel != null)
                      _Badge(
                        label: deadlineLabel,
                        backgroundColor: isPastDeadline
                            ? AppColors.error
                            : (task!.deadline.difference(session.end).inHours <=
                                    48
                                ? AppColors.warning
                                : AppColors.background),
                        textColor: isPastDeadline ? Colors.white : AppColors.black,
                      ),
                  ] else
                    _Badge(
                      label: 'ID: ${session.taskId}',
                      backgroundColor: AppColors.background,
                    ),
                ],
              ),

              const SizedBox(height: 10),
              // ── Tap to view details hint ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.backgroundColor,
    this.textColor = AppColors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
