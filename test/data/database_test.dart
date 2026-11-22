import 'package:cadence/data/drift/converters.dart';
import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/drift/drift_combo_repository.dart';
import 'package:cadence/data/drift/drift_technique_repository.dart';
import 'package:cadence/models/catalog.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../models/fixtures.dart';
import 'test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  group('creation', () {
    test('the catalog is inserted in the order of catalog.dart (D1)', () async {
      final rows = await (db.select(
        db.techniques,
      )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
      expect(rows.map((r) => r.slug), catalog.map((t) => t.slug));
      expect(rows.map((r) => r.position), [for (var i = 1; i <= 41; i++) i]);
    });

    test('the foreign keys are enforced', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.read<int>('foreign_keys'), 1);
    });
  });

  test('the query of the due combos uses the index on due_on', () async {
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM combos '
          "WHERE due_on <= '2026-11-24' ORDER BY due_on",
        )
        .get();
    expect(
      plan.map((row) => row.read<String>('detail')).join(' '),
      contains('combos_due_on'),
    );
  });

  group('T10 — the database refuses invalid values (R3)', () {
    // Raw SQL on purpose: the repositories would refuse these values before
    // the database. Here, the database alone must say no.
    Future<void> insertCombo({required String signature, int box = 1}) =>
        db.customStatement(
          'INSERT INTO combos (signature, box, due_on, created_at, updated_at) '
          "VALUES (?, ?, '2026-11-24', '2026-11-23T20:00:00.000000Z', "
          "'2026-11-23T20:00:00.000000Z')",
          [signature, box],
        );

    test('a duplicate signature', () async {
      await insertCombo(signature: 'jab:lead:head|cross:rear:head');
      await expectLater(
        insertCombo(signature: 'jab:lead:head|cross:rear:head'),
        throwsSqliteError,
      );
    });

    test('box 7', () async {
      await insertCombo(signature: 'a', box: 6);
      await expectLater(insertCombo(signature: 'b', box: 7), throwsSqliteError);
      await expectLater(insertCombo(signature: 'c', box: 0), throwsSqliteError);
    });

    test('an unknown grade', () async {
      await insertCombo(signature: 'a');
      await db.customStatement(
        "INSERT INTO reviews (combo_id, reviewed_at, grade) VALUES (1, 'x', 'good')",
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO reviews (combo_id, reviewed_at, grade) VALUES (1, 'x', 'perfect')",
        ),
        throwsSqliteError,
      );
    });

    test('an unknown family, side or target', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO techniques (slug, name, family, position) '
          "VALUES ('x', 'X', 'grappling', 42)",
        ),
        throwsSqliteError,
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO technique_sides (technique_id, side) VALUES (1, 'left')",
        ),
        throwsSqliteError,
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO technique_targets (technique_id, target) VALUES (1, 'feet')",
        ),
        throwsSqliteError,
      );
    });

    test('a step at position 12, or of an unknown combo', () async {
      await insertCombo(signature: 'a');
      await expectLater(
        db.customStatement(
          'INSERT INTO combo_steps (combo_id, position, technique_id) '
          'VALUES (1, 12, 1)',
        ),
        throwsSqliteError,
      );
      await expectLater(
        db.customStatement(
          'INSERT INTO combo_steps (combo_id, position, technique_id) '
          'VALUES (99, 0, 1)',
        ),
        throwsSqliteError,
      );
    });

    test('deleting a technique used by a combo', () async {
      final techniques = DriftTechniqueRepository(db);
      await DriftComboRepository(db, techniques).create(
        steps: [step('jab'), step('cross')],
        now: DateTime(2026, 11, 23, 20),
      );
      await expectLater(
        db.customStatement("DELETE FROM techniques WHERE slug = 'jab'"),
        throwsSqliteError,
      );
    });
  });

  group('D9 — dates', () {
    const instant = InstantConverter();
    const day = DayConverter();

    test('an instant comes back identical, microseconds included', () {
      final now = DateTime(2026, 10, 25, 2, 30, 12, 345, 678);
      expect(instant.fromSql(instant.toSql(now)), now);
      expect(instant.toSql(now), endsWith('Z'));
    });

    test('the stored text sorts like the time', () {
      final a = instant.toSql(DateTime.utc(2026, 11, 24, 20, 47, 12));
      final b = instant.toSql(DateTime.utc(2026, 11, 24, 20, 47, 12, 0, 500));
      expect(a, '2026-11-24T20:47:12.000000Z');
      expect(a.compareTo(b), lessThan(0));
    });

    test('a day is stored as YYYY-MM-DD', () {
      expect(day.toSql(DateTime(2026, 12, 1)), '2026-12-01');
      expect(day.fromSql('2026-12-01'), DateTime(2026, 12, 1));
    });

    test('a day refuses an hour', () {
      expect(() => day.toSql(DateTime(2026, 12, 1, 8)), throwsArgumentError);
    });
  });
}
