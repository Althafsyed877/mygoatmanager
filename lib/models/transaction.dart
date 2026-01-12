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
    // Handle both new and old field names
    final typeStr = json['type'] ?? (json['kind'] == 'income' ? 'income' : 'expense');
    final category = json['category'] ?? json['income_type'] ?? json['expense_type'];
    final subCategory = json['sub_category'] ?? json['type'];
    
    return Transaction(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      type: typeStr.toString().toLowerCase() == 'income' 
          ? TransactionType.income 
          : TransactionType.expense,
      category: category?.toString(),
      subCategory: subCategory?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] ?? json['date']),
      contactName: json['contact_name'] ?? json['buyer_name'] ?? json['vendor_name'],
      contactInfo: json['contact_info'] ?? json['buyer_contact'] ?? json['vendor_contact'],
      notes: json['notes'] as String?,
      receiptNumber: json['receipt_number'] ?? json['receipt'],
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : null,
      pricePerUnit: json['price_per_unit'] ?? json['price'] != null 
          ? (json['price'] as num).toDouble() 
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
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
}