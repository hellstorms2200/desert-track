import 'dart:io';
import 'package:path_provider/path_provider.dart';

const String kSatelliteUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

class TileCacheService {
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/tile_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
  }

  static Future<String> cacheSizeFormatted() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/tile_cache');
      if (!await cacheDir.exists()) return '0 MB';
      int bytes = 0;
      await for (final f in cacheDir.list(recursive: true)) {
        if (f is File) bytes += await f.length();
      }
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    } catch (_) {
      return '0 MB';
    }
  }

  static Future<void> clearCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/tile_cache');
    if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
    await cacheDir.create();
  }
}
