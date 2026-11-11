import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/theme.dart';

/// A number inside an eight-pointed star (two overlaid squares), the
/// traditional verse and section marker.
class VerseMarker extends StatelessWidget {
  const VerseMarker({super.key, required this.number, this.active = false});
  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: CustomPaint(
        painter: _StarPainter(active: active),
        child: Center(
          child: Text(
            '$number',
            textScaler: TextScaler.noScaling,
            style: T.label.copyWith(
              fontSize: number > 99 ? 11 : 13,
              color: active ? Palette.paper : Palette.inkSoft,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      // Alternate between the points and the notches of the star.
      final radius = i.isEven ? r : r * 0.78;
      final a = -math.pi / 2 + i * math.pi / 8;
      final p = c + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    if (active) {
      canvas.drawPath(path, Paint()..color = Palette.greenDeep);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = Palette.tan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.active != active;
}
