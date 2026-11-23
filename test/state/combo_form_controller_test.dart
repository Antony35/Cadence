import 'dart:async';

import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/combo_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';

void main() {
  late FakeComboRepository repository;
  late ComboFormController form;

  setUp(() {
    repository = FakeComboRepository();
    form = ComboFormController(combos: repository, clock: FixedClock());
  });
  tearDown(() => form.dispose());

  List<String> slugs() => form.steps.map((s) => s.technique.slug).toList();

  group('building the sequence (F9, F10, F11)', () {
    test('add, replace, move and remove', () {
      form
        ..addStep(step('jab'))
        ..addStep(step('cross'))
        ..addStep(step('low_kick'));
      expect(slugs(), ['jab', 'cross', 'low_kick']);

      form.replaceStep(0, step('hook', side: Side.rear, target: Target.body));
      expect(form.steps.first.label, 'Crochet arrière au corps');

      form.moveStep(2, -1);
      expect(slugs(), ['hook', 'low_kick', 'cross']);
      form.moveStep(0, -1); // Already first: nothing moves.
      expect(slugs(), ['hook', 'low_kick', 'cross']);

      form.removeStep(1);
      expect(slugs(), ['hook', 'cross']);
    });

    test('no more than 12 steps', () {
      for (var i = 0; i < 13; i++) {
        form.addStep(step(i.isEven ? 'jab' : 'cross'));
      }
      expect(form.steps, hasLength(ComboRules.maxSteps));
      expect(form.isFull, isTrue);
    });

    test('the screen cannot change the list behind the controller', () {
      expect(() => form.steps.add(step('jab')), throwsUnsupportedError);
    });
  });

  group('saving', () {
    test('T13 — one step: refused before the database', () async {
      form.addStep(step('jab'));
      expect(await form.save(''), isNull);
      expect(form.problem, isA<InvalidCombo>());
      expect(repository.writes, 0);
      // Any change clears the message.
      form.addStep(step('cross'));
      expect(form.problem, isNull);
    });

    test('a valid combo is created, due tomorrow', () async {
      form
        ..addStep(step('jab'))
        ..addStep(step('cross'));
      final combo = await form.save('  Base  ');
      expect(combo?.name, 'Base');
      expect(combo?.dueOn, DateTime(2026, 11, 24));
      expect(repository.combos, hasLength(1));
    });

    test('F12 — a duplicate gives the id of the existing combo', () async {
      repository.combos = [combo(id: 7, dueOn: DateTime(2026, 11, 24))];
      form
        ..addStep(step('jab'))
        ..addStep(step('cross'));
      expect(await form.save('Autre nom'), isNull);
      expect((form.problem! as DuplicateCombo).existingId, 7);
    });

    test('F13 — a failure keeps the sequence', () async {
      repository.writeError = Exception('disk full');
      form
        ..addStep(step('jab'))
        ..addStep(step('cross'));
      expect(await form.save(''), isNull);
      expect(form.problem, isA<SaveFailed>());
      expect(form.steps, hasLength(2));
      expect(form.isSaving, isFalse);
    });

    test('F13 — two touches save once', () async {
      repository.writeGate = Completer();
      form
        ..addStep(step('jab'))
        ..addStep(step('cross'));
      final first = form.save('');
      expect(form.isSaving, isTrue);
      expect(await form.save(''), isNull);
      repository.writeGate!.complete();
      expect(await first, isNotNull);
      expect(repository.writes, 1);
    });
  });

  group('editing (F14, F15)', () {
    test('keeps the id and replaces the steps', () async {
      final original = combo(id: 3, name: 'Base', dueOn: DateTime(2026, 12, 1));
      repository.combos = [original];
      final edit = ComboFormController(
        combos: repository,
        clock: FixedClock(),
        editedCombo: original,
      );
      addTearDown(edit.dispose);

      expect(edit.hasChanges('Base'), isFalse);
      edit.addStep(step('low_kick'));
      expect(edit.hasChanges('Base'), isTrue);

      final saved = await edit.save('Base');
      expect(saved?.id, 3);
      expect(saved?.dueOn, original.dueOn);
      expect(saved?.steps.last.technique.slug, 'low_kick');
    });

    test('a new form has changes once a name is typed', () {
      expect(form.hasChanges(''), isFalse);
      expect(form.hasChanges('Base'), isTrue);
    });
  });
}
