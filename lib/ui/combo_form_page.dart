import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/combo_form_controller.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/state/techniques_controller.dart';
import 'package:cadence/ui/combo_page.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/search_filter_bar.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:cadence/ui/widgets/step_sheet.dart';
import 'package:cadence/ui/widgets/technique_grid.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// E2: creates a combo, or edits [editing] (F6 to F15). Closes with the
/// saved combo as its result.
class ComboFormPage extends StatefulWidget {
  const ComboFormPage({super.key, this.editing});

  final Combo? editing;

  @override
  State<ComboFormPage> createState() => _ComboFormPageState();
}

class _ComboFormPageState extends State<ComboFormPage> {
  late final _form = ComboFormController(
    combos: context.read<ComboRepository>(),
    clock: context.read<Clock>(),
    editing: widget.editing,
  );

  /// The catalog and its search: the same controller as the Techniques
  /// screen, reused.
  late final _catalog = TechniquesController(
    techniques: context.read<TechniqueRepository>(),
  )..load();

  late final _name = TextEditingController(text: widget.editing?.name);

  /// Gives access to the [Form] below, to validate its fields.
  final _formKey = GlobalKey<FormState>();

  /// Moves the page back to the top, where the problem is shown.
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    _form.dispose();
    _catalog.dispose();
    _name.dispose();
    super.dispose();
  }

  /// F9: a technique without choice is added at once; the others open the
  /// technique window.
  Future<void> _addTechnique(Technique technique) async {
    _dismissKeyboard();
    if (technique.hasNoChoice) {
      _form.add(ComboStep.withDefaults(technique));
      return;
    }
    final edit = await showStepSheet(context, technique: technique);
    if (edit is SetStep) _form.add(edit.step);
  }

  /// Touching a technique ends the typing: the keyboard closes, and the
  /// field is forgotten, so that it does not take the focus back when the
  /// window closes (Flutter gives the focus back to the last focused field).
  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  /// F10: the same window, to correct, move or remove a step.
  Future<void> _editStep(int index) async {
    _dismissKeyboard();
    final step = _form.steps[index];
    final edit = await showStepSheet(
      context,
      technique: step.technique,
      current: step,
      canMoveBefore: index > 0,
      canMoveAfter: index < _form.steps.length - 1,
    );
    switch (edit) {
      case SetStep(:final step):
        _form.replace(index, step);
      case MoveStep(:final offset):
        _form.move(index, offset);
      case RemoveStep():
        _form.remove(index);
      case null:
        break; // Closed without choosing.
    }
  }

  Future<void> _save() async {
    // Like `$form->isValid()`: runs the validator of each field.
    if (!_formKey.currentState!.validate()) return;
    final combo = await _form.save(_name.text);
    if (!mounted) return;
    if (combo != null) {
      Navigator.pop(context, combo);
    } else if (_scroll.hasClients) {
      // F13: the screen stays open with the input; the message is at the top.
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// F15: leaving with unsaved input asks first.
  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner la saisie ?'),
        content: const Text('Les modifications seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  /// F12: « Ouvrir l'existant » replaces the form by the existing combo.
  void _openExisting(int id) => Navigator.pushReplacement(
    context,
    MaterialPageRoute<void>(builder: (_) => ComboPage(id: id)),
  );

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the sequence, the catalog or the name changes.
    return ListenableBuilder(
      listenable: Listenable.merge([_form, _catalog, _name]),
      builder: (context, _) {
        final saving = _form.saving;
        return PopScope(
          // The back button closes the screen only when nothing is lost.
          canPop: !_form.hasChanges(_name.text),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !saving) _confirmLeave();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _form.editing == null ? 'NOUVEL ENCHAÎNEMENT' : 'MODIFIER',
              ),
              bottom: saving
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(2),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : null,
            ),
            // At the bottom, full width, within reach of the thumb.
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  // F13: disabled while saving, so two touches save once.
                  onPressed: saving ? null : _save,
                  child: const Text('Enregistrer'),
                ),
              ),
            ),
            // One scrolling page: the name goes away under the bar, the
            // sequence and the search stay pinned, the grid scrolls below.
            body: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    // The Flutter equivalent of a FormType: the fields and
                    // their constraints.
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: ComboRules.maxNameLength,
                        // The counter shows the limit; the validator explains.
                        maxLengthEnforcement: MaxLengthEnforcement.none,
                        decoration: const InputDecoration(
                          labelText: 'Nom (facultatif)',
                          isDense: true,
                        ),
                        validator: (value) =>
                            (value?.trim().length ?? 0) >
                                ComboRules.maxNameLength
                            ? 'Le nom fait ${ComboRules.maxNameLength} '
                                  'caractères au plus.'
                            : null,
                      ),
                    ),
                  ),
                ),
                if (_form.problem case final problem?)
                  SliverToBoxAdapter(
                    child: _ProblemBanner(
                      problem,
                      onOpenExisting: _openExisting,
                    ),
                  ),
                _pinnedHeader(context),
                ..._catalogView(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The sequence and, once the catalog is read, the search: pinned at the
  /// top while the grid scrolls. A pinned header needs a fixed height,
  /// computed from the text size of the phone.
  Widget _pinnedHeader(BuildContext context) {
    final ready = _catalog.state is Ready;
    final height =
        _Sequence.height(context) +
        1 +
        (ready ? SearchFilterBar.height : 0) +
        4; // Slack for the rounding of text heights.
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FixedHeader(
        height: height,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Takes what the bar leaves: never a half pixel too much.
              Expanded(
                child: _Sequence(steps: _form.steps, onTap: _editStep),
              ),
              const Divider(),
              if (ready)
                SearchFilterBar(
                  filter: _catalog.filter,
                  onQueryChanged: _catalog.search,
                  onFamilyChanged: _catalog.selectFamily,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _catalogView() => switch (_catalog.state) {
    Loading() => const [SliverFillRemaining(child: LoadingView())],
    Failed(:final message) => [
      SliverFillRemaining(
        child: ErrorView(message: message, onRetry: _catalog.load),
      ),
    ],
    Empty() => const [],
    Ready() when _catalog.visible.isEmpty => [
      SliverFillRemaining(child: NoResultView(onClear: _catalog.clearFilter)),
    ],
    Ready() => [
      TechniqueGrid.sliver(
        techniques: _catalog.visible,
        // F11: at 12 steps, the grid is disabled.
        onTap: _form.isFull ? null : _addTechnique,
      ),
    ],
  };
}

/// A header of fixed [height] for [SliverPersistentHeader].
class _FixedHeader extends SliverPersistentHeaderDelegate {
  _FixedHeader({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_FixedHeader old) => true;
}

/// F7: the sequence being built, numbered, with « 3 / 12 ».
class _Sequence extends StatelessWidget {
  const _Sequence({required this.steps, required this.onTap});

  /// The title, then a row of [_StepTile]: their height grows with the text
  /// size of the phone (V4).
  static double height(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final text = Theme.of(context).textTheme;
    double line(TextStyle? style) =>
        scaler.scale(style!.fontSize!) * style.height!;
    return 12 + line(text.titleMedium) + _rowHeight(context);
  }

  static double _rowHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final text = Theme.of(context).textTheme;
    double line(TextStyle? style) =>
        scaler.scale(style!.fontSize!) * style.height!;
    return line(text.labelMedium) + 2 + 36 + 4 + 2 * line(text.bodySmall) + 8;
  }

  final List<ComboStep> steps;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text.rich(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            TextSpan(
              style: text.titleMedium,
              children: [
                const TextSpan(text: 'SÉQUENCE '),
                TextSpan(
                  text: '${steps.length} / ${ComboRules.maxSteps}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: _rowHeight(context),
          child: steps.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Touchez une technique pour l'ajouter.",
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: steps.length,
                  itemBuilder: (context, index) => _StepTile(
                    index: index,
                    step: steps[index],
                    onTap: () => onTap(index),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.onTap,
  });

  final int index;
  final ComboStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Text(
              stepNumber(index),
              style: text.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            TechniqueImage(step.technique, size: 36),
            const SizedBox(height: 4),
            Text(
              step.label,
              style: text.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Why the combo was not saved, kept on screen until the next change.
class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner(this.problem, {required this.onOpenExisting});

  final FormProblem problem;
  final ValueChanged<int> onOpenExisting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = switch (problem) {
      InvalidCombo(error: ComboError.tooFewSteps) =>
        'Ajoutez au moins ${ComboRules.minSteps} techniques.',
      InvalidCombo(error: ComboError.tooManySteps) =>
        'Un enchaînement compte ${ComboRules.maxSteps} techniques au plus.',
      InvalidCombo(error: ComboError.nameTooLong) =>
        'Le nom fait ${ComboRules.maxNameLength} caractères au plus.',
      DuplicateCombo() => 'Cet enchaînement existe déjà.',
      SaveFailed() =>
        "L'enregistrement a échoué. Votre saisie est conservée : "
            'réessayez.',
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          if (problem case DuplicateCombo(:final existingId))
            TextButton(
              onPressed: () => onOpenExisting(existingId),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onErrorContainer,
              ),
              child: const Text("Ouvrir l'existant"),
            ),
        ],
      ),
    );
  }
}
