import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/track_point.dart';
import '../models/trip.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  static Database? _db;

  DatabaseService._();

  Future<Database> get db async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<void> initialize() async {
    _db = await _openDb();
  }

  Future<Database> _openDb() async {
    final dbPath = p.join(await getDatabasesPath(), 'desert_track.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        total_distance REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE track_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL DEFAULT 0,
        speed REAL DEFAULT 0,
        bearing REAL DEFAULT 0,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE waypoints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        timestamp TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_track_points_trip ON track_points(trip_id)');
    await db.execute(
        'CREATE INDEX idx_waypoints_trip ON waypoints(trip_id)');
  }

  // ──────────── TRIPS ────────────

  Future<int> insertTrip(Trip trip) async {
    final database = await db;
    return database.insert('trips', trip.toMap());
  }

  Future<void> updateTrip(Trip trip) async {
    final database = await db;
    await database.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> deleteTrip(int tripId) async {
    final database = await db;
    await database.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }

  Future<List<Trip>> getAllTrips() async {
    final database = await db;
    final rows = await database.query(
      'trips',
      orderBy: 'start_time DESC',
    );
    return rows.map(Trip.fromMap).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final database = await db;
    final rows = await database.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final trip = Trip.fromMap(rows.first);
    final points = await getTrackPoints(id);
    final wps = await getWaypoints(id);
    return trip.copyWith(trackPoints: points, waypoints: wps);
  }

  Future<void> renameTrip(int id, String newName) async {
    final database = await db;
    await database.update(
      'trips',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ──────────── TRACK POINTS ────────────

  Future<void> insertTrackPoints(List<TrackPoint> points) async {
    if (points.isEmpty) return;
    final database = await db;
    final batch = database.batch();
    for (final point in points) {
      batch.insert('track_points', point.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertTrackPoint(TrackPoint point) async {
    final database = await db;
    await database.insert('track_points', point.toMap());
  }

  Future<List<TrackPoint>> getTrackPoints(int tripId) async {
    final database = await db;
    final rows = await database.query(
      'track_points',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(TrackPoint.fromMap).toList();
  }

  // ──────────── WAYPOINTS ────────────

  Future<int> insertWaypoint(Waypoint wp) async {
    final database = await db;
    return database.insert('waypoints', wp.toMap());
  }

  Future<void> deleteWaypoint(int id) async {
    final database = await db;
    await database.delete('waypoints', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Waypoint>> getWaypoints(int tripId) async {
    final database = await db;
    final rows = await database.query(
      'waypoints',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(Waypoint.fromMap).toList();
  }
}
