/// Task ViewModel managing task list state, business logic, and local persistence.
///
/// Follows AGENTS.md §9 (keep business logic outside widgets, separate MVVM layers).
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../repositories/local_storage_repository.dart';

class TaskViewModel extends ChangeNotifier {
  final LocalStorageRepository repository;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  TaskViewModel({LocalStorageRepository? repository})
      : repository = repository ?? LocalStorageRepository();

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get taskCount => _tasks.length;

  /// Total study hours required across all active tasks.
  double get totalStudyHours =>
      _tasks.fold(0.0, (sum, t) => sum + t.studyDurationHours);

  /// Total 15-minute study blocks required across all active tasks.
  int get totalRequiredBlocks =>
      _tasks.fold(0, (sum, t) => sum + t.requiredBlocks);

  /// Load tasks from local persistence.
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await repository.loadTasks();
      // Sort tasks by deadline ascending (earliest deadline first)
      loaded.sort((a, b) => a.deadline.compareTo(b.deadline));
      _tasks = loaded;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new task and persist to local storage.
  Future<bool> addTask(Task task) async {
    try {
      _tasks = [..._tasks, task]..sort((a, b) => a.deadline.compareTo(b.deadline));
      await repository.saveTasks(_tasks);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing task by ID and persist changes.
  Future<bool> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      _errorMessage = 'Task with ID ${task.id} not found';
      notifyListeners();
      return false;
    }

    try {
      final updatedList = List<Task>.from(_tasks);
      updatedList[index] = task;
      updatedList.sort((a, b) => a.deadline.compareTo(b.deadline));
      _tasks = updatedList;
      await repository.saveTasks(_tasks);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a task by ID and update local storage.
  Future<bool> deleteTask(String id) async {
    try {
      _tasks = _tasks.where((t) => t.id != id).toList();
      await repository.saveTasks(_tasks);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Find a task by its unique ID.
  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Validation Helpers ──

  /// Validates task name according to PROJECT_SPEC.md §2 and backend rules.
  static String? validateTaskName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task name is required';
    }
    if (value.trim().length > 200) {
      return 'Task name cannot exceed 200 characters';
    }
    return null;
  }

  /// Validates study duration in hours (positive number).
  static String? validateStudyDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Study duration is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number (e.g. 2.0)';
    }
    if (parsed <= 0.0) {
      return 'Duration must be greater than 0 hours';
    }
    if (parsed > 100.0) {
      return 'Duration must be 100 hours or less';
    }
    return null;
  }

  /// Validates course credit weight (1 to 6).
  static String? validateCreditWeight(int weight) {
    if (weight < 1 || weight > 6) {
      return 'Credit weight must be between 1 and 6';
    }
    return null;
  }

  /// Validates perceived task difficulty score (1 to 10).
  static String? validateDifficulty(int difficulty) {
    if (difficulty < 1 || difficulty > 10) {
      return 'Difficulty score must be between 1 and 10';
    }
    return null;
  }

  /// Validates task deadline.
  static String? validateDeadline(DateTime? deadline) {
    if (deadline == null) {
      return 'Deadline date and time is required';
    }
    return null;
  }
}
