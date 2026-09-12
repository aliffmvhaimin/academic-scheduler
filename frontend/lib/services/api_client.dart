import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/free_slot.dart';
import '../models/schedule.dart';

/// Exception for API communication failures.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final bool isMalformed;

  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
    this.isMalformed = false,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final Duration timeoutDuration;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// Default factory pointing to local dev server.
  factory ApiClient.defaultClient({Duration? timeoutDuration}) {
    // When running in a web browser, connect directly to 127.0.0.1:8000.
    // Android emulator uses 10.0.2.2 to reach host localhost.
    final host = kIsWeb ? '127.0.0.1' : '10.0.2.2';
    return ApiClient(
      baseUrl: 'http://$host:8000/api/v1',
      timeoutDuration: timeoutDuration ?? const Duration(seconds: 15),
    );
  }

  /// Health check endpoint.
  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(timeoutDuration);
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

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/schedule'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeoutDuration);
    } on TimeoutException {
      throw ApiException(
        'Network timeout: The scheduling server at $baseUrl took too long to respond.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Network failure: Unable to connect to scheduling server at $baseUrl. Ensure backend is running.',
        isNetworkError: true,
      );
    }

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ScheduleResult.fromJson(data);
      } catch (e) {
        throw ApiException(
          'Malformed response: The server returned an invalid schedule format.',
          statusCode: 200,
          isMalformed: true,
        );
      }
    } else if (response.statusCode == 422) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        throw ApiException(
          'Validation error: ${data['detail']}',
          statusCode: 422,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Validation error: ${response.body}',
          statusCode: 422,
          isMalformed: true,
        );
      }
    } else {
      throw ApiException(
        'Server error (${response.statusCode}): ${response.body}',
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
      'missed_blocks': (missedBlocks ?? []).map((b) => b.toJson()).toList(),
      'completed_task_ids': completedTaskIds ?? [],
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/schedule/recalculate'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeoutDuration);
    } on TimeoutException {
      throw ApiException(
        'Network timeout: The scheduling server at $baseUrl took too long to respond.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Network failure: Unable to connect to scheduling server at $baseUrl. Ensure backend is running.',
        isNetworkError: true,
      );
    }

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ScheduleResult.fromJson(data);
      } catch (e) {
        throw ApiException(
          'Malformed response: The server returned an invalid recalculation format.',
          statusCode: 200,
          isMalformed: true,
        );
      }
    } else if (response.statusCode == 422) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        throw ApiException(
          'Validation error: ${data['detail']}',
          statusCode: 422,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Validation error: ${response.body}',
          statusCode: 422,
          isMalformed: true,
        );
      }
    } else {
      throw ApiException(
        'Server error (${response.statusCode}): ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Clean up HTTP client resources.
  void dispose() {
    _client.close();
  }
}

