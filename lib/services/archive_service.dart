import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goat.dart';
import '../models/archive.dart';

class ArchiveService {
  static const String _archivesKey = 'archived_goats';
  
  // Archive a goat
  static Future<void> archiveGoat({
    required Goat goat,
    required String reason,
    required DateTime archiveDate,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Create archive record
    final archive = ArchivedGoat(
      tagNo: goat.tagNo,
      reason: reason,
      archiveDate: archiveDate,
      notes: notes,
      goatData: goat.toJson(),
    );
    
    // 2. Add to archive list
    final archivesData = prefs.getString(_archivesKey);
    List<Map<String, dynamic>> archives = [];
    
    if (archivesData != null) {
      try {
        final List<dynamic> list = jsonDecode(archivesData) as List<dynamic>;
        archives = list.map((e) => e as Map<String, dynamic>).toList();
      } catch (e) {
        // ignore
      }
    }
    
    // Check if goat is already archived
    final existingIndex = archives.indexWhere((a) => a['tagNo'] == goat.tagNo);
    if (existingIndex != -1) {
      archives[existingIndex] = archive.toJson();
    } else {
      archives.add(archive.toJson());
    }
    
    // Save archives
    await prefs.setString(_archivesKey, jsonEncode(archives));
  }
  
  // Get archived goats by reason
  static Future<List<ArchivedGoat>> getArchivedGoats(String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final archivesData = prefs.getString(_archivesKey);
    
    if (archivesData != null) {
      try {
        final List<dynamic> list = jsonDecode(archivesData) as List<dynamic>;
        final List<ArchivedGoat> allArchives = list
            .map((e) => ArchivedGoat.fromJson(e as Map<String, dynamic>))
            .toList();
        
        return allArchives.where((archive) => archive.reason == reason).toList();
      } catch (e) {
        return [];
      }
    }
    
    return [];
  }
  
  // Get all archived goats
  static Future<List<ArchivedGoat>> getAllArchives() async {
    final prefs = await SharedPreferences.getInstance();
    final archivesData = prefs.getString(_archivesKey);
    
    if (archivesData != null) {
      try {
        final List<dynamic> list = jsonDecode(archivesData) as List<dynamic>;
        return list
            .map((e) => ArchivedGoat.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
    
    return [];
  }
  
  // Get count by reason
  static Future<int> getArchiveCount(String reason) async {
    final archives = await getArchivedGoats(reason);
    return archives.length;
  }
  
  // Restore a goat from archive
  static Future<Goat?> restoreGoat(String tagNo) async {
    final prefs = await SharedPreferences.getInstance();
    final archivesData = prefs.getString(_archivesKey);
    
    if (archivesData != null) {
      try {
        final List<dynamic> list = jsonDecode(archivesData) as List<dynamic>;
        final List<Map<String, dynamic>> archives = 
            list.map((e) => e as Map<String, dynamic>).toList();
        
        // Find the archive
        final archiveIndex = archives.indexWhere((a) => a['tagNo'] == tagNo);
        if (archiveIndex != -1) {
          final archiveData = archives[archiveIndex];
          final goatData = archiveData['goatData'] as Map<String, dynamic>;
          
          // Remove from archives
          archives.removeAt(archiveIndex);
          await prefs.setString(_archivesKey, jsonEncode(archives));
          
          // Return Goat object for restoration
          return Goat.fromJson(goatData);
        }
      } catch (e) {
        // Handle error
      }
    }
    
    return null;
  }
  
  // Check if goat is archived
  static Future<bool> isGoatArchived(String tagNo) async {
    final archives = await getAllArchives();
    return archives.any((archive) => archive.tagNo == tagNo);
  }
  
  // Get total archived count
  static Future<int> getTotalArchivedCount() async {
    final archives = await getAllArchives();
    return archives.length;
  }
}