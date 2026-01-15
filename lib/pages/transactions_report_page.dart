import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions') ?? '[]';
      double incomeSum = 0.0;
      double expenseSum = 0.0;
      final List<Map<String, dynamic>> incomes = [];
      final List<Map<String, dynamic>> expenses = [];

      final List<dynamic> jsonList = jsonDecode(transactionsJson);
      for (var item in jsonList) {
        if (item is Map<String, dynamic>) {
          final type = item['type']?.toString().toLowerCase() ?? '';
          final amt = double.tryParse((item['amount'] ?? '0').toString()) ?? 0.0;
          if (type == 'income') {
            incomeSum += amt;
            incomes.add(Map<String, dynamic>.from(item));
          } else if (type == 'expense') {
            expenseSum += amt;
            expenses.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (mounted) {
        setState(() {
          totalIncome = incomeSum;
          totalExpense = expenseSum;
          _incomes.clear();
          _incomes.addAll(incomes);
          _expenses.clear();
          _expenses.addAll(expenses);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
   Future<void> _generateAndPreviewPDF() async {
  try {
    List<Map<String, dynamic>> filteredIncomes = _incomes;
    List<Map<String, dynamic>> filteredExpenses = _expenses;
    
    if (_selectedRange != null) {
      filteredIncomes = _incomes.where((item) {
        final dateStr = item['date']?.toString() ?? '';
        if (dateStr.isEmpty) return false;
        
        try {
          final date = DateTime.parse(dateStr);
          return date.isAtSameMomentAs(_selectedRange!.start) ||
                 (date.isAfter(_selectedRange!.start) && date.isBefore(_selectedRange!.end)) ||
                 date.isAtSameMomentAs(_selectedRange!.end);
        } catch (e) {
          debugPrint('Error parsing date in PDF filter: $e');
          return false;
        }
      }).toList();
      
      filteredExpenses = _expenses.where((item) {
        final dateStr = item['date']?.toString() ?? '';
        if (dateStr.isEmpty) return false;
        
        try {
          final date = DateTime.parse(dateStr);
          return date.isAtSameMomentAs(_selectedRange!.start) ||
                 (date.isAfter(_selectedRange!.start) && date.isBefore(_selectedRange!.end)) ||
                 date.isAtSameMomentAs(_selectedRange!.end);
        } catch (e) {
          debugPrint('Error parsing date in PDF filter: $e');
          return false;
        }
      }).toList();
    }
    
    final double pdfTotalIncome = filteredIncomes.fold(0.0, (sum, item) {
      final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
      return sum + amount;
    });
    
    final double pdfTotalExpense = filteredExpenses.fold(0.0, (sum, item) {
      final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
      return sum + amount;
    });
    
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
    
    PdfColor createPdfColorWithOpacity(PdfColor color, double opacity) {
      return PdfColor(
        color.red / 255.0,
        color.green / 255.0,
        color.blue / 255.0,
        opacity,
      );
    }
    
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
      color: PdfColor.fromInt(0xFF4CAF50),
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
                              'Date Range: ${_formatDateForPDF(_selectedRange!.start)} to ${_formatDateForPDF(_selectedRange!.end)}',
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
                        'Time: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 24),
              
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8F9FA),
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
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
                              'Rs. ${pdfTotalIncome.toStringAsFixed(2)}',
                              style: metricValueStyle.copyWith(
                                color: PdfColor.fromInt(0xFF4CAF50),
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
                              'Rs. ${pdfTotalExpense.toStringAsFixed(2)}',
                              style: metricValueStyle.copyWith(
                                color: PdfColor.fromInt(0xFFFF9800),
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
                    
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: net >= 0 
                              ? PdfColor.fromInt(0xFFE8F5E9)
                              : PdfColor.fromInt(0xFFFFEBEE),
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
                              'Rs. ${net.toStringAsFixed(2)}',
                              style: metricValueStyle.copyWith(
                                color: net >= 0 
                                    ? PdfColor.fromInt(0xFF2E7D32)
                                    : PdfColor.fromInt(0xFFC62828),
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
                      color: PdfColor.fromInt(0xFF4CAF50),
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
                      final dateStr = item['date']?.toString() ?? '';
                      String formattedDate = 'Unknown';
                      try {
                        final date = DateTime.parse(dateStr);
                        formattedDate = DateFormat('yyyy-MM-dd').format(date);
                      } catch (_) {}
                      
                      final type = item['type']?.toString() ?? '';
                      final qty = item['quantity']?.toString() ?? '-';
                      final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                      final notes = item['notes']?.toString() ?? '';
                      
                      return [
                        formattedDate,
                        type,
                        qty,
                        'Rs. ${amount.toStringAsFixed(2)}',
                        notes.length > 30 ? '${notes.substring(0, 30)}...' : notes,
                      ];
                    }).toList(),
                  ),
                ),
              
              pw.SizedBox(height: 32),
              
              pw.Text('Expense Transactions', style: sectionHeaderStyle.copyWith(
                color: PdfColor.fromInt(0xFFFF9800),
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
                      color: PdfColor.fromInt(0xFFFF9800),
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
                      final dateStr = item['date']?.toString() ?? '';
                      String formattedDate = 'Unknown';
                      try {
                        final date = DateTime.parse(dateStr);
                        formattedDate = DateFormat('yyyy-MM-dd').format(date);
                      } catch (_) {}
                      
                      final type = item['type']?.toString() ?? '';
                      final qty = item['quantity']?.toString() ?? '-';
                      final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                      final notes = item['notes']?.toString() ?? '';
                      
                      return [
                        formattedDate,
                        type,
                        qty,
                        'Rs. ${amount.toStringAsFixed(2)}',
                        notes.length > 30 ? '${notes.substring(0, 30)}...' : notes,
                      ];
                    }).toList(),
                  ),
                ),
              
              pw.SizedBox(height: 32),
              
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
                          'Total Income: Rs. ${pdfTotalIncome.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.green,
                          ),
                        ),
                        pw.Text(
                          'Total Expenses: Rs. ${pdfTotalExpense.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.orange,
                          ),
                        ),
                        pw.Text(
                          'Net ${net >= 0 ? 'Profit' : 'Loss'}: Rs. ${net.abs().toStringAsFixed(2)}',
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
  } catch (e) {
    debugPrint('Error generating PDF: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _showDateRangePicker() async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _selectedRange,
      );
      
      if (picked != null && mounted) {
        setState(() {
          _selectedRange = picked;
        });
      }
    } catch (e) {
      debugPrint('Error showing date picker: $e');
    }
  }

  List<FlSpot> _prepareIncomeChartData(List<Map<String, dynamic>> incomes) {
    final Map<String, double> dailyIncome = {};
    try {
      for (var income in incomes) {
        // Support both 'transaction_date' and 'date' fields
        final dateStr = income['transaction_date']?.toString() ?? income['date']?.toString() ?? '';
        if (dateStr.isNotEmpty && dateStr != 'null') {
          try {
            final date = DateTime.parse(dateStr);
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            final amount = double.tryParse(income['amount']?.toString() ?? '0') ?? 0.0;
            dailyIncome[dateKey] = (dailyIncome[dateKey] ?? 0.0) + amount;
          } catch (e) {
            // Skip invalid dates
            continue;
          }
        }
      }
      final sortedDates = dailyIncome.keys.toList()..sort();
      final List<FlSpot> spots = [];
      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final amount = dailyIncome[date] ?? 0.0;
        final x = i.toDouble();
        final y = amount.isFinite ? amount : 0.0;
        spots.add(FlSpot(x, y));
      }
      return spots;
    } catch (e) {
      return [];
    }
  }

  List<FlSpot> _prepareExpenseChartData(List<Map<String, dynamic>> expenses) {
    final Map<String, double> dailyExpense = {};
    try {
      for (var expense in expenses) {
        // Support both 'transaction_date' and 'date' fields
        final dateStr = expense['transaction_date']?.toString() ?? expense['date']?.toString() ?? '';
        if (dateStr.isNotEmpty && dateStr != 'null') {
          try {
            final date = DateTime.parse(dateStr);
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
            dailyExpense[dateKey] = (dailyExpense[dateKey] ?? 0.0) + amount;
          } catch (e) {
            // Skip invalid dates
            continue;
          }
        }
      }
      final sortedDates = dailyExpense.keys.toList()..sort();
      final List<FlSpot> spots = [];
      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final amount = dailyExpense[date] ?? 0.0;
        final x = i.toDouble();
        final y = amount.isFinite ? amount : 0.0;
        spots.add(FlSpot(x, y));
      }
      return spots;
    } catch (e) {
      return [];
    }
  }

  List<String> _getSortedDates(
    List<Map<String, dynamic>> incomes, 
    List<Map<String, dynamic>> expenses
  ) {
    final allDates = <String>{};
    
    try {
      for (var income in incomes) {
        final dateStr = income['transaction_date']?.toString() ?? income['date']?.toString() ?? '';
        if (dateStr.isNotEmpty && dateStr != 'null') {
          allDates.add(dateStr);
        }
      }
      for (var expense in expenses) {
        final dateStr = expense['transaction_date']?.toString() ?? expense['date']?.toString() ?? '';
        if (dateStr.isNotEmpty && dateStr != 'null') {
          allDates.add(dateStr);
        }
      }
      final sortedDates = allDates.toList()..sort();
      return sortedDates;
    } catch (e) {
      return [];
    }
  }

  String _formatDateForPDF(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          title: const Text('Transactions Report', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      List<Map<String, dynamic>> filteredIncomes = _incomes;
      List<Map<String, dynamic>> filteredExpenses = _expenses;
      
      if (_selectedRange != null) {
        filteredIncomes = _incomes.where((item) {
          final dateStr = item['date']?.toString() ?? '';
          if (dateStr.isEmpty) return false;
          
          try {
            final date = DateTime.parse(dateStr);
            return date.isAtSameMomentAs(_selectedRange!.start) ||
                   (date.isAfter(_selectedRange!.start) && date.isBefore(_selectedRange!.end)) ||
                   date.isAtSameMomentAs(_selectedRange!.end);
          } catch (e) {
            return false;
          }
        }).toList();
        
        filteredExpenses = _expenses.where((item) {
          final dateStr = item['date']?.toString() ?? '';
          if (dateStr.isEmpty) return false;
          
          try {
            final date = DateTime.parse(dateStr);
            return date.isAtSameMomentAs(_selectedRange!.start) ||
                   (date.isAfter(_selectedRange!.start) && date.isBefore(_selectedRange!.end)) ||
                   date.isAtSameMomentAs(_selectedRange!.end);
          } catch (e) {
            return false;
          }
        }).toList();
      }
      
      final double currentTotalIncome = filteredIncomes.fold(0.0, (sum, item) {
        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        return sum + amount;
      });
      
      final double currentTotalExpense = filteredExpenses.fold(0.0, (sum, item) {
        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        return sum + amount;
      });
      
      final double net = currentTotalIncome - currentTotalExpense;
      
      final incomeChartData = _prepareIncomeChartData(filteredIncomes);
      final expenseChartData = _prepareExpenseChartData(filteredExpenses);
      final dates = _getSortedDates(filteredIncomes, filteredExpenses);
      
      // Debug logging
      debugPrint('=== CHART DATA DEBUG ===');
      debugPrint('Income spots: ${incomeChartData.length}');
      debugPrint('Expense spots: ${expenseChartData.length}');
      debugPrint('Dates: ${dates.length}');
      
      for (var spot in incomeChartData) {
        if (!spot.x.isFinite || !spot.y.isFinite) {
          debugPrint('Invalid income spot: x=${spot.x}, y=${spot.y}');
        }
      }
      
      for (var spot in expenseChartData) {
        if (!spot.x.isFinite || !spot.y.isFinite) {
          debugPrint('Invalid expense spot: x=${spot.x}, y=${spot.y}');
        }
      }
      
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
              icon: const Icon(Icons.filter_list, color: Colors.white),
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
                            '${DateFormat('MMM d, yyyy').format(_selectedRange!.start)} to ${DateFormat('MMM d, yyyy').format(_selectedRange!.end)}',
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
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(12), 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08), 
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
                                      '₹${_formatAmount(net)}', 
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
                      _buildMetricRow(
                        label: 'Total Income',
                        value: '₹${_formatAmount(currentTotalIncome)}',
                        color: const Color(0xFF4CAF50),
                        icon: Icons.arrow_upward,
                      ),
                      const SizedBox(height: 8),
                      _buildMetricRow(
                        label: 'Total Expenses',
                        value: '₹${_formatAmount(currentTotalExpense)}',
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
                              '₹${_formatAmount(net.abs())}',
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
                            builder: (context) => TransactionsDataSummary(
                              totalIncome: currentTotalIncome,
                              totalExpense: currentTotalExpense,
                              net: net,
                              incomeDetails: filteredIncomes,
                              expenseDetails: filteredExpenses,
                              dateRange: _selectedRange,
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
                      onPressed: () async {
                        try {
                          // Validate data before navigating
                          if (incomeChartData.isEmpty && expenseChartData.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No chart data available'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          
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
                                  child: TransactionsLineChart(
                                    incomeSpots: incomeChartData,
                                    expenseSpots: expenseChartData,
                                    dates: dates,
                                    title: 'Financial Trends',
                                    dateRange: _selectedRange,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint('Error opening line chart: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error loading chart'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
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
                        const SizedBox(height: 16),
                        Text(
                          'Financial Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildFinancialMetric(
                                label: 'Average Income per Transaction',
                                value: filteredIncomes.isNotEmpty 
                                    ? '₹${_formatAmount(currentTotalIncome / filteredIncomes.length)}'
                                    : '₹0',
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildFinancialMetric(
                                label: 'Average Expense per Transaction',
                                value: filteredExpenses.isNotEmpty
                                    ? '₹${_formatAmount(currentTotalExpense / filteredExpenses.length)}'
                                    : '₹0',
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              _buildFinancialMetric(
                                label: 'Profit Margin',
                                value: currentTotalIncome > 0
                                    ? '${((net / currentTotalIncome) * 100).toStringAsFixed(1)}%'
                                    : '0%',
                                color: net >= 0 ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
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
    } catch (e, stackTrace) {
      debugPrint('Error building TransactionsReportPage: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          title: const Text('Error'),
        ),
        body: Center(
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
                  'Unable to load transactions report',
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
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadTransactions();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
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

  Widget _buildFinancialMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
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