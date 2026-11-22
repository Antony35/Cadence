import 'package:cadence/ui/app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

/// Starts the whole app on fake services, on Monday 23 November.
Future<void> pumpApp(
  WidgetTester tester, {
  FakeComboRepository? combos,
  FakeTechniqueRepository? techniques,
  FakeReviewRepository? reviews,
}) async {
  await tester.pumpWidget(
    CadenceApp(
      techniques: techniques ?? FakeTechniqueRepository(),
      combos: combos ?? FakeComboRepository(),
      reviews: reviews ?? FakeReviewRepository(),
      clock: FixedClock(),
    ),
  );
  // One more frame: the fake read has answered, the screen shows it.
  await tester.pump();
}
