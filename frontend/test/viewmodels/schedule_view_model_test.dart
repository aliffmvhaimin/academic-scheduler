import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/task.dart';
import 'package:academic_scheduler/models/free_slot.dart';
import 'package:academic_scheduler/models/schedule.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/schedule_view_model.dart';
import 'package:academic_scheduler/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;
  late ScheduleViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
    viewModel = ScheduleViewModel(repository: repository);
  });

  group('ScheduleViewModel - Initialization', () {
    test('initial state is empty and uninitialized', () {
      expect(viewModel.blocks, isEmpty);
      expect(viewModel.hasSchedule, false);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isInfeasible, false);
      expect(viewModel.diagnostics, isNull);
      expect(viewModel.totalScheduledBlocks, 0);
      expect(viewModel.totalScheduledHours, 0.0);
      expect(viewModel.uniqueDates, isEmpty);
      expect(viewModel.groupedByDate, isEmpty);
      expect(viewModel.contiguousSessionsByDate, isEmpty);
    });
  });

  group('ScheduleViewModel - Loading & State Management', () {
    test('loadSchedule populates tasks and blocks from repository', () async {
      final task = Task(
        id: 'task-1',
        taskName: 'Data Structures',
        creditWeight: 4,
        difficultyScore: 8,
        deadline: DateTime(2026, 8, 30, 23, 59),
        studyDurationHours: 1.0,
      );
      final b1 = ScheduleBlock(
        taskId: 'task-1',
        start: DateTime(2026, 8, 25, 9, 0),
        end: DateTime(2026, 8, 25, 9, 15),
      );
      final b2 = ScheduleBlock(
        taskId: 'task-1',
        start: DateTime(2026, 8, 25, 9, 15),
        end: DateTime(2026, 8, 25, 9, 30),
      );

      await repository.saveTasks([task]);
      await repository.saveScheduleBlocks([b2, b1]); // Unsorted

      await viewModel.loadSchedule();

      expect(viewModel.hasSchedule, true);
      expect(viewModel.totalScheduledBlocks, 2);
      expect(viewModel.totalScheduledHours, 0.5);
      expect(viewModel.blocks.first.start, DateTime(2026, 8, 25, 9, 0)); // Sorted
      expect(viewModel.getTask('task-1'), isNotNull);
      expect(viewModel.getTask('task-1')!.taskName, 'Data Structures');
    });

    test('setScheduleResult handles feasible result and merges contiguous sessions', () async {
      final task1 = Task(
        id: 'task-1',
        taskName: 'Calculus III',
        creditWeight: 4,
        difficultyScore: 8,
        deadline: DateTime(2026, 8, 28, 12, 0),
        studyDurationHours: 1.0,
      );

      final blocks = [
        ScheduleBlock(
          taskId: 'task-1',
          start: DateTime(2026, 8, 25, 10, 0),
          end: DateTime(2026, 8, 25, 10, 15),
        ),
        ScheduleBlock(
          taskId: 'task-1',
          start: DateTime(2026, 8, 25, 10, 15),
          end: DateTime(2026, 8, 25, 10, 30),
        ),
        ScheduleBlock(
          taskId: 'task-1',
          start: DateTime(2026, 8, 25, 10, 30),
          end: DateTime(2026, 8, 25, 10, 45),
        ),
        ScheduleBlock(
          taskId: 'task-1',
          start: DateTime(2026, 8, 25, 10, 45),
          end: DateTime(2026, 8, 25, 11, 0),
        ),
      ];

      final result = ScheduleResult(
        success: true,
        feasible: true,
        fitnessScore: 0.91,
        generationCount: 120,
        executionTimeMs: 185,
        schedule: blocks,
      );

      await viewModel.setScheduleResult(result, tasks: [task1]);

      expect(viewModel.hasSchedule, true);
      expect(viewModel.isInfeasible, false);
      expect(viewModel.diagnostics, isNull);
      expect(viewModel.totalScheduledBlocks, 4);
      expect(viewModel.totalScheduledHours, 1.0);

      // Verify contiguous session merging: 4 contiguous 15-min blocks merged into 1 session of 1 hour
      final sessionsMap = viewModel.contiguousSessionsByDate;
      expect(sessionsMap.containsKey('2026-08-25'), true);
      final sessions = sessionsMap['2026-08-25']!;
      expect(sessions.length, 1);
      expect(sessions.first.durationHours, 1.0);
      expect(sessions.first.blockCount, 4);
      expect(sessions.first.timeRangeFormatted, '10:00 – 11:00');

      // Verify persisted in repository
      final saved = await repository.loadScheduleBlocks();
      expect(saved.length, 4);
    });

    test('setScheduleResult handles infeasible result with diagnostics', () async {
      final result = ScheduleResult(
        success: true,
        feasible: false,
        fitnessScore: null,
        generationCount: 200,
        executionTimeMs: 250,
        schedule: const [],
        diagnostics: {
          'required_hours': 12,
          'available_hours_before_deadline': 4,
          'shortfall_hours': 8,
        },
      );

      await viewModel.setScheduleResult(result);

      expect(viewModel.hasSchedule, false);
      expect(viewModel.isInfeasible, true);
      expect(viewModel.diagnostics, isNotNull);
      expect(viewModel.diagnostics!['shortfall_hours'], 8);

      final saved = await repository.loadScheduleBlocks();
      expect(saved, isEmpty);
    });

    test('clearSchedule resets all state and repository storage', () async {
      final block = ScheduleBlock(
        taskId: 't1',
        start: DateTime(2026, 8, 25, 9, 0),
        end: DateTime(2026, 8, 25, 9, 15),
      );
      await repository.saveScheduleBlocks([block]);
      await viewModel.loadSchedule();
      expect(viewModel.hasSchedule, true);

      await viewModel.clearSchedule();
      expect(viewModel.hasSchedule, false);
      expect(viewModel.blocks, isEmpty);
      expect(viewModel.isInfeasible, false);

      final saved = await repository.loadScheduleBlocks();
      expect(saved, isEmpty);
    });
  });

  group('ScheduleViewModel - Priority Contribution & Urgency', () {
    test('calculates correct priority contribution and urgency ratings', () async {
      final now = DateTime(2026, 8, 25, 9, 0);
      final criticalTask = Task(
        id: 'crit-1',
        taskName: 'Critical Assignment',
        creditWeight: 5,
        difficultyScore: 9,
        deadline: DateTime(2026, 8, 25, 20, 0), // 11 hours away
        studyDurationHours: 2.0,
      );

      viewModel = ScheduleViewModel(repository: repository);
      final b1 = ScheduleBlock(
        taskId: 'crit-1',
        start: now,
        end: DateTime(2026, 8, 25, 9, 15),
      );

      await viewModel.setScheduleResult(
        ScheduleResult(
          success: true,
          feasible: true,
          fitnessScore: 0.88,
          generationCount: 100,
          executionTimeMs: 150,
          schedule: [b1],
        ),
        tasks: [criticalTask],
      );

      final contribution = viewModel.getPriorityContribution(b1);
      expect(contribution, isNotNull);
      expect(contribution!.isBeforeDeadline, true);
      expect(contribution.urgencyLevel, 'Critical (< 24h)');
      expect(contribution.allocatedBlocks, 1);
      expect(contribution.requiredBlocks, 8); // 2.0h * 4
    });

    test('returns null priority contribution if task not found', () {
      final b1 = ScheduleBlock(
        taskId: 'unknown-id',
        start: DateTime(2026, 8, 25, 9, 0),
        end: DateTime(2026, 8, 25, 9, 15),
      );

      final contribution = viewModel.getPriorityContribution(b1);
      expect(contribution, isNull);
    });
  });

  group('ScheduleViewModel - Validation Guards for Generation', () {
    test('generateSchedule returns false with error if no tasks exist', () async {
      // Free slots exist but no tasks
      await repository.saveFreeSlots([
        const FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00'),
      ]);

      final success = await viewModel.generateSchedule();
      expect(success, false);
      expect(viewModel.errorMessage, contains('No tasks found'));
    });

    test('generateSchedule returns false with error if no availability exists', () async {
      // Tasks exist but no free slots
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

      final success = await viewModel.generateSchedule();
      expect(success, false);
      expect(viewModel.errorMessage, contains('No availability configured'));
    });
  });

  group('ScheduleViewModel - End-to-End API Integration', () {
    test('generateSchedule successfully updates state and persists when API returns feasible schedule', () async {
      final task = Task(
        id: 't-api-1',
        taskName: 'Algorithm Design',
        creditWeight: 4,
        difficultyScore: 7,
        deadline: DateTime(2026, 8, 30),
        studyDurationHours: 1.0,
      );
      final slot = const FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00');
      await repository.saveTasks([task]);
      await repository.saveFreeSlots([slot]);

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/schedule');
        final responseData = {
          'success': true,
          'feasible': true,
          'fitness_score': 0.88,
          'generation_count': 95,
          'execution_time_ms': 140,
          'schedule': [
            {
              'task_id': 't-api-1',
              'start': '2026-08-25T09:00:00',
              'end': '2026-08-25T09:15:00',
            },
            {
              'task_id': 't-api-1',
              'start': '2026-08-25T09:15:00',
              'end': '2026-08-25T09:30:00',
            },
          ],
          'diagnostics': null,
        };
        return http.Response(json.encode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      final success = await vm.generateSchedule();

      expect(success, true);
      expect(vm.hasSchedule, true);
      expect(vm.isInfeasible, false);
      expect(vm.totalScheduledBlocks, 2);
      expect(vm.totalScheduledHours, 0.5);
      expect(vm.isLoading, false);

      final saved = await repository.loadScheduleBlocks();
      expect(saved.length, 2);
    });

    test('generateSchedule handles network failure cleanly', () async {
      final task = Task(
        id: 't1',
        taskName: 'Task',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 1.0,
      );
      await repository.saveTasks([task]);
      await repository.saveFreeSlots([const FreeSlot(date: '2026-08-25', start: '09:00', end: '10:00')]);

      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      final success = await vm.generateSchedule();

      expect(success, false);
      expect(vm.hasSchedule, false);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, contains('Network failure'));
    });

    test('generateSchedule handles malformed response cleanly', () async {
      final task = Task(
        id: 't1',
        taskName: 'Task',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 1.0,
      );
      await repository.saveTasks([task]);
      await repository.saveFreeSlots([const FreeSlot(date: '2026-08-25', start: '09:00', end: '10:00')]);

      final mockClient = MockClient((request) async {
        return http.Response('INVALID_JSON_CORRUPTED', 200);
      });

      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      final success = await vm.generateSchedule();

      expect(success, false);
      expect(vm.hasSchedule, false);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, contains('Malformed response'));
    });

    test('generateSchedule handles infeasible API response and populates diagnostics', () async {
      final task = Task(
        id: 't-big',
        taskName: 'Big Task',
        creditWeight: 4,
        difficultyScore: 8,
        deadline: DateTime(2026, 8, 26),
        studyDurationHours: 8.0,
      );
      await repository.saveTasks([task]);
      await repository.saveFreeSlots([const FreeSlot(date: '2026-08-25', start: '09:00', end: '10:00')]);

      final mockClient = MockClient((request) async {
        final infeasibleData = {
          'success': true,
          'feasible': false,
          'fitness_score': null,
          'generation_count': 200,
          'execution_time_ms': 190,
          'schedule': [],
          'diagnostics': {
            'required_hours': 8.0,
            'available_hours_before_deadline': 1.0,
            'shortfall_hours': 7.0,
          },
        };
        return http.Response(json.encode(infeasibleData), 200, headers: {'content-type': 'application/json'});
      });

      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      final success = await vm.generateSchedule();

      expect(success, false);
      expect(vm.hasSchedule, false);
      expect(vm.isInfeasible, true);
      expect(vm.diagnostics, isNotNull);
      expect(vm.diagnostics!['shortfall_hours'], 7.0);
    });

    test('recalculateSchedule automatically includes stored completed task IDs in request', () async {
      final task = Task(
        id: 't1',
        taskName: 'Active Task',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 1.0,
      );
      await repository.saveTasks([task]);
      await repository.saveFreeSlots([const FreeSlot(date: '2026-08-25', start: '09:00', end: '10:00')]);
      await repository.saveCompletedTaskIds(['completed-task-99']);

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/schedule/recalculate');
        final reqBody = json.decode(request.body) as Map<String, dynamic>;
        expect(reqBody['completed_task_ids'], contains('completed-task-99'));

        final resData = {
          'success': true,
          'feasible': true,
          'fitness_score': 0.9,
          'generation_count': 40,
          'execution_time_ms': 80,
          'schedule': [],
          'diagnostics': null,
        };
        return http.Response(json.encode(resData), 200, headers: {'content-type': 'application/json'});
      });

      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      final success = await vm.recalculateSchedule();
      expect(success, true);
    });

    test('markSessionMissed saves blocks to storage and triggers recalculation', () async {
      final task = Task(
        id: 't-missed-1',
        taskName: 'Missed Task',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 1.0,
      );
      await repository.saveTasks([task]);
      await repository.saveFreeSlots([const FreeSlot(date: '2026-08-25', start: '09:00', end: '11:00')]);

      final missedBlock = ScheduleBlock(
        taskId: 't-missed-1',
        start: DateTime(2026, 8, 25, 9, 0),
        end: DateTime(2026, 8, 25, 9, 15),
      );
      final session = ContiguousStudySession(
        taskId: 't-missed-1',
        start: DateTime(2026, 8, 25, 9, 0),
        end: DateTime(2026, 8, 25, 9, 15),
        blocks: [missedBlock],
      );

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/schedule/recalculate');
        final reqBody = json.decode(request.body) as Map<String, dynamic>;
        expect(reqBody['missed_blocks'], isNotEmpty);
        expect(reqBody['missed_blocks'][0]['task_id'], 't-missed-1');

        final resData = {
          'success': true,
          'feasible': true,
          'fitness_score': 0.88,
          'generation_count': 30,
          'execution_time_ms': 75,
          'schedule': [],
          'diagnostics': null,
        };
        return http.Response(json.encode(resData), 200, headers: {'content-type': 'application/json'});
      });

      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      final success = await vm.markSessionMissed(session);
      expect(success, true);
      expect(vm.missedBlocks.length, 1);
      expect(vm.missedBlocks.first.taskId, 't-missed-1');

      final storedMissed = await repository.loadMissedBlocks();
      expect(storedMissed.length, 1);
    });

    test('markTaskCompleted saves completed ID and triggers recalculation', () async {
      final task = Task(
        id: 't-completed-1',
        taskName: 'Done Task',
        creditWeight: 2,
        difficultyScore: 3,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 1.0,
      );
      await repository.saveTasks([task]);
      await repository.saveFreeSlots([const FreeSlot(date: '2026-08-25', start: '09:00', end: '11:00')]);

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/schedule/recalculate');
        final reqBody = json.decode(request.body) as Map<String, dynamic>;
        expect(reqBody['completed_task_ids'], contains('t-completed-1'));

        final resData = {
          'success': true,
          'feasible': true,
          'fitness_score': 0.95,
          'generation_count': 10,
          'execution_time_ms': 40,
          'schedule': [],
          'diagnostics': null,
        };
        return http.Response(json.encode(resData), 200, headers: {'content-type': 'application/json'});
      });

      final api = ApiClient(baseUrl: 'http://localhost:8000/api/v1', client: mockClient);
      final vm = ScheduleViewModel(repository: repository, apiClient: api);

      final success = await vm.markTaskCompleted('t-completed-1');
      expect(success, true);
      expect(vm.completedTaskIds, contains('t-completed-1'));

      final storedCompleted = await repository.loadCompletedTaskIds();
      expect(storedCompleted, contains('t-completed-1'));
    });
  });
}
