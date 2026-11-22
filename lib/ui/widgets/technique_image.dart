import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Knows which technique images exist (D2), so that a screen never tries to
/// load a missing file.
///
/// Flutter lists the files of the app in a manifest: it is read once at
/// start-up, then each question is a lookup in a set.
class TechniqueImages {
  const TechniqueImages(this._paths);

  /// No image at all: the tests, and the app until the images are added.
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

  /// D2: the image of the technique (`assets/techniques/<slug>.png`), else
  /// the image of its family (`family_<family>.png`), else null.
  String? pathOf(Technique technique) =>
      _existing('$folder${technique.slug}.png') ??
      familyPathOf(technique.family);

  /// The image of a family, if it exists.
  String? familyPathOf(Family family) =>
      _existing('${folder}family_${family.name}.png');

  String? _existing(String path) => _paths.contains(path) ? path : null;
}

/// The icon of each family (V3), always shown with a name or a label.
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

/// The image of a technique, or of its family, or the family icon when
/// there is none (D2), straight on the background of the screen.
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
              fit: BoxFit.contain,
              // The technique name is always written next to the image.
              excludeFromSemantics: true,
            ),
    );
  }
}
