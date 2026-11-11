import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services.dart';
import '../../data/quran.dart';
import '../../data/settings.dart';
import '../../theme/palette.dart';
import '../../theme/theme.dart';
import 'verse_player.dart';

String timesLabel(int repeat) => repeat == 0 ? '∞' : '×$repeat';

/// The memorisation controls, docked under the text.
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({super.key, required this.surah});
  final Surah surah;

  String _what(VersePlayer p, Settings s, bool here) {
    if (!here) return 'Tap a verse';
    return switch (s.scope) {
      RepeatScope.verse => 'Verse ${p.index + 1}',
      RepeatScope.range => 'Verses ${p.from + 1}–${p.to + 1}',
      RepeatScope.surah => 'Surah · verse ${p.index + 1}',
    };
  }

  String _progress(VersePlayer p, Settings s) => switch (p.status) {
    PlayerStatus.loading => '…',
    PlayerStatus.error => 'Offline',
    PlayerStatus.idle => '',
    _ => '${p.pass} / ${s.repeat == 0 ? '∞' : s.repeat}',
  };

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final player = services.player, settings = services.settings;
    return ListenableBuilder(
      listenable: Listenable.merge([player, settings]),
      builder: (context, _) {
        final here = player.surah?.number == surah.number;
        final status = here ? player.status : PlayerStatus.idle;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Palette.sand,
            border: Border(top: BorderSide(color: Palette.tan)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _what(player, settings, here),
                          style: T.title.copyWith(fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (status != PlayerStatus.idle)
                          Text(
                            _progress(player, settings),
                            style: T.numeral.copyWith(
                              fontSize: 14,
                              color: status == PlayerStatus.error ? Palette.alert : Palette.inkSoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _RepeatButton(surah: surah),
                  IconButton(
                    tooltip: 'Previous verse',
                    onPressed: here ? player.previous : null,
                    icon: const Icon(Icons.skip_previous_rounded, color: Palette.greenDeep),
                  ),
                  _PlayButton(
                    playing: status == PlayerStatus.playing,
                    busy: status == PlayerStatus.loading,
                    onPressed: here ? player.toggle : () => player.play(surah, 0),
                  ),
                  IconButton(
                    tooltip: 'Next verse',
                    onPressed: here ? player.next : null,
                    icon: const Icon(Icons.skip_next_rounded, color: Palette.greenDeep),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RepeatButton extends StatelessWidget {
  const _RepeatButton({required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Tooltip(
      message: 'Repeat',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => AppScope(
            services: s,
            child: RepeatSheet(surah: surah),
          ),
        ),
        // A fixed height: a centring box here would stretch to fill the
        // whole screen, because the panel is offered all of it.
        child: Container(
          height: 48,
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.repeat_rounded, size: 20, color: Palette.greenDeep),
              const SizedBox(width: 3),
              Text(
                timesLabel(s.settings.repeat),
                style: T.numeral.copyWith(fontSize: 16, color: Palette.greenDeep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.busy, required this.onPressed});
  final bool playing;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Pause' : 'Play',
      child: Material(
        color: Palette.greenDeep,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 56,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Palette.paper),
                  )
                : Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Palette.paper,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}

/// What to repeat (verse, range, surah) and how many times.
class RepeatSheet extends StatefulWidget {
  const RepeatSheet({super.key, required this.surah});
  final Surah surah;

  @override
  State<RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<RepeatSheet> {
  late Services _s;
  late RepeatScope _scope;
  late int _times;
  late int _from;
  late int _to;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _s = AppScope.of(context);
    final p = _s.player;
    final here = p.surah?.number == widget.surah.number;
    _scope = _s.settings.scope;
    _times = _s.settings.repeat;
    _from = here ? p.from : 0;
    _to = here ? p.to : 0;
    if (_scope == RepeatScope.surah || _to == _from) {
      _from = here ? p.index : 0;
      _to = (_from + 2).clamp(0, widget.surah.ayahs.length - 1);
    }
  }

  void _play() {
    _s.settings.setRepeat(_times);
    final p = _s.player;
    final here = p.surah?.number == widget.surah.number;
    if (_scope == RepeatScope.range) {
      unawaited(p.playRange(widget.surah, _from, _to));
    } else {
      _s.settings.setScope(_scope);
      unawaited(p.play(widget.surah, here ? p.index : 0));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.surah.ayahs.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('REPEAT', style: T.eyebrow),
            const SizedBox(height: 12),
            Choice<RepeatScope>(
              options: const {
                RepeatScope.verse: 'Verse',
                RepeatScope.range: 'Range',
                RepeatScope.surah: 'Surah',
              },
              value: _scope,
              onChanged: (v) => setState(() => _scope = v),
            ),
            if (_scope == RepeatScope.range) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Stepper(
                      label: 'From',
                      value: _from + 1,
                      min: 1,
                      max: last,
                      onChanged: (v) => setState(() {
                        _from = v - 1;
                        if (_to < _from) _to = _from;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stepper(
                      label: 'To',
                      value: _to + 1,
                      min: 1,
                      max: last,
                      onChanged: (v) => setState(() {
                        _to = v - 1;
                        if (_from > _to) _from = _to;
                      }),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const Text('TIMES', style: T.eyebrow),
            const SizedBox(height: 12),
            Choice<int>(
              options: {for (final t in Settings.repeatChoices) t: timesLabel(t)},
              value: _times,
              onChanged: (v) => setState(() => _times = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _play,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Play'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Palette.tan),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: T.eyebrow),
                Text('$value', style: T.numeral.copyWith(fontSize: 22)),
              ],
            ),
          ),
          IconButton(
            tooltip: '$label down',
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded, color: Palette.greenDeep),
          ),
          IconButton(
            tooltip: '$label up',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded, color: Palette.greenDeep),
          ),
        ],
      ),
    );
  }
}

/// A row of equal choices; the chosen one is filled deep green.
class Choice<V> extends StatelessWidget {
  const Choice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.sizes,
  });
  final Map<V, String> options;
  final V value;
  final ValueChanged<V> onChanged;

  /// Optional font size per option (used to preview text sizes).
  final List<double>? sizes;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Palette.greenDeep, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, e) in entries.indexed) ...[
              if (i > 0)
                const VerticalDivider(width: 1.5, thickness: 1.5, color: Palette.greenDeep),
              Expanded(
                child: Semantics(
                  selected: e.key == value,
                  button: true,
                  child: InkWell(
                    onTap: () => onChanged(e.key),
                    child: Container(
                      color: e.key == value ? Palette.greenDeep : null,
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        e.value,
                        style:
                            (sizes == null
                                    ? T.label.copyWith(fontSize: e.value == '∞' ? 24 : 16)
                                    : T.arabic(sizes![i] * 0.8))
                                .copyWith(
                                  height: sizes == null ? 1.2 : 1.3,
                                  color: e.key == value ? Palette.paper : Palette.greenDeep,
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
