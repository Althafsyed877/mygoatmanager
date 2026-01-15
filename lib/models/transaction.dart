// lib/models/transaction.dart
import 'package:intl/intl.dart';

enum TransactionType {
  income,
  expense,
}

class Transaction {
  final int? id;
  final TransactionType type;
  final String? category;
  final String? subCategory;
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final String? contactName;
  final String? contactInfo;
  final String? notes;
  final String? receiptNumber;
  final double? quantity;
  final double? pricePerUnit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    required this.type,
    this.category,
    this.subCategory,
    required this.amount,
    this.description,
    required this.transactionDate,
    this.contactName,
    this.contactInfo,
    this.notes,
    this.receiptNumber,
    this.quantity,
    this.pricePerUnit,
    this.createdAt,
    this.updatedAt,
  });

  // Get display title
  String get displayTitle {
    if (subCategory != null) {
      return subCategory!;
    }
    if (category != null) {
      return category!;
    }
    return type == TransactionType.income ? 'Income' : 'Expense';
  }

  // Get formatted dates
  String get formattedDate => DateFormat('yyyy-MM-dd').format(transactionDate);
  String get displayDate => DateFormat('MMM dd, yyyy').format(transactionDate);
  
  // For backward compatibility
  String get formattedDateForBackend => transactionDate.toIso8601String().split('T')[0];

  // Get amount with sign
  double get signedAmount => type == TransactionType.income ? amount : -amount;

  // Factory constructor from JSON (API response)
  factory Transaction.fromJson(Map<String, dynamic> json) {
  // SIMPLIFIED VERSION - No boolean parsing
  String? typeStr;
  
  if (json['type'] != null) {
    typeStr = json['type'].toString();
  } else if (json['kind'] != null) {
    typeStr = json['kind'].toString();
  } else {
    typeStr = 'expense';
  }
  
  // Get amount as double
  double amount = 0.0;
  final amountValue = json['amount'];
  if (amountValue != null) {
    if (amountValue is int) {
      amount = amountValue.toDouble();
    } else if (amountValue is double) {
      amount = amountValue;
    } else if (amountValue is String) {
      amount = double.tryParse(amountValue) ?? 0.0;
    }
  }
  
  // Get date
  DateTime date;
  try {
    final dateStr = json['transaction_date'] ?? json['date'];
    if (dateStr is String) {
      date = DateTime.parse(dateStr);
    } else {
      date = DateTime.now();
    }
  } catch (e) {
    date = DateTime.now();
  }
  
  return Transaction(
    type: typeStr.toLowerCase() == 'income' ? TransactionType.income : TransactionType.expense,
    category: json['category']?.toString(),
    subCategory: json['sub_category']?.toString(),
    amount: amount,
    description: json['description']?.toString(),
    transactionDate: date,
    contactName: json['contact_name']?.toString(),
    contactInfo: json['contact_info']?.toString(),
    notes: json['notes']?.toString(),
    receiptNumber: json['receipt_number']?.toString(),
    quantity: json['quantity'] != null ? double.tryParse(json['quantity'].toString()) : null,
    pricePerUnit: json['price_per_unit'] != null ? double.tryParse(json['price_per_unit'].toString()) : null,
  );
}

  // Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type == TransactionType.income ? 'income' : 'expense',
      if (category != null) 'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      'amount': amount,
      if (description != null) 'description': description,
      'transaction_date': formattedDateForBackend,
      if (contactName != null) 'contact_name': contactName,
      if (contactInfo != null) 'contact_info': contactInfo,
      if (notes != null) 'notes': notes,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (quantity != null) 'quantity': quantity,
      if (pricePerUnit != null) 'price_per_unit': pricePerUnit,
    };
  }

  // Convert to old format for backward compatibility with sync
  Map<String, dynamic> toOldFormat() {
    if (type == TransactionType.income) {
      return {
        'kind': 'income',
        'date': transactionDate.toIso8601String(),
        'type': subCategory ?? category ?? 'Other',
        'category': category,
        'quantity': quantity,
        'price': pricePerUnit,
        'amount': amount.toString(),
        'receipt': receiptNumber,
        'notes': notes,
        'buyer_name': contactName,
        'buyer_contact': contactInfo,
      };
    } else {
      return {
        'kind': 'expense',
        'date': transactionDate.toIso8601String(),
        'type': subCategory ?? category ?? 'Other',
        'category': category,
        'quantity': quantity,
        'amount': amount.toString(),
        'receipt': receiptNumber,
        'notes': notes,
        'vendor_name': contactName,
        'vendor_contact': contactInfo,
      };
    }
  }

  // Factory constructor from UI data (your current map structure)
  factory Transaction.fromUIMap(Map<String, dynamic> map) {
    // Determine type
    final TransactionType transactionType = 
        map['kind'] == 'income' ? TransactionType.income : TransactionType.expense;
    
    // Parse date
    DateTime date;
    if (map['date'] is DateTime) {
      date = map['date'] as DateTime;
    } else if (map['date'] is String) {
      try {
        date = DateTime.parse(map['date'] as String);
      } catch (_) {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }
    
    // Parse amount
    final amount = double.tryParse((map['amount'] ?? '0').toString()) ?? 0.0;
    
    // Handle category and subCategory from UI
    String? category;
    String? subCategory;
    
    final typeValue = map['type'] as String?;
    if (transactionType == TransactionType.income) {
      if (typeValue == 'Milk Sale' || typeValue == 'Goat Sale' || 
          typeValue == 'Manure Sale' || typeValue == 'Category Income') {
        category = typeValue;
      } else {
        category = 'Other';
        subCategory = typeValue;
      }
    } else {
      if (typeValue == 'Feed' || typeValue == 'Medicine' || typeValue == 'Equipment' ||
          typeValue == 'Labor' || typeValue == 'Transport' || typeValue == 'Utilities' ||
          typeValue == 'Category Expense') {
        category = typeValue;
      } else {
        category = 'Other';
        subCategory = typeValue;
      }
    }
    
    return Transaction(
      type: transactionType,
      category: category,
      subCategory: subCategory,
      amount: amount,
      description: map['description'] as String?,
      transactionDate: date,
      contactName: transactionType == TransactionType.income 
          ? map['buyer_name'] as String? 
          : map['vendor_name'] as String?,
      contactInfo: transactionType == TransactionType.income 
          ? map['buyer_contact'] as String? 
          : map['vendor_contact'] as String?,
      notes: map['notes'] as String?,
      receiptNumber: map['receipt'] as String?,
      quantity: map['quantity'] != null ? double.tryParse(map['quantity'].toString()) : null,
      pricePerUnit: map['price'] != null ? double.tryParse(map['price'].toString()) : null,
    );
  }

  // Add this to your Transaction model in transaction.dart
Transaction copyWith({
  int? id,
  TransactionType? type,
  String? category,
  String? subCategory,
  double? amount,
  String? description,
  DateTime? transactionDate,
  String? contactName,
  String? contactInfo,
  String? notes,
  String? receiptNumber,
  double? quantity,
  double? pricePerUnit,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Transaction(
    id: id ?? this.id,
    type: type ?? this.type,
    category: category ?? this.category,
    subCategory: subCategory ?? this.subCategory,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    transactionDate: transactionDate ?? this.transactionDate,
    contactName: contactName ?? this.contactName,
    contactInfo: contactInfo ?? this.contactInfo,
    notes: notes ?? this.notes,
    receiptNumber: receiptNumber ?? this.receiptNumber,
    quantity: quantity ?? this.quantity,
    pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
}