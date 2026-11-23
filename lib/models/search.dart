import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';

class SearchFilter {
  const SearchFilter({this.query = '', this.family});

  final String query;

  final Family? family;

  bool get isEmpty => normalize(query).isEmpty && family == null;

  bool matchesTechnique(Technique technique) =>
      (family == null || technique.family == family) &&
      _matchesText([technique.name]);

  bool matchesCombo(Combo combo) {
    final techniques = combo.steps.map((step) => step.technique);
    return (family == null ||
            techniques.any((technique) => technique.family == family)) &&
        _matchesText([
          ?combo.name,
          ...techniques.map((technique) => technique.name),
        ]);
  }

  bool _matchesText(Iterable<String> texts) {
    final normalizedQuery = normalize(query);
    return normalizedQuery.isEmpty ||
        texts.any((text) => normalize(text).contains(normalizedQuery));
  }
}

String normalize(String text) {
  final buffer = StringBuffer();
  for (final char in text.trim().toLowerCase().split('')) {
    buffer.write(_withoutAccent[char] ?? char);
  }
  return buffer.toString();
}

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
