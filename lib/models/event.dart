// lib/models/event.dart
class Event {
  final DateTime date;
  final String tagNo;
  final String eventType;
  final String? symptoms;
  final String? diagnosis;
  final String? technician;
  final String? medicine;
  final String? weighedResult;
  final String? otherName;
  final String? notes;
  final bool isMassEvent;

  Event({
    required this.date,
    required this.tagNo,
    required this.eventType,
    this.symptoms,
    this.diagnosis,
    this.technician,
    this.medicine,
    this.weighedResult,
    this.otherName,
    this.notes,
    this.isMassEvent = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'tagNo': tagNo,
        'eventType': eventType,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'technician': technician,
        'medicine': medicine,
        'weighedResult': weighedResult,
        'otherName': otherName,
        'notes': notes,
        'isMassEvent': isMassEvent,
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        date: DateTime.parse(json['date'] as String),
        tagNo: json['tagNo'] as String,
        eventType: json['eventType'] as String,
        symptoms: json['symptoms'] as String?,
        diagnosis: json['diagnosis'] as String?,
        technician: json['technician'] as String?,
        medicine: json['medicine'] as String?,
        weighedResult: json['weighedResult'] as String?,
        otherName: json['otherName'] as String?,
        notes: json['notes'] as String?,
        isMassEvent: json['isMassEvent'] as bool? ?? false,
      );
}