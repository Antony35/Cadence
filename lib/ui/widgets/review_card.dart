import 'package:cadence/models/leitner.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/sunburst.dart';
import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.summary, required this.onStart});

  final ReviewSummary summary;

  final VoidCallback onStart;

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
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: Sunburst(
                colors: [
                  board.accent.withValues(alpha: 0.16),
                  board.ink.withValues(alpha: 0.07),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (due == 0)
                  Text(
                    "RIEN À RÉVISER AUJOURD'HUI",
                    style: text.titleLarge?.copyWith(color: board.ink),
                  )
                else
                  // A screen reader says « 5 à réviser », not « 05 ».
                  MergeSemantics(
                    child: Semantics(
                      label: '$due à réviser',
                      excludeSemantics: true,
                      // One Text.rich: it wraps instead of overflowing with large text.
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: due.toString().padLeft(2, '0'),
                              style: text.displaySmall?.copyWith(
                                color: board.accent,
                              ),
                            ),
                            TextSpan(
                              text: ' À RÉVISER',
                              style: text.titleLarge?.copyWith(
                                color: board.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (overdue > 0) 'dont $overdue en retard',
                    plural(total, 'enchaînement', 'enchaînements'),
                  ].join(' · '),
                  style: text.bodyMedium?.copyWith(color: board.muted),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onStart,
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
        ],
      ),
    );
  }
}
