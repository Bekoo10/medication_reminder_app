import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../business/alarm_service.dart';
import '../business/medication_service.dart';


class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // We obtain instances via parameters or static instances in main. 
  // For simplicity, we will access them from the parent or global scope.
  // In our main.dart we will register them as globals or inherited widgets.
  // Let's assume we access them via global variables defined in main.dart:
  // `globalMedicationService` and `globalAlarmService`.
  // This is extremely simple, clean, and avoids dependencies.

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Import global services from main.dart
    final alarmService = _getAlarmService();
    final medService = _getMedicationService();

    final medication = alarmService.currentMedication;
    final scheduledTime = alarmService.currentScheduledTime ?? "";

    if (medication == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No active alarm ringing.", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text("Go Home"),
              )
            ],
          ),
        ),
      );
    }

    final Color pillColor = Color(int.parse(medication.colorHex));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark elegant background (Slate-900)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const Text(
                    "MEDICATION REMINDER",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Time to take your medicine!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Animated Pulsing Icon & Medication details
              Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: pillColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: pillColor.withOpacity(0.4),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pillColor.withOpacity(0.25),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(
                        _getPillIcon(medication.pillType),
                        size: 64,
                        color: pillColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    medication.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Dosage: ${medication.dosage}",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (medication.instructions.isNotEmpty && medication.instructions != 'No instruction') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        medication.instructions,
                        style: TextStyle(
                          color: pillColor.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    "Scheduled for $scheduledTime",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Column(
                children: [
                  // Take Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1), // Modern Indigo
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                      ),
                      onPressed: () async {
                        // Mark as taken in SQLite database and decrement stock
                        await medService.markAsTaken(medication, scheduledTime, DateTime.now());
                        // Stop the alarm audio and dismiss
                        await alarmService.dismissAlarm();
                        if (mounted) {
                          // Navigate back to Dashboard
                          context.go('/');
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "TAKE NOW",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Snooze & Skip row
                  Row(
                    children: [
                      // Snooze Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade700, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            onPressed: () async {
                              await alarmService.snoozeAlarm();
                              if (mounted) {
                                context.go('/');
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.snooze_rounded, color: Colors.grey.shade400, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "SNOOZE (5m)",
                                  style: TextStyle(
                                    color: Colors.grey.shade300,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Skip Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            onPressed: () async {
                              await medService.markAsSkipped(medication, scheduledTime, DateTime.now());
                              await alarmService.dismissAlarm();
                              if (mounted) {
                                context.go('/');
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, color: Colors.red.shade400, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "SKIP DOSE",
                                  style: TextStyle(
                                    color: Colors.red.shade300,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to resolve global alarm service instance
  AlarmService _getAlarmService() {
    return (context.findAncestorStateOfType<MainEntryState>()?.alarmService) ?? globalAlarmService;
  }

  // Helper function to resolve global medication service instance
  MedicationService _getMedicationService() {
    return (context.findAncestorStateOfType<MainEntryState>()?.medicationService) ?? globalMedicationService;
  }

  IconData _getPillIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pill':
        return Icons.circle_rounded;
      case 'capsule':
        return Icons.medication_rounded;
      case 'syrup':
        return Icons.water_drop_rounded;
      case 'injection':
        return Icons.colorize_rounded;
      case 'drops':
        return Icons.opacity_rounded;
      default:
        return Icons.medication_rounded;
    }
  }
}

// Public state helper interface for locating services up the tree if nested
abstract class MainEntryState<T extends StatefulWidget> extends State<T> {
  AlarmService get alarmService;
  MedicationService get medicationService;
}
