import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

/// C2: the techniques in 3 columns. The same grid serves the Techniques
/// screen (a touch opens the sheet) and, from step 4, the form (a touch
/// opens the window to add the technique).
class TechniqueGrid extends StatelessWidget {
  const TechniqueGrid({
    super.key,
    required this.techniques,
    required this.onTap,
  });

  /// The square that holds the image or the badge.
  static const tileSize = 88.0;
  static const imageSize = 56.0;

  final List<Technique> techniques;
  final ValueChanged<Technique> onTap;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge!;
    // V4: 3 columns even with enlarged text, so the tile grows in height
    // with the text size instead of cutting the name.
    final line =
        MediaQuery.textScalerOf(context).scale(label.fontSize!) * label.height!;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        mainAxisExtent: tileSize + 8 + 2 * line,
      ),
      itemCount: techniques.length,
      // Built on demand: only the visible tiles exist.
      itemBuilder: (context, index) {
        final technique = techniques[index];
        return _Tile(technique: technique, onTap: () => onTap(technique));
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.technique, required this.onTap});

  final Technique technique;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // No card: a grey square for the image, the name under it.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Column(
        children: [
          Container(
            height: TechniqueGrid.tileSize,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: TechniqueImage(technique, size: TechniqueGrid.imageSize),
          ),
          const SizedBox(height: 8),
          Text(
            technique.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
