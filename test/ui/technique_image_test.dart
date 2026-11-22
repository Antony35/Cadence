import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter_test/flutter_test.dart';

import '../models/fixtures.dart';

void main() {
  const images = TechniqueImages({
    'assets/techniques/jab.png',
    'assets/techniques/family_punch.png',
    'assets/techniques/family_kick.png',
  });

  test('D2 — the technique image first', () {
    expect(images.pathOf(technique('jab')), 'assets/techniques/jab.png');
  });

  test('D2 — else the image of its family', () {
    expect(
      images.pathOf(technique('cross')),
      'assets/techniques/family_punch.png',
    );
    expect(
      images.familyPathOf(Family.kick),
      'assets/techniques/family_kick.png',
    );
  });

  test('D2 — else nothing: the screen draws the family badge', () {
    expect(images.pathOf(technique('elbow_horizontal')), isNull);
    expect(const TechniqueImages.none().pathOf(technique('jab')), isNull);
  });
}
