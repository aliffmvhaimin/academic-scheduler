import 'package:flutter_test/flutter_test.dart';
import 'package:academic_scheduler/models/task.dart';

void main() {
  group('Task model', () {
    test('toJson and fromJson round-trip', () {
      final task = Task(
        id: 'task-001',
        taskName: 'Data Structures',
        creditWeight: 4,
        difficultyScore: 8,
        deadline: DateTime(2026, 8, 28, 23, 59),
        studyDurationHours: 2.0,
      );

      final json = task.toJson();
      expect(json['id'], 'task-001');
      expect(json['task_name'], 'Data Structures');
      expect(json['credit_weight'], 4);
      expect(json['difficulty_score'], 8);
      expect(json['study_duration_hours'], 2.0);

      final restored = Task.fromJson(json);
      expect(restored.id, task.id);
      expect(restored.taskName, task.taskName);
      expect(restored.creditWeight, task.creditWeight);
      expect(restored.difficultyScore, task.difficultyScore);
      expect(restored.deadline, task.deadline);
      expect(restored.studyDurationHours, task.studyDurationHours);
    });

    test('requiredBlocks calculates correctly', () {
      final task = Task(
        id: 't1',
        taskName: 'Test',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 8, 28),
        studyDurationHours: 1.5, // 6 blocks
      );
      expect(task.requiredBlocks, 6);

      final taskHalf = task.copyWith(studyDurationHours: 0.25); // 1 block
      expect(taskHalf.requiredBlocks, 1);
    });

    test('copyWith preserves unchanged fields', () {
      final original = Task(
        id: 't1',
        taskName: 'Original',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 8, 28),
        studyDurationHours: 1.0,
      );

      final modified = original.copyWith(taskName: 'Modified');
      expect(modified.taskName, 'Modified');
      expect(modified.id, original.id);
      expect(modified.creditWeight, original.creditWeight);
    });

    test('equality is based on id', () {
      final t1 = Task(
        id: 'same-id',
        taskName: 'A',
        creditWeight: 3,
        difficultyScore: 5,
        deadline: DateTime(2026, 8, 28),
        studyDurationHours: 1.0,
      );
      final t2 = Task(
        id: 'same-id',
        taskName: 'B',
        creditWeight: 4,
        difficultyScore: 7,
        deadline: DateTime(2026, 9, 1),
        studyDurationHours: 2.0,
      );
      expect(t1, equals(t2));
    });
  });
}
