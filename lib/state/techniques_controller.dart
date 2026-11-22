import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/search.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter/foundation.dart';

/// The state of the Techniques screen: the catalog and its search (F24).
class TechniquesController extends ChangeNotifier {
  TechniquesController({required this._techniques});

  final TechniqueRepository _techniques;

  LoadState<List<Technique>> _state = const Loading();
  SearchFilter _filter = const SearchFilter();
  bool _disposed = false;

  LoadState<List<Technique>> get state => _state;
  SearchFilter get filter => _filter;

  List<Technique> get visible => switch (_state) {
    Ready(:final data) => data.where(_filter.matchesTechnique).toList(),
    _ => const [],
  };

  Future<void> load() async {
    _setState(const Loading());
    LoadState<List<Technique>> next;
    try {
      final techniques = await _techniques.findAll();
      next = techniques.isEmpty ? const Empty() : Ready(techniques);
    } catch (error) {
      debugPrint('TechniquesController.load: $error');
      next = const Failed('Impossible de lire le catalogue des techniques.');
    }
    if (_disposed) return;
    _setState(next);
  }

  void search(String query) {
    _filter = SearchFilter(query: query, family: _filter.family);
    notifyListeners();
  }

  void selectFamily(Family? family) {
    _filter = SearchFilter(query: _filter.query, family: family);
    notifyListeners();
  }

  void clearFilter() {
    _filter = const SearchFilter();
    notifyListeners();
  }

  void _setState(LoadState<List<Technique>> state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
