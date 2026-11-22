import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

/// C2: the techniques in 3 columns. The same grid serves the Techniques
/// screen (a touch opens the sheet) and, from step 4, the form (a touch
/// opens the window to add the technique). A null [onTap] disables the
/// tiles: the form is full (F11).
class TechniqueGrid extends StatelessWidget {
  const TechniqueGrid({
    super.key,
    required this.techniques,
    required this.onTap,
  }) : sliver = false;

  /// The same grid as a sliver: a piece of a [CustomScrollView], which
  /// scrolls with the other pieces (the form).
  const TechniqueGrid.sliver({
    super.key,
    required this.techniques,
    required this.onTap,
  }) : sliver = true;

  /// The square that holds the image or the badge.
  static const tileSize = 88.0;
  static const imageSize = 56.0;

  final List<Technique> techniques;
  final ValueChanged<Technique>? onTap;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge!;
    // V4: 3 columns even with enlarged text, so the tile grows in height
    // with the text size instead of cutting the name.
    final line =
        MediaQuery.textScalerOf(context).scale(label.fontSize!) * label.height!;
    const padding = EdgeInsets.fromLTRB(16, 4, 16, 16);
    final layout = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      mainAxisExtent: tileSize + 8 + 2 * line,
    );

    // Built on demand: only the visible tiles exist.
    Widget tile(BuildContext context, int index) {
      final technique = techniques[index];
      final onTap = this.onTap;
      return _Tile(
        technique: technique,
        onTap: onTap == null ? null : () => onTap(technique),
      );
    }

    if (sliver) {
      return SliverPadding(
        padding: padding,
        sliver: SliverGrid.builder(
          gridDelegate: layout,
          itemCount: techniques.length,
          itemBuilder: tile,
        ),
      );
    }
    return GridView.builder(
      padding: padding,
      gridDelegate: layout,
      itemCount: techniques.length,
      itemBuilder: tile,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.technique, required this.onTap});

  final Technique technique;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // No card: a grey square for the image, the name under it. Disabled
    // tiles are faded.
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
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
      ),
    );
  }
}
