import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:outcall/core/utils/app_logger.dart';

class OutboxEntry {
  final int? id;
  final String userId;
  final String audioPath;
  final String animalType;
  final int attemptCount;
  final int timestampMs;
  
  OutboxEntry({
    this.id,
    required this.userId,
    required this.audioPath,
    required this.animalType,
    this.attemptCount = 0,
    required this.timestampMs,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'audio_path': audioPath,
      'animal_type': animalType,
      'attempt_count': attemptCount,
      'timestamp_ms': timestampMs,
    };
  }

  factory OutboxEntry.fromMap(Map<String, dynamic> map) {
    return OutboxEntry(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      audioPath: map['audio_path'] as String,
      animalType: map['animal_type'] as String,
      attemptCount: map['attempt_count'] as int,
      timestampMs: map['timestamp_ms'] as int,
    );
  }
}

class SqliteOutboxRepository {
  static Database? _database;
  
  static const String tableName = 'outbox_calls';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'outcall_outbox.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            audio_path TEXT NOT NULL,
            animal_type TEXT NOT NULL,
            attempt_count INTEGER NOT NULL,
            timestamp_ms INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Add a failed call to the offline outbox
  Future<int> queueCall(String userId, String audioPath, String animalType) async {
    try {
      final db = await database;
      final entry = OutboxEntry(
        userId: userId,
        audioPath: audioPath,
        animalType: animalType,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
      final id = await db.insert(tableName, entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      AppLogger.d('SqliteOutboxRepository: Queued outbox call $id for $animalType');
      return id;
    } catch (e) {
      AppLogger.e('SqliteOutboxRepository: Failed to queue call', e, StackTrace.current);
      return -1;
    }
  }

  /// Retrieve all pending calls that haven't failed too many times
  Future<List<OutboxEntry>> getPendingCalls({int maxAttempts = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'attempt_count < ?',
      whereArgs: [maxAttempts],
      orderBy: 'timestamp_ms ASC',
    );
    return List.generate(maps.length, (i) => OutboxEntry.fromMap(maps[i]));
  }

  /// Increment the attempt counter for a specific entry
  Future<void> incrementAttempt(int id) async {
    final db = await database;
    await db.rawUpdate('UPDATE $tableName SET attempt_count = attempt_count + 1 WHERE id = ?', [id]);
  }

  /// Remove an entry after successful sync
  Future<void> removeCall(int id) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    AppLogger.d('SqliteOutboxRepository: Successfully removed synced call $id');
  }
}
