import 'dart:math' as math;
import 'dart:ui';

/// The five brand colours, plus text colours derived from them for contrast.
/// Ratios are enforced by test/contrast_test.dart.
abstract final class Palette {
  // Brand palette (fixed).
  static const green = Color(0xFF5D866C); // Quran, active state: fills and rules
  static const tan = Color(0xFFC2A68C); // hairlines, quiet marks
  static const sand = Color(0xFFE6D8C3); // raised surfaces
  static const paper = Color(0xFFF5F5F0); // page
  static const sky = Color(0xFFA6C8E2); // time and direction

  // Derived text colours.
  static const ink = Color(0xFF1B241F); // body text
  static const inkSoft = Color(0xFF4F5A52); // secondary text
  static const greenDeep = Color(0xFF35523F); // green text and icons
  static const skyDeep = Color(0xFF2F5673); // blue text and icons
  static const alert = Color(0xFF8A3B2A); // errors only

  /// WCAG 2 contrast ratio between two opaque colours (1..21).
  static double contrast(Color a, Color b) {
    final la = _luminance(a), lb = _luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  static double _luminance(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }
}
