import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The logo of Cadence: the gloves of the character, on the charcoal of the
/// poster. Purely decorative for a screen reader: the name is always
/// written next to it.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32});

  static const asset = 'assets/brand/gloves.webp';

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppTheme.radius),
    child: Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    ),
  );
}

/// The poster, cut to a square: the poster is taller than wide, and its
/// gloves fill the lower part. A square keeps them whole at any width; only
/// the top of the hanging lace is cut.
class BrandPoster extends StatelessWidget {
  const BrandPoster({super.key});

  static const asset = 'assets/brand/poster.webp';

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      excludeFromSemantics: true,
    ),
  );
}
