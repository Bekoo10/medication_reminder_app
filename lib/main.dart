import 'package:flutter/material.dart';
import 'business/alarm_service.dart';
import 'business/medication_service.dart';
import 'router/app_router.dart';

// Declare public global variables for state management and alarm checks
final MedicationService globalMedicationService = MedicationService();
final AlarmService globalAlarmService = AlarmService();

void main() async {
  // Ensure Flutter engine bindings are initialized before accessing databases
  WidgetsFlutterBinding.ensureInitialized();

  // Load medications and log records from the local SQLite database
  await globalMedicationService.loadData();

  // Start checking for scheduled medication alarms periodically
  globalAlarmService.startAlarmCheck(globalMedicationService);

  runApp(const MedicianApp());
}

class MedicianApp extends StatelessWidget {
  const MedicianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Medician Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo base
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6), // Purple Accent
          surface: Colors.white,
          error: const Color(0xFFEF4444),
        ),
        useMaterial3: true,
        // Configures clean typography across the app
        fontFamily: 'Outfit',
      ),
      routerConfig: AppRouter.router,
    );
  }
}
