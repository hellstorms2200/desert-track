class TrackPoint {
  final int? id;
  final int tripId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;    // m/s
  final double bearing;  // degrees 0–360
  final DateTime timestamp;

  const TrackPoint({
    this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.bearing = 0.0,
    required this.timestamp,
  });

  double get speedKmh => speed * 3.6;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'trip_id': tripId,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'speed': speed,
        'bearing': bearing,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TrackPoint.fromMap(Map<String, dynamic> map) => TrackPoint(
        id: map['id'] as int?,
        tripId: map['trip_id'] as int,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
        speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
        bearing: (map['bearing'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );

  TrackPoint copyWith({int? id, int? tripId}) => TrackPoint(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        speed: speed,
        bearing: bearing,
        timestamp: timestamp,
      );
}
