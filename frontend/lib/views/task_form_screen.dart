/// Neo-Brutalist Task Form Screen for creating and editing academic tasks.
///
/// Implements FR1 (Create Task), FR2 (Edit Task), and validation as per PROJECT_SPEC.md §2.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../viewmodels/task_view_model.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? initialTask;
  final TaskViewModel viewModel;

  const TaskFormScreen({
    super.key,
    this.initialTask,
    required this.viewModel,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _durationController;

  late int _creditWeight;
  late int _difficultyScore;
  late DateTime _deadline;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;

    _nameController = TextEditingController(text: task?.taskName ?? '');
    _durationController = TextEditingController(
      text: task != null
          ? (task.studyDurationHours.truncateToDouble() == task.studyDurationHours
              ? task.studyDurationHours.toStringAsFixed(1)
              : task.studyDurationHours.toString())
          : '2.0',
    );

    _creditWeight = task?.creditWeight ?? 3;
    _difficultyScore = task?.difficultyScore ?? 5;
    _deadline = task?.deadline ??
        DateTime.now().add(const Duration(days: 3)).copyWith(
              hour: 23,
              minute: 59,
              second: 0,
              millisecond: 0,
            );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // ── Date & Time Pickers ──

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline,
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

    if (pickedDate != null) {
      setState(() {
        _deadline = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _deadline.hour,
          _deadline.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _deadline.hour, minute: _deadline.minute),
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

    if (pickedTime != null) {
      setState(() {
        _deadline = DateTime(
          _deadline.year,
          _deadline.month,
          _deadline.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  // ── Form Submission ──

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final duration = double.parse(_durationController.text.trim());

    setState(() => _isSubmitting = true);

    final task = Task(
      id: widget.initialTask?.id ?? const Uuid().v4(),
      taskName: _nameController.text.trim(),
      creditWeight: _creditWeight,
      difficultyScore: _difficultyScore,
      deadline: _deadline,
      studyDurationHours: duration,
    );

    final success = _isEditing
        ? await widget.viewModel.updateTask(task)
        : await widget.viewModel.addTask(task);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Task updated successfully' : 'Task created successfully',
          ),
          backgroundColor: AppColors.black,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.viewModel.errorMessage ?? 'Failed to save task',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDeadline =
        DateFormat('EEE, d MMM yyyy • HH:mm').format(_deadline);

    final durationVal = double.tryParse(_durationController.text.trim());
    final blocksCount = durationVal != null ? (durationVal * 4).ceil() : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: AppTypography.h2,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppTheme.borderWidth),
          child: Container(
            color: AppColors.border,
            height: AppTheme.borderWidth,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Task Name ──
              const Text('TASK NAME', style: AppTypography.label),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('task_name_input'),
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Data Structures Assignment 2',
                  prefixIcon: Icon(Icons.title, color: AppColors.black),
                ),
                style: AppTypography.body,
                validator: TaskViewModel.validateTaskName,
              ),
              const SizedBox(height: 24),

              // ── Credit Weight (1–6) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CREDIT WEIGHT', style: AppTypography.label),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_creditWeight Credits',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final weight = index + 1;
                  final isSelected = _creditWeight == weight;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 5 ? 8 : 0,
                      ),
                      child: InkWell(
                        key: Key('credit_weight_$weight'),
                        onTap: () => setState(() => _creditWeight = weight),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            border: AppTheme.thickBorder,
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadius),
                            boxShadow: isSelected ? AppTheme.hardShadow : null,
                          ),
                          child: Text(
                            '$weight',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // ── Difficulty Score (1–10) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DIFFICULTY SCORE', style: AppTypography.label),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _difficultyScore >= 7
                          ? AppColors.secondary
                          : (_difficultyScore >= 4
                              ? AppColors.warning
                              : AppColors.success),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_difficultyScore / 10',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.black,
                  inactiveTrackColor: AppColors.border.withOpacity(0.3),
                  trackHeight: 6,
                  thumbColor: AppColors.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                    elevation: 4,
                  ),
                  overlayColor: AppColors.primary.withOpacity(0.3),
                ),
                child: Slider(
                  key: const Key('difficulty_slider'),
                  value: _difficultyScore.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_difficultyScore',
                  onChanged: (val) =>
                      setState(() => _difficultyScore = val.round()),
                ),
              ),
              const SizedBox(height: 16),

              // ── Deadline Picker ──
              const Text('DEADLINE', style: AppTypography.label),
              const SizedBox(height: 8),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedDeadline,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('pick_date_button'),
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: const Text('DATE'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('pick_time_button'),
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time, size: 18),
                            label: const Text('TIME'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Study Duration (Hours) ──
              const Text('STUDY DURATION (HOURS)', style: AppTypography.label),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('study_duration_input'),
                controller: _durationController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 2.0 or 1.5',
                  prefixIcon:
                      const Icon(Icons.timelapse_rounded, color: AppColors.black),
                  helperText: blocksCount > 0
                      ? '$blocksCount study blocks of 15 min each'
                      : null,
                  helperStyle: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                style: AppTypography.body,
                validator: TaskViewModel.validateStudyDuration,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Duration quick buttons
              Row(
                children: [
                  _QuickDurationButton(
                    label: '+0.5h',
                    onTap: () => _adjustDuration(0.5),
                  ),
                  const SizedBox(width: 8),
                  _QuickDurationButton(
                    label: '+1.0h',
                    onTap: () => _adjustDuration(1.0),
                  ),
                  const SizedBox(width: 8),
                  _QuickDurationButton(
                    label: '+2.0h',
                    onTap: () => _adjustDuration(2.0),
                  ),
                  const Spacer(),
                  _QuickDurationButton(
                    label: '-0.5h',
                    onTap: () => _adjustDuration(-0.5),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('save_task_button'),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      side: const BorderSide(
                        color: AppColors.border,
                        width: AppTheme.borderWidth,
                      ),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.black,
                          ),
                        )
                      : Text(
                          _isEditing ? 'UPDATE TASK' : 'CREATE TASK',
                          style: AppTypography.button.copyWith(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _adjustDuration(double delta) {
    final current = double.tryParse(_durationController.text.trim()) ?? 0.0;
    final next = (current + delta).clamp(0.25, 100.0);
    setState(() {
      final formatted = next.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
      _durationController.text =
          formatted.endsWith('.') ? '${formatted}0' : formatted;
    });
  }
}

class _QuickDurationButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDurationButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
