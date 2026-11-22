import 'package:cadence/data/exceptions.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter/foundation.dart';

/// What the combo sheet shows: the combo and its number of reviews (F16).
typedef ComboDetail = ({Combo combo, int reviews});

/// The state of the combo sheet (E3): reading it, deleting it.
class ComboController extends ChangeNotifier {
  ComboController({
    required this.id,
    required this._combos,
    required this._reviews,
    required this._clock,
  });

  final int id;
  final ComboRepository _combos;
  final ReviewRepository _reviews;
  final Clock _clock;

  LoadState<ComboDetail> _state = const Loading();
  late DateTime _today = dateOnly(_clock.now());
  bool _disposed = false;

  LoadState<ComboDetail> get state => _state;
  DateTime get today => _today;

  /// Like `find($id)` in Symfony, plus a count of the reviews.
  Future<void> load() async {
    if (_state is! Ready) _set(const Loading());
    LoadState<ComboDetail> next;
    try {
      final combo = await _combos.findById(id);
      final reviews = await _reviews.countFor(id);
      next = Ready((combo: combo, reviews: reviews));
    } on NotFoundException {
      next = const Failed("Cet enchaînement n'existe plus.");
    } catch (error) {
      debugPrint('ComboController.load: $error');
      next = const Failed('Impossible de lire cet enchaînement.');
    }
    if (_disposed) return;
    _today = dateOnly(_clock.now());
    _set(next);
  }

  /// F18, after the confirmation. True when the combo is gone.
  Future<bool> delete() async {
    try {
      await _combos.delete(id);
      return true;
    } on NotFoundException {
      return true; // Already gone: the result the user asked for.
    } catch (error) {
      debugPrint('ComboController.delete: $error');
      return false;
    }
  }

  void _set(LoadState<ComboDetail> state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
