class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String frequency; // 'daily', 'alternate_days', 'specific_days'
  final String? specificDays; // Comma-separated days of week: 'Monday,Wednesday,Friday'
  final String times; // Comma-separated times: '08:00,20:00'
  final String pillType; // 'pill', 'capsule', 'syrup', 'injection', 'drops'
  final String colorHex; // Hex color string: '0xFF4CAF50'
  final String instructions; // 'Before food', 'After food', 'With food', 'No instruction'
  final int stockCount;
  final int lowStockThreshold;
  final bool isActive;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.specificDays,
    required this.times,
    required this.pillType,
    required this.colorHex,
    required this.instructions,
    required this.stockCount,
    required this.lowStockThreshold,
    this.isActive = true,
  });

  // Convert a Medication object into a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'specificDays': specificDays,
      'times': times,
      'pillType': pillType,
      'colorHex': colorHex,
      'instructions': instructions,
      'stockCount': stockCount,
      'lowStockThreshold': lowStockThreshold,
      'isActive': isActive ? 1 : 0,
    };
  }

  // Convert a Map from SQLite into a Medication object
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      specificDays: map['specificDays'] as String?,
      times: map['times'] as String,
      pillType: map['pillType'] as String,
      colorHex: map['colorHex'] as String,
      instructions: map['instructions'] as String,
      stockCount: map['stockCount'] as int,
      lowStockThreshold: map['lowStockThreshold'] as int,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  // Helper: Get list of reminder times
  List<String> get timesList => times.split(',').where((t) => t.isNotEmpty).toList();

  // Helper: Get list of specific days
  List<String> get specificDaysList =>
      specificDays != null ? specificDays!.split(',').where((d) => d.isNotEmpty).toList() : [];

  // CopyWith helper to clone/update properties
  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    String? specificDays,
    String? times,
    String? pillType,
    String? colorHex,
    String? instructions,
    int? stockCount,
    int? lowStockThreshold,
    bool? isActive,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      specificDays: specificDays ?? this.specificDays,
      times: times ?? this.times,
      pillType: pillType ?? this.pillType,
      colorHex: colorHex ?? this.colorHex,
      instructions: instructions ?? this.instructions,
      stockCount: stockCount ?? this.stockCount,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
    );
  }
}
