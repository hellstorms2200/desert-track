import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TileCacheService {
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/tile_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
  }

  static Future<String> getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/tile_cache';
  }
}
