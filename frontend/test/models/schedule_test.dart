import 'package:flutter_test/flutter_test.dart';
import 'package:academic_scheduler/models/schedule.dart';

void main() {
  group('ScheduleBlock model', () {
    test('fromJson and toJson round-trip', () {
      final block = ScheduleBlock(
        taskId: 'task-001',
        start: DateTime(2026, 8, 25, 18, 0),
        end: DateTime(2026, 8, 25, 18, 15),
      );

      final json = block.toJson();
      expect(json['task_id'], 'task-001');

      final restored = ScheduleBlock.fromJson(json);
      expect(restored.taskId, block.taskId);
      expect(restored.start, block.start);
      expect(restored.end, block.end);
    });
  });

  group('ScheduleResult model', () {
    test('fromJson parses feasible result', () {
      final json = {
        'success': true,
        'feasible': true,
        'fitness_score': 84.5,
        'generation_count': 143,
        'execution_time_ms': 218,
        'schedule': [
          {
            'task_id': 'task-001',
            'start': '2026-08-25T18:00:00',
            'end': '2026-08-25T18:15:00',
          },
          {
            'task_id': 'task-001',
            'start': '2026-08-25T18:15:00',
            'end': '2026-08-25T18:30:00',
          },
        ],
        'diagnostics': null,
      };

      final result = ScheduleResult.fromJson(json);
      expect(result.success, true);
      expect(result.feasible, true);
      expect(result.fitnessScore, 84.5);
      expect(result.generationCount, 143);
      expect(result.executionTimeMs, 218);
      expect(result.schedule.length, 2);
      expect(result.diagnostics, isNull);
    });

    test('fromJson parses infeasible result with diagnostics', () {
      final json = {
        'success': true,
        'feasible': false,
        'fitness_score': null,
        'generation_count': 200,
        'execution_time_ms': 220,
        'schedule': [],
        'diagnostics': {
          'required_hours': 10,
          'available_hours_before_deadline': 2,
          'shortfall_hours': 8,
        },
      };

      final result = ScheduleResult.fromJson(json);
      expect(result.success, true);
      expect(result.feasible, false);
      expect(result.fitnessScore, isNull);
      expect(result.schedule, isEmpty);
      expect(result.diagnostics, isNotNull);
      expect(result.diagnostics!['shortfall_hours'], 8);
    });
  });
}
