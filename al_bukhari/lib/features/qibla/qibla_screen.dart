import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services.dart';
import '../../data/settings.dart';
import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../places/place_gate.dart';
import '../places/place_picker.dart';
import 'compass_dial.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) {
        final place = services.settings.place;
        if (place == null) return const PlaceGate(title: 'Qibla');
        return _Compass(key: ValueKey(place.coordinates), place: place);
      },
    );
  }
}

class _Compass extends StatefulWidget {
  const _Compass({super.key, required this.place});
  final Place place;

  @override
  State<_Compass> createState() => _CompassState();
}

class _CompassState extends State<_Compass> {
  StreamSubscription<double?>? _sub;
  late double _bearing;
  late double _distanceKm;
  late double _correction;
  bool _wasFacing = false;

  /// True heading in degrees, or null when the phone has no compass.
  double? _heading;

  /// Dial rotation in whole turns, accumulated so it never spins the long way.
  double _turns = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub != null) return;
    final s = AppScope.of(context);
    _bearing = s.core.qiblaBearing(widget.place);
    _distanceKm = s.core.distanceToKaabaKm(widget.place);
    _correction = s.core.headingCorrection(widget.place, s.now());
    _sub = s.heading().listen(_onHeading);
  }

  void _onHeading(double? raw) {
    if (!mounted || raw == null) return;
    final heading = (raw + _correction) % 360;
    final step = ((heading - (_heading ?? 0) + 540) % 360) - 180;
    final facing = _offBy(heading).abs() <= 3;
    if (facing && !_wasFacing) unawaited(HapticFeedback.heavyImpact());
    _wasFacing = facing;
    setState(() {
      _heading = heading;
      _turns -= step / 360;
    });
  }

  /// Degrees to turn: negative is left, positive is right.
  double _offBy(double heading) => ((_bearing - heading + 540) % 360) - 180;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading;
    final turn = heading == null ? null : _offBy(heading);
    final facing = turn != null && turn.abs() <= 3;
    return OrnamentBand(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PlaceBar(place: widget.place),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Center(
                  child: CompassDial(
                    bearing: _bearing,
                    turns: _turns,
                    facing: facing,
                    centre: _Readout(turn: turn, facing: facing),
                  ),
                ),
              ),
            ),
            _Stats(bearing: _bearing, distanceKm: _distanceKm),
          ],
        ),
      ),
    );
  }
}

class _PlaceBar extends StatelessWidget {
  const _PlaceBar({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: Palette.sand, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              place.label,
              style: T.title.copyWith(color: Palette.paper, fontSize: 18),
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
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.turn, required this.facing});
  final double? turn;
  final bool facing;

  @override
  Widget build(BuildContext context) {
    final turn = this.turn;
    final big = T.display.copyWith(
      fontFamily: Fonts.sans,
      fontSize: 52,
      color: Palette.paper,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (turn == null) {
      return Text('No compass', style: T.title.copyWith(color: Palette.sand));
    }
    if (facing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 40, color: Palette.sand),
          Text('Qibla', style: big.copyWith(fontFamily: Fonts.serif, fontSize: 40)),
        ],
      );
    }
    return Semantics(
      label: 'Turn ${turn < 0 ? 'left' : 'right'} ${turn.abs().round()} degrees',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            turn < 0 ? Icons.turn_left_rounded : Icons.turn_right_rounded,
            size: 40,
            color: Palette.sand,
          ),
          Text('${turn.abs().round()}°', style: big),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.bearing, required this.distanceKm});
  final double bearing;
  final double distanceKm;

  static String _thousands(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: T.numeral.copyWith(color: Palette.paper, fontSize: 24)),
          ),
          const SizedBox(height: 2),
          Text(label, style: T.eyebrow.copyWith(color: Palette.sand)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Row(
        children: [
          stat('${bearing.round()}°', 'FROM NORTH'),
          Container(width: 1, height: 36, color: Palette.green),
          stat('${_thousands(distanceKm.round())} km', 'TO MAKKAH'),
        ],
      ),
    );
  }
}
