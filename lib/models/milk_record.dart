// lib/models/milk_record.dart
import 'package:intl/intl.dart';

class MilkRecord {
  final DateTime milkingDate;
  final String tagNo;
  final double morningQuantity;
  final double eveningQuantity;
  final double total;
  final String? notes;
  final bool isWholeFarm;
  final String milkType;

  MilkRecord({
    required this.milkingDate,
    required this.tagNo,
    this.morningQuantity = 0.0,
    this.eveningQuantity = 0.0,
    this.total = 0.0,
    this.notes,
    this.isWholeFarm = false,
    required this.milkType,
  });

  // Factory constructor for creating from your UI data
  factory MilkRecord.fromUIMap(Map<String, dynamic> map) {
    final milkType = map['milkType'] as String? ?? '- Select milk type -';
    final total = (map['total'] is String) ? double.tryParse(map['total'] as String) ?? 0.0 : (map['total'] as num?)?.toDouble() ?? 0.0;
    final used = (map['used'] is String) ? double.tryParse(map['used'] as String) ?? 0.0 : (map['used'] as num?)?.toDouble() ?? 0.0;
    
    // For whole farm, tagNo should be 'FARM'
    final isWholeFarm = milkType == 'Whole Farm Milk';
    final tagNo = isWholeFarm ? 'FARM' : (map['tagNo'] as String? ?? 'UNKNOWN');
    
    // Parse date
    DateTime milkingDate;
    if (map['date'] is DateTime) {
      milkingDate = map['date'] as DateTime;
    } else if (map['date'] is String) {
      milkingDate = DateTime.parse(map['date'] as String);
    } else {
      milkingDate = DateTime.now();
    }
    
    // Split total into morning/evening (simple logic - can be adjusted)
    final morningQuantity = total * 0.6; // 60% morning
    final eveningQuantity = total * 0.4; // 40% evening
    
    return MilkRecord(
      milkingDate: milkingDate,
      tagNo: tagNo,
      morningQuantity: morningQuantity,
      eveningQuantity: eveningQuantity,
      total: total,
      notes: map['notes'] as String?,
      isWholeFarm: isWholeFarm,
      milkType: milkType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'milking_date': milkingDate.toIso8601String(),
      'date': milkingDate.toIso8601String(), // Keep both for compatibility
      'tag_no': tagNo,
      'tagNo': tagNo, // Keep both for compatibility
      'morning_quantity': morningQuantity,
      'evening_quantity': eveningQuantity,
      'total': total,
      'used': 0, // Not used in your current UI
      'notes': notes,
      'is_whole_farm': isWholeFarm,
      'isWholeFarm': isWholeFarm, // Keep both for compatibility
      'milk_type': milkType,
      'milkType': milkType, // Keep both for compatibility
    };
  }

  factory MilkRecord.fromJson(Map<String, dynamic> json) {
    // Parse date
    DateTime milkingDate;
    if (json['milking_date'] != null) {
      milkingDate = DateTime.parse(json['milking_date'] as String);
    } else if (json['date'] != null) {
      milkingDate = DateTime.parse(json['date'] as String);
    } else {
      milkingDate = DateTime.now();
    }
    
    // Parse quantities
    final morningQuantity = (json['morning_quantity'] as num?)?.toDouble() ?? 0.0;
    final eveningQuantity = (json['evening_quantity'] as num?)?.toDouble() ?? 0.0;
    final total = morningQuantity + eveningQuantity;
    
    // Determine milk type
    final bool isWholeFarm = json['is_whole_farm'] as bool? ?? json['isWholeFarm'] as bool? ?? false;
    final milkType = isWholeFarm ? 'Whole Farm Milk' : 'Individual Goat Milk';
    
    return MilkRecord(
      milkingDate: milkingDate,
      tagNo: json['tag_no'] as String? ?? json['tagNo'] as String? ?? 'UNKNOWN',
      morningQuantity: morningQuantity,
      eveningQuantity: eveningQuantity,
      total: total,
      notes: json['notes'] as String?,
      isWholeFarm: isWholeFarm,
      milkType: milkType,
    );
  }

  // Helper getters
  double get available => total; // In your UI, available = total - used
  String get formattedDate => DateFormat('yyyy-MM-dd').format(milkingDate);
  String get displayDate => DateFormat('MMM dd, yyyy').format(milkingDate);
}