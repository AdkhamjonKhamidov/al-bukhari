import 'package:flutter/material.dart';

import '../../core/services.dart';
import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import 'place_picker.dart';

/// Shown by Qibla and Prayer until the app has a place: GPS, or pick one.
class PlaceGate extends StatefulWidget {
  const PlaceGate({super.key, required this.title});
  final String title;

  @override
  State<PlaceGate> createState() => _PlaceGateState();
}

class _PlaceGateState extends State<PlaceGate> {
  bool _busy = false;
  LocateFailure? _failure;

  Future<void> _gps() async {
    setState(() => _busy = true);
    final result = await AppScope.of(context).useGps();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = result.failure;
    });
  }

  static String _message(LocateFailure f) => switch (f) {
    LocateFailure.serviceOff => 'Location is off',
    LocateFailure.denied => 'Location not allowed',
    LocateFailure.deniedForever => 'Location blocked',
    LocateFailure.unavailable => 'Location not found',
  };

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return OrnamentBand(
      child: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CustomPaint(
                      size: const Size(96, 124),
                      painter: const _ArchIcon(),
                      child: const SizedBox(
                        width: 96,
                        height: 124,
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Icon(Icons.place_outlined, size: 40, color: Palette.paper),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.title,
                    style: T.display.copyWith(color: Palette.paper),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    failure == null ? 'Stays on this phone' : _message(failure),
                    style: T.label.copyWith(fontSize: 16, color: Palette.sand),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.sand,
                      foregroundColor: Palette.ink,
                    ),
                    onPressed: _busy ? () {} : _gps,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Palette.ink),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(_busy ? 'Finding…' : 'Use GPS'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.paper,
                      side: const BorderSide(color: Palette.sand, width: 1.5),
                    ),
                    onPressed: () => openPlacePicker(context, offerGps: false),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Choose city'),
                  ),
                  if (failure == LocateFailure.deniedForever)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Palette.sand),
                      onPressed: AppScope.of(context).openSettings,
                      child: const Text('Open settings'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchIcon extends CustomPainter {
  const _ArchIcon();

  @override
  void paint(Canvas canvas, Size size) {
    final path = archPath(Offset.zero & size, rise: 0.55);
    canvas.drawPath(path, Paint()..color = Palette.ink.withValues(alpha: 0.22));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Palette.sand,
    );
  }

  @override
  bool shouldRepaint(_ArchIcon oldDelegate) => false;
}
