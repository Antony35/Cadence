import 'dart:math';

import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/review.dart';

typedef ReviewSummary = ({int due, int overdue, int total});

abstract final class Leitner {
  static const firstBox = 1;
  static const lastBox = 6;

  static const intervals = [1, 3, 7, 14, 30, 60];

  static int nextBox(int box, Grade grade) => switch (grade) {
    Grade.hard => firstBox,
    Grade.good => min(box + 1, lastBox),
    Grade.easy => min(box + 2, lastBox),
  };

  static DateTime dueOn(int box, DateTime reviewedAt) =>
      addDays(dateOnly(reviewedAt), intervals[box - 1]);

  static DateTime firstDueOn(DateTime createdAt) => dueOn(firstBox, createdAt);

  static bool isDue(Combo combo, DateTime today) =>
      !combo.dueOn.isAfter(dateOnly(today));

  static bool isOverdue(Combo combo, DateTime today) =>
      combo.dueOn.isBefore(dateOnly(today));

  static ReviewSummary summarize(Iterable<Combo> combos, DateTime today) => (
    due: combos.where((combo) => isDue(combo, today)).length,
    overdue: combos.where((combo) => isOverdue(combo, today)).length,
    total: combos.length,
  );

  static int compare(Combo a, Combo b) {
    final byDue = a.dueOn.compareTo(b.dueOn);
    if (byDue != 0) return byDue;
    final byBox = a.box.compareTo(b.box);
    if (byBox != 0) return byBox;
    return a.createdAt.compareTo(b.createdAt);
  }
}
