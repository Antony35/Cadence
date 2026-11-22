import 'package:cadence/data/drift/converters.dart';
import 'package:cadence/data/drift/tables.dart';
import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// The SQLite database of the app (R2): the six tables and the catalog.
///
/// The constructor takes the connection, so the tests open an in-memory
/// database and the app opens the `cadence.sqlite` file ([AppDatabase.open]).
@DriftDatabase(
  tables: [
    Techniques,
    TechniqueSides,
    TechniqueTargets,
    Combos,
    ComboSteps,
    Reviews,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The file of the app, in its private folder.
  AppDatabase.open() : this(driftDatabase(name: 'cadence'));

  /// Bumped with each change of the tables, together with a migration step
  /// and a snapshot in `drift_schemas/`.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _insertCatalog();
    },
    // SQLite ignores foreign keys unless asked, on every connection.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// D1: the 41 techniques, in the order of `catalog.dart`: the first one
  /// gets position 1.
  Future<void> _insertCatalog() async {
    for (final (index, technique) in catalog.indexed) {
      final id = await into(techniques).insert(
        TechniquesCompanion.insert(
          slug: technique.slug,
          name: technique.name,
          spokenName: Value(technique.spokenName),
          family: technique.family,
          defaultSide: Value(technique.defaultSide),
          defaultTarget: Value(technique.defaultTarget),
          position: index + 1,
        ),
      );
      for (final side in technique.sides) {
        await into(
          techniqueSides,
        ).insert(TechniqueSidesCompanion.insert(techniqueId: id, side: side));
      }
      for (final target in technique.targets) {
        await into(techniqueTargets).insert(
          TechniqueTargetsCompanion.insert(techniqueId: id, target: target),
        );
      }
    }
  }
}
