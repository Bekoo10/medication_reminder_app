import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

abstract class DatabaseWrapper {
  Future<int> insert(String table, Map<String, dynamic> values);
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs});
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});
  Future<List<Map<String, Object?>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy});
  Future<void> close();
}

class SqfliteDatabaseWrapper implements DatabaseWrapper {
  final sqflite.Database db;
  SqfliteDatabaseWrapper(this.db);

  @override
  Future<int> insert(String table, Map<String, dynamic> values) => db.insert(table, values);

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) =>
      db.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      db.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<List<Map<String, Object?>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) =>
      db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);

  @override
  Future<void> close() => db.close();
}

class PreferencesDatabaseWrapper implements DatabaseWrapper {
  late SharedPreferences _prefs;
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTable('medications');
    _loadTable('dose_logs');
  }

  void _loadTable(String name) {
    final key = 'db_table_$name';
    final jsonStr = _prefs.getString(key);
    if (jsonStr != null) {
      try {
        final decoded = json.decode(jsonStr) as List;
        _tables[name] = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        _tables[name] = [];
      }
    } else {
      _tables[name] = [];
    }
  }

  Future<void> _saveTable(String name) async {
    final key = 'db_table_$name';
    final jsonStr = json.encode(_tables[name]);
    await _prefs.setString(key, jsonStr);
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final list = _tables[table] ?? [];
    int maxId = 0;
    for (final row in list) {
      final id = row['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    final newId = maxId + 1;
    final rowMap = Map<String, dynamic>.from(values);
    rowMap['id'] = newId;
    list.add(rowMap);
    _tables[table] = list;
    await _saveTable(table);
    return newId;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    final list = _tables[table] ?? [];
    int count = 0;
    for (int i = 0; i < list.length; i++) {
      if (_matchRow(list[i], where, whereArgs)) {
        final updatedRow = Map<String, dynamic>.from(list[i]);
        values.forEach((key, value) {
          if (key != 'id') {
            updatedRow[key] = value;
          }
        });
        list[i] = updatedRow;
        count++;
      }
    }
    if (count > 0) {
      await _saveTable(table);
    }
    return count;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = _tables[table] ?? [];
    final originalLength = list.length;
    list.removeWhere((row) => _matchRow(row, where, whereArgs));
    final count = originalLength - list.length;
    if (count > 0) {
      await _saveTable(table);
    }
    return count;
  }

  @override
  Future<List<Map<String, Object?>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final list = _tables[table] ?? [];
    final matched = list.where((row) => _matchRow(row, where, whereArgs)).map((row) => Map<String, Object?>.from(row)).toList();
    _sortRows(matched, orderBy);
    return matched;
  }

  @override
  Future<void> close() async {}

  bool _matchRow(Map<String, dynamic> row, String? where, List<Object?>? whereArgs) {
    if (where == null) return true;
    if (whereArgs == null || whereArgs.isEmpty) return true;

    final cleanWhere = where.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanWhere == 'id = ?') {
      return row['id'] == whereArgs[0];
    }
    if (cleanWhere == 'medicationId = ?') {
      return row['medicationId'] == whereArgs[0];
    }
    if (cleanWhere == 'loggedDateTime LIKE ?') {
      final pattern = whereArgs[0] as String;
      final value = row['loggedDateTime'] as String? ?? '';
      if (pattern.endsWith('%')) {
        final prefix = pattern.substring(0, pattern.length - 1);
        return value.startsWith(prefix);
      }
      return value == pattern;
    }

    return true;
  }

  void _sortRows(List<Map<String, dynamic>> rows, String? orderBy) {
    if (orderBy == null) return;
    final parts = orderBy.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;

    final field = parts[0];
    final isDesc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';

    rows.sort((a, b) {
      final valA = a[field];
      final valB = b[field];

      if (valA == null && valB == null) return 0;
      if (valA == null) return isDesc ? 1 : -1;
      if (valB == null) return isDesc ? -1 : 1;

      int cmp;
      if (valA is Comparable && valB is Comparable) {
        cmp = valA.compareTo(valB);
      } else {
        cmp = valA.toString().compareTo(valB.toString());
      }
      return isDesc ? -cmp : cmp;
    });
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static DatabaseWrapper? _database;

  DatabaseHelper._init();

  Future<DatabaseWrapper> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medication_reminder.db');
    return _database!;
  }

  Future<DatabaseWrapper> _initDB(String filePath) async {
    if (kIsWeb) {
      debugPrint("DatabaseHelper: Running on web. Initializing PreferencesDatabaseWrapper.");
      final wrapper = PreferencesDatabaseWrapper();
      await wrapper.init();
      return wrapper;
    }

    try {
      final dbPath = await sqflite.getDatabasesPath();
      final path = p.join(dbPath, filePath);

      final db = await sqflite.openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
      debugPrint("DatabaseHelper: Successfully opened sqflite database.");
      return SqfliteDatabaseWrapper(db);
    } catch (e) {
      debugPrint("DatabaseHelper Error opening sqflite database: $e. Falling back to PreferencesDatabaseWrapper.");
      final wrapper = PreferencesDatabaseWrapper();
      await wrapper.init();
      return wrapper;
    }
  }

  Future _createDB(sqflite.Database db, int version) async {
    // Create medications table
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        specificDays TEXT,
        times TEXT NOT NULL,
        pillType TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        instructions TEXT NOT NULL,
        stockCount INTEGER NOT NULL,
        lowStockThreshold INTEGER NOT NULL,
        isActive INTEGER NOT NULL
      )
    ''');

    // Create dose_logs table
    await db.execute('''
      CREATE TABLE dose_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        medicationName TEXT NOT NULL,
        dosage TEXT NOT NULL,
        scheduledTime TEXT NOT NULL,
        loggedDateTime TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}
