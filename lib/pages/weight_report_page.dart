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
  List<Goat> _goatsWithoutWeightInRange = []; // Goats without weight IN DATE RANGE (or without dates in range)
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
      print('Goats with weight IN RANGE: ${_goatsWithWeightInRange.length}');
      print('Goats without weight IN RANGE: ${_goatsWithoutWeightInRange.length}');
    }
    
    setState(() { _isLoading = false; });
  }
  
  void _applyDateFilter() {
    // Reset lists
    _goatsWithWeightInRange = [];
    _goatsWithoutWeightInRange = [];
    
    if (_fromDate == null || _toDate == null) {
      // If no dates selected, show ALL goats with ANY weight data
      for (var goat in _allGoats) {
        if (_hasAnyWeightData(goat)) {
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
    
    for (var goat in _allGoats) {
      print('=== Checking goat: ${goat.tagNo} ===');
      
      // Debug: Print weight history
      if (goat.weightHistory != null && goat.weightHistory!.isNotEmpty) {
        print('Weight history entries: ${goat.weightHistory!.length}');
        for (var record in goat.weightHistory!) {
          print('  Record: date="${record['date']}", weight="${record['weight']}"');
        }
      } else {
        print('No weight history');
      }
      
      bool hasWeightInDateRange = false;
      String? latestWeightInRange;
      DateTime? latestWeightDate;
      
      // FIRST and ONLY check: Check weight history for dates in range
      if (goat.weightHistory != null && goat.weightHistory!.isNotEmpty) {
        for (var record in goat.weightHistory!) {
          if (record['date'] != null && record['weight'] != null) {
            try {
              final weightDateStr = record['date'].toString();
              final weight = record['weight'].toString();
              
              // Try to parse the date
              DateTime? weightDate = _tryParseDate(weightDateStr);
              
              if (weightDate != null) {
                // Check if this weight record is within the selected date range
                if (weightDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                    weightDate.isBefore(endDate.add(const Duration(days: 1)))) {
                  hasWeightInDateRange = true;
                  
                  // Track the latest weight in this range
                  if (latestWeightDate == null || weightDate.isAfter(latestWeightDate)) {
                    latestWeightDate = weightDate;
                    latestWeightInRange = weight;
                  }
                  
                  print('✓ ${goat.tagNo} has weight recorded on ${DateFormat('yyyy-MM-dd').format(weightDate)}: $weight');
                } else {
                  print('✗ ${goat.tagNo} weight date ${DateFormat('yyyy-MM-dd').format(weightDate)} is NOT in range');
                }
              } else {
                print('✗ ${goat.tagNo} could not parse date: "$weightDateStr"');
              }
            } catch (e) {
              print('✗ ${goat.tagNo} error parsing weight record: $e');
            }
          }
        }
      }
      
      // SECOND: Check current weight - BUT ONLY IF we can't trust weight history
      // Actually, for weight report, we should NOT include current weight without date
      // because we don't know when it was recorded
      // So we skip this part
      
      if (hasWeightInDateRange) {
        // Create a temporary goat with the latest weight from the date range
        final goatInRange = Goat(
          tagNo: goat.tagNo,
          name: goat.name,
          breed: goat.breed,
          gender: goat.gender,
          goatStage: goat.goatStage,
          dateOfBirth: goat.dateOfBirth,
          dateOfEntry: goat.dateOfEntry,
          weight: latestWeightInRange, // Use weight from the date range
          group: goat.group,
          obtained: goat.obtained,
          motherTag: goat.motherTag,
          fatherTag: goat.fatherTag,
          notes: goat.notes,
          photoPath: goat.photoPath,
          weightHistory: goat.weightHistory,
        );
        _goatsWithWeightInRange.add(goatInRange);
      } else {
        // Goat has no weight recorded in this date range
        _goatsWithoutWeightInRange.add(goat);
      }
    }
    
    // Sort by tag number
    _goatsWithWeightInRange.sort((a, b) => a.tagNo.compareTo(b.tagNo));
    _goatsWithoutWeightInRange.sort((a, b) => a.tagNo.compareTo(b.tagNo));
    
    print('=== Filter Results ===');
    print('Goats with weight RECORDED IN DATE RANGE: ${_goatsWithWeightInRange.length}');
    print('Goats WITHOUT weight recorded in date range: ${_goatsWithoutWeightInRange.length}');
  }
  
  // Improved date parsing method
  DateTime? _tryParseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    // Clean the string
    dateStr = dateStr.trim();
    
    // Try standard DateTime.parse first
    try {
      return DateTime.parse(dateStr);
    } catch (e1) {
      print('Standard parse failed for: $dateStr');
    }
    
    // Try common date formats
    final formats = [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'yyyy/MM/dd',
      'dd MMM yyyy',
      'MMM dd, yyyy',
    ];
    
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (e) {
        continue;
      }
    }
    
    // Try to extract date from string (e.g., "2024-12-10 10:30:00.000")
    try {
      // Extract first part before space
      final parts = dateStr.split(' ');
      if (parts.isNotEmpty) {
        return DateTime.parse(parts[0]);
      }
    } catch (e) {
      // Ignore
    }
    
    // Try manual parsing
    try {
      // Look for common separators
      String? separator;
      if (dateStr.contains('/')) separator = '/';
      else if (dateStr.contains('-')) separator = '-';
      else if (dateStr.contains('.')) separator = '.';
      
      if (separator != null) {
        final parts = dateStr.split(separator);
        if (parts.length == 3) {
          // Try different orders
          List<List<int>> orders = [
            [2, 1, 0], // yyyy-MM-dd
            [0, 1, 2], // dd-MM-yyyy
            [2, 0, 1], // MM-dd-yyyy
          ];
          
          for (var order in orders) {
            try {
              final y = int.tryParse(parts[order[0]]);
              final m = int.tryParse(parts[order[1]]);
              final d = int.tryParse(parts[order[2]]);
              
              if (y != null && m != null && d != null && y > 1900 && y < 2100) {
                return DateTime(y, m, d);
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
    } catch (e) {
      print('Manual parse failed for: $dateStr');
    }
    
    return null;
  }
  
  // Check if goat has ANY weight data at all (for "All Time" view)
  bool _hasAnyWeightData(Goat goat) {
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
            final weightDate = _tryParseDate(record['date'].toString());
            final weight = record['weight'].toString();
            
            if (weightDate != null && (latestDate == null || weightDate.isAfter(latestDate))) {
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
    
    // Check if it's a single day
    if (_isSameDay(_fromDate!, _toDate!)) {
      return format.format(_fromDate!);
    }
    
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
                  'Select Date Range for Weight Records',
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
                    _buildPdfRow('Total Goats in Database:', '${_allGoats.length}'),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('With weight recorded IN RANGE:', '${_goatsWithWeightInRange.length}'),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('Without weight recorded IN RANGE:', '${_goatsWithoutWeightInRange.length}'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 24),
              
              // Detailed Table
              if (_goatsWithWeightInRange.isNotEmpty) ...[
                pw.Text(
                  'GOATS WITH WEIGHT RECORDED IN DATE RANGE (${_goatsWithWeightInRange.length})',
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
                            'Latest Weight in Range',
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
                            child: pw.Text(goat.weight ?? 'N/A'),
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
                  
                  // Summary Section - SIMPLIFIED AND CORRECT
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
                          // Total Goats in Database
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
                              'Total Goats in Database',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Text(
                              '${_allGoats.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const Divider(),
                          
                          // Goats WITH Weight recorded IN Date Range
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
                              'With Weight Recorded IN RANGE',
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
                          
                          // Goats WITHOUT Weight recorded IN Date Range
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
                              'Without Weight Recorded IN RANGE',
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
                  
                  // Important Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Important:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This report ONLY shows goats that have weight records (from weight history) with dates that fall within the selected date range. Current weight without date history is NOT included.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
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