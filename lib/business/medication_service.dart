import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../dao/medication_dao.dart';
import '../dao/dose_log_dao.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';

class MedicationService extends ChangeNotifier {
  final MedicationDao _medicationDao = MedicationDao();
  final DoseLogDao _doseLogDao = DoseLogDao();

  List<Medication> _medications = [];
  List<DoseLog> _logs = [];

  List<Medication> get medications => _medications;
  List<DoseLog> get logs => _logs;

  // Initialize and load data from SQLite
  Future<void> loadData() async {
    _medications = await _medicationDao.getAllMedications();
    _logs = await _doseLogDao.getAllLogs();
    notifyListeners();
  }

  // Add new medication
  Future<void> addMedication(Medication medication) async {
    await _medicationDao.insert(medication);
    await loadData();
  }

  // Update existing medication
  Future<void> updateMedication(Medication medication) async {
    await _medicationDao.update(medication);
    await loadData();
  }

  // Delete medication and its associated logs
  Future<void> deleteMedication(int id) async {
    await _medicationDao.delete(id);
    await _doseLogDao.deleteLogsForMedication(id);
    await loadData();
  }

  // Refill medication stock
  Future<void> refillStock(Medication medication, int amount) async {
    final updated = medication.copyWith(stockCount: medication.stockCount + amount);
    await _medicationDao.update(updated);
    await loadData();
  }

  // Mark a medication dose as TAKEN
  Future<void> markAsTaken(Medication medication, String scheduledTime, DateTime logTime) async {
    if (medication.id == null) return;

    // 1. Create a dose log
    final log = DoseLog(
      medicationId: medication.id!,
      medicationName: medication.name,
      dosage: medication.dosage,
      scheduledTime: scheduledTime,
      loggedDateTime: logTime,
      status: 'taken',
    );
    await _doseLogDao.insert(log);

    // 2. Decrement the inventory stock by 1
    await _medicationDao.decrementStock(medication.id!, 1);

    // 3. Reload lists and trigger UI rebuild
    await loadData();
  }

  // Mark a medication dose as SKIPPED
  Future<void> markAsSkipped(Medication medication, String scheduledTime, DateTime logTime) async {
    if (medication.id == null) return;

    // 1. Create a dose log
    final log = DoseLog(
      medicationId: medication.id!,
      medicationName: medication.name,
      dosage: medication.dosage,
      scheduledTime: scheduledTime,
      loggedDateTime: logTime,
      status: 'skipped',
    );
    await _doseLogDao.insert(log);

    // 2. Reload lists and trigger UI rebuild
    await loadData();
  }

  // Clear all log history (Admin/Setting helper)
  Future<void> clearHistory() async {
    await _doseLogDao.deleteAllLogs();
    await loadData();
  }

  // Helper: Get list of active medications scheduled for a specific date
  List<Medication> getMedicationsForDate(DateTime date) {
    final weekdayName = DateFormat('EEEE').format(date); // e.g. 'Monday'
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final daysSinceEpoch = date.difference(epoch).inDays;

    return _medications.where((med) {
      if (!med.isActive) return false;

      switch (med.frequency) {
        case 'daily':
          return true;
        case 'alternate_days':
          // Scheduled every 2 days
          return daysSinceEpoch % 2 == 0;
        case 'specific_days':
          return med.specificDaysList.contains(weekdayName);
        default:
          return false;
      }
    }).toList();
  }

  // Helper: Get logs recorded on a specific date
  List<DoseLog> getLogsForDateList(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _logs.where((log) {
      final logDateStr = DateFormat('yyyy-MM-dd').format(log.loggedDateTime);
      return logDateStr == dateStr;
    }).toList();
  }

  // Helper: Get compliance/adherence statistics for the last N days
  // Returns a double between 0.0 and 1.0 (taken / total logs)
  double getComplianceRateForDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredLogs = _logs.where((log) => log.loggedDateTime.isAfter(cutoffDate)).toList();

    if (filteredLogs.isEmpty) return 1.0; // Assume 100% if no logs yet

    final takenCount = filteredLogs.where((log) => log.status == 'taken').length;
    return takenCount / filteredLogs.length;
  }
}
