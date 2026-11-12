import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

class City {
  const City(this.name, this.aliases, this.country, this.latitude, this.longitude, this.timeZone);
  final String name;
  final List<String> aliases;
  final String country;
  final double latitude;
  final double longitude;
  final String timeZone;

  Place toPlace() => Place(latitude, longitude, name: '$name, $country', timeZone: timeZone);
}

/// Every city over 15,000 people (GeoNames), searched on the phone.
/// Nothing typed here leaves the device.
class Places {
  Places(this.cities);
  final List<City> cities;

  static const asset = 'assets/places/cities.tsv.gz';

  static Future<Places> load([AssetBundle? bundle]) async {
    final data = await (bundle ?? rootBundle).load(asset);
    return compute(fromGzip, data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  static Places fromGzip(List<int> bytes) {
    final lines = utf8.decode(gzip.decode(bytes)).split('\n');
    final countries = {
      for (final pair in lines.first.split('\t'))
        pair.substring(0, pair.indexOf('=')): pair.substring(pair.indexOf('=') + 1),
    };
    final cities = <City>[];
    for (final line in lines.skip(1)) {
      final f = line.split('\t');
      if (f.length < 6) continue;
      cities.add(
        City(
          f[0],
          f[1].isEmpty ? const [] : f[1].split('|'),
          countries[f[2]] ?? f[2],
          double.parse(f[3]),
          double.parse(f[4]),
          f[5],
        ),
      );
    }
    return Places(cities);
  }

  /// Best matches first: name starts with the query, then an alias does,
  /// then the name contains it. Bigger cities come first within each group.
  List<City> search(String query, {int limit = 30}) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final groups = [<City>[], <City>[], <City>[]];
    for (final c in cities) {
      final name = c.name.toLowerCase();
      if (name.startsWith(q)) {
        groups[0].add(c);
      } else if (c.aliases.any((a) => a.toLowerCase().startsWith(q))) {
        groups[1].add(c);
      } else if (name.contains(q)) {
        groups[2].add(c);
      }
      if (groups[0].length >= limit) break;
    }
    return groups.expand((g) => g).take(limit).toList();
  }

  /// The city closest to a point (within 150 km), for naming a GPS place
  /// and finding its time zone. Plain distance on a sphere; 34k cities take
  /// a few milliseconds.
  City? nearest(double lat, double lon) {
    City? best;
    var bestD = double.infinity;
    final cosLat = math.cos(lat * math.pi / 180);
    for (final c in cities) {
      final dLat = c.latitude - lat;
      var dLon = (c.longitude - lon).abs();
      if (dLon > 180) dLon = 360 - dLon;
      final d = dLat * dLat + (dLon * cosLat) * (dLon * cosLat);
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    // Degrees squared to km: 150 km is about 1.35 degrees.
    return bestD <= 1.35 * 1.35 ? best : null;
  }

  /// Reads "41.3, 69.2" (or with N/S/E/W) as a place, if it is one.
  static Place? parseCoordinates(String text) {
    final m = RegExp(
      r'^\s*(-?\d{1,2}(?:\.\d+)?)\s*°?\s*([NnSs])?\s*[,; ]\s*(-?\d{1,3}(?:\.\d+)?)\s*°?\s*([EeWw])?\s*$',
    ).firstMatch(text);
    if (m == null) return null;
    var lat = double.parse(m[1]!), lon = double.parse(m[3]!);
    if ((m[2] ?? '').toUpperCase() == 'S') lat = -lat.abs();
    if ((m[4] ?? '').toUpperCase() == 'W') lon = -lon.abs();
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    return Place(lat, lon);
  }
}
