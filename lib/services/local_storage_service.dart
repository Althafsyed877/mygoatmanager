// lib/services/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goat.dart';  // ADD THIS IMPORT

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
  Future<List<Map<String, dynamic>>> getEvents() async {
    final prefs = await _prefs;
    final eventsData = prefs.getString('events');
    
    if (eventsData == null || eventsData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(eventsData);
      return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
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
  Future<List<Map<String, dynamic>>> getMilkRecords() async {
    final prefs = await _prefs;
    final milkData = prefs.getString('milk_records');
    
    if (milkData == null || milkData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(milkData);
      return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      print('Error parsing milk records from local storage: $e');
      return [];
    }
  }

  Future<void> saveMilkRecords(List<Map<String, dynamic>> records) async {
    final prefs = await _prefs;
    await prefs.setString('milk_records', jsonEncode(records));
  }

  // ========== TRANSACTIONS ==========
  Future<List<Map<String, dynamic>>> getIncomes() async {
    final prefs = await _prefs;
    final incomesData = prefs.getString('saved_incomes');
    
    if (incomesData == null || incomesData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(incomesData);
      return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      print('Error parsing incomes from local storage: $e');
      return [];
    }
  }

  Future<void> saveIncomes(List<Map<String, dynamic>> incomes) async {
    final prefs = await _prefs;
    await prefs.setString('saved_incomes', jsonEncode(incomes));
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final prefs = await _prefs;
    final expensesData = prefs.getString('saved_expenses');
    
    if (expensesData == null || expensesData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(expensesData);
      return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      print('Error parsing expenses from local storage: $e');
      return [];
    }
  }

  Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
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