import 'package:cadence/data/exceptions.dart';
import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/state/clock.dart';
import 'package:flutter/foundation.dart';

sealed class FormProblem {
  const FormProblem();
}

final class InvalidCombo extends FormProblem {
  const InvalidCombo(this.error);

  final ComboError error;
}

final class DuplicateCombo extends FormProblem {
  const DuplicateCombo(this.existingId);

  final int existingId;
}

final class SaveFailed extends FormProblem {
  const SaveFailed();
}

class ComboFormController extends ChangeNotifier {
  ComboFormController({
    required this._combos,
    required this._clock,
    this.editedCombo,
  }) : _steps = [...?editedCombo?.steps];

  final ComboRepository _combos;
  final Clock _clock;

  final Combo? editedCombo;

  final List<ComboStep> _steps;
  FormProblem? _problem;
  bool _saving = false;
  bool _disposed = false;

  List<ComboStep> get steps => List.unmodifiable(_steps);

  bool get isFull => _steps.length >= ComboRules.maxSteps;

  bool get isSaving => _saving;

  FormProblem? get problem => _problem;

  bool hasChanges(String name) =>
      name.trim() != (editedCombo?.name ?? '') ||
      ComboRules.signature(_steps) !=
          ComboRules.signature(editedCombo?.steps ?? const []);

  void addStep(ComboStep step) {
    if (isFull) return;
    _steps.add(step);
    _onStepsChanged();
  }

  void replaceStep(int index, ComboStep step) {
    _steps[index] = step;
    _onStepsChanged();
  }

  void moveStep(int index, int offset) {
    final newIndex = index + offset;
    if (newIndex < 0 || newIndex >= _steps.length) return;
    final step = _steps.removeAt(index);
    _steps.insert(newIndex, step);
    _onStepsChanged();
  }

  void removeStep(int index) {
    _steps.removeAt(index);
    _onStepsChanged();
  }

  Future<Combo?> save(String name) async {
    if (_saving) return null;

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
      final editedCombo = this.editedCombo;
      return editedCombo == null
          ? await _combos.create(name: name, steps: _steps, now: now)
          : await _combos.update(
              editedCombo.id,
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
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _onStepsChanged() {
    _problem = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
