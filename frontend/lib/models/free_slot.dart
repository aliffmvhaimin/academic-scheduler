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
