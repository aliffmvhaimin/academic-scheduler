/// Availability Screen managing student study periods and daily time windows.
///
/// Implements Phase 8 — Availability (FR4 Configure Availability, persistence, validation).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/free_slot.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../viewmodels/availability_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/slot_card.dart';
import 'slot_form_dialog.dart';

class AvailabilityScreen extends StatefulWidget {
  final AvailabilityViewModel? viewModel;

  const AvailabilityScreen({
    super.key,
    this.viewModel,
  });

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late final AvailabilityViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? AvailabilityViewModel();
    _viewModel.loadSlots();
  }

  Future<void> _openAddSlotDialog(BuildContext context,
      {String? defaultDate}) async {
    final result = await SlotFormDialog.show(
      context,
      defaultDate: defaultDate,
      viewModel: _viewModel,
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study slot added'),
          backgroundColor: AppColors.black,
        ),
      );
    }
  }

  Future<void> _openEditSlotDialog(BuildContext context, FreeSlot slot) async {
    final result = await SlotFormDialog.show(
      context,
      initialSlot: slot,
      viewModel: _viewModel,
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study slot updated'),
          backgroundColor: AppColors.black,
        ),
      );
    }
  }

  Future<void> _confirmDeleteSlot(BuildContext context, FreeSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: AppTheme.borderWidth,
          ),
        ),
        title: const Text('Delete Slot?', style: AppTypography.h2),
        content: Text(
          'Remove ${slot.start} – ${slot.end} on ${slot.date}?',
          style: AppTypography.body,
        ),
        actions: [
          OutlinedButton(
            key: const Key('cancel_delete_slot_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_slot_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _viewModel.deleteSlot(slot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot removed'),
            backgroundColor: AppColors.black,
          ),
        );
      }
    }
  }

  Future<void> _applyQuickWeekTemplate(BuildContext context) async {
    final now = DateTime.now();
    final next7Days = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(d);
    });

    final success = await _viewModel.applyTemplateToDays(
      dates: next7Days,
      windows: [
        {'start': '09:00', 'end': '12:00'},
        {'start': '14:00', 'end': '17:00'},
        {'start': '19:00', 'end': '22:00'},
      ],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Applied study schedule to next 7 days'
              : 'Failed to apply schedule'),
          backgroundColor: AppColors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.slots.isEmpty) {
            return const BrutalistLoadingIndicator(
                message: 'Loading availability...');
          }

          if (_viewModel.errorMessage != null && _viewModel.slots.isEmpty) {
            return BrutalistErrorView(
              message: _viewModel.errorMessage!,
              onRetry: _viewModel.loadSlots,
            );
          }

          if (_viewModel.slots.isEmpty) {
            return BrutalistEmptyState(
              icon: Icons.access_time_outlined,
              title: 'No Availability Set',
              subtitle: 'Define your available study periods for scheduling.',
              actionLabel: 'ADD AVAILABILITY',
              onAction: () => _openAddSlotDialog(context),
            );
          }

          final grouped = _viewModel.groupedByDate;
          final dates = _viewModel.uniqueDates;

          return RefreshIndicator(
            onRefresh: _viewModel.loadSlots,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(
                        value: '${dates.length}',
                        label: 'DAYS',
                      ),
                      Container(
                        width: 2,
                        height: 36,
                        color: AppColors.border,
                      ),
                      _MetricItem(
                        value:
                            '${_viewModel.totalAvailableHours.toStringAsFixed(1)}h',
                        label: 'TOTAL AVAIL',
                      ),
                      Container(
                        width: 2,
                        height: 36,
                        color: AppColors.border,
                      ),
                      _MetricItem(
                        value: '${_viewModel.totalAvailableBlocks}',
                        label: 'BLOCKS',
                      ),
                    ],
                  ),
                ),

                // ── Quick Templates Bar ──
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    key: const Key('quick_week_template_button'),
                    onPressed: () => _applyQuickWeekTemplate(context),
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('AUTO-FILL NEXT 7 DAYS (9–12, 14–17, 19–22)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                // ── Daily Groups ──
                ...dates.map((dateStr) {
                  final daySlots = grouped[dateStr] ?? [];
                  final dayHours = _viewModel.getHoursForDate(dateStr);
                  final parsedDate = DateTime.parse(dateStr);
                  final formattedDate =
                      DateFormat('EEEE, d MMM yyyy').format(parsedDate);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: AppTheme.thickBorder,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      boxShadow: AppTheme.hardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: AppTypography.h3
                                        .copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dayHours.toStringAsFixed(1)}h study time (${(dayHours * 4).round()} blocks)',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 24),
                              color: AppColors.black,
                              tooltip: 'Add Slot to $dateStr',
                              onPressed: () => _openAddSlotDialog(context,
                                  defaultDate: dateStr),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined,
                                  size: 24),
                              color: AppColors.error,
                              tooltip: 'Clear Day',
                              onPressed: () =>
                                  _viewModel.deleteSlotsForDate(dateStr),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Slots on this day
                        ...daySlots.map(
                          (slot) => SlotCard(
                            key: Key('slot_${slot.date}_${slot.start}'),
                            slot: slot,
                            onEdit: () => _openEditSlotDialog(context, slot),
                            onDelete: () => _confirmDeleteSlot(context, slot),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_slot_fab'),
        onPressed: () => _openAddSlotDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: AppTheme.borderWidth,
          ),
        ),
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'NEW TIME WINDOW',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
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
