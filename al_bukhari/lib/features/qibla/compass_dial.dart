import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';

/// The compass: a dial that turns with the phone, the Kaaba set on its rim
/// at the Qibla bearing, and a fixed arch at the top marking where the
/// phone points. Line the Kaaba up under the arch to face the Qibla.
class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.bearing,
    required this.turns,
    required this.facing,
    required this.centre,
  });
  final double bearing;
  final double turns;
  final bool facing;
  final Widget centre;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest.shortestSide;
          return Stack(
            alignment: Alignment.center,
            children: [
              AnimatedRotation(
                turns: turns,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _DialPainter(bearing: bearing, facing: facing),
                ),
              ),
              Positioned(
                top: 0,
                child: CustomPaint(
                  size: Size(size * 0.14, size * 0.15),
                  painter: _ArchPainter(lit: facing),
                ),
              ),
              SizedBox.square(
                dimension: size * 0.5,
                child: FittedBox(fit: BoxFit.scaleDown, child: centre),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// An outline, so the Kaaba shows through it when lined up.
class _ArchPainter extends CustomPainter {
  const _ArchPainter({required this.lit});
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final path = archPath(Offset.zero & size, rise: 0.35);
    if (lit) canvas.drawPath(path, Paint()..color = Palette.paper.withValues(alpha: 0.16));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lit ? 3.5 : 2
        ..strokeJoin = StrokeJoin.round
        ..color = lit ? Palette.paper : Palette.sand,
    );
  }

  @override
  bool shouldRepaint(_ArchPainter oldDelegate) => oldDelegate.lit != lit;
}

class _DialPainter extends CustomPainter {
  const _DialPainter({required this.bearing, required this.facing});
  final double bearing;
  final bool facing;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final rim = outer * 0.84; // edge of the face, where the Kaaba sits
    final r = outer * 0.72; // tick ring
    Offset at(double degrees, double radius) {
      final a = (degrees - 90) * math.pi / 180;
      return c + Offset(math.cos(a), math.sin(a)) * radius;
    }

    // Face: a sand-edged disc a shade darker than the field.
    canvas.drawCircle(c, rim, Paint()..color = Palette.ink.withValues(alpha: 0.22));
    canvas.drawCircle(
      c,
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = facing ? 4 : 1.5
        ..color = facing ? Palette.sand : Palette.tan,
    );

    // Ticks: fine every 5 degrees, strong every 30.
    for (var d = 0; d < 360; d += 5) {
      final major = d % 30 == 0;
      canvas.drawLine(
        at(d.toDouble(), r - (major ? outer * 0.07 : outer * 0.035)),
        at(d.toDouble(), r),
        Paint()
          ..strokeWidth = major ? 2 : 1
          ..color = major ? Palette.sand : Palette.tan.withValues(alpha: 0.7),
      );
    }

    // Cardinal letters, turned to read from the centre.
    const letters = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    letters.forEach((d, letter) {
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: T.eyebrow.copyWith(
            fontSize: outer * (d == 0 ? 0.085 : 0.065),
            letterSpacing: 0,
            color: d == 0 ? Palette.paper : Palette.sand,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = at(d.toDouble(), r - outer * 0.15);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(d * math.pi / 180);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    });

    // The Qibla line and the Kaaba on the rim.
    canvas.drawLine(
      at(bearing, outer * 0.30),
      at(bearing, rim - outer * 0.085),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Palette.sand,
    );
    final k = at(bearing, rim);
    canvas.drawCircle(k, outer * 0.085, Paint()..color = Palette.sand);
    canvas.save();
    canvas.translate(k.dx, k.dy);
    canvas.rotate(bearing * math.pi / 180);
    final half = outer * 0.047;
    final cube = Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2);
    canvas.drawRect(cube, Paint()..color = Palette.ink);
    canvas.drawRect(
      Rect.fromLTWH(-half, -half * 0.45, half * 2, half * 0.32),
      Paint()..color = Palette.tan,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.bearing != bearing || oldDelegate.facing != facing;
}
