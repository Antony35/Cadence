import 'dart:math';

import 'package:flutter/material.dart';

/// The broken rays of the logo poster, drawn behind a block (the round
/// board). Decorative: faint, and the same pattern every time.
class Sunburst extends StatelessWidget {
  const Sunburst({super.key, required this.colors, this.center});

  /// Each ray takes the next color of the list.
  final List<Color> colors;

  /// Where the rays start, as a fraction of the size; right by default,
  /// behind the big figure's side.
  final Alignment? center;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SunburstPainter(colors, center ?? const Alignment(0.7, -0.2)),
    size: Size.infinite,
  );
}

/// A [CustomPainter] draws with lines and shapes on a canvas, like an HTML
/// canvas: here, 36 rays cut into dashes.
class _SunburstPainter extends CustomPainter {
  _SunburstPainter(this.colors, this.center);

  final List<Color> colors;
  final Alignment center;

  static const rays = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = center.alongSize(size);
    final reach = size.longestSide;
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < rays; i++) {
      final angle = 2 * pi * i / rays;
      final direction = Offset(cos(angle), sin(angle));
      paint.color = colors[i % colors.length];
      // Dashes of varying length, starting away from the center.
      var from = 40.0 + (i % 3) * 14;
      var dash = 0;
      while (from < reach) {
        final length = 18.0 + ((i * 7 + dash * 11) % 5) * 9;
        canvas.drawLine(
          origin + direction * from,
          origin + direction * (from + length),
          paint,
        );
        from += length + 10 + ((i + dash) % 3) * 6;
        dash++;
      }
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter old) =>
      old.colors != colors || old.center != center;
}
