import 'package:cadence/models/dates.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/review.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('T1 — Leitner boxes (D5)', () {
    test('hard sends back to box 1', () {
      expect(Leitner.nextBox(4, Grade.hard), 1);
      expect(Leitner.nextBox(1, Grade.hard), 1);
    });

    test('good moves one box up', () {
      expect(Leitner.nextBox(1, Grade.good), 2);
      expect(Leitner.nextBox(5, Grade.good), 6);
    });

    test('easy moves two boxes up', () {
      expect(Leitner.nextBox(1, Grade.easy), 3);
      expect(Leitner.nextBox(3, Grade.easy), 5);
    });

    test('box 6 is the ceiling', () {
      expect(Leitner.nextBox(6, Grade.good), 6);
      expect(Leitner.nextBox(5, Grade.easy), 6);
      expect(Leitner.nextBox(6, Grade.easy), 6);
    });

    test('the next review is the review day plus the box interval', () {
      final reviewedAt = DateTime(2026, 11, 20, 21, 45);
      expect(Leitner.dueOn(1, reviewedAt), DateTime(2026, 11, 21));
      expect(Leitner.dueOn(3, reviewedAt), DateTime(2026, 11, 27));
      expect(Leitner.dueOn(6, reviewedAt), DateTime(2027, 1, 19));
    });

    test('a new combo is due the next day', () {
      expect(
        Leitner.firstDueOn(DateTime(2026, 12, 31, 23, 59)),
        DateTime(2027, 1, 1),
      );
    });
  });

  group('days', () {
    test('dateOnly drops the time', () {
      expect(dateOnly(DateTime(2026, 11, 20, 23, 59)), DateTime(2026, 11, 20));
    });

    test('addDays crosses months and years', () {
      expect(addDays(DateTime(2026, 11, 30), 1), DateTime(2026, 12, 1));
      expect(addDays(DateTime(2026, 12, 25), 14), DateTime(2027, 1, 8));
    });

    test('addDays stays at midnight across the switch to winter time', () {
      // In France, 25 October 2026 lasts 25 hours.
      final day = addDays(DateTime(2026, 10, 24), 3);
      expect(day, DateTime(2026, 10, 27));
      expect(day.hour, 0);
    });

    test('daysBetween counts whole days, forward or back', () {
      final today = DateTime(2026, 11, 23, 22, 30);
      expect(daysBetween(today, DateTime(2026, 11, 23)), 0);
      expect(daysBetween(today, DateTime(2026, 11, 24)), 1);
      expect(daysBetween(today, DateTime(2026, 11, 21)), -2);
      expect(daysBetween(today, DateTime(2027, 1, 1)), 39);
    });

    test('daysBetween is not cut short by the switch to winter time', () {
      // 24 to 27 October 2026 lasts 73 hours in France, still 3 days.
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 27)), 3);
    });
  });

  group('T2 — due, overdue and review order (D6, D7)', () {
    final today = DateTime(2026, 11, 20, 8, 30);

    test('due today: to review, not overdue', () {
      final c = combo(dueOn: DateTime(2026, 11, 20));
      expect(Leitner.isDue(c, today), isTrue);
      expect(Leitner.isOverdue(c, today), isFalse);
    });

    test('due yesterday: to review and overdue', () {
      final c = combo(dueOn: DateTime(2026, 11, 19));
      expect(Leitner.isDue(c, today), isTrue);
      expect(Leitner.isOverdue(c, today), isTrue);
    });

    test('due tomorrow: not to review', () {
      final c = combo(dueOn: DateTime(2026, 11, 21));
      expect(Leitner.isDue(c, today), isFalse);
      expect(Leitner.isOverdue(c, today), isFalse);
    });

    test('order: most overdue, then lowest box, then oldest', () {
      final early = DateTime(2026, 11, 1);
      final late = DateTime(2026, 11, 5);
      final combos = [
        combo(id: 1, dueOn: DateTime(2026, 11, 20), box: 1),
        combo(id: 2, dueOn: DateTime(2026, 11, 18), box: 3, createdAt: late),
        combo(id: 3, dueOn: DateTime(2026, 11, 18), box: 3, createdAt: early),
        combo(id: 4, dueOn: DateTime(2026, 11, 18), box: 2),
        combo(id: 5, dueOn: DateTime(2026, 11, 10), box: 6),
      ]..sort(Leitner.compare);
      expect(combos.map((c) => c.id), [5, 4, 3, 2, 1]);
    });

    test('F1 — the summary counts due, overdue and all combos', () {
      final combos = [
        combo(id: 1, dueOn: DateTime(2026, 11, 18)),
        combo(id: 2, dueOn: DateTime(2026, 11, 20)),
        combo(id: 3, dueOn: DateTime(2026, 11, 21)),
      ];
      expect(Leitner.summarize(combos, today), (due: 2, overdue: 1, total: 3));
      expect(Leitner.summarize([], today), (due: 0, overdue: 0, total: 0));
    });
  });
}
