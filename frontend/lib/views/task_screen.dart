/// Academic Task Screen displaying active tasks, summary metrics, and CRUD actions.
///
/// Implements Phase 7: Task Management (Task List, Create, Edit, Delete, Validation).
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../viewmodels/task_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskScreen extends StatefulWidget {
  final TaskViewModel? viewModel;

  const TaskScreen({
    super.key,
    this.viewModel,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late final TaskViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? TaskViewModel();
    _viewModel.loadTasks();
  }

  Future<void> _navigateToCreateTask(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TaskFormScreen(viewModel: _viewModel),
      ),
    );
    if (result == true) {
      await _viewModel.loadTasks();
    }
  }

  Future<void> _navigateToEditTask(BuildContext context, Task task) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TaskFormScreen(
          initialTask: task,
          viewModel: _viewModel,
        ),
      ),
    );
    if (result == true) {
      await _viewModel.loadTasks();
    }
  }

  Future<void> _confirmDeleteTask(BuildContext context, Task task) async {
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
        title: const Text('Delete Task?', style: AppTypography.h2),
        content: Text(
          'Are you sure you want to delete "${task.taskName}"? This cannot be undone.',
          style: AppTypography.body,
        ),
        actions: [
          OutlinedButton(
            key: const Key('cancel_delete_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              side: const BorderSide(
                color: AppColors.border,
                width: AppTheme.borderWidth,
              ),
            ),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                side: const BorderSide(
                  color: AppColors.border,
                  width: AppTheme.borderWidth,
                ),
              ),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _viewModel.deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Task deleted' : 'Failed to delete task',
            ),
            backgroundColor: AppColors.black,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.tasks.isEmpty) {
            return const BrutalistLoadingIndicator(message: 'Loading tasks...');
          }

          if (_viewModel.errorMessage != null && _viewModel.tasks.isEmpty) {
            return BrutalistErrorView(
              message: _viewModel.errorMessage!,
              onRetry: _viewModel.loadTasks,
            );
          }

          if (_viewModel.tasks.isEmpty) {
            return BrutalistEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No Tasks Yet',
              subtitle: 'Add your academic tasks to get started.',
              actionLabel: 'ADD TASK',
              onAction: () => _navigateToCreateTask(context),
            );
          }

          return RefreshIndicator(
            onRefresh: _viewModel.loadTasks,
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
                        value: '${_viewModel.taskCount}',
                        label: 'TASKS',
                      ),
                      Container(
                        width: 2,
                        height: 36,
                        color: AppColors.border,
                      ),
                      _MetricItem(
                        value:
                            '${_viewModel.totalStudyHours.toStringAsFixed(1)}h',
                        label: 'TOTAL TIME',
                      ),
                      Container(
                        width: 2,
                        height: 36,
                        color: AppColors.border,
                      ),
                      _MetricItem(
                        value: '${_viewModel.totalRequiredBlocks}',
                        label: 'BLOCKS',
                      ),
                    ],
                  ),
                ),

                // ── Task List ──
                ..._viewModel.tasks.map(
                  (task) => TaskCard(
                    key: Key('task_card_${task.id}'),
                    task: task,
                    onEdit: () => _navigateToEditTask(context, task),
                    onDelete: () => _confirmDeleteTask(context, task),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_task_fab'),
        onPressed: () => _navigateToCreateTask(context),
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
          'NEW TASK',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
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
