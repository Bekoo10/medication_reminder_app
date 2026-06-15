import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/medication.dart';
import '../business/medication_service.dart';
import '../main.dart';
import 'alarm_screen.dart'; // Access global service fallbacks

class AddMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;

  String _frequency = 'daily';
  final List<String> _selectedDays = [];
  final List<String> _times = [];
  String _pillType = 'capsule';
  String _colorHex = '0xFF6366F1'; // Default Indigo
  String _instructions = 'No instruction';
  bool _isActive = true;

  // Available options
  final List<Map<String, dynamic>> _pillTypes = [
    {'type': 'pill', 'icon': Icons.circle_rounded, 'label': 'Pill'},
    {'type': 'capsule', 'icon': Icons.medication_rounded, 'label': 'Capsule'},
    {'type': 'syrup', 'icon': Icons.water_drop_rounded, 'label': 'Syrup'},
    {'type': 'injection', 'icon': Icons.colorize_rounded, 'label': 'Injection'},
    {'type': 'drops', 'icon': Icons.opacity_rounded, 'label': 'Drops'},
  ];

  final List<String> _colors = [
    '0xFF6366F1', // Indigo
    '0xFFEF4444', // Red
    '0xFF10B981', // Emerald Green
    '0xFFF59E0B', // Amber Orange
    '0xFF3B82F6', // Blue
    '0xFFEC4899', // Pink
  ];

  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  final List<String> _instructionOptions = [
    'Before food', 'After food', 'With food', 'No instruction'
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.medication;

    _nameController = TextEditingController(text: med?.name ?? '');
    _dosageController = TextEditingController(text: med?.dosage ?? '1 Pill');
    _stockController = TextEditingController(text: med?.stockCount.toString() ?? '30');
    _thresholdController = TextEditingController(text: med?.lowStockThreshold.toString() ?? '5');

    if (med != null) {
      _frequency = med.frequency;
      if (med.specificDays != null) {
        _selectedDays.addAll(med.specificDaysList);
      }
      _times.addAll(med.timesList);
      _pillType = med.pillType;
      _colorHex = med.colorHex;
      _instructions = med.instructions;
      _isActive = med.isActive;
    } else {
      // Default initial time
      _times.add('08:00');
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.medication != null;
    final medService = _getMedicationService(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditMode ? "Edit Medication" : "Add Medication",
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Pill Name and Dosage
                _buildCardSection(
                  title: "Medication Info",
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: _buildInputDecoration("Medication Name", Icons.badge_outlined),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? "Name cannot be empty" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dosageController,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: _buildInputDecoration("Dosage (e.g. 500mg, 1 tablet)", Icons.medication_liquid_rounded),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? "Dosage cannot be empty" : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Pill Type selector
                _buildCardSection(
                  title: "Pill Type",
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pillTypes.length,
                      itemBuilder: (context, index) {
                        final type = _pillTypes[index];
                        final isSelected = _pillType == type['type'];
                        final Color activeColor = Color(int.parse(_colorHex));

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _pillType = type['type'];
                            });
                          },
                          child: Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor.withOpacity(0.12) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? activeColor : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type['icon'],
                                  color: isSelected ? activeColor : Colors.grey.shade400,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type['label'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? activeColor : Colors.grey.shade500,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Color Theme Selector
                _buildCardSection(
                  title: "Card Theme Color",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colors.map((hexStr) {
                      final isSelected = _colorHex == hexStr;
                      final Color color = Color(int.parse(hexStr));

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _colorHex = hexStr;
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.grey.shade800 : Colors.transparent,
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Frequency & Days select
                _buildCardSection(
                  title: "Frequency",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _frequency,
                        decoration: _buildInputDecoration("Repeat frequency", Icons.cached_rounded),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily (Every day)')),
                          DropdownMenuItem(value: 'alternate_days', child: Text('Alternate Days (Every 2 days)')),
                          DropdownMenuItem(value: 'specific_days', child: Text('Specific Days of Week')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _frequency = val;
                            });
                          }
                        },
                      ),
                      
                      // Specific Weekdays multi-select chips
                      if (_frequency == 'specific_days') ...[
                        const SizedBox(height: 16),
                        const Text(
                          "Select Days",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _weekdays.map((day) {
                            final isSelected = _selectedDays.contains(day);
                            final Color activeColor = Color(int.parse(_colorHex));

                            return ChoiceChip(
                              label: Text(
                                day.substring(0, 3),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: activeColor,
                              backgroundColor: Colors.white,
                              disabledColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDays.add(day);
                                  } else {
                                    _selectedDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Times List (multi-time select)
                _buildCardSection(
                  title: "Reminder Times",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _times.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.alarm_rounded, color: Color(0xFF6366F1), size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _times[index],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_calendar_rounded, color: Colors.blue),
                                      onPressed: () => _pickTime(index),
                                    ),
                                    if (_times.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _times.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _pickTime(null),
                        style: TextButton.styleFrom(
                          foregroundColor: Color(int.parse(_colorHex)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_alarm_rounded),
                        label: const Text("Add Another Time", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Food Instructions
                _buildCardSection(
                  title: "Instructions",
                  child: DropdownButtonFormField<String>(
                    value: _instructions,
                    decoration: _buildInputDecoration("Food instructions", Icons.restaurant_rounded),
                    items: _instructionOptions.map((opt) {
                      return DropdownMenuItem(value: opt, child: Text(opt));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _instructions = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Stock Count & Warnings
                _buildCardSection(
                  title: "Inventory Stock Tracking",
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: _buildInputDecoration("Total Pills", Icons.inventory_2_outlined),
                          validator: (value) =>
                              value == null || int.tryParse(value) == null ? "Enter valid stock" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _thresholdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: _buildInputDecoration("Low Limit", Icons.warning_amber_rounded),
                          validator: (value) =>
                              value == null || int.tryParse(value) == null ? "Enter valid limit" : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 8. Medication Status (Active/Inactive Toggle)
                _buildCardSection(
                  title: "Medication Status",
                  child: SwitchListTile(
                    title: const Text(
                      "Active Status",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: const Text("Receive reminder notifications for this medication"),
                    value: _isActive,
                    activeColor: Color(int.parse(_colorHex)),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(int.parse(_colorHex)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                      shadowColor: Color(int.parse(_colorHex)).withOpacity(0.4),
                    ),
                    onPressed: () => _saveMedication(medService),
                    child: Text(
                      isEditMode ? "UPDATE MEDICATION" : "SAVE MEDICATION",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),

                // Delete button (Only for Edit Mode)
                if (isEditMode) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.08),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () => _deleteMedication(medService),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text(
                        "DELETE MEDICATION",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      labelStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 14),
      floatingLabelStyle: TextStyle(color: Color(int.parse(_colorHex)), fontWeight: FontWeight.bold),
      fillColor: const Color(0xFFF8FAFC),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(int.parse(_colorHex)), width: 1.5),
      ),
    );
  }

  Future<void> _pickTime(int? index) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
    
    if (index != null) {
      final parts = _times[index].split(':');
      initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(int.parse(_colorHex)),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      final timeStr = "$hourStr:$minStr";

      setState(() {
        if (index != null) {
          _times[index] = timeStr;
        } else {
          // Avoid duplicate times
          if (!_times.contains(timeStr)) {
            _times.add(timeStr);
          }
        }
      });
    }
  }

  Future<void> _saveMedication(MedicationService service) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one reminder time."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_frequency == 'specific_days' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one day of the week."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Sort times chronologically
    _times.sort();

    final isEditMode = widget.medication != null;

    final newMed = Medication(
      id: widget.medication?.id,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      specificDays: _frequency == 'specific_days' ? _selectedDays.join(',') : null,
      times: _times.join(','),
      pillType: _pillType,
      colorHex: _colorHex,
      instructions: _instructions,
      stockCount: int.parse(_stockController.text),
      lowStockThreshold: int.parse(_thresholdController.text),
      isActive: _isActive,
    );

    try {
      if (isEditMode) {
        await service.updateMedication(newMed);
      } else {
        await service.addMedication(newMed);
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving medication: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteMedication(MedicationService service) async {
    final med = widget.medication;
    if (med?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Medication?"),
        content: Text("Are you sure you want to delete '${med!.name}'? This will also delete all of its historical dose logs."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.deleteMedication(med!.id!);
      if (mounted) {
        context.pop(); // Close AddMedicationScreen
      }
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
