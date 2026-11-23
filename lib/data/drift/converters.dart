import 'package:drift/drift.dart';

// UTC: never ambiguous during the hour repeated at the switch to winter time,
// and the text sorts in time order.
class InstantConverter extends TypeConverter<DateTime, String> {
  const InstantConverter();

  @override
  String toSql(DateTime value) {
    // Always 6 decimals, else « 12.000Z » would sort after « 12.000500Z ».
    final iso = value.toUtc().toIso8601String();
    return iso.length == 24 ? '${iso.substring(0, 23)}000Z' : iso;
  }

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toLocal();
}

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
