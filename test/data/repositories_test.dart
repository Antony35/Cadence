import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/drift/drift_combo_repository.dart';
import 'package:cadence/data/drift/drift_review_repository.dart';
import 'package:cadence/data/drift/drift_technique_repository.dart';
import 'package:cadence/data/exceptions.dart';
import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';
import 'package:flutter_test/flutter_test.dart';

import '../models/fixtures.dart';
import 'test_database.dart';

void main() {
  late AppDatabase db;
  late DriftTechniqueRepository techniques;
  late DriftComboRepository combos;
  late DriftReviewRepository reviews;

  // Monday 23 November 2026, 20:47, with microseconds as on a phone.
  final monday = DateTime(2026, 11, 23, 20, 47, 12, 345, 678);
  final tuesday = DateTime(2026, 11, 24);

  setUp(() {
    db = openTestDatabase();
    techniques = DriftTechniqueRepository(db);
    combos = DriftComboRepository(db, techniques);
    reviews = DriftReviewRepository(db);
  });
  tearDown(() => db.close());

  Future<Combo> create(List<String> slugs, {String? name, DateTime? now}) =>
      combos.create(
        name: name,
        steps: [for (final slug in slugs) step(slug)],
        now: now ?? monday,
      );

  group('techniques', () {
    test('the catalog read from the database is catalog.dart', () async {
      expect(await techniques.findAll(), catalog);
    });
  });

  group('T9 — a combo comes back identical (D9)', () {
    test('create, then read', () async {
      final created = await combos.create(
        name: 'Fin de round',
        steps: [
          step('jab'),
          step('hook', side: Side.rear, target: Target.body),
          step('low_kick'),
          step('slip'),
        ],
        now: monday,
      );
      expect(created.box, 1);
      expect(created.dueOn, tuesday);
      expect(await combos.findById(created.id), created);
    });

    test('the name is saved without spaces; empty means no name', () async {
      expect((await create(['jab', 'cross'], name: '  Base  ')).name, 'Base');
      final unnamed = await create(['jab', 'hook'], name: '   ');
      expect(unnamed.name, isNull);
      expect((await combos.findById(unnamed.id)).name, isNull);
    });

    test('the created combo does not share the caller\'s list', () async {
      final steps = [step('jab'), step('cross')];
      final created = await combos.create(steps: steps, now: monday);
      steps.add(step('hook'));
      expect(created.steps, hasLength(2));
      expect(() => created.steps.add(step('hook')), throwsUnsupportedError);
    });

    test('an invalid combo is refused before the database', () async {
      expect(() => create(['jab']), throwsArgumentError);
      expect(await combos.findAll(), isEmpty);
    });

    test('an unknown id', () async {
      await expectLater(combos.findById(99), throwsA(isA<NotFoundException>()));
    });
  });

  group('lists', () {
    test('findAll follows the review order of Leitner.compare (D7)', () async {
      final a = await create(['jab', 'cross']);
      final b = await create(['jab', 'hook'], now: DateTime(2026, 11, 20, 9));
      final c = await create(['jab', 'uppercut'], now: DateTime(2026, 11, 22));
      final d = await reviews.record(
        c,
        Grade.easy,
        now: DateTime(2026, 11, 22),
      );
      final all = await combos.findAll();
      expect(all, [...all]..sort(Leitner.compare));
      expect(all.map((x) => x.id), [b.id, a.id, d.id]);
    });

    test('findDue keeps only the combos due today or before (D6)', () async {
      final due = await create(['jab', 'cross'], now: DateTime(2026, 11, 20));
      final today = await create(['jab', 'hook']);
      await create(['jab', 'uppercut'], now: DateTime(2026, 11, 24, 8));
      expect((await combos.findDue(tuesday)).map((c) => c.id), [
        due.id,
        today.id,
      ]);
    });

    test('F25 — findWithTechnique keeps the combos that use it', () async {
      final both = await create(['teep', 'jab', 'cross']);
      await create(['jab', 'hook']);
      final last = await create(['low_kick', 'teep']);
      expect((await combos.findWithTechnique('teep')).map((c) => c.id), [
        both.id,
        last.id,
      ]);
      // All the steps come back, not only the matching one.
      expect((await combos.findWithTechnique('teep')).first, both);
      expect(await combos.findWithTechnique('clinch'), isEmpty);
      expect(await combos.findWithTechnique('unknown'), isEmpty);
    });

    test('each combo gets its own steps, in order', () async {
      await create(['jab', 'cross']);
      await create(['teep', 'low_kick', 'slip']);
      final all = await combos.findAll();
      expect(
        all[0].signature,
        ComboRules.signature([step('jab'), step('cross')]),
      );
      expect(all[1].steps.map((s) => s.technique.slug), [
        'teep',
        'low_kick',
        'slip',
      ]);
    });
  });

  group('duplicates (D8, F12)', () {
    test('the same steps under another name are refused', () async {
      final first = await create(['jab', 'cross'], name: 'Base');
      await expectLater(
        create(['jab', 'cross'], name: 'Ouverture'),
        throwsA(
          isA<DuplicateComboException>().having(
            (e) => e.existingId,
            'existingId',
            first.id,
          ),
        ),
      );
      expect(await combos.findAll(), hasLength(1));
    });

    test('the form can ask before saving', () async {
      final first = await create(['jab', 'cross']);
      expect(await combos.findIdBySignature(first.signature), first.id);
      expect(await combos.findIdBySignature('jab:lead:head'), isNull);
    });
  });

  group('update (F14)', () {
    test('replaces name and steps, keeps the rest', () async {
      final created = await create(['jab', 'cross', 'low_kick']);
      final reviewed = await reviews.record(created, Grade.good, now: tuesday);
      final later = DateTime(2026, 11, 25, 7);

      final updated = await combos.update(
        created.id,
        name: 'Nouveau',
        steps: [step('low_kick'), step('jab'), step('cross'), step('slip')],
        now: later,
      );

      expect(updated.name, 'Nouveau');
      expect(updated.steps.map((s) => s.technique.slug), [
        'low_kick',
        'jab',
        'cross',
        'slip',
      ]);
      expect(updated.updatedAt, later);
      expect(updated.createdAt, created.createdAt);
      expect(updated.box, reviewed.box);
      expect(updated.dueOn, reviewed.dueOn);
      expect(await reviews.countFor(created.id), 1);
      expect(await combos.findById(created.id), updated);
    });

    test('saving the same steps again is not a duplicate of itself', () async {
      final created = await create(['jab', 'cross']);
      final renamed = await combos.update(
        created.id,
        name: 'Base',
        steps: created.steps,
        now: tuesday,
      );
      expect(renamed.name, 'Base');
    });

    test('taking the steps of another combo is refused', () async {
      final first = await create(['jab', 'cross']);
      final second = await create(['jab', 'hook']);
      await expectLater(
        combos.update(second.id, steps: first.steps, now: tuesday),
        throwsA(isA<DuplicateComboException>()),
      );
      expect(await combos.findById(second.id), second);
    });

    test('an unknown id (R5)', () async {
      await expectLater(
        combos.update(99, steps: [step('jab'), step('cross')], now: tuesday),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('T11 — delete and transactions (R3, R4)', () {
    test('deleting a combo deletes its steps and reviews', () async {
      final created = await create(['jab', 'cross']);
      await reviews.record(created, Grade.hard, now: tuesday);
      await combos.delete(created.id);

      expect(await combos.findAll(), isEmpty);
      expect(await db.select(db.comboSteps).get(), isEmpty);
      expect(await db.select(db.reviews).get(), isEmpty);
    });

    test('deleting an unknown id (R5)', () async {
      await expectLater(combos.delete(99), throwsA(isA<NotFoundException>()));
    });

    test('a review moves the combo to its next box and due day', () async {
      final created = await create(['jab', 'cross']);
      final reviewed = await reviews.record(created, Grade.easy, now: tuesday);
      expect(reviewed.box, 3);
      expect(reviewed.dueOn, DateTime(2026, 12, 1));
      expect(await combos.findById(created.id), reviewed);
      expect(await reviews.countFor(created.id), 1);
    });

    test('if the review cannot be saved, the box does not move', () async {
      final created = await create(['jab', 'cross']);
      // Makes the second write of the transaction fail.
      await db.customStatement(
        'CREATE TRIGGER no_review BEFORE INSERT ON reviews '
        "BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(
        reviews.record(created, Grade.easy, now: tuesday),
        throwsA(anything),
      );
      expect(await combos.findById(created.id), created);
    });

    test('if a step cannot be saved, the combo is not saved', () async {
      await db.customStatement(
        'CREATE TRIGGER no_step BEFORE INSERT ON combo_steps '
        "BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(create(['jab', 'cross']), throwsA(anything));
      expect(await db.select(db.combos).get(), isEmpty);
    });

    test('a review of a deleted combo is refused', () async {
      final created = await create(['jab', 'cross']);
      await combos.delete(created.id);
      await expectLater(
        reviews.record(created, Grade.good, now: tuesday),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
