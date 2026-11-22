import 'package:cadence/data/drift/database.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/technique.dart';
import 'package:drift/drift.dart';

/// Reads the catalog from the database, its only source at run time (D1).
///
/// The catalog is read-only: it is read once, then kept in memory.
class DriftTechniqueRepository implements TechniqueRepository {
  DriftTechniqueRepository(this._db);

  final AppDatabase _db;

  /// Each technique with its database id, in catalog order.
  List<(int, Technique)>? _cache;

  @override
  Future<List<Technique>> findAll() async => [
    for (final (_, technique) in await _entries()) technique,
  ];

  /// For the combo repository: the id of a step row gives its technique.
  Future<Map<int, Technique>> byId() async => {
    for (final (id, technique) in await _entries()) id: technique,
  };

  /// For the combo repository: a step saves the id of its technique.
  Future<Map<String, int>> idBySlug() async => {
    for (final (id, technique) in await _entries()) technique.slug: id,
  };

  Future<List<(int, Technique)>> _entries() async => _cache ??= await _read();

  /// Three queries, assembled here: the techniques, their accepted sides and
  /// their accepted targets (one value per row, R3).
  Future<List<(int, Technique)>> _read() async {
    final rows = await (_db.select(
      _db.techniques,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
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
            spokenName: row.spokenName,
            sides: {
              for (final s in sides)
                if (s.techniqueId == row.id) s.side,
            },
            targets: {
              for (final t in targets)
                if (t.techniqueId == row.id) t.target,
            },
            defaultSide: row.defaultSide,
            defaultTarget: row.defaultTarget,
          ),
        ),
    ];
  }
}
