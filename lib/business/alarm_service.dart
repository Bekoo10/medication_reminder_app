import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import 'medication_service.dart';

class AlarmService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  
  bool _isAlarmActive = false;
  Medication? _currentMedication;
  String? _currentScheduledTime;

  bool get isAlarmActive => _isAlarmActive;
  Medication? get currentMedication => _currentMedication;
  String? get currentScheduledTime => _currentScheduledTime;

  // Set to store already triggered alarms for today to avoid multiple triggers in the same minute
  // Format: "medicationId_time_date" (e.g. "3_08:00_2026-06-10")
  final Set<String> _triggeredAlarms = {};

  // List of active snoozed alarms
  // Key: DateTime when it should fire, Value: Map of medication and time
  final List<Map<String, dynamic>> _snoozedAlarms = [];

  AlarmService() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // Start checking for alarms periodically
  void startAlarmCheck(MedicationService medicationService) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkSchedule(medicationService);
    });
  }

  // Stop alarm checks (usually when app closes)
  void stopAlarmCheck() {
    _timer?.cancel();
    _audioPlayer.dispose();
  }

  // Check current time against medication schedules and snoozed alarms
  void _checkSchedule(MedicationService medService) {
    if (_isAlarmActive) return; // Don't trigger another alarm if one is already ringing

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentTimeStr = DateFormat('HH:mm').format(now);

    // 1. Check Snoozed Alarms first
    for (int i = _snoozedAlarms.length - 1; i >= 0; i--) {
      final snoozeTime = _snoozedAlarms[i]['triggerTime'] as DateTime;
      if (now.isAfter(snoozeTime) || now.isAtSameMomentAs(snoozeTime)) {
        final med = _snoozedAlarms[i]['medication'] as Medication;
        final schedTime = _snoozedAlarms[i]['time'] as String;
        _snoozedAlarms.removeAt(i);
        triggerAlarm(med, schedTime);
        return;
      }
    }

    // 2. Check Daily Medications Schedule
    final medicationsForToday = medService.getMedicationsForDate(now);
    for (var med in medicationsForToday) {
      if (med.id == null) continue;
      
      for (var time in med.timesList) {
        if (time == currentTimeStr) {
          final alarmKey = "${med.id}_${time}_$todayStr";
          
          if (!_triggeredAlarms.contains(alarmKey)) {
            _triggeredAlarms.add(alarmKey);
            triggerAlarm(med, time);
            return; // Trigger one alarm at a time
          }
        }
      }
    }
  }

  // Explicitly trigger the alarm
  Future<void> triggerAlarm(Medication medication, String scheduledTime) async {
    _isAlarmActive = true;
    _currentMedication = medication;
    _currentScheduledTime = scheduledTime;
    notifyListeners();

    try {
      // Plays assets/audio/alarm.mp3
      // AssetSource searches inside pubspec-defined assets. In our case, 'audio/alarm.mp3'.
      await _audioPlayer.play(AssetSource('audio/alarm.mp3'));
    } catch (e) {
      debugPrint("Error playing alarm sound: $e");
    }
  }

  // Trigger a test alarm immediately
  Future<void> triggerTestAlarm() async {
    final testMed = Medication(
      id: 999,
      name: "Test Medication",
      dosage: "1 Pill",
      frequency: "daily",
      times: "12:00",
      pillType: "capsule",
      colorHex: "0xFF2196F3",
      instructions: "With water",
      stockCount: 10,
      lowStockThreshold: 3,
    );
    await triggerAlarm(testMed, "12:00");
  }

  // Dismiss/Stop the alarm
  Future<void> dismissAlarm() async {
    _isAlarmActive = false;
    _currentMedication = null;
    _currentScheduledTime = null;
    notifyListeners();
    await _audioPlayer.stop();
  }

  // Snooze the alarm for 5 minutes
  Future<void> snoozeAlarm() async {
    if (_currentMedication == null || _currentScheduledTime == null) return;

    final triggerTime = DateTime.now().add(const Duration(minutes: 5));
    _snoozedAlarms.add({
      'triggerTime': triggerTime,
      'medication': _currentMedication!,
      'time': _currentScheduledTime!,
    });

    await dismissAlarm();
  }
}
