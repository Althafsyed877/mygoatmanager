// lib/utils/transaction_helper.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionHelper {
  static const String _transactionsKey = 'transactions';

  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString(_transactionsKey) ?? '[]';
    
    try {
      final List<dynamic> jsonList = jsonDecode(transactionsJson);
      List<Transaction> loadedTransactions = [];
      
      for (var json in jsonList) {
        try {
          final transaction = Transaction.fromJson(Map<String, dynamic>.from(json));
          loadedTransactions.add(transaction);
        } catch (e) {
          print('Error parsing transaction: $e');
        }
      }
      
      // Sort by date (newest first)
      loadedTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      
      return loadedTransactions;
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = jsonEncode(
      transactions.map((t) => t.toJson()).toList()
    );
    await prefs.setString(_transactionsKey, transactionsJson);
  }

  static Future<void> addTransaction(Transaction transaction) async {
    final transactions = await loadTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);
  }

  static Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    final transactions = await loadTransactions();
    final index = transactions.indexOf(oldTransaction);
    if (index != -1) {
      transactions[index] = newTransaction;
      await saveTransactions(transactions);
    }
  }

  static Future<void> deleteTransaction(Transaction transaction) async {
    final transactions = await loadTransactions();
    transactions.remove(transaction);
    await saveTransactions(transactions);
  }
}