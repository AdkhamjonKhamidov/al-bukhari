import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services.dart';
import '../../data/settings.dart';
import '../../theme/brand.dart';
import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import '../places/place_picker.dart';
import '../prayer/prayer_screen.dart' show methodNames;

const appVersion = '1.0.0';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _pick<V>(
    BuildContext context,
    String title,
    Map<V, String> options,
    V current,
    void Function(V) onPicked,
  ) async {
    final picked = await showDialog<V>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final e in options.entries)
            InkWell(
              onTap: () => Navigator.pop(context, e.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: Text(e.value, style: T.reading)),
                    if (e.key == current) const Icon(Icons.check, color: Palette.greenDeep),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (picked != null) onPicked(picked);
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => ListView(
        padding: EdgeInsets.zero,
        children: [
          const _Masthead(),
          const _Heading('PLACE'),
          _Row(
            label: 'Place',
            value: settings.place?.label ?? 'Not set',
            onTap: () => openPlacePicker(context),
          ),
          const _Heading('QURAN'),
          _Row(
            label: 'Reciter',
            value: Settings.reciters[settings.reciter],
            onTap: () =>
                _pick(context, 'Reciter', Settings.reciters, settings.reciter, settings.setReciter),
          ),
          _Toggle(
            label: 'Phonetic',
            value: settings.showPhonetic,
            onChanged: settings.setShowPhonetic,
          ),
          _Toggle(
            label: 'English',
            value: settings.showTranslation,
            onChanged: settings.setShowTranslation,
          ),
          const _Heading('PRAYER TIMES'),
          _Row(
            label: 'Method',
            value: methodNames[settings.method],
            onTap: () => _pick(context, 'Method', methodNames, settings.method, settings.setMethod),
          ),
          _Row(
            label: 'Asr',
            value: settings.hanafiAsr ? 'Hanafi' : "Shafi'i",
            onTap: () => _pick(
              context,
              'Asr',
              const {true: 'Hanafi', false: "Shafi'i, Maliki, Hanbali"},
              settings.hanafiAsr,
              settings.setHanafiAsr,
            ),
          ),
          const _Heading('ABOUT'),
          _Row(label: 'Privacy', onTap: () => _open(context, const _PrivacyPage())),
          _Row(label: 'Sources', onTap: () => _open(context, const _SourcesPage())),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Version $appVersion', textAlign: TextAlign.center, style: T.label),
          ),
        ],
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) => OrnamentBand(
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Column(
          children: [
            const BrandMark(size: 84),
            const SizedBox(height: 12),
            Text(
              'AL BUKHARI',
              textAlign: TextAlign.center,
              style: T.title.copyWith(fontSize: 22, letterSpacing: 3, color: Palette.paper),
            ),
            const SizedBox(height: 6),
            Text(
              'No accounts  ·  No ads  ·  No tracking',
              textAlign: TextAlign.center,
              style: T.label.copyWith(color: Palette.sand),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
        child: Text(text, style: T.eyebrow.copyWith(color: Palette.greenDeep)),
      ),
      const Rule(),
    ],
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, required this.onTap});
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Row(
            children: [
              Text(label, style: T.title),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value ?? '',
                  style: T.label.copyWith(fontSize: 15),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: Palette.inkSoft),
            ],
          ),
        ),
        const Rule(indent: 20),
      ],
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
        title: Text(label, style: T.title),
        value: value,
        onChanged: onChanged,
      ),
      const Rule(indent: 20),
    ],
  );
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: children),
  );
}

/// Shows assets/legal/privacy.md, the same file that is hosted for the stores.
class _PrivacyPage extends StatefulWidget {
  const _PrivacyPage();

  @override
  State<_PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<_PrivacyPage> {
  final _text = rootBundle.loadString('assets/legal/privacy.md');

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _text,
    builder: (context, snap) => _Page(
      title: 'Privacy',
      children: [
        for (final line in (snap.data ?? '').split('\n'))
          if (line.startsWith('# '))
            const SizedBox.shrink()
          else if (line.startsWith('## '))
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 6),
              child: Text(line.substring(3).toUpperCase(), style: T.eyebrow),
            )
          else if (line.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(line.replaceAll('**', '').replaceAll('`', ''), style: T.reading),
            ),
      ],
    ),
  );
}

class _SourcesPage extends StatelessWidget {
  const _SourcesPage();

  @override
  Widget build(BuildContext context) => const _Page(
    title: 'Sources',
    children: [
      _Source(
        kind: 'ARABIC TEXT',
        name: 'Tanzil Project, Uthmani',
        note: 'Hafs from Asim. Shown word for word, unchanged.',
        link: 'https://tanzil.net',
      ),
      _Source(
        kind: 'ENGLISH',
        name: 'Saheeh International',
        note: 'Translation and phonetic text via Tanzil. Non-commercial use.',
        link: 'https://tanzil.net/trans/',
      ),
      _Source(
        kind: 'RECITATION',
        name: 'Al-Husary, Alafasy',
        note: 'From the Islamic Network.',
        link: 'https://alquran.cloud',
      ),
      _Source(
        kind: 'PRAYER TIMES',
        name: 'Hanafi Asr, Karachi method',
        note: 'Calculated on this phone. Check with your mosque.',
      ),
      _Source(
        kind: 'PLACES',
        name: 'GeoNames',
        note: 'City list, CC BY 4.0. Searched on this phone.',
        link: 'https://www.geonames.org',
      ),
      _Source(
        kind: 'COMPASS',
        name: 'NOAA World Magnetic Model',
        note: 'True north, calculated on this phone.',
      ),
      _Source(
        kind: 'TYPE',
        name: 'Amiri Quran, Newsreader, Instrument Sans',
        note: 'SIL Open Font License 1.1.',
      ),
    ],
  );
}

class _Source extends StatelessWidget {
  const _Source({required this.kind, required this.name, required this.note, this.link});
  final String kind;
  final String name;
  final String note;
  final String? link;

  @override
  Widget build(BuildContext context) {
    final link = this.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(kind, style: T.eyebrow),
        const SizedBox(height: 4),
        Text(name, style: T.title),
        Text(note, style: T.reading.copyWith(color: Palette.inkSoft)),
        if (link != null)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => _openLink(link),
            child: Text(Uri.parse(link).host + Uri.parse(link).path.replaceAll(RegExp(r'/$'), '')),
          ),
        const SizedBox(height: 12),
        const Rule(),
      ],
    );
  }
}

/// Opens a source link in the browser. A phone with no browser does nothing.
Future<void> _openLink(String link) async {
  try {
    await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  } catch (_) {}
}
