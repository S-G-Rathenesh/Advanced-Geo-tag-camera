import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';

/// Initializes and provides access to the local SQLite database
/// used for the offline evidence queue.
class LocalDatabase {
  static Database? _database;

  /// Returns the singleton database instance, creating it on first call.
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.databaseName);

    return openDatabase(
      path,
      version: 3, // Incremented version to add gnssConstellations
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.evidenceTable} (
        captureId       TEXT PRIMARY KEY,
        userId          TEXT NOT NULL,
        deviceId        TEXT NOT NULL,
        imagePath       TEXT NOT NULL,
        encryptedPath   TEXT,
        latitude        REAL NOT NULL,
        longitude       REAL NOT NULL,
        altitude        REAL,
        accuracy        REAL NOT NULL,
        address         TEXT,
        timestamp       TEXT NOT NULL,
        sha256Hash      TEXT NOT NULL,
        syncStatus      TEXT NOT NULL DEFAULT 'pending',
        ivBase64        TEXT,
        retryCount      INTEGER NOT NULL DEFAULT 0,
        gnssConstellations TEXT,
        createdAt       TEXT NOT NULL,
        updatedAt       TEXT NOT NULL
      )
    ''');

    // Index for quick sync-status queries
    await db.execute('''
      CREATE INDEX idx_sync_status
      ON ${AppConstants.evidenceTable} (syncStatus)
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${AppConstants.evidenceTable} ADD COLUMN address TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE ${AppConstants.evidenceTable} ADD COLUMN gnssConstellations TEXT');
    }
  }

  /// Close the database (e.g. on app termination).
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
