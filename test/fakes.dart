import 'dart:async';

import 'package:cadence/data/exceptions.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/settings.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/screen_awake.dart';
import 'package:cadence/state/speaker.dart';

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
  Future<Combo> findById(int id) async {
    reads++;
    if (error case final error?) throw error;
    return combos.firstWhere(
      (c) => c.id == id,
      orElse: () => throw NotFoundException('combo', id),
    );
  }

  @override
  Future<int?> findIdBySignature(String signature) async =>
      combos.where((c) => c.signature == signature).firstOrNull?.id;

  /// When set, every write throws it.
  Object? writeError;

  /// When set, writes wait for it: the test sees the saving state.
  Completer<void>? writeGate;

  int writes = 0;

  Future<void> _write(String signature, {int? except}) async {
    writes++;
    if (writeGate case final gate?) await gate.future;
    if (writeError case final error?) throw error;
    final existing = await findIdBySignature(signature);
    if (existing != null && existing != except) {
      throw DuplicateComboException(existing);
    }
  }

  @override
  Future<Combo> create({
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  }) async {
    await _write(ComboRules.signature(steps));
    final trimmed = name?.trim();
    final combo = Combo(
      id: combos.fold(0, (max, c) => c.id > max ? c.id : max) + 1,
      name: trimmed == null || trimmed.isEmpty ? null : trimmed,
      steps: steps,
      box: Leitner.firstBox,
      dueOn: Leitner.firstDueOn(now),
      createdAt: now,
      updatedAt: now,
    );
    combos = [...combos, combo];
    return combo;
  }

  @override
  Future<Combo> update(
    int id, {
    String? name,
    required List<ComboStep> steps,
    required DateTime now,
  }) async {
    await _write(ComboRules.signature(steps), except: id);
    final old = await findById(id);
    final trimmed = name?.trim();
    final updated = old.copyWith(
      name: trimmed == null || trimmed.isEmpty ? null : trimmed,
      steps: steps,
      updatedAt: now,
    );
    combos = [for (final c in combos) c.id == id ? updated : c];
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    writes++;
    if (writeError case final error?) throw error;
    if (!combos.any((c) => c.id == id)) throw NotFoundException('combo', id);
    combos = combos.where((c) => c.id != id).toList();
  }
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
  /// [combos], when given, gets the new box and due day of each review, as
  /// the database would.
  FakeReviewRepository([this.combos]);

  final FakeComboRepository? combos;

  Map<int, int> counts = {};

  final recorded = <(int comboId, Grade grade)>[];

  /// When set, every record throws it.
  Object? error;

  @override
  Future<Combo> record(
    Combo combo,
    Grade grade, {
    required DateTime now,
  }) async {
    if (error case final error?) throw error;
    recorded.add((combo.id, grade));
    final box = Leitner.nextBox(combo.box, grade);
    final updated = combo.copyWith(box: box, dueOn: Leitner.dueOn(box, now));
    if (combos case final repository?) {
      repository.combos = [
        for (final c in repository.combos) c.id == combo.id ? updated : c,
      ];
    }
    return updated;
  }

  @override
  Future<int> countFor(int comboId) async => counts[comboId] ?? 0;
}

class FakeSpeaker implements Speaker {
  FakeSpeaker({this.available = true});

  final bool available;

  final said = <(String call, Pace pace)>[];
  int stops = 0;

  @override
  Future<bool> init() async => available;

  @override
  Future<void> speak(ComboStep step, Pace pace) async =>
      said.add((Drill.announcement(step, pace), pace));

  @override
  Future<void> stop() async => stops++;
}

class FakeScreenAwake implements ScreenAwake {
  bool on = false;

  @override
  Future<void> keepOn() async => on = true;

  @override
  Future<void> release() async => on = false;
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.stored = const Settings()]);

  Settings stored;
  Object? error;

  @override
  Future<Settings> load() async => stored;

  @override
  Future<void> save(Settings settings) async {
    if (error case final error?) throw error;
    stored = settings;
  }
}
