import 'package:cadence/data/exceptions.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/load_state.dart';
import 'package:flutter/foundation.dart';

typedef ComboDetail = ({Combo combo, int reviewCount});

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

  Future<void> load() async {
    if (_state is! Ready) _setState(const Loading());
    LoadState<ComboDetail> next;
    try {
      final combo = await _combos.findById(id);
      final reviewCount = await _reviews.countFor(id);
      next = Ready((combo: combo, reviewCount: reviewCount));
    } on NotFoundException {
      next = const Empty(); // Deleted elsewhere: retrying cannot bring it back.
    } catch (error) {
      debugPrint('ComboController.load: $error');
      next = const Failed('Impossible de lire cet enchaînement.');
    }
    if (_disposed) return;
    _today = dateOnly(_clock.now());
    _setState(next);
  }

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

  void _setState(LoadState<ComboDetail> state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
