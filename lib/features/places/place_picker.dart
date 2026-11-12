import 'package:flutter/material.dart';

import '../../core/services.dart';
import '../../data/places.dart';
import '../../data/settings.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';

/// Opens the place picker. Searching happens on the phone; nothing typed
/// here is sent anywhere.
Future<void> openPlacePicker(BuildContext context, {bool offerGps = true}) {
  final services = AppScope.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AppScope(
        services: services,
        child: _PlacePicker(offerGps: offerGps),
      ),
    ),
  );
}

class _PlacePicker extends StatefulWidget {
  const _PlacePicker({required this.offerGps});
  final bool offerGps;

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  String _query = '';
  bool _locating = false;
  String? _gpsError;

  void _choose(Place p) {
    AppScope.of(context).settings.setPlace(p);
    Navigator.pop(context);
  }

  Future<void> _gps() async {
    setState(() {
      _locating = true;
      _gpsError = null;
    });
    final result = await AppScope.of(context).useGps();
    if (!mounted) return;
    if (result.place != null) return Navigator.pop(context);
    setState(() {
      _locating = false;
      _gpsError = 'Location not available';
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final typed = Places.parseCoordinates(_query);
    return Scaffold(
      appBar: AppBar(title: const Text('Place')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              autofocus: true,
              onChanged: (q) => setState(() => _query = q),
              style: T.reading,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'City, or 41.31, 69.24',
                hintStyle: T.reading.copyWith(color: Palette.inkSoft),
                prefixIcon: const Icon(Icons.search_rounded, color: Palette.greenDeep),
                filled: true,
                fillColor: Palette.sand,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (widget.offerGps)
            _Row(
              icon: Icons.my_location_rounded,
              title: _locating ? 'Finding…' : 'Use GPS',
              subtitle: _gpsError,
              onTap: _locating ? null : _gps,
            ),
          if (typed != null)
            _Row(
              icon: Icons.pin_drop_outlined,
              title: typed.coordinates,
              onTap: () => _choose(typed),
            ),
          Expanded(
            child: FutureBuilder<Places>(
              future: services.places,
              builder: (context, snap) {
                final places = snap.data;
                if (places == null) {
                  return snap.hasError
                      ? const Center(child: Text('City list unavailable', style: T.label))
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Palette.greenDeep,
                            strokeWidth: 2,
                          ),
                        );
                }
                final found = places.search(_query);
                if (found.isEmpty && _query.trim().length >= 2 && typed == null) {
                  return const Center(child: Text('No match', style: T.title));
                }
                return ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: found.length,
                  itemBuilder: (context, i) => _Row(
                    icon: Icons.location_city_outlined,
                    title: found[i].name,
                    subtitle: found[i].country,
                    onTap: () => _choose(found[i].toPlace()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Icon(icon, color: Palette.greenDeep),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: T.title.copyWith(fontSize: 18)),
                      if (subtitle != null) Text(subtitle, style: T.label),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Rule(indent: 60),
        ],
      ),
    );
  }
}
