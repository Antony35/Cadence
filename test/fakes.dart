import 'dart:async';

import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';

// Fakes of the services, in memory, for the controller and widget tests:
// no database, and a test decides what a read returns or when it fails.

/// Monday 23 November 2026, 9:00.
final monday = DateTime(2026, 11, 23, 9);

class FixedClock extends Clock {
  FixedClock([DateTime? time]) : time = time ?? monday;

  DateTime time;

  @override
  DateTime now() => time;
}

class FakeComboRepository implements ComboRepository {
  FakeComboRepository([List<Combo> combos = const []]) : combos = [...combos];

  List<Combo> combos;

  /// When set, every read throws it.
  Object? error;

  /// When set, reads wait for it: the test sees the loading state.
  Completer<void>? gate;

  int reads = 0;

  Future<List<Combo>> _read(bool Function(Combo) keep) async {
    reads++;
    if (gate case final gate?) await gate.future;
    if (error case final error?) throw error;
    return combos.where(keep).toList()..sort(Leitner.compare);
  }

  @override
  Future<List<Combo>> findAll() => _read((_) => true);

  @override
  Future<List<Combo>> findWithTechnique(String slug) =>
      _read((c) => c.steps.any((s) => s.technique.slug == slug));

  @override
  Future<List<Combo>> findDue(DateTime today) =>
      _read((c) => Leitner.isDue(c, today));

  @override
  Future<Combo> findById(int id) => throw UnimplementedError();

  @override
  Future<int?> findIdBySignature(String signature) =>
      throw UnimplementedError();

  @override
  Future<Combo> create({
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  }) => throw UnimplementedError();

  @override
  Future<Combo> update(
    int id, {
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(int id) => throw UnimplementedError();
}

class FakeTechniqueRepository implements TechniqueRepository {
  Object? error;

  @override
  Future<List<Technique>> findAll() async {
    if (error case final error?) throw error;
    return catalog;
  }
}

class FakeReviewRepository implements ReviewRepository {
  @override
  Future<Combo> record(Combo combo, Grade grade, {required DateTime now}) =>
      throw UnimplementedError();

  @override
  Future<int> countFor(int comboId) => throw UnimplementedError();
}
