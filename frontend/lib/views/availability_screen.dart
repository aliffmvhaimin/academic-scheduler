/// Placeholder screen for Availability setup (Phase 8 implementation).
import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrutalistEmptyState(
      icon: Icons.access_time_outlined,
      title: 'No Availability Set',
      subtitle: 'Define your available study periods for scheduling.',
      actionLabel: 'SET AVAILABILITY',
    );
  }
}
