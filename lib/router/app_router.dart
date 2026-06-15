import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/medication.dart';
import '../ui/dashboard_screen.dart';
import '../ui/add_medication_screen.dart';
import '../ui/history_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/alarm_screen.dart';
import '../business/alarm_service.dart';
import '../business/medication_service.dart';
import '../main.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Main navigation holds Bottom Navigation Bar to switch tabs
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      // Add Medication Screen
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddMedicationScreen(),
      ),
      // Edit Medication Screen - accepts Medication object through extra parameters
      GoRoute(
        path: '/edit',
        builder: (context, state) {
          final medication = state.extra as Medication?;
          return AddMedicationScreen(medication: medication);
        },
      ),
      // Fullscreen Alarm Trigger Screen
      GoRoute(
        path: '/alarm',
        builder: (context, state) => const AlarmScreen(),
      ),
    ],
  );
}

// Shell/Container screen to hold bottom navigation bar switching between screens locally
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> implements MainEntryState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  AlarmService get alarmService => globalAlarmService;

  @override
  MedicationService get medicationService => globalMedicationService;

  bool _hasPushedAlarm = false;

  @override
  void initState() {
    super.initState();
    globalAlarmService.addListener(_onAlarmStateChanged);
  }

  @override
  void dispose() {
    globalAlarmService.removeListener(_onAlarmStateChanged);
    super.dispose();
  }

  void _onAlarmStateChanged() {
    if (globalAlarmService.isAlarmActive) {
      if (!_hasPushedAlarm) {
        _hasPushedAlarm = true;
        context.push('/alarm').then((_) {
          _hasPushedAlarm = false;
        });
      }
    } else {
      _hasPushedAlarm = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF6366F1), // Modern Indigo
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.today_rounded, size: 24),
                activeIcon: Icon(Icons.today_rounded, size: 26),
                label: 'Today',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded, size: 24),
                activeIcon: Icon(Icons.calendar_month_rounded, size: 26),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded, size: 24),
                activeIcon: Icon(Icons.settings_rounded, size: 26),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
