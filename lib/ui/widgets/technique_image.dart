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

  /// `assets/techniques/<slug>.png` if the file exists, else null.
  String? pathOf(Technique technique) {
    final path = '$folder${technique.slug}.png';
    return _paths.contains(path) ? path : null;
  }
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

/// The image of a technique, or its family badge when there is none (D2).
class TechniqueImage extends StatelessWidget {
  const TechniqueImage(this.technique, {super.key, this.size = 40});

  final Technique technique;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = context.watch<TechniqueImages>().pathOf(technique);
    if (path == null) return FamilyBadge(technique.family, size: size);
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // The technique name is always written next to the image.
      excludeFromSemantics: true,
    );
  }
}

/// A disc in the family color, with the family icon.
class FamilyBadge extends StatelessWidget {
  const FamilyBadge(this.family, {super.key, this.size = 40});

  final Family family;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = CadenceColors.of(context).family(family);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.fill, shape: BoxShape.circle),
      child: Icon(family.icon, size: size * 0.55, color: colors.ink),
    );
  }
}
