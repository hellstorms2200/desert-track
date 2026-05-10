class TrackPoint {
  final int? id;
  final int tripId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final DateTime timestamp;

  TrackPoint({
    this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speed = 0.0,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tripId': tripId,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'speed': speed,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TrackPoint.fromMap(Map<String, dynamic> map) => TrackPoint(
    id: map['id'],
    tripId: map['tripId'],
    latitude: map['latitude'],
    longitude: map['longitude'],
    altitude: map['altitude'] ?? 0.0,
    speed: map['speed'] ?? 0.0,
    timestamp: DateTime.parse(map['timestamp']),
  );
}
