import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/place_time.dart';
import '../../core/services.dart';
import '../../data/settings.dart';
import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../places/place_gate.dart';
import '../places/place_picker.dart';
import 'sun_arc.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps "next" and the countdown current.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) {
        final place = services.settings.place;
        if (place == null) return const PlaceGate(title: 'Prayer times');
        return _Today(place: place);
      },
    );
  }
}

const names = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const _sunrise = 1;

List<int> minutesOf(PrayerTimes t) => [t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha];

String clock(BuildContext context, int minutes) {
  final h = (minutes ~/ 60) % 24, m = minutes % 60;
  final mm = m.toString().padLeft(2, '0');
  if (MediaQuery.alwaysUse24HourFormatOf(context)) return '${h.toString().padLeft(2, '0')}:$mm';
  return '${h % 12 == 0 ? 12 : h % 12}:$mm ${h < 12 ? 'am' : 'pm'}';
}

String _countdown(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  return h == 0 ? '$m min' : '$h h $m min';
}

/// The next prayer, how long until it, and which of today's rows to mark
/// (none when the next prayer is tomorrow's Fajr). Sunrise is not a prayer.
({String name, int wait, int? row}) nextPrayer(List<int> today, int now, int? tomorrowFajr) {
  for (final i in const [0, 2, 3, 4, 5]) {
    if (today[i] > now) return (name: names[i], wait: today[i] - now, row: i);
  }
  return (name: names[0], wait: (tomorrowFajr ?? today[0]) + 1440 - now, row: null);
}

class _Today extends StatelessWidget {
  const _Today({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = nowAt(place, s.now());
    final method = s.settings.method, hanafi = s.settings.hanafiAsr;
    final today = s.core.prayerTimes(place, now, method, hanafi);
    if (today == null) {
      // Polar day or night: there is no sunrise or sunset to work from.
      return Column(
        children: [_Header(place: place, title: 'No sunrise', subtitle: 'today', child: null)],
      );
    }
    final times = minutesOf(today);
    final nowMin = now.hour * 60 + now.minute;
    final tomorrow = s.core.prayerTimes(place, now.add(const Duration(days: 1)), method, hanafi);
    final next = nextPrayer(times, nowMin, tomorrow?.fajr);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(
          place: place,
          title: next.name,
          subtitle: 'in ${_countdown(next.wait)}',
          child: Semantics(
            label: 'Daylight today',
            child: SunArc(times: times, now: nowMin, labels: (m) => clock(context, m)),
          ),
        ),
        for (var i = 0; i < 6; i++)
          _TimeRow(
            name: names[i],
            time: clock(context, times[i]),
            next: i == next.row,
            quiet: i == _sunrise,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Text(
            '${hanafi ? 'Hanafi' : "Shafi'i"} Asr  ·  ${methodNames[method]}',
            style: T.label,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

const methodNames = {
  CalcMethod.muslimWorldLeague: 'Muslim World League',
  CalcMethod.northAmerica: 'North America (ISNA)',
  CalcMethod.egyptian: 'Egyptian',
  CalcMethod.ummAlQura: 'Umm al-Qura, Makkah',
  CalcMethod.karachi: 'Karachi',
};

class _Header extends StatelessWidget {
  const _Header({
    required this.place,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final Place place;
  final String title;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    return OrnamentBand(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.place_outlined, color: Palette.sand, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place.label,
                      style: T.label.copyWith(color: Palette.sand),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Change place',
                    onPressed: () => openPlacePicker(context),
                    icon: const Icon(Icons.edit_location_alt_outlined, color: Palette.sand),
                  ),
                ],
              ),
              Text(title, style: T.display.copyWith(fontSize: 46, color: Palette.paper)),
              Text(subtitle, style: T.numeral.copyWith(color: Palette.sand, fontSize: 18)),
              if (child != null) ...[
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.only(right: 12), child: child),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.name, required this.time, required this.next, required this.quiet});
  final String name;
  final String time;
  final bool next;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final color = quiet ? Palette.inkSoft : Palette.ink;
    return Column(
      children: [
        Container(
          color: next ? Palette.sand : null,
          foregroundDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: next ? Palette.greenDeep : Colors.transparent, width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(name, style: T.title.copyWith(color: color)),
              ),
              Text(time, style: T.numeral.copyWith(color: color)),
            ],
          ),
        ),
        const Rule(),
      ],
    );
  }
}
