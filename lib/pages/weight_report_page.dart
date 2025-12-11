import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';

class WeightReportPage extends StatefulWidget {
  const WeightReportPage({super.key});

  @override
  State<WeightReportPage> createState() => _WeightReportPageState();
}

class _WeightReportPageState extends State<WeightReportPage> {
  List<Goat> _allGoats = []; // All goats from database
  List<Goat> _goatsWithWeightInRange = []; // Goats with weight IN DATE RANGE
  List<Goat> _goatsWithoutWeightInRange = []; // Goats without weight IN DATE RANGE
  List<Goat> _allGoatsInDateRange = []; // All goats that EXIST in date range
  bool _isLoading = true;
  
  // Date variables
  DateTime? _fromDate;
  DateTime? _toDate;
  
  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadData();
  }
  
  void _initializeDates() {
    final now = DateTime.now();
    // Set default to last 30 days
    _fromDate = now.subtract(const Duration(days: 30));
    _toDate = now;
  }
  
  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    
    final prefs = await SharedPreferences.getInstance();
    final String? goatsJson = prefs.getString('goats');
    
    if (goatsJson != null) {
      final List<dynamic> decoded = jsonDecode(goatsJson);
      _allGoats = decoded.map((item) => Goat.fromJson(item)).toList();
      
      // Apply date filter
      _applyDateFilter();
      
      print('=== Weight Report Data ===');
      print('Total goats in database: ${_allGoats.length}');
      print('Date range: ${_getFormattedDateRange()}');
      print('All goats in date range: ${_allGoatsInDateRange.length}');
      print('With weight data: ${_goatsWithWeightInRange.length}');
      print('Without weight data: ${_goatsWithoutWeightInRange.length}');
    }
    
    setState(() { _isLoading = false; });
  }
  
  void _applyDateFilter() {
    // Reset lists
    _allGoatsInDateRange = [];
    _goatsWithWeightInRange = [];
    _goatsWithoutWeightInRange = [];
    
    if (_fromDate == null || _toDate == null) {
      // If no dates selected, show ALL goats
      _allGoatsInDateRange = _allGoats;
      
      // Categorize all goats based on whether they have ANY weight data
      for (var goat in _allGoats) {
        if (_hasWeightData(goat)) {
          _goatsWithWeightInRange.add(goat);
        } else {
          _goatsWithoutWeightInRange.add(goat);
        }
      }
      return;
    }
    
    // Adjust times for proper date comparison
    final startDate = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final endDate = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
    
    print('=== Applying Date Filter ===');
    print('From: ${DateFormat('yyyy-MM-dd').format(startDate)}');
    print('To: ${DateFormat('yyyy-MM-dd').format(endDate)}');
    
    // First, find all goats that EXISTED during the date range
    // (based on birth date or entry date)
    for (var goat in _allGoats) {
      bool isGoatInDateRange = false;
      
      // Check if goat was alive/existed during the date range
      // Try to parse birth date
      if (goat.dateOfBirth != null && goat.dateOfBirth!.isNotEmpty) {
        final birthDate = _tryParseDate(goat.dateOfBirth!);
        if (birthDate != null && birthDate.isBefore(endDate.add(const Duration(days: 1)))) {
          isGoatInDateRange = true;
        } else if (birthDate == null) {
          // If date can't be parsed, include the goat (for backward compatibility)
          isGoatInDateRange = true;
        }
      }
      
      // If still not in range, try entry date
      if (!isGoatInDateRange && goat.dateOfEntry != null && goat.dateOfEntry!.isNotEmpty) {
        final entryDate = _tryParseDate(goat.dateOfEntry!);
        if (entryDate != null && entryDate.isBefore(endDate.add(const Duration(days: 1)))) {
          isGoatInDateRange = true;
        } else if (entryDate == null) {
          // If date can't be parsed, include the goat
          isGoatInDateRange = true;
        }
      }
      
      // If no dates at all, include the goat (for backward compatibility)
      if (!isGoatInDateRange && 
          (goat.dateOfBirth == null || goat.dateOfBirth!.isEmpty) && 
          (goat.dateOfEntry == null || goat.dateOfEntry!.isEmpty)) {
        isGoatInDateRange = true;
      }
      
      if (isGoatInDateRange) {
        _allGoatsInDateRange.add(goat);
        
        // Now check if this goat has weight data
        if (_hasWeightData(goat)) {
          _goatsWithWeightInRange.add(goat);
        } else {
          _goatsWithoutWeightInRange.add(goat);
        }
      }
    }
    
    // Sort by tag number
    _goatsWithWeightInRange.sort((a, b) => a.tagNo.compareTo(b.tagNo));
    _goatsWithoutWeightInRange.sort((a, b) => a.tagNo.compareTo(b.tagNo));
    
    print('=== Filter Results ===');
    print('Goats that existed in date range: ${_allGoatsInDateRange.length}');
    print('Goats with weight data: ${_goatsWithWeightInRange.length}');
    print('Goats without weight data: ${_goatsWithoutWeightInRange.length}');
  }
  
  // Helper method to parse dates with different formats
  DateTime? _tryParseDate(String dateStr) {
    try {
      // Try standard DateTime.parse first
      return DateTime.parse(dateStr);
    } catch (e1) {
      try {
        // Try common date formats
        final formats = [
          DateFormat('dd/MM/yyyy'),
          DateFormat('dd-MM-yyyy'),
          DateFormat('MM/dd/yyyy'),
          DateFormat('MM-dd-yyyy'),
          DateFormat('yyyy/MM/dd'),
          DateFormat('yyyy-MM-dd'),
        ];
        
        for (var format in formats) {
          try {
            return format.parse(dateStr);
          } catch (e) {
            continue;
          }
        }
      } catch (e2) {
        return null;
      }
    }
    return null;
  }
  
  // Check if goat has any weight data (current weight or weight history)
  bool _hasWeightData(Goat goat) {
    // Check current weight
    if (goat.weight != null && goat.weight!.isNotEmpty && goat.weight != "0") {
      return true;
    }
    
    // Check weight history
    if (goat.weightHistory != null && goat.weightHistory!.isNotEmpty) {
      return true;
    }
    
    return false;
  }
  
  // Get the latest weight from weight history or current weight
  String? _getLatestWeight(Goat goat) {
    String? latestWeight;
    DateTime? latestDate;
    
    // Check weight history for latest entry
    if (goat.weightHistory != null && goat.weightHistory!.isNotEmpty) {
      for (var record in goat.weightHistory!) {
        if (record['date'] != null && record['weight'] != null) {
          try {
            final weightDate = DateTime.parse(record['date'].toString());
            final weight = record['weight'].toString();
            
            if (latestDate == null || weightDate.isAfter(latestDate)) {
              latestDate = weightDate;
              latestWeight = weight;
            }
          } catch (e) {
            // Skip invalid records
          }
        }
      }
    }
    
    // If no weight history, use current weight
    if (latestWeight == null && goat.weight != null && goat.weight!.isNotEmpty && goat.weight != "0") {
      latestWeight = goat.weight;
    }
    
    return latestWeight;
  }
  
  // Date format for display
  String _getFormattedDateRange() {
    if (_fromDate == null || _toDate == null) {
      return 'All Time';
    }
    
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(_fromDate!)} - ${format.format(_toDate!)}';
  }
  
  // Show filter options in a bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Filter by Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildDateChip('Today', isSmallScreen),
                    _buildDateChip('Yesterday', isSmallScreen),
                    _buildDateChip('Last 7 Days', isSmallScreen),
                    _buildDateChip('This Month', isSmallScreen),
                    _buildDateChip('Last Month', isSmallScreen),
                    _buildDateChip('Last 30 Days', isSmallScreen),
                    _buildDateChip('Last 90 Days', isSmallScreen),
                    _buildDateChip('Last 12 Months', isSmallScreen),
                    _buildDateChip('All Time', isSmallScreen),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Custom Date Range',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From Date', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _selectFromDate(context),
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 14.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Expanded(
                                  child: Text(
                                    _fromDate != null 
                                        ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: _fromDate != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To Date', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _selectToDate(context),
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 14.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Expanded(
                                  child: Text(
                                    _toDate != null 
                                        ? DateFormat('dd/MM/yyyy').format(_toDate!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: _toDate != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                          });
                          _applyDateFilter();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          'Clear Filter',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyDateFilter();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Apply Filter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDateChip(String label, bool isSmallScreen) {
    final now = DateTime.now();
    bool isSelected = false;
    
    if (_fromDate == null && _toDate == null && label == 'All Time') {
      isSelected = true;
    } else if (_fromDate != null && _toDate != null) {
      switch (label) {
        case 'Today':
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          isSelected = _isSameDay(_fromDate!, todayStart) && 
                      _isSameDay(_toDate!, todayEnd);
          break;
        case 'Yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
          final yesterdayEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          isSelected = _isSameDay(_fromDate!, yesterdayStart) && 
                      _isSameDay(_toDate!, yesterdayEnd);
          break;
        case 'Last 7 Days':
          final weekAgo = now.subtract(const Duration(days: 7));
          isSelected = _isSameDay(_fromDate!, weekAgo) && 
                      _isSameDay(_toDate!, now);
          break;
        case 'This Month':
          final monthStart = DateTime(now.year, now.month, 1);
          isSelected = _isSameDay(_fromDate!, monthStart) && 
                      _isSameDay(_toDate!, now);
          break;
        case 'Last Month':
          final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
          final lastDayLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
          isSelected = _isSameDay(_fromDate!, firstDayLastMonth) && 
                      _isSameDay(_toDate!, lastDayLastMonth);
          break;
        case 'Last 30 Days':
          final monthAgo = now.subtract(const Duration(days: 30));
          isSelected = _isSameDay(_fromDate!, monthAgo) && 
                      _isSameDay(_toDate!, now);
          break;
        case 'Last 90 Days':
          final quarterAgo = now.subtract(const Duration(days: 90));
          isSelected = _isSameDay(_fromDate!, quarterAgo) && 
                      _isSameDay(_toDate!, now);
          break;
        case 'Last 12 Months':
          final yearAgo = now.subtract(const Duration(days: 365));
          isSelected = _isSameDay(_fromDate!, yearAgo) && 
                      _isSameDay(_toDate!, now);
          break;
        case 'All Time':
          isSelected = _fromDate == null && _toDate == null;
          break;
      }
    }

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
      ),
      selected: isSelected,
      onSelected: (selected) {
        final now = DateTime.now();
        switch (label) {
          case 'Today':
            setState(() {
              _fromDate = DateTime(now.year, now.month, now.day);
              _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
            });
            break;
          case 'Yesterday':
            final yesterday = now.subtract(const Duration(days: 1));
            setState(() {
              _fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
              _toDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
            });
            break;
          case 'Last 7 Days':
            setState(() {
              _fromDate = now.subtract(const Duration(days: 7));
              _toDate = now;
            });
            break;
          case 'This Month':
            setState(() {
              _fromDate = DateTime(now.year, now.month, 1);
              _toDate = now;
            });
            break;
          case 'Last Month':
            final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
            final lastDayLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
            setState(() {
              _fromDate = firstDayLastMonth;
              _toDate = lastDayLastMonth;
            });
            break;
          case 'Last 30 Days':
            setState(() {
              _fromDate = now.subtract(const Duration(days: 30));
              _toDate = now;
            });
            break;
          case 'Last 90 Days':
            setState(() {
              _fromDate = now.subtract(const Duration(days: 90));
              _toDate = now;
            });
            break;
          case 'Last 12 Months':
            setState(() {
              _fromDate = now.subtract(const Duration(days: 365));
              _toDate = now;
            });
            break;
          case 'All Time':
            setState(() {
              _fromDate = null;
              _toDate = null;
            });
            break;
        }
        _applyDateFilter();
        Navigator.pop(context);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300),
    );
  }
  
  // Helper to compare if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF4CAF50),
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF4CAF50),
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }
  
  // ✅ PDF Export Function
  Future<void> _exportToPdf(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    
    // Create PDF document
    final pdfDoc = pw.Document();
    
    pdfDoc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'WEIGHT REPORT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColors.green,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                _getFormattedDateRange(),
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              
              // Summary Section
              pw.Text(
                'SUMMARY',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: pdf.PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfRow('Date Range:', _getFormattedDateRange()),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('Goats in Date Range:', '${_allGoatsInDateRange.length}'),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('With Weight Data:', '${_goatsWithWeightInRange.length}'),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('Without Weight Data:', '${_goatsWithoutWeightInRange.length}'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 24),
              
              // Detailed Table
              if (_goatsWithWeightInRange.isNotEmpty) ...[
                pw.Text(
                  'GOATS WITH WEIGHT DATA (${_goatsWithWeightInRange.length})',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: pdf.PdfColors.grey300),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: pdf.PdfColors.green),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Tag No',
                            style: pw.TextStyle(
                              color: pdf.PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Name',
                            style: pw.TextStyle(
                              color: pdf.PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Weight',
                            style: pw.TextStyle(
                              color: pdf.PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Gender',
                            style: pw.TextStyle(
                              color: pdf.PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Data rows
                    for (var goat in _goatsWithWeightInRange)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(goat.tagNo),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(goat.name ?? 'Unnamed'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(_getLatestWeight(goat) ?? 'N/A'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(goat.gender),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
              
              // Footer
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
    
    // Save and share PDF
    final pdfBytes = await pdfDoc.save();
    
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Weight_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
  
  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.weightReportTitle,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Filter Icon
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filter by Date',
          ),
          // PDF Icon
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
            onPressed: () => _exportToPdf(context),
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Date Range',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getFormattedDateRange(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showFilterBottomSheet(context),
                              icon: const Icon(Icons.filter_list, size: 18),
                              label: const Text('Change Date Filter'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Summary Section - CORRECTED LOGIC
                  Text(
                    'Summary for Selected Period',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Goats in Date Range (NOT total goats)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.agriculture, color: Colors.green),
                            ),
                            title: const Text(
                              'Goats in Date Range',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Text(
                              '${_allGoatsInDateRange.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const Divider(),
                          
                          // Goats WITH Weight in Date Range
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle, color: Colors.blue),
                            ),
                            title: const Text(
                              'With Weight Data',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Text(
                              '${_goatsWithWeightInRange.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const Divider(),
                          
                          // Goats WITHOUT Weight in Date Range
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning, color: Colors.orange),
                            ),
                            title: const Text(
                              'Without Weight Data',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Text(
                              '${_goatsWithoutWeightInRange.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Performance Card
                  Text(
                    'Detailed Report',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 48,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Export detailed weight report',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_goatsWithWeightInRange.length} goats with weight data in selected date range',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // PDF export button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _exportToPdf(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 24),
                      label: Text(
                        loc.exportReportButton,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}