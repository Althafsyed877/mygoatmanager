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
  final List<Goat> _allGoats = [];
  final List<Map<String, dynamic>> _goatsWithWeight = [];
  final List<Goat> _goatsWithoutWeight = [];
  bool _isLoading = true;
  
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
    _fromDate = null; // Start with all time
    _toDate = null;
  }
  
  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    
    final prefs = await SharedPreferences.getInstance();
    final String? goatsJson = prefs.getString('goats');
    
    if (goatsJson != null) {
      final List<dynamic> decoded = jsonDecode(goatsJson);
      _allGoats.clear();
      _allGoats.addAll(decoded.map((item) => Goat.fromJson(item)).toList());
      _applyFilter();
      
      debugPrint('=== Weight Report Data ===');
      debugPrint('Total goats: ${_allGoats.length}');
      debugPrint('Goats WITH weight: ${_goatsWithWeight.length}');
      debugPrint('Goats WITHOUT weight: ${_goatsWithoutWeight.length}');
    }
    
    setState(() { _isLoading = false; });
  }
  
  void _applyFilter() {
    _goatsWithWeight.clear();
    _goatsWithoutWeight.clear();
    
    for (var goat in _allGoats) {
      // Check if goat has weight (from the main weight field, not history)
      final hasWeight = goat.weight != null && goat.weight!.isNotEmpty;
      
      if (hasWeight) {
        // For goats with weight, check if we need to filter by date
        // Since we only have single weight, we'll use entry date or DOB
        DateTime? weightDate;
        
        // Try to get a date associated with the weight
        if (goat.dateOfEntry != null && goat.dateOfEntry!.isNotEmpty) {
          weightDate = _parseDate(goat.dateOfEntry!);
        } else if (goat.dateOfBirth != null && goat.dateOfBirth!.isNotEmpty) {
          weightDate = _parseDate(goat.dateOfBirth!);
        }
        
        // If no date filter is applied OR weight date is within range
        if (_fromDate == null || _toDate == null || 
            (weightDate != null && _isDateInRange(weightDate))) {
          
          _goatsWithWeight.add({
            'goat': goat,
            'weight': goat.weight!,
            'weightDate': weightDate,
            'weightDateFormatted': weightDate != null 
                ? DateFormat('dd MMM yyyy').format(weightDate)
                : 'No date',
          });
        }
      } else {
        // Goats without weight
        _goatsWithoutWeight.add(goat);
      }
    }
    
    // Sort by weight value (highest first)
    _goatsWithWeight.sort((a, b) {
      final weightA = double.tryParse(a['weight'].toString().replaceAll(RegExp(r'[^\d.]'), ''));
      final weightB = double.tryParse(b['weight'].toString().replaceAll(RegExp(r'[^\d.]'), ''));
      
      if (weightA == null && weightB == null) return 0;
      if (weightA == null) return 1;
      if (weightB == null) return -1;
      
      return weightB.compareTo(weightA); // Descending order
    });
    
    _goatsWithoutWeight.sort((a, b) => a.tagNo.compareTo(b.tagNo));
  }
  
  bool _isDateInRange(DateTime date) {
    if (_fromDate == null || _toDate == null) {
      return true;
    }
    
    final checkDate = DateTime(date.year, date.month, date.day);
    final startDate = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final endDate = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
    
    return !checkDate.isBefore(startDate) && !checkDate.isAfter(endDate);
  }
  
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    dateStr = dateStr.trim();
    
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    
    // Try common date formats
    final formats = [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'MM/dd/yyyy',
      'dd MMM yyyy',
      'MMM dd, yyyy',
    ];
    
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (_) {}
    }
    
    return null;
  }
  
  String _getFormattedDateRange() {
    final loc = AppLocalizations.of(context);
    
    if (_fromDate == null || _toDate == null) {
      return loc?.allTime ?? 'All Time';
    }
    
    final format = DateFormat('dd MMM yyyy');
    
    if (_isSameDay(_fromDate!, _toDate!)) {
      return format.format(_fromDate!);
    }
    
    return '${format.format(_fromDate!)} - ${format.format(_toDate!)}';
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                      AppLocalizations.of(context)?.selectDateRange ?? 'Select Date Range',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickFilterChip(AppLocalizations.of(context)?.allTime ?? 'All Time', context),
                          const SizedBox(width: 8),
                          _buildQuickFilterChip(AppLocalizations.of(context)?.thisMonth ?? 'This Month', context),
                          const SizedBox(width: 8),
                          _buildQuickFilterChip(AppLocalizations.of(context)?.lastMonth ?? 'Last Month', context),
                          const SizedBox(width: 8),
                          _buildQuickFilterChip(AppLocalizations.of(context)?.last3Months ?? 'Last 3 Months', context),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)?.customRange ?? 'Custom Range',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)?.fromDate ?? 'From Date'),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _selectDate(context, true, setStateDialog),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _fromDate != null 
                                              ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                                              : AppLocalizations.of(context)?.selectDate ?? 'Select Date',
                                          style: TextStyle(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)?.toDate ?? 'To Date'),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _selectDate(context, false, setStateDialog),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _toDate != null 
                                              ? DateFormat('dd/MM/yyyy').format(_toDate!)
                                              : AppLocalizations.of(context)?.selectDate ?? 'Select Date',
                                          style: TextStyle(
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
                              _applyFilter();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: Text(AppLocalizations.of(context)?.clearFilter ?? 'Clear Filter'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _applyFilter();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)?.applyFilter ?? 'Apply Filter',
                              style: const TextStyle(color: Colors.white),
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
      },
    );
  }
  
  Widget _buildQuickFilterChip(String label, BuildContext context) {
    final isSelected = _isQuickFilterSelected(label, context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final now = DateTime.now();
        final loc = AppLocalizations.of(context);
        
        if (label == (loc?.allTime ?? 'All Time')) {
          setState(() {
            _fromDate = null;
            _toDate = null;
          });
        } else if (label == (loc?.thisMonth ?? 'This Month')) {
          setState(() {
            _fromDate = DateTime(now.year, now.month, 1);
            _toDate = DateTime(now.year, now.month, now.day);
          });
        } else if (label == (loc?.lastMonth ?? 'Last Month')) {
          final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
          final lastDayLastMonth = DateTime(now.year, now.month, 0);
          setState(() {
            _fromDate = firstDayLastMonth;
            _toDate = lastDayLastMonth;
          });
        } else if (label == (loc?.last3Months ?? 'Last 3 Months')) {
          setState(() {
            _toDate = DateTime(now.year, now.month, now.day);
            _fromDate = DateTime(now.year, now.month - 3, now.day);
          });
        }
        
        _applyFilter();
        Navigator.pop(context);
      },
      backgroundColor: isSelected ? const Color(0xFF4CAF50) : Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
      ),
    );
  }
  
  bool _isQuickFilterSelected(String label, BuildContext context) {
    final now = DateTime.now();
    final loc = AppLocalizations.of(context);
    
    if (_fromDate == null || _toDate == null) {
      return label == (loc?.allTime ?? 'All Time');
    }
    
    if (label == (loc?.thisMonth ?? 'This Month')) {
      final monthStart = DateTime(now.year, now.month, 1);
      return _isSameDay(_fromDate!, monthStart) && _isSameDay(_toDate!, now);
    } else if (label == (loc?.lastMonth ?? 'Last Month')) {
      final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
      final lastDayLastMonth = DateTime(now.year, now.month, 0);
      return _isSameDay(_fromDate!, firstDayLastMonth) && _isSameDay(_toDate!, lastDayLastMonth);
    } else if (label == (loc?.last3Months ?? 'Last 3 Months')) {
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      return _isSameDay(_fromDate!, threeMonthsAgo) && _isSameDay(_toDate!, now);
    }
    
    return false;
  }
  
  Future<void> _selectDate(BuildContext context, bool isFromDate, StateSetter setStateDialog) async {
    final initialDate = isFromDate ? _fromDate : _toDate;
    final firstDate = isFromDate ? DateTime(2000) : (_fromDate ?? DateTime(2000));
    final lastDate = isFromDate ? (_toDate ?? DateTime.now()) : DateTime.now();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setStateDialog(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
            _fromDate = _toDate;
          }
        }
      });
    }
  }
  
  Future<void> _exportToPdf(BuildContext context) async {
    try {
      final pdfDoc = pw.Document();
      
      pdfDoc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            final greenColor = pdf.PdfColor.fromInt(0xFF4CAF50);
            final whiteColor = pdf.PdfColor.fromInt(0xFFFFFFFF);
            final greyColor = pdf.PdfColor.fromInt(0xFF9E9E9E);
            final orangeColor = pdf.PdfColor.fromInt(0xFFFF9800);
            final grey300 = pdf.PdfColor.fromInt(0xFFE0E0E0);
            
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'WEIGHT REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: greenColor,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    _getFormattedDateRange(),
                    style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: greyColor),
                  ),
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),
                
                // Summary
                pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfSummaryItem('Total Goats:', '${_allGoats.length}', greenColor),
                          pw.SizedBox(height: 6),
                          _buildPdfSummaryItem('With Weight:', '${_goatsWithWeight.length}', greenColor),
                          pw.SizedBox(height: 6),
                          _buildPdfSummaryItem('Without Weight:', '${_goatsWithoutWeight.length}', greenColor),
                        ],
                      ),
                      pw.Container(
                        width: 100,
                        height: 100,
                        child: pw.Stack(
                          children: [
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: greenColor,
                                shape: pw.BoxShape.circle,
                              ),
                              width: 100,
                              height: 100,
                            ),
                            pw.Center(
                              child: pw.Text(
                                '${_goatsWithWeight.length}/${_allGoats.length}',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  color: whiteColor,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Goats with weight
                if (_goatsWithWeight.isNotEmpty) ...[
                  pw.Text(
                    'GOATS WITH WEIGHT RECORDED',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: greenColor,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  
                  pw.TableHelper.fromTextArray(
                    context: context,
                    data: [
                      ['Tag No', 'Name', 'Weight', 'Gender', 'Breed'],
                      ..._goatsWithWeight.map((item) {
                        final goat = item['goat'] as Goat;
                        final weight = item['weight'] as String;
                        return [
                          goat.tagNo,
                          goat.name ?? 'Unnamed',
                          '$weight kg',
                          goat.gender,
                          goat.breed ?? 'N/A',
                        ];
                      }),
                    ],
                    headerStyle: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: whiteColor,
                    ),
                    headerDecoration: pw.BoxDecoration(color: greenColor),
                    cellStyle: pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerAlignment: pw.Alignment.centerLeft,
                    border: pw.TableBorder.all(color: grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.2),
                      1: const pw.FlexColumnWidth(1.5),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1),
                      4: const pw.FlexColumnWidth(1.5),
                    },
                  ),
                  
                  pw.SizedBox(height: 30),
                ],
                
                // Goats without weight
                if (_goatsWithoutWeight.isNotEmpty) ...[
                  pw.Text(
                    'GOATS WITHOUT WEIGHT RECORDED',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: orangeColor,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  
                  pw.Wrap(
                    children: _goatsWithoutWeight.map((goat) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(right: 8, bottom: 4),
                        child: pw.Text(
                          goat.tagNo,
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                // Footer
                pw.SizedBox(height: 40),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Goat Manager - Weight Report',
                      style: pw.TextStyle(fontSize: 8, color: greyColor),
                    ),
                    pw.Text(
                      'Page 1 of 1',
                      style: pw.TextStyle(fontSize: 8, color: greyColor),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      final pdfBytes = await pdfDoc.save();
      
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Weight_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  pw.Widget _buildPdfSummaryItem(String label, String value, pdf.PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc?.weightReportTitle ?? 'Weight Report',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: loc?.filterByDate ?? 'Filter by Date',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _exportToPdf(context),
            tooltip: loc?.exportToPdf ?? 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: loc?.refreshData ?? 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date range card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc?.dateRange ?? 'Date Range',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getFormattedDateRange(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showFilterBottomSheet(context),
                            icon: const Icon(Icons.edit_calendar, size: 20),
                            label: Text(loc?.changeDateRange ?? 'Change Date Range'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Summary stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          loc?.totalGoats ?? 'Total Goats',
                          '${_allGoats.length}',
                          Colors.blue,
                          Icons.agriculture,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          loc?.withWeight ?? 'With Weight',
                          '${_goatsWithWeight.length}',
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          loc?.withoutWeight ?? 'Without Weight',
                          '${_goatsWithoutWeight.length}',
                          Colors.orange,
                          Icons.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
                
                // Tab bar for viewing data
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Material(
                          color: Colors.white,
                          child: TabBar(
                            labelColor: const Color(0xFF4CAF50),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFF4CAF50),
                            tabs: [
                              Tab(text: '${loc?.withWeight ?? 'With Weight'} (${_goatsWithWeight.length})'),
                              Tab(text: '${loc?.withoutWeight ?? 'Without Weight'} (${_goatsWithoutWeight.length})'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Tab 1: Goats with weight
                              _goatsWithWeight.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.scale,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc?.noWeightRecordsFound ?? 'No weight records found',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _goatsWithWeight.length,
                                      itemBuilder: (context, index) {
                                        final item = _goatsWithWeight[index];
                                        final goat = item['goat'] as Goat;
                                        final weight = item['weight'] as String;
                                        final date = item['weightDateFormatted'] as String?;
                                        
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          elevation: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                                  child: const Icon(
                                                    Icons.scale,
                                                    color: Color(0xFF4CAF50),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        goat.tagNo,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        goat.name ?? 'Unnamed',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      if (date != null && date != 'No date')
                                                        Text(
                                                          'Date: $date',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '$weight kg',
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF4CAF50),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      goat.gender,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: goat.gender.toLowerCase().contains('male')
                                                            ? Colors.blue
                                                            : Colors.pink,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              
                              // Tab 2: Goats without weight
                              _goatsWithoutWeight.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 60,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc?.allGoatsHaveWeightRecords ?? 'All goats have weight records',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _goatsWithoutWeight.length,
                                      itemBuilder: (context, index) {
                                        final goat = _goatsWithoutWeight[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          elevation: 1,
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                              child: const Icon(
                                                Icons.warning,
                                                color: Colors.orange,
                                              ),
                                            ),
                                            title: Text(
                                              goat.tagNo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(goat.name ?? 'Unnamed'),
                                                Text(
                                                  goat.gender,
                                                  style: TextStyle(
                                                    color: goat.gender.toLowerCase().contains('male')
                                                        ? Colors.blue
                                                        : Colors.pink,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: Text(
                                              loc?.noWeight ?? 'No Weight',
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
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
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                Text(
                  value,
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
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}