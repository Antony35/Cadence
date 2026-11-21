import 'dart:math';

import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/review.dart';

/// Spaced repetition with Leitner boxes (D5 to D7).
///
/// A combo starts in box 1. Each box has a waiting time before the next
/// review: the better the combo is known, the higher its box, the longer the
/// wait.
abstract final class Leitner {
  static const firstBox = 1;
  static const lastBox = 6;

  /// Days to wait after a review, for boxes 1 to 6.
  static const intervals = [1, 3, 7, 14, 30, 60];

  /// D5: hard → box 1, good → next box, easy → two boxes up, 6 at most.
  static int nextBox(int box, Grade grade) => switch (grade) {
    Grade.hard => firstBox,
    Grade.good => min(box + 1, lastBox),
    Grade.easy => min(box + 2, lastBox),
  };

  /// D5: the review day plus the interval of [box].
  static DateTime dueOn(int box, DateTime reviewedAt) =>
      addDays(dateOnly(reviewedAt), intervals[box - 1]);

  /// A new combo is due the day after its creation, like box 1.
  static DateTime firstDueOn(DateTime createdAt) => dueOn(firstBox, createdAt);

  /// D6: due today or before.
  static bool isDue(Combo combo, DateTime today) =>
      !combo.dueOn.isAfter(dateOnly(today));

  /// D6: due before today.
  static bool isOverdue(Combo combo, DateTime today) =>
      combo.dueOn.isBefore(dateOnly(today));

  /// D7: the most overdue first, then the lowest box, then the oldest.
  /// Also the order of the main list (F3).
  static int compare(Combo a, Combo b) {
    final byDue = a.dueOn.compareTo(b.dueOn);
    if (byDue != 0) return byDue;
    final byBox = a.box.compareTo(b.box);
    if (byBox != 0) return byBox;
    return a.createdAt.compareTo(b.createdAt);
  }
}
