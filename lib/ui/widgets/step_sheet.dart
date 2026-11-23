import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

sealed class StepEdit {
  const StepEdit();
}

final class SetStep extends StepEdit {
  const SetStep(this.step);

  final ComboStep step;
}

final class MoveStep extends StepEdit {
  const MoveStep(this.offset);

  final int offset;
}

final class RemoveStep extends StepEdit {
  const RemoveStep();
}

Future<StepEdit?> showStepSheet(
  BuildContext context, {
  required Technique technique,
  ComboStep? editedStep,
  bool canMoveBefore = false,
  bool canMoveAfter = false,
}) => showModalBottomSheet<StepEdit>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _StepSheet(
    technique: technique,
    editedStep: editedStep,
    canMoveBefore: canMoveBefore,
    canMoveAfter: canMoveAfter,
  ),
);

class _StepSheet extends StatefulWidget {
  const _StepSheet({
    required this.technique,
    required this.editedStep,
    required this.canMoveBefore,
    required this.canMoveAfter,
  });

  final Technique technique;
  final ComboStep? editedStep;
  final bool canMoveBefore;
  final bool canMoveAfter;

  @override
  State<_StepSheet> createState() => _StepSheetState();
}

class _StepSheetState extends State<_StepSheet> {
  late Side? _side = widget.editedStep?.side ?? widget.technique.defaultSide;
  late Target? _target =
      widget.editedStep?.target ?? widget.technique.defaultTarget;

  ComboStep get _step =>
      ComboStep(technique: widget.technique, side: _side, target: _target);

  void _close(StepEdit edit) => Navigator.pop(context, edit);

  @override
  Widget build(BuildContext context) {
    final technique = widget.technique;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.editedStep != null;

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
            Text(
              '« ${_step.label} »',
              style: text.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isEditing) ...[
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
              child: Text(isEditing ? 'Valider' : 'Ajouter'),
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
