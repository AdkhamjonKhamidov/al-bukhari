import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Ayah {
  const Ayah(this.arabic, this.english, this.phonetic);
  final String arabic;
  final String english;

  /// The Arabic sounds written in English letters.
  final String phonetic;
}

class Surah {
  const Surah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.meaning,
    required this.place,
    required this.ayahs,
    required this.firstGlobalAyah,
  });

  final int number;
  final String arabicName;
  final String englishName;
  final String meaning;
  final String place;
  final List<Ayah> ayahs;

  /// Number (1..6236) of this surah's first verse across the whole Quran.
  final int firstGlobalAyah;

  /// Al-Fatiha's Basmala is its first verse; At-Tawba has none.
  bool get showsBasmala => number != 1 && number != 9;
}

class Quran {
  const Quran({required this.basmala, required this.basmalaPhonetic, required this.surahs});
  final String basmala;
  final String basmalaPhonetic;
  final List<Surah> surahs;

  static const asset = 'assets/quran/quran.json.gz';

  /// The text ships gzip-compressed (under a third of its size) and is
  /// unpacked off the main thread so the first screen never stutters.
  static Future<Quran> load([AssetBundle? bundle]) async {
    final data = await (bundle ?? rootBundle).load(asset);
    return compute(fromGzip, data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  static Quran fromGzip(List<int> bytes) => parse(utf8.decode(gzip.decode(bytes)));

  static Quran parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    var next = 1;
    final surahs = <Surah>[];
    for (final s in (json['surahs'] as List).cast<Map<String, dynamic>>()) {
      final ayahs = [
        for (final a in (s['ayahs'] as List).cast<List<dynamic>>())
          Ayah(a[0] as String, a[1] as String, a[2] as String),
      ];
      surahs.add(
        Surah(
          number: s['n'] as int,
          arabicName: s['ar'] as String,
          englishName: s['en'] as String,
          meaning: s['meaning'] as String,
          place: s['place'] as String,
          ayahs: ayahs,
          firstGlobalAyah: next,
        ),
      );
      next += ayahs.length;
    }
    return Quran(
      basmala: json['basmala'] as String,
      basmalaPhonetic: json['basmalaTr'] as String,
      surahs: surahs,
    );
  }
}
