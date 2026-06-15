import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../business/medication_service.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import '../main.dart';
import 'alarm_screen.dart'; // To access the service accessor

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  late ScrollController _calendarScrollController;

  @override
  void initState() {
    super.initState();
    _calendarScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate(animate: false));
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate({bool animate = true}) {
    if (_calendarScrollController.hasClients) {
      final index = _selectedDate.day - 1;
      final offset = index * 62.0 - (MediaQuery.of(context).size.width / 2 - 41.0);
      final maxScroll = _calendarScrollController.position.maxScrollExtent;
      final targetOffset = offset.clamp(0.0, maxScroll);
      if (animate) {
        _calendarScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _calendarScrollController.jumpTo(targetOffset);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1), // Indigo
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final medService = _getMedicationService(context);

    // Listen to changes in the MedicationService using ListenableBuilder
    return ListenableBuilder(
      listenable: medService,
      builder: (context, _) {
        final medications = medService.getMedicationsForDate(_selectedDate);
        final logs = medService.getLogsForDateList(_selectedDate);

        // Map logs to scheduled times to check which doses are done
        final Map<String, DoseLog> completedDoses = {};
        for (var log in logs) {
          final key = "${log.medicationId}_${log.scheduledTime}";
          completedDoses[key] = log;
        }

        // Calculate progress metrics
        int totalScheduledDoses = 0;
        int takenDosesCount = 0;

        for (var med in medications) {
          totalScheduledDoses += med.timesList.length;
          for (var time in med.timesList) {
            final log = completedDoses["${med.id}_$time"];
            if (log != null && log.status == 'taken') {
              takenDosesCount++;
            }
          }
        }

        final double progress = totalScheduledDoses > 0 
            ? takenDosesCount / totalScheduledDoses 
            : 0.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // Modern Slate-50 background
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (AppName & Today's Summary)
                _buildHeader(takenDosesCount, totalScheduledDoses, progress),

                // Horizontal Date Selector
                _buildHorizontalCalendar(),

                // Main Content
                Expanded(
                  child: medications.isEmpty
                      ? _buildEmptyState()
                      : _buildMedicationList(medications, completedDoses, medService),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF6366F1), // Indigo
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => context.push('/add'),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int taken, int total, double progress) {
    final dateString = DateFormat('MMMM dd, yyyy').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isToday ? "Today" : DateFormat('EEEE').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF6366F1),
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Custom Ring Progress
          if (total > 0)
            Container(
              height: 60,
              width: 60,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                  Center(
                    child: Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final daysCount = DateTime(year, month + 1, 0).day;

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: daysCount,
        itemBuilder: (context, index) {
          final date = DateTime(year, month, index + 1);
          final isSelected = date.day == _selectedDate.day;
          final dayName = DateFormat('E').format(date)[0]; // e.g. 'M'
          final dayNum = DateFormat('d').format(date);
          final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
            },
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : (isToday ? const Color(0xFFEEF2F6) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.healing_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Healthy Day!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "No medications scheduled for this date. Tap '+' to schedule new reminders.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(
    List<Medication> medications,
    Map<String, DoseLog> completedDoses,
    MedicationService medService,
  ) {
    // We flatten the list since a medication can be taken multiple times a day
    final List<Map<String, dynamic>> scheduledDoseItems = [];

    for (var med in medications) {
      for (var time in med.timesList) {
        scheduledDoseItems.add({
          'medication': med,
          'time': time,
        });
      }
    }

    // Sort by scheduled time chronologically
    scheduledDoseItems.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: scheduledDoseItems.length,
      itemBuilder: (context, index) {
        final item = scheduledDoseItems[index];
        final Medication med = item['medication'];
        final String time = item['time'];
        
        final logKey = "${med.id}_$time";
        final DoseLog? log = completedDoses[logKey];
        final String status = log?.status ?? 'pending';

        return _buildPillCard(med, time, status, medService);
      },
    );
  }

  Widget _buildPillCard(Medication med, String time, String status, MedicationService service) {
    final Color pillColor = Color(int.parse(med.colorHex));
    final isTaken = status == 'taken';
    final isSkipped = status == 'skipped';
    
    final isLowStock = med.stockCount <= med.lowStockThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isTaken
              ? Colors.green.withOpacity(0.25)
              : (isSkipped ? Colors.red.withOpacity(0.25) : Colors.transparent),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to Edit Medication Screen
            context.push('/edit', extra: med);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Pill Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pillColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getPillIcon(med.pillType),
                    color: pillColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (med.instructions.isNotEmpty && med.instructions != 'No instruction')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                med.instructions,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${med.dosage} • ${med.frequency == 'specific_days' ? 'Weekly' : med.frequency}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      // Stock warning
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 12,
                            color: isLowStock ? Colors.orange : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Stock: ${med.stockCount}",
                            style: TextStyle(
                              fontSize: 11,
                              color: isLowStock ? Colors.orange.shade700 : Colors.grey.shade500,
                              fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "REFILL",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Quick actions
                _buildActionButtons(med, time, status, service),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Medication med, String time, String status, MedicationService service) {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (status == 'taken') {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
      );
    }

    if (status == 'skipped') {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
      );
    }

    // Quick Action buttons only show up for today's pending medication
    if (isToday) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skip Button
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: Colors.red.shade300, size: 26),
            onPressed: () async {
              await service.markAsSkipped(med, time, DateTime.now());
            },
          ),
          // Take Button
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
            onPressed: () async {
              await service.markAsTaken(med, time, DateTime.now());
            },
          ),
        ],
      );
    }

    return Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400);
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

  MedicationService _getMedicationService(BuildContext context) {
    final mainEntryState = context.findAncestorStateOfType<MainEntryState>();
    if (mainEntryState != null) {
      return mainEntryState.medicationService;
    }
    return globalMedicationService;
  }
}
