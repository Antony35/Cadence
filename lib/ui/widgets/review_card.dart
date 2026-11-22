import 'package:cadence/models/leitner.dart';
import 'package:cadence/ui/format.dart';
import 'package:flutter/material.dart';

/// F1, F2: the « À réviser » card, the summary view of the app.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ink = scheme.onPrimaryContainer;
    final (:due, :overdue, :total) = summary;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (due == 0)
              Text(
                "Rien à réviser aujourd'hui",
                style: text.titleLarge?.copyWith(color: ink),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$due', style: text.displaySmall?.copyWith(color: ink)),
                  const SizedBox(width: 8),
                  Text(
                    'à réviser',
                    style: text.titleLarge?.copyWith(color: ink),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              [
                if (overdue > 0) 'dont $overdue en retard',
                plural(total, 'enchaînement', 'enchaînements'),
              ].join(' · '),
              style: text.bodyMedium?.copyWith(color: ink),
            ),
            const SizedBox(height: 16),
            // Step 5 enables both buttons: they open the session.
            if (due == 0)
              const OutlinedButton(
                onPressed: null,
                child: Text('Réviser en avance'),
              )
            else
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Commencer'),
              ),
          ],
        ),
      ),
    );
  }
}
