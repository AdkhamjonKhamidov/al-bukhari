import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../src/rust/api/prayer.dart' show CalcMethod;

/// A place for Qibla and prayer times. GPS places are rounded to about a
/// kilometre before they are stored (see Services.useGps). [timeZone] is set for places picked
/// from the city list, so their prayer times are shown in their own time.
class Place {
  const Place(this.latitude, this.longitude, {this.name, this.timeZone});
  final double latitude;
  final double longitude;
  final String? name;
  final String? timeZone;

  String get coordinates {
    final ns = latitude >= 0 ? 'N' : 'S';
    final ew = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(2)}°$ns  ${longitude.abs().toStringAsFixed(2)}°$ew';
  }

  String get label => name ?? coordinates;
}

/// What a tap on a verse repeats.
enum RepeatScope { verse, range, surah }

/// Everything the app remembers. Stored on the phone only.
class Settings extends ChangeNotifier {
  Settings(this._prefs);
  final SharedPreferences _prefs;

  static Future<Settings> load() async => Settings(await SharedPreferences.getInstance());

  /// How many times the chosen verses play. 0 means until stopped.
  static const repeatChoices = [1, 3, 5, 10, 0];

  int get repeat => _prefs.getInt('repeat') ?? 3;

  RepeatScope get scope =>
      RepeatScope.values.elementAtOrNull(_prefs.getInt('scope') ?? 0) ?? RepeatScope.verse;

  bool get showPhonetic => _prefs.getBool('showPhonetic') ?? true;
  bool get showTranslation => _prefs.getBool('showTranslation') ?? true;

  /// 0 small, 1 medium, 2 large.
  int get arabicSize => (_prefs.getInt('arabicSize') ?? 1).clamp(0, 2);

  /// Hanafi by default: Asr begins when a shadow is twice its object's length.
  bool get hanafiAsr => _prefs.getBool('hanafiAsr') ?? true;

  /// Reciters offered, by their id on the audio CDN. Both read Hafs from Asim.
  static const reciters = {
    'ar.husary': 'Mahmoud Khalil Al-Husary',
    'ar.alafasy': 'Mishary Rashid Alafasy',
  };

  String get reciter {
    final id = _prefs.getString('reciter');
    return reciters.containsKey(id) ? id! : reciters.keys.first;
  }

  /// Karachi (Fajr and Isha at 18 degrees) is the default: the method in
  /// common use where the Hanafi school is followed.
  CalcMethod get method {
    final i = _prefs.getInt('method');
    return (i == null ? null : CalcMethod.values.elementAtOrNull(i)) ?? CalcMethod.karachi;
  }

  /// (surah number, verse number) last played, if any.
  (int, int)? get lastRead {
    final s = _prefs.getInt('lastSurah'), a = _prefs.getInt('lastAyah');
    return s == null || a == null ? null : (s, a);
  }

  Place? get place {
    final lat = _prefs.getDouble('lat'), lon = _prefs.getDouble('lon');
    if (lat == null || lon == null) return null;
    return Place(
      lat,
      lon,
      name: _prefs.getString('placeName'),
      timeZone: _prefs.getString('placeTz'),
    );
  }

  void setRepeat(int v) => _set(() => _prefs.setInt('repeat', v));
  void setScope(RepeatScope v) => _set(() => _prefs.setInt('scope', v.index));
  void setShowPhonetic(bool v) => _set(() => _prefs.setBool('showPhonetic', v));
  void setShowTranslation(bool v) => _set(() => _prefs.setBool('showTranslation', v));
  void setArabicSize(int v) => _set(() => _prefs.setInt('arabicSize', v.clamp(0, 2)));
  void setHanafiAsr(bool v) => _set(() => _prefs.setBool('hanafiAsr', v));
  void setReciter(String id) => _set(() => _prefs.setString('reciter', id));
  void setMethod(CalcMethod v) => _set(() => _prefs.setInt('method', v.index));

  void setLastRead(int surah, int ayah) =>
      _set(() => Future.wait([_prefs.setInt('lastSurah', surah), _prefs.setInt('lastAyah', ayah)]));

  void setPlace(Place p) {
    _set(
      () => Future.wait([
        _prefs.setDouble('lat', p.latitude),
        _prefs.setDouble('lon', p.longitude),
        if (p.name == null) _prefs.remove('placeName') else _prefs.setString('placeName', p.name!),
        if (p.timeZone == null)
          _prefs.remove('placeTz')
        else
          _prefs.setString('placeTz', p.timeZone!),
      ]),
    );
  }

  /// Values are readable at once (the store keeps them in memory); the write
  /// to disk finishes in the background.
  void _set(Future<Object?> Function() write) {
    unawaited(write());
    notifyListeners();
  }
}
