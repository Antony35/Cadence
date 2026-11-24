import 'package:cadence/models/app_info.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/brand.dart';
import 'package:cadence/ui/widgets/fact_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final version = context.read<AppInfo>().version;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('À PROPOS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          24,
          AppTheme.gutter,
          24,
        ),
        children: [
          const Center(child: BrandMark(size: 96)),
          const SizedBox(height: 16),
          Text(
            'CADENCE',
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          Text(
            "Carnet d'enchaînements",
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FactRow('Version', version),
          const FactRow(
            'Données',
            "Vos enchaînements restent sur ce téléphone : Cadence n'a pas "
                'accès à Internet. Si la sauvegarde Android est activée, ils '
                'sont copiés dans votre compte Google, comme les autres '
                'applications.',
          ),
          const FactRow(
            'Voix',
            'Enregistrée avec la synthèse vocale de Gemini (Google).',
          ),
          const FactRow(
            'Images',
            'Logo et illustrations créés pour Cadence avec Gemini.',
          ),
          const FactRow(
            'Polices',
            'Barlow et Barlow Condensed, SIL Open Font License.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Cadence',
              applicationVersion: version,
              applicationIcon: const Padding(
                padding: EdgeInsets.all(8),
                child: BrandMark(size: 64),
              ),
            ),
            child: const Text('Licences'),
          ),
        ],
      ),
    );
  }
}
