import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/search.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter/foundation.dart';

class HomeController extends ChangeNotifier {
  HomeController({required this._combos, required this._clock});

  final ComboRepository _combos;
  final Clock _clock;

  LoadState<List<Combo>> _state = const Loading();
  SearchFilter _filter = const SearchFilter();
  late DateTime _today = dateOnly(_clock.now());

  int _loadCount = 0;
  bool _disposed = false;

  LoadState<List<Combo>> get state => _state;
  SearchFilter get filter => _filter;

  DateTime get today => _today;

  List<Combo> get _allCombos => switch (_state) {
    Ready(:final data) => data,
    _ => const [],
  };

  List<Combo> get visibleCombos =>
      _allCombos.where(_filter.matchesCombo).toList();

  ReviewSummary get summary => Leitner.summarize(_allCombos, _today);

  Future<void> load() async {
    final thisLoad = ++_loadCount;
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
    if (_disposed || thisLoad != _loadCount) return;
    _today = dateOnly(_clock.now());
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
