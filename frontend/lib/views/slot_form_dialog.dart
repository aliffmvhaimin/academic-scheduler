/// Neo-Brutalist dialog for creating and editing free study slots.
///
/// Implements FR4 (Configure Availability) with time window validation.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/free_slot.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../viewmodels/availability_view_model.dart';

class SlotFormDialog extends StatefulWidget {
  final FreeSlot? initialSlot;
  final String? defaultDate;
  final AvailabilityViewModel viewModel;

  const SlotFormDialog({
    super.key,
    this.initialSlot,
    this.defaultDate,
    required this.viewModel,
  });

  /// Static helper to display the dialog.
  static Future<bool?> show(
    BuildContext context, {
    FreeSlot? initialSlot,
    String? defaultDate,
    required AvailabilityViewModel viewModel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => SlotFormDialog(
        initialSlot: initialSlot,
        defaultDate: defaultDate,
        viewModel: viewModel,
      ),
    );
  }

  @override
  State<SlotFormDialog> createState() => _SlotFormDialogState();
}

class _SlotFormDialogState extends State<SlotFormDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _errorMessage;

  bool get _isEditing => widget.initialSlot != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialSlot != null) {
      _selectedDate = DateTime.parse(widget.initialSlot!.date);
      final sParts = widget.initialSlot!.start.split(':');
      final eParts = widget.initialSlot!.end.split(':');
      _startTime =
          TimeOfDay(hour: int.parse(sParts[0]), minute: int.parse(sParts[1]));
      _endTime =
          TimeOfDay(hour: int.parse(eParts[0]), minute: int.parse(eParts[1]));
    } else if (widget.defaultDate != null) {
      _selectedDate = DateTime.parse(widget.defaultDate!);
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 12, minute: 0);
    } else {
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 12, minute: 0);
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  double get _calculatedHours {
    final sMin = _startTime.hour * 60 + _startTime.minute;
    final eMin = _endTime.hour * 60 + _endTime.minute;
    if (eMin <= sMin) return 0.0;
    return (eMin - sMin) / 60.0;
  }

  int get _calculatedBlocks => (_calculatedHours * 4).round();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _errorMessage = null;
      });
    }
  }

  void _applyPreset(int sH, int sM, int eH, int eM) {
    setState(() {
      _startTime = TimeOfDay(hour: sH, minute: sM);
      _endTime = TimeOfDay(hour: eH, minute: eM);
      _errorMessage = null;
    });
  }

  Future<void> _handleSubmit() async {
    final newSlot = FreeSlot(
      date: _dateString,
      start: _formatTime(_startTime),
      end: _formatTime(_endTime),
    );

    final validationError = AvailabilityViewModel.validateSlot(
      newSlot,
      widget.viewModel.slots,
      excludeSlot: widget.initialSlot,
    );

    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    final success = _isEditing
        ? await widget.viewModel.updateSlot(widget.initialSlot!, newSlot)
        : await widget.viewModel.addSlot(newSlot);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = widget.viewModel.errorMessage ?? 'Failed to save slot';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEE, d MMM yyyy').format(_selectedDate);

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
                Text(
                  _isEditing ? 'Edit Time Slot' : 'Add Time Slot',
                  style: AppTypography.h2,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Date Selector ──
            const Text('DATE', style: AppTypography.label),
            const SizedBox(height: 8),
            InkWell(
              key: const Key('slot_date_picker'),
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border, width: 2),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Text(
                      'CHANGE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Time Pickers ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('START TIME', style: AppTypography.label),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('slot_start_time'),
                        onTap: _pickStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border:
                                Border.all(color: AppColors.border, width: 2),
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_startTime),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('–',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('END TIME', style: AppTypography.label),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('slot_end_time'),
                        onTap: _pickEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border:
                                Border.all(color: AppColors.border, width: 2),
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time_filled, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_endTime),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Quick Presets ──
            const Text('QUICK PRESETS', style: AppTypography.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetChip(
                  label: 'Morning (9–12)',
                  onTap: () => _applyPreset(9, 0, 12, 0),
                ),
                _PresetChip(
                  label: 'Afternoon (14–17)',
                  onTap: () => _applyPreset(14, 0, 17, 0),
                ),
                _PresetChip(
                  label: 'Evening (19–22)',
                  onTap: () => _applyPreset(19, 0, 22, 0),
                ),
                _PresetChip(
                  label: 'Night (20–23)',
                  onTap: () => _applyPreset(20, 0, 23, 0),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Duration Summary / Error Banner ──
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  border: Border.all(color: AppColors.error, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_calculatedHours > 0) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_calculatedHours.toStringAsFixed(1)} hours (${_calculatedBlocks} study blocks)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('cancel_slot_button'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('save_slot_button'),
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_isEditing ? 'SAVE' : 'ADD SLOT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}
