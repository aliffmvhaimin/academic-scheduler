/// Academic task domain model.
///
/// Mirrors the backend TaskSchema (credit_weight: 1–6, difficulty_score: 1–10).
class Task {
  final String id;
  final String taskName;
  final int creditWeight;
  final int difficultyScore;
  final DateTime deadline;
  final double studyDurationHours;

  const Task({
    required this.id,
    required this.taskName,
    required this.creditWeight,
    required this.difficultyScore,
    required this.deadline,
    required this.studyDurationHours,
  });

  /// Number of 15-minute blocks required.
  int get requiredBlocks => (studyDurationHours * 4).ceil();

  Task copyWith({
    String? id,
    String? taskName,
    int? creditWeight,
    int? difficultyScore,
    DateTime? deadline,
    double? studyDurationHours,
  }) {
    return Task(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      creditWeight: creditWeight ?? this.creditWeight,
      difficultyScore: difficultyScore ?? this.difficultyScore,
      deadline: deadline ?? this.deadline,
      studyDurationHours: studyDurationHours ?? this.studyDurationHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_name': taskName,
      'credit_weight': creditWeight,
      'difficulty_score': difficultyScore,
      'deadline': deadline.toIso8601String(),
      'study_duration_hours': studyDurationHours,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      taskName: json['task_name'] as String,
      creditWeight: json['credit_weight'] as int,
      difficultyScore: json['difficulty_score'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      studyDurationHours: (json['study_duration_hours'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task(id: $id, taskName: $taskName)';
}
