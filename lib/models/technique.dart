import 'package:freezed_annotation/freezed_annotation.dart';

part 'technique.freezed.dart';

/// The six families of the catalog, in display order.
///
/// The database stores [Enum.name] (`punch`, `elbow`…), the codes of the data
/// model, and the screens show [label].
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

/// Which arm or leg throws the technique.
enum Side {
  lead('avant'),
  rear('arrière');

  const Side(this.label);

  final String label;
}

/// Where the technique lands.
enum Target {
  head('à la tête'),
  body('au corps'),
  legs('à la cuisse');

  const Target(this.label);

  /// Written to follow a technique name: « Crochet au corps ».
  final String label;
}

/// A technique of the read-only catalog (`catalog.dart`).
///
/// The app identifies a technique by its [slug]: the database id and the
/// catalog position stay in the data layer.
@freezed
class Technique with _$Technique {
  const Technique({
    required this.slug,
    required this.name,
    required this.family,
    this.spokenName,
    this.sides = const {},
    this.targets = const {},
    this.defaultSide,
    this.defaultTarget,
  });

  /// Stable identifier (`low_kick`), also the image file name.
  final String slug;

  /// Name shown on screen, as used in French clubs (« Low kick »).
  final String name;

  final Family family;

  /// Phonetic spelling for the voice when it mispronounces [name].
  final String? spokenName;

  /// Accepted sides; empty for a technique without side (a defense).
  final Set<Side> sides;

  /// Accepted targets; empty when the target is in the name (Low kick).
  final Set<Target> targets;

  /// Preselected side, one of [sides].
  final Side? defaultSide;

  /// Preselected target, one of [targets].
  final Target? defaultTarget;

  /// What the voice says: [spokenName] if any, else [name].
  String get spoken => spokenName ?? name;

  /// True when there is nothing to choose before adding the technique (F9).
  bool get hasNoChoice => sides.length < 2 && targets.length < 2;
}
