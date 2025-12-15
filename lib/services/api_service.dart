// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goat.dart';  // Your existing Goat model
import '../models/event.dart'; // Your existing Event model

class ApiService {
  // === CONFIGURATION - UPDATE THESE FOR YOUR GOAT MANAGER ===
  
  // Production URL (your Goat Manager backend)
  static const String productionUrl = 'https://sheepfarmmanager.myqrmart.com/api';
  
  // Local development URL (adjust port as needed)
  static const String localUrl = 'http://10.0.2.2:38429/api';
  
  // Toggle between local and production
  static bool useLocalhost = false;
  
  static String get baseUrl => useLocalhost ? localUrl : productionUrl;
  
  // === SINGLETON ===
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // === TOKEN MANAGEMENT ===
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
  
  // === HEALTH CHECKS ===
  Future<ApiResponse> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }
  
  Future<ApiResponse> checkDbHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/db-health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Database check error: $e');
    }
  }
  
  // === AUTHENTICATION ===
  Future<ApiResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      if (result.success && result.data?['token'] != null) {
        await saveToken(result.data!['token']);
        
        // Also save user data if provided
        if (result.data?['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(result.data!['user']));
        }
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Login error: $e');
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
  
  // === GOAT OPERATIONS ===
  Future<ApiResponse> getAllGoats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/goats'),
        headers: headers,
      );
      
      final result = ApiResponse.fromHttpResponse(response);
      
      // Convert API data to your Goat models if successful
      if (result.success && result.data?['goats'] is List) {
        final goatsList = (result.data!['goats'] as List)
            .map((json) => Goat.fromJson(json))
            .toList();
        result.data = {'goats': goatsList};
      }
      
      return result;
    } catch (e) {
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
  Future<ApiResponse> getMilkRecords() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/milk-records'),
        headers: headers,
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Get milk records error: $e');
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
        Uri.parse('$baseUrl/transactions'),
        headers: headers,
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Get transactions error: $e');
    }
  }
  
  // === SYNC DATA METHODS ===
  Future<ApiResponse> syncGoats(List<Map<String, dynamic>> goatsData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sync/goats'),
        headers: headers,
        body: json.encode({'goats': goatsData}),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Sync goats error: $e');
    }
  }
  
  Future<ApiResponse> syncEvents(List<Map<String, dynamic>> eventsData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sync/events'),
        headers: headers,
        body: json.encode({'events': eventsData}),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Sync events error: $e');
    }
  }
  
  Future<ApiResponse> syncMilkRecords(List<Map<String, dynamic>> milkRecordsData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sync/milk-records'),
        headers: headers,
        body: json.encode({'milk_records': milkRecordsData}),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Sync milk records error: $e');
    }
  }
  
  Future<ApiResponse> syncTransactions(List<Map<String, dynamic>> incomesData, List<Map<String, dynamic>> expensesData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sync/transactions'),
        headers: headers,
        body: json.encode({
          'incomes': incomesData,
          'expenses': expensesData
        }),
      );
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse.error('Sync transactions error: $e');
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
  
  // === UTILITIES ===
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
  
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }
  
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
      return ApiResponse.error(
        'Response parsing error: $e',
        statusCode: response.statusCode,
      );
    }
  }
  
  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}