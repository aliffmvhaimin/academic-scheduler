import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/task.dart';
import 'package:academic_scheduler/models/free_slot.dart';
import 'package:academic_scheduler/models/schedule.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
  });

  group('LocalStorageRepository - Tasks', () {
    test('saveTasks and loadTasks', () async {
      final tasks = [
        Task(
          id: 'task-1',
          taskName: 'Math',
          creditWeight: 3,
          difficultyScore: 5,
          deadline: DateTime(2026, 8, 30, 12, 0),
          studyDurationHours: 2.0,
        ),
        Task(
          id: 'task-2',
          taskName: 'Physics',
          creditWeight: 4,
          difficultyScore: 7,
          deadline: DateTime(2026, 8, 31, 15, 0),
          studyDurationHours: 3.5,
        ),
      ];

      await repository.saveTasks(tasks);
      final loaded = await repository.loadTasks();

      expect(loaded.length, 2);
      expect(loaded[0].id, 'task-1');
      expect(loaded[0].taskName, 'Math');
      expect(loaded[1].id, 'task-2');
      expect(loaded[1].studyDurationHours, 3.5);
    });

    test('loadTasks returns empty list when no data', () async {
      final loaded = await repository.loadTasks();
      expect(loaded, isEmpty);
    });
  });

  group('LocalStorageRepository - Free Slots', () {
    test('saveFreeSlots and loadFreeSlots', () async {
      const slots = [
        FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00'),
        FreeSlot(date: '2026-08-26', start: '14:00', end: '17:00'),
      ];

      await repository.saveFreeSlots(slots);
      final loaded = await repository.loadFreeSlots();

      expect(loaded.length, 2);
      expect(loaded[0], equals(slots[0]));
      expect(loaded[1], equals(slots[1]));
    });

    test('loadFreeSlots returns empty list when no data', () async {
      final loaded = await repository.loadFreeSlots();
      expect(loaded, isEmpty);
    });
  });

  group('LocalStorageRepository - Schedule', () {
    test('saveScheduleBlocks and loadScheduleBlocks', () async {
      final blocks = [
        ScheduleBlock(
          taskId: 'task-1',
          start: DateTime(2026, 8, 25, 9, 0),
          end: DateTime(2026, 8, 25, 9, 15),
        ),
        ScheduleBlock(
          taskId: 'task-1',
          start: DateTime(2026, 8, 25, 9, 15),
          end: DateTime(2026, 8, 25, 9, 30),
        ),
      ];

      await repository.saveScheduleBlocks(blocks);
      final loaded = await repository.loadScheduleBlocks();

      expect(loaded.length, 2);
      expect(loaded[0].taskId, 'task-1');
      expect(loaded[0], equals(blocks[0]));
      expect(loaded[1], equals(blocks[1]));
    });

    test('saveScheduleResult saves blocks correctly', () async {
      final result = ScheduleResult(
        success: true,
        feasible: true,
        fitnessScore: 92.0,
        generationCount: 100,
        executionTimeMs: 150,
        schedule: [
          ScheduleBlock(
            taskId: 't1',
            start: DateTime(2026, 8, 25, 10, 0),
            end: DateTime(2026, 8, 25, 10, 15),
          ),
        ],
      );

      await repository.saveScheduleResult(result);
      final loaded = await repository.loadScheduleBlocks();

      expect(loaded.length, 1);
      expect(loaded[0].taskId, 't1');
    });

    test('loadScheduleBlocks returns empty list when no data', () async {
      final loaded = await repository.loadScheduleBlocks();
      expect(loaded, isEmpty);
    });
  });

  group('LocalStorageRepository - Completed Tasks', () {
    test('saveCompletedTaskIds and loadCompletedTaskIds', () async {
      final ids = ['task-1', 'task-3'];

      await repository.saveCompletedTaskIds(ids);
      final loaded = await repository.loadCompletedTaskIds();

      expect(loaded, equals(['task-1', 'task-3']));
    });

    test('loadCompletedTaskIds returns empty list when none stored', () async {
      final loaded = await repository.loadCompletedTaskIds();
      expect(loaded, isEmpty);
    });
  });

  group('LocalStorageRepository - clearAll', () {
    test('clears all keys', () async {
      await repository.saveTasks([
        Task(
          id: 't1',
          taskName: 'Math',
          creditWeight: 1,
          difficultyScore: 1,
          deadline: DateTime(2026, 9, 1),
          studyDurationHours: 1.0,
        ),
      ]);
      await repository.saveFreeSlots([
        const FreeSlot(date: '2026-08-25', start: '09:00', end: '10:00'),
      ]);
      await repository.saveCompletedTaskIds(['t1']);

      await repository.clearAll();

      expect(await repository.loadTasks(), isEmpty);
      expect(await repository.loadFreeSlots(), isEmpty);
      expect(await repository.loadScheduleBlocks(), isEmpty);
      expect(await repository.loadCompletedTaskIds(), isEmpty);
    });
  });
}
