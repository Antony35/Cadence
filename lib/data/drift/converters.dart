import 'package:drift/drift.dart';

/// Stores an instant as UTC ISO 8601 text (`2026-11-24T20:47:12.000Z`) and
/// reads it back in local time (D9).
///
/// UTC is never ambiguous, even during the hour repeated by the switch to
/// winter time, and the text sorts in time order (`ORDER BY created_at`).
class InstantConverter extends TypeConverter<DateTime, String> {
  const InstantConverter();

  @override
  String toSql(DateTime value) {
    // Dart writes 3 decimals, or 6 when there are microseconds: always 6,
    // else « 12.000Z » would sort after « 12.000500Z ».
    final iso = value.toUtc().toIso8601String();
    return iso.length == 24 ? '${iso.substring(0, 23)}000Z' : iso;
  }

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toLocal();
}

/// Stores a local day as `2026-11-27` (D9): a day only exists in local time.
class DayConverter extends TypeConverter<DateTime, String> {
  const DayConverter();

  @override
  String toSql(DateTime value) {
    if (value != DateTime(value.year, value.month, value.day)) {
      throw ArgumentError.value(value, 'value', 'not a local day at midnight');
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  DateTime fromSql(String fromDb) {
    final [year, month, day] = fromDb.split('-').map(int.parse).toList();
    return DateTime(year, month, day);
  }
}
