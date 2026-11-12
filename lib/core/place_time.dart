import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/settings.dart';

/// Loads the time-zone rules bundled with the app. No network.
void initTimeZones() => tzdata.initializeTimeZones();

tz.Location? _location(Place p) {
  final id = p.timeZone;
  if (id == null) return null;
  try {
    return tz.getLocation(id);
  } catch (_) {
    return null;
  }
}

/// The clock at [p]: its own time zone for a chosen city, the phone's for
/// a GPS or typed place.
DateTime nowAt(Place p, DateTime phoneNow) {
  final loc = _location(p);
  return loc == null ? phoneNow : tz.TZDateTime.from(phoneNow, loc);
}

/// Hours ahead of UTC at [p] on the given day.
double utcOffsetAt(Place p, DateTime day) {
  final loc = _location(p);
  final offset = loc == null
      ? DateTime(day.year, day.month, day.day, 12).timeZoneOffset
      : tz.TZDateTime(loc, day.year, day.month, day.day, 12).timeZoneOffset;
  return offset.inMinutes / 60;
}
