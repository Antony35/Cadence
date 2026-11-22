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

  /// Null until the sheet exists (step 4).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final late = daysBetween(today, combo.dueOn) < 0;
    final hidden = combo.steps.length - maxThumbnails;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  const SizedBox(width: 8),
                  Text(
                    dueLabel(combo.dueOn, today),
                    style: text.labelMedium?.copyWith(
                      color: late ? scheme.error : scheme.onSurfaceVariant,
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
                    TechniqueImage(step.technique, size: 32),
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
      ),
    );
  }
}
