import 'dart:async';
import 'dart:io';

/// Keeps each verse recording on the phone after its first download, so a
/// verse repeats (and replays later) with no internet and no extra data.
class AudioStore {
  AudioStore({
    Directory? directory,
    this.maxBytes = 200 * 1024 * 1024,
    this.timeout = const Duration(seconds: 15),
  }) : _dir = directory ?? Directory('${Directory.systemTemp.path}/verse_audio');

  final Directory _dir;

  /// Oldest recordings are removed once the store grows past this.
  final int maxBytes;

  /// Longest wait for the server to connect, to answer, or to send more.
  final Duration timeout;

  /// Downloads in progress, so a verse asked for twice is fetched once.
  final _inFlight = <String, Future<File>>{};

  /// "…/64/ar.husary/262.mp3" becomes "ar.husary_64_262.mp3". Only letters,
  /// digits, dots and dashes survive, so a name can never leave the folder.
  static String fileName(Uri url) {
    final s = url.pathSegments.where((p) => p.isNotEmpty).toList();
    if (s.length < 3) throw ArgumentError.value(url, 'url', 'not a verse address');
    String clean(String part) =>
        part.replaceAll(RegExp('[^A-Za-z0-9.-]'), '_').replaceAll(RegExp(r'\.{2,}'), '_');
    return '${clean(s[s.length - 2])}_${clean(s[s.length - 3])}_${clean(s.last)}';
  }

  /// Returns the local file for [url], downloading it first if needed.
  /// Throws when it is not stored and cannot be downloaded.
  Future<File> fetch(String url) async {
    final uri = Uri.parse(url);
    final name = fileName(uri);
    final running = _inFlight[name];
    if (running != null) return running;
    final download = _fetch(uri, File('${_dir.path}/$name'));
    _inFlight[name] = download;
    try {
      return await download;
    } finally {
      // Waiters already hold the same future; this only clears the slot.
      _inFlight.remove(name)?.ignore();
    }
  }

  Future<File> _fetch(Uri uri, File file) async {
    if (await file.exists() && await file.length() > 0) return file;

    await _dir.create(recursive: true);
    final part = File('${file.path}.part');
    final client = HttpClient()..connectionTimeout = timeout;
    IOSink? sink;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      sink = part.openWrite();
      var received = 0;
      // The timeout applies between chunks, so a stalled download is dropped.
      await for (final chunk in response.timeout(timeout)) {
        received += chunk.length;
        sink.add(chunk);
      }
      await sink.close();
      sink = null;
      final expected = response.contentLength;
      if (received == 0 || (expected >= 0 && received != expected)) {
        throw HttpException('incomplete download ($received bytes)', uri: uri);
      }
      // Renaming last means a half-finished download is never played.
      return await part.rename(file.path);
    } catch (_) {
      // Release the file before removing it, whatever state the write is in.
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  /// Deletes the least recently used recordings until under [maxBytes].
  Future<void> prune() async {
    if (!await _dir.exists()) return;
    final files = <(File, FileStat)>[];
    await for (final e in _dir.list()) {
      if (e is File) files.add((e, await e.stat()));
    }
    var total = files.fold<int>(0, (n, f) => n + f.$2.size);
    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    for (final (file, stat) in files) {
      if (total <= maxBytes) break;
      try {
        await file.delete();
        total -= stat.size;
      } catch (_) {} // in use right now; it will go next time
    }
  }
}
