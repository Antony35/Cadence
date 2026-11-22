import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

/// One combo of a list (F3): its name, the images of its steps and its next
/// review.
class ComboTile extends StatelessWidget {
  const ComboTile({
    super.key,
    required this.combo,
    required this.today,
    this.onTap,
  });

  /// F3: six images at most, then « +3 ».
  static const maxThumbnails = 6;

  final Combo combo;
  final DateTime today;

  /// Opens the combo sheet.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final days = daysBetween(today, combo.dueOn);
    final hidden = combo.steps.length - maxThumbnails;

    // A plain row, not a card: the screen separates the rows with lines.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    combo.displayName,
                    style: text.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  dueLabel(combo.dueOn, today).toUpperCase(),
                  style: text.labelMedium?.copyWith(
                    color: switch (days) {
                      < 0 => scheme.error,
                      0 => scheme.primary,
                      _ => scheme.onSurfaceVariant,
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final step in combo.steps.take(maxThumbnails))
                  TechniqueImage(step.technique, size: 28),
                if (hidden > 0)
                  Text(
                    '+$hidden',
                    style: text.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
