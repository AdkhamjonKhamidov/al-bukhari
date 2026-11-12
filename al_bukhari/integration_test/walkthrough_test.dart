// Temporary: drives the real app on the iOS simulator in the cloud build and
// saves a screenshot of each screen. Removed once iOS is verified.
import 'dart:io';

import 'package:al_bukhari/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Lets real time pass (network, animations) while drawing frames.
  Future<void> wait(WidgetTester tester, double seconds) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(WidgetTester tester, Finder f, {double seconds = 40}) async {
    for (var i = 0; i < seconds * 10 && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(f, findsWidgets);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await wait(tester, 1);
    await binding.takeScreenshot(name);
  }

  testWidgets('walk through every screen', (tester) async {
    app.main();
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await waitFor(tester, find.text('Al-Faatiha'));
    await shot(tester, '01_home');

    await tester.tap(find.text('Al-Faatiha'));
    await waitFor(tester, find.textContaining('Lord of the worlds'));
    await shot(tester, '02_reader');

    await tester.tap(find.textContaining('Lord of the worlds'));
    await wait(tester, 8); // first play downloads the verse
    await shot(tester, '03_playing');

    await tester.tap(find.byTooltip('Repeat'));
    await waitFor(tester, find.text('Range'));
    await tester.tap(find.text('Range'));
    await wait(tester, 1);
    await shot(tester, '04_repeat_range');
    await tester.tap(find.text('Play'));
    await wait(tester, 6);
    await shot(tester, '05_range_playing');

    await tester.tap(find.byTooltip('Text'));
    await wait(tester, 1);
    await shot(tester, '06_text_options');
    await tester.tapAt(const Offset(20, 120)); // close the sheet
    await wait(tester, 1);

    await tester.tap(find.byType(BackButton));
    await waitFor(tester, find.text('Qibla'));
    await tester.tap(find.text('Qibla'));
    await waitFor(tester, find.text('Choose city'));
    await shot(tester, '07_qibla_needs_place');

    await tester.tap(find.text('Choose city'));
    await waitFor(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Bukh');
    await waitFor(tester, find.text('Bukhara'));
    await shot(tester, '08_place_search');
    await tester.tap(find.text('Bukhara'));
    await waitFor(tester, find.text('TO MAKKAH'));
    await shot(tester, '09_qibla');

    await tester.tap(find.text('Prayer'));
    await waitFor(tester, find.text('Maghrib'));
    await shot(tester, '10_prayer');

    await tester.tap(find.text('More'));
    await waitFor(tester, find.text('Reciter'));
    await shot(tester, '11_more');

    await tester.tap(find.text('Quran'));
    await waitFor(tester, find.text('CONTINUE'));
    await shot(tester, '12_home_continue');
  });
}
