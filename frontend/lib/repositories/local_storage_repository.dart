/// Local persistence repository using SharedPreferences.
///
/// Stores active tasks, user availability, and current schedule state
/// as per ARCHITECTURE.md §4 (Data Layer).
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/free_slot.dart';
import '../models/schedule.dart';

class LocalStorageRepository {
  static const String _tasksKey = 'active_tasks';
  static const String _slotsKey = 'free_slots';
  static const String _scheduleKey = 'current_schedule';
  static const String _completedKey = 'completed_task_ids';

  // ── Tasks ──

  /// Save the active task list.
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList(_tasksKey, jsonList);
  }

  /// Load the active task list.
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_tasksKey);
    if (jsonList == null) return [];
    return jsonList
        .map((s) => Task.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  // ── Free Slots ──

  /// Save user availability (free study slots).
  Future<void> saveFreeSlots(List<FreeSlot> slots) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = slots.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList(_slotsKey, jsonList);
  }

  /// Load user availability.
  Future<List<FreeSlot>> loadFreeSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_slotsKey);
    if (jsonList == null) return [];
    return jsonList
        .map((s) => FreeSlot.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  // ── Schedule ──

  /// Save scheduled blocks directly.
  Future<void> saveScheduleBlocks(List<ScheduleBlock> blocks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = blocks.map((b) => json.encode(b.toJson())).toList();
    await prefs.setStringList(_scheduleKey, jsonList);
  }

  /// Save the current schedule result.
  Future<void> saveScheduleResult(ScheduleResult result) async {
    await saveScheduleBlocks(result.schedule);
  }

  /// Load scheduled blocks.
  Future<List<ScheduleBlock>> loadScheduleBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_scheduleKey);
    if (jsonList == null) return [];
    return jsonList
        .map((s) =>
            ScheduleBlock.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  // ── Completed Tasks ──

  /// Save completed task IDs.
  Future<void> saveCompletedTaskIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, ids);
  }

  /// Load completed task IDs.
  Future<List<String>> loadCompletedTaskIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedKey) ?? [];
  }

  // ── Clear All ──

  /// Clear all stored data.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_slotsKey);
    await prefs.remove(_scheduleKey);
    await prefs.remove(_completedKey);
  }
}
