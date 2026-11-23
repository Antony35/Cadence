import 'dart:async';

import 'package:cadence/models/technique.dart';
import 'package:cadence/state/home_controller.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';

void main() {
  late FakeComboRepository repository;
  late FixedClock clock;
  late HomeController controller;

  setUp(() {
    repository = FakeComboRepository([
      combo(id: 1, name: 'Base', dueOn: DateTime(2026, 11, 21)),
      combo(
        id: 2,
        steps: [step('teep'), step('low_kick')],
        dueOn: DateTime(2026, 11, 23),
      ),
      combo(
        id: 3,
        steps: [step('jab'), step('elbow_horizontal')],
        dueOn: DateTime(2026, 11, 30),
      ),
    ]);
    clock = FixedClock();
    controller = HomeController(combos: repository, clock: clock);
  });
  tearDown(() => controller.dispose());

  List<int> visibleIds() =>
      controller.visibleCombos.map((combo) => combo.id).toList();

  group('the four states (S1)', () {
    test('loading, then ready, in review order', () async {
      repository.gate = Completer();
      final loading = controller.load();
      expect(controller.state, isA<Loading<Object>>());

      repository.gate!.complete();
      await loading;
      expect(controller.state, isA<Ready<Object>>());
      expect(visibleIds(), [1, 2, 3]);
    });

    test('no combo: empty, not an error', () async {
      repository.combos = [];
      await controller.load();
      expect(controller.state, isA<Empty<Object>>());
    });

    test('a read error: failed with a French message, never empty', () async {
      repository.error = Exception('disk I/O error');
      await controller.load();
      final state = controller.state;
      expect(state, isA<Failed<Object>>());
      expect(
        (state as Failed).message,
        'Impossible de lire vos enchaînements.',
      );
      expect(controller.visibleCombos, isEmpty);
    });

    test('« Réessayer » after an error', () async {
      repository.error = Exception('disk I/O error');
      await controller.load();
      repository.error = null;
      await controller.load();
      expect(controller.state, isA<Ready<Object>>());
    });

    test('a reload keeps the list on screen instead of a spinner', () async {
      await controller.load();
      repository.gate = Completer();
      final reload = controller.load();
      expect(controller.state, isA<Ready<Object>>());
      repository.gate!.complete();
      await reload;
    });

    test('nothing is notified once the screen is closed', () async {
      repository.gate = Completer();
      final loading = controller.load();
      controller.dispose();
      repository.gate!.complete();
      // Would throw if the disposed controller notified its listeners.
      await loading;
      // tearDown disposes again: start a fresh one for it.
      controller = HomeController(combos: repository, clock: clock);
    });
  });

  group('F1 — the « À réviser » card', () {
    test('counts on all the combos, whatever the search', () async {
      await controller.load();
      controller.search('teep');
      expect(controller.summary, (due: 2, overdue: 1, total: 3));
    });

    test('a reload after midnight moves « today »', () async {
      await controller.load();
      clock.time = DateTime(2026, 11, 30, 0, 5);
      await controller.load();
      expect(controller.today, DateTime(2026, 11, 30));
      expect(controller.summary, (due: 3, overdue: 2, total: 3));
    });
  });

  group('F4 — search and family filter', () {
    setUp(() => controller.load());

    test('the text matches a name or a technique', () {
      controller.search('base');
      expect(visibleIds(), [1]);
      controller.search('LOW');
      expect(visibleIds(), [2]);
    });

    test('the family keeps combos with one technique of it', () {
      controller.selectFamily(Family.elbow);
      expect(visibleIds(), [3]);
    });

    test('text and family combine', () {
      controller.selectFamily(Family.punch);
      controller.search('jab');
      expect(visibleIds(), [1, 3]);
      controller.selectFamily(Family.kick);
      expect(visibleIds(), isEmpty);
    });

    test('clearFilter shows everything again', () {
      controller.selectFamily(Family.knee);
      controller.search('x');
      controller.clearFilter();
      expect(controller.filter.isEmpty, isTrue);
      expect(visibleIds(), [1, 2, 3]);
    });

    test('each change notifies the screen', () {
      var notified = 0;
      controller.addListener(() => notified++);
      controller.search('jab');
      controller.selectFamily(Family.punch);
      controller.clearFilter();
      expect(notified, 3);
    });
  });
}
