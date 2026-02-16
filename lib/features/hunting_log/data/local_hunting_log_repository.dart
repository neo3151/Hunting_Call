import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../domain/hunting_log_entry.dart';
import 'hunting_log_repository.dart';

class LocalHuntingLogRepository implements HuntingLogRepository {
  Database? _database;

  @override
  Future<void> initialize() async {
    if (_database != null) return; // Already initialized
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'hunting_logs.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE hunting_logs (id TEXT PRIMARY KEY, animalId TEXT, timestamp TEXT, latitude REAL, longitude REAL, notes TEXT, imagePath TEXT)',
        );
      },
    );
  }

  @override
  Future<List<HuntingLogEntry>> getLogs() async {
    final db = _database;
    if (db == null) throw Exception('Database not initialized');

    final List<Map<String, dynamic>> maps = await db.query('hunting_logs', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) {
      return HuntingLogEntry.fromMap(maps[i]);
    });
  }

  @override
  Future<void> addLog(HuntingLogEntry entry) async {
    final db = _database;
    if (db == null) throw Exception('Database not initialized');

    await db.insert(
      'hunting_logs',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteLog(String id) async {
    final db = _database;
    if (db == null) throw Exception('Database not initialized');

    await db.delete(
      'hunting_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
