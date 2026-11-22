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
  Future<List<Combo>> findAll() => _load();

  /// The optimized query of the session: SQLite reads only the due combos,
  /// through the index on `due_on`.
  @override
  Future<List<Combo>> findDue(DateTime today) => _load(
    (combos) =>
        combos.dueOn.isSmallerOrEqualValue(const DayConverter().toSql(today)),
  );

  /// `WHERE id IN (SELECT combo_id FROM combo_steps WHERE technique_id = ?)`,
  /// through the index on `combo_steps.technique_id`.
  @override
  Future<List<Combo>> findWithTechnique(String slug) async {
    final techniqueId = (await _techniques.idBySlug())[slug];
    if (techniqueId == null) return const [];
    final usedIn = _db.selectOnly(_db.comboSteps)
      ..addColumns([_db.comboSteps.comboId])
      ..where(_db.comboSteps.techniqueId.equals(techniqueId));
    return _load((combos) => combos.id.isInQuery(usedIn));
  }

  @override
  Future<Combo> findById(int id) async {
    final found = await _load((combos) => combos.id.equals(id));
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
    final cleanName = _clean(name);
    final signature = ComboRules.signature(steps);
    final dueOn = Leitner.firstDueOn(now);

    // R4: the combo and its steps are saved together, or not at all.
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
        steps: steps,
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
    final cleanName = _clean(name);
    final signature = ComboRules.signature(steps);

    return _db.transaction(() async {
      await _refuseDuplicate(signature, except: id);
      final updated =
          await (_db.update(_db.combos)..where((c) => c.id.equals(id))).write(
            CombosCompanion(
              name: Value(cleanName),
              signature: Value(signature),
              updatedAt: Value(now),
            ),
          );
      if (updated == 0) throw NotFoundException('combo', id);

      // The steps are replaced, not compared: moving one step shifts all the
      // positions, and (combo_id, position) is the primary key.
      await (_db.delete(
        _db.comboSteps,
      )..where((s) => s.comboId.equals(id))).go();
      await _insertSteps(id, steps);
      return findById(id);
    });
  }

  @override
  Future<void> delete(int id) async {
    // The steps and the reviews follow: ON DELETE CASCADE.
    final deleted = await (_db.delete(
      _db.combos,
    )..where((c) => c.id.equals(id))).go();
    if (deleted == 0) throw NotFoundException('combo', id);
  }

  /// Two queries whatever the number of combos (no N+1): the combos, then
  /// all their steps, joined to `combos` to apply the same [filter]. The
  /// steps are then put under their combo here.
  Future<List<Combo>> _load([
    Expression<bool> Function($CombosTable combos)? filter,
  ]) async {
    final techniques = await _techniques.byId();
    final combos = _db.combos;
    final comboSteps = _db.comboSteps;

    // D7, the same order as Leitner.compare; the id makes it total.
    final comboQuery = _db.select(combos)
      ..orderBy([
        (c) => OrderingTerm.asc(c.dueOn),
        (c) => OrderingTerm.asc(c.box),
        (c) => OrderingTerm.asc(c.createdAt),
        (c) => OrderingTerm.asc(c.id),
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
  }

  /// Checked inside the transaction, before writing. The UNIQUE constraint
  /// stays as a safety net, but its error arrives wrapped differently in the
  /// app (background isolate) and in the tests: it is not parsed.
  Future<void> _refuseDuplicate(String signature, {int? except}) async {
    final existingId = await findIdBySignature(signature);
    if (existingId != null && existingId != except) {
      throw DuplicateComboException(existingId);
    }
  }

  Future<void> _insertSteps(int comboId, List<ComboStep> steps) async {
    final ids = await _techniques.idBySlug();
    await _db.batch((batch) {
      batch.insertAll(_db.comboSteps, [
        for (final (position, step) in steps.indexed)
          ComboStepsCompanion.insert(
            comboId: comboId,
            position: position,
            techniqueId: ids[step.technique.slug]!,
            side: Value(step.side),
            target: Value(step.target),
          ),
      ]);
    });
  }

  /// The form validates first; reaching this is a programming error.
  static void _validate(String? name, List<ComboStep> steps) {
    if (ComboRules.validate(name, steps) case final error?) {
      throw ArgumentError('invalid combo: ${error.name}');
    }
  }

  /// Saved without the spaces around; an empty name is no name (D4).
  static String? _clean(String? name) {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
