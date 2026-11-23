import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('ComboStep', () {
    test('refuses a side or a target the technique does not accept', () {
      expect(() => step('jab', side: Side.rear), throwsArgumentError);
      expect(() => step('low_kick', target: Target.head), throwsArgumentError);
      expect(
        () => ComboStep(technique: technique('hook'), target: Target.head),
        throwsArgumentError,
        reason: 'a technique with sides needs one',
      );
    });

    test('accepts a technique without side nor target', () {
      expect(ComboStep(technique: technique('slip')).label, 'Esquive latérale');
    });

    test('withDefaults uses the preselected side and target', () {
      final hook = ComboStep.withDefaults(technique('hook'));
      expect(hook.side, Side.lead);
      expect(hook.target, Target.head);
    });

    test('two equal steps are equal (generated ==)', () {
      expect(step('hook'), step('hook'));
      expect(step('hook'), isNot(step('hook', side: Side.rear)));
    });
  });

  group('T3 — step labels and display name (D3, D4)', () {
    test('the side is said only when the technique accepts two', () {
      expect(step('jab').label, 'Jab');
      expect(step('cross').label, 'Direct');
      expect(step('hook', side: Side.rear).label, 'Crochet arrière');
      expect(step('low_kick').label, 'Low kick arrière');
    });

    test('the target is said only when it is not the default one', () {
      expect(step('hook', target: Target.body).label, 'Crochet avant au corps');
      expect(step('jab', target: Target.body).label, 'Jab au corps');
      expect(step('teep', target: Target.legs).label, 'Teep avant à la cuisse');
      expect(step('front_kick', side: Side.rear).label, 'Front kick arrière');
    });

    test('saidSide and saidTarget are what the label adds to the name', () {
      final hook = step('hook', side: Side.rear, target: Target.body);
      expect((hook.saidSide, hook.saidTarget), (Side.rear, Target.body));
      expect((step('jab').saidSide, step('jab').saidTarget), (null, null));
    });

    test('the display name is the name when filled in', () {
      final c = combo(name: '  Ouverture  ', dueOn: DateTime(2026, 11, 2));
      expect(c.displayName, 'Ouverture');
    });

    test('without a name, it joins the step labels', () {
      final steps = [step('jab'), step('cross'), step('low_kick')];
      expect(
        combo(steps: steps, dueOn: DateTime(2026, 11, 2)).displayName,
        'Jab · Direct · Low kick arrière',
      );
      expect(
        ComboRules.displayName('   ', steps),
        'Jab · Direct · Low kick arrière',
      );
    });
  });

  group('T4 — validation (F11)', () {
    List<ComboStep> steps(int count) =>
        List.generate(count, (_) => step('jab'));

    test('one step is refused', () {
      expect(ComboRules.validate(null, steps(1)), ComboError.tooFewSteps);
      expect(ComboRules.validate(null, []), ComboError.tooFewSteps);
    });

    test('2 and 12 steps are accepted', () {
      expect(ComboRules.validate(null, steps(2)), isNull);
      expect(ComboRules.validate(null, steps(12)), isNull);
    });

    test('a 13th step is refused', () {
      expect(ComboRules.validate(null, steps(13)), ComboError.tooManySteps);
    });

    test('the name holds 60 characters at most, spaces around excluded', () {
      expect(ComboRules.validate('a' * 60, steps(2)), isNull);
      expect(ComboRules.validate(' ${'a' * 60} ', steps(2)), isNull);
      expect(ComboRules.validate('a' * 61, steps(2)), ComboError.nameTooLong);
    });
  });

  group('T5 — signature (D8)', () {
    test('it ignores the name', () {
      final steps = [step('jab'), step('cross')];
      final a = combo(name: 'Base', steps: steps, dueOn: DateTime(2026, 11, 2));
      final b = combo(id: 2, steps: [...steps], dueOn: DateTime(2026, 11, 9));
      expect(a.signature, b.signature);
    });

    test('it changes when a side changes', () {
      expect(
        ComboRules.signature([step('jab'), step('hook')]),
        isNot(
          ComboRules.signature([step('jab'), step('hook', side: Side.rear)]),
        ),
      );
    });

    test('it changes when a target or the order changes', () {
      final base = ComboRules.signature([step('jab'), step('cross')]);
      expect(
        ComboRules.signature([step('jab'), step('cross', target: Target.body)]),
        isNot(base),
      );
      expect(ComboRules.signature([step('cross'), step('jab')]), isNot(base));
    });

    test('it is readable', () {
      expect(
        ComboRules.signature([step('jab'), step('low_kick'), step('slip')]),
        'jab:lead:head|low_kick:rear:-|slip:-:-',
      );
    });
  });
}
