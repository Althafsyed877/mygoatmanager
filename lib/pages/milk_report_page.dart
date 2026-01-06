import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../models/milk_record.dart';

class MilkReportPage extends StatefulWidget {
  const MilkReportPage({super.key});

  @override
  State<MilkReportPage> createState() => _MilkReportPageState();
}

class _MilkReportPageState extends State<MilkReportPage> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  List<MilkRecord> _allRecords = [];
  List<MilkRecord> _filteredRecords = [];
  Map<String, dynamic> _summaryData = {};
  bool _isLoading = true;
  bool _showLineChart = false;
  String _farmName = 'My Goat Farm';
  String _farmLocation = 'Farm Location';
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadFarmSettings();
    _loadRecords();
  }

  Future<void> _loadFarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _farmName = prefs.getString('farm_name') ?? 'My Goat Farm';
      _farmLocation = prefs.getString('farm_location') ?? 'Farm Location';
    });
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('milk_records');
    
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        _allRecords = jsonList.map((e) => MilkRecord.fromJson(e as Map<String, dynamic>)).toList();
        _filteredRecords = List.from(_allRecords);
        _calculateSummary();
        _prepareChartData();
        _isLoading = false;
      });
    } else {
      setState(() {
        _allRecords = [];
        _filteredRecords = [];
        _calculateSummary();
        _prepareChartData();
        _isLoading = false;
      });
    }
  }

  void _filterRecords() {
    if (_allRecords.isEmpty) {
      setState(() {
        _filteredRecords = [];
      });
      return;
    }

    setState(() {
      _filteredRecords = _allRecords.where((record) {
        final recordDate = DateTime(record.milkingDate.year, record.milkingDate.month, record.milkingDate.day);
        final fromDate = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
        final toDate = DateTime(_toDate.year, _toDate.month, _toDate.day);
        return recordDate.isAtSameMomentAs(fromDate) ||
               recordDate.isAtSameMomentAs(toDate) ||
               (recordDate.isAfter(fromDate) && recordDate.isBefore(toDate));
      }).toList();
      _calculateSummary();
      _prepareChartData();
    });
  }

  void _prepareChartData() {
    final Map<String, Map<String, double>> dailyRecords = {};
    
    for (var record in _filteredRecords) {
      final dateKey = DateFormat('MMM dd').format(record.milkingDate);
      if (!dailyRecords.containsKey(dateKey)) {
        dailyRecords[dateKey] = {'produced': 0.0, 'used': 0.0};
      }
      dailyRecords[dateKey]!['produced'] = dailyRecords[dateKey]!['produced']! + record.total;
      dailyRecords[dateKey]!['used'] = dailyRecords[dateKey]!['used']! + record.used;
    }

    final sortedDates = dailyRecords.keys.toList()
      ..sort((a, b) => DateFormat('MMM dd').parse(a).compareTo(DateFormat('MMM dd').parse(b)));

    _chartData = sortedDates.map((date) {
      return {
        'date': date,
        'produced': dailyRecords[date]!['produced']!,
        'used': dailyRecords[date]!['used']!,
      };
    }).toList();
  }

  void _calculateSummary() {
    if (_filteredRecords.isEmpty) {
      setState(() {
        _summaryData = {
          'dailyAverage': 0.0,
          'totalProduced': 0.0,
          'totalUsed': 0.0,
          'averageMorning': 0.0,
          'averageEvening': 0.0,
          'hasData': false,
          'totalRecords': _filteredRecords.length,
        };
      });
      return;
    }
    
    double totalProduced = 0.0;
    double totalUsed = 0.0;
    double totalMorning = 0.0;
    double totalEvening = 0.0;
    
    for (var record in _filteredRecords) {
      totalProduced += record.total;
      totalUsed += record.used;
      totalMorning += record.morningQuantity;
      totalEvening += record.eveningQuantity;
    }

    final daysInRange = _toDate.difference(_fromDate).inDays + 1;
    final dailyAverage = daysInRange > 0 ? (totalProduced / daysInRange) : 0.0;
    final averageMorning = _filteredRecords.isNotEmpty ? (totalMorning / _filteredRecords.length) : 0.0;
    final averageEvening = _filteredRecords.isNotEmpty ? (totalEvening / _filteredRecords.length) : 0.0;

    setState(() {
      _summaryData = {
        'dailyAverage': dailyAverage,
        'totalProduced': totalProduced,
        'totalUsed': totalUsed,
        'averageMorning': averageMorning,
        'averageEvening': averageEvening,
        'hasData': totalProduced > 0 || totalUsed > 0,
        'totalRecords': _filteredRecords.length,
      };
    });
  }

  Widget _buildDateChip(BuildContext context, String label, bool isSmallScreen) {
    final loc = AppLocalizations.of(context)!;
    bool isSelected = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    String localizedLabel = label;
    if (label == 'Today') localizedLabel = loc.today;
    if (label == 'Yesterday') localizedLabel = loc.yesterday;
    if (label == 'Last Week') localizedLabel = loc.lastWeek;
    if (label == 'Current Month') localizedLabel = loc.currentMonth;
    if (label == 'Last Month') localizedLabel = loc.previousMonth;
    
    if (label == 'Today') {
      isSelected = _fromDate.isAtSameMomentAs(today) && _toDate.isAtSameMomentAs(today);
    } else if (label == 'Yesterday') {
      isSelected = _fromDate.isAtSameMomentAs(yesterday) && _toDate.isAtSameMomentAs(yesterday);
    } else if (label == 'Last Week') {
      final lastWeekStart = today.subtract(const Duration(days: 7));
      isSelected = _fromDate.isAtSameMomentAs(lastWeekStart) && _toDate.isAtSameMomentAs(today);
    } else if (label == 'Current Month') {
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      isSelected = _fromDate.isAtSameMomentAs(monthStart) && _toDate.isAtSameMomentAs(monthEnd);
    } else if (label == 'Last Month') {
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      isSelected = _fromDate.isAtSameMomentAs(lastMonthStart) && _toDate.isAtSameMomentAs(lastMonthEnd);
    }

    return ChoiceChip(
      label: Text(
        localizedLabel,
        style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          switch (label) {
            case 'Today':
              _fromDate = today;
              _toDate = today;
              break;
            case 'Yesterday':
              _fromDate = today.subtract(const Duration(days: 1));
              _toDate = today.subtract(const Duration(days: 1));
              break;
            case 'Last Week':
              _fromDate = today.subtract(const Duration(days: 7));
              _toDate = today;
              break;
            case 'Current Month':
              _fromDate = DateTime(now.year, now.month, 1);
              _toDate = DateTime(now.year, now.month + 1, 0);
              break;
            case 'Last Month':
              _fromDate = DateTime(now.year, now.month - 1, 1);
              _toDate = DateTime(now.year, now.month, 0);
              break;
          }
          
          _filterRecords();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFFFA726),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFFFFA726) : Colors.grey.shade300),
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final helpText = loc.selectDateRange;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: helpText,
      cancelText: loc.cancel,
      confirmText: loc.confirm,
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        if (_toDate.isBefore(picked)) {
          _toDate = picked;
        }
        _filterRecords();
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final helpText = loc.selectDateRange;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(2101),
      helpText: helpText,
      cancelText: loc.cancel,
      confirmText: loc.confirm,
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
        _filterRecords();
      });
    }
  }

  Widget _buildLineChart() {
    if (_chartData.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No data available for chart',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final producedSpots = _chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['produced'].toDouble());
    }).toList();

    final usedSpots = _chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['used'].toDouble());
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milk Production Chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _chartData[value.toInt()]['date'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFF37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: _chartData.length > 1 ? (_chartData.length - 1).toDouble() : 1,
                  minY: 0,
                  maxY: _chartData.map((d) => d['produced']).reduce((a, b) => a > b ? a : b).toDouble() * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: producedSpots,
                      isCurved: true,
                      color: const Color(0xFF4CAF50),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: usedSpots,
                      isCurved: true,
                      color: const Color(0xFFFF9800),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Produced', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 20),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Used', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String titleKey, String value, IconData icon, Color color) {
    final loc = AppLocalizations.of(context)!;
    
    String title;
    switch (titleKey) {
      case 'dailyAverage':
        title = loc.dailyMilkAverage;
        break;
      case 'totalProduced':
        title = loc.totalMilkProduced;
        break;
      case 'totalUsed':
        title = loc.totalForKidsUsed;
        break;
      case 'averageMorning':
        title = 'Average Morning';
        break;
      case 'averageEvening':
        title = 'Average Evening';
        break;
      default:
        title = titleKey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _loadMilkImage() async {
    try {
      final byteData = await rootBundle.load('assets/images/milk.png');
      return byteData.buffer.asUint8List();
    } catch (e) {
      return Uint8List(0);
    }
  }

  Future<void> _generatePDF() async {
    if (!mounted) return;
    
    final loc = AppLocalizations.of(context)!;
    
    if (!_summaryData['hasData']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.noDataToExport),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.pdfGenerating),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // Create PDF document
      final pdf = pw.Document();

      // Load milk.png image
      final milkImageBytes = await _loadMilkImage();
      pw.ImageProvider? milkImage;
      if (milkImageBytes.isNotEmpty) {
        milkImage = pw.MemoryImage(milkImageBytes);
      }

      // Add page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // CENTERED MILK.PNG LOGO AT TOP
                if (milkImage != null)
                  pw.Center(
                    child: pw.Container(
                      height: 80,
                      width: 80,
                      child: pw.Image(milkImage),
                    ),
                  ),
                
                if (milkImage == null)
                  pw.Center(
                    child: pw.Text(
                      'Milk Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                  ),
                
                pw.SizedBox(height: 10),
                
                // Farm name and location
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        _farmName,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        _farmLocation,
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                // Report period
                pw.Center(
                  child: pw.Text(
                    '${_formatDate(_fromDate)} - ${_formatDate(_toDate)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                pw.Text(
                  'Date: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 11),
                ),
                
                pw.SizedBox(height: 20),
                
                // Milk Summary table
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.green100),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Center(
                              child: pw.Text(
                                'Milk Summary',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.Container(),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Daily milk average',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${(_summaryData['dailyAverage'] as double).toStringAsFixed(1)} L'),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Total milk produced',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${(_summaryData['totalProduced'] as double).toStringAsFixed(1)} L'),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Total for kids/used',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${(_summaryData['totalUsed'] as double).toStringAsFixed(1)} L'),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Average morning milk',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${(_summaryData['averageMorning'] as double).toStringAsFixed(1)} L'),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Average evening milk',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${(_summaryData['averageEvening'] as double).toStringAsFixed(1)} L'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 25),
                
                // Milk Records table
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.5),
                      1: const pw.FlexColumnWidth(1.5),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1),
                      4: const pw.FlexColumnWidth(1),
                      5: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      // Table header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.green100),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Center(
                              child: pw.Text(
                                'Milk Records',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.Container(),
                          pw.Container(),
                          pw.Container(),
                          pw.Container(),
                          pw.Container(),
                        ],
                      ),
                      
                      // Column headers
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Date',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Type',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Morning',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Evening',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Total',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Used',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      
                      // Table data rows
                      ..._filteredRecords.map((record) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(DateFormat('yyyy-MM-dd').format(record.milkingDate)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(record.milkType),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(record.morningQuantity.toStringAsFixed(1)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(record.eveningQuantity.toStringAsFixed(1)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(record.total.toStringAsFixed(1)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(record.used.toStringAsFixed(1)),
                            ),
                          ],
                        );
                      }),
                      
                      // Total row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Total',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text((_summaryData['averageMorning'] as double).toStringAsFixed(1),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text((_summaryData['averageEvening'] as double).toStringAsFixed(1),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text((_summaryData['totalProduced'] as double).toStringAsFixed(1),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text((_summaryData['totalUsed'] as double).toStringAsFixed(1),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to file
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/milk_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(await pdf.save());

      // Share PDF
      await Share.shareXFiles([XFile(file.path)], text: 'Milk Report - $_farmName');

      // Success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildRecordsTable(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    final Map<String, Map<String, double>> dailyRecords = {};
    
    for (var record in _filteredRecords) {
      final dateKey = '${record.milkingDate.month.toString().padLeft(2, '0')}-${record.milkingDate.day.toString().padLeft(2, '0')}';
      if (!dailyRecords.containsKey(dateKey)) {
        dailyRecords[dateKey] = {'produced': 0.0, 'used': 0.0};
      }
      dailyRecords[dateKey]!['produced'] = dailyRecords[dateKey]!['produced']! + record.total;
      dailyRecords[dateKey]!['used'] = dailyRecords[dateKey]!['used']! + record.used;
    }

    final sortedDates = dailyRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${loc.records} (${_filteredRecords.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            if (sortedDates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    loc.noRecordsFound,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  dataRowMinHeight: 50,
                  dataRowMaxHeight: 50,
                  headingRowHeight: 40,
                  columns: [
                    DataColumn(
                      label: Text(loc.day, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text(loc.produced, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text(loc.used, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: sortedDates.map((date) {
                    final records = dailyRecords[date]!;
                    return DataRow(
                      cells: [
                        DataCell(Text(date)),
                        DataCell(Text(
                            (records['produced'] != null && records['produced']! > 0) ? records['produced']!.toStringAsFixed(1) : '-',
                          style: TextStyle(
                            color: records['produced']! > 0 ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                        DataCell(Text(
                            (records['used'] != null && records['used']! > 0) ? records['used']!.toStringAsFixed(1) : '-',
                          style: TextStyle(
                            color: records['used']! > 0 ? Colors.orange : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              loc.noRecordsFound,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '${_formatDate(_fromDate)} - ${_formatDate(_toDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    
    // Helper function to safely get summary value
    String getSummaryValue(String key) {
      final value = _summaryData[key];
      if (value is double) {
        return '${value.toStringAsFixed(1)} L';
      }
      return '0.0 L';
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Green Header with PDF icon and Chart toggle
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    loc.milkReport,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showLineChart = !_showLineChart;
                    });
                  },
                  icon: Icon(
                    _showLineChart ? Icons.table_chart : Icons.show_chart,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: _showLineChart ? 'Show Table' : 'Show Chart',
                ),
                IconButton(
                  onPressed: _generatePDF,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
                  tooltip: loc.exportPDF,
                ),
              ],
            ),
          ),
          
          // Orange Line
          Container(
            height: 4,
            color: const Color(0xFFFF9800),
          ),
          
          // Content
          Expanded(
            child: _isLoading 
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line Chart (if enabled)
                          if (_showLineChart)
                            Column(
                              children: [
                                _buildLineChart(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          
                          // Date Range Section
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Date Range',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Date chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildDateChip(context, 'Today', isSmallScreen),
                                      _buildDateChip(context, 'Yesterday', isSmallScreen),
                                      _buildDateChip(context, 'Last Week', isSmallScreen),
                                      _buildDateChip(context, 'Current Month', isSmallScreen),
                                      _buildDateChip(context, 'Last Month', isSmallScreen),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Custom date range
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'From',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _selectFromDate(context),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      _formatDate(_fromDate),
                                                      style: const TextStyle(fontSize: 14),
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
                                            Text(
                                              'To',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _selectToDate(context),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      _formatDate(_toDate),
                                                      style: const TextStyle(fontSize: 14),
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
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Milk Summary Section
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${loc.milkSummary} (${_formatDate(_fromDate)} - ${_formatDate(_toDate)})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Summary Cards Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isSmallScreen ? 1 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isSmallScreen ? 3.5 : 2.2,
                            children: [
                              _buildSummaryCard(
                                context,
                                'dailyAverage',
                                getSummaryValue('dailyAverage'),
                                Icons.local_drink,
                                const Color(0xFF2196F3),
                              ),
                              _buildSummaryCard(
                                context,
                                'totalProduced',
                                getSummaryValue('totalProduced'),
                                Icons.bar_chart,
                                const Color(0xFF4CAF50),
                              ),
                              _buildSummaryCard(
                                context,
                                'totalUsed',
                                getSummaryValue('totalUsed'),
                                Icons.child_care,
                                const Color(0xFFFF9800),
                              ),
                              _buildSummaryCard(
                                context,
                                'averageMorning',
                                getSummaryValue('averageMorning'),
                                Icons.wb_sunny,
                                const Color(0xFFFF9800),
                              ),
                              _buildSummaryCard(
                                context,
                                'averageEvening',
                                getSummaryValue('averageEvening'),
                                Icons.nights_stay,
                                const Color(0xFF2196F3),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Records Table or Empty State
                          if (!_summaryData['hasData'])
                            _buildEmptyState(context)
                          else
                            _buildRecordsTable(context),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}