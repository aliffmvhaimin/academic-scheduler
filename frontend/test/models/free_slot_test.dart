import 'package:flutter_test/flutter_test.dart';
import 'package:academic_scheduler/models/free_slot.dart';

void main() {
  group('FreeSlot model', () {
    test('toJson and fromJson round-trip', () {
      const slot = FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00');

      final json = slot.toJson();
      expect(json['date'], '2026-08-25');
      expect(json['start'], '09:00');
      expect(json['end'], '12:00');

      final restored = FreeSlot.fromJson(json);
      expect(restored.date, slot.date);
      expect(restored.start, slot.start);
      expect(restored.end, slot.end);
    });

    test('copyWith replaces fields', () {
      const original = FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00');
      final modified = original.copyWith(start: '10:00');
      expect(modified.start, '10:00');
      expect(modified.date, original.date);
      expect(modified.end, original.end);
    });

    test('equality is value-based', () {
      const a = FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00');
      const b = FreeSlot(date: '2026-08-25', start: '09:00', end: '12:00');
      const c = FreeSlot(date: '2026-08-25', start: '10:00', end: '12:00');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
