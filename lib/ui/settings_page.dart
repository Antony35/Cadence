import 'package:cadence/models/settings.dart';
import 'package:cadence/state/settings_controller.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('PARAMÈTRES')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const _SectionTitle('Thème'),
          RadioGroup<ThemeChoice>(
            groupValue: settings.theme,
            onChanged: (theme) {
              if (theme != null) controller.chooseTheme(theme);
            },
            child: Column(
              children: [
                for (final (index, theme) in ThemeChoice.values.indexed) ...[
                  if (index > 0)
                    const Divider(
                      indent: AppTheme.gutter,
                      endIndent: AppTheme.gutter,
                    ),
                  RadioListTile<ThemeChoice>(
                    value: theme,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter - 8,
                    ),
                    title: Text(theme.label),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _SectionTitle('Taille de la séance'),
          _SessionSizeCounter(controller: controller, settings: settings),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        0,
        AppTheme.gutter,
        8,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _SessionSizeCounter extends StatelessWidget {
  const _SessionSizeCounter({required this.controller, required this.settings});

  final SettingsController controller;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final size = settings.sessionSize;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Enchaînements par série', style: text.bodyLarge),
              ),
              IconButton.outlined(
                tooltip: 'Un de moins',
                onPressed: settings.canShrinkSession
                    ? controller.shrinkSession
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Semantics(
                  label: '$size enchaînements par série',
                  excludeSemantics: true,
                  child: Text(
                    size.toString().padLeft(2, '0'),
                    style: text.displaySmall?.copyWith(color: scheme.primary),
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Un de plus',
                onPressed: settings.canGrowSession
                    ? controller.growSession
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'De ${Settings.minSessionSize} à ${Settings.maxSessionSize}. '
            "Les plus en retard passent d'abord ; « Continuer » propose "
            'les suivants.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
