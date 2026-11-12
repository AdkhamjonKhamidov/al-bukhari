import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';

/// The day as the sun's path: an arch from sunrise to sunset, the prayers
/// marked along it, and the sun where it is now.
class SunArc extends StatelessWidget {
  const SunArc({super.key, required this.times, required this.now, required this.labels});

  /// Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha in minutes after midnight.
  final List<int> times;
  final int now;
  final String Function(int minutes) labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 92),
          painter: _ArcPainter(times: times, now: now),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(labels(times[1]), style: T.label.copyWith(color: Palette.sand)),
            const Spacer(),
            Text(labels(times[4]), style: T.label.copyWith(color: Palette.sand)),
          ],
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.times, required this.now});
  final List<int> times;
  final int now;

  @override
  void paint(Canvas canvas, Size size) {
    final rise = times[1], set = times[4];
    final base = size.height - 4;
    final left = 8.0, right = size.width - 8;
    // Position along the arch for a time between sunrise and sunset.
    Offset at(int minutes) {
      final t = ((minutes - rise) / (set - rise)).clamp(0.0, 1.0);
      final x = left + (right - left) * t;
      final y = base - (size.height - 18) * math.sin(math.pi * t);
      return Offset(x, y);
    }

    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = Palette.green
        ..strokeWidth = 1.5,
    );

    final path = Path()..moveTo(at(rise).dx, at(rise).dy);
    for (var m = rise; m <= set; m += 5) {
      path.lineTo(at(m).dx, at(m).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Palette.tan,
    );

    // Daylight already passed, drawn solid.
    if (now > rise) {
      final done = Path()..moveTo(at(rise).dx, at(rise).dy);
      for (var m = rise; m <= math.min(now, set); m += 5) {
        done.lineTo(at(m).dx, at(m).dy);
      }
      canvas.drawPath(
        done,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Palette.sand,
      );
    }

    // Dhuhr and Asr as small stars on the arch.
    for (final i in const [2, 3]) {
      canvas.drawPath(starPath(at(times[i]), 6), Paint()..color = Palette.sand);
    }

    // The sun by day; below the line at night.
    final daytime = now >= rise && now <= set;
    final sun = daytime ? at(now) : Offset(now < rise ? left : right, base);
    canvas.drawCircle(sun, 11, Paint()..color = Palette.greenDeep);
    canvas.drawCircle(sun, 8, Paint()..color = daytime ? Palette.paper : Palette.tan);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.now != now || oldDelegate.times != times;
}
