import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();
  Database? _db;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'desert_track.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            startTime TEXT NOT NULL,
            endTime TEXT,
            totalDistance REAL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insertTrip(Trip trip) async {
    return await _db!.insert('trips', trip.toMap());
  }

  Future<List<Trip>> getTrips() async {
    final maps = await _db!.query('trips', orderBy: 'startTime DESC');
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  Future<void> updateTrip(Trip trip) async {
    await _db!.update('trips', trip.toMap(),
        where: 'id = ?', whereArgs: [trip.id]);
  }

  Future<void> deleteTrip(int id) async {
    await _db!.delete('trips', where: 'id = ?', whereArgs: [id]);
  }
}
