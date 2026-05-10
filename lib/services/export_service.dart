import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../models/track_point.dart';

class ExportService {
  static Future<void> exportGPX(Trip trip, List<TrackPoint> points) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Desert Track">');
    buffer.writeln('  <trk><name>${trip.name}</name><trkseg>');
    for (final p in points) {
      buffer.writeln(
          '    <trkpt lat="${p.latitude}" lon="${p.longitude}">');
      buffer.writeln('      <ele>${p.altitude}</ele>');
      buffer.writeln('      <time>${p.timestamp.toIso8601String()}</time>');
      buffer.writeln('    </trkpt>');
    }
    buffer.writeln('  </trkseg></trk></gpx>');
    await _shareFile(buffer.toString(), '${trip.name}.gpx');
  }

  static Future<void> exportKML(Trip trip, List<TrackPoint> points) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document><name>${trip.name}</name>');
    buffer.writeln('<Placemark><LineString><coordinates>');
    for (final p in points) {
      buffer.writeln('${p.longitude},${p.latitude},${p.altitude}');
    }
    buffer.writeln('</coordinates></LineString></Placemark>');
    buffer.writeln('</Document></kml>');
    await _shareFile(buffer.toString(), '${trip.name}.kml');
  }

  static Future<void> _shareFile(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: filename);
  }
}
