/// Schedule ViewModel managing generated schedule state, timeline grouping,
/// infeasible diagnostics, and API schedule generation / recalculation.
///
/// Follows AGENTS.md §9 (MVVM architecture, separating UI from scheduling logic).
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/free_slot.dart';
import '../models/schedule.dart';
import '../repositories/local_storage_repository.dart';
import '../services/api_client.dart';

/// Represents a grouped contiguous study session of 15-minute blocks for a single task.
class ContiguousStudySession {
  final String taskId;
  final DateTime start;
  final DateTime end;
  final List<ScheduleBlock> blocks;

  const ContiguousStudySession({
    required this.taskId,
    required this.start,
    required this.end,
    required this.blocks,
  });

  double get durationHours => end.difference(start).inMinutes / 60.0;
  int get blockCount => blocks.length;

  String get startTimeFormatted =>
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  String get endTimeFormatted =>
      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  String get timeRangeFormatted => '$startTimeFormatted – $endTimeFormatted';
}

/// Metadata explaining why a task was prioritized in the schedule (GA soft objectives).
class PriorityContribution {
  final Task task;
  final ScheduleBlock block;
  final String urgencyLevel;
  final double hoursBeforeDeadline;
  final bool isBeforeDeadline;
  final int allocatedBlocks;
  final int requiredBlocks;

  const PriorityContribution({
    required this.task,
    required this.block,
    required this.urgencyLevel,
    required this.hoursBeforeDeadline,
    required this.isBeforeDeadline,
    required this.allocatedBlocks,
    required this.requiredBlocks,
  });
}

class ScheduleViewModel extends ChangeNotifier {
  final LocalStorageRepository repository;
  final ApiClient apiClient;

  List<ScheduleBlock> _blocks = [];
  ScheduleResult? _scheduleResult;
  Map<String, Task> _taskMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInfeasible = false;
  Map<String, dynamic>? _diagnostics;
  List<ScheduleBlock> _missedBlocks = [];
  List<String> _completedTaskIds = [];

  ScheduleViewModel({
    LocalStorageRepository? repository,
    ApiClient? apiClient,
  })  : repository = repository ?? LocalStorageRepository(),
        apiClient = apiClient ?? ApiClient.defaultClient();

  // ── State Getters ──

  List<ScheduleBlock> get blocks => List.unmodifiable(_blocks);
  ScheduleResult? get scheduleResult => _scheduleResult;
  Map<String, Task> get taskMap => Map.unmodifiable(_taskMap);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInfeasible => _isInfeasible;
  Map<String, dynamic>? get diagnostics => _diagnostics;
  List<ScheduleBlock> get missedBlocks => List.unmodifiable(_missedBlocks);
  List<String> get completedTaskIds => List.unmodifiable(_completedTaskIds);

  int get totalScheduledBlocks => _blocks.length;
  double get totalScheduledHours => _blocks.length * 0.25;

  bool get hasSchedule => _blocks.isNotEmpty;

  /// Unique dates with scheduled blocks, sorted chronologically.
  List<String> get uniqueDates {
    final dates = _blocks.map((b) => b.date).toSet().toList();
    dates.sort();
    return dates;
  }

  /// Blocks grouped by date string (YYYY-MM-DD), sorted by start time.
  Map<String, List<ScheduleBlock>> get groupedByDate {
    final map = <String, List<ScheduleBlock>>{};
    for (final block in _blocks) {
      map.putIfAbsent(block.date, () => []).add(block);
    }
    for (final dayBlocks in map.values) {
      dayBlocks.sort((a, b) => a.start.compareTo(b.start));
    }
    return map;
  }

  /// Contiguous study sessions grouped by date string.
  Map<String, List<ContiguousStudySession>> get contiguousSessionsByDate {
    final map = <String, List<ContiguousStudySession>>{};
    final grouped = groupedByDate;

    for (final entry in grouped.entries) {
      final date = entry.key;
      final dayBlocks = entry.value;
      if (dayBlocks.isEmpty) continue;

      final sessions = <ContiguousStudySession>[];
      var currentSessionBlocks = <ScheduleBlock>[dayBlocks.first];

      for (var i = 1; i < dayBlocks.length; i++) {
        final current = dayBlocks[i];
        final previous = currentSessionBlocks.last;

        // Merge if contiguous in time and for the same task
        if (current.taskId == previous.taskId &&
            current.start.isAtSameMomentAs(previous.end)) {
          currentSessionBlocks.add(current);
        } else {
          sessions.add(ContiguousStudySession(
            taskId: previous.taskId,
            start: currentSessionBlocks.first.start,
            end: currentSessionBlocks.last.end,
            blocks: List.from(currentSessionBlocks),
          ));
          currentSessionBlocks = [current];
        }
      }

      if (currentSessionBlocks.isNotEmpty) {
        sessions.add(ContiguousStudySession(
          taskId: currentSessionBlocks.first.taskId,
          start: currentSessionBlocks.first.start,
          end: currentSessionBlocks.last.end,
          blocks: List.from(currentSessionBlocks),
        ));
      }

      map[date] = sessions;
    }

    return map;
  }

  /// Look up task metadata by taskId.
  Task? getTask(String taskId) => _taskMap[taskId];

  /// Get all scheduled blocks for a given task.
  List<ScheduleBlock> getBlocksForTask(String taskId) =>
      _blocks.where((b) => b.taskId == taskId).toList();

  /// Total hours scheduled for a given task.
  double getScheduledHoursForTask(String taskId) =>
      getBlocksForTask(taskId).length * 0.25;

  /// Computes priority contribution and urgency metadata for a scheduled block.
  PriorityContribution? getPriorityContribution(ScheduleBlock block) {
    final task = _taskMap[block.taskId];
    if (task == null) return null;

    final hoursBeforeDeadline =
        task.deadline.difference(block.end).inMinutes / 60.0;
    final isBefore = hoursBeforeDeadline >= 0;

    String urgencyLevel;
    if (!isBefore) {
      urgencyLevel = 'Overdue (Violation)';
    } else if (hoursBeforeDeadline <= 24) {
      urgencyLevel = 'Critical (< 24h)';
    } else if (hoursBeforeDeadline <= 48) {
      urgencyLevel = 'Urgent (< 48h)';
    } else if (hoursBeforeDeadline <= 120) {
      urgencyLevel = 'High (< 5 days)';
    } else {
      urgencyLevel = 'Normal';
    }

    final allocated = getBlocksForTask(task.id).length;

    return PriorityContribution(
      task: task,
      block: block,
      urgencyLevel: urgencyLevel,
      hoursBeforeDeadline: hoursBeforeDeadline,
      isBeforeDeadline: isBefore,
      allocatedBlocks: allocated,
      requiredBlocks: task.requiredBlocks,
    );
  }

  // ── Load & Mutation ──

  /// Load existing schedule and task list from repository.
  Future<void> loadSchedule() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedTasks = await repository.loadTasks();
      _taskMap = {for (final t in loadedTasks) t.id: t};

      final loadedBlocks = await repository.loadScheduleBlocks();
      _sortBlocks(loadedBlocks);
      _blocks = loadedBlocks;

      _missedBlocks = await repository.loadMissedBlocks();
      _completedTaskIds = await repository.loadCompletedTaskIds();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load schedule: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Directly set a schedule result (used by tests or direct API consumers).
  Future<void> setScheduleResult(
    ScheduleResult result, {
    List<Task>? tasks,
  }) async {
    if (tasks != null) {
      _taskMap = {for (final t in tasks) t.id: t};
      await repository.saveTasks(tasks);
    }

    _scheduleResult = result;

    if (result.feasible) {
      _isInfeasible = false;
      _diagnostics = null;
      _sortBlocks(result.schedule);
      _blocks = List.from(result.schedule);
      await repository.saveScheduleBlocks(_blocks);
    } else {
      _isInfeasible = true;
      _diagnostics = result.diagnostics;
      _blocks = [];
      await repository.saveScheduleBlocks([]);
    }

    _errorMessage = null;
    notifyListeners();
  }

  /// Generate schedule by pulling active tasks and availability from storage,
  /// then dispatching to the scheduling backend API.
  Future<bool> generateSchedule() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tasks = await repository.loadTasks();
      if (tasks.isEmpty) {
        _errorMessage = 'No tasks found. Add tasks before generating a schedule.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final freeSlots = await repository.loadFreeSlots();
      if (freeSlots.isEmpty) {
        _errorMessage =
            'No availability configured. Define your study periods first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _taskMap = {for (final t in tasks) t.id: t};

      final result = await apiClient.generateSchedule(
        tasks: tasks,
        freeSlots: freeSlots,
      );

      await setScheduleResult(result, tasks: tasks);
      _isLoading = false;
      notifyListeners();
      return result.feasible;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Schedule generation failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Recalculate schedule with current tasks and availability.
  Future<bool> recalculateSchedule({
    List<ScheduleBlock>? missedBlocks,
    List<String>? completedTaskIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tasks = await repository.loadTasks();
      final freeSlots = await repository.loadFreeSlots();

      if (tasks.isEmpty || freeSlots.isEmpty) {
        _errorMessage = 'Both tasks and availability are required to recalculate.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _taskMap = {for (final t in tasks) t.id: t};

      final effectiveMissed = missedBlocks ?? await repository.loadMissedBlocks();
      _missedBlocks = effectiveMissed;

      final effectiveCompletedIds = completedTaskIds ??
          await repository.loadCompletedTaskIds();
      _completedTaskIds = effectiveCompletedIds;

      final result = await apiClient.recalculateSchedule(
        tasks: tasks,
        freeSlots: freeSlots,
        missedBlocks: effectiveMissed,
        completedTaskIds: effectiveCompletedIds,
      );

      await setScheduleResult(result, tasks: tasks);
      _isLoading = false;
      notifyListeners();
      return result.feasible;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Schedule recalculation failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark an entire session's blocks as missed, update local storage, and dynamically recalculate.
  Future<bool> markSessionMissed(ContiguousStudySession session) async {
    final current = await repository.loadMissedBlocks();
    final updated = List<ScheduleBlock>.from(current)..addAll(session.blocks);
    await repository.saveMissedBlocks(updated);
    _missedBlocks = updated;
    return recalculateSchedule(missedBlocks: updated);
  }

  /// Mark a single block as missed, update local storage, and dynamically recalculate.
  Future<bool> markBlockMissed(ScheduleBlock block) async {
    final current = await repository.loadMissedBlocks();
    final updated = List<ScheduleBlock>.from(current)..add(block);
    await repository.saveMissedBlocks(updated);
    _missedBlocks = updated;
    return recalculateSchedule(missedBlocks: updated);
  }

  /// Mark a task as completed, update local storage, and dynamically recalculate.
  Future<bool> markTaskCompleted(String taskId) async {
    final current = await repository.loadCompletedTaskIds();
    if (!current.contains(taskId)) {
      final updated = List<String>.from(current)..add(taskId);
      await repository.saveCompletedTaskIds(updated);
      _completedTaskIds = updated;
      return recalculateSchedule(completedTaskIds: updated);
    }
    return recalculateSchedule();
  }

  /// Clear recorded missed blocks history and reset.
  Future<void> clearMissedBlocks() async {
    await repository.saveMissedBlocks([]);
    _missedBlocks = [];
    notifyListeners();
  }

  /// Clear current schedule.
  Future<void> clearSchedule() async {
    _blocks = [];
    _scheduleResult = null;
    _isInfeasible = false;
    _diagnostics = null;
    _errorMessage = null;
    await repository.saveScheduleBlocks([]);
    notifyListeners();
  }

  static void _sortBlocks(List<ScheduleBlock> list) {
    list.sort((a, b) => a.start.compareTo(b.start));
  }
}
