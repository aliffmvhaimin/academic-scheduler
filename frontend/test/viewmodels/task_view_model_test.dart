import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/task.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/task_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;
  late TaskViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
    viewModel = TaskViewModel(repository: repository);
  });

  group('TaskViewModel - Initialization and Load', () {
    test('initial state is empty and not loading', () {
      expect(viewModel.tasks, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.taskCount, 0);
      expect(viewModel.totalStudyHours, 0.0);
      expect(viewModel.totalRequiredBlocks, 0);
    });

    test('loadTasks populates tasks sorted by deadline', () async {
      final t1 = Task(
        id: 't1',
        taskName: 'Later Task',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 9, 10, 12, 0),
        studyDurationHours: 2.0,
      );
      final t2 = Task(
        id: 't2',
        taskName: 'Earlier Task',
        creditWeight: 4,
        difficultyScore: 7,
        deadline: DateTime(2026, 8, 20, 10, 0),
        studyDurationHours: 1.5,
      );

      await repository.saveTasks([t1, t2]);
      await viewModel.loadTasks();

      expect(viewModel.tasks.length, 2);
      // t2 should be first due to earlier deadline
      expect(viewModel.tasks.first.id, 't2');
      expect(viewModel.tasks.last.id, 't1');
      expect(viewModel.totalStudyHours, 3.5);
      expect(viewModel.totalRequiredBlocks, 14); // 6 + 8
    });
  });

  group('TaskViewModel - CRUD Operations', () {
    test('addTask persists and notifies', () async {
      final task = Task(
        id: 'task-100',
        taskName: 'Physics Homework',
        creditWeight: 3,
        difficultyScore: 6,
        deadline: DateTime(2026, 8, 30, 23, 59),
        studyDurationHours: 2.5,
      );

      final result = await viewModel.addTask(task);
      expect(result, true);
      expect(viewModel.taskCount, 1);
      expect(viewModel.tasks.first.id, 'task-100');

      // Verify persisted in repository
      final loaded = await repository.loadTasks();
      expect(loaded.length, 1);
      expect(loaded.first.taskName, 'Physics Homework');
    });

    test('updateTask replaces matching task and persists', () async {
      final task = Task(
        id: 'task-100',
        taskName: 'Original Name',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 8, 30),
        studyDurationHours: 2.0,
      );
      await viewModel.addTask(task);

      final updatedTask = task.copyWith(
        taskName: 'Updated Name',
        difficultyScore: 9,
      );
      final result = await viewModel.updateTask(updatedTask);

      expect(result, true);
      expect(viewModel.tasks.first.taskName, 'Updated Name');
      expect(viewModel.tasks.first.difficultyScore, 9);

      final loaded = await repository.loadTasks();
      expect(loaded.first.taskName, 'Updated Name');
    });

    test('updateTask fails gracefully for non-existent ID', () async {
      final nonExistent = Task(
        id: 'does-not-exist',
        taskName: 'Fake',
        creditWeight: 1,
        difficultyScore: 1,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 1.0,
      );

      final result = await viewModel.updateTask(nonExistent);
      expect(result, false);
      expect(viewModel.errorMessage, isNotNull);
    });

    test('deleteTask removes task and persists', () async {
      final t1 = Task(
        id: 't1',
        taskName: 'Task 1',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 8, 30),
        studyDurationHours: 1.0,
      );
      final t2 = Task(
        id: 't2',
        taskName: 'Task 2',
        creditWeight: 4,
        difficultyScore: 6,
        deadline: DateTime(2026, 8, 31),
        studyDurationHours: 2.0,
      );
      await viewModel.addTask(t1);
      await viewModel.addTask(t2);
      expect(viewModel.taskCount, 2);

      final result = await viewModel.deleteTask('t1');
      expect(result, true);
      expect(viewModel.taskCount, 1);
      expect(viewModel.tasks.first.id, 't2');

      final loaded = await repository.loadTasks();
      expect(loaded.length, 1);
      expect(loaded.first.id, 't2');
    });

    test('getTaskById returns task or null', () async {
      final task = Task(
        id: 'find-me',
        taskName: 'Findable',
        creditWeight: 2,
        difficultyScore: 3,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 1.0,
      );
      await viewModel.addTask(task);

      expect(viewModel.getTaskById('find-me'), isNotNull);
      expect(viewModel.getTaskById('find-me')!.taskName, 'Findable');
      expect(viewModel.getTaskById('missing'), isNull);
    });
  });

  group('TaskViewModel - Validation Helpers', () {
    test('validateTaskName', () {
      expect(TaskViewModel.validateTaskName(null), isNotNull);
      expect(TaskViewModel.validateTaskName(''), isNotNull);
      expect(TaskViewModel.validateTaskName('   '), isNotNull);
      expect(TaskViewModel.validateTaskName('a' * 201), isNotNull);
      expect(TaskViewModel.validateTaskName('Calculus Assignment 1'), isNull);
    });

    test('validateStudyDuration', () {
      expect(TaskViewModel.validateStudyDuration(null), isNotNull);
      expect(TaskViewModel.validateStudyDuration(''), isNotNull);
      expect(TaskViewModel.validateStudyDuration('abc'), isNotNull);
      expect(TaskViewModel.validateStudyDuration('0'), isNotNull);
      expect(TaskViewModel.validateStudyDuration('-1.5'), isNotNull);
      expect(TaskViewModel.validateStudyDuration('101'), isNotNull);
      expect(TaskViewModel.validateStudyDuration('2.0'), isNull);
      expect(TaskViewModel.validateStudyDuration('0.5'), isNull);
    });

    test('validateCreditWeight', () {
      expect(TaskViewModel.validateCreditWeight(0), isNotNull);
      expect(TaskViewModel.validateCreditWeight(7), isNotNull);
      expect(TaskViewModel.validateCreditWeight(1), isNull);
      expect(TaskViewModel.validateCreditWeight(6), isNull);
      expect(TaskViewModel.validateCreditWeight(3), isNull);
    });

    test('validateDifficulty', () {
      expect(TaskViewModel.validateDifficulty(0), isNotNull);
      expect(TaskViewModel.validateDifficulty(11), isNotNull);
      expect(TaskViewModel.validateDifficulty(1), isNull);
      expect(TaskViewModel.validateDifficulty(10), isNull);
      expect(TaskViewModel.validateDifficulty(5), isNull);
    });

    test('validateDeadline', () {
      expect(TaskViewModel.validateDeadline(null), isNotNull);
      expect(TaskViewModel.validateDeadline(DateTime(2026, 9, 1)), isNull);
    });
  });
}
