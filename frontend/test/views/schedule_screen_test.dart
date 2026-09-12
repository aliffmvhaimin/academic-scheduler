import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/task.dart';
import 'package:academic_scheduler/models/schedule.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/schedule_view_model.dart';
import 'package:academic_scheduler/views/schedule_screen.dart';
import 'package:academic_scheduler/views/schedule_detail_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:academic_scheduler/models/free_slot.dart';
import 'package:academic_scheduler/services/api_client.dart';
import 'package:academic_scheduler/widgets/empty_state.dart';
import 'package:academic_scheduler/widgets/loading_indicator.dart';
import 'package:academic_scheduler/widgets/error_view.dart';
import 'package:academic_scheduler/widgets/schedule_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;
  late ScheduleViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
    viewModel = ScheduleViewModel(repository: repository);
  });

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildScreenWidget() {
    return MaterialApp(
      home: ScheduleScreen(viewModel: viewModel),
    );
  }

  group('ScheduleScreen - Empty State', () {
    testWidgets('renders BrutalistEmptyState when no schedule is generated',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BrutalistEmptyState), findsOneWidget);
      expect(find.text('No Schedule Generated'), findsOneWidget);
      expect(find.text('GENERATE SCHEDULE'), findsOneWidget);
    });
  });

  group('ScheduleScreen - Infeasible State (FR10)', () {
    testWidgets('renders diagnostics deficit and dismiss button when schedule is infeasible',
        (WidgetTester tester) async {
      setTallViewport(tester);
      final infeasibleResult = ScheduleResult(
        success: true,
        feasible: false,
        fitnessScore: null,
        generationCount: 200,
        executionTimeMs: 215,
        schedule: const [],
        diagnostics: {
          'required_hours': 10,
          'available_hours_before_deadline': 2,
          'shortfall_hours': 8,
        },
      );
      await viewModel.setScheduleResult(infeasibleResult);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      // Empty state should NOT be visible
      expect(find.byType(BrutalistEmptyState), findsNothing);

      // Infeasible warning header
      expect(find.text('INFEASIBLE SCHEDULE'), findsOneWidget);
      expect(find.text('DEFICIT DIAGNOSTICS'), findsOneWidget);
      expect(find.text('10 hours'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);
      expect(find.text('8 hours'), findsOneWidget);
      expect(find.text('RECOMMENDED ACTIONS'), findsOneWidget);

      // Dismiss button returns to empty state
      final dismissBtn = find.byKey(const Key('clear_infeasible_button'));
      expect(dismissBtn, findsOneWidget);
      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      expect(find.byType(BrutalistEmptyState), findsOneWidget);
    });
  });

  group('ScheduleScreen - Feasible Timeline & Block Rendering', () {
    testWidgets('renders timeline banner, session cards, and daily groups',
        (WidgetTester tester) async {
      setTallViewport(tester);

      final task1 = Task(
        id: 't-100',
        taskName: 'Advanced Operating Systems',
        creditWeight: 4,
        difficultyScore: 8,
        deadline: DateTime(2026, 8, 28, 23, 59),
        studyDurationHours: 1.0,
      );

      final blocks = [
        ScheduleBlock(
          taskId: 't-100',
          start: DateTime(2026, 8, 25, 9, 0),
          end: DateTime(2026, 8, 25, 9, 15),
        ),
        ScheduleBlock(
          taskId: 't-100',
          start: DateTime(2026, 8, 25, 9, 15),
          end: DateTime(2026, 8, 25, 9, 30),
        ),
        ScheduleBlock(
          taskId: 't-100',
          start: DateTime(2026, 8, 25, 9, 30),
          end: DateTime(2026, 8, 25, 9, 45),
        ),
        ScheduleBlock(
          taskId: 't-100',
          start: DateTime(2026, 8, 25, 9, 45),
          end: DateTime(2026, 8, 25, 10, 0),
        ),
      ];

      final result = ScheduleResult(
        success: true,
        feasible: true,
        fitnessScore: 0.92,
        generationCount: 140,
        executionTimeMs: 198,
        schedule: blocks,
      );

      await viewModel.setScheduleResult(result, tasks: [task1]);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      // Summary Banner metrics
      expect(find.text('FEASIBLE SCHEDULE'), findsOneWidget);
      expect(find.text('TOTAL STUDY'), findsOneWidget);
      expect(find.text('1.0h'), findsAtLeastNWidgets(1));
      expect(find.text('BLOCKS (15M)'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('STUDY DAYS'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('198ms • 140 gens'), findsOneWidget);

      // Daily header
      expect(find.text('Tuesday, 25 Aug 2026'), findsOneWidget);

      // ScheduleCard
      expect(find.byType(ScheduleCard), findsOneWidget);
      expect(find.text('Advanced Operating Systems'), findsOneWidget);
      expect(find.text('09:00 – 10:00'), findsOneWidget);
      expect(find.text('1.0h • 4 blocks'), findsOneWidget);
      expect(find.text('4 CREDITS'), findsOneWidget);
      expect(find.text('DIFF: 8/10'), findsOneWidget);
    });

    testWidgets('tapping ScheduleCard opens ScheduleDetailDialog with full metadata',
        (WidgetTester tester) async {
      setTallViewport(tester);

      final task1 = Task(
        id: 't-200',
        taskName: 'Distributed Systems',
        creditWeight: 5,
        difficultyScore: 9,
        deadline: DateTime(2026, 8, 30, 18, 0),
        studyDurationHours: 1.5,
      );

      final blocks = [
        ScheduleBlock(
          taskId: 't-200',
          start: DateTime(2026, 8, 26, 14, 0),
          end: DateTime(2026, 8, 26, 14, 30),
        ),
      ];

      final result = ScheduleResult(
        success: true,
        feasible: true,
        fitnessScore: 0.89,
        generationCount: 110,
        executionTimeMs: 160,
        schedule: blocks,
      );

      await viewModel.setScheduleResult(result, tasks: [task1]);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      // Tap on the ScheduleCard
      await tester.tap(find.byType(ScheduleCard));
      await tester.pumpAndSettle();

      // Verify ScheduleDetailDialog is displayed
      expect(find.byType(ScheduleDetailDialog), findsOneWidget);
      expect(find.text('Schedule Detail'), findsOneWidget);
      expect(find.text('Distributed Systems'), findsAtLeastNWidgets(1));
      expect(find.text('TASK ID: t-200'), findsOneWidget);
      expect(find.text('SCHEDULED WINDOW'), findsOneWidget);
      expect(find.text('DEADLINE INFORMATION'), findsOneWidget);
      expect(find.text('Valid (Scheduled before deadline)'), findsOneWidget);
      expect(find.text('PRIORITY CONTRIBUTION'), findsOneWidget);
      expect(find.text('5 / 6 credits'), findsOneWidget);
      expect(find.text('9 / 10 difficulty'), findsOneWidget);

      // Close dialog
      final closeBtn = find.byKey(const Key('close_detail_button'));
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleDetailDialog), findsNothing);
    });

    testWidgets('clear schedule button clears timeline and returns to empty state',
        (WidgetTester tester) async {
      setTallViewport(tester);

      final block = ScheduleBlock(
        taskId: 't-1',
        start: DateTime(2026, 8, 25, 9, 0),
        end: DateTime(2026, 8, 25, 9, 15),
      );
      final result = ScheduleResult(
        success: true,
        feasible: true,
        fitnessScore: 0.9,
        generationCount: 50,
        executionTimeMs: 100,
        schedule: [block],
      );
      await viewModel.setScheduleResult(result);

      await tester.pumpWidget(buildScreenWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleCard), findsOneWidget);

      // Tap clear icon button
      final clearBtn = find.byKey(const Key('clear_schedule_button'));
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleCard), findsNothing);
      expect(find.byType(BrutalistEmptyState), findsOneWidget);
    });
  });

  group('ScheduleScreen - Loading State', () {
    testWidgets('renders BrutalistLoadingIndicator when viewModel is computing',
        (WidgetTester tester) async {
      // Create a mock client with Completer so we control when it responds
      final completer = Completer<http.Response>();
      final mockClient = MockClient((request) => completer.future);
      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      await repository.saveTasks([
        Task(
          id: 't1',
          taskName: 'Task',
          creditWeight: 3,
          difficultyScore: 5,
          deadline: DateTime(2026, 9, 1),
          studyDurationHours: 1.0,
        ),
      ]);
      await repository.saveFreeSlots([
        const FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00'),
      ]);

      // Trigger generate in background
      final genFuture = vm.generateSchedule();

      await tester.pumpWidget(MaterialApp(home: ScheduleScreen(viewModel: vm)));
      // Pump once without settling (since BrutalistLoadingIndicator has infinite animation)
      await tester.pump();

      expect(find.byType(BrutalistLoadingIndicator), findsOneWidget);
      expect(find.text('Computing schedule with Genetic Algorithm...'), findsOneWidget);

      // Complete the response to clear all async operations and timeout timers
      completer.complete(http.Response(
        '{"success": true, "feasible": true, "fitness_score": 0.9, "generation_count": 10, "execution_time_ms": 50, "schedule": []}',
        200,
        headers: {'content-type': 'application/json'},
      ));
      await genFuture;
      await tester.pumpAndSettle();
    });
  });

  group('ScheduleScreen - Network Error State', () {
    testWidgets('renders BrutalistErrorView when network failure occurs',
        (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });
      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      await repository.saveTasks([
        Task(
          id: 't1',
          taskName: 'Task',
          creditWeight: 3,
          difficultyScore: 5,
          deadline: DateTime(2026, 9, 1),
          studyDurationHours: 1.0,
        ),
      ]);
      await repository.saveFreeSlots([
        const FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00'),
      ]);

      await vm.generateSchedule();

      await tester.pumpWidget(MaterialApp(home: ScheduleScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      expect(find.byType(BrutalistErrorView), findsOneWidget);
      expect(find.textContaining('Network failure'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
    });
  });
}
