/// Placeholder screen for Schedule View (Phase 9 implementation).
import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrutalistEmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'No Schedule Generated',
      subtitle: 'Add tasks and availability, then generate your study schedule.',
    );
  }
}
