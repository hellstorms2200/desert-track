import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/trip.dart';

class ExportService {
  static Future<String> exportGpx(Trip trip) async {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<gpx version="1.1" creator="Desert Track" xmlns="http://www.topografix.com/GPX/1/1">');
    buf.writeln('  <metadata>');
    buf.writeln('    <name>${_esc(trip.name)}</name>');
    buf.writeln('    <time>${trip.startTime.toIso8601String()}</time>');
    buf.writeln('  </metadata>');
    for (final wp in trip.waypoints) {
      buf.writeln('  <wpt lat="${wp.latitude}" lon="${wp.longitude}">');
      buf.writeln('    <name>${_esc(wp.name)}</name>');
      buf.writeln('    <desc>${_esc(wp.description)}</desc>');
      buf.writeln('    <time>${wp.timestamp.toIso8601String()}</time>');
      buf.writeln('  </wpt>');
    }
    buf.writeln('  <trk>');
    buf.writeln('    <name>${_esc(trip.name)}</name>');
    buf.writeln('    <trkseg>');
    for (final pt in trip.trackPoints) {
      buf.writeln('      <trkpt lat="${pt.latitude}" lon="${pt.longitude}">');
      buf.writeln('        <ele>${pt.altitude.toStringAsFixed(1)}</ele>');
      buf.writeln('        <time>${pt.timestamp.toIso8601String()}</time>');
      buf.writeln('        <extensions>');
      buf.writeln('          <speed>${pt.speed.toStringAsFixed(2)}</speed>');
      buf.writeln('          <course>${pt.bearing.toStringAsFixed(1)}</course>');
      buf.writeln('        </extensions>');
      buf.writeln('      </trkpt>');
    }
    buf.writeln('    </trkseg>');
    buf.writeln('  </trk>');
    buf.writeln('</gpx>');

    final path = await _exportPath('${_safeName(trip.name)}.gpx');
    await File(path).writeAsString(buf.toString());
    return path;
  }

  static Future<String> exportKml(Trip trip) async {
    final coords = trip.trackPoints
        .map((p) => '${p.longitude},${p.latitude},${p.altitude.toStringAsFixed(1)}')
        .join('\n');

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buf.writeln('<Document>');
    buf.writeln('  <name>${_esc(trip.name)}</name>');
    buf.writeln('  <Style id="trackStyle">');
    buf.writeln('    <LineStyle><color>ff0088ff</color><width>4</width></LineStyle>');
    buf.writeln('  </Style>');
    buf.writeln('  <Placemark>');
    buf.writeln('    <name>${_esc(trip.name)}</name>');
    buf.writeln('    <styleUrl>#trackStyle</styleUrl>');
    buf.writeln('    <LineString>');
    buf.writeln('      <altitudeMode>clampToGround</altitudeMode>');
    buf.writeln('      <coordinates>$coords</coordinates>');
    buf.writeln('    </LineString>');
    buf.writeln('  </Placemark>');
    for (final wp in trip.waypoints) {
      buf.writeln('  <Placemark>');
      buf.writeln('    <name>${_esc(wp.name)}</name>');
      buf.writeln('    <description>${_esc(wp.description)}</description>');
      buf.writeln('    <Point><coordinates>${wp.longitude},${wp.latitude},0</coordinates></Point>');
      buf.writeln('  </Placemark>');
    }
    buf.writeln('</Document>');
    buf.writeln('</kml>');

    final path = await _exportPath('${_safeName(trip.name)}.kml');
    await File(path).writeAsString(buf.toString());
    return path;
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static Future<String> _exportPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);
    return p.join(exportDir.path, filename);
  }

  static String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^\w\u0600-\u06FF\s]'), '_').trim();
}
