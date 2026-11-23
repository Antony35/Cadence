import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:cadence/ui/widgets/technique_image.dart';
import 'package:flutter/material.dart';

class TechniqueGrid extends StatelessWidget {
  const TechniqueGrid({
    super.key,
    required this.techniques,
    required this.onTap,
  }) : sliver = false;

  const TechniqueGrid.sliver({
    super.key,
    required this.techniques,
    required this.onTap,
  }) : sliver = true;

  static const tileSize = 88.0;
  static const imageSize = 80.0;

  final List<Technique> techniques;
  final ValueChanged<Technique>? onTap;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge!;
    // Three columns even with large text: tiles grow taller, names never cut.
    final line =
        MediaQuery.textScalerOf(context).scale(label.fontSize!) * label.height!;
    const padding = EdgeInsets.fromLTRB(
      AppTheme.gutter,
      12,
      AppTheme.gutter,
      32,
    );
    final layout = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 12,
      mainAxisExtent: tileSize + 8 + 2 * line,
    );

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
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Column(
          children: [
            SizedBox(
              height: TechniqueGrid.tileSize,
              child: Center(
                child: TechniqueImage(technique, size: TechniqueGrid.imageSize),
              ),
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
