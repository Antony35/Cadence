import 'package:freezed_annotation/freezed_annotation.dart';

part 'technique.freezed.dart';

enum Family {
  punch('Poings'),
  elbow('Coudes'),
  kick('Pieds'),
  knee('Genoux'),
  defense('Défenses'),
  footwork('Déplacements');

  const Family(this.label);

  final String label;
}

enum Side {
  lead('avant'),
  rear('arrière');

  const Side(this.label);

  final String label;
}

enum Target {
  head('à la tête', 'tête'),
  body('au corps', 'corps'),
  legs('à la cuisse', 'cuisse');

  const Target(this.label, this.shortLabel);

  final String label;

  final String shortLabel;
}

@freezed
class Technique with _$Technique {
  const Technique({
    required this.slug,
    required this.name,
    required this.family,
    this.sides = const {},
    this.targets = const {},
    this.defaultSide,
    this.defaultTarget,
  });

  final String slug;

  final String name;

  final Family family;

  final Set<Side> sides;

  // Empty when the name says the target: Low kick.
  final Set<Target> targets;

  final Side? defaultSide;

  final Target? defaultTarget;

  bool get hasNoChoice => sides.length < 2 && targets.length < 2;
}
