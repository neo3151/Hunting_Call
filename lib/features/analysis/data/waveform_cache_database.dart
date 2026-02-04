import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class WaveformCacheDatabase {
  static Database? _database;
  static const String tableName = 'waveform_cache';

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Initialize sqflite for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'waveform_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            waveform TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> cacheWaveform(String id, List<double> waveform) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        'id': id,
        'waveform': jsonEncode(waveform),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<double>?> getCachedWaveform(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final String waveformJson = maps.first['waveform'] as String;
    final List<dynamic> decoded = jsonDecode(waveformJson);
    return decoded.map((e) => (e as num).toDouble()).toList();
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete(tableName);
  }

  /// Clear cache entries older than the specified duration
  Future<int> clearOldCache({Duration maxAge = const Duration(days: 7)}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return await db.delete(
      tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffTime],
    );
  }

  /// Get the number of cached waveforms
  Future<int> getCacheCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get approximate cache size in bytes (rough estimate)
  Future<int> getApproximateCacheSize() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    int totalSize = 0;
    for (var map in maps) {
      final String waveformJson = map['waveform'] as String;
      totalSize += waveformJson.length;
    }
    return totalSize;
  }
}
