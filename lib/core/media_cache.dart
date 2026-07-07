import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MediaCache {
  const MediaCache._();

  static const int maxCacheBytes = 500 * 1024 * 1024;

  static Future<String> cachedMediaPath({
    required String url,
    required String cacheKey,
    String extensionHint = 'mp4',
  }) async {
    final directory = await _cacheDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}${_fileName(cacheKey, url, extensionHint)}');
    if (await file.exists() && await file.length() > 0) {
      await file.setLastModified(DateTime.now());
      return file.path;
    }

    final partialFile = File('${file.path}.part');
    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(const Duration(minutes: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('media download failed: HTTP ${response.statusCode}');
      }

      final sink = partialFile.openWrite();
      try {
        await sink.addStream(response.stream);
      } finally {
        await sink.close();
      }

      if (await partialFile.length() == 0) {
        throw Exception('media download failed: empty file');
      }
      await partialFile.rename(file.path);
      await trimToSize(maxCacheBytes);
      return file.path;
    } catch (_) {
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  static String fileUri(String path) => Uri.file(path).toString();

  static Future<int> cacheSizeBytes() async {
    final directory = await _cacheDirectory();
    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  static Future<void> clear() async {
    final directory = await _cacheDirectory();
    await for (final entity in directory.list(followLinks: false)) {
      await entity.delete(recursive: true);
    }
  }

  static Future<void> trimToSize(int maxBytes) async {
    final directory = await _cacheDirectory();
    final files = <File>[];
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File && !entity.path.endsWith('.part')) {
        files.add(entity);
      }
    }

    var total = 0;
    final entries = <({File file, DateTime modified, int size})>[];
    for (final file in files) {
      final stat = await file.stat();
      total += stat.size;
      entries.add((file: file, modified: stat.modified, size: stat.size));
    }
    if (total <= maxBytes) return;

    entries.sort((a, b) => a.modified.compareTo(b.modified));
    for (final entry in entries) {
      if (total <= maxBytes) break;
      try {
        await entry.file.delete();
        total -= entry.size;
      } catch (_) {
        // Best effort: cache cleanup should never block media playback.
      }
    }
  }

  static Future<Directory> _cacheDirectory() async {
    final root = await getApplicationCacheDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}media_cache');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static String _fileName(String cacheKey, String url, String extensionHint) {
    final source = cacheKey.trim().isNotEmpty ? cacheKey.trim() : url;
    final hash = _fnv1a(source);
    final label = source
        .split(RegExp(r'[\\/]'))
        .where((part) => part.trim().isNotEmpty)
        .lastOrNull
        ?.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final safeLabel = label == null || label.isEmpty ? 'media' : label;
    final extension = _extension(source, url, extensionHint);
    final base = safeLabel.length > 48 ? safeLabel.substring(safeLabel.length - 48) : safeLabel;
    final withoutExtension = base.replaceFirst(RegExp(r'\.[A-Za-z0-9]{1,8}$'), '');
    return '${withoutExtension}_$hash.$extension';
  }

  static String _extension(String cacheKey, String url, String extensionHint) {
    for (final value in [cacheKey, Uri.tryParse(url)?.path ?? '', extensionHint]) {
      final match = RegExp(r'\.([A-Za-z0-9]{1,8})$').firstMatch(value);
      if (match != null) {
        return match.group(1)!.toLowerCase();
      }
    }
    return extensionHint.replaceAll(RegExp(r'^\.+'), '').toLowerCase();
  }

  static String _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
