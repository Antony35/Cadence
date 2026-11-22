import 'package:cadence/data/exceptions.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';

// The contracts of the data layer (R1). The state layer only knows these
// interfaces: the drift implementations live in `data/drift/`, and the
// widget tests will use fakes in memory.
//
// Every method is asynchronous: it returns a Future, the promise of a
// result, because reading the disk takes time and must not freeze the screen.

abstract interface class TechniqueRepository {
  /// The catalog, in its display order (`ORDER BY position`).
  Future<List<Technique>> findAll();
}

abstract interface class ComboRepository {
  /// All combos, in review order (D7): the list of the main screen (F3).
  Future<List<Combo>> findAll();

  /// Only the combos due on [today] or before (D6), in review order.
  Future<List<Combo>> findDue(DateTime today);

  /// The combos that use the technique [slug] at least once, in review
  /// order: the « Utilisée dans » list of the technique sheet (F25).
  Future<List<Combo>> findWithTechnique(String slug);

  /// Throws [NotFoundException].
  Future<Combo> findById(int id);

  /// The id of the combo that has [signature], to warn before saving (F12).
  Future<int?> findIdBySignature(String signature);

  /// Saves a new combo in box 1, due the day after [now].
  ///
  /// Throws [DuplicateComboException]. The [name] and [steps] must pass
  /// `ComboRules.validate`, else it throws an [ArgumentError].
  Future<Combo> create({
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  });

  /// Replaces the name and the steps; keeps the id, the creation date, the
  /// box, the due day and the reviews (F14).
  ///
  /// Throws [NotFoundException], [DuplicateComboException], [ArgumentError].
  Future<Combo> update(
    int id, {
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  });

  /// Deletes the combo with its steps and reviews (F18).
  ///
  /// Throws [NotFoundException].
  Future<void> delete(int id);
}

abstract interface class ReviewRepository {
  /// Saves the [grade] and moves [combo] to its next box and due day (D5),
  /// in one transaction (R4). Returns the updated combo.
  ///
  /// Throws [NotFoundException].
  Future<Combo> record(Combo combo, Grade grade, {required DateTime now});

  /// The number of reviews of a combo (F16).
  Future<int> countFor(int comboId);
}
