import 'package:flutter/material.dart';

import 'palette.dart';

/// Three families, each with one job.
abstract final class Fonts {
  static const arabic = 'AmiriQuran';
  static const serif = 'Newsreader';
  static const sans = 'InstrumentSans';
}

abstract final class T {
  /// Quran text. Tall line height keeps the marks from colliding.
  static TextStyle arabic(double size) =>
      TextStyle(fontFamily: Fonts.arabic, fontSize: size, height: 2.15, color: Palette.ink);

  static const arabicName = TextStyle(
    fontFamily: Fonts.arabic,
    fontSize: 22,
    height: 1.6,
    color: Palette.greenDeep,
  );

  static const display = TextStyle(
    fontFamily: Fonts.serif,
    fontSize: 34,
    height: 1.1,
    fontVariations: [FontVariation('wght', 500), FontVariation('opsz', 48)],
    fontFeatures: [FontFeature.disable('liga'), FontFeature.disable('dlig')],
    letterSpacing: -0.4,
    color: Palette.ink,
  );
  static const title = TextStyle(
    fontFamily: Fonts.serif,
    fontSize: 20,
    height: 1.25,
    fontVariations: [FontVariation('wght', 500), FontVariation('opsz', 24)],
    fontFeatures: [FontFeature.disable('liga'), FontFeature.disable('dlig')],
    color: Palette.ink,
  );
  static const reading = TextStyle(
    fontFamily: Fonts.serif,
    fontSize: 17,
    height: 1.55,
    fontVariations: [FontVariation('wght', 400), FontVariation('opsz', 16)],
    color: Palette.ink,
  );

  /// The Arabic sounds in English letters.
  static const phonetic = TextStyle(
    fontFamily: Fonts.serif,
    fontStyle: FontStyle.italic,
    fontSize: 16,
    height: 1.5,
    fontVariations: [FontVariation('wght', 450), FontVariation('opsz', 16)],
    color: Palette.greenDeep,
  );

  static const label = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 14,
    height: 1.35,
    fontVariations: [FontVariation('wght', 500)],
    color: Palette.inkSoft,
  );

  /// Small capitals used for section headings.
  static const eyebrow = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 12,
    height: 1.3,
    letterSpacing: 1.4,
    fontVariations: [FontVariation('wght', 600)],
    color: Palette.inkSoft,
  );

  static const numeral = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 20,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
    fontVariations: [FontVariation('wght', 500)],
    color: Palette.ink,
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.greenDeep,
    onPrimary: Palette.paper,
    secondary: Palette.green,
    onSecondary: Palette.paper,
    error: Palette.alert,
    onError: Palette.paper,
    surface: Palette.paper,
    onSurface: Palette.ink,
    surfaceContainerHighest: Palette.sand,
    outline: Palette.tan,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    fontFamily: Fonts.sans,
    dividerTheme: const DividerThemeData(color: Palette.tan, thickness: 1, space: 1),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Palette.greenDeep),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.greenDeep,
      foregroundColor: Palette.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: Fonts.serif,
        fontSize: 19,
        fontVariations: [FontVariation('wght', 500)],
        color: Palette.paper,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.greenDeep,
        minimumSize: const Size(48, 48),
        textStyle: T.label.copyWith(fontSize: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.greenDeep,
        foregroundColor: Palette.paper,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: shape,
        textStyle: T.label.copyWith(fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.greenDeep,
        side: const BorderSide(color: Palette.greenDeep, width: 1.5),
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: shape,
        textStyle: T.label.copyWith(fontSize: 16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Palette.tan,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.paper,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      titleTextStyle: T.title,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Palette.paper : Palette.tan,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Palette.greenDeep : Palette.sand,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Palette.tan),
    ),
  );
}

/// A hairline rule, the app's only separator.
class Rule extends StatelessWidget {
  const Rule({super.key, this.indent = 0});
  final double indent;

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: EdgeInsets.only(left: indent),
    color: Palette.tan,
  );
}
