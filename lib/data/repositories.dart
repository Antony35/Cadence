import 'package:cadence/data/exceptions.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';

abstract interface class TechniqueRepository {
  Future<List<Technique>> findAll();
}

abstract interface class ComboRepository {
  Future<List<Combo>> findAll();

  Future<List<Combo>> findDue(DateTime today);

  Future<List<Combo>> findWithTechnique(String slug);

  /// Throws [NotFoundException].
  Future<Combo> findById(int id);

  Future<int?> findIdBySignature(String signature);

  /// Saves in box 1, due the day after [now].
  ///
  /// Throws [DuplicateComboException], or [ArgumentError] when the steps
  /// break `ComboRules.validate`.
  Future<Combo> create({
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  });

  /// Keeps the box, the due day and the reviews.
  ///
  /// Throws [NotFoundException], [DuplicateComboException], [ArgumentError].
  Future<Combo> update(
    int id, {
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  });

  /// Throws [NotFoundException].
  Future<void> delete(int id);
}

abstract interface class ReviewRepository {
  /// Saves the review and the new due day in one transaction.
  ///
  /// Throws [NotFoundException].
  Future<Combo> record(Combo combo, Grade grade, {required DateTime now});

  Future<int> countFor(int comboId);
}
