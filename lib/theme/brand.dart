import 'package:flutter/material.dart';

import 'palette.dart';
import 'theme.dart';

/// The Al Bukhari mark: the Kalyan Minaret of Bukhara on a green disc.
/// Drawn from the same geometry as logo/al-bukhari-mark.svg (512 unit box),
/// so it stays sharp at any size.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Al Bukhari',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: const _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 512);
    final green = Paint()..color = Palette.green;
    final brick = Paint()..color = Palette.tan;
    final sand = Paint()..color = Palette.sand;
    final ivory = Paint()..color = Palette.paper;

    canvas.drawCircle(const Offset(256, 256), 236, green);

    // Tapered shaft with brick bands.
    final shaft = Path()
      ..moveTo(196, 436)
      ..lineTo(316, 436)
      ..lineTo(294, 200)
      ..lineTo(218, 200)
      ..close();
    canvas.drawPath(shaft, brick);
    canvas.save();
    canvas.clipPath(shaft);
    for (final y in const [404.0, 364.0, 322.0, 282.0, 244.0]) {
      canvas.drawRect(Rect.fromLTWH(180, y, 160, 6), sand);
    }
    canvas.restore();

    RRect rounded(double x, double y, double w, double h) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(2));

    // Plinth.
    canvas.drawRRect(rounded(182, 436, 148, 12), sand);

    // Muqarnas cornice with a scalloped underside.
    final cornice = Path()
      ..moveTo(206, 180)
      ..lineTo(306, 180)
      ..lineTo(294, 202);
    for (final x in const [281.33, 268.67, 256.0, 243.33, 230.67, 218.0]) {
      cornice.arcToPoint(Offset(x, 202), radius: const Radius.circular(6.33));
    }
    canvas.drawPath(cornice..close(), sand);

    // Lantern with three arched openings.
    canvas.drawRect(const Rect.fromLTWH(212, 132, 88, 48), brick);
    for (final x in const [224.0, 248.0, 272.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 174)
          ..lineTo(x, 154)
          ..arcToPoint(Offset(x + 16, 154), radius: const Radius.circular(8))
          ..lineTo(x + 16, 174)
          ..close(),
        green,
      );
    }

    // Cap, dome and finial.
    canvas.drawRRect(rounded(204, 122, 104, 10), sand);
    canvas.drawPath(
      Path()
        ..moveTo(228, 122)
        ..quadraticBezierTo(228, 96, 256, 90)
        ..quadraticBezierTo(284, 96, 284, 122)
        ..close(),
      brick,
    );
    canvas.drawRect(const Rect.fromLTWH(254, 72, 4, 20), sand);
    canvas.drawCircle(const Offset(256, 70), 5, ivory);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

/// Mark + wordmark, following logo/al-bukhari-lockup.svg. The wordmark uses
/// the deep green so it stays readable at small sizes.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.markSize = 40, this.color = Palette.greenDeep});
  final double markSize;

  /// Wordmark colour: deep green on paper, paper on the green bands.
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BrandMark(size: markSize),
      SizedBox(width: markSize * 0.3),
      // The wordmark grows with the system text size but shrinks to fit
      // narrow screens rather than run off the edge.
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AL BUKHARI',
                  style: T.title.copyWith(
                    fontSize: markSize * 0.5,
                    letterSpacing: markSize * 0.05,
                    color: color,
                  ),
                ),
                SizedBox(height: markSize * 0.08),
                Container(width: markSize * 0.6, height: 2, color: Palette.tan),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
