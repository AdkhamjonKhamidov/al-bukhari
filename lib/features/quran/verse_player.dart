import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/quran.dart';
import '../../data/settings.dart';
import 'audio_store.dart';

/// The small slice of an audio player the memorisation logic needs.
abstract class AudioEngine {
  Future<void> load(String url);

  /// Starts downloading [url] so it is ready when needed.
  Future<void> prefetch(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> replay();
  Future<void> stop();

  /// Fires each time the loaded clip plays to its end.
  Stream<void> get completed;
  void dispose();
}

class JustAudioEngine implements AudioEngine {
  JustAudioEngine([AudioStore? store]) : _store = store ?? AudioStore() {
    _store.prune().ignore();
  }

  final AudioStore _store;
  final _player = AudioPlayer();

  @override
  Future<void> load(String url) async {
    final file = await _store.fetch(url);
    await _player.setFilePath(file.path);
  }

  @override
  Future<void> prefetch(String url) async {
    try {
      await _store.fetch(url);
    } catch (_) {
      // Only a head start; the real load will try again and report.
    }
  }

  // play() only completes when playback stops, so it is not awaited.
  @override
  Future<void> play() async => unawaited(_player.play());

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> replay() async {
    await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get completed =>
      _player.processingStateStream.where((s) => s == ProcessingState.completed).map((_) {});

  @override
  void dispose() => unawaited(_player.dispose());
}

enum PlayerStatus { idle, loading, playing, paused, error }

/// Plays a verse, a range of verses or a whole surah, and loops it.
class VersePlayer extends ChangeNotifier {
  VersePlayer(this._engine, this._settings) {
    _sub = _engine.completed.listen((_) => _onCompleted());
  }

  final AudioEngine _engine;
  final Settings _settings;
  late final StreamSubscription<void> _sub;

  Surah? _surah;
  int _index = 0;
  int _from = 0;
  int _to = 0;
  int _pass = 1;
  int _request = 0;
  bool _disposed = false;
  PlayerStatus _status = PlayerStatus.idle;

  Surah? get surah => _surah;

  /// Zero-based index of the verse playing (or ready to play).
  int get index => _index;

  /// First and last verse (zero-based) of what repeats.
  int get from => _from;
  int get to => _to;

  /// Which time through the selection, starting at 1.
  int get pass => _pass;
  PlayerStatus get status => _status;

  bool isCurrent(Surah s, int i) => _surah?.number == s.number && _index == i;
  bool inSelection(Surah s, int i) => _surah?.number == s.number && i >= _from && i <= _to;

  /// One verse of recitation from the Islamic Network CDN: the only address
  /// the app ever contacts. 64 kbps is clear for speech and half the data
  /// of the usual 128.
  static String audioUrl(int globalAyah, String reciter) =>
      'https://cdn.islamic.network/quran/audio/64/$reciter/$globalAyah.mp3';

  /// Plays from verse [index]. What repeats follows the scope setting.
  Future<void> play(Surah surah, int index) {
    final last = surah.ayahs.length - 1;
    switch (_settings.scope) {
      case RepeatScope.verse:
        _from = index;
        _to = index;
      case RepeatScope.surah:
        _from = 0;
        _to = last;
      case RepeatScope.range:
        if (!inSelection(surah, index)) {
          _from = index;
          _to = index;
        }
    }
    _pass = 1;
    return _load(surah, index);
  }

  /// Repeats verses [a] to [b] (either order), starting at the first.
  Future<void> playRange(Surah surah, int a, int b) {
    _settings.setScope(RepeatScope.range);
    final last = surah.ayahs.length - 1;
    _from = (a < b ? a : b).clamp(0, last);
    _to = (a < b ? b : a).clamp(0, last);
    _pass = 1;
    return _load(surah, _from);
  }

  /// Applies a new scope to the verse already chosen.
  Future<void> rescope(RepeatScope scope) async {
    _settings.setScope(scope);
    final surah = _surah;
    if (surah != null) await play(surah, _index);
  }

  Future<void> next() => _step(1);
  Future<void> previous() => _step(-1);

  Future<void> _step(int by) async {
    final surah = _surah;
    if (surah == null) return;
    final i = (_index + by).clamp(0, surah.ayahs.length - 1);
    if (i != _index) await play(surah, i);
  }

  Future<void> toggle() async {
    final surah = _surah;
    if (surah == null) return;
    switch (_status) {
      case PlayerStatus.playing:
        await _command(_engine.pause, PlayerStatus.paused);
      case PlayerStatus.paused:
        await _command(_engine.play, PlayerStatus.playing);
      case PlayerStatus.idle || PlayerStatus.error:
        await _load(surah, _index);
      case PlayerStatus.loading:
        break;
    }
  }

  Future<void> stop() async {
    final request = ++_request;
    try {
      await _engine.stop();
    } catch (_) {
      // Stopping is a request to go quiet; a speaker fault changes nothing.
    }
    if (request != _request) return;
    _status = PlayerStatus.idle;
    _pass = 1;
    _notify();
  }

  String _url(Surah surah, int i) => audioUrl(surah.firstGlobalAyah + i, _settings.reciter);

  Future<void> _load(Surah surah, int index) async {
    final request = ++_request;
    _surah = surah;
    _index = index;
    _status = PlayerStatus.loading;
    _settings.setLastRead(surah.number, index + 1);
    _notify();
    try {
      await _engine.load(_url(surah, index));
      if (request != _request) return; // a newer command arrived meanwhile
      await _engine.play();
      if (request != _request) return;
      _status = PlayerStatus.playing;
      // Fetch the next verse now so the selection plays without a gap.
      final next = index < _to ? index + 1 : _from;
      if (next != index) unawaited(_engine.prefetch(_url(surah, next)));
    } catch (_) {
      if (request != _request) return;
      _status = PlayerStatus.error;
    }
    _notify();
  }

  /// Sends one command to the speaker. A failure becomes the error state,
  /// never a crash; a result that arrives after a newer command is ignored.
  Future<void> _command(Future<void> Function() action, PlayerStatus then) async {
    final request = ++_request;
    try {
      await action();
      if (request != _request) return;
      _status = then;
    } catch (_) {
      if (request != _request) return;
      _status = PlayerStatus.error;
    }
    _notify();
  }

  Future<void> _onCompleted() async {
    final surah = _surah;
    if (surah == null || _status != PlayerStatus.playing) return;
    if (_index < _to) return _load(surah, _index + 1);

    final repeat = _settings.repeat;
    if (repeat != 0 && _pass >= repeat) {
      _status = PlayerStatus.idle;
      _pass = 1;
      _index = _from;
      return _notify();
    }
    _pass++;
    if (_from != _to) return _load(surah, _from);
    _notify();
    final request = _request;
    try {
      await _engine.replay();
    } catch (_) {
      if (request != _request) return;
      _status = PlayerStatus.error;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sub.cancel());
    _engine.dispose();
    super.dispose();
  }
}
