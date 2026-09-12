import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academic_scheduler/models/free_slot.dart';
import 'package:academic_scheduler/repositories/local_storage_repository.dart';
import 'package:academic_scheduler/viewmodels/availability_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageRepository repository;
  late AvailabilityViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalStorageRepository();
    viewModel = AvailabilityViewModel(repository: repository);
  });

  group('AvailabilityViewModel - Initialization', () {
    test('initial state is empty and not loading', () {
      expect(viewModel.slots, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.totalSlots, 0);
      expect(viewModel.totalAvailableHours, 0.0);
      expect(viewModel.totalAvailableBlocks, 0);
      expect(viewModel.uniqueDates, isEmpty);
      expect(viewModel.groupedByDate, isEmpty);
    });
  });

  group('AvailabilityViewModel - Load Slots', () {
    test('loadSlots populates slots sorted by date and start time', () async {
      final s1 = const FreeSlot(date: '2026-09-15', start: '14:00', end: '17:00');
      final s2 = const FreeSlot(date: '2026-09-14', start: '19:00', end: '22:00');
      final s3 = const FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');

      await repository.saveFreeSlots([s1, s2, s3]);
      await viewModel.loadSlots();

      expect(viewModel.slots.length, 3);
      // 2026-09-14 09:00-12:00 should be first
      expect(viewModel.slots[0], s3);
      // 2026-09-14 19:00-22:00 should be second
      expect(viewModel.slots[1], s2);
      // 2026-09-15 14:00-17:00 should be third
      expect(viewModel.slots[2], s1);

      expect(viewModel.uniqueDates, ['2026-09-14', '2026-09-15']);
      expect(viewModel.totalAvailableHours, 9.0); // 3h each * 3 = 9h
      expect(viewModel.totalAvailableBlocks, 36); // 9h * 4 = 36 blocks

      // Check groupedByDate
      final grouped = viewModel.groupedByDate;
      expect(grouped.keys.length, 2);
      expect(grouped['2026-09-14']!.length, 2);
      expect(grouped['2026-09-15']!.length, 1);

      // Check getSlotsForDate and getHoursForDate
      expect(viewModel.getSlotsForDate('2026-09-14').length, 2);
      expect(viewModel.getHoursForDate('2026-09-14'), 6.0);
      expect(viewModel.getHoursForDate('2026-09-15'), 3.0);
      expect(viewModel.getHoursForDate('2026-09-99'), 0.0);
    });
  });

  group('AvailabilityViewModel - Add Slot', () {
    test('adds valid slot and persists to repository', () async {
      const slot = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      final success = await viewModel.addSlot(slot);

      expect(success, true);
      expect(viewModel.slots.length, 1);
      expect(viewModel.slots.first, slot);
      expect(viewModel.totalAvailableHours, 3.0);
      expect(viewModel.totalAvailableBlocks, 12);
      expect(viewModel.errorMessage, isNull);

      final loaded = await repository.loadFreeSlots();
      expect(loaded.length, 1);
      expect(loaded.first, slot);
    });

    test('rejects slot with start time after or equal to end time', () async {
      const invalidEqual = FreeSlot(date: '2026-09-14', start: '10:00', end: '10:00');
      final success1 = await viewModel.addSlot(invalidEqual);
      expect(success1, false);
      expect(viewModel.errorMessage, contains('Start time must be before end time'));

      const invalidReverse = FreeSlot(date: '2026-09-14', start: '12:00', end: '10:00');
      final success2 = await viewModel.addSlot(invalidReverse);
      expect(success2, false);
      expect(viewModel.errorMessage, contains('Start time must be before end time'));
    });

    test('rejects slot shorter than 15 minutes', () async {
      const shortSlot = FreeSlot(date: '2026-09-14', start: '09:00', end: '09:10');
      final success = await viewModel.addSlot(shortSlot);
      expect(success, false);
      expect(viewModel.errorMessage, contains('at least 15 minutes'));
    });

    test('rejects slot with invalid date format', () async {
      const invalidDate = FreeSlot(date: '14-09-2026', start: '09:00', end: '11:00');
      final success = await viewModel.addSlot(invalidDate);
      expect(success, false);
      expect(viewModel.errorMessage, contains('YYYY-MM-DD'));
    });

    test('rejects overlapping slots on the same date', () async {
      const slot1 = FreeSlot(date: '2026-09-14', start: '10:00', end: '12:00');
      await viewModel.addSlot(slot1);

      // Exact match
      const exact = FreeSlot(date: '2026-09-14', start: '10:00', end: '12:00');
      expect(await viewModel.addSlot(exact), false);
      expect(viewModel.errorMessage, contains('Overlaps with existing slot'));

      // Partial overlap - left
      const overlapLeft = FreeSlot(date: '2026-09-14', start: '09:00', end: '10:30');
      expect(await viewModel.addSlot(overlapLeft), false);

      // Partial overlap - right
      const overlapRight = FreeSlot(date: '2026-09-14', start: '11:30', end: '13:00');
      expect(await viewModel.addSlot(overlapRight), false);

      // Enclosing overlap
      const enclosing = FreeSlot(date: '2026-09-14', start: '09:00', end: '13:00');
      expect(await viewModel.addSlot(enclosing), false);

      // Inside overlap
      const inside = FreeSlot(date: '2026-09-14', start: '10:15', end: '11:45');
      expect(await viewModel.addSlot(inside), false);
    });

    test('allows adjacent non-overlapping slots on same date', () async {
      const slot1 = FreeSlot(date: '2026-09-14', start: '10:00', end: '12:00');
      await viewModel.addSlot(slot1);

      // Exactly touches at 12:00
      const adjacentAfter = FreeSlot(date: '2026-09-14', start: '12:00', end: '14:00');
      expect(await viewModel.addSlot(adjacentAfter), true);

      // Exactly touches at 10:00
      const adjacentBefore = FreeSlot(date: '2026-09-14', start: '08:00', end: '10:00');
      expect(await viewModel.addSlot(adjacentBefore), true);

      expect(viewModel.slots.length, 3);
    });

    test('allows identical time windows on different dates', () async {
      const slot1 = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      const slot2 = FreeSlot(date: '2026-09-15', start: '09:00', end: '12:00');

      expect(await viewModel.addSlot(slot1), true);
      expect(await viewModel.addSlot(slot2), true);
      expect(viewModel.slots.length, 2);
    });
  });

  group('AvailabilityViewModel - Update Slot', () {
    test('updates existing slot and persists', () async {
      const original = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      await viewModel.addSlot(original);

      const updated = FreeSlot(date: '2026-09-14', start: '09:00', end: '13:00');
      final success = await viewModel.updateSlot(original, updated);

      expect(success, true);
      expect(viewModel.slots.first.end, '13:00');
      expect(viewModel.totalAvailableHours, 4.0);

      final loaded = await repository.loadFreeSlots();
      expect(loaded.first.end, '13:00');
    });

    test('updateSlot fails if target slot does not exist', () async {
      const nonExistent = FreeSlot(date: '2026-09-14', start: '08:00', end: '10:00');
      const newSlot = FreeSlot(date: '2026-09-14', start: '08:00', end: '11:00');

      final success = await viewModel.updateSlot(nonExistent, newSlot);
      expect(success, false);
      expect(viewModel.errorMessage, 'Slot not found');
    });

    test('updateSlot rejects updates causing overlap with another slot', () async {
      const s1 = const FreeSlot(date: '2026-09-14', start: '09:00', end: '11:00');
      const s2 = const FreeSlot(date: '2026-09-14', start: '13:00', end: '15:00');
      await viewModel.addSlot(s1);
      await viewModel.addSlot(s2);

      // Extend s1 so it overlaps with s2 (13:00-15:00)
      const invalidUpdate = const FreeSlot(date: '2026-09-14', start: '09:00', end: '14:00');
      final success = await viewModel.updateSlot(s1, invalidUpdate);

      expect(success, false);
      expect(viewModel.errorMessage, contains('Overlaps with existing slot'));
      expect(viewModel.slots.first.end, '11:00'); // Unchanged
    });
  });

  group('AvailabilityViewModel - Delete Operations', () {
    test('deleteSlot removes specified slot and persists', () async {
      const s1 = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      const s2 = FreeSlot(date: '2026-09-14', start: '14:00', end: '17:00');
      await viewModel.addSlot(s1);
      await viewModel.addSlot(s2);
      expect(viewModel.slots.length, 2);

      final success = await viewModel.deleteSlot(s1);
      expect(success, true);
      expect(viewModel.slots.length, 1);
      expect(viewModel.slots.first, s2);

      final loaded = await repository.loadFreeSlots();
      expect(loaded.length, 1);
      expect(loaded.first, s2);
    });

    test('deleteSlotsForDate removes all slots matching date', () async {
      const s1 = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      const s2 = FreeSlot(date: '2026-09-14', start: '14:00', end: '17:00');
      const s3 = FreeSlot(date: '2026-09-15', start: '09:00', end: '12:00');
      await viewModel.addSlot(s1);
      await viewModel.addSlot(s2);
      await viewModel.addSlot(s3);
      expect(viewModel.slots.length, 3);

      final success = await viewModel.deleteSlotsForDate('2026-09-14');
      expect(success, true);
      expect(viewModel.slots.length, 1);
      expect(viewModel.slots.first.date, '2026-09-15');

      final loaded = await repository.loadFreeSlots();
      expect(loaded.length, 1);
      expect(loaded.first.date, '2026-09-15');
    });

    test('clearAllSlots empties all slots and repository', () async {
      const s1 = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      await viewModel.addSlot(s1);
      expect(viewModel.slots.length, 1);

      await viewModel.clearAllSlots();
      expect(viewModel.slots, isEmpty);

      final loaded = await repository.loadFreeSlots();
      expect(loaded, isEmpty);
    });
  });

  group('AvailabilityViewModel - Template Application', () {
    test('applyTemplateToDays populates multiple dates with time windows', () async {
      final dates = ['2026-09-14', '2026-09-15'];
      final windows = [
        {'start': '09:00', 'end': '12:00'},
        {'start': '14:00', 'end': '17:00'},
      ];

      final success = await viewModel.applyTemplateToDays(
        dates: dates,
        windows: windows,
      );

      expect(success, true);
      expect(viewModel.slots.length, 4); // 2 days * 2 windows
      expect(viewModel.uniqueDates, dates);
      expect(viewModel.totalAvailableHours, 12.0); // 4 slots * 3h

      final loaded = await repository.loadFreeSlots();
      expect(loaded.length, 4);
    });

    test('applyTemplateToDays replaces existing slots on target dates cleanly', () async {
      // Add existing slot on 2026-09-14
      const existing = FreeSlot(date: '2026-09-14', start: '10:00', end: '11:00');
      await viewModel.addSlot(existing);

      final success = await viewModel.applyTemplateToDays(
        dates: ['2026-09-14'],
        windows: [
          {'start': '09:00', 'end': '12:00'},
        ],
      );

      expect(success, true);
      expect(viewModel.slots.length, 1);
      expect(viewModel.slots.first.start, '09:00');
      expect(viewModel.slots.first.end, '12:00');
    });
  });

  group('AvailabilityViewModel - Static Validation Helpers', () {
    test('validateDateFormat checks', () {
      expect(AvailabilityViewModel.validateDateFormat('2026-09-14'), isNull);
      expect(AvailabilityViewModel.validateDateFormat('2026-9-14'), isNotNull);
      expect(AvailabilityViewModel.validateDateFormat('2026/09/14'), isNotNull);
      expect(AvailabilityViewModel.validateDateFormat('invalid'), isNotNull);
      expect(AvailabilityViewModel.validateDateFormat('2026-02-31'), isNotNull); // Invalid calendar date
    });

    test('validateTimeOrder checks', () {
      expect(AvailabilityViewModel.validateTimeOrder('09:00', '12:00'), isNull);
      expect(AvailabilityViewModel.validateTimeOrder('12:00', '12:00'), isNotNull);
      expect(AvailabilityViewModel.validateTimeOrder('13:00', '12:00'), isNotNull);
      expect(AvailabilityViewModel.validateTimeOrder('invalid', '12:00'), isNotNull);
      expect(AvailabilityViewModel.validateTimeOrder('09:00', 'invalid'), isNotNull);
    });

    test('validateSlot excludes specified slot during update', () {
      const slot = FreeSlot(date: '2026-09-14', start: '09:00', end: '12:00');
      final existing = [slot];

      // Overlap with itself should be flagged if excludeSlot is not passed
      expect(
        AvailabilityViewModel.validateSlot(slot, existing),
        isNotNull,
      );

      // Overlap with itself ignored when excludeSlot is passed
      expect(
        AvailabilityViewModel.validateSlot(slot, existing, excludeSlot: slot),
        isNull,
      );
    });
  });
}
