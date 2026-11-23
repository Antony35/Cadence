import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/ui/format.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

class ComboTile extends StatelessWidget {
  const ComboTile({
    super.key,
    required this.combo,
    required this.today,
    this.onTap,
  });

  static const maxThumbnails = 6;

  final Combo combo;
  final DateTime today;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final days = daysBetween(today, combo.dueOn);
    final hidden = combo.steps.length - maxThumbnails;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter,
          vertical: 18,
        ),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final step in combo.steps.take(maxThumbnails))
                  TechniqueImage(step.technique, size: 24),
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
