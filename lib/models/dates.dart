// Dart has no date-only type: a day is a local DateTime at midnight.
library;

DateTime dateOnly(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

// Counted in UTC, where a day always lasts 24 hours, so the switch to
// winter time cannot cut the result short.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
