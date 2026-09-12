/// Neo-Brutalist dialog displaying in-depth details of a scheduled study block/session.
///
/// Implements FR7 (View Schedule Detail), deadline information, and priority contribution.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/schedule.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../viewmodels/schedule_view_model.dart';

class ScheduleDetailDialog extends StatelessWidget {
  final ContiguousStudySession session;
  final Task? task;
  final PriorityContribution? priority;

  const ScheduleDetailDialog({
    super.key,
    required this.session,
    this.task,
    this.priority,
  });

  /// Static helper to display the detail dialog.
  static Future<void> show(
    BuildContext context, {
    required ContiguousStudySession session,
    Task? task,
    PriorityContribution? priority,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ScheduleDetailDialog(
        session: session,
        task: task,
        priority: priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskName = task?.taskName ?? 'Task: ${session.taskId}';
    final hasTask = task != null;
    final dateFormatted =
        DateFormat('EEEE, d MMMM yyyy').format(session.start);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: const BorderSide(
          color: AppColors.border,
          width: AppTheme.borderWidth,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Schedule Detail',
                  style: AppTypography.h2,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Task Title Box ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: AppTheme.thickBorder,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskName,
                    style: AppTypography.h3.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TASK ID: ${session.taskId}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Time & Session Window ──
            const Text('SCHEDULED WINDOW', style: AppTypography.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: dateFormatted,
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Time Interval',
                    value: session.timeRangeFormatted,
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    icon: Icons.timelapse,
                    label: 'Study Duration',
                    value:
                        '${session.durationHours.toStringAsFixed(1)} hours (${session.blockCount} blocks × 15 min)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Deadline Information (Hard Constraint C2) ──
            if (hasTask) ...[
              const Text('DEADLINE INFORMATION', style: AppTypography.label),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border, width: 2),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.event_available,
                      label: 'Task Deadline',
                      value: DateFormat('EEE, d MMM yyyy • HH:mm')
                          .format(task!.deadline),
                    ),
                    const Divider(height: 16),
                    _InfoRow(
                      icon: priority?.isBeforeDeadline == true
                          ? Icons.check_circle
                          : Icons.error,
                      iconColor: priority?.isBeforeDeadline == true
                          ? AppColors.success
                          : AppColors.error,
                      label: 'Constraint Status',
                      value: priority?.isBeforeDeadline == true
                          ? 'Valid (Scheduled before deadline)'
                          : 'Violation (Scheduled after deadline)',
                    ),
                    if (priority != null) ...[
                      const Divider(height: 16),
                      _InfoRow(
                        icon: Icons.hourglass_bottom,
                        label: 'Time To Deadline',
                        value:
                            '${priority!.hoursBeforeDeadline.toStringAsFixed(1)} hours remaining',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── Priority Contribution (GA Soft Objectives) ──
            const Text('PRIORITY CONTRIBUTION', style: AppTypography.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTask) ...[
                    _MetricBar(
                      label: 'Credit Weight',
                      valueText: '${task!.creditWeight} / 6 credits',
                      percentage: task!.creditWeight / 6.0,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _MetricBar(
                      label: 'Difficulty Score',
                      valueText: '${task!.difficultyScore} / 10 difficulty',
                      percentage: task!.difficultyScore / 10.0,
                      color: task!.difficultyScore >= 7
                          ? AppColors.secondary
                          : AppColors.tertiary,
                    ),
                    const SizedBox(height: 10),
                    if (priority != null)
                      _MetricBar(
                        label: 'Urgency Priority',
                        valueText: priority!.urgencyLevel,
                        percentage: (priority!.urgencyLevel.contains('Critical')
                            ? 1.0
                            : priority!.urgencyLevel.contains('Urgent')
                                ? 0.75
                                : 0.5),
                        color: AppColors.warning,
                      ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.insights, size: 16, color: AppColors.black),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The Genetic Algorithm balances deadline urgency, credit weight, and difficulty to schedule study time in optimal available slots.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Close Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('close_detail_button'),
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    this.iconColor = AppColors.black,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final String valueText;
  final double percentage;
  final Color color;

  const _MetricBar({
    required this.label,
    required this.valueText,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
