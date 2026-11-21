import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/search.dart';
import 'package:cadence/models/technique.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('T6 — search and family filter (C1)', () {
    test('normalize ignores case, accents and surrounding spaces', () {
      expect(normalize('  Décalage '), 'decalage');
      expect(normalize('ÉPÂULE'), 'epaule');
      expect(normalize('Cœur'), 'coeur');
    });

    test('the search finds a technique without accents nor capitals', () {
      const filter = SearchFilter(query: ' esquive LATERALE');
      final found = catalog.where(filter.matchesTechnique);
      expect(found.map((t) => t.slug), ['slip']);
    });

    test('an empty filter keeps everything', () {
      const filter = SearchFilter(query: '   ');
      expect(filter.isEmpty, isTrue);
      expect(catalog.where(filter.matchesTechnique), hasLength(41));
    });

    test('text and family combine', () {
      const sauteElbows = SearchFilter(query: 'saute', family: Family.elbow);
      final found = catalog.where(sauteElbows.matchesTechnique);
      expect(found.map((t) => t.slug), ['elbow_jumping']);
      expect(sauteElbows.isEmpty, isFalse);
    });

    test('a combo matches on its name or its technique names', () {
      final c = combo(
        name: 'Fin de round',
        steps: [step('jab'), step('low_kick')],
        dueOn: DateTime(2026, 11, 2),
      );
      expect(const SearchFilter(query: 'round').matchesCombo(c), isTrue);
      expect(const SearchFilter(query: 'low').matchesCombo(c), isTrue);
      expect(const SearchFilter(query: 'crochet').matchesCombo(c), isFalse);
    });

    test('the family filter keeps a combo with one technique of it', () {
      final c = combo(
        steps: [step('jab'), step('elbow_horizontal')],
        dueOn: DateTime(2026, 11, 2),
      );
      expect(const SearchFilter(family: Family.elbow).matchesCombo(c), isTrue);
      expect(const SearchFilter(family: Family.kick).matchesCombo(c), isFalse);
      expect(
        const SearchFilter(query: 'jab', family: Family.kick).matchesCombo(c),
        isFalse,
        reason: 'the text matches but not the family',
      );
    });
  });
}
