import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/combo_controller.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/ui/combo_form_page.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/technique_page.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/fact_row.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ComboPage extends StatefulWidget {
  const ComboPage({super.key, required this.id});

  final int id;

  @override
  State<ComboPage> createState() => _ComboPageState();
}

class _ComboPageState extends State<ComboPage> {
  late final _controller = ComboController(
    id: widget.id,
    combos: context.read<ComboRepository>(),
    reviews: context.read<ReviewRepository>(),
    clock: context.read<Clock>(),
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit(Combo combo) async {
    await Navigator.push(
      context,
      MaterialPageRoute<Combo>(
        builder: (_) => ComboFormPage(editedCombo: combo),
      ),
    );
    if (!mounted) return;
    await _controller.load();
  }

  // The technique sheet links back to its combos, this one included: it may
  // have been edited or deleted from there.
  Future<void> _openTechnique(Technique technique) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TechniquePage(technique: technique),
      ),
    );
    if (!mounted) return;
    await _controller.load();
  }

  Future<void> _delete(Combo combo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${combo.displayName} » ?'),
        content: const Text(
          'Ses étapes et ses révisions seront supprimées. '
          'Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await _controller.delete();
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('La suppression a échoué.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text('ENCHAÎNEMENT'),
            actions: [
              if (state case Ready(data: (:final combo, reviewCount: _))) ...[
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(combo),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _delete(combo),
                ),
              ],
            ],
          ),
          body: switch (state) {
            Loading() => const LoadingView(),
            Failed(:final message) => ErrorView(
              message: message,
              onRetry: _controller.load,
            ),
            Empty() => const SizedBox.shrink(),
            Ready(:final data) => _details(data),
          },
        );
      },
    );
  }

  Widget _details(ComboDetail detail) {
    final (:combo, :reviewCount) = detail;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final due = dueLabel(combo.dueOn, _controller.today);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.gutter,
        vertical: 20,
      ),
      children: [
        Text(combo.displayName.toUpperCase(), style: text.headlineSmall),
        const SizedBox(height: 16),
        FactRow('Prochaine', '$due · ${dayLabel(combo.dueOn)}'),
        const SizedBox(height: 40),
        Text.rich(
          TextSpan(
            style: text.titleMedium,
            children: [
              const TextSpan(text: 'SÉQUENCE '),
              TextSpan(
                text: '${combo.steps.length}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        for (final (index, step) in combo.steps.indexed) ...[
          if (index > 0) const Divider(),
          InkWell(
            onTap: () => _openTechnique(step.technique),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      stepNumber(index),
                      style: text.titleMedium?.copyWith(color: scheme.primary),
                    ),
                  ),
                  TechniqueImage(step.technique, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.label, style: text.titleSmall),
                        Text(
                          step.technique.family.label,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
        FactRow('Révisions', plural(reviewCount, 'révision', 'révisions')),
        FactRow('Créé le', dayLabel(combo.createdAt)),
        FactRow('Modifié le', dayLabel(combo.updatedAt)),
      ],
    );
  }
}
