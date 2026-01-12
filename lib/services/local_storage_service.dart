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
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing transactions from local storage: $e');
      return [];
    }
  }

// Get incomes only
  Future<List<Transaction>> getIncomes() async {
    final transactions = await getTransactions();
    return transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
  }

  // Get expenses only
  Future<List<Transaction>> getExpenses() async {
    final transactions = await getTransactions();
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
  }

  // Save all transactions
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await _prefs;
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    await prefs.setString('transactions', jsonEncode(transactionsJson));
  }

  Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    final prefs = await _prefs;
    await prefs.setString('saved_expenses', jsonEncode(expenses));
  }
  Future<void> saveIncomes(List<Map<String, dynamic>> incomes) async {
    final prefs = await _prefs;
    await prefs.setString('saved_incomes', jsonEncode(incomes));
  }
  // Add or update a transaction
  Future<void> addOrUpdateTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    
    // If transaction has ID, update existing, otherwise add new
    if (transaction.id != null) {
      final index = transactions.indexWhere((t) => t.id == transaction.id);
      if (index >= 0) {
        transactions[index] = transaction;
      } else {
        transactions.add(transaction);
      }
    } else {
      // For new transactions, check by date, type, amount
      final index = transactions.indexWhere((t) =>
          t.transactionDate == transaction.transactionDate &&
          t.type == transaction.type &&
          t.amount == transaction.amount &&
          (t.category == transaction.category || t.subCategory == transaction.subCategory));
      
      if (index >= 0) {
        transactions[index] = transaction;
      } else {
        transactions.add(transaction);
      }
    }
    
    await saveTransactions(transactions);
  }

  // Delete transaction
  Future<void> deleteTransaction(int id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await saveTransactions(transactions);
  }
 // Backward compatibility: Convert old incomes/expenses to new Transaction format
  Future<void> migrateOldTransactions() async {
    final prefs = await _prefs;
    
    // Get old data
    final oldIncomes = prefs.getString('saved_incomes');
    final oldExpenses = prefs.getString('saved_expenses');
    
    if ((oldIncomes == null || oldIncomes.isEmpty) && 
        (oldExpenses == null || oldExpenses.isEmpty)) {
      return; // No old data to migrate
    }
    
    final List<Transaction> allTransactions = [];
    
    // Migrate old incomes
    if (oldIncomes != null && oldIncomes.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(oldIncomes);
        for (final json in jsonList) {
          final map = Map<String, dynamic>.from(json);
          final transaction = Transaction.fromUIMap(map);
          allTransactions.add(transaction);
        }
      } catch (e) {
        print('Error migrating old incomes: $e');
      }
    }
    
    // Migrate old expenses
    if (oldExpenses != null && oldExpenses.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(oldExpenses);
        for (final json in jsonList) {
          final map = Map<String, dynamic>.from(json);
          final transaction = Transaction.fromUIMap(map);
          allTransactions.add(transaction);
        }
      } catch (e) {
        print('Error migrating old expenses: $e');
      }
    }

    // Save as new format
    if (allTransactions.isNotEmpty) {
      await saveTransactions(allTransactions);
      
      // Optionally remove old data after migration
      // await prefs.remove('saved_incomes');
      // await prefs.remove('saved_expenses');
    }
  }
    // Keep old methods for backward compatibility during transition
  Future<void> saveIncomesOld(List<Map<String, dynamic>> incomes) async {
    final prefs = await _prefs;
    await prefs.setString('saved_incomes', jsonEncode(incomes));
  }
  Future<void> saveExpensesOld(List<Map<String, dynamic>> expenses) async {
    final prefs = await _prefs;
    await prefs.setString('saved_expenses', jsonEncode(expenses));
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