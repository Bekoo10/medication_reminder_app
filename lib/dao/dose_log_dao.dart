import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../models/dose_log.dart';

class DoseLogDao {
  final dbHelper = DatabaseHelper.instance;

  // Insert a new log entry
  Future<int> insert(DoseLog log) async {
    final db = await dbHelper.database;
    return await db.insert('dose_logs', log.toMap());
  }

  // Get all logs
  Future<List<DoseLog>> getAllLogs() async {
    final db = await dbHelper.database;
    final result = await db.query('dose_logs', orderBy: 'loggedDateTime DESC');
    return result.map((json) => DoseLog.fromMap(json)).toList();
  }

  // Get logs filtered by date (e.g. '2026-06-10')
  Future<List<DoseLog>> getLogsForDate(DateTime date) async {
    final db = await dbHelper.database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    
    // We filter using LIKE for the ISO8601 string prefix
    final result = await db.query(
      'dose_logs',
      where: 'loggedDateTime LIKE ?',
      whereArgs: ['$dateString%'],
      orderBy: 'loggedDateTime ASC',
    );
    
    return result.map((json) => DoseLog.fromMap(json)).toList();
  }

  // Get logs for a specific medication
  Future<List<DoseLog>> getLogsForMedication(int medicationId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'dose_logs',
      where: 'medicationId = ?',
      whereArgs: [medicationId],
      orderBy: 'loggedDateTime DESC',
    );
    return result.map((json) => DoseLog.fromMap(json)).toList();
  }

  // Delete all logs for a specific medication (cascade delete helper)
  Future<int> deleteLogsForMedication(int medicationId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'dose_logs',
      where: 'medicationId = ?',
      whereArgs: [medicationId],
    );
  }

  // Clear all logs
  Future<int> deleteAllLogs() async {
    final db = await dbHelper.database;
    return await db.delete('dose_logs');
  }
}
