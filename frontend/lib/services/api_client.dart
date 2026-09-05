/// HTTP API client for the Academic Scheduler backend.
///
/// Communicates with the FastAPI backend via JSON/REST.
/// Does not expose GA implementation details to the Flutter layer
/// (AGENTS.md §8, ARCHITECTURE.md §6).
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/free_slot.dart';
import '../models/schedule.dart';

/// Exception for API communication failures.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Default factory pointing to local dev server.
  factory ApiClient.defaultClient() {
    // Android emulator uses 10.0.2.2 to reach host localhost.
    // For physical device testing, replace with your machine's IP.
    return ApiClient(baseUrl: 'http://10.0.2.2:8000/api/v1');
  }

  /// Health check endpoint.
  Future<bool> healthCheck() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// POST /schedule — generates a study schedule.
  Future<ScheduleResult> generateSchedule({
    required List<Task> tasks,
    required List<FreeSlot> freeSlots,
  }) async {
    final body = json.encode({
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'free_slots': freeSlots.map((s) => s.toJson()).toList(),
    });

    final response = await _client.post(
      Uri.parse('$baseUrl/schedule'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ScheduleResult.fromJson(data);
    } else if (response.statusCode == 422) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(
        'Validation error: ${data['detail']}',
        statusCode: 422,
      );
    } else {
      throw ApiException(
        'Server error: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  /// POST /schedule/recalculate — dynamically recalculates the schedule.
  Future<ScheduleResult> recalculateSchedule({
    required List<Task> tasks,
    required List<FreeSlot> freeSlots,
    List<ScheduleBlock>? missedBlocks,
    List<String>? completedTaskIds,
  }) async {
    final body = json.encode({
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'free_slots': freeSlots.map((s) => s.toJson()).toList(),
      'missed_blocks':
          (missedBlocks ?? []).map((b) => b.toJson()).toList(),
      'completed_task_ids': completedTaskIds ?? [],
    });

    final response = await _client.post(
      Uri.parse('$baseUrl/schedule/recalculate'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ScheduleResult.fromJson(data);
    } else if (response.statusCode == 422) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(
        'Validation error: ${data['detail']}',
        statusCode: 422,
      );
    } else {
      throw ApiException(
        'Server error: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Clean up HTTP client resources.
  void dispose() {
    _client.close();
  }
}
