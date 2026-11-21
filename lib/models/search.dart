import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';

/// The search text and the family filter of the C1 component. Both combine:
/// an item must match the text **and** the family.
class SearchFilter {
  const SearchFilter({this.query = '', this.family});

  final String query;

  /// Null means « Toutes ».
  final Family? family;

  /// True when nothing filters: the screen can tell « Aucun résultat » (S2)
  /// from an empty list.
  bool get isEmpty => normalize(query).isEmpty && family == null;

  /// F8, F24: on the technique name and its family.
  bool matchesTechnique(Technique technique) =>
      (family == null || technique.family == family) &&
      _matchesText([technique.name]);

  /// F4: on the combo name and its technique names; the family filter keeps
  /// a combo with at least one technique of the family.
  bool matchesCombo(Combo combo) {
    final techniques = combo.steps.map((step) => step.technique);
    return (family == null || techniques.any((t) => t.family == family)) &&
        _matchesText([?combo.name, ...techniques.map((t) => t.name)]);
  }

  bool _matchesText(Iterable<String> texts) {
    final wanted = normalize(query);
    return wanted.isEmpty ||
        texts.any((text) => normalize(text).contains(wanted));
  }
}

/// Lowercase, without accents and surrounding spaces, so that « É » matches
/// « e » (C1).
String normalize(String text) {
  final buffer = StringBuffer();
  for (final char in text.trim().toLowerCase().split('')) {
    buffer.write(_withoutAccent[char] ?? char);
  }
  return buffer.toString();
}

/// The accented letters of French. A small table is enough: no package.
const _withoutAccent = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'æ': 'ae',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'ô': 'o',
  'ö': 'o',
  'œ': 'oe',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ÿ': 'y',
};
