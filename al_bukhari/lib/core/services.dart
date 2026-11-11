import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../data/places.dart';
import '../data/quran.dart';
import '../data/settings.dart';
import '../features/quran/verse_player.dart';
import '../src/rust/api/declination.dart' as rust;
import '../src/rust/api/prayer.dart' as rust;
import '../src/rust/api/qibla.dart' as rust;
import 'place_time.dart';

export '../src/rust/api/prayer.dart' show CalcMethod, PrayerTimes;

/// The calculations the screens need, done by the Rust core on the phone.
class Core {
  const Core();

  double qiblaBearing(Place p) => rust.qiblaBearing(latitude: p.latitude, longitude: p.longitude);

  double distanceToKaabaKm(Place p) =>
      rust.distanceToKaabaKm(latitude: p.latitude, longitude: p.longitude);

  /// Prayer times on the calendar day [day] at [p], in minutes after that
  /// place's midnight.
  rust.PrayerTimes? prayerTimes(Place p, DateTime day, rust.CalcMethod method, bool hanafiAsr) =>
      rust.prayerTimes(
        latitude: p.latitude,
        longitude: p.longitude,
        year: day.year,
        month: day.month,
        day: day.day,
        utcOffsetHours: utcOffsetAt(p, day),
        method: method,
        hanafiAsr: hanafiAsr,
      );

  /// Degrees to add to the compass reading to get true north. iOS already
  /// reports true north; Android reports magnetic north.
  double headingCorrection(Place p, DateTime day) {
    if (!Platform.isAndroid) return 0;
    return rust.magneticDeclination(
      latitude: p.latitude,
      longitude: p.longitude,
      year: day.year,
      dayOfYear: day.difference(DateTime(day.year)).inDays + 1,
    );
  }
}

enum LocateFailure { serviceOff, denied, deniedForever, unavailable }

class LocateResult {
  const LocateResult.ok(Place this.place) : failure = null;
  const LocateResult.failed(LocateFailure this.failure) : place = null;
  final Place? place;
  final LocateFailure? failure;
}

/// Asks for approximate location once. Nothing is sent anywhere.
Future<LocateResult> locateDevice() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocateResult.failed(LocateFailure.serviceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocateResult.failed(LocateFailure.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocateResult.failed(LocateFailure.deniedForever);
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return LocateResult.ok(Place(pos.latitude, pos.longitude));
  } catch (_) {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LocateResult.ok(Place(last.latitude, last.longitude));
    } catch (_) {}
    return const LocateResult.failed(LocateFailure.unavailable);
  }
}

/// Compass heading in degrees; null when the phone has no compass.
Stream<double?> deviceHeading() =>
    (FlutterCompass.events ?? const Stream<CompassEvent>.empty()).map((e) => e.heading);

/// Everything screens depend on, in one place.
class Services {
  Services({
    required this.quran,
    required this.settings,
    required this.player,
    this.core = const Core(),
    this.locate = locateDevice,
    this.heading = deviceHeading,
    this.openSettings = Geolocator.openAppSettings,
    this.loadPlaces = Places.load,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final Quran quran;
  final Settings settings;
  final Core core;
  final VersePlayer player;
  final Future<LocateResult> Function() locate;
  final Stream<double?> Function() heading;
  final Future<bool> Function() openSettings;
  final DateTime Function() now;
  final Future<Places> Function() loadPlaces;

  /// The city list, read from the app's files the first time it is needed.
  late final Future<Places> places = loadPlaces();

  /// Locates the phone and remembers the (rounded) place.
  Future<LocateResult> useGps() async {
    final result = await locate();
    final p = result.place;
    if (p == null) return result;
    double round(double v) => (v * 100).round() / 100;
    final lat = round(p.latitude), lon = round(p.longitude);
    City? near;
    try {
      near = (await places).nearest(lat, lon);
    } catch (_) {
      // Without the city list the phone's own time zone is used.
    }
    settings.setPlace(
      Place(
        lat,
        lon,
        name: near == null ? null : '${near.name}, ${near.country}',
        timeZone: near?.timeZone,
      ),
    );
    return result;
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final Services services;

  static Services of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
