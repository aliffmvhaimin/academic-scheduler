/// Availability ViewModel managing free study slot state, daily time windows,
/// overlap validation, and local persistence.
///
/// Follows AGENTS.md §9 (business logic outside widgets, MVVM architecture).
import 'package:flutter/foundation.dart';
import '../models/free_slot.dart';
import '../repositories/local_storage_repository.dart';

class AvailabilityViewModel extends ChangeNotifier {
  final LocalStorageRepository repository;

  List<FreeSlot> _slots = [];
  bool _isLoading = false;
  String? _errorMessage;

  AvailabilityViewModel({LocalStorageRepository? repository})
      : repository = repository ?? LocalStorageRepository();

  List<FreeSlot> get slots => List.unmodifiable(_slots);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalSlots => _slots.length;

  /// Total available study hours across all configured time slots.
  double get totalAvailableHours =>
      _slots.fold(0.0, (sum, s) => sum + s.durationHours);

  /// Total 15-minute study blocks available.
  int get totalAvailableBlocks =>
      _slots.fold(0, (sum, s) => sum + s.blockCount);

  /// List of unique dates configured with study slots, sorted chronologically.
  List<String> get uniqueDates {
    final dates = _slots.map((s) => s.date).toSet().toList();
    dates.sort();
    return dates;
  }

  /// Map of slots grouped by date string (YYYY-MM-DD).
  Map<String, List<FreeSlot>> get groupedByDate {
    final map = <String, List<FreeSlot>>{};
    for (final slot in _slots) {
      map.putIfAbsent(slot.date, () => []).add(slot);
    }
    // Ensure slots within each day are sorted by start time
    for (final daySlots in map.values) {
      daySlots.sort((a, b) => a.start.compareTo(b.start));
    }
    return map;
  }

  /// Get slots for a specific date.
  List<FreeSlot> getSlotsForDate(String date) {
    final daySlots = _slots.where((s) => s.date == date).toList();
    daySlots.sort((a, b) => a.start.compareTo(b.start));
    return daySlots;
  }

  /// Total study hours for a specific date.
  double getHoursForDate(String date) {
    return getSlotsForDate(date).fold(0.0, (sum, s) => sum + s.durationHours);
  }

  // ── Load & Mutation ──

  /// Load free slots from local storage repository.
  Future<void> loadSlots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await repository.loadFreeSlots();
      _sortSlots(loaded);
      _slots = loaded;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load availability: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new free study slot.
  /// Returns false if overlap exists on the same date or validation fails.
  Future<bool> addSlot(FreeSlot slot) async {
    final validationError = validateSlot(slot, _slots);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;
      final updated = [..._slots, slot];
      _sortSlots(updated);
      _slots = updated;
      await repository.saveFreeSlots(_slots);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save availability slot: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing free slot.
  Future<bool> updateSlot(FreeSlot oldSlot, FreeSlot newSlot) async {
    final index = _slots.indexOf(oldSlot);
    if (index == -1) {
      _errorMessage = 'Slot not found';
      notifyListeners();
      return false;
    }

    final validationError =
        validateSlot(newSlot, _slots, excludeSlot: oldSlot);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;
      final updated = List<FreeSlot>.from(_slots);
      updated[index] = newSlot;
      _sortSlots(updated);
      _slots = updated;
      await repository.saveFreeSlots(_slots);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update availability slot: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a single free slot.
  Future<bool> deleteSlot(FreeSlot slot) async {
    try {
      _slots = _slots.where((s) => s != slot).toList();
      await repository.saveFreeSlots(_slots);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete availability slot: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete all slots for a given date.
  Future<bool> deleteSlotsForDate(String date) async {
    try {
      _slots = _slots.where((s) => s.date != date).toList();
      await repository.saveFreeSlots(_slots);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete slots for date $date: $e';
      notifyListeners();
      return false;
    }
  }

  /// Apply quick time windows (e.g. morning + evening) to multiple dates.
  Future<bool> applyTemplateToDays({
    required List<String> dates,
    required List<Map<String, String>> windows,
  }) async {
    try {
      final newSlots = <FreeSlot>[];
      for (final date in dates) {
        // Remove existing slots for this date to avoid overlaps
        _slots.removeWhere((s) => s.date == date);
        for (final w in windows) {
          final slot = FreeSlot(
            date: date,
            start: w['start']!,
            end: w['end']!,
          );
          newSlots.add(slot);
        }
      }
      final combined = [..._slots, ...newSlots];
      _sortSlots(combined);
      _slots = combined;
      await repository.saveFreeSlots(_slots);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to apply template: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear all availability slots.
  Future<void> clearAllSlots() async {
    _slots = [];
    await repository.saveFreeSlots([]);
    notifyListeners();
  }

  // ── Helper & Validation Methods ──

  static void _sortSlots(List<FreeSlot> list) {
    list.sort((a, b) {
      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.start.compareTo(b.start);
    });
  }

  /// Validates a slot against constraints and checks for overlaps on the same day.
  static String? validateSlot(
    FreeSlot slot,
    List<FreeSlot> existingSlots, {
    FreeSlot? excludeSlot,
  }) {
    // 1. Date format
    final dateErr = validateDateFormat(slot.date);
    if (dateErr != null) return dateErr;

    // 2. Time order (start must be before end)
    final timeErr = validateTimeOrder(slot.start, slot.end);
    if (timeErr != null) return timeErr;

    // 3. Minimum 15-minute duration
    if (slot.durationHours < 0.25) {
      return 'Slot duration must be at least 15 minutes';
    }

    // 4. Overlap check with other slots on the same date
    final sameDaySlots = existingSlots.where((s) {
      if (s.date != slot.date) return false;
      if (excludeSlot != null && s == excludeSlot) return false;
      return true;
    }).toList();

    for (final existing in sameDaySlots) {
      if (_timesOverlap(slot.start, slot.end, existing.start, existing.end)) {
        return 'Overlaps with existing slot (${existing.start}–${existing.end}) on ${slot.date}';
      }
    }

    return null;
  }

  /// Validates that YYYY-MM-DD is a valid calendar date.
  static String? validateDateFormat(String date) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return 'Date must be in YYYY-MM-DD format';
    }
    try {
      final dt = DateTime.parse(date);
      final parts = date.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      if (dt.year != y || dt.month != m || dt.day != d) {
        return 'Invalid calendar date';
      }
    } catch (_) {
      return 'Invalid calendar date';
    }
    return null;
  }

  /// Validates that start time is strictly before end time.
  static String? validateTimeOrder(String start, String end) {
    final sParts = start.split(':');
    final eParts = end.split(':');
    if (sParts.length != 2 || eParts.length != 2) {
      return 'Time must be in HH:MM format';
    }

    final sMinutes = int.parse(sParts[0]) * 60 + int.parse(sParts[1]);
    final eMinutes = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);

    if (sMinutes >= eMinutes) {
      return 'Start time must be before end time';
    }
    return null;
  }

  /// Helper checking if two time windows [s1, e1) and [s2, e2) overlap.
  static bool _timesOverlap(String s1, String e1, String s2, String e2) {
    final s1Min = _toMinutes(s1);
    final e1Min = _toMinutes(e1);
    final s2Min = _toMinutes(s2);
    final e2Min = _toMinutes(e2);

    return s1Min < e2Min && s2Min < e1Min;
  }

  static int _toMinutes(String time) {
    final p = time.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}
