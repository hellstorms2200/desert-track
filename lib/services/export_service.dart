import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../models/track_point.dart';

class ExportService {
  static Future<void> exportGPX(Trip trip, List<TrackPoint> points) async {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="Desert Track">')
      ..writeln('  <trk><name>${trip.name}</name><trkseg>');
    for (final p in points) {
      buf
        ..writeln('    <trkpt lat="${p.latitude}" lon="${p.longitude}">')
        ..writeln('      <ele>${p.altitude}</ele>')
        ..writeln('      <time>${p.timestamp.toIso8601String()}</time>')
        ..writeln('    </trkpt>');
    }
    buf
      ..writeln('  </trkseg></trk>')
      ..writeln('</gpx>');
    await _share(buf.toString(), '${trip.name}.gpx');
  }

  static Future<void> exportKML(Trip trip, List<TrackPoint> points) async {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
      ..writeln('<Document><name>${trip.name}</name>')
      ..writeln('<Placemark><LineString><coordinates>');
    for (final p in points) {
      buf.writeln('${p.longitude},${p.latitude},${p.altitude}');
    }
    buf
      ..writeln('</coordinates></LineString></Placemark>')
      ..writeln('</Document></kml>');
    await _share(buf.toString(), '${trip.name}.kml');
  }

  static Future<void> _share(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: filename);
  }
}
