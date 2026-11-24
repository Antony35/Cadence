import 'package:cadence/data/drift/converters.dart';
import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/drift/drift_technique_repository.dart';
import 'package:cadence/data/exceptions.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/leitner.dart';
import 'package:drift/drift.dart';

class DriftComboRepository implements ComboRepository {
  DriftComboRepository(this._db, this._techniques);

  final AppDatabase _db;
  final DriftTechniqueRepository _techniques;

  @override
  Future<List<Combo>> findAll() => _findWhere();

  @override
  Future<List<Combo>> findDue(DateTime today) => _findWhere(
    (combos) =>
        combos.dueOn.isSmallerOrEqualValue(const DayConverter().toSql(today)),
  );

  @override
  Future<List<Combo>> findWithTechnique(String slug) async {
    final techniqueId = (await _techniques.techniqueIdsBySlug())[slug];
    if (techniqueId == null) return const [];
    final usedIn = _db.selectOnly(_db.comboSteps)
      ..addColumns([_db.comboSteps.comboId])
      ..where(_db.comboSteps.techniqueId.equals(techniqueId));
    return _findWhere((combos) => combos.id.isInQuery(usedIn));
  }

  @override
  Future<Combo> findById(int id) async {
    final found = await _findWhere((combos) => combos.id.equals(id));
    if (found.isEmpty) throw NotFoundException('combo', id);
    return found.single;
  }

  @override
  Future<int?> findIdBySignature(String signature) async {
    final query = _db.selectOnly(_db.combos)
      ..addColumns([_db.combos.id])
      ..where(_db.combos.signature.equals(signature));
    final row = await query.getSingleOrNull();
    return row?.read(_db.combos.id);
  }

  @override
  Future<Combo> create({
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  }) {
    _validate(name, steps);
    final cleanName = _cleanName(name);
    final signature = ComboRules.signature(steps);
    final dueOn = Leitner.firstDueOn(now);

    return _db.transaction(() async {
      await _refuseDuplicate(signature);
      final id = await _db
          .into(_db.combos)
          .insert(
            CombosCompanion.insert(
              name: Value(cleanName),
              signature: signature,
              box: Leitner.firstBox,
              dueOn: dueOn,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _insertSteps(id, steps);
      return Combo(
        id: id,
        name: cleanName,
        // A copy: the caller's list may be the form's, still being edited.
        steps: List.unmodifiable(steps),
        box: Leitner.firstBox,
        dueOn: dueOn,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<Combo> update(
    int id, {
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  }) {
    _validate(name, steps);
    final cleanName = _cleanName(name);
    final signature = ComboRules.signature(steps);

    return _db.transaction(() async {
      await _refuseDuplicate(signature, exceptId: id);
      final updatedRows =
          await (_db.update(
            _db.combos,
          )..where((combo) => combo.id.equals(id))).write(
            CombosCompanion(
              name: Value(cleanName),
              signature: Value(signature),
              updatedAt: Value(now),
            ),
          );
      if (updatedRows == 0) throw NotFoundException('combo', id);

      // Replaced, not compared: moving one step shifts every position, and
      // (combo_id, position) is the primary key.
      await (_db.delete(
        _db.comboSteps,
      )..where((step) => step.comboId.equals(id))).go();
      await _insertSteps(id, steps);
      return findById(id);
    });
  }

  @override
  Future<void> delete(int id) async {
    // Steps and reviews go with it: ON DELETE CASCADE.
    final deletedRows = await (_db.delete(
      _db.combos,
    )..where((combo) => combo.id.equals(id))).go();
    if (deletedRows == 0) throw NotFoundException('combo', id);
  }

  // Two queries whatever the number of combos, not one per combo (N+1), in
  // one transaction so that an edit cannot slip in between them.
  Future<List<Combo>> _findWhere([
    Expression<bool> Function($CombosTable combos)? filter,
  ]) => _db.transaction(() async {
    final techniques = await _techniques.techniquesById();
    final combos = _db.combos;
    final comboSteps = _db.comboSteps;

    // Same order as Leitner.compare; the id breaks ties.
    final comboQuery = _db.select(combos)
      ..orderBy([
        (combo) => OrderingTerm.asc(combo.dueOn),
        (combo) => OrderingTerm.asc(combo.box),
        (combo) => OrderingTerm.asc(combo.createdAt),
        (combo) => OrderingTerm.asc(combo.id),
      ]);
    if (filter != null) comboQuery.where(filter);

    final stepQuery =
        _db.select(comboSteps).join([
          innerJoin(
            combos,
            combos.id.equalsExp(comboSteps.comboId),
            useColumns: false,
          ),
        ])..orderBy([
          OrderingTerm.asc(comboSteps.comboId),
          OrderingTerm.asc(comboSteps.position),
        ]);
    if (filter != null) stepQuery.where(filter(combos));

    final stepsByCombo = <int, List<ComboStep>>{};
    for (final result in await stepQuery.get()) {
      final row = result.readTable(comboSteps);
      (stepsByCombo[row.comboId] ??= []).add(
        ComboStep(
          // The foreign key guarantees the technique exists.
          technique: techniques[row.techniqueId]!,
          side: row.side,
          target: row.target,
        ),
      );
    }

    return [
      for (final row in await comboQuery.get())
        Combo(
          id: row.id,
          name: row.name,
          steps: stepsByCombo[row.id] ?? const [],
          box: row.box,
          dueOn: row.dueOn,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
    ];
  });

  // The UNIQUE constraint stays as a safety net, but its error is wrapped
  // differently in the app (background isolate) and in tests: not parsed.
  Future<void> _refuseDuplicate(String signature, {int? exceptId}) async {
    final existingId = await findIdBySignature(signature);
    if (existingId != null && existingId != exceptId) {
      throw DuplicateComboException(existingId);
    }
  }

  Future<void> _insertSteps(int comboId, List<ComboStep> steps) async {
    final techniqueIds = await _techniques.techniqueIdsBySlug();
    await _db.batch((batch) {
      batch.insertAll(_db.comboSteps, [
        for (final (position, step) in steps.indexed)
          ComboStepsCompanion.insert(
            comboId: comboId,
            position: position,
            techniqueId: techniqueIds[step.technique.slug]!,
            side: Value(step.side),
            target: Value(step.target),
          ),
      ]);
    });
  }

  static void _validate(String? name, List<ComboStep> steps) {
    if (ComboRules.validate(name, steps) case final error?) {
      throw ArgumentError('invalid combo: ${error.name}');
    }
  }

  static String? _cleanName(String? name) {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
