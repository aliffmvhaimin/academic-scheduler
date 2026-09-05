/// Placeholder screen for Task Input (Phase 7 implementation).
import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrutalistEmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Tasks Yet',
      subtitle: 'Add your academic tasks to get started.',
      actionLabel: 'ADD TASK',
    );
  }
}
