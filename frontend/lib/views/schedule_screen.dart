/// Neo-Brutalist Schedule Screen displaying generated study timelines,
/// task blocks, infeasible diagnostics, and block inspection details.
///
/// Implements Phase 9 — Schedule UI (FR5, FR6, FR7, FR8, FR10).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/schedule.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../viewmodels/schedule_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/schedule_card.dart';
import 'schedule_detail_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  final ScheduleViewModel? viewModel;

  const ScheduleScreen({
    super.key,
    this.viewModel,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? ScheduleViewModel();
    if (widget.viewModel == null ||
        (!_viewModel.hasSchedule &&
            _viewModel.errorMessage == null &&
            !_viewModel.isLoading &&
            !_viewModel.isInfeasible)) {
      _viewModel.loadSchedule();
    }
  }

  Future<void> _handleGenerate() async {
    final success = await _viewModel.generateSchedule();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study schedule generated successfully!'),
          backgroundColor: AppColors.black,
        ),
      );
    } else if (_viewModel.isInfeasible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule is infeasible. Check diagnostics below.'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRecalculate() async {
    final success = await _viewModel.recalculateSchedule();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule recalculated successfully!'),
          backgroundColor: AppColors.black,
        ),
      );
    } else if (_viewModel.isInfeasible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recalculation resulted in an infeasible schedule.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openDetail(ContiguousStudySession session) {
    final task = _viewModel.getTask(session.taskId);
    final priority = session.blocks.isNotEmpty
        ? _viewModel.getPriorityContribution(session.blocks.first)
        : null;

    ScheduleDetailDialog.show(
      context,
      session: session,
      task: task,
      priority: priority,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const BrutalistLoadingIndicator(
              message: 'Computing schedule with Genetic Algorithm...',
            );
          }

          // Error view when no schedule or infeasible state is available to display
          if (_viewModel.errorMessage != null &&
              !_viewModel.hasSchedule &&
              !_viewModel.isInfeasible) {
            return BrutalistErrorView(
              message: _viewModel.errorMessage!,
              onRetry: _handleGenerate,
            );
          }

          // Infeasible State View (FR10)
          if (_viewModel.isInfeasible) {
            return _buildInfeasibleView();
          }

          // Empty State View
          if (!_viewModel.hasSchedule) {
            return BrutalistEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Schedule Generated',
              subtitle:
                  'Define your tasks and available study windows, then compute your personalized study timeline.',
              actionLabel: 'GENERATE SCHEDULE',
              onAction: _handleGenerate,
            );
          }

          // Feasible Schedule Timeline
          return _buildTimelineView();
        },
      ),
    );
  }

  /// Infeasible state view communicating shortfall diagnostics to the student (FR10).
  Widget _buildInfeasibleView() {
    final diag = _viewModel.diagnostics ?? {};
    final req = diag['required_hours'] ?? diag['required_duration'] ?? 'N/A';
    final avail = diag['available_hours_before_deadline'] ??
        diag['available_hours'] ??
        'N/A';
    final shortfall = diag['shortfall_hours'] ?? diag['shortfall'] ?? 'N/A';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Infeasible Warning Banner ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            border: AppTheme.thickBorder,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: AppTheme.hardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      size: 28, color: AppColors.black),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'INFEASIBLE SCHEDULE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'The scheduler could not find a feasible schedule that satisfies all hard constraints. The available study time before your deadlines is insufficient.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Diagnostics Breakdown ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: AppTheme.thickBorder,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: AppTheme.hardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DEFICIT DIAGNOSTICS', style: AppTypography.h3),
              const SizedBox(height: 14),
              _DiagnosticRow(
                icon: Icons.timer_outlined,
                label: 'Required Study Time',
                value: '$req hours',
              ),
              const Divider(height: 16),
              _DiagnosticRow(
                icon: Icons.event_available,
                label: 'Available Time Before Deadlines',
                value: '$avail hours',
              ),
              const Divider(height: 16),
              _DiagnosticRow(
                icon: Icons.hourglass_disabled,
                label: 'Shortfall Deficit',
                value: '$shortfall hours',
                isHighlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Recommendation & Actions ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20),
                  SizedBox(width: 8),
                  Text('RECOMMENDED ACTIONS', style: AppTypography.label),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• Add more study periods in the Availability tab.\n'
                '• Extend task deadlines in the Tasks tab.\n'
                '• Reduce study durations if allowable.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Buttons ──
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('clear_infeasible_button'),
                onPressed: _viewModel.clearSchedule,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('DISMISS'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('retry_schedule_button'),
                onPressed: _handleGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('RE-CALCULATE'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Feasible timeline view displaying summary banner, daily timelines, and blocks.
  Widget _buildTimelineView() {
    final dates = _viewModel.uniqueDates;
    final sessionsByDate = _viewModel.contiguousSessionsByDate;
    final res = _viewModel.scheduleResult;

    return RefreshIndicator(
      onRefresh: _viewModel.loadSchedule,
      color: AppColors.black,
      backgroundColor: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          // ── Summary Metrics Banner ──
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: AppTheme.thickBorder,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              boxShadow: AppTheme.hardShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        border: Border.all(color: AppColors.border, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FEASIBLE SCHEDULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (res?.executionTimeMs != null)
                      Text(
                        '${res!.executionTimeMs}ms • ${res.generationCount} gens',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricItem(
                      value:
                          '${_viewModel.totalScheduledHours.toStringAsFixed(1)}h',
                      label: 'TOTAL STUDY',
                    ),
                    Container(
                      width: 2,
                      height: 36,
                      color: AppColors.border,
                    ),
                    _MetricItem(
                      value: '${_viewModel.totalScheduledBlocks}',
                      label: 'BLOCKS (15M)',
                    ),
                    Container(
                      width: 2,
                      height: 36,
                      color: AppColors.border,
                    ),
                    _MetricItem(
                      value: '${dates.length}',
                      label: 'STUDY DAYS',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action Buttons (Recalculate & Clear) ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('recalculate_schedule_button'),
                  onPressed: _handleRecalculate,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('RECALCULATE'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                key: const Key('clear_schedule_button'),
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppColors.error,
                tooltip: 'Clear Schedule',
                onPressed: _viewModel.clearSchedule,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Daily Timeline Groups ──
          ...dates.map((dateStr) {
            final daySessions = sessionsByDate[dateStr] ?? [];
            final parsedDate = DateTime.parse(dateStr);
            final formattedDate =
                DateFormat('EEEE, d MMM yyyy').format(parsedDate);
            final dayHours = daySessions.fold(
                0.0, (sum, s) => sum + s.durationHours);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: AppTheme.thickBorder,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: AppTheme.hardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: AppTypography.h3.copyWith(fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border:
                              Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${dayHours.toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Scheduled study session cards
                  ...daySessions.map((session) {
                    final task = _viewModel.getTask(session.taskId);
                    return ScheduleCard(
                      key: Key('schedule_session_${session.taskId}_${session.startTimeFormatted}'),
                      session: session,
                      task: task,
                      onTap: () => _openDetail(session),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String value;
  final String label;

  const _MetricItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const _DiagnosticRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isHighlight ? AppColors.error : AppColors.black),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isHighlight ? AppColors.error : AppColors.black,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isHighlight ? AppColors.error : AppColors.black,
          ),
        ),
      ],
    );
  }
}
