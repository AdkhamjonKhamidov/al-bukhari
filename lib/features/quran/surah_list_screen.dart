import 'package:flutter/material.dart';

import '../../core/services.dart';
import '../../data/quran.dart';
import '../../theme/brand.dart';
import '../../theme/ornament.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import 'reader_screen.dart';
import 'verse_marker.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _query = '';

  void _open(Surah surah, {int? ayah}) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(surah: surah, initialAyah: ayah),
      ),
    );
  }

  List<Surah> _filter(List<Surah> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final n = int.tryParse(q);
    if (n != null) {
      return [
        for (final s in all)
          if (s.number.toString().startsWith(q)) s,
      ];
    }
    String plain(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
    final p = plain(q);
    return [
      for (final s in all)
        if (plain(s.englishName).contains(p) ||
            s.meaning.toLowerCase().contains(q) ||
            s.arabicName.contains(_query.trim()))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) {
        final last = services.settings.lastRead;
        final surahs = _filter(services.quran.surahs);
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                last: last == null ? null : (services.quran.surahs[last.$1 - 1], last.$2),
                onContinue: (s, a) => _open(s, ayah: a),
                onQuery: (q) => setState(() => _query = q),
              ),
            ),
            if (surahs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No match', style: T.title)),
              ),
            SliverList.builder(
              itemCount: surahs.length,
              itemBuilder: (context, i) =>
                  _SurahRow(surah: surahs[i], onTap: () => _open(surahs[i])),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.last, required this.onContinue, required this.onQuery});
  final (Surah, int)? last;
  final void Function(Surah, int) onContinue;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final last = this.last;
    return OrnamentBand(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandLockup(color: Palette.paper),
              ),
              const SizedBox(height: 20),
              if (last != null) ...[
                _ContinueCard(
                  surah: last.$1,
                  ayah: last.$2,
                  onTap: () => onContinue(last.$1, last.$2),
                ),
                const SizedBox(height: 14),
              ],
              _SearchField(onChanged: onQuery),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.surah, required this.ayah, required this.onTap});
  final Surah surah;
  final int ayah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.sand,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONTINUE', style: T.eyebrow.copyWith(color: Palette.greenDeep)),
                    const SizedBox(height: 4),
                    Text(surah.englishName, style: T.title.copyWith(fontSize: 22)),
                    Text('Verse $ayah', style: T.label.copyWith(color: Palette.inkSoft)),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  surah.arabicName,
                  style: T.arabicName.copyWith(fontSize: 30),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Palette.greenDeep, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Palette.paper, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: T.reading.copyWith(color: Palette.paper),
      cursorColor: Palette.sand,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search surah',
        hintStyle: T.reading.copyWith(color: Palette.sand),
        prefixIcon: const Icon(Icons.search, color: Palette.sand),
        filled: true,
        fillColor: Palette.ink.withValues(alpha: 0.18),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.green),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.sand, width: 1.5),
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.surah, required this.onTap});
  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                VerseMarker(number: surah.number),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah.englishName, style: T.title),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.meaning}  ·  ${surah.ayahs.length}',
                        style: T.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    surah.arabicName,
                    style: T.arabicName,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Rule(indent: 20),
        ],
      ),
    );
  }
}
