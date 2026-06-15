import '../data/database_helper.dart';
import '../models/medication.dart';

class MedicationDao {
  final dbHelper = DatabaseHelper.instance;

  // Insert a new medication
  Future<int> insert(Medication medication) async {
    final db = await dbHelper.database;
    return await db.insert('medications', medication.toMap());
  }

  // Update an existing medication
  Future<int> update(Medication medication) async {
    final db = await dbHelper.database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  // Delete a medication
  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get a single medication by ID
  Future<Medication?> getMedication(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    }
    return null;
  }

  // Get all medications
  Future<List<Medication>> getAllMedications() async {
    final db = await dbHelper.database;
    final result = await db.query('medications', orderBy: 'id ASC');
    return result.map((json) => Medication.fromMap(json)).toList();
  }

  // Decrement stock count when a dose is marked as taken
  Future<int> decrementStock(int id, int amount) async {
    final medication = await getMedication(id);
    if (medication != null) {
      int newStock = medication.stockCount - amount;
      if (newStock < 0) newStock = 0;
      
      final updated = medication.copyWith(stockCount: newStock);
      return await update(updated);
    }
    return 0;
  }
}
