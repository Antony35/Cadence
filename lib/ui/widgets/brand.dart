import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
