import 'package:flutter/material.dart';
import 'package:mygoatmanager/services/api_service.dart';
import 'package:mygoatmanager/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

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
        debugPrint('🔄 Syncing ${localEvents.length} events...');

        String? formatDate(dynamic date) {
          if (date == null) return null;

          if (date is DateTime) {
            return date.toIso8601String().split('T').first; // Returns YYYY-MM-DD
          }

          if (date is String) {
            try {
              final parsed = DateTime.parse(date);
              return parsed.toIso8601String().split('T').first; // Returns YYYY-MM-DD
            } catch (_) {
              return null;
            }
          }
          return null;
        }

        if (localEvents.isNotEmpty) {
          final localEventsJson = localEvents.map((event) {
            // Get the original JSON
            final eventJson = event.toJson();
            
            // Format the date field to YYYY-MM-DD
            eventJson['date'] = formatDate(event.date) ?? 
                                formatDate(eventJson['date']) ?? 
                                eventJson['date'];
            
            return eventJson;
          }).toList();

          final response = await apiService.syncEvents(localEventsJson);

          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Events: ${response.message}\n';
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Events error: $e\n';
        debugPrint('❌ Events sync error: $e');
      }

      // ========== 3. SYNC MILK RECORDS ==========
      try {
        final localMilkRecords = await localStorage.getMilkRecords();
        debugPrint('🔄 Syncing ${localMilkRecords.length} milk records...');

        if (localMilkRecords.isNotEmpty) {
          final fixedMilkRecords = localMilkRecords.map((record) {
            final fixed = Map<String, dynamic>.from(record);

            if (fixed['milking_date'] != null) {
              final dateStr = fixed['milking_date'].toString();
              if (dateStr.contains('/')) {
                final parts = dateStr.split('/');
                if (parts.length == 3) {
                  fixed['milking_date'] =
                      '${parts[2]}-${parts[1]}-${parts[0]}';
                }
              }
            }

            if (fixed['goat_id'] != null) {
              fixed['goat_id'] = fixed['goat_id'].toString();
            }

            return fixed;
          }).toList();

          final response =
              await apiService.syncMilkRecords(fixedMilkRecords);

          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Milk: ${response.message}\n';
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Milk error: $e\n';
        debugPrint('❌ Milk sync error: $e');
      }

      // ========== 4. SYNC TRANSACTIONS ==========
      try {
        final localIncomes = await localStorage.getIncomes();
        final localExpenses = await localStorage.getExpenses();

        debugPrint(
          '🔄 Syncing ${localIncomes.length} incomes, ${localExpenses.length} expenses...',
        );

        if (localIncomes.isNotEmpty || localExpenses.isNotEmpty) {
          final fixedIncomes = localIncomes.map((income) {
            final fixed = Map<String, dynamic>.from(income);

            if (fixed['transaction_date'] != null) {
              final dateStr = fixed['transaction_date'].toString();
              if (dateStr.contains('/')) {
                final parts = dateStr.split('/');
                if (parts.length == 3) {
                  fixed['transaction_date'] =
                      '${parts[2]}-${parts[1]}-${parts[0]}';
                }
              }
            }

            fixed['income_type'] ??= 'Other';
            return fixed;
          }).toList();

          final fixedExpenses = localExpenses.map((expense) {
            final fixed = Map<String, dynamic>.from(expense);

            if (fixed['transaction_date'] != null) {
              final dateStr = fixed['transaction_date'].toString();
              if (dateStr.contains('/')) {
                final parts = dateStr.split('/');
                if (parts.length == 3) {
                  fixed['transaction_date'] =
                      '${parts[2]}-${parts[1]}-${parts[0]}';
                }
              }
            }

            fixed['expense_type'] ??= 'Other';
            return fixed;
          }).toList();

          final response = await apiService.syncTransactions(
            fixedIncomes,
            fixedExpenses,
          );

          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Transactions: ${response.message}\n';
          }
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
