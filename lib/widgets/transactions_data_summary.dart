import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class TransactionsDataSummary extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final double net;
  final List<Map<String, dynamic>>? incomeDetails;
  final List<Map<String, dynamic>>? expenseDetails;
  final DateTimeRange? dateRange;

  const TransactionsDataSummary({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    this.incomeDetails,
    this.expenseDetails,
    this.dateRange,
  });

  @override
  State<TransactionsDataSummary> createState() => _TransactionsDataSummaryState();
}

class _TransactionsDataSummaryState extends State<TransactionsDataSummary> {
  DateTimeRange? _selectedDateRange;
  double _currentTotalIncome = 0.0;
  double _currentTotalExpense = 0.0;
  double _currentNet = 0.0;
  List<Map<String, dynamic>> _currentIncomeDetails = [];
  List<Map<String, dynamic>> _currentExpenseDetails = [];
  List<Map<String, dynamic>> _allIncomes = [];
  List<Map<String, dynamic>> _allExpenses = [];
  bool _isLoading = true;
  
  // Store original data from parent
  late double _originalTotalIncome;
  late double _originalTotalExpense;
  late double _originalNet;
  late List<Map<String, dynamic>> _originalIncomeDetails;
  late List<Map<String, dynamic>> _originalExpenseDetails;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.dateRange;
    
    // Store original data from parent
    _originalIncomeDetails = List.from(widget.incomeDetails ?? []);
    _originalExpenseDetails = List.from(widget.expenseDetails ?? []);
    _originalTotalIncome = widget.totalIncome;
    _originalTotalExpense = widget.totalExpense;
    _originalNet = widget.net;
    
    // Set current data to original data
    _currentIncomeDetails = List.from(_originalIncomeDetails);
    _currentExpenseDetails = List.from(_originalExpenseDetails);
    _currentTotalIncome = _originalTotalIncome;
    _currentTotalExpense = _originalTotalExpense;
    _currentNet = _originalNet;
    
    debugPrint('=== TRANSACTIONS SUMMARY INIT ===');
    debugPrint('Parent data received:');
    debugPrint('  Total Income: $_originalTotalIncome');
    debugPrint('  Total Expense: $_originalTotalExpense');
    debugPrint('  Net: $_originalNet');
    debugPrint('  Income details: ${_originalIncomeDetails.length}');
    debugPrint('  Expense details: ${_originalExpenseDetails.length}');
    debugPrint('  Date range: $_selectedDateRange');
    
    // Start loading all transactions
    _loadAllTransactions();
  }

  Future<void> _loadAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final incomesStr = prefs.getString('saved_incomes');
      final expensesStr = prefs.getString('saved_expenses');
      
      debugPrint('=== TRANSACTIONS SUMMARY DEBUG ===');
      debugPrint('Loading transactions from SharedPreferences...');
      debugPrint('Incomes key exists: ${incomesStr != null}');
      debugPrint('Expenses key exists: ${expensesStr != null}');
      
      if (incomesStr != null && incomesStr.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(incomesStr);
          _allIncomes = [];
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              _allIncomes.add(Map<String, dynamic>.from(item));
            }
          }
          debugPrint('Successfully loaded ${_allIncomes.length} incomes');
        } catch (e) {
          debugPrint('Error parsing incomes: $e');
          debugPrint('Incomes string content: ${incomesStr.substring(0, incomesStr.length > 100 ? 100 : incomesStr.length)}');
        }
      } else {
        debugPrint('No incomes string or empty string');
      }
      
      if (expensesStr != null && expensesStr.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(expensesStr);
          _allExpenses = [];
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              _allExpenses.add(Map<String, dynamic>.from(item));
            }
          }
          debugPrint('Successfully loaded ${_allExpenses.length} expenses');
        } catch (e) {
          debugPrint('Error parsing expenses: $e');
          debugPrint('Expenses string content: ${expensesStr.substring(0, expensesStr.length > 100 ? 100 : expensesStr.length)}');
        }
      } else {
        debugPrint('No expenses string or empty string');
      }
      
      debugPrint('Total loaded: ${_allIncomes.length} incomes, ${_allExpenses.length} expenses');
      
    } catch (e) {
      debugPrint('Error in _loadAllTransactions: $e');
      debugPrint('Stack trace: ${e.toString()}');
    }
    
    // CRITICAL: Always set loading to false
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            debugPrint('Loading set to false. Current data:');
            debugPrint('Original income details: ${_originalIncomeDetails.length}');
            debugPrint('Original expense details: ${_originalExpenseDetails.length}');
            debugPrint('Current income details: ${_currentIncomeDetails.length}');
            debugPrint('Current expense details: ${_currentExpenseDetails.length}');
            debugPrint('Current total income: $_currentTotalIncome');
            debugPrint('Current total expense: $_currentTotalExpense');
            debugPrint('Current net: $_currentNet');
          });
        }
      });
    }
  }

  void _filterData() {
    debugPrint('Filtering data. Date range: $_selectedDateRange');
    debugPrint('All incomes: ${_allIncomes.length}, All expenses: ${_allExpenses.length}');
    
    // If no date range selected, reset to original data
    if (_selectedDateRange == null) {
      debugPrint('No date range selected, resetting to original data');
      setState(() {
        _currentIncomeDetails = List.from(_originalIncomeDetails);
        _currentExpenseDetails = List.from(_originalExpenseDetails);
        _currentTotalIncome = _originalTotalIncome;
        _currentTotalExpense = _originalTotalExpense;
        _currentNet = _originalNet;
      });
    } else {
      debugPrint('Filtering with date range: ${_selectedDateRange!.start} to ${_selectedDateRange!.end}');
      
      // Filter from ALL transactions based on selected date range
      final filteredIncomes = _allIncomes.where((item) {
        final dateStr = item['date']?.toString() ?? '';
        if (dateStr.isEmpty) {
          debugPrint('Empty date string for income item: $item');
          return false;
        }
        
        try {
          final date = DateTime.parse(dateStr);
          final isInRange = date.isAtSameMomentAs(_selectedDateRange!.start) ||
                 (date.isAfter(_selectedDateRange!.start) && date.isBefore(_selectedDateRange!.end)) ||
                 date.isAtSameMomentAs(_selectedDateRange!.end);
          return isInRange;
        } catch (e) {
          debugPrint('Error parsing date in filter: $e for date string: $dateStr');
          return false;
        }
      }).toList();

      final filteredExpenses = _allExpenses.where((item) {
        final dateStr = item['date']?.toString() ?? '';
        if (dateStr.isEmpty) {
          debugPrint('Empty date string for expense item: $item');
          return false;
        }
        
        try {
          final date = DateTime.parse(dateStr);
          final isInRange = date.isAtSameMomentAs(_selectedDateRange!.start) ||
                 (date.isAfter(_selectedDateRange!.start) && date.isBefore(_selectedDateRange!.end)) ||
                 date.isAtSameMomentAs(_selectedDateRange!.end);
          return isInRange;
        } catch (e) {
          debugPrint('Error parsing date in filter: $e for date string: $dateStr');
          return false;
        }
      }).toList();

      debugPrint('Filtered ${filteredIncomes.length} incomes, ${filteredExpenses.length} expenses');

      // Calculate totals from filtered data
      final filteredTotalIncome = filteredIncomes.fold(0.0, (sum, item) {
        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        return sum + amount;
      });

      final filteredTotalExpense = filteredExpenses.fold(0.0, (sum, item) {
        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        return sum + amount;
      });

      final filteredNet = filteredTotalIncome - filteredTotalExpense;

      debugPrint('Filtered totals - Income: $filteredTotalIncome, Expense: $filteredTotalExpense, Net: $filteredNet');

      setState(() {
        _currentIncomeDetails = filteredIncomes;
        _currentExpenseDetails = filteredExpenses;
        _currentTotalIncome = filteredTotalIncome;
        _currentTotalExpense = filteredTotalExpense;
        _currentNet = filteredNet;
      });
    }
  }

  void _clearFilter() {
    debugPrint('Clearing filter');
    setState(() {
      _selectedDateRange = null;
      // Reset to original data
      _currentIncomeDetails = List.from(_originalIncomeDetails);
      _currentExpenseDetails = List.from(_originalExpenseDetails);
      _currentTotalIncome = _originalTotalIncome;
      _currentTotalExpense = _originalTotalExpense;
      _currentNet = _originalNet;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Filter cleared'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showDateFilterDialog(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _filterData(); // Re-filter data with new date range
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filter applied: ${_formatDate(picked.start)} to ${_formatDate(picked.end)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _generatePDF(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pw.ImageProvider? goatImage;
      
      try {
        final data = await rootBundle.load('assets/images/goat.png');
        final bytes = data.buffer.asUint8List();
        goatImage = pw.MemoryImage(bytes);
      } catch (_) {
        goatImage = null;
      }
      
      final incomeByCategory = _groupByCategory(_currentIncomeDetails);
      final expenseByCategory = _groupByCategory(_currentExpenseDetails);
      
      final headerStyle = pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );
      
      final subtitleStyle = pw.TextStyle(
        fontSize: 12,
        color: PdfColors.grey600,
      );
      
      final sectionHeaderStyle = pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromInt(0xFF4CAF50),
      );
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (goatImage != null)
                      pw.Image(goatImage, width: 50, height: 50),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Financial Data Summary',
                            style: headerStyle,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Detailed Analysis Report',
                            style: subtitleStyle,
                          ),
                          if (_selectedDateRange != null)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                'Date Range: ${_formatDateForPDF(_selectedDateRange!.start)} to ${_formatDateForPDF(_selectedDateRange!.end)}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Generated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                          style: subtitleStyle,
                        ),
                        pw.Text(
                          'Time: ${DateFormat('HH:mm').format(DateTime.now())}',
                          style: subtitleStyle,
                        ),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 24),
                
                // Summary Metrics
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8F9FA),
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPDFMetricCard(
                        title: 'Total Income',
                        amount: _currentTotalIncome,
                        color: PdfColor.fromInt(0xFF4CAF50),
                      ),
                      pw.SizedBox(width: 12),
                      _buildPDFMetricCard(
                        title: 'Total Expenses',
                        amount: _currentTotalExpense,
                        color: PdfColor.fromInt(0xFFFF9800),
                      ),
                      pw.SizedBox(width: 12),
                      _buildPDFMetricCard(
                        title: _currentNet >= 0 ? 'Net Profit' : 'Net Loss',
                        amount: _currentNet.abs(),
                        color: _currentNet >= 0 ? PdfColor.fromInt(0xFF2E7D32) : PdfColor.fromInt(0xFFC62828),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 24),
                
                // Income Breakdown
                if (_currentIncomeDetails.isNotEmpty) ...[
                  pw.Text('Income Breakdown', style: sectionHeaderStyle),
                  pw.SizedBox(height: 12),
                  _buildCategoryPDFTable(incomeByCategory, _currentTotalIncome, Colors.green),
                  pw.SizedBox(height: 24),
                ],
                
                // Expense Breakdown
                if (_currentExpenseDetails.isNotEmpty) ...[
                  pw.Text('Expense Breakdown', style: sectionHeaderStyle.copyWith(
                    color: PdfColor.fromInt(0xFFFF9800),
                  )),
                  pw.SizedBox(height: 12),
                  _buildCategoryPDFTable(expenseByCategory, _currentTotalExpense, Colors.orange),
                  pw.SizedBox(height: 24),
                ],
                
                // Show message if no data
                if (_currentIncomeDetails.isEmpty && _currentExpenseDetails.isEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(40),
                    child: pw.Center(
                      child: pw.Text(
                        'No transactions found in selected date range',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 12),
                
                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Farm Management System - Data Summary',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Page 1 of 1',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPDFMetricCard({
    required String title,
    required double amount,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Rs. ${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildCategoryPDFTable(
    Map<String, double> categoryMap,
    double total,
    Color color,
  ) {
    if (categoryMap.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF5F5F5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Center(
          child: pw.Text(
            'No data available',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.TableHelper.fromTextArray(
        context: null,
        border: null,
        headerDecoration: pw.BoxDecoration(
          color: PdfColor.fromInt(color.value),
          borderRadius: const pw.BorderRadius.only(
            topLeft: pw.Radius.circular(8),
            topRight: pw.Radius.circular(8),
          ),
        ),
        headerStyle: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        cellStyle: pw.TextStyle(fontSize: 10),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerRight,
          2: pw.Alignment.centerRight,
        },
        headers: ['Category', 'Amount', 'Percentage'],
        data: sortedCategories.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0;
          return [
            entry.key,
            'Rs. ${entry.value.toStringAsFixed(2)}',
            '${percentage.toStringAsFixed(1)}%',
          ];
        }).toList(),
      ),
    );
  }

  String _formatDateForPDF(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          title: const Text('Data Summary', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.dataSummary,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Filter Icon
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showDateFilterDialog(context),
            tooltip: 'Filter by Date',
          ),
          // PDF Icon
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _generatePDF(context),
            tooltip: 'Generate PDF',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFF9800),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Loading financial data...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please wait while we load your transactions',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    debugPrint('=== BUILDING CONTENT ===');
    debugPrint('Current data:');
    debugPrint('Income details: ${_currentIncomeDetails.length} items');
    debugPrint('Expense details: ${_currentExpenseDetails.length} items');
    debugPrint('Total income: $_currentTotalIncome');
    debugPrint('Total expense: $_currentTotalExpense');
    debugPrint('Net: $_currentNet');
    
    try {
      final incomeByCategory = _groupByCategory(_currentIncomeDetails);
      final expenseByCategory = _groupByCategory(_currentExpenseDetails);
      
      return CustomScrollView(
        slivers: [
          // Date Range Display (only if date range is selected)
          if (_selectedDateRange != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDate(_selectedDateRange!.start)} to ${_formatDate(_selectedDateRange!.end)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.green.shade700),
                      onPressed: _clearFilter,
                    ),
                  ],
                ),
              ),
            ),
          
          // Show message if no data after filtering
          if (_currentIncomeDetails.isEmpty && _currentExpenseDetails.isEmpty && _selectedDateRange != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.orange.shade700),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are no transactions in the selected date range',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Show message if no data at all
          if (_currentIncomeDetails.isEmpty && _currentExpenseDetails.isEmpty && _selectedDateRange == null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.blue.shade700),
                    const SizedBox(height: 16),
                    Text(
                      'No transaction data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are no transactions to display. Try adding some income or expense records first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_currentIncomeDetails.isNotEmpty || _currentExpenseDetails.isNotEmpty) ...[
                  _buildSummaryCards(context),
                  const SizedBox(height: 24),
                ],
                
                if (_currentIncomeDetails.isNotEmpty) ...[
                  _buildSectionHeader('Income Breakdown', Colors.green.shade700),
                  const SizedBox(height: 12),
                  _buildCategoryBreakdown(incomeByCategory, Colors.green, _currentTotalIncome),
                  const SizedBox(height: 24),
                ],
                
                if (_currentExpenseDetails.isNotEmpty) ...[
                  _buildSectionHeader('Expense Breakdown', Colors.orange.shade700),
                  const SizedBox(height: 12),
                  _buildCategoryBreakdown(expenseByCategory, Colors.orange, _currentTotalExpense),
                  const SizedBox(height: 24),
                ],
                
                if (_currentIncomeDetails.isNotEmpty || _currentExpenseDetails.isNotEmpty) ...[
                  _buildNetAnalysis(context),
                  const SizedBox(height: 24),
                  
                  _buildInsights(context),
                  const SizedBox(height: 40),
                ],
              ]),
            ),
          ),
        ],
      );
    } catch (e, stackTrace) {
      debugPrint('Error building TransactionsDataSummary: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Unable to load financial summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Error: ${e.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Income',
            amount: _currentTotalIncome,
            color: const Color(0xFF4CAF50),
            icon: Icons.arrow_upward,
            percentage: _currentTotalIncome > 0 && _currentTotalExpense > 0 
                ? (_currentTotalIncome / (_currentTotalIncome + _currentTotalExpense) * 100)
                : 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Expenses',
            amount: _currentTotalExpense,
            color: Colors.orange,
            icon: Icons.arrow_downward,
            percentage: _currentTotalExpense > 0 && _currentTotalIncome > 0
                ? (_currentTotalExpense / (_currentTotalIncome + _currentTotalExpense) * 100)
                : 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: _currentNet >= 0 ? 'Net Profit' : 'Net Loss',
            amount: _currentNet.abs(),
            color: _currentNet >= 0 ? Colors.green.shade700 : Colors.red,
            icon: _currentNet >= 0 ? Icons.trending_up : Icons.trending_down,
            percentage: _currentTotalIncome > 0 ? (_currentNet / _currentTotalIncome * 100).abs() : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required double percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
    Map<String, double> categoryMap,
    Color color,
    double total,
  ) {
    if (categoryMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...sortedCategories.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0;
            return _buildCategoryItem(
              category: entry.key,
              amount: entry.value,
              percentage: percentage.toDouble(),
              color: color,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    final percentageInt = percentage.round();
    final remainingPercentage = 100 - percentageInt;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${_formatAmount(amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: percentageInt,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: remainingPercentage,
                      child: const SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetAnalysis(BuildContext context) {
    final savingsRate = _currentTotalIncome > 0 ? (_currentNet / _currentTotalIncome * 100) : 0;
    final expenseRate = _currentTotalIncome > 0 ? (_currentTotalExpense / _currentTotalIncome * 100) : 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Financial Health Analysis', Colors.blue.shade700),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalysisItem(
                label: 'Savings Rate',
                value: '${savingsRate.toStringAsFixed(1)}%',
                icon: Icons.savings,
                color: savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red,
              ),
              _buildAnalysisItem(
                label: 'Expense Ratio',
                value: '${expenseRate.toStringAsFixed(1)}%',
                icon: Icons.pie_chart,
                color: expenseRate <= 80 ? Colors.green : expenseRate <= 90 ? Colors.orange : Colors.red,
              ),
              _buildAnalysisItem(
                label: 'Profit Margin',
                value: '${(_currentNet >= 0 ? savingsRate : savingsRate.abs()).toStringAsFixed(1)}%',
                icon: _currentNet >= 0 ? Icons.trending_up : Icons.trending_down,
                color: _currentNet >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(BuildContext context) {
    final insights = <String>[];
    
    if (_currentNet > 0) {
      insights.add('You are operating at a profit. Great work!');
    } else if (_currentNet < 0) {
      insights.add('Expenses are exceeding income. Consider reviewing costs.');
    }
    
    if (_currentTotalIncome > 0 && _currentTotalExpense / _currentTotalIncome > 0.9) {
      insights.add('Expense ratio is high. Look for cost-saving opportunities.');
    }
    
    if (_currentTotalIncome > 0 && _currentNet / _currentTotalIncome > 0.3) {
      insights.add('Strong profit margin indicates efficient operations.');
    }
    
    if (insights.isEmpty) {
      insights.add('Add more transactions to get personalized insights.');
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Insights & Recommendations', Colors.purple.shade700),
          const SizedBox(height: 16),
          
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Map<String, double> _groupByCategory(List<Map<String, dynamic>> transactions) {
    final Map<String, double> result = {};
    
    try {
      for (var transaction in transactions) {
        final category = transaction['category']?.toString() ?? 
                        transaction['type']?.toString() ?? 'Uncategorized';
        final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
        
        result[category] = (result[category] ?? 0.0) + amount;
      }
    } catch (e) {
      debugPrint('Error in _groupByCategory: $e');
    }
    
    return result;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}