import 'package:cadence/models/leitner.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// F1, F2: the « À réviser » card, the summary view of the app, drawn as a
/// round board: a solid block, a gold figure.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final board = CadenceColors.of(context).scoreboard;
    final text = Theme.of(context).textTheme;
    final (:due, :overdue, :total) = summary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: board.fill,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (due == 0)
              Text(
                "RIEN À RÉVISER AUJOURD'HUI",
                style: text.titleLarge?.copyWith(color: board.ink),
              )
            else
              // Read as « 5 à réviser » by a screen reader, not « 05 ».
              MergeSemantics(
                child: Semantics(
                  label: '$due à réviser',
                  excludeSemantics: true,
                  // One text with two styles: it wraps with enlarged text
                  // instead of overflowing.
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          // Two digits, like a round counter.
                          text: due.toString().padLeft(2, '0'),
                          style: text.displaySmall?.copyWith(
                            color: board.accent,
                          ),
                        ),
                        TextSpan(
                          text: ' À RÉVISER',
                          style: text.titleLarge?.copyWith(color: board.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              [
                if (overdue > 0) 'dont $overdue en retard',
                plural(total, 'enchaînement', 'enchaînements'),
              ].join(' · '),
              style: text.bodyMedium?.copyWith(color: board.muted),
            ),
            const SizedBox(height: 16),
            // Step 5 enables the button: it opens the session (F19).
            FilledButton.icon(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: board.accent,
                foregroundColor: board.fill,
                // Until step 5: a dimmed gold, the label still readable.
                disabledBackgroundColor: board.accent.withValues(alpha: 0.3),
                disabledForegroundColor: board.ink.withValues(alpha: 0.75),
              ),
              icon: Icon(
                due == 0
                    ? Icons.fast_forward_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(due == 0 ? 'Réviser en avance' : 'Commencer'),
            ),
          ],
        ),
      ),
    );
  }
}
