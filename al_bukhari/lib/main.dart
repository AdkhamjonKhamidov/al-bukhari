import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/place_time.dart';
import 'core/services.dart';
import 'data/quran.dart';
import 'data/settings.dart';
import 'features/quran/verse_player.dart';
import 'src/rust/frb_generated.dart';
import 'theme/brand.dart';
import 'theme/palette.dart';
import 'theme/theme.dart';

Future<Services> startServices() async {
  await RustLib.init();
  // Recitation is spoken audio: it plays with the silent switch on (iOS)
  // and pauses other audio while it plays.
  final audio = await AudioSession.instance;
  await audio.configure(const AudioSessionConfiguration.speech());
  initTimeZones();
  final (quran, settings) = await (Quran.load(), Settings.load()).wait;
  return Services(
    quran: quran,
    settings: settings,
    player: VersePlayer(JustAudioEngine(), settings),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Boot(start: startServices));
}

/// Shows the mark while the app loads, then the app. If loading fails the
/// user gets a way to try again instead of a frozen screen.
class Boot extends StatefulWidget {
  const Boot({super.key, required this.start});
  final Future<Services> Function() start;

  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  late Future<Services> _services = widget.start();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Services>(
      future: _services,
      builder: (context, snap) {
        final services = snap.data;
        if (services != null) return AlBukhariApp(services: services);
        final failed = snap.hasError && snap.connectionState == ConnectionState.done;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: Palette.green,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 160),
                  if (failed) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.paper,
                        foregroundColor: Palette.ink,
                        textStyle: T.label.copyWith(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        minimumSize: const Size(48, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      onPressed: () => setState(() => _services = widget.start()),
                      child: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
