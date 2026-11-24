import 'package:cadence/state/combo_controller.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';

void main() {
  late FakeComboRepository combos;
  late FakeReviewRepository reviews;

  setUp(() {
    combos = FakeComboRepository([combo(id: 4, dueOn: DateTime(2026, 11, 24))]);
    reviews = FakeReviewRepository()..counts = {4: 3};
  });

  ComboController controllerFor(int id) {
    final controller = ComboController(
      id: id,
      combos: combos,
      reviews: reviews,
      clock: FixedClock(),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('F16 — the combo and its number of reviews', () async {
    final controller = controllerFor(4);
    await controller.load();
    final detail = (controller.state as Ready<ComboDetail>).data;
    expect(detail.combo.id, 4);
    expect(detail.reviewCount, 3);
  });

  test('a combo that no longer exists', () async {
    final controller = controllerFor(99);
    await controller.load();
    expect(controller.state, isA<Empty<ComboDetail>>());
  });

  test('F18 — delete', () async {
    final controller = controllerFor(4);
    expect(await controller.delete(), isTrue);
    expect(combos.combos, isEmpty);
  });

  test('a failed delete says so', () async {
    combos.writeError = Exception('disk I/O error');
    expect(await controllerFor(4).delete(), isFalse);
    expect(combos.combos, hasLength(1));
  });
}
