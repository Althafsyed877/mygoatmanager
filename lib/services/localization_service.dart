import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageCodeKey = 'languageCode';
  static const String _countryCodeKey = 'countryCode';

  static Future<void> saveLanguage(String languageCode, String countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
    await prefs.setString(_countryCodeKey, countryCode);
  }

  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);
    
    if (languageCode != null) {
      return Locale(languageCode, countryCode);
    }
    return null;
  }

  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'te':
        return 'Telugu';
      case 'hi':
        return 'Hindi';
      case 'ta':
        return 'Tamil';
      case 'kn':
        return 'Kannada';
      default:
        return 'English';
    }
  }

  static String getLanguageNativeName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'te':
        return 'తెలుగు';
      case 'hi':
        return 'हिन्दी';
      case 'ta':
        return 'தமிழ்';
      case 'kn':
        return 'ಕನ್ನಡ';
      default:
        return 'English';
    }
  }

  static String getLanguageCode(String name) {
    switch (name) {
      case 'English':
        return 'en';
      case 'Telugu':
        return 'te';
      case 'Hindi':
        return 'hi';
      case 'Tamil':
        return 'ta';
      case 'Kannada':
        return 'kn';
      default:
        return 'en';
    }
  }
}

