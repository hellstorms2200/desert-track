import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ESRI World Imagery – free, no API key
const kSatelliteUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

class TileCacheService {
  static String? _cacheDir;

  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = p.join(appDir.path, 'tile_cache');
    await Directory(_cacheDir!).create(recursive: true);
  }

  static String get cacheDir => _cacheDir ?? '';

  static Future<String> cacheSizeFormatted() async {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) return '0 MB';
    int total = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) total += e.lengthSync();
    }
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Future<void> clearCache() async {
    final dir = Directory(cacheDir);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  static Future<void> downloadRegion({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int minZoom = 8,
    int maxZoom = 14,
    void Function(int done, int total)? onProgress,
  }) async {
    final tiles = <({int z, int x, int y})>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final t1 = _tile(minLat, minLon, z);
      final t2 = _tile(maxLat, maxLon, z);
      final x0 = min(t1.$1, t2.$1);
      final x1 = max(t1.$1, t2.$1);
      final y0 = min(t1.$2, t2.$2);
      final y1 = max(t1.$2, t2.$2);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          tiles.add((z: z, x: x, y: y));
        }
      }
    }
    int done = 0;
    for (final t in tiles) {
      await _downloadTile(t.z, t.x, t.y);
      onProgress?.call(++done, tiles.length);
    }
  }

  static Future<void> _downloadTile(int z, int x, int y) async {
    final file = _tileFile(z, x, y);
    if (file.existsSync()) return;
    final url = kSatelliteUrl
        .replaceAll('{z}', '$z')
        .replaceAll('{y}', '$y')
        .replaceAll('{x}', '$x');
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(res.bodyBytes, flush: true);
      }
    } catch (_) {}
  }

  static File _tileFile(int z, int x, int y) =>
      File(p.join(cacheDir, '$z', '$x', '$y.png'));

  static (int, int) _tile(double lat, double lon, int z) {
    final n = 1 << z;
    final x = ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
    final lr = lat * pi / 180.0;
    final y = ((1.0 - log(tan(lr) + 1.0 / cos(lr)) / pi) / 2.0 * n)
        .floor()
        .clamp(0, n - 1);
    return (x, y);
  }
}

// ─── Caching TileProvider ────────────────────────────────────────────────────

class CachedSatelliteTileProvider extends TileProvider {
  const CachedSatelliteTileProvider();

  @override
  ImageProvider<Object> getImage(
      TileCoordinates coords, TileLayer options) {
    final file = File(p.join(
      TileCacheService.cacheDir,
      '${coords.z}', '${coords.x}', '${coords.y}.png',
    ));
    if (file.existsSync()) return FileImage(file);
    return _NetCacheImage(
        url: getTileUrl(coords, options), cacheFile: file);
  }
}

class _NetCacheImage extends ImageProvider<_NetCacheImage> {
  final String url;
  final File cacheFile;
  const _NetCacheImage({required this.url, required this.cacheFile});

  @override
  Future<_NetCacheImage> obtainKey(ImageConfiguration c) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
      _NetCacheImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _fetch(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _fetch(
      _NetCacheImage key, ImageDecoderCallback decode) async {
    try {
      final res = await http
          .get(Uri.parse(key.url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        try {
          await key.cacheFile.parent.create(recursive: true);
          await key.cacheFile.writeAsBytes(res.bodyBytes, flush: true);
        } catch (_) {}
        return decode(
            await ui.ImmutableBuffer.fromUint8List(res.bodyBytes));
      }
    } catch (_) {}
    return decode(
        await ui.ImmutableBuffer.fromUint8List(_kTransparentPng));
  }

  @override
  bool operator ==(Object o) => o is _NetCacheImage && url == o.url;
  @override
  int get hashCode => url.hashCode;
}

final Uint8List _kTransparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
  0x0a, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x62, 0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0xe2, 0x21, 0xbc, 0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);
