import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

/// What the user chose in the technique window. A `sealed` class, like the
/// load states: the form handles each case in an exhaustive `switch`.
sealed class StepEdit {
  const StepEdit();
}

/// « Ajouter » or « Valider »: the step with its side and target.
final class SetStep extends StepEdit {
  const SetStep(this.step);

  final ComboStep step;
}

/// « Avant » (-1) or « Après » (+1).
final class MoveStep extends StepEdit {
  const MoveStep(this.offset);

  final int offset;
}

/// « Retirer ».
final class RemoveStep extends StepEdit {
  const RemoveStep();
}

/// F9, F10: the technique window, a sheet that rises from the bottom.
///
/// For a new step, [current] is null and the window offers « Ajouter ».
/// For a step of the sequence, it also offers to move or remove it.
/// `await` waits until the user chooses; null means closed without choice.
Future<StepEdit?> showStepSheet(
  BuildContext context, {
  required Technique technique,
  ComboStep? current,
  bool canMoveBefore = false,
  bool canMoveAfter = false,
}) => showModalBottomSheet<StepEdit>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _StepSheet(
    technique: technique,
    current: current,
    canMoveBefore: canMoveBefore,
    canMoveAfter: canMoveAfter,
  ),
);

class _StepSheet extends StatefulWidget {
  const _StepSheet({
    required this.technique,
    required this.current,
    required this.canMoveBefore,
    required this.canMoveAfter,
  });

  final Technique technique;
  final ComboStep? current;
  final bool canMoveBefore;
  final bool canMoveAfter;

  @override
  State<_StepSheet> createState() => _StepSheetState();
}

/// The side and target being chosen are local state: they only matter to
/// this window, until « Ajouter ».
class _StepSheetState extends State<_StepSheet> {
  late Side? _side = widget.current?.side ?? widget.technique.defaultSide;
  late Target? _target =
      widget.current?.target ?? widget.technique.defaultTarget;

  ComboStep get _step =>
      ComboStep(technique: widget.technique, side: _side, target: _target);

  void _close(StepEdit edit) => Navigator.pop(context, edit);

  @override
  Widget build(BuildContext context) {
    final technique = widget.technique;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.current != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TechniqueImage(technique, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technique.name.toUpperCase(),
                        style: text.titleLarge,
                      ),
                      Text(
                        technique.family.label,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Only the choices the technique accepts (F9).
            if (technique.sides.length > 1) ...[
              _Label('Côté'),
              SegmentedButton<Side>(
                showSelectedIcon: false,
                segments: [
                  for (final side in Side.values)
                    if (technique.sides.contains(side))
                      ButtonSegment(value: side, label: Text(side.label)),
                ],
                selected: {?_side},
                onSelectionChanged: (chosen) =>
                    setState(() => _side = chosen.single),
              ),
            ],
            if (technique.targets.length > 1) ...[
              _Label('Cible'),
              SegmentedButton<Target>(
                showSelectedIcon: false,
                segments: [
                  for (final target in Target.values)
                    if (technique.targets.contains(target))
                      ButtonSegment(value: target, label: Text(target.label)),
                ],
                selected: {?_target},
                onSelectionChanged: (chosen) =>
                    setState(() => _target = chosen.single),
              ),
            ],
            const SizedBox(height: 24),
            // What the list and the voice will say (D3).
            Text(
              '« ${_step.label} »',
              style: text.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (editing) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.canMoveBefore
                          ? () => _close(const MoveStep(-1))
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Avant'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.canMoveAfter
                          ? () => _close(const MoveStep(1))
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Après'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _close(const RemoveStep()),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Retirer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: () => _close(SetStep(_step)),
              child: Text(editing ? 'Valider' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
