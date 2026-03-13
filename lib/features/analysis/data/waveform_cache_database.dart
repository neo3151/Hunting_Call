import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class WaveformCacheDatabase {
  static Database? _database;
  static const String tableName = 'waveform_cache';
  static const String metaTable = 'cache_meta';

  /// Bump this when the waveform normalization algorithm changes.
  /// Any cached data from a previous version will be purged on next open.
  static const int currentCacheVersion = 2;

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            waveform TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $metaTable (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.insert(metaTable, {'key': 'cache_version', 'value': '$currentCacheVersion'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $metaTable (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          // Purge stale data from v1 (old normalization)
          await db.delete(tableName);
          await db.insert(metaTable, {'key': 'cache_version', 'value': '$currentCacheVersion'},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      },
    );
  }

  /// Check if cached data was produced by a different algorithm version.
  /// If so, purge stale entries and update the stored version.
  Future<void> migrateIfNeeded() async {
    final db = await database;
    final rows = await db.query(metaTable, where: 'key = ?', whereArgs: ['cache_version']);
    final storedVersion = rows.isNotEmpty ? int.tryParse(rows.first['value'] as String) ?? 0 : 0;

    if (storedVersion < currentCacheVersion) {
      await db.delete(tableName);
      await db.insert(metaTable, {'key': 'cache_version', 'value': '$currentCacheVersion'},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
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
