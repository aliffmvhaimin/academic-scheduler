import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:academic_scheduler/models/task.dart';
import 'package:academic_scheduler/models/free_slot.dart';
import 'package:academic_scheduler/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('healthCheck returns true on 200 ok', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/health');
        return http.Response(json.encode({'status': 'ok'}), 200);
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      final isHealthy = await api.healthCheck();
      expect(isHealthy, true);
    });

    test('healthCheck returns false on error status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('error', 500);
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      final isHealthy = await api.healthCheck();
      expect(isHealthy, false);
    });

    test('generateSchedule successfully parses feasible schedule response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/schedule');
        expect(request.method, 'POST');

        final reqBody = json.decode(request.body) as Map<String, dynamic>;
        expect(reqBody['tasks'], isNotEmpty);
        expect(reqBody['free_slots'], isNotEmpty);

        final responseJson = {
          'success': true,
          'feasible': true,
          'fitness_score': 85.0,
          'generation_count': 120,
          'execution_time_ms': 180,
          'schedule': [
            {
              'task_id': 'task-1',
              'start': '2026-08-25T09:00:00',
              'end': '2026-08-25T09:15:00',
            },
          ],
          'diagnostics': null,
        };

        return http.Response(
          json.encode(responseJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      final tasks = [
        Task(
          id: 'task-1',
          taskName: 'Math',
          creditWeight: 3,
          difficultyScore: 5,
          deadline: DateTime(2026, 8, 30),
          studyDurationHours: 1.0,
        ),
      ];
      final slots = [
        const FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00'),
      ];

      final result = await api.generateSchedule(tasks: tasks, freeSlots: slots);
      expect(result.success, true);
      expect(result.feasible, true);
      expect(result.schedule.length, 1);
      expect(result.schedule.first.taskId, 'task-1');
    });

    test('generateSchedule throws ApiException on 422 validation error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'detail': 'Invalid credit weight'}),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      expect(
        () => api.generateSchedule(tasks: [], freeSlots: []),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
      );
    });

    test('recalculateSchedule sends correct payload and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/schedule/recalculate');
        expect(request.method, 'POST');

        final reqBody = json.decode(request.body) as Map<String, dynamic>;
        expect(reqBody['completed_task_ids'], equals(['task-done']));

        final responseJson = {
          'success': true,
          'feasible': true,
          'fitness_score': 90.0,
          'generation_count': 50,
          'execution_time_ms': 75,
          'schedule': [],
          'diagnostics': null,
        };

        return http.Response(
          json.encode(responseJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      final result = await api.recalculateSchedule(
        tasks: [],
        freeSlots: [],
        completedTaskIds: ['task-done'],
      );

      expect(result.success, true);
      expect(result.schedule, isEmpty);
    });

    test('generateSchedule throws ApiException with isNetworkError on connection error', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      expect(
        () => api.generateSchedule(tasks: [], freeSlots: []),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)
            .having((e) => e.message, 'message', contains('Network failure'))),
      );
    });

    test('generateSchedule throws ApiException with isMalformed on invalid JSON response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body>502 Bad Gateway</body></html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      expect(
        () => api.generateSchedule(tasks: [], freeSlots: []),
        throwsA(isA<ApiException>()
            .having((e) => e.isMalformed, 'isMalformed', true)
            .having((e) => e.message, 'message', contains('Malformed response'))),
      );
    });

    test('generateSchedule throws ApiException on 500 server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final api = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      expect(
        () => api.generateSchedule(tasks: [], freeSlots: []),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', contains('Server error (500)'))),
      );
    });
  });
}
