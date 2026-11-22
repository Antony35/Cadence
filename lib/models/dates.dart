/// Day arithmetic on local dates. Dart has no date-only type: a day is a
/// local [DateTime] at midnight.
///
/// No function here reads the clock: callers pass "today", so tests never
/// depend on the real date.
library;

/// The local day of [moment], at midnight.
DateTime dateOnly(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

/// The day [days] after [day], at midnight.
///
/// `add(Duration(days: n))` would add n × 24 hours, and land on the previous
/// day at 23:00 across the switch to winter time (a 25-hour day). Building
/// the date from its parts lets [DateTime] handle month and year overflow.
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// The number of days from the day of [from] to the day of [to]: 1 for
/// tomorrow, -2 for the day before yesterday.
///
/// Counted on UTC copies of the two days: a UTC day always lasts 24 hours,
/// so the switch to winter time cannot cut the result short.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
