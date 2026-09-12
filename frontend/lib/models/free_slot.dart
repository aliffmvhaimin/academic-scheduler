/// Available study time slot model.
///
/// Mirrors the backend FreeSlotSchema (date: YYYY-MM-DD, start/end: HH:MM).
class FreeSlot {
  final String date;
  final String start;
  final String end;

  const FreeSlot({
    required this.date,
    required this.start,
    required this.end,
  });

  /// Start time as DateTime.
  DateTime get startDateTime {
    final parts = start.split(':');
    final d = DateTime.parse(date);
    return DateTime(
        d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// End time as DateTime.
  DateTime get endDateTime {
    final parts = end.split(':');
    final d = DateTime.parse(date);
    return DateTime(
        d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Total duration of the slot in hours.
  double get durationHours =>
      endDateTime.difference(startDateTime).inMinutes / 60.0;

  /// Total number of 15-minute blocks in this slot.
  int get blockCount => (durationHours * 4).round();

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'start': start,
      'end': end,
    };
  }

  factory FreeSlot.fromJson(Map<String, dynamic> json) {
    return FreeSlot(
      date: json['date'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }

  FreeSlot copyWith({
    String? date,
    String? start,
    String? end,
  }) {
    return FreeSlot(
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeSlot &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(date, start, end);

  @override
  String toString() => 'FreeSlot(date: $date, $start–$end)';
}
