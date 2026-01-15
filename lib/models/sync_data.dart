import 'package:flutter/material.dart';
import 'package:mygoatmanager/services/api_service.dart';
import 'package:mygoatmanager/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
// REMOVE this import since it's unused: import 'package:mygoatmanager/models/milk_record.dart';

class SyncResult {
  final bool success;
  final bool hasErrors;
  final bool notAuthenticated;
  final String errorMessage;

  SyncResult({
    required this.success,
    required this.hasErrors,
    required this.notAuthenticated,
    required this.errorMessage,
  });
}

class SyncService {
  Future<SyncResult> syncData() async {
    try {
      final localStorage = LocalStorageService();
      final apiService = ApiService();

      bool hasErrors = false;
      String errorMessage = '';

      // ========== AUTH CHECK ==========
      final isAuthenticated = await apiService.isAuthenticated();
      if (!isAuthenticated) {
        return SyncResult(
          success: false,
          hasErrors: false,
          notAuthenticated: true,
          errorMessage: '',
        );
      }

      // ========== 1. SYNC GOATS ==========
      try {
        final localGoats = await localStorage.getGoats();
        debugPrint('🔄 Syncing ${localGoats.length} goats...');

        if (localGoats.isNotEmpty) {
          final localGoatsJson = localGoats.map((goat) => goat.toJson()).toList();

          final response = await apiService.syncGoats(localGoatsJson);

          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Goats: ${response.message}\n';
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Goats error: $e\n';
        debugPrint('❌ Goats sync error: $e');
      }

      // ========== 2. SYNC EVENTS ==========
      try {
        final localEvents = await localStorage.getEvents();
        debugPrint('🔄 [SYNC_DATA] Found ${localEvents.length} events in local storage');
        
        if (localEvents.isNotEmpty) {
          debugPrint('📋 [SYNC_DATA] Event details:');
          for (int i = 0; i < localEvents.length; i++) {
            final event = localEvents[i];
            debugPrint('   Event ${i + 1}: ${event.eventType} for ${event.tagNo}');
          }
        } else {
          debugPrint('⚠️ [SYNC_DATA] NO EVENTS FOUND!');
        }

        String? formatDate(dynamic date) {
          if (date == null) return null;

          if (date is DateTime) {
            return date.toIso8601String().split('T').first;
          }

          if (date is String) {
            try {
              final parsed = DateTime.parse(date);
              return parsed.toIso8601String().split('T').first;
            } catch (_) {
              return null;
            }
          }
          return null;
        }

        if (localEvents.isNotEmpty) {
          final localEventsJson = localEvents.map((event) {
            final eventJson = event.toJson();
            
            eventJson['date'] = formatDate(event.date) ?? 
                                formatDate(eventJson['date']) ?? 
                                eventJson['date'];
            
            debugPrint('📝 [SYNC_DATA] Event JSON: ${eventJson['tagNo']} - ${eventJson['date']}');
            return eventJson;
          }).toList();

          debugPrint('📤 [SYNC_DATA] Calling apiService.syncEvents()...');
          final response = await apiService.syncEvents(localEventsJson);
          
          debugPrint('📥 [SYNC_DATA] Events sync response: ${response.success} - ${response.message}');

          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Events: ${response.message}\n';
            debugPrint('❌ [SYNC_DATA] Events sync failed: ${response.message}');
          } else {
            debugPrint('✅ [SYNC_DATA] Events sync successful!');
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Events error: $e\n';
        debugPrint('❌ [SYNC_DATA] Events sync error: $e');
      }

      // ========== 3. SYNC MILK RECORDS ==========
      try {
        final localMilkRecords = await localStorage.getMilkRecords();
        debugPrint('🔄 Syncing ${localMilkRecords.length} milk records...');

        if (localMilkRecords.isNotEmpty) {
          // Convert to List<Map<String, dynamic>> for the API
          final milkRecordsJson = localMilkRecords.map((record) {
            return {
              'milking_date': record.formattedDate,
              'morning_quantity': record.morningQuantity,
              'evening_quantity': record.eveningQuantity,
              'total_quantity': record.total,
              'used_quantity': record.used,
              'notes': record.notes,
              'milk_type': record.milkType,
            };
          }).toList();

          debugPrint('📤 Calling apiService.syncMilkRecords()...');
          // If this still gives error, check the ApiService method signature
          final response = await apiService.syncMilkRecords(milkRecordsJson);
          
          debugPrint('📥 Milk sync response: ${response.success} - ${response.message}');

          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Milk Records: ${response.message}\n';
            debugPrint('❌ Milk records sync failed: ${response.message}');
          } else {
            debugPrint('✅ Milk records sync successful!');
          }
        } else {
          debugPrint('ℹ️ No milk records to sync');
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Milk Records error: $e\n';
        debugPrint('❌ Milk records sync error: $e');
      }

      // ========== 4. SYNC TRANSACTIONS ==========
      try {
        // Migrate old data first
       await localStorage.migrateAndConsolidateTransactions();
        
        final localTransactions = await localStorage.getTransactions();
        debugPrint('🔄 Syncing ${localTransactions.length} transactions...');

        if (localTransactions.isNotEmpty) {
       
        
       // Debug: Print transaction types
           final incomeCount = localTransactions.where((t) => t.type == TransactionType.income).length;
    final expenseCount = localTransactions.where((t) => t.type == TransactionType.expense).length;
          debugPrint('   - Incomes: ${incomeCount}');
          debugPrint('   - Expenses: ${expenseCount}');

          // Use the combined sync endpoint
          final response = await apiService.syncTransactions(localTransactions);
          
          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Transactions: ${response.message}\n';
            debugPrint('❌ Transactions sync failed: ${response.message}');
          } else {
            debugPrint('✅ Transactions sync successful!');
          }
        } else {
          debugPrint('ℹ️ No transactions to sync');
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Transactions error: $e\n';
        debugPrint('❌ Transactions sync error: $e');
      }

      await localStorage.setLastSyncTime(DateTime.now());

      return SyncResult(
        success: true,
        hasErrors: hasErrors,
        notAuthenticated: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      debugPrint('💥 Main sync error: $e');
      return SyncResult(
        success: false,
        hasErrors: true,
        notAuthenticated: false,
        errorMessage: e.toString(),
      );
    }
  }
}