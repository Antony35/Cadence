import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/search.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter/foundation.dart';

/// The state of the main screen: the combos, the search and the figures of
/// the « À réviser » card (F1 to F4).
///
/// A [ChangeNotifier] keeps data and calls [notifyListeners] when it
/// changes; the screen listens and rebuilds. Unlike a Symfony controller,
/// it lives as long as the screen, not for one request.
class HomeController extends ChangeNotifier {
  // `this._combos`: the caller writes `combos:`, the field stays private.
  HomeController({required this._combos, required this._clock});

  final ComboRepository _combos;
  final Clock _clock;

  LoadState<List<Combo>> _state = const Loading();
  SearchFilter _filter = const SearchFilter();
  late DateTime _today = dateOnly(_clock.now());

  /// Counts the calls to [load]: only the result of the last one is kept.
  int _loads = 0;
  bool _disposed = false;

  LoadState<List<Combo>> get state => _state;
  SearchFilter get filter => _filter;

  /// The day the figures and the « Demain » labels are computed for.
  DateTime get today => _today;

  /// All the combos, or none while loading or after an error.
  List<Combo> get _all => switch (_state) {
    Ready(:final data) => data,
    _ => const [],
  };

  /// The combos that pass the search and the family filter (F4), still in
  /// review order (D7).
  List<Combo> get visible => _all.where(_filter.matchesCombo).toList();

  /// F1: computed on all the combos, whatever the search.
  ReviewSummary get summary => Leitner.summarize(_all, _today);

  /// Reads the combos. Called when the screen opens, when it comes back to
  /// the foreground (the day may have changed) and after « Réessayer ».
  Future<void> load() async {
    final call = ++_loads;
    // A reload keeps the list on screen: no spinner flashing on each return.
    if (_state is! Ready) _setState(const Loading());

    LoadState<List<Combo>> next;
    try {
      final combos = await _combos.findAll();
      next = combos.isEmpty ? const Empty() : Ready(combos);
    } catch (error) {
      debugPrint('HomeController.load: $error');
      next = const Failed('Impossible de lire vos enchaînements.');
    }

    // While waiting, the screen may have closed, or a newer load started.
    if (_disposed || call != _loads) return;
    _today = dateOnly(_clock.now());
    _setState(next);
  }

  void search(String query) {
    _filter = SearchFilter(query: query, family: _filter.family);
    notifyListeners();
  }

  /// Null means « Toutes ».
  void selectFamily(Family? family) {
    _filter = SearchFilter(query: _filter.query, family: family);
    notifyListeners();
  }

  /// « Tout effacer » of the « Aucun résultat » message (S2).
  void clearFilter() {
    _filter = const SearchFilter();
    notifyListeners();
  }

  void _setState(LoadState<List<Combo>> state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
