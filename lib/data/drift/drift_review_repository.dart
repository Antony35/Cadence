import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/exceptions.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/review.dart';
import 'package:drift/drift.dart';

class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Combo> record(Combo combo, Grade grade, {required DateTime now}) {
    final box = Leitner.nextBox(combo.box, grade);
    final dueOn = Leitner.dueOn(box, now);

    // R4: the review and the new due day are saved together. Any query run
    // inside this callback belongs to the transaction; an exception cancels
    // all of it (rollback).
    return _db.transaction(() async {
      final updated =
          await (_db.update(_db.combos)..where((c) => c.id.equals(combo.id)))
              .write(CombosCompanion(box: Value(box), dueOn: Value(dueOn)));
      if (updated == 0) throw NotFoundException('combo', combo.id);

      await _db
          .into(_db.reviews)
          .insert(
            ReviewsCompanion.insert(
              comboId: combo.id,
              reviewedAt: now,
              grade: grade,
            ),
          );
      // A review is not an edit: updatedAt does not move.
      return combo.copyWith(box: box, dueOn: dueOn);
    });
  }

  @override
  Future<int> countFor(int comboId) async {
    final count = _db.reviews.id.count();
    final query = _db.selectOnly(_db.reviews)
      ..addColumns([count])
      ..where(_db.reviews.comboId.equals(comboId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}
