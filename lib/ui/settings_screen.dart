import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../business/alarm_service.dart';
import '../business/medication_service.dart';
import '../main.dart';
import 'alarm_screen.dart'; // Access global service fallbacks

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarmService = _getAlarmService(context);
    final medService = _getMedicationService(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Settings",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Card
              _buildProfileCard(),
              const SizedBox(height: 24),

              // Alarm Section
              _buildSectionHeader("Alarm Operations"),
              const SizedBox(height: 8),
              _buildSettingsCard(
                children: [
                  _buildListTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: "Trigger Test Alarm",
                    subtitle: "Test the sound and alarm UI popup immediately",
                    onTap: () async {
                      // Trigger a test alarm in 1 second
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Launching test alarm in 2 seconds..."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      await Future.delayed(const Duration(seconds: 2));
                      await alarmService.triggerTestAlarm();
                      if (context.mounted) {
                        context.push('/alarm');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Data Management Section
              _buildSectionHeader("Data Management"),
              const SizedBox(height: 8),
              _buildSettingsCard(
                children: [
                  _buildListTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: Colors.red,
                    title: "Clear Dose History",
                    subtitle: "Wipe out all database log entries permanently",
                    onTap: () => _confirmClearHistory(context, medService),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader("About Application"),
              const SizedBox(height: 8),
              _buildSettingsCard(
                children: [
                  _buildAboutRow("App Name", "Medician Reminder"),
                  _buildAboutRow("Architecture", "Flutter + SQLite + GoRouter"),
                  _buildAboutRow("Version", "1.0.0 (Release-Build)"),
                  _buildAboutRow("Locale Language", "English (TR translations)"),
                ],
              ),
              const SizedBox(height: 40),

              // Bottom developer tag
              const Center(
                child: Text(
                  "Designed & Developed with Flutter 💙",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "BU",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // User text info
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Berke User",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Active Treatment Program",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context, MedicationService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear History Logs?"),
        content: const Text("Are you sure you want to delete all historical logs? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Wipe Logs", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dose history logs have been cleared successfully."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  AlarmService _getAlarmService(BuildContext context) {
    final mainEntryState = context.findAncestorStateOfType<MainEntryState>();
    if (mainEntryState != null) {
      return mainEntryState.alarmService;
    }
    return globalAlarmService;
  }

  MedicationService _getMedicationService(BuildContext context) {
    final mainEntryState = context.findAncestorStateOfType<MainEntryState>();
    if (mainEntryState != null) {
      return mainEntryState.medicationService;
    }
    return globalMedicationService;
  }
}
