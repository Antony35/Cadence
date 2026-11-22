import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter/foundation.dart';

/// The state of a technique sheet: the combos that use it (F25). The
/// technique itself comes from the catalog, already read.
class TechniqueController extends ChangeNotifier {
  TechniqueController({
    required this.technique,
    required this._combos,
    required this._clock,
  });

  final Technique technique;
  final ComboRepository _combos;
  final Clock _clock;

  LoadState<List<Combo>> _combosUsing = const Loading();
  late DateTime _today = dateOnly(_clock.now());
  bool _disposed = false;

  LoadState<List<Combo>> get combosUsing => _combosUsing;
  DateTime get today => _today;

  Future<void> load() async {
    // A reload keeps the list on screen.
    if (_combosUsing is! Ready) _set(const Loading());
    LoadState<List<Combo>> next;
    try {
      final combos = await _combos.findWithTechnique(technique.slug);
      next = combos.isEmpty ? const Empty() : Ready(combos);
    } catch (error) {
      debugPrint('TechniqueController.load: $error');
      next = const Failed('Impossible de lire les enchaînements.');
    }
    if (_disposed) return;
    _today = dateOnly(_clock.now());
    _set(next);
  }

  void _set(LoadState<List<Combo>> state) {
    _combosUsing = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
