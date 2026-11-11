import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Eight-pointed star outline (two overlaid squares) of radius [r].
Path starPath(Offset c, double r, {double inner = 0.76}) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final radius = i.isEven ? r : r * inner;
    final a = -math.pi / 2 + i * math.pi / 8;
    final p = c + Offset(math.cos(a), math.sin(a)) * radius;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// A pointed (mihrab) arch filling [rect]: straight sides, then two arcs
/// meeting at a point at the top.
Path archPath(Rect rect, {double rise = 0.42}) {
  final spring = rect.top + rect.width * rise;
  final r = rect.width * 0.85;
  return Path()
    ..moveTo(rect.left, rect.bottom)
    ..lineTo(rect.left, spring)
    ..arcToPoint(Offset(rect.center.dx, rect.top), radius: Radius.circular(r))
    ..arcToPoint(Offset(rect.right, spring), radius: Radius.circular(r))
    ..lineTo(rect.right, rect.bottom)
    ..close();
}

/// A dark green band laid with a zellige-style star lattice, tone on tone.
/// Used behind the headers so each screen opens on the same patterned field.
class OrnamentBand extends StatelessWidget {
  const OrnamentBand({super.key, required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Palette.greenDeep,
    child: CustomPaint(
      painter: const LatticePainter(),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class LatticePainter extends CustomPainter {
  const LatticePainter({this.color = Palette.green, this.cell = 44});
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint()..color = color.withValues(alpha: 0.5);
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        canvas.drawPath(starPath(c, cell * 0.36), line);
        // Lines joining neighbouring stars make the lattice.
        canvas.drawLine(c + Offset(cell * 0.36, 0), c + Offset(cell * 0.64, 0), line);
        canvas.drawLine(c + Offset(0, cell * 0.36), c + Offset(0, cell * 0.64), line);
        canvas.drawCircle(c + Offset(cell / 2, cell / 2), 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(LatticePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.cell != cell;
}
