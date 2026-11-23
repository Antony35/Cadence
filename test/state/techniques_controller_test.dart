import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/state/technique_controller.dart';
import 'package:cadence/state/techniques_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';

void main() {
  group('F24 — the Techniques screen', () {
    test('the 41 techniques, then searched and filtered', () async {
      final controller = TechniquesController(
        techniques: FakeTechniqueRepository(),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.visibleTechniques, hasLength(41));

      controller.selectFamily(Family.knee);
      expect(controller.visibleTechniques, hasLength(4));
      controller.search('saute');
      expect(controller.visibleTechniques.map((technique) => technique.slug), [
        'knee_jumping',
      ]);
    });

    test('a read error is shown as an error', () async {
      final controller = TechniquesController(
        techniques: FakeTechniqueRepository()..error = Exception('boom'),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.state, isA<Failed<Object>>());
    });
  });

  group('F25 — the technique sheet', () {
    test('lists the combos that use the technique', () async {
      final controller = TechniqueController(
        technique: technique('teep'),
        combos: FakeComboRepository([
          combo(id: 1, dueOn: DateTime(2026, 11, 24)),
          combo(
            id: 2,
            steps: [step('teep'), step('jab')],
            dueOn: DateTime(2026, 11, 24),
          ),
        ]),
        clock: FixedClock(),
      );
      addTearDown(controller.dispose);
      await controller.load();
      final state = controller.combosUsing as Ready<List<Combo>>;
      expect(state.data.map((c) => c.id), [2]);
    });

    test('no combo uses it: empty', () async {
      final controller = TechniqueController(
        technique: technique('clinch'),
        combos: FakeComboRepository(),
        clock: FixedClock(),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.combosUsing, isA<Empty<Object>>());
    });
  });
}
