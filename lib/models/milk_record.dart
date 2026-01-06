// lib/models/milk_record.dart
import 'package:intl/intl.dart';

class MilkRecord {
  final DateTime milkingDate;
  final double morningQuantity;
  final double eveningQuantity;
  final double total;
  final double used;
  final String? notes;
  final String milkType;

  MilkRecord({
    required this.milkingDate,
    required this.morningQuantity,
    required this.eveningQuantity,
    required this.total,
    required this.used,
    this.notes,
    required this.milkType,
  });

  // Factory constructor for creating from UI data
  factory MilkRecord.fromUIMap(Map<String, dynamic> map) {
    // Parse milk type
    final milkType = map['milkType'] as String? ?? '- Select milk type -';
    
    // Parse quantities - accept various input formats
    double parseQuantity(dynamic value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        return 0.0;
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else if (value is num) {
        return value.toDouble();
      } else {
        return 0.0;
      }
    }

    final morningQuantity = parseQuantity(map['morningQuantity']);
    final eveningQuantity = parseQuantity(map['eveningQuantity']);
    final total = parseQuantity(map['total'] ?? (morningQuantity + eveningQuantity));
    final used = parseQuantity(map['used']);

    // Parse date
    DateTime milkingDate;
    if (map['date'] is DateTime) {
      milkingDate = map['date'] as DateTime;
    } else if (map['date'] is String) {
      milkingDate = DateTime.parse(map['date'] as String);
    } else {
      milkingDate = DateTime.now();
    }

    return MilkRecord(
      milkingDate: milkingDate,
      morningQuantity: morningQuantity,
      eveningQuantity: eveningQuantity,
      total: total,
      used: used,
      notes: map['notes'] as String?,
      milkType: milkType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'milkingDate': milkingDate.toIso8601String(),
      'morningQuantity': morningQuantity,
      'eveningQuantity': eveningQuantity,
      'total': total,
      'used': used,
      'notes': notes,
      'milkType': milkType,
    };
  }

  factory MilkRecord.fromJson(Map<String, dynamic> json) {
    // Parse date
    DateTime milkingDate;
    if (json['milkingDate'] != null) {
      milkingDate = DateTime.parse(json['milkingDate'] as String);
    } else {
      milkingDate = DateTime.now();
    }

    // Parse quantities
    final morningQuantity = (json['morningQuantity'] as num?)?.toDouble() ?? 0.0;
    final eveningQuantity = (json['eveningQuantity'] as num?)?.toDouble() ?? 0.0;
    final total = (json['total'] as num?)?.toDouble() ?? (morningQuantity + eveningQuantity);
    final used = (json['used'] as num?)?.toDouble() ?? 0.0;

    // Parse milk type directly from JSON
    final milkType = json['milkType'] as String? ?? 'Individual Goat Milk';

    return MilkRecord(
      milkingDate: milkingDate,
      morningQuantity: morningQuantity,
      eveningQuantity: eveningQuantity,
      total: total,
      used: used,
      notes: json['notes'] as String?,
      milkType: milkType,
    );
  }

  // Helper getters
  double get available => total - used;
  String get formattedDate => DateFormat('yyyy-MM-dd').format(milkingDate);
  String get displayDate => DateFormat('MMM dd, yyyy').format(milkingDate);
}