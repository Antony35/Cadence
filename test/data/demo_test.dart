import 'package:cadence/data/demo.dart';
import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/drift/drift_combo_repository.dart';
import 'package:cadence/data/drift/drift_review_repository.dart';
import 'package:cadence/data/drift/drift_technique_repository.dart';
import 'package:cadence/models/leitner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late DriftTechniqueRepository techniques;
  late DriftComboRepository combos;
  late DriftReviewRepository reviews;
  final now = DateTime(2026, 11, 30, 10);

  setUp(() {
    db = openTestDatabase();
    techniques = DriftTechniqueRepository(db);
    combos = DriftComboRepository(db, techniques);
    reviews = DriftReviewRepository(db);
  });
  tearDown(() => db.close());

  Future<void> load() => DemoData.loadIfEmpty(
    techniques: techniques,
    combos: combos,
    reviews: reviews,
    now: now,
  );

  test('is off unless the app is started with CADENCE_DEMO', () {
    expect(DemoData.enabled, isFalse);
  });

  test('ten valid combos, with due dates for every case', () async {
    await load();
    final all = await combos.findAll();
    expect(all, hasLength(10));
    expect(Leitner.summarize(all, now), (due: 5, overdue: 3, total: 10));
    expect(all.map((c) => c.box).toSet().length, greaterThan(2));
  });

  test('never added twice, nor to a notebook in use', () async {
    await load();
    await load();
    expect(await combos.findAll(), hasLength(10));
  });
}
