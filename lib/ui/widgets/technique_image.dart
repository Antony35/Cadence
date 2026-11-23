import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class TechniqueImages {
  const TechniqueImages(this._paths);

  const TechniqueImages.none() : _paths = const {};

  static const folder = 'assets/techniques/';

  final Set<String> _paths;

  static Future<TechniqueImages> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return TechniqueImages({
      for (final path in manifest.listAssets())
        if (path.startsWith(folder)) path,
    });
  }

  String? pathOf(Technique technique) =>
      _existing('$folder${technique.slug}.png') ??
      familyPathOf(technique.family);

  String? familyPathOf(Family family) =>
      _existing('${folder}family_${family.name}.png');

  String? _existing(String path) => _paths.contains(path) ? path : null;
}

extension FamilyIcon on Family {
  IconData get icon => switch (this) {
    Family.punch => Icons.sports_mma_rounded,
    Family.elbow => Icons.call_made_rounded,
    Family.kick => Icons.sports_martial_arts_rounded,
    Family.knee => Icons.north_rounded,
    Family.defense => Icons.shield_outlined,
    Family.footwork => Icons.directions_walk_rounded,
  };
}

class TechniqueImage extends StatelessWidget {
  const TechniqueImage(this.technique, {super.key, this.size = 40});

  final Technique technique;
  final double size;

  @override
  Widget build(BuildContext context) {
    final family = technique.family;
    final path = context.watch<TechniqueImages>().pathOf(technique);
    return SizedBox.square(
      dimension: size,
      child: path == null
          ? Icon(
              family.icon,
              size: size * 0.6,
              color: CadenceColors.of(context).family(family),
            )
          : Image.asset(
              path,
              // Decoded at the displayed size, not at 512 px: less memory.
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              fit: BoxFit.contain,
              // The name is always written next to the image.
              excludeFromSemantics: true,
            ),
    );
  }
}
