import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/technique.dart';
import 'package:drift/drift.dart';

class DriftTechniqueRepository implements TechniqueRepository {
  DriftTechniqueRepository(this._db);

  final AppDatabase _db;

  List<(int, Technique)>? _catalogCache;

  @override
  Future<List<Technique>> findAll() async => [
    for (final (_, technique) in await _catalogWithIds()) technique,
  ];

  Future<Map<int, Technique>> techniquesById() async => {
    for (final (id, technique) in await _catalogWithIds()) id: technique,
  };

  Future<Map<String, int>> techniqueIdsBySlug() async => {
    for (final (id, technique) in await _catalogWithIds()) technique.slug: id,
  };

  Future<List<(int, Technique)>> _catalogWithIds() async =>
      _catalogCache ??= await _readCatalog();

  Future<List<(int, Technique)>> _readCatalog() async {
    final rows = await (_db.select(
      _db.techniques,
    )..orderBy([(technique) => OrderingTerm.asc(technique.position)])).get();
    final sides = await _db.select(_db.techniqueSides).get();
    final targets = await _db.select(_db.techniqueTargets).get();

    return [
      for (final row in rows)
        (
          row.id,
          Technique(
            slug: row.slug,
            name: row.name,
            family: row.family,
            sides: {
              for (final side in sides)
                if (side.techniqueId == row.id) side.side,
            },
            targets: {
              for (final target in targets)
                if (target.techniqueId == row.id) target.target,
            },
            defaultSide: row.defaultSide,
            defaultTarget: row.defaultTarget,
          ),
        ),
    ];
  }
}
