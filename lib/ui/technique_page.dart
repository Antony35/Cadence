import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/state/technique_controller.dart';
import 'package:cadence/ui/combo_page.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/combo_tile.dart';
import 'package:cadence/ui/widgets/fact_row.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TechniquePage extends StatefulWidget {
  const TechniquePage({super.key, required this.technique});

  final Technique technique;

  @override
  State<TechniquePage> createState() => _TechniquePageState();
}

class _TechniquePageState extends State<TechniquePage> {
  late final _controller = TechniqueController(
    technique: widget.technique,
    combos: context.read<ComboRepository>(),
    clock: context.read<Clock>(),
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(builder: (_) => ComboPage(id: id)),
    );
    if (!mounted) return;
    await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final technique = widget.technique;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(technique.family.label.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter,
          vertical: 20,
        ),
        children: [
          Center(child: TechniqueImage(technique, size: 220)),
          const SizedBox(height: 24),
          Text(technique.name.toUpperCase(), style: text.headlineSmall),
          const SizedBox(height: 16),
          FactRow('Famille', technique.family.label),
          if (sidesText(technique.sides) case final sides?)
            FactRow('Côté', sides),
          if (targetsText(technique.targets) case final targets?)
            FactRow('Cible', targets),
          const SizedBox(height: 40),
          Text('UTILISÉE DANS', style: text.titleMedium),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => switch (_controller.combosUsing) {
              Loading() => const Padding(
                padding: EdgeInsets.all(24),
                child: LoadingView(),
              ),
              Failed(:final message) => ErrorView(
                message: message,
                onRetry: _controller.load,
              ),
              Empty() => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Aucun enchaînement ne l'utilise pour l'instant.",
                  style: text.bodyMedium,
                ),
              ),
              Ready(:final data) => Column(
                children: [
                  for (final (index, combo) in data.indexed) ...[
                    if (index > 0) const Divider(),
                    ComboTile(
                      combo: combo,
                      today: _controller.today,
                      onTap: () => _open(combo.id),
                    ),
                  ],
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
