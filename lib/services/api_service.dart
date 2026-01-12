// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goat.dart';  // Your Goat model
import '../models/event.dart'; 
import '../models/milk_record.dart';// Your Event model
import 'dart:io';
import '../models/transaction.dart';
// Remove unused import: import 'dart:math';

class ApiService {
  // === CONFIGURATION - UPDATE THESE FOR YOUR GOAT MANAGER ===
  
  // Production URL (your Goat Manager backend)
  static const String productionUrl = 'https://sheepfarmmanager.myqrmart.com/api';
  
  // Local development URL (adjust port as needed)
  static const String localUrl = 'http://10.0.2.2:38429/api'; // For emulator
  // For physical device testing: 'http://<YOUR_COMPUTER_IP>:38429/api'
  
  // Toggle between local and production
  static bool useLocalhost = false; // Set to true for local testing
  
  static String get baseUrl => productionUrl;
  
  // === SINGLETON ===
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // === TOKEN MANAGEMENT (KEEP THESE - AuthService uses them) ===
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goat_auth_token', token);
  }
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('goat_auth_token');
  }
  
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('goat_auth_token');
  }
  
  // === HEADERS ===
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // === AUTHENTICATION ENDPOINTS ===
  Future<ApiResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.toLowerCase().trim(),
          'password': password,
        }),
      );

      debugPrint('Login request to: $baseUrl/auth/login');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final result = ApiResponse.fromHttpResponse(response);

      if (result.success && result.data?['token'] != null) {
        await saveToken(result.data!['token']);

        // Save user data if provided
        if (result.data?['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_data',
            json.encode(result.data!['user']),
          );
        }
      }

      return result;
    } catch (e) {
      debugPrint('Login exception: $e');
      return ApiResponse.error('Login failed. Please try again.');
    }
  }
    
  Future<ApiResponse> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Registration error: $e');
    }
  }
  
  Future<ApiResponse> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Forgot password error: $e');
    }
  }
  
  // === GOOGLE AUTHENTICATION ===
  Future<ApiResponse> loginWithGoogle(String idToken, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': idToken,
          'email': email,
        }),
      );
      
      debugPrint('Google Login request to: $baseUrl/auth/google');
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['token'] != null) {
        await saveToken(result.data!['token']);
        
        if (result.data?['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(result.data!['user']));
        }
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Google Login error: $e');
    }
  }
  
  // === USER DATA ===
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }
  
  // === AUTH VALIDATION (For AuthService) ===
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/validate'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // === GOAT OPERATIONS ===
   Future<ApiResponse> getAllGoats() async {
   try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/goats'),
      headers: headers,
     );

    debugPrint('Get goats response: ${response.statusCode}');

    final result = ApiResponse.fromHttpResponse(response);
    
    // Convert API data to your Goat models if successful
    if (result.success && result.data?['goats'] is List) {
      try {
        final goatsList = (result.data!['goats'] as List)
            .map((json) {
              // If it's already a Goat object, return it
              if (json is Goat) {
                return json;
              }
              // Otherwise, convert from JSON
              return Goat.fromJson(json);
            })
            .toList();
        result.data = {'goats': goatsList};
      } catch (e) {
        debugPrint('Error converting goats: $e');
        return ApiResponse.error('Error processing goats data: $e');
      }
    }
    
    return result;
   } catch (e) {
    debugPrint('Get goats error: $e');
    return ApiResponse.error('Get goats error: $e');
   }
  }


  Future<ApiResponse> getGoat(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/goats/$id'),
        headers: headers,
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['goat'] != null) {
        final goat = Goat.fromJson(result.data!['goat']);
        result.data = {'goat': goat};
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Get goat error: $e');
    }
  }
  

  Future<ApiResponse> createGoat(Map<String, dynamic> goatData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/goats'),
        headers: headers,
        body: json.encode(goatData),
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['goat'] != null) {
        final goat = Goat.fromJson(result.data!['goat']);
        result.data = {'goat': goat};
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Create goat error: $e');
    }
  }
  

  Future<ApiResponse> updateGoat(String id, Map<String, dynamic> goatData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/goats/$id'),
        headers: headers,
        body: json.encode(goatData),
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['goat'] != null) {
        final goat = Goat.fromJson(result.data!['goat']);
        result.data = {'goat': goat};
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Update goat error: $e');
    }
  }
  

  Future<ApiResponse> deleteGoat(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/goats/$id'),
        headers: headers,
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Delete goat error: $e');
    }
  }
  

  // === EVENT OPERATIONS ===
  Future<ApiResponse> getAllEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: headers,
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['events'] is List) {
        final eventsList = (result.data!['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();
        result.data = {'events': eventsList};
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Get events error: $e');
    }
  }
  

  Future<ApiResponse> createEvent(Map<String, dynamic> eventData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: headers,
        body: json.encode(eventData),
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['event'] != null) {
        final event = Event.fromJson(result.data!['event']);
        result.data = {'event': event};
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Create event error: $e');
    }
  }
  

  // === MILK RECORDS ===

// GET milk records with proper conversion
Future<ApiResponse> getMilkRecords() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/milk-records'),
      headers: headers,
    );
    
    final result = ApiResponse.fromHttpResponse(response);
    
    // Convert API data to MilkRecord models if successful
    if (result.success && result.data?['milk_records'] is List) {
      try {
        final milkRecordsList = (result.data!['milk_records'] as List)
            .map((json) {
              // Create MilkRecord from API JSON
              return MilkRecord(
                milkingDate: DateTime.parse(json['milking_date'] ?? json['date']),
                morningQuantity: (json['morning_quantity'] ?? json['morningQuantity'] ?? 0).toDouble(),
                eveningQuantity: (json['evening_quantity'] ?? json['eveningQuantity'] ?? 0).toDouble(),
                total: (json['total'] ?? 0).toDouble(),
                used: (json['used'] ?? 0).toDouble(),
                notes: json['notes'],
                milkType: json['milk_type'] ?? json['milkType'] ?? 'Individual Goat Milk',
              );
            })
            .toList();
        result.data = {'milk_records': milkRecordsList};
      } catch (e) {
        debugPrint('Error converting milk records: $e');
        return ApiResponse.error('Error processing milk records data: $e');
      }
    }
    
    return result;
  } catch (e) {
    debugPrint('Get milk records error: $e');
    return ApiResponse.error('Get milk records error: $e');
  }
}

// CREATE milk record with proper mapping
Future<ApiResponse> createMilkRecord(MilkRecord milkRecord) async {
  try {
    final headers = await _getHeaders();
    
    // Map your MilkRecord model to API expected format
    final milkData = {
      'milking_date': milkRecord.milkingDate.toIso8601String(),
      'morning_quantity': milkRecord.morningQuantity,
      'evening_quantity': milkRecord.eveningQuantity,
      'total': milkRecord.total,
      'used': milkRecord.used,
      'notes': milkRecord.notes,
      'milk_type': milkRecord.milkType,
      'is_whole_farm': milkRecord.milkType == 'Whole Farm Milk', // Convert to boolean
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/milk-records'),
      headers: headers,
      body: json.encode(milkData),
    );
    
    final result = ApiResponse.fromHttpResponse(response);
    
    if (result.success && result.data?['milk_record'] != null) {
      // Convert back to MilkRecord if needed
      final createdRecord = MilkRecord(
        milkingDate: DateTime.parse(result.data!['milk_record']['milking_date']),
        morningQuantity: (result.data!['milk_record']['morning_quantity'] ?? 0).toDouble(),
        eveningQuantity: (result.data!['milk_record']['evening_quantity'] ?? 0).toDouble(),
        total: (result.data!['milk_record']['total'] ?? 0).toDouble(),
        used: (result.data!['milk_record']['used'] ?? 0).toDouble(),
        notes: result.data!['milk_record']['notes'],
        milkType: result.data!['milk_record']['milk_type'] ?? 'Individual Goat Milk',
      );
      result.data = {'milk_record': createdRecord};
    }
    
    return result;
  } catch (e) {
    return ApiResponse.error('Create milk record error: $e');
  }
}

// UPDATE milk record
Future<ApiResponse> updateMilkRecord(String id, MilkRecord milkRecord) async {
  try {
    final headers = await _getHeaders();
    
    final milkData = {
      'milking_date': milkRecord.milkingDate.toIso8601String(),
      'morning_quantity': milkRecord.morningQuantity,
      'evening_quantity': milkRecord.eveningQuantity,
      'total_quantity': milkRecord.total,
      'used_quantity': milkRecord.used,
      'notes': milkRecord.notes,
      'milk_type': milkRecord.milkType,
    };
    
    final response = await http.put(
      Uri.parse('$baseUrl/milk-records/$id'),
      headers: headers,
      body: json.encode(milkData),
    );
    
    return ApiResponse.fromHttpResponse(response);
  } catch (e) {
    return ApiResponse.error('Update milk record error: $e');
  }
}

// DELETE milk record
Future<ApiResponse> deleteMilkRecord(String id) async {
  try {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/milk-records/$id'),
      headers: headers,
    );
    
    return ApiResponse.fromHttpResponse(response);
  } catch (e) {
    return ApiResponse.error('Delete milk record error: $e');
  }
}
  

  // === PREGNANCIES ===
  Future<ApiResponse> getPregnancies() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pregnancies'),
        headers: headers,
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Get pregnancies error: $e');
    }
  }
  

  // === REPORTS ===
  Future<ApiResponse> getReports() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reports'),
        headers: headers,
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Get reports error: $e');
    }
  }
  

  // === TRANSACTIONS ===
  Future<ApiResponse> getTransactions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/transactions'), // This endpoint needs to be created
        headers: headers,
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['transactions'] is List) {
        try {
          final transactionsList = (result.data!['transactions'] as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
          result.data = {'transactions': transactionsList};
        } catch (e) {
          debugPrint('Error converting transactions: $e');
          return ApiResponse.error('Error processing transactions: $e');
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Get transactions error: $e');
      return ApiResponse.error('Get transactions error: $e');
    }
  }

  // GET incomes only
  Future<ApiResponse> getIncomes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/incomes'),
        headers: headers,
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['incomes'] is List) {
        try {
          final incomesList = (result.data!['incomes'] as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
          result.data = {'incomes': incomesList};
        } catch (e) {
          debugPrint('Error converting incomes: $e');
          return ApiResponse.error('Error processing incomes: $e');
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Get incomes error: $e');
      return ApiResponse.error('Get incomes error: $e');
    }
  }

  // GET expenses only
  Future<ApiResponse> getExpenses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: headers,
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['expenses'] is List) {
        try {
          final expensesList = (result.data!['expenses'] as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
          result.data = {'expenses': expensesList};
        } catch (e) {
          debugPrint('Error converting expenses: $e');
          return ApiResponse.error('Error processing expenses: $e');
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Get expenses error: $e');
      return ApiResponse.error('Get expenses error: $e');
    }
  }

  // CREATE transaction
  Future<ApiResponse> createTransaction(Transaction transaction) async {
    try {
      final headers = await _getHeaders();
      
      final transactionData = transaction.toJson();
      
      final url = transaction.type == TransactionType.income 
          ? '$baseUrl/incomes'
          : '$baseUrl/expenses';
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(transactionData),
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data != null) {
        final key = transaction.type == TransactionType.income ? 'income' : 'expense';
        if (result.data![key] != null) {
          final createdTransaction = Transaction.fromJson(result.data![key]);
          result.data = {key: createdTransaction};
        }
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Create transaction error: $e');
    }
  }

  // UPDATE transaction
  Future<ApiResponse> updateTransaction(Transaction transaction) async {
    try {
      if (transaction.id == null) {
        return ApiResponse.error('Transaction ID is required for update');
      }
      
      final headers = await _getHeaders();
      
      final transactionData = transaction.toJson();
      
      final url = transaction.type == TransactionType.income 
          ? '$baseUrl/incomes/${transaction.id}'
          : '$baseUrl/expenses/${transaction.id}';
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(transactionData),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Update transaction error: $e');
    }
  }

  // DELETE transaction
  Future<ApiResponse> deleteTransaction(Transaction transaction) async {
    try {
      if (transaction.id == null) {
        return ApiResponse.error('Transaction ID is required for delete');
      }
      
      final headers = await _getHeaders();
      
      final url = transaction.type == TransactionType.income 
          ? '$baseUrl/incomes/${transaction.id}'
          : '$baseUrl/expenses/${transaction.id}';
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Delete transaction error: $e');
    }
  }

  // SYNC transactions
  Future<ApiResponse> syncTransactions(List<Transaction> transactions) async {
    try {
      debugPrint('🔄 [TRANSACTIONS SYNC] Starting sync...');
      
      // Separate incomes and expenses
      final incomes = transactions
          .where((t) => t.type == TransactionType.income)
          .map((t) => t.toJson())
          .toList();
      
      final expenses = transactions
          .where((t) => t.type == TransactionType.expense)
          .map((t) => t.toJson())
          .toList();
      
      debugPrint('📱 Number of incomes to sync: ${incomes.length}');
      debugPrint('📱 Number of expenses to sync: ${expenses.length}');
      
      // Check authentication
      final headers = await _getHeaders();
      
      if (!headers.containsKey('Authorization')) {
        debugPrint('❌ NO AUTH TOKEN FOUND!');
        return ApiResponse.error('Not authenticated. Please login again.');
      }
      
      // Prepare request
      final url = '$baseUrl/sync/transactions';
      debugPrint('🌐 Calling URL: $url');
      
      final body = json.encode({
        'incomes': incomes,
        'expenses': expenses,
      });
      
      // Send request
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      
      debugPrint('📥 Response Status Code: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success) {
        debugPrint('✅ TRANSACTIONS SYNC SUCCESSFUL!');
      } else {
        debugPrint('❌ TRANSACTIONS SYNC FAILED: ${result.message}');
        if (response.statusCode == 401) {
          debugPrint('⚠️ Token expired - clearing token');
          await clearToken();
        }
      }
      
      return result;
      
    } catch (e) {
      debugPrint('💥 CRITICAL ERROR in syncTransactions: $e');
      
      if (e is SocketException) {
        return ApiResponse.error('Cannot connect to server. Check internet.');
      }
      if (e is FormatException) {
        return ApiResponse.error('Server returned invalid data.');
      }
      
      return ApiResponse.error('Transactions sync failed: $e');
    }
  }
  

  // === SYNC DATA METHODS ===
Future<ApiResponse> syncGoats(List<Map<String, dynamic>> goatsData) async {
  try {
    // debugPrint('🔄 SYNC GOATS STARTED =========================');
    // debugPrint('📱 Number of goats to sync: ${goatsData.length}');
    
    // 1. GET HEADERS
    final headers = await _getHeaders();
    // debugPrint('   - Content-Type: ${headers['Content-Type']}');
    // debugPrint('   - Auth exists: ${headers.containsKey('Authorization')}');
    
    if (!headers.containsKey('Authorization')) {
      debugPrint('❌ ERROR: No auth token found!');
      return ApiResponse.error('Not authenticated. Please login again.');
    }
    
    // 2. CHECK DATA
    if (goatsData.isEmpty) {
      debugPrint('ℹ️ No goats to sync');
      return ApiResponse.success(message: 'No goats to sync');
    }
    
    // Show sample data
    if (goatsData.isNotEmpty) {
      debugPrint('📋 Sample goat data (first of ${goatsData.length}):');
      final firstGoat = goatsData.first;
      for (final key in firstGoat.keys) {
        debugPrint('   - $key: ${firstGoat[key]}');
      }
    }
    
    // 3. SEND REQUEST
    final url = '$baseUrl/sync/goats';
    debugPrint('🌐 Sending POST to: $url');
    
    final body = json.encode({'goats': goatsData});
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    
    // 4. ANALYZE RESPONSE
    debugPrint('📥 Response:');
    debugPrint('   - Status: ${response.statusCode}');
    debugPrint('   - Body: ${response.body}');
    
    final result = ApiResponse.fromHttpResponse(response);
    
    debugPrint('📊 Result: ${result.success ? "✅" : "❌"} ${result.message}');
    
    if (!result.success) {
      debugPrint('❌ ERROR: ${result.message}');
      if (response.statusCode == 401) {
        await clearToken();
        debugPrint('⚠️ Token cleared due to 401');
      }
    }
    
    return result;
    
  } catch (e) {
    debugPrint('💥 ERROR: $e');
    
    if (e is SocketException) {
      return ApiResponse.error('Cannot connect to server. Check URL: $baseUrl');
    }
    if (e is FormatException) {
      return ApiResponse.error('Invalid server response format');
    }
    
    return ApiResponse.error('Sync failed: $e');
  }
}


// Additional sync methods for other data types
Future<ApiResponse> syncEvents(List<Map<String, dynamic>> eventsData) async {
  try {
    // ========== ADD THESE DEBUG LOGS ==========
    debugPrint('🔄 [EVENTS SYNC] STARTING ========================');
    debugPrint('📱 Number of events to sync: ${eventsData.length}');
    
    // Show all events being sent
    for (int i = 0; i < eventsData.length; i++) {
      final event = eventsData[i];
      debugPrint('📋 Event ${i + 1}:');
      debugPrint('   - Tag No: ${event['tagNo']}');
      debugPrint('   - Event Type: ${event['eventType']}');
      debugPrint('   - Date: ${event['date']}');
      debugPrint('   - Medicine: ${event['medicine']}');
      debugPrint('   - Notes: ${event['notes']}');
      debugPrint('   - Is Mass Event: ${event['isMassEvent']}');
    }
    
    // Check authentication
    final headers = await _getHeaders();
    
    if (!headers.containsKey('Authorization')) {
      debugPrint('❌ NO AUTH TOKEN FOUND! User might be logged out.');
      return ApiResponse.error('Not authenticated. Please login again.');
    }
    
    debugPrint('🔑 Auth token exists: YES');
    
    // Prepare request
    final url = '$baseUrl/sync/events';
    debugPrint('🌐 Calling URL: $url');
    
    final body = json.encode({'events': eventsData});
    debugPrint('📦 Request body size: ${body.length} bytes');
    
    // Send request
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    
    debugPrint('📥 Response Status Code: ${response.statusCode}');
    debugPrint('📥 Response Body: ${response.body}');
    
    final result = ApiResponse.fromHttpResponse(response);
    
    if (result.success) {
      debugPrint('✅ EVENTS SYNC SUCCESSFUL!');
      if (result.data != null) {
        debugPrint('   - Synced: ${result.data!['synced_count']}');
        debugPrint('   - Failed: ${result.data!['skipped_count']}');
      }
    } else {
      debugPrint('❌ EVENTS SYNC FAILED: ${result.message}');
      if (response.statusCode == 401) {
        debugPrint('⚠️ Token expired - clearing token');
        await clearToken();
      }
    }
    
    debugPrint('===============================================');
    return result;
    
  } catch (e) {
    debugPrint('💥 CRITICAL ERROR in syncEvents:');
    debugPrint('   - Error: $e');
    debugPrint('   - Type: ${e.runtimeType}');
    
    if (e is SocketException) {
      debugPrint('   - SocketException: Cannot connect to server');
      return ApiResponse.error('Cannot connect to server. Check internet.');
    }
    if (e is FormatException) {
      debugPrint('   - FormatException: Invalid response from server');
      return ApiResponse.error('Server returned invalid data.');
    }
    
    return ApiResponse.error('Events sync failed: $e');
  }
}
  
// FIXED: syncMilkRecords method
Future<ApiResponse> syncMilkRecords(List<Map<String, dynamic>> milkRecordsData) async {
  try {
    debugPrint('🔄 [MILK RECORDS SYNC] STARTING ========================');
    debugPrint('📱 Number of milk records to sync: ${milkRecordsData.length}');
    
    // Show all milk records being sent
    for (int i = 0; i < milkRecordsData.length; i++) {
      final record = milkRecordsData[i];
      debugPrint('📋 Milk Record ${i + 1}:');
      debugPrint('   - Date: ${record['milking_date'] ?? record['date'] ?? record['milkingDate']}');
      debugPrint('   - Morning Quantity: ${record['morning_quantity'] ?? record['morningQuantity']}');
      debugPrint('   - Evening Quantity: ${record['evening_quantity'] ?? record['eveningQuantity']}');
      debugPrint('   - Total: ${record['total']}');
      debugPrint('   - Used: ${record['used']}');
      debugPrint('   - Notes: ${record['notes']}');
      debugPrint('   - Milk Type: ${record['milk_type'] ?? record['milkType']}');
    }
    
    // Check authentication
    final headers = await _getHeaders();
    
    if (!headers.containsKey('Authorization')) {
      debugPrint('❌ NO AUTH TOKEN FOUND! User might be logged out.');
      return ApiResponse.error('Not authenticated. Please login again.');
    }
    
    debugPrint('🔑 Auth token exists: YES');
    
    // Prepare request
    final url = '$baseUrl/sync/milk-records';
    debugPrint('🌐 Calling URL: $url');
    
    // Ensure correct field names:
    final List<Map<String, dynamic>> formattedRecords = milkRecordsData.map((record) {
      return {
        'milking_date': record['milking_date'] ?? record['date'] ?? record['milkingDate'],
        'morning_quantity': record['morning_quantity'] ?? record['morningQuantity'] ?? 0,
        'evening_quantity': record['evening_quantity'] ?? record['eveningQuantity'] ?? 0,
        'total_quantity': record['total'] ?? record['total_quantity'] ?? 0, // Accept both
        'used_quantity': record['used'] ?? record['used_quantity'] ?? 0,   // Accept both
        'notes': record['notes'],
        'milk_type': record['milk_type'] ?? record['milkType'] ?? 'Individual Goat Milk',
      };
    }).toList();
    
    final body = json.encode({'milk_records': formattedRecords});
    debugPrint('📦 Request body size: ${body.length} bytes');
    
    // Send request
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    
    debugPrint('📥 Response Status Code: ${response.statusCode}');
    debugPrint('📥 Response Body: ${response.body}');
    
    final result = ApiResponse.fromHttpResponse(response);
    
    if (result.success) {
      debugPrint('✅ MILK RECORDS SYNC SUCCESSFUL!');
      if (result.data != null) {
        debugPrint('   - Created: ${result.data!['created']}');
        debugPrint('   - Updated: ${result.data!['updated']}');
        debugPrint('   - Skipped: ${result.data!['skipped']}');
        debugPrint('   - Synced: ${result.data!['synced_count']}');
      }
    } else {
      debugPrint('❌ MILK RECORDS SYNC FAILED: ${result.message}');
      if (response.statusCode == 401) {
        debugPrint('⚠️ Token expired - clearing token');
        await clearToken();
      }
    }
    
    debugPrint('===============================================');
    return result;
    
  } catch (e) {
    debugPrint('💥 CRITICAL ERROR in syncMilkRecords:');
    debugPrint('   - Error: $e');
    debugPrint('   - Type: ${e.runtimeType}');
    
    if (e is SocketException) {
      debugPrint('   - SocketException: Cannot connect to server');
      return ApiResponse.error('Cannot connect to server. Check internet.');
    }
    if (e is FormatException) {
      debugPrint('   - FormatException: Invalid response from server');
      return ApiResponse.error('Server returned invalid data.');
    }
    
    return ApiResponse.error('Milk records sync failed: $e');
  }
}
  

  Future<ApiResponse> syncFarmSetup(Map<String, dynamic> farmSetupData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sync/farm-setup'),
        headers: headers,
        body: json.encode(farmSetupData),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Sync farm setup error: $e');
    }
  }
  

  Future<ApiResponse> syncArchivedGoats(List<Map<String, dynamic>> archivedGoatsData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sync/archived-goats'),
        headers: headers,
        body: json.encode({'archived_goats': archivedGoatsData}),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Sync archived goats error: $e');
    }
  }
  

  // === DOWNLOAD/SYNC DATA FROM SERVER ===
  Future<ApiResponse> downloadAllData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/sync/download-all'),
        headers: headers,
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Download all data error: $e');
    }
  }
  
  
  // === BULK SYNC METHOD (Alternative simpler approach) ===
  Future<ApiResponse> bulkSyncGoats(List<Map<String, dynamic>> goatsData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/goats/bulk-sync'),
        headers: headers,
        body: json.encode({'goats': goatsData}),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Bulk sync goats error: $e');
    }
  }
  
  // === LOGOUT ===
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('goat_auth_token');
    await prefs.remove('user_data');
  }
}

// === API RESPONSE MODEL ===
class ApiResponse {
  final bool success;
  final String message;
  Map<String, dynamic>? data;
  final int? statusCode;
  final bool requiresLogin;
  
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.requiresLogin = false,
  });
  
  factory ApiResponse.success({
    String message = 'Success',
    Map<String, dynamic>? data,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }
  
  factory ApiResponse.error(String message, {int? statusCode, bool requiresLogin = false}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      requiresLogin: requiresLogin,
    );
  }
  
  factory ApiResponse.fromHttpResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          message: data['message'] ?? 'Success',
          data: data,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          data['error'] ?? 'Unauthorized',
          statusCode: response.statusCode,
          requiresLogin: true,
        );
      } else {
        return ApiResponse.error(
          data['error'] ?? data['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // If JSON parsing fails, treat the response body as plain text error message
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          message: response.body.isNotEmpty ? response.body : 'Success',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          response.body.isNotEmpty ? response.body : 'Request failed',
          statusCode: response.statusCode,
        );
      }
    }
  }
  
  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}