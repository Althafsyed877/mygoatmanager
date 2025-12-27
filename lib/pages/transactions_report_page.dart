import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../widgets/transactions_line_chart.dart';
import '../widgets/transactions_data_summary.dart';
import '../l10n/app_localizations.dart';

class TransactionsReportPage extends StatefulWidget {
  const TransactionsReportPage({super.key});

  @override
  State<TransactionsReportPage> createState() => _TransactionsReportPageState();
}

class _TransactionsReportPageState extends State<TransactionsReportPage> {
  DateTimeRange? _selectedRange;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  final List<Map<String, dynamic>> _incomes = [];
  final List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final incomesStr = prefs.getString('saved_incomes');
    final expensesStr = prefs.getString('saved_expenses');
    double incomeSum = 0.0;
    double expenseSum = 0.0;
    final List<Map<String, dynamic>> incomes = [];
    final List<Map<String, dynamic>> expenses = [];
    
    if (incomesStr != null) {
      try {
        final List<dynamic> list = jsonDecode(incomesStr);
        for (var item in list) {
          final amt = double.tryParse((item['amount'] ?? '').toString()) ?? 0.0;
          incomeSum += amt;
          incomes.add(Map<String, dynamic>.from(item));
        }
      } catch (_) {}
    }
    
    if (expensesStr != null) {
      try {
        final List<dynamic> list = jsonDecode(expensesStr);
        for (var item in list) {
          final amt = double.tryParse((item['amount'] ?? '').toString()) ?? 0.0;
          expenseSum += amt;
          expenses.add(Map<String, dynamic>.from(item));
        }
      } catch (_) {}
    }
    
    setState(() {
      totalIncome = incomeSum;
      totalExpense = expenseSum;
      _incomes.clear();
      _incomes.addAll(incomes);
      _expenses.clear();
      _expenses.addAll(expenses);
    });
  }

  // PDF generation and preview with improved styling
  Future<void> _generateAndPreviewPDF() async {
    // Filter data for PDF based on selected range
    List<Map<String, dynamic>> filteredIncomes = _incomes;
    List<Map<String, dynamic>> filteredExpenses = _expenses;
    
    if (_selectedRange != null) {
      filteredIncomes = _incomes.where((item) {
        final dateStr = item['date'] ?? '';
        final date = DateTime.tryParse(dateStr);
        return date != null && 
               date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) && 
               date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
      }).toList();
      
      filteredExpenses = _expenses.where((item) {
        final dateStr = item['date'] ?? '';
        final date = DateTime.tryParse(dateStr);
        return date != null && 
               date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) && 
               date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    final double pdfTotalIncome = filteredIncomes.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
    final double pdfTotalExpense = filteredExpenses.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
    final double net = pdfTotalIncome - pdfTotalExpense;
    final double profitPercentage = pdfTotalIncome > 0 ? (net / pdfTotalIncome) * 100 : 0.0;
    
    final pdf = pw.Document();
    pw.ImageProvider? goatImage;
    
    try {
      final data = await rootBundle.load('assets/images/goat.png');
      final bytes = data.buffer.asUint8List();
      goatImage = pw.MemoryImage(bytes);
    } catch (_) {
      goatImage = null;
    }
    
    // Helper function to create colors with opacity for PDF
    PdfColor createPdfColorWithOpacity(PdfColor color, double opacity) {
      return PdfColor(
        color.red / 255.0,
        color.green / 255.0,
        color.blue / 255.0,
        opacity,
      );
    }
    
    // Custom styles
    final headerStyle = pw.TextStyle(
      fontSize: 28,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    
    final subtitleStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColors.grey600,
    );
    
    final sectionHeaderStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromInt(0xFF4CAF50), // Green color
    );
    
    final metricValueStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );
    
    final metricLabelStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColors.grey700,
    );
    
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    
    final tableCellStyle = pw.TextStyle(
      fontSize: 10,
    );
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (goatImage != null)
                    pw.Image(goatImage, width: 60, height: 60),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Farm Financial Report',
                          style: headerStyle,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Transaction Analysis & Summary',
                          style: subtitleStyle,
                        ),
                        if (_selectedRange != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              'Date Range: ${_selectedRange!.start.toLocal().toString().split(' ')[0]} to ${_selectedRange!.end.toLocal().toString().split(' ')[0]}',
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
                        'Generated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                        style: subtitleStyle,
                      ),
                      pw.Text(
                        'Time: ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}',
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 24),
              
              // Summary Metrics in modern cards
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8F9FA), // Light grey background
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Income Card
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        ),
                        padding: const pw.EdgeInsets.all(16),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              '₹${pdfTotalIncome.toStringAsFixed(2)}',
                              style: metricValueStyle.copyWith(
                                color: PdfColor.fromInt(0xFF4CAF50), // Green
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Total Income',
                              style: metricLabelStyle,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              height: 4,
                              width: 40,
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFF4CAF50),
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    pw.SizedBox(width: 16),
                    
                    // Expense Card
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        ),
                        padding: const pw.EdgeInsets.all(16),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              '₹${pdfTotalExpense.toStringAsFixed(2)}',
                              style: metricValueStyle.copyWith(
                                color: PdfColor.fromInt(0xFFFF9800), // Orange
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Total Expenses',
                              style: metricLabelStyle,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              height: 4,
                              width: 40,
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFFF9800),
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    pw.SizedBox(width: 16),
                    
                    // Net Profit Card
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: net >= 0 
                              ? PdfColor.fromInt(0xFFE8F5E9) // Light green for profit
                              : PdfColor.fromInt(0xFFFFEBEE), // Light red for loss
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(
                            color: net >= 0 
                                ? createPdfColorWithOpacity(PdfColor.fromInt(0xFF4CAF50), 0.3)
                                : createPdfColorWithOpacity(PdfColor.fromInt(0xFFF44336), 0.3),
                            width: 1,
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(16),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              '₹${net.toStringAsFixed(2)}',
                              style: metricValueStyle.copyWith(
                                color: net >= 0 
                                    ? PdfColor.fromInt(0xFF2E7D32) // Dark green for profit
                                    : PdfColor.fromInt(0xFFC62828), // Dark red for loss
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              net >= 0 ? 'Net Profit' : 'Net Loss',
                              style: metricLabelStyle,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${profitPercentage.toStringAsFixed(1)}% ${net >= 0 ? 'profit' : 'loss'}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: net >= 0 ? PdfColors.green : PdfColors.red,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 32),
              
              // Income Transactions Table
              pw.Text('Income Transactions', style: sectionHeaderStyle),
              pw.SizedBox(height: 12),
              
              if (filteredIncomes.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF5F5F5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No income transactions in selected period',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.TableHelper.fromTextArray(
                    context: context,
                    border: null,
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF4CAF50), // Green header
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(8),
                        topRight: pw.Radius.circular(8),
                      ),
                    ),
                    headerStyle: tableHeaderStyle,
                    cellStyle: tableCellStyle,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerLeft,
                    },
                    headers: ['Date', 'Source', 'Quantity', 'Amount', 'Notes'],
                    data: filteredIncomes.map((item) {
                      final date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
                      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final type = item['type']?.toString() ?? '';
                      final qty = item['quantity']?.toString() ?? '-';
                      final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                      final notes = item['notes']?.toString() ?? '';
                      
                      return [
                        dateStr,
                        type,
                        qty,
                        '₹${amount.toStringAsFixed(2)}',
                        notes.length > 30 ? '${notes.substring(0, 30)}...' : notes,
                      ];
                    }).toList(),
                  ),
                ),
              
              pw.SizedBox(height: 32),
              
              // Expense Transactions Table
              pw.Text('Expense Transactions', style: sectionHeaderStyle.copyWith(
                color: PdfColor.fromInt(0xFFFF9800), // Orange color
              )),
              pw.SizedBox(height: 12),
              
              if (filteredExpenses.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF5F5F5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No expense transactions in selected period',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.TableHelper.fromTextArray(
                    context: context,
                    border: null,
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFF9800), // Orange header
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(8),
                        topRight: pw.Radius.circular(8),
                      ),
                    ),
                    headerStyle: tableHeaderStyle,
                    cellStyle: tableCellStyle,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerLeft,
                    },
                    headers: ['Date', 'Category/Type', 'Quantity', 'Amount', 'Notes'],
                    data: filteredExpenses.map((item) {
                      final date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
                      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final type = item['type']?.toString() ?? '';
                      final qty = item['quantity']?.toString() ?? '-';
                      final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                      final notes = item['notes']?.toString() ?? '';
                      
                      return [
                        dateStr,
                        type,
                        qty,
                        '₹${amount.toStringAsFixed(2)}',
                        notes.length > 30 ? '${notes.substring(0, 30)}...' : notes,
                      ];
                    }).toList(),
                  ),
                ),
              
              pw.SizedBox(height: 32),
              
              // Footer with summary
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8F9FA),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Summary',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Total Income: ₹${pdfTotalIncome.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.green,
                          ),
                        ),
                        pw.Text(
                          'Total Expenses: ₹${pdfTotalExpense.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.orange,
                          ),
                        ),
                        pw.Text(
                          'Net ${net >= 0 ? 'Profit' : 'Loss'}: ₹${net.abs().toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: net >= 0 ? PdfColors.green : PdfColors.red,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: net >= 0 ? PdfColors.green : PdfColors.red,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        net >= 0 ? 'PROFITABLE' : 'IN LOSS',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Page footer
              pw.Container(
                height: 1,
                color: PdfColors.grey300,
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Farm Management System',
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
  }

  // Date range filter dialog
  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  // Helper method to prepare chart data
  List<FlSpot> _prepareIncomeChartData(List<Map<String, dynamic>> incomes) {
    // Group by date and sum amounts
    final Map<String, double> dailyIncome = {};
    
    for (var income in incomes) {
      final dateStr = income['date']?.toString() ?? '';
      if (dateStr.isNotEmpty) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final amount = double.tryParse(income['amount']?.toString() ?? '0') ?? 0.0;
          dailyIncome[dateKey] = (dailyIncome[dateKey] ?? 0.0) + amount;
        }
      }
    }
    
    // Convert to sorted list for chart
    final sortedDates = dailyIncome.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      final idx = entry.key;
      final dateKey = entry.value;
      return FlSpot(idx.toDouble(), dailyIncome[dateKey]!);
    }).toList();
  }

  List<FlSpot> _prepareExpenseChartData(List<Map<String, dynamic>> expenses) {
    // Group by date and sum amounts
    final Map<String, double> dailyExpense = {};
    
    for (var expense in expenses) {
      final dateStr = expense['date']?.toString() ?? '';
      if (dateStr.isNotEmpty) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
          dailyExpense[dateKey] = (dailyExpense[dateKey] ?? 0.0) + amount;
        }
      }
    }
    
    // Convert to sorted list for chart
    final sortedDates = dailyExpense.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      final idx = entry.key;
      final dateKey = entry.value;
      return FlSpot(idx.toDouble(), dailyExpense[dateKey]!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Filter incomes and expenses by selected date range
    List<Map<String, dynamic>> filteredIncomes = _incomes;
    List<Map<String, dynamic>> filteredExpenses = _expenses;
    
    if (_selectedRange != null) {
      filteredIncomes = _incomes.where((item) {
        final dateStr = item['date'] ?? '';
        final date = DateTime.tryParse(dateStr);
        return date != null && 
               date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) && 
               date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
      }).toList();
      
      filteredExpenses = _expenses.where((item) {
        final dateStr = item['date'] ?? '';
        final date = DateTime.tryParse(dateStr);
        return date != null && 
               date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) && 
               date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    final double net = filteredIncomes.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0)) - 
                      filteredExpenses.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
    final double currentTotalIncome = filteredIncomes.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
    final double currentTotalExpense = filteredExpenses.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
    
    final l10n = AppLocalizations.of(context)!;
    
    // Prepare chart data
    final incomeChartData = _prepareIncomeChartData(filteredIncomes);
    final expenseChartData = _prepareExpenseChartData(filteredExpenses);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.transactionsReport, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'PDF',
            onPressed: _generateAndPreviewPDF,
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            tooltip: 'Filter',
            onPressed: _showDateRangePicker,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(
            height: 4, 
            child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFFF9800)))
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Info
              if (_selectedRange != null)
                Container(
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
                          '${_selectedRange!.start.toLocal().toString().split(' ')[0]} to ${_selectedRange!.end.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: Colors.green.shade700),
                        onPressed: () {
                          setState(() {
                            _selectedRange = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              
              if (_selectedRange != null) const SizedBox(height: 12),
              
              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08), 
                      blurRadius: 8, 
                      offset: const Offset(0, 2)
                    )
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRange != null 
                        ? 'Selected Date Range'
                        : 'All Transactions',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: net >= 0
                              ? [Colors.green.shade100, Colors.green.shade300]
                              : [Colors.orange.shade100, Colors.orange.shade300],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, 
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '₹${net.toStringAsFixed(2)}', 
                                    textAlign: TextAlign.center, 
                                    style: TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold,
                                      color: net >= 0 ? Colors.green.shade800 : Colors.orange.shade800,
                                    ),
                                  ),
                                  Text(
                                    'Net ${net >= 0 ? 'Profit' : 'Loss'}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Income/Expense breakdown
                    _buildMetricRow(
                      label: 'Total Income',
                      value: '₹${currentTotalIncome.toStringAsFixed(2)}',
                      color: const Color(0xFF4CAF50),
                      icon: Icons.arrow_upward,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      label: 'Total Expenses',
                      value: '₹${currentTotalExpense.toStringAsFixed(2)}',
                      color: Colors.orange,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: net >= 0 ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: net >= 0 ? Colors.green.shade200 : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            net >= 0 ? 'Net Profit' : 'Net Loss',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₹${net.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16, 
                              color: net >= 0 ? Colors.green.shade800 : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Analytics Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.summarize, size: 20),
                    label: Text(l10n.dataSummary),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.green.shade300),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text(l10n.dataSummary),
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                            body: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TransactionsDataSummary(
                                totalIncome: currentTotalIncome,
                                totalExpense: currentTotalExpense,
                                net: net,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.show_chart, size: 20),
                    label: Text(l10n.lineChart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text(l10n.lineChart),
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                            body: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Income Trend',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: TransactionsLineChart(
                                              spots: incomeChartData,
                                              isIncome: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Expense Trend',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: TransactionsLineChart(
                                              spots: expenseChartData,
                                              isIncome: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildChartLegend(
                                          color: Colors.green,
                                          label: 'Income',
                                        ),
                                        const SizedBox(width: 24),
                                        _buildChartLegend(
                                          color: Colors.orange,
                                          label: 'Expenses',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Stats
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              label: 'Income Transactions',
                              count: filteredIncomes.length,
                              color: Colors.green,
                              icon: Icons.attach_money,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              label: 'Expense Transactions',
                              count: filteredExpenses.length,
                              color: Colors.orange,
                              icon: Icons.money_off,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}