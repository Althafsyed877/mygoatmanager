// lib/services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

  // === AUTHENTICATION CHECKS ===
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      // Just check if we have a token - simple validation
      // The actual API validation will happen when making API calls
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Auth check error: $e');
      return false;
    }
  }

  // === VALIDATE SESSION ===
Future<bool> validateSession() async {
  try {
    final token = await getToken();
    
    // If no token, definitely not authenticated
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // Check if token is valid (basic check)
    // Don't call API if we don't need to
    return true;
    
    // If you want to actually validate with backend:
    // try {
    //   final response = await _apiService.checkAuth();
    //   return response.statusCode == 200;
    // } catch (e) {
    //   return false;
    // }
  } catch (e) {
    // ignore: avoid_print
    print('Session validation error: $e');
    return false; // Default to false on error
  }
}

  // === LOGIN ===
  Future<ApiResponse> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      
      if (response.success && response.data?['token'] != null) {
        await saveToken(response.data!['token']);
        
        if (response.data?['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(response.data!['user']));
        }
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Login error: $e');
    }
  }

  // === REGISTER ===
  Future<ApiResponse> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.register(userData);
      
      // Optionally auto-login after registration
      if (response.success && response.data?['token'] != null) {
        await saveToken(response.data!['token']);
        
        if (response.data?['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(response.data!['user']));
        }
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Registration error: $e');
    }
  }

  // === GOOGLE LOGIN ===
  Future<ApiResponse> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return ApiResponse.error('Google sign in cancelled');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Get the ID token
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return ApiResponse.error('No ID token received from Google');
      }
      
      final result = await _apiService.loginWithGoogle(idToken);
      
      if (result.success && result.data?['token'] != null) {
        await saveToken(result.data!['token']);
        
        if (result.data?['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(result.data!['user']));
        }
      }
      
      return result;
    } catch (e) {
      // ignore: avoid_print
      print('Google login error: $e');
      return ApiResponse.error('Google login error: $e');
    }
  }

  // === FORGOT PASSWORD ===
  Future<ApiResponse> forgotPassword(String email) async {
    try {
      return await _apiService.forgotPassword(email);
    } catch (e) {
      return ApiResponse.error('Forgot password error: $e');
    }
  }

  // === LOGOUT ===
 Future<void> logout() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('goat_auth_token');
    await prefs.remove('user_data');
    
    // Clear any other user-related data
    await prefs.remove('selectedLanguage');
    await prefs.remove('selectedLanguageCode');
    
    // Sign out from Google if used
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore Google signout errors
    }
    
    // ignore: avoid_print
    print('User logged out successfully');
  } catch (e) {
    // ignore: avoid_print
    print('Logout error: $e');
    rethrow; // Re-throw to handle in UI
  }
 }

  // === USER DATA ===
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user_data');
      if (userString != null && userString.isNotEmpty) {
        return json.decode(userString);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Get user data error: $e');
      return null;
    }
  }

  // === GET USER EMAIL ===
  Future<String?> getUserEmail() async {
    try {
      final userData = await getUserData();
      return userData?['email']?.toString();
    } catch (e) {
      // ignore: avoid_print
      print('Get user email error: $e');
      return null;
    }
  }

  // === GET USERNAME ===
  Future<String?> getUsername() async {
    try {
      final userData = await getUserData();
      return userData?['username']?.toString() ?? userData?['name']?.toString();
    } catch (e) {
      // ignore: avoid_print
      print('Get username error: $e');
      return null;
    }
  }

  // === CHECK IF USER IS LOGGED IN ===
  Future<bool> isLoggedIn() async {
    return await validateSession();
  }

  // === CLEAR ALL USER DATA ===
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _googleSignIn.signOut();
    } catch (e) {
      // ignore: avoid_print
      print('Clear all data error: $e');
    }
  }

  // === REFRESH TOKEN ===
  Future<bool> refreshToken() async {
    try {
      // Implement token refresh logic if your API supports it
      final token = await getToken();
      if (token == null) return false;
      
      // Call refresh endpoint if available
      // Example: final response = await _apiService.refreshToken(token);
      // if (response.success) { await saveToken(response.data['token']); return true; }
      
      return false; // Return true if refreshed successfully
    } catch (e) {
      // ignore: avoid_print
      print('Refresh token error: $e');
      return false;
    }
  }
}