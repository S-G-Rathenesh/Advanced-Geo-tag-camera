import 'package:sqflite/sqflite.dart';

import '../../models/evidence_record.dart';
import '../../models/sync_status.dart';
import '../constants/app_constants.dart';
import 'local_database.dart';

/// Data Access Object for offline evidence queue CRUD operations.
class EvidenceQueueDao {
  /// Insert a new evidence record into the queue.
  Future<void> insert(EvidenceRecord record) async {
    final db = await LocalDatabase.database;
    await db.insert(
      AppConstants.evidenceTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all evidence records, optionally filtered by [status].
  Future<List<EvidenceRecord>> getAll({SyncStatus? status}) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps;

    if (status != null) {
      maps = await db.query(
        AppConstants.evidenceTable,
        where: 'syncStatus = ?',
        whereArgs: [status.name],
        orderBy: 'createdAt DESC',
      );
    } else {
      maps = await db.query(
        AppConstants.evidenceTable,
        orderBy: 'createdAt DESC',
      );
    }

    return maps.map((m) => EvidenceRecord.fromMap(m)).toList();
  }

  /// Get a single evidence record by [captureId].
  Future<EvidenceRecord?> getById(String captureId) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      AppConstants.evidenceTable,
      where: 'captureId = ?',
      whereArgs: [captureId],
    );

    if (maps.isEmpty) return null;
    return EvidenceRecord.fromMap(maps.first);
  }

  /// Update the sync status of a record.
  Future<void> updateSyncStatus(
      String captureId, SyncStatus status) async {
    final db = await LocalDatabase.database;
    await db.update(
      AppConstants.evidenceTable,
      {
        'syncStatus': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'captureId = ?',
      whereArgs: [captureId],
    );
  }

  /// Increment retry count for failed syncs.
  Future<void> incrementRetryCount(String captureId) async {
    final db = await LocalDatabase.database;
    await db.rawUpdate('''
      UPDATE ${AppConstants.evidenceTable}
      SET retryCount = retryCount + 1, updatedAt = ?
      WHERE captureId = ?
    ''', [DateTime.now().toIso8601String(), captureId]);
  }

  /// Delete a record (after successful server sync).
  Future<void> delete(String captureId) async {
    final db = await LocalDatabase.database;
    await db.delete(
      AppConstants.evidenceTable,
      where: 'captureId = ?',
      whereArgs: [captureId],
    );
  }

  /// Count records by sync status.
  Future<Map<SyncStatus, int>> getCounts() async {
    final db = await LocalDatabase.database;
    final counts = <SyncStatus, int>{};

    for (final status in SyncStatus.values) {
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM ${AppConstants.evidenceTable}
        WHERE syncStatus = ?
      ''', [status.name]);
      counts[status] = Sqflite.firstIntValue(result) ?? 0;
    }

    return counts;
  }

  /// Get all pending records that haven't exceeded max retries.
  Future<List<EvidenceRecord>> getPendingForSync() async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      AppConstants.evidenceTable,
      where: 'syncStatus IN (?, ?) AND retryCount < ?',
      whereArgs: [
        SyncStatus.pending.name,
        SyncStatus.failed.name,
        AppConstants.maxSyncRetries,
      ],
      orderBy: 'createdAt ASC',
    );

    return maps.map((m) => EvidenceRecord.fromMap(m)).toList();
  }
}
