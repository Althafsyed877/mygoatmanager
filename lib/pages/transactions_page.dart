// lib/pages/transactions/transactions_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import 'add_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  int _selectedTab = 0; // 0 for Income, 1 for Expenses
  final TextEditingController _searchController = TextEditingController();
  List<Transaction> _transactions = [];
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  String _selectedDateRangeFilter = 'Current Month';
  String? _selectedCategoryFilter;
  String? _selectedSubCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }
  
Future<void> _loadTransactions() async {
  final prefs = await SharedPreferences.getInstance();
  final transactionsJson = prefs.getString('transactions') ?? '[]';
  
  print('=== LOADING TRANSACTIONS ===');
  print('JSON length: ${transactionsJson.length} chars');
  
  try {
    final List<dynamic> jsonList = jsonDecode(transactionsJson);
    print('Found ${jsonList.length} JSON entries');
    
    List<Transaction> loadedTransactions = [];
    
    for (var i = 0; i < jsonList.length; i++) {
      try {
        final json = jsonList[i];
        print('\n--- Parsing transaction $i ---');
        
        // Check the raw JSON structure
        if (json is Map<String, dynamic>) {
          print('Raw JSON keys: ${json.keys.toList()}');
          print('Type field value: ${json['type']}');
          print('Kind field value: ${json['kind']}');
          print('Category: ${json['category']}');
        }
        
        final transaction = Transaction.fromJson(Map<String, dynamic>.from(json));
        loadedTransactions.add(transaction);
        
        print('✅ Successfully parsed:');
        print('   Type: ${transaction.type == TransactionType.income ? "INCOME" : "EXPENSE"}');
        print('   Category: ${transaction.category}');
        print('   Amount: ${transaction.amount}');
        print('   Date: ${transaction.transactionDate}');
        
      } catch (e, stack) {
        print('❌ Error parsing transaction $i: $e');
        print('Stack trace: $stack');
      }
    }
    
    // Sort by date (newest first)
    loadedTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    
    setState(() {
      _transactions = loadedTransactions;
    });
    
    print('\n=== LOAD SUMMARY ===');
    print('Total transactions loaded: ${loadedTransactions.length}');
    
    final incomes = loadedTransactions.where((t) => t.type == TransactionType.income).toList();
    final expenses = loadedTransactions.where((t) => t.type == TransactionType.expense).toList();
    
    print('Income count: ${incomes.length}');
    print('Expense count: ${expenses.length}');
    
    // Debug: List all income transactions
    if (incomes.isEmpty) {
      print('⚠️ NO INCOME TRANSACTIONS FOUND!');
    } else {
      print('Income transactions:');
      for (var i = 0; i < incomes.length; i++) {
        final t = incomes[i];
        print('  $i: ${t.category} - ₹${t.amount} - ${t.transactionDate}');
      }
    }
    
    // Check if there are any issues with the loaded data
    if (loadedTransactions.isNotEmpty) {
      print('\nFirst transaction sample:');
      final first = loadedTransactions.first;
      print('  Type: ${first.type}');
      print('  Type enum value: ${first.type == TransactionType.income ? "TransactionType.income" : "TransactionType.expense"}');
      print('  Category: ${first.category}');
      print('  Amount: ${first.amount}');
    }
    
  } catch (e) {
    print('❌ Error loading transactions: $e');
    setState(() {
      _transactions = [];
    });
  }
}
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = jsonEncode(
      _transactions.map((t) => t.toJson()).toList()
    );
    await prefs.setString('transactions', transactionsJson);
  }

  Future<void> _deleteTransaction(Transaction transaction, int index) async {
    // Show confirmation dialog
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.delete),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _transactions.removeAt(index);
      });
      await _saveTransactions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.record_deleted)),
        );
      }
    }
  }

  Future<void> _debugStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final transactionsJson = prefs.getString('transactions') ?? '[]';
  final List<dynamic> jsonList = jsonDecode(transactionsJson);
  
  print('=== STORAGE DIAGNOSTIC ===');
  print('Total entries: ${jsonList.length}');
  
  for (var i = 0; i < jsonList.length; i++) {
    final entry = jsonList[i] as Map<String, dynamic>;
    print('--- Entry $i ---');
    print('Type field: ${entry['type']}');
    print('Kind field: ${entry['kind']}');
    print('Category: ${entry['category']}');
    print('Amount: ${entry['amount']}');
    print('Transaction Date: ${entry['transaction_date'] ?? entry['date']}');
  }
}

  Future<void> _editTransaction(Transaction transaction, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddTransactionPage(
          type: transaction.type,
          initialTransaction: transaction,
        ),
      ),
    );
    
    if (result != null && result is Transaction) {
      // Reload all transactions to get the updated list
      await _loadTransactions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transaction.type == TransactionType.income
                  ? AppLocalizations.of(context)!.income_updated
                  : AppLocalizations.of(context)!.expense_updated,
            ),
          ),
        );
      }
    }
  }

  void _showSearchDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.search_transactions),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: loc.search_by_description,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _searchController.clear();
                setState(() {});
              },
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(loc.search),
            ),
          ],
        );
      },
    );
  }

  List<Transaction> _getFilteredTransactions() {
    final searchQuery = _searchController.text.toLowerCase();
    final isIncomeTab = _selectedTab == 0;
    
    return _transactions.where((transaction) {
      // Filter by tab (income/expense)
      if (isIncomeTab && transaction.type != TransactionType.income) return false;
      if (!isIncomeTab && transaction.type != TransactionType.expense) return false;
      
      // Filter by date range
      if (_filterFromDate != null) {
        final fromDate = DateTime(_filterFromDate!.year, _filterFromDate!.month, _filterFromDate!.day);
        if (transaction.transactionDate.isBefore(fromDate)) {
          return false;
        }
      }
      
      if (_filterToDate != null) {
        final toDate = DateTime(_filterToDate!.year, _filterToDate!.month, _filterToDate!.day, 23, 59, 59);
        if (transaction.transactionDate.isAfter(toDate)) {
          return false;
        }
      }
      
      // Filter by category
      if (_selectedCategoryFilter != null && 
          transaction.category != _selectedCategoryFilter) {
        return false;
      }
      
      // Filter by sub-category
      if (_selectedSubCategoryFilter != null && 
          transaction.subCategory != _selectedSubCategoryFilter) {
        return false;
      }
      
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final matchesDescription = transaction.description?.toLowerCase().contains(searchQuery) ?? false;
        final matchesNotes = transaction.notes?.toLowerCase().contains(searchQuery) ?? false;
        final matchesContact = transaction.contactName?.toLowerCase().contains(searchQuery) ?? false;
        final matchesCategory = transaction.category?.toLowerCase().contains(searchQuery) ?? false;
        final matchesSubCategory = transaction.subCategory?.toLowerCase().contains(searchQuery) ?? false;
        
        if (!matchesDescription && !matchesNotes && !matchesContact && 
            !matchesCategory && !matchesSubCategory) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Widget _buildTransactionList(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final filteredTransactions = _getFilteredTransactions();
    
    if (filteredTransactions.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt, color: Color(0xFF9E9E9E), size: 48),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 0
                ? loc.no_income_to_display
                : loc.no_expenses_to_display,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
        ],
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.separated(
        itemCount: filteredTransactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          final originalIndex = _transactions.indexOf(transaction);
          
          return Card(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: transaction.type == TransactionType.income 
                          ? Colors.green 
                          : Colors.orange,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.displayTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (transaction.description != null && transaction.description!.isNotEmpty)
                            Text(
                              transaction.description!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.displayDate,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${transaction.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: transaction.type == TransactionType.income 
                                ? Colors.green 
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: PopupMenuButton<String>(
                      color: Colors.white,
                      onSelected: (val) async {
                        if (val == 'delete') {
                          await _deleteTransaction(transaction, originalIndex);
                        } else if (val == 'edit') {
                          await _editTransaction(transaction, originalIndex);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(loc.edit_view_record),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(loc.delete),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        title: Text(
          loc.transactions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
          ),
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 24),
          ),
          IconButton(
            onPressed: () => _showMoreOptionsMenu(context),
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Income/Expenses Tabs
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 
                            ? const Color(0xFFFFA726) 
                            : Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        loc.income,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _selectedTab == 0 ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 
                            ? const Color(0xFFFFA726) 
                            : Colors.white,
                      ),
                      child: Text(
                        loc.expenses,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _selectedTab == 1 ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 16.0),
                child: Column(
                  children: [
                    // Transactions List
                    Expanded(
                      child: _buildTransactionList(context),
                    ),

                    // Add Button
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => AddTransactionPage(
                                  type: _selectedTab == 0 
                                      ? TransactionType.income 
                                      : TransactionType.expense,
                                ),
                              ),
                            );
                            
                            if (result != null && result is Transaction) {
                              // Reload transactions from storage
                              await _loadTransactions();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result.type == TransactionType.income
                                          ? loc.income_saved
                                          : loc.expense_saved,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA726),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTab == 0 ? loc.add_income : loc.add_expense,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter dialog and other dialogs remain similar but adapted for Transaction model
  void _showFilterDialog(BuildContext context) {
    // Similar to previous filter dialog but adapted for Transaction model
    // You can implement this similarly
  }

  void _showMoreOptionsMenu(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(loc.export_pdf),
                onTap: () {
                  Navigator.pop(context);
                  _exportPdf(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category, color: Colors.blue),
                title: Text(
                  _selectedTab == 0 
                      ? loc.filter_by_income_type 
                      : loc.filter_by_expense_type,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryFilter(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

 void _showCategoryFilter(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final categories = _getUniqueCategories();
  
  // Get the category display names for the dialog
  final Map<String, String> categoryDisplayNames = {
    'Milk Sale': loc.milk_sale,
    'Goat Sale': loc.goat_sale,
    'Manure Sale': 'Manure Sale',
    'Category Income': loc.category_income,
    'Other': 'Other',
    'Feed': 'Feed',
    'Medicine': 'Medicine',
    'Equipment': 'Equipment',
    'Labor': 'Labor',
    'Transport': 'Transport',
    'Utilities': 'Utilities',
    'Category Expense': loc.category_expense,
  };
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        _selectedTab == 0 
            ? loc.filter_by_income_type 
            : loc.filter_by_expense_type,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                title: Text(loc.all_types),
                trailing: _selectedCategoryFilter == null 
                    ? const Icon(Icons.check, color: Colors.green) 
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = null;
                    _selectedSubCategoryFilter = null;
                  });
                  Navigator.pop(ctx);
                },
              );
            }
            
            final category = categories[index - 1];
            final displayName = categoryDisplayNames[category] ?? category;
            final isSelected = _selectedCategoryFilter == category;
            
            return ListTile(
              title: Text(displayName),
              trailing: isSelected 
                  ? Icon(
                      _selectedTab == 0 ? Icons.check : Icons.check,
                      color: _selectedTab == 0 ? Colors.green : Colors.orange,
                    ) 
                  : null,
              onTap: () {
                setState(() {
                  _selectedCategoryFilter = category;
                  _selectedSubCategoryFilter = null;
                });
                Navigator.pop(ctx);
              },
            );
          },
        ),
      ),
    ),
  );
}

  List<String> _getUniqueCategories() {
    final isIncome = _selectedTab == 0;
    final categorySet = <String>{};
    
    for (final transaction in _transactions) {
      if ((isIncome && transaction.type == TransactionType.income) ||
          (!isIncome && transaction.type == TransactionType.expense)) {
        if (transaction.category != null) {
          categorySet.add(transaction.category!);
        }
      }
    }
    
    return categorySet.toList();
  }

  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();
    final filteredTransactions = _getFilteredTransactions();
    final isIncome = _selectedTab == 0;
    
    pw.Widget? headerImage;
    try {
      final data = await rootBundle.load('assets/images/goat.png');
      final bytes = data.buffer.asUint8List();
      final img = pw.MemoryImage(bytes);
      headerImage = pw.Center(child: pw.Image(img, width: 80, height: 80));
    } catch (e) {
      headerImage = null;
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final List<pw.Widget> children = [];
          
          if (headerImage != null) {
            children.add(headerImage!);
            children.add(pw.SizedBox(height: 8));
          }
          
          children.add(
            pw.Center(
              child: pw.Text(
                isIncome ? 'Income Records' : 'Expense Records',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          
          children.add(pw.SizedBox(height: 6));
          children.add(
            pw.Text(
              'Generated: ${DateTime.now().toLocal()}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          );
          children.add(pw.SizedBox(height: 12));
          
          if (filteredTransactions.isEmpty) {
            children.add(pw.Center(child: pw.Text('No records found')));
          } else {
            children.add(
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                ),
                padding: const pw.EdgeInsets.all(6),
                child: pw.TableHelper.fromTextArray(
                  headers: isIncome
                      ? ['Date', 'Category', 'Description', 'Quantity', 'Price', 'Amount', 'Buyer', 'Notes']
                      : ['Date', 'Category', 'Description', 'Quantity', 'Amount', 'Vendor', 'Notes'],
                  data: filteredTransactions.map((t) {
                    if (isIncome) {
                      return [
                        t.displayDate,
                        t.category ?? '',
                        t.description ?? '',
                        t.quantity?.toString() ?? '',
                        t.pricePerUnit?.toString() ?? '',
                        '₹${t.amount.toStringAsFixed(2)}',
                        t.contactName ?? '',
                        t.notes ?? '',
                      ];
                    } else {
                      return [
                        t.displayDate,
                        t.category ?? '',
                        t.description ?? '',
                        t.quantity?.toString() ?? '',
                        '₹${t.amount.toStringAsFixed(2)}',
                        t.contactName ?? '',
                        t.notes ?? '',
                      ];
                    }
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: isIncome ? PdfColors.green : PdfColors.orange,
                  ),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                ),
              ),
            );
          }
          
          return children;
        },
      ),
    );
    
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${isIncome ? 'income' : 'expense'}_${DateTime.now().toIso8601String()}.pdf',
    );
  }
}