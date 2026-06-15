class DoseLog {
  final int? id;
  final int medicationId;
  final String medicationName;
  final String dosage;
  final String scheduledTime; // HH:mm format, e.g. '08:00'
  final DateTime loggedDateTime; // Exact time when action was taken
  final String status; // 'taken' or 'skipped'

  DoseLog({
    this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    required this.loggedDateTime,
    required this.status,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'dosage': dosage,
      'scheduledTime': scheduledTime,
      'loggedDateTime': loggedDateTime.toIso8601String(),
      'status': status,
    };
  }

  // Convert from Map for database
  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] as int?,
      medicationId: map['medicationId'] as int,
      medicationName: map['medicationName'] as String,
      dosage: map['dosage'] as String,
      scheduledTime: map['scheduledTime'] as String,
      loggedDateTime: DateTime.parse(map['loggedDateTime'] as String),
      status: map['status'] as String,
    );
  }
}
