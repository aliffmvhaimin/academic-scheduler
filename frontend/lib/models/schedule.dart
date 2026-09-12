/// Schedule block and result models.
///
/// Mirrors the backend ScheduleBlockSchema and ScheduleResponse.
import 'package:intl/intl.dart';

/// A single 15-minute scheduled study block.
class ScheduleBlock {
  final String taskId;
  final DateTime start;
  final DateTime end;

  const ScheduleBlock({
    required this.taskId,
    required this.start,
    required this.end,
  });

  /// Duration in minutes.
  int get durationMinutes => end.difference(start).inMinutes;

  /// Duration in hours.
  double get durationHours => durationMinutes / 60.0;

  /// Number of 15-minute blocks.
  int get blockCount => (durationMinutes / 15).round();

  /// Date string in YYYY-MM-DD format.
  String get date => DateFormat('yyyy-MM-dd').format(start);

  /// Start time formatted as HH:mm.
  String get startTimeFormatted => DateFormat('HH:mm').format(start);

  /// End time formatted as HH:mm.
  String get endTimeFormatted => DateFormat('HH:mm').format(end);

  /// Time range formatted as 'HH:mm – HH:mm'.
  String get timeRangeFormatted => '$startTimeFormatted – $endTimeFormatted';

  /// Formatted date string (e.g., 'Monday, 25 Aug 2026').
  String get formattedDate => DateFormat('EEEE, d MMM yyyy').format(start);

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    return ScheduleBlock(
      taskId: json['task_id'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleBlock &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(taskId, start, end);

  @override
  String toString() => 'ScheduleBlock(taskId: $taskId, $start–$end)';
}


/// Full schedule result from the backend API.
class ScheduleResult {
  final bool success;
  final bool feasible;
  final double? fitnessScore;
  final int generationCount;
  final int executionTimeMs;
  final List<ScheduleBlock> schedule;
  final Map<String, dynamic>? diagnostics;

  const ScheduleResult({
    required this.success,
    required this.feasible,
    this.fitnessScore,
    required this.generationCount,
    required this.executionTimeMs,
    required this.schedule,
    this.diagnostics,
  });

  /// Required study hours from diagnostics if infeasible.
  double? get requiredHours =>
      (diagnostics?['required_hours'] as num?)?.toDouble();

  /// Available study hours before deadline from diagnostics if infeasible.
  double? get availableHours =>
      (diagnostics?['available_hours_before_deadline'] as num?)?.toDouble();

  /// Shortfall study hours from diagnostics if infeasible.
  double? get shortfallHours =>
      (diagnostics?['shortfall_hours'] as num?)?.toDouble();

  factory ScheduleResult.fromJson(Map<String, dynamic> json) {
    return ScheduleResult(
      success: json['success'] as bool,
      feasible: json['feasible'] as bool,
      fitnessScore: json['fitness_score'] != null
          ? (json['fitness_score'] as num).toDouble()
          : null,
      generationCount: json['generation_count'] as int,
      executionTimeMs: json['execution_time_ms'] as int,
      schedule: (json['schedule'] as List<dynamic>?)
              ?.map((e) => ScheduleBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      diagnostics: json['diagnostics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'feasible': feasible,
      'fitness_score': fitnessScore,
      'generation_count': generationCount,
      'execution_time_ms': executionTimeMs,
      'schedule': schedule.map((b) => b.toJson()).toList(),
      'diagnostics': diagnostics,
    };
  }

  @override
  String toString() =>
      'ScheduleResult(success: $success, feasible: $feasible, blocks: ${schedule.length})';
}
