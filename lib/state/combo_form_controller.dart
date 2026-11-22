import 'package:cadence/data/exceptions.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/state/clock.dart';
import 'package:flutter/foundation.dart';

/// Why the combo cannot be saved. The screen chooses the French words.
sealed class FormProblem {
  const FormProblem();
}

/// Fewer than 2 or more than 12 steps, or a name too long (F11).
final class InvalidCombo extends FormProblem {
  const InvalidCombo(this.error);

  final ComboError error;
}

/// The same sequence is already saved (F12).
final class DuplicateCombo extends FormProblem {
  const DuplicateCombo(this.existingId);

  final int existingId;
}

/// The database refused for another reason: the input is kept (F13).
final class SaveFailed extends FormProblem {
  const SaveFailed();
}

/// The state of the form (E2): the sequence being built, and the saving.
///
/// The same controller creates a combo, or edits [editing] (F14). The name
/// lives in the screen's text field, like a field of a Symfony form; it is
/// passed to [save].
class ComboFormController extends ChangeNotifier {
  ComboFormController({
    required this._combos,
    required this._clock,
    this.editing,
  }) : _steps = [...?editing?.steps];

  final ComboRepository _combos;
  final Clock _clock;

  /// The combo being edited, or null for a new one.
  final Combo? editing;

  final List<ComboStep> _steps;
  FormProblem? _problem;
  bool _saving = false;
  bool _disposed = false;

  /// A read-only view: the screen cannot change the list behind our back.
  List<ComboStep> get steps => List.unmodifiable(_steps);

  /// F11: at 12 steps, the grid is disabled.
  bool get isFull => _steps.length >= ComboRules.maxSteps;

  /// F13: true while saving; the button is disabled.
  bool get saving => _saving;

  FormProblem? get problem => _problem;

  /// F15: true when leaving would lose something.
  bool hasChanges(String name) =>
      name.trim() != (editing?.name ?? '') ||
      ComboRules.signature(_steps) !=
          ComboRules.signature(editing?.steps ?? const []);

  /// F9: adds a step at the end.
  void add(ComboStep step) {
    if (isFull) return;
    _steps.add(step);
    _changed();
  }

  /// F10: the step corrected in the technique window.
  void replace(int index, ComboStep step) {
    _steps[index] = step;
    _changed();
  }

  /// F10: moves a step one place before (-1) or after (+1).
  void move(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _steps.length) return;
    final step = _steps.removeAt(index);
    _steps.insert(target, step);
    _changed();
  }

  /// F10: removes a step.
  void remove(int index) {
    _steps.removeAt(index);
    _changed();
  }

  /// Saves the combo and returns it, or returns null and sets [problem].
  ///
  /// Like `isValid()` then `flush()` in Symfony: the rules are checked
  /// first, then the repository writes, and the database has the last word
  /// on duplicates.
  Future<Combo?> save(String name) async {
    if (_saving) return null; // F13: a second touch does nothing.

    if (ComboRules.validate(name, _steps) case final error?) {
      _problem = InvalidCombo(error);
      notifyListeners();
      return null;
    }

    _saving = true;
    _problem = null;
    notifyListeners();
    try {
      final now = _clock.now();
      final editing = this.editing;
      return editing == null
          ? await _combos.create(name: name, steps: _steps, now: now)
          : await _combos.update(
              editing.id,
              name: name,
              steps: _steps,
              now: now,
            );
    } on DuplicateComboException catch (error) {
      _problem = DuplicateCombo(error.existingId);
      return null;
    } catch (error) {
      debugPrint('ComboFormController.save: $error');
      _problem = const SaveFailed();
      return null;
    } finally {
      // Runs after the return or the catch, success or not.
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Any change of the sequence makes the previous problem obsolete.
  void _changed() {
    _problem = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
