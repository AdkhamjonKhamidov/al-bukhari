import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/services.dart';
import '../../data/quran.dart';
import '../../data/settings.dart';
import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import 'player_panel.dart';
import 'verse_marker.dart';
import 'verse_player.dart';

const arabicSizes = [24.0, 29.0, 35.0];

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.surah, this.initialAyah});
  final Surah surah;

  /// 1-based verse to open at.
  final int? initialAyah;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _scroll = ItemScrollController();
  VersePlayer? _player;
  int _followed = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_player == null) {
      _player = AppScope.of(context).player..addListener(_follow);
      _followed = _player!.index;
    }
  }

  @override
  void dispose() {
    _player?.removeListener(_follow);
    super.dispose();
  }

  /// Keeps the verse that is playing in view as the player moves on.
  void _follow() {
    final p = _player!;
    if (p.surah?.number != widget.surah.number || p.index == _followed) return;
    _followed = p.index;
    if (!_scroll.isAttached) return;
    unawaited(
      _scroll.scrollTo(
        index: p.index + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      ),
    );
  }

  void _longPress(VersePlayer player, int i) {
    unawaited(HapticFeedback.selectionClick());
    final anchor = player.surah?.number == widget.surah.number ? player.index : i;
    unawaited(player.playRange(widget.surah, anchor, i));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final surah = widget.surah;
    return Scaffold(
      appBar: AppBar(
        title: Text(surah.englishName),
        actions: [
          IconButton(
            tooltip: 'Text',
            icon: const Icon(Icons.text_fields_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => AppScope(services: s, child: const _TextSheet()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([s.player, s.settings]),
        builder: (context, _) => ScrollablePositionedList.builder(
          itemScrollController: _scroll,
          initialScrollIndex: widget.initialAyah ?? 0,
          initialAlignment: widget.initialAyah == null ? 0 : 0.12,
          itemCount: surah.ayahs.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _SurahHeading(surah: surah, quran: s.quran, settings: s.settings);
            final index = i - 1;
            return _VerseTile(
              ayah: surah.ayahs[index],
              number: index + 1,
              settings: s.settings,
              current: s.player.isCurrent(surah, index),
              selected: s.player.inSelection(surah, index),
              onTap: () => s.player.play(surah, index),
              onLongPress: () => _longPress(s.player, index),
            );
          },
        ),
      ),
      bottomNavigationBar: PlayerPanel(surah: surah),
    );
  }
}

class _SurahHeading extends StatelessWidget {
  const _SurahHeading({required this.surah, required this.quran, required this.settings});
  final Surah surah;
  final Quran quran;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrnamentBand(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Column(
            children: [
              Text(
                surah.arabicName,
                style: T.arabicName.copyWith(fontSize: 44, color: Palette.paper, height: 1.7),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              Text(
                surah.meaning,
                style: T.title.copyWith(color: Palette.paper, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${surah.place.toUpperCase()}  ·  ${surah.ayahs.length} VERSES',
                style: T.eyebrow.copyWith(color: Palette.sand),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (surah.showsBasmala)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              children: [
                Text(
                  quran.basmala,
                  style: T
                      .arabic(arabicSizes[settings.arabicSize])
                      .copyWith(color: Palette.greenDeep),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                if (settings.showPhonetic)
                  Text(quran.basmalaPhonetic, style: T.phonetic, textAlign: TextAlign.center),
              ],
            ),
          ),
        const Rule(),
      ],
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({
    required this.ayah,
    required this.number,
    required this.settings,
    required this.current,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });
  final Ayah ayah;
  final int number;
  final Settings settings;
  final bool current;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: current,
      label: 'Verse $number',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Palette.sand : null,
            border: const Border(bottom: BorderSide(color: Palette.tan)),
          ),
          foregroundDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: current ? Palette.greenDeep : Colors.transparent, width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: VerseMarker(number: number, active: current),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      ayah.arabic,
                      style: T.arabic(arabicSizes[settings.arabicSize]),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
              if (settings.showPhonetic) ...[
                const SizedBox(height: 6),
                Text(ayah.phonetic, style: T.phonetic),
              ],
              if (settings.showTranslation) ...[
                const SizedBox(height: 6),
                Text(ayah.english, style: T.reading),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reading options: which lines to show and how large the Arabic is.
class _TextSheet extends StatelessWidget {
  const _TextSheet();

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Phonetic', style: T.title),
                value: settings.showPhonetic,
                onChanged: settings.setShowPhonetic,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('English', style: T.title),
                value: settings.showTranslation,
                onChanged: settings.setShowTranslation,
              ),
              const SizedBox(height: 8),
              Choice<int>(
                options: const {0: 'ع', 1: 'ع', 2: 'ع'},
                sizes: arabicSizes,
                value: settings.arabicSize,
                onChanged: settings.setArabicSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
