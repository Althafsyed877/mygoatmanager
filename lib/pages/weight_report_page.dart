import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
import '../services/archive_service.dart';
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
  // Date range variables
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Report data
  List<Goat> _activeGoats = [];
  List<Goat> _goatsWithWeight = [];
  List<Goat> _goatsWithoutWeight = [];
  
  // Loading state
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Set default date range to last 12 months
    _endDate = DateTime.now();
    _startDate = DateTime(_endDate!.year - 1, _endDate!.month, _endDate!.day);
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Load goats from SharedPreferences (same as GoatsPage)
    final prefs = await SharedPreferences.getInstance();
    final String? goatsJson = prefs.getString('goats');
    
    if (goatsJson != null) {
      final List<dynamic> decodedList = jsonDecode(goatsJson);
      List<Goat> allGoats = decodedList.map((item) => Goat.fromJson(item)).toList();
      
      // Load archived goats to filter them out
      // FIXED: Removed context parameter - check your ArchiveService
    final archivedGoats = await ArchiveService.getArchivedGoats('archived_goats.json');
      final archivedTags = archivedGoats.map((g) => g.tagNo).toSet();
      
      // Filter active goats (not archived)
      _activeGoats = allGoats.where((goat) => !archivedTags.contains(goat.tagNo)).toList();
      
      // Analyze weight data
      _analyzeWeights();
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  void _analyzeWeights() {
    _goatsWithWeight = [];
    _goatsWithoutWeight = [];
    
    for (var goat in _activeGoats) {
      final hasWeightRecord = _hasWeightInPeriod(goat);
      
      if (hasWeightRecord) {
        _goatsWithWeight.add(goat);
      } else {
        _goatsWithoutWeight.add(goat);
      }
    }
  }
  
  bool _hasWeightInPeriod(Goat goat) {
    // IMPORTANT: You need to add weightHistory field to your Goat model
    if (goat.weightHistory == null || goat.weightHistory!.isEmpty) {
      return false;
    }
    
    for (var entry in goat.weightHistory!) {
      final entryDate = _parseDate(entry['date']);
      if (entryDate != null && 
          entryDate.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
          entryDate.isBefore(_endDate!.add(const Duration(days: 1)))) {
        return true;
      }
    }
    
    return false;
  }
  
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').parse(dateStr);
      } catch (_) {
        try {
          return DateFormat('dd-MM-yyyy').parse(dateStr);
        } catch (_) {
          return null;
        }
      }
    }
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
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
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _analyzeWeights();
    }
  }
  
  Future<void> _exportToPdf(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final doc = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    // Calculate performance data for PDF only
    final performanceData = await _calculatePerformanceDataForPdf();
    
    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                loc.weightReportTitle.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColors.green,
                ),
              ),
              pw.Text(
                '${loc.lastMonths}: ${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}',
                style: pw.TextStyle(fontSize: 12, color: pdf.PdfColors.grey),
              ),
              pw.Divider(thickness: 2),
            ],
          ),
          
          // Summary Section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(loc.summarySection, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: pdf.PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(loc.summaryForPeriod, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    _buildSummaryRow(loc.numberActiveGoats, '${_activeGoats.length}'),
                    _buildSummaryRow(loc.numberGoatsWithWeight, '${_goatsWithWeight.length}'),
                    _buildSummaryRow(loc.numberGoatsWithoutWeight, '${_goatsWithoutWeight.length}'),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),
          
          // Performance Data Section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(loc.performanceByGoat, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              performanceData.isEmpty 
                  ? pw.Padding(
                      padding: const pw.EdgeInsets.all(20),
                      child: pw.Text(
                        loc.noPerformanceData,
                        style: pw.TextStyle(fontSize: 12, color: pdf.PdfColors.grey),
                      ),
                    )
                  : pw.TableHelper.fromTextArray(
                      context: context,
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdf.PdfColors.white),
                      headerDecoration: pw.BoxDecoration(color: pdf.PdfColors.green),
                      headers: [
                        loc.tagNo,
                        loc.name,
                        loc.breed,
                        loc.gender,
                        '${loc.firstWeight} (kg)',
                        '${loc.lastWeight} (kg)',
                        '${loc.weightGain} (kg)',
                        '${loc.gainPercentage} (%)',
                        '${loc.avgDailyGain} (kg/day)',
                        '${loc.avgWeight} (kg)',
                        loc.measurements,
                      ],
                      data: performanceData,
                    ),
            ],
          ),
          
          // Goats Without Weight
          if (_goatsWithoutWeight.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(loc.goatsWithoutWeight, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: pdf.PdfColors.orange)),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _goatsWithoutWeight.map((goat) => 
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: pdf.PdfColors.orange),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text('${goat.tagNo} - ${goat.name ?? loc.unnamed}'),
                    )
                  ).toList(),
                ),
              ],
            ),
          ],
          
          // Footer
          pw.Column(
            children: [
              pw.Divider(thickness: 1),
              pw.Text(
                '${loc.generatedOn}: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
    
    final bytes = await doc.save();
    
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${loc.weightReportFilename}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
  
  Future<List<List<String>>> _calculatePerformanceDataForPdf() async {
    List<List<String>> data = [];
    
    for (var goat in _goatsWithWeight) {
      final performance = await _calculateGoatPerformance(goat);
      if (performance.isNotEmpty) {
        data.add([
          performance['tagNo'] ?? '',
          performance['name'] ?? '',
          performance['breed'] ?? '-',
          performance['gender'] ?? '',
          performance['firstWeight'] ?? '0.0',
          performance['lastWeight'] ?? '0.0',
          performance['weightGain'] ?? '0.0',
          performance['weightGainPercentage'] ?? '0.0%',
          performance['avgDailyGain'] ?? '0.000',
          performance['avgWeight'] ?? '0.0',
          performance['measurementsCount'] ?? '0',
        ]);
      }
    }
    
    return data;
  }
  
  Future<Map<String, String>> _calculateGoatPerformance(Goat goat) async {
    // IMPORTANT: You need to add weightHistory field to your Goat model
    if (goat.weightHistory == null || goat.weightHistory!.isEmpty) {
      return {};
    }
    
    final sortedHistory = List<Map<String, dynamic>>.from(goat.weightHistory!);
    sortedHistory.sort((a, b) {
      final dateA = _parseDate(a['date']) ?? DateTime(1970);
      final dateB = _parseDate(b['date']) ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
    
    final periodWeights = sortedHistory.where((entry) {
      final entryDate = _parseDate(entry['date']);
      return entryDate != null && 
          entryDate.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
          entryDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();
    
    if (periodWeights.length < 2) {
      return {};
    }
    
    final firstWeight = periodWeights.first['weight'] ?? 0.0;
    final lastWeight = periodWeights.last['weight'] ?? 0.0;
    final firstDate = _parseDate(periodWeights.first['date']);
    final lastDate = _parseDate(periodWeights.last['date']);
    
    if (firstDate == null || lastDate == null) {
      return {};
    }
    
    final weightDiff = lastWeight - firstWeight;
    final weightGainPercentage = firstWeight > 0 ? (weightDiff / firstWeight) * 100 : 0;
    final daysBetween = lastDate.difference(firstDate).inDays;
    final avgDailyGain = daysBetween > 0 ? weightDiff / daysBetween : 0;
    
    double totalWeight = 0;
    for (var entry in periodWeights) {
      if (entry['weight'] != null) {
        totalWeight += entry['weight'];
      }
    }
    final avgWeight = totalWeight / periodWeights.length;
    
    return {
      'tagNo': goat.tagNo,
      'name': goat.name ?? 'Unnamed',
      'breed': goat.breed ?? '-',
      'gender': goat.gender,
      'firstWeight': firstWeight.toStringAsFixed(1),
      'lastWeight': lastWeight.toStringAsFixed(1),
      'weightGain': weightDiff.toStringAsFixed(1),
      'weightGainPercentage': '${weightGainPercentage.toStringAsFixed(1)}%',
      'avgDailyGain': avgDailyGain.toStringAsFixed(3),
      'avgWeight': avgWeight.toStringAsFixed(1),
      'measurementsCount': periodWeights.length.toString(),
    };
  }
  
  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isGood = true,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), // FIXED: Changed from withOpacity()
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
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
        ),
        Icon(
          isGood ? Icons.check_circle : Icons.warning,
          color: isGood ? Colors.green : Colors.orange,
          size: 28,
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.weightReportTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadData,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : Container(
              color: const Color(0xFFF5F5F5),
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                loc.lastMonths,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _selectDateRange(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue[700],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.blue[300]!),
                                ),
                              ),
                              icon: const Icon(Icons.edit_calendar, size: 20),
                              label: Text(loc.changeDateRange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary Card
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
                          Row(
                            children: [
                              Icon(Icons.summarize, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                loc.summaryForPeriod,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Summary Stats
                          _buildStatRow(
                            icon: Icons.agriculture,
                            label: loc.numberActiveGoats,
                            value: '${_activeGoats.length}',
                            color: Colors.green,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            icon: Icons.scale,
                            label: loc.numberGoatsWithWeight,
                            value: '${_goatsWithWeight.length}',
                            color: Colors.blue,
                            isGood: true,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            icon: Icons.warning,
                            label: loc.numberGoatsWithoutWeight,
                            value: '${_goatsWithoutWeight.length}',
                            color: Colors.orange,
                            isGood: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Performance Card
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
                          Row(
                            children: [
                              Icon(Icons.assessment, color: Colors.purple[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                loc.performanceByGoat,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.orange[700], size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  loc.detailedDataMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  loc.exportPdfMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _exportToPdf(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
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