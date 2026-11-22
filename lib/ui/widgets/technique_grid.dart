import 'package:cadence/models/technique.dart';
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
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 12 + imageSize + 8 + 2 * line + 12,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
          child: Column(
            children: [
              TechniqueImage(technique, size: TechniqueGrid.imageSize),
              const SizedBox(height: 8),
              Text(
                technique.name,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
