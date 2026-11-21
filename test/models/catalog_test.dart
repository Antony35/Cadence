import 'package:cadence/models/catalog.dart';
import 'package:cadence/models/technique.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('T8 — the catalog is consistent (D1)', () {
    test('it holds 41 techniques with unique slugs and names', () {
      expect(catalog, hasLength(41));
      expect(catalog.map((t) => t.slug).toSet(), hasLength(41));
      expect(catalog.map((t) => t.name).toSet(), hasLength(41));
    });

    test('slugs are valid file names', () {
      for (final t in catalog) {
        expect(t.slug, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')), reason: t.slug);
      }
    });

    test('families follow each other in Family order', () {
      final indexes = catalog.map((t) => t.family.index).toList();
      expect(indexes, orderedEquals([...indexes]..sort()));
    });

    test('each family has its expected count', () {
      int count(Family f) => catalog.where((t) => t.family == f).length;
      expect(count(Family.punch), 8);
      expect(count(Family.elbow), 6);
      expect(count(Family.kick), 10);
      expect(count(Family.knee), 4);
      expect(count(Family.defense), 7);
      expect(count(Family.footwork), 6);
    });

    test('a default value exists exactly when there is a choice set', () {
      for (final t in catalog) {
        expect(t.defaultSide == null, t.sides.isEmpty, reason: t.slug);
        expect(t.defaultTarget == null, t.targets.isEmpty, reason: t.slug);
      }
    });

    test('default values belong to the accepted values', () {
      for (final t in catalog) {
        if (t.defaultSide case final side?) {
          expect(t.sides, contains(side), reason: t.slug);
        }
        if (t.defaultTarget case final target?) {
          expect(t.targets, contains(target), reason: t.slug);
        }
      }
    });

    test('defenses and footwork have no side and no target', () {
      for (final t in catalog.where(
        (t) => t.family == Family.defense || t.family == Family.footwork,
      )) {
        expect(t.sides, isEmpty, reason: t.slug);
        expect(t.targets, isEmpty, reason: t.slug);
        expect(t.hasNoChoice, isTrue, reason: t.slug);
      }
    });

    test('Jab is always lead and Direct always rear', () {
      final jab = catalog.firstWhere((t) => t.slug == 'jab');
      final cross = catalog.firstWhere((t) => t.slug == 'cross');
      expect(jab.sides, {Side.lead});
      expect(cross.sides, {Side.rear});
    });

    test('only the Teep reaches the thigh', () {
      final legs = catalog.where((t) => t.targets.contains(Target.legs));
      expect(legs.map((t) => t.slug), ['teep']);
    });

    test('the three mispronounced names have a spoken name', () {
      final spoken = {
        for (final t in catalog)
          if (t.spokenName != null) t.slug,
      };
      expect(spoken, {'jab', 'overhand', 'superman_punch'});
    });
  });
}
