import 'dart:convert';

class ArchivedGoat {
  final String tagNo;
  final String reason; // sold, dead, lost, other
  final DateTime archiveDate;
  final String? notes;
  final Map<String, dynamic> goatData; // Original goat data snapshot

  ArchivedGoat({
    required this.tagNo,
    required this.reason,
    required this.archiveDate,
    this.notes,
    required this.goatData,
  });

  Map<String, dynamic> toJson() => {
    'tagNo': tagNo,
    'reason': reason,
    'archiveDate': archiveDate.toIso8601String(),
    'notes': notes,
    'goatData': goatData,
  };

  factory ArchivedGoat.fromJson(Map<String, dynamic> json) => ArchivedGoat(
    tagNo: json['tagNo'] as String,
    reason: json['reason'] as String,
    archiveDate: DateTime.parse(json['archiveDate'] as String),
    notes: json['notes'] as String?,
    goatData: json['goatData'] as Map<String, dynamic>,
  );

  // Helper method to get display name
  String get displayName {
    final name = goatData['name'];
    return name != null ? '$tagNo - $name' : tagNo;
  }

  // Helper method to get breed
  String? get breed => goatData['breed'] as String?;

  // Helper method to get gender
  String get gender => goatData['gender'] as String;
}