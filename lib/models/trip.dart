class Trip {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<Map<String, double>> waypoints;
  final double totalDistance;

  Trip({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.waypoints = const [],
    this.totalDistance = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'totalDistance': totalDistance,
  };

  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
    id: map['id'],
    name: map['name'],
    startTime: DateTime.parse(map['startTime']),
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    totalDistance: map['totalDistance'] ?? 0.0,
  );
}
