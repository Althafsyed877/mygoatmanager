// lib/services/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goat.dart';  // ADD THIS IMPORT
import '../models/event.dart';
import '../models/milk_record.dart';
import '../models/transaction.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ========== GOATS ==========
  Future<List<Goat>> getGoats() async {
    final prefs = await _prefs;
    final goatsData = prefs.getString('goats');
    
    if (goatsData == null || goatsData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(goatsData);
      return jsonList.map((json) => Goat.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing goats from local storage: $e');
      return [];
    }
  }

  Future<void> saveGoats(List<Goat> goats) async {
    final prefs = await _prefs;
    final goatsJson = goats.map((goat) => goat.toJson()).toList();
    await prefs.setString('goats', jsonEncode(goatsJson));
  }

  Future<void> addOrUpdateGoat(Goat goat) async {
    final goats = await getGoats();
    final index = goats.indexWhere((g) => g.tagNo == goat.tagNo);
    
    if (index >= 0) {
      goats[index] = goat;
    } else {
      goats.add(goat);
    }
    
    await saveGoats(goats);
  }

  Future<void> deleteGoat(String tagNo) async {
    final goats = await getGoats();
    goats.removeWhere((goat) => goat.tagNo == tagNo);
    await saveGoats(goats);
  }

  // ========== EVENTS ==========
  Future<List<Event>> getEvents() async {
    final prefs = await _prefs;
    final eventsData = prefs.getString('events');
    
    if (eventsData == null || eventsData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(eventsData);
      return jsonList.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing events from local storage: $e');
      return [];
    }
  }

  Future<void> saveEvents(List<Map<String, dynamic>> events) async {
    final prefs = await _prefs;
    await prefs.setString('events', jsonEncode(events));
  }

  // ========== MILK RECORDS ==========

Future<List<MilkRecord>> getMilkRecords() async {
  final prefs = await _prefs;
  final milkData = prefs.getString('milk_records');
  
  if (milkData == null || milkData.isEmpty) {
    return [];
  }
  
  try {
    final List<dynamic> jsonList = jsonDecode(milkData);
    return jsonList.map((json) => MilkRecord.fromJson(json)).toList();
  } catch (e) {
    print('Error parsing milk records from local storage: $e');
    return [];
  }
}

Future<void> saveMilkRecords(List<MilkRecord> records) async {
  final prefs = await _prefs;
  final recordsJson = records.map((record) => record.toJson()).toList();
  await prefs.setString('milk_records', jsonEncode(recordsJson));
}

Future<void> addOrUpdateMilkRecord(MilkRecord record) async {
  final records = await getMilkRecords();
  final index = records.indexWhere((r) => 
    r.milkingDate == record.milkingDate);
  
  if (index >= 0) {
    records[index] = record;
  } else {
    records.add(record);
  }
  
  await saveMilkRecords(records);
}

  // ========== TRANSACTIONS ==========
  Future<List<Transaction>> getTransactions() async {
    final prefs = await _prefs;
    final transactionsData = prefs.getString('transactions');
    
    if (transactionsData == null || transactionsData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(transactionsData);
      final transactions = <Transaction>[];
      
      for (var json in jsonList) {
        try {
          final transaction = Transaction.fromJson(Map<String, dynamic>.from(json));
          transactions.add(transaction);
        } catch (e) {
          print('Error parsing single transaction: $e');
          print('Problematic JSON: $json');
        }
      }
      
      return transactions;
    } catch (e) {
      print('Error parsing transactions from local storage: $e');
      return [];
    }
  }

  // Save all transactions
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await _prefs;
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    await prefs.setString('transactions', jsonEncode(transactionsJson));
    print('Saved ${transactions.length} transactions to storage');
  }

  // Add or update a transaction
  Future<void> addOrUpdateTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    
    // Generate a unique ID if not present
    if (transaction.id == null) {
      final maxId = transactions.fold<int>(0, (max, t) => t.id != null && t.id! > max ? t.id! : max);
      // Create a new transaction with ID - you need to add copyWith method to Transaction model
      final transactionWithId = transaction.copyWith(id: maxId + 1);
      transactions.add(transactionWithId);
    } else {
      final index = transactions.indexWhere((t) => t.id == transaction.id);
      if (index >= 0) {
        transactions[index] = transaction;
      } else {
        transactions.add(transaction);
      }
    }
    
    await saveTransactions(transactions);
  }

  // For backward compatibility during transition
  Future<void> migrateAndConsolidateTransactions() async {
    final prefs = await _prefs;
    
    // First, get transactions from new storage
    final newTransactions = await getTransactions();
    
    // Get old incomes and expenses
    final oldIncomesJson = prefs.getString('saved_incomes');
    final oldExpensesJson = prefs.getString('saved_expenses');
    
    List<Transaction> allTransactions = [...newTransactions];
    
    // Migrate old incomes
    if (oldIncomesJson != null && oldIncomesJson.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(oldIncomesJson);
        for (final json in jsonList) {
          try {
            final map = Map<String, dynamic>.from(json);
            map['kind'] = 'income'; // Ensure kind is set
            final transaction = Transaction.fromUIMap(map);
            
            // Check if this transaction already exists
            final exists = allTransactions.any((t) =>
                t.type == transaction.type &&
                t.amount == transaction.amount &&
                t.transactionDate == transaction.transactionDate &&
                t.category == transaction.category);
            
            if (!exists) {
              allTransactions.add(transaction);
            }
          } catch (e) {
            print('Error migrating old income: $e');
          }
        }
        
        // Remove old incomes after migration
        await prefs.remove('saved_incomes');
      } catch (e) {
        print('Error parsing old incomes: $e');
      }
    }
    
    // Migrate old expenses
    if (oldExpensesJson != null && oldExpensesJson.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(oldExpensesJson);
        for (final json in jsonList) {
          try {
            final map = Map<String, dynamic>.from(json);
            map['kind'] = 'expense'; // Ensure kind is set
            final transaction = Transaction.fromUIMap(map);
            
            // Check if this transaction already exists
            final exists = allTransactions.any((t) =>
                t.type == transaction.type &&
                t.amount == transaction.amount &&
                t.transactionDate == transaction.transactionDate &&
                t.category == transaction.category);
            
            if (!exists) {
              allTransactions.add(transaction);
            }
          } catch (e) {
            print('Error migrating old expense: $e');
          }
        }
        
        // Remove old expenses after migration
        await prefs.remove('saved_expenses');
      } catch (e) {
        print('Error parsing old expenses: $e');
      }
    }
    
    // Save all consolidated transactions
    if (allTransactions.isNotEmpty) {
      // Assign IDs if missing
      var nextId = 1;
      final transactionsWithIds = allTransactions.map((t) {
        if (t.id == null) {
          return t.copyWith(id: nextId++);
        }
        return t;
      }).toList();
      
      await saveTransactions(transactionsWithIds);
      print('Migrated and consolidated ${allTransactions.length} transactions');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(int id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await saveTransactions(transactions);
  }

  // DEPRECATED - Remove these old methods or update them to use new system
  Future<void> saveIncomesOld(List<Map<String, dynamic>> incomes) async {
    // This should now convert to Transaction format
    final transactions = incomes.map((map) {
      map['kind'] = 'income';
      return Transaction.fromUIMap(map);
    }).toList();
    
    await addMultipleTransactions(transactions);
  }
  
  Future<void> saveExpensesOld(List<Map<String, dynamic>> expenses) async {
    // This should now convert to Transaction format
    final transactions = expenses.map((map) {
      map['kind'] = 'expense';
      return Transaction.fromUIMap(map);
    }).toList();
    
    await addMultipleTransactions(transactions);
  }
  
  Future<void> addMultipleTransactions(List<Transaction> transactions) async {
    final existingTransactions = await getTransactions();
    existingTransactions.addAll(transactions);
    await saveTransactions(existingTransactions);
  }

  // ========== SYNC STATUS ==========
  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await _prefs;
    await prefs.setString('last_sync_time', time.toIso8601String());
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await _prefs;
    final timeString = prefs.getString('last_sync_time');
    
    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ========== CLEAR ALL DATA ==========
  Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.remove('goats');
    await prefs.remove('events');
    await prefs.remove('milk_records');
    await prefs.remove('saved_incomes');
    await prefs.remove('saved_expenses');
    await prefs.remove('last_sync_time');
  }
}