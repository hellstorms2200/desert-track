import 'track_point.dart';

class Waypoint {
  final int? id;
  final int tripId;
  final double latitude;
  final double longitude;
  final String name;
  final String description;
  final DateTime timestamp;

  const Waypoint({
    this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.name,
    this.description = '',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'trip_id': tripId,
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Waypoint.fromMap(Map<String, dynamic> map) => Waypoint(
        id: map['id'] as int?,
        tripId: map['trip_id'] as int,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}

class Trip {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceMeters;
  final List<TrackPoint> trackPoints;
  final List<Waypoint> waypoints;

  const Trip({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.totalDistanceMeters = 0.0,
    this.trackPoints = const [],
    this.waypoints = const [],
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  double get avgSpeedKmh {
    final hours = duration.inSeconds / 3600.0;
    if (hours == 0) return 0.0;
    return totalDistanceKm / hours;
  }

  double get maxSpeedKmh {
    if (trackPoints.isEmpty) return 0.0;
    return trackPoints
        .map((p) => p.speedKmh)
        .reduce((a, b) => a > b ? a : b);
  }

  bool get isCompleted => endTime != null;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'total_distance': totalDistanceMeters,
      };

  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
        id: map['id'] as int?,
        name: map['name'] as String,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        totalDistanceMeters:
            (map['total_distance'] as num?)?.toDouble() ?? 0.0,
      );

  Trip copyWith({
    int? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistanceMeters,
    List<TrackPoint>? trackPoints,
    List<Waypoint>? waypoints,
  }) =>
      Trip(
        id: id ?? this.id,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        totalDistanceMeters:
            totalDistanceMeters ?? this.totalDistanceMeters,
        trackPoints: trackPoints ?? this.trackPoints,
        waypoints: waypoints ?? this.waypoints,
      );
}
