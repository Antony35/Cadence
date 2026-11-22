import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/technique.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/load_state.dart';
import 'package:cadence/state/technique_controller.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/widgets/combo_tile.dart';
import 'package:cadence/ui/widgets/state_views.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// F25: the sheet of a technique, and the combos that use it.
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

  @override
  Widget build(BuildContext context) {
    final technique = widget.technique;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(technique.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: TechniqueImage(technique, size: 120)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FamilyBadge(technique.family, size: 24),
              const SizedBox(width: 8),
              Text(technique.family.label, style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in [
            sidesText(technique.sides),
            targetsText(technique.targets),
          ])
            if (line != null)
              Text(line, style: text.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Utilisée dans', style: text.titleMedium),
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
              Empty() => Text(
                "Aucun enchaînement ne l'utilise pour l'instant.",
                style: text.bodyMedium,
              ),
              Ready(:final data) => Column(
                children: [
                  for (final combo in data)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      // Opens the combo sheet from step 4.
                      child: ComboTile(combo: combo, today: _controller.today),
                    ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
