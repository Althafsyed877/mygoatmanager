import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
import '../models/event.dart';
import 'edit_goat_page.dart';
import 'add_event_page.dart';
import '../services/archive_service.dart';

class ViewGoatPage extends StatefulWidget {
  final Goat goat;

  const ViewGoatPage({super.key, required this.goat});

  @override
  State<ViewGoatPage> createState() => _ViewGoatPageState();
}

class _ViewGoatPageState extends State<ViewGoatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  late Goat _currentGoat;
  List<Event> _goatEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentGoat = widget.goat;
    _loadPersistedImage();
    _loadGoatEvents();
  }

  Future<void> _loadPersistedImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('goat_image_${widget.goat.tagNo}');
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) {
          setState(() {
            _selectedImage = f;
            _currentGoat = Goat(
              tagNo: widget.goat.tagNo,
              name: widget.goat.name,
              breed: widget.goat.breed,
              gender: widget.goat.gender,
              goatStage: widget.goat.goatStage,
              dateOfBirth: widget.goat.dateOfBirth,
              dateOfEntry: widget.goat.dateOfEntry,
              weight: widget.goat.weight,
              group: widget.goat.group,
              obtained: widget.goat.obtained,
              motherTag: widget.goat.motherTag,
              fatherTag: widget.goat.fatherTag,
              notes: widget.goat.notes,
              photoPath: path,
            );
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadGoatEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('events');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data) as List<dynamic>;
        final allEvents = list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
        
        setState(() {
          _goatEvents = allEvents.where((event) => 
            event.tagNo == widget.goat.tagNo || 
            (event.isMassEvent && event.tagNo.contains(widget.goat.tagNo))
          ).toList();
        });
      }
    } catch (e) {
      // ignore errors
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime? _tryParseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      final isoDate = DateTime.tryParse(dateString);
      if (isoDate != null) return isoDate;
      
      final parts = dateString.split(RegExp(r'[/\-.]'));
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        
        if (year != null && month != null && day != null) {
          if (year > 1000 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
        
        if (parts[0].length == 4) {
          final year2 = int.tryParse(parts[0]);
          final month2 = int.tryParse(parts[1]);
          final day2 = int.tryParse(parts[2]);
          
          if (year2 != null && month2 != null && day2 != null) {
            return DateTime(year2, month2, day2);
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _calculateAge() {
    if (_currentGoat.dateOfBirth == null || _currentGoat.dateOfBirth!.isEmpty) {
      return '-';
    }
    
    final dobString = _currentGoat.dateOfBirth!;
    final dob = _tryParseDate(dobString);
    
    if (dob == null) return '-';
    
    final now = DateTime.now();
    
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    int days = now.day - dob.day;
    
    if (days < 0) {
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    
    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''} ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''} ${days > 0 ? '$days day${days > 1 ? 's' : ''}' : ''}';
    } else {
      return '$days day${days != 1 ? 's' : ''}';
    }
  }

  String _formatDisplayDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    final date = _tryParseDate(dateString);
    if (date == null) return dateString;
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatPdfDate(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatEventDate(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _calculateAgeAtDate(DateTime dob, DateTime atDate) {
    int years = atDate.year - dob.year;
    int months = atDate.month - dob.month;
    int days = atDate.day - dob.day;
    
    if (days < 0) {
      final prevMonth = DateTime(atDate.year, atDate.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    
    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''} ${days > 0 ? '$days day${days > 1 ? 's' : ''}' : ''}';
    } else {
      return '$days day${days != 1 ? 's' : ''}';
    }
  }

  List<Event> _getWeightEvents() {
    return _goatEvents
        .where((event) => event.eventType.toLowerCase().contains('weigh'))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Map<String, dynamic>> _calculateWeightGainData() {
    final weightEvents = _getWeightEvents();
    final List<Map<String, dynamic>> data = [];
    
    if (weightEvents.isEmpty) return data;
    
    DateTime? dob = _tryParseDate(_currentGoat.dateOfBirth);
    
    for (int i = 0; i < weightEvents.length; i++) {
      final event = weightEvents[i];
      final weightStr = event.weighedResult ?? '0';
      final weight = double.tryParse(weightStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      
      String age = '-';
      if (dob != null) {
        age = _calculateAgeAtDate(dob, event.date);
      }
      
      String gain = '-';
      String daysPassed = '-';
      String avgDailyGain = '-';
      
      if (i > 0) {
        final prevEvent = weightEvents[i - 1];
        final prevWeightStr = prevEvent.weighedResult ?? '0';
        final prevWeight = double.tryParse(prevWeightStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        
        final weightGain = weight - prevWeight;
        final daysBetween = event.date.difference(prevEvent.date).inDays;
        final dailyGain = daysBetween > 0 ? weightGain / daysBetween : 0;
        
        gain = weightGain.toStringAsFixed(2);
        daysPassed = daysBetween.toString();
        avgDailyGain = dailyGain.toStringAsFixed(2);
      }
      
      data.add({
        'date': event.date,
        'dateFormatted': _formatEventDate(event.date),
        'age': age,
        'weight': weight,
        'weightStr': weight.toStringAsFixed(2),
        'gain': gain,
        'daysPassed': daysPassed,
        'avgDailyGain': avgDailyGain,
      });
    }
    
    return data;
  }

  // Load goat's uploaded photo for PDF
  Future<Uint8List?> _loadSelectedGoatPhotoForPdf() async {
    try {
      // First try the current selected image
      if (_selectedImage != null && _selectedImage!.existsSync()) {
        return await _selectedImage!.readAsBytes();
      }
      
      // Try to load from stored path
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('goat_image_${widget.goat.tagNo}');
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          return await file.readAsBytes();
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Load default goat icon for PDF
  Future<Uint8List?> _loadDefaultGoatIconForPdf() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/goat.png');
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  void _showMenuOptions() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(400, 80, 0, 0), // Position at top-right corner
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.green[700]),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'event',
          child: Row(
            children: [
              Icon(Icons.event, color: Colors.orange[700]),
              const SizedBox(width: 12),
              const Text('Add Event'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'stage',
          child: Row(
            children: [
              Icon(Icons.switch_account, color: Colors.blue[700]),
              const SizedBox(width: 12),
              const Text('Change Stage'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'weight_report',
          child: Row(
            children: [
              Icon(Icons.scale, color: Colors.purple[700]),
              const SizedBox(width: 12),
              const Text('Weight Report'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export_pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red[700]),
              const SizedBox(width: 12),
              const Text('Export PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive, color: Colors.orange[700]),
              const SizedBox(width: 12),
              const Text('Archive'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red[700]),
              const SizedBox(width: 12),
              const Text('Delete Goat'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'edit':
            _navigateToEdit();
            break;
          case 'event':
            _navigateToAddEvent();
            break;
          case 'stage':
            _showChangeStageDialog();
            break;
          case 'weight_report':
            _exportWeightReportPdf();
            break;
          case 'export_pdf':
            _exportGoatDetailsPdf();
            break;
          case 'archive':
            _showArchiveDialog();
            break;
          case 'delete':
            _showDeleteDialog();
            break;
        }
      }
    });
  }

  Future<void> _exportWeightReportPdf() async {
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      
      // Load goat's photo for PDF (user uploaded photo takes priority)
      final selectedGoatPhotoBytes = await _loadSelectedGoatPhotoForPdf();
      final defaultGoatIconBytes = await _loadDefaultGoatIconForPdf();
      
      final weightData = _calculateWeightGainData();
      
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header with image
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Left: Image section
                    pw.Container(
                      width: 100,
                      height: 100,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
                      child: selectedGoatPhotoBytes != null
                          ? pw.Container(
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black, width: 1),
                              ),
                              child: pw.Image(
                                pw.MemoryImage(selectedGoatPhotoBytes),
                                width: 100,
                                height: 100,
                                fit: pw.BoxFit.cover,
                              ),
                            )
                          : (defaultGoatIconBytes != null
                              ? pw.Center(
                                  child: pw.Image(
                                    pw.MemoryImage(defaultGoatIconBytes),
                                    width: 60,
                                    height: 60,
                                  ),
                                )
                              : pw.Container()),
                    ),
                    
                    // Center: Title
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'WEIGHT GROWTH REPORT',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Goat Tag: ${_currentGoat.tagNo}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              color: PdfColors.black,
                            ),
                          ),
                          if (_currentGoat.name != null && _currentGoat.name!.isNotEmpty)
                            pw.Text(
                              'Name: ${_currentGoat.name!}',
                              style: pw.TextStyle(
                                fontSize: 14,
                                color: PdfColors.black,
                              ),
                            ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Generated on: ${_formatPdfDate(now)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right: Empty space for balance
                    pw.Container(width: 100),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 20),
                
                // Goat details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Goat Information',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfInfoRow('Breed:', _currentGoat.breed ?? '-'),
                                _buildPdfInfoRow('Gender:', _currentGoat.gender),
                                _buildPdfInfoRow('Date of Birth:', _formatDisplayDate(_currentGoat.dateOfBirth)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfInfoRow('Age:', _calculateAge()),
                                _buildPdfInfoRow('Stage:', _currentGoat.goatStage ?? '-'),
                                _buildPdfInfoRow('Current Weight:', _currentGoat.weight ?? '-'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Weight table title
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Text(
                    'WEIGHT HISTORY',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                
                pw.SizedBox(height: 16),
                
                // Weight table
                if (weightData.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: ['Date', 'Age at Weighing', 'Weight (kg)', 'Gain (kg)', 'Days', 'Avg Daily Gain'],
                    data: weightData.map((data) => [
                      data['dateFormatted'] as String,
                      data['age'] as String,
                      data['weightStr'] as String,
                      data['gain'] as String,
                      data['daysPassed'] as String,
                      data['avgDailyGain'] as String,
                    ]).toList(),
                    border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                    headerStyle: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.green),
                    cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerRight,
                      5: pw.Alignment.centerRight,
                    },
                    headerAlignment: pw.Alignment.center,
                    cellAlignment: pw.Alignment.center,
                    columnWidths: {
                      0: pw.FlexColumnWidth(1.5),
                      1: pw.FlexColumnWidth(2),
                      2: pw.FlexColumnWidth(1),
                      3: pw.FlexColumnWidth(1),
                      4: pw.FlexColumnWidth(0.8),
                      5: pw.FlexColumnWidth(1.2),
                    },
                  )
                else
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    child: pw.Text(
                      'No weight records available',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                
                pw.SizedBox(height: 30),
                
                // Summary
                if (weightData.length > 1)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SUMMARY',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Total Weightings:',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '${weightData.length}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'First Weight:',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              '${weightData.first['weightStr']} kg',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Latest Weight:',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              '${weightData.last['weightStr']} kg',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        if (weightData.length > 1)
                          pw.SizedBox(height: 4),
                        if (weightData.length > 1)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Total Gain:',
                                style: pw.TextStyle(fontSize: 11),
                              ),
                              pw.Text(
                                '${(double.parse(weightData.last['weightStr'] as String) - double.parse(weightData.first['weightStr'] as String)).toStringAsFixed(2)} kg',
                                style: pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generated by Goat Manager',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Page 1 of 1',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Weight_Report_${_currentGoat.tagNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating weight report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper for PDF info rows
  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportGoatDetailsPdf() async {
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      
      // Load goat's photo for PDF
      final selectedGoatPhotoBytes = await _loadSelectedGoatPhotoForPdf();
      final defaultGoatIconBytes = await _loadDefaultGoatIconForPdf();
      
      final weightEvents = _goatEvents.where((e) => e.eventType.toLowerCase().contains('weigh')).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      final otherEvents = _goatEvents.where((e) => !e.eventType.toLowerCase().contains('weigh')).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // First Page - Goat Details
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header with large image
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Goat image (larger)
                    pw.Container(
                      width: 180,
                      height: 180,
                      margin: const pw.EdgeInsets.only(right: 20),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 2),
                      ),
                      child: selectedGoatPhotoBytes != null
                          ? pw.Container(
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black, width: 2),
                              ),
                              child: pw.Image(
                                pw.MemoryImage(selectedGoatPhotoBytes),
                                width: 180,
                                height: 180,
                                fit: pw.BoxFit.cover,
                              ),
                            )
                          : (defaultGoatIconBytes != null
                              ? pw.Center(
                                  child: pw.Image(
                                    pw.MemoryImage(defaultGoatIconBytes),
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : pw.Container()),
                    ),
                    
                    // Goat info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'GOAT DETAILS REPORT',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'Tag: ${_currentGoat.tagNo}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue,
                            ),
                          ),
                          if (_currentGoat.name != null && _currentGoat.name!.isNotEmpty)
                            pw.Text(
                              'Name: ${_currentGoat.name!}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.black,
                              ),
                            ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Generated on: ${_formatPdfDate(now)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                pw.Divider(thickness: 2, color: PdfColors.black),
                pw.SizedBox(height: 20),
                
                // General Details section
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GENERAL INFORMATION',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      
                      // Two column layout for details
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Left column
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfDetailRow('Tag No:', _currentGoat.tagNo),
                                _buildPdfDetailRow('Name:', _currentGoat.name ?? '-'),
                                _buildPdfDetailRow('Date of Birth:', _formatDisplayDate(_currentGoat.dateOfBirth)),
                                _buildPdfDetailRow('Age:', _calculateAge()),
                                _buildPdfDetailRow('Gender:', _currentGoat.gender),
                                _buildPdfDetailRow('Weight:', _currentGoat.weight ?? '-'),
                                _buildPdfDetailRow('Stage:', _currentGoat.goatStage ?? '-'),
                              ],
                            ),
                          ),
                          
                          pw.SizedBox(width: 20),
                          
                          // Right column
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfDetailRow('Breed:', _currentGoat.breed ?? '-'),
                                _buildPdfDetailRow('Group:', _currentGoat.group ?? '-'),
                                _buildPdfDetailRow('Joined On:', _formatDisplayDate(_currentGoat.dateOfEntry)),
                                _buildPdfDetailRow('Source:', _currentGoat.obtained ?? '-'),
                                _buildPdfDetailRow('Mother Tag:', _currentGoat.motherTag ?? '-'),
                                _buildPdfDetailRow('Father Tag:', _currentGoat.fatherTag ?? '-'),
                                _buildPdfDetailRow('Status:', 'Active'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      pw.SizedBox(height: 16),
                      
                      // Notes section
                      if (_currentGoat.notes != null && _currentGoat.notes!.isNotEmpty)
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'NOTES',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                _currentGoat.notes!,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Goat Manager - Comprehensive Goat Management System',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Page 1 of ${(weightEvents.isNotEmpty || otherEvents.isNotEmpty) ? 2 : 1}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Second Page - Events (if any)
      if (weightEvents.isNotEmpty || otherEvents.isNotEmpty) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(30),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Header for events page
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 80,
                        height: 80,
                        margin: const pw.EdgeInsets.only(right: 16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 1),
                        ),
                        child: selectedGoatPhotoBytes != null
                            ? pw.Container(
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.black, width: 1),
                                ),
                                child: pw.Image(
                                  pw.MemoryImage(selectedGoatPhotoBytes),
                                  width: 80,
                                  height: 80,
                                  fit: pw.BoxFit.cover,
                                ),
                              )
                            : (defaultGoatIconBytes != null
                                ? pw.Center(
                                    child: pw.Image(
                                      pw.MemoryImage(defaultGoatIconBytes),
                                      width: 50,
                                      height: 50,
                                    ),
                                  )
                                : pw.Container()),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'EVENTS HISTORY',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Goat: ${_currentGoat.tagNo}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Total Events: ${_goatEvents.length}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 30),
                  pw.Divider(thickness: 1, color: PdfColors.grey),
                  pw.SizedBox(height: 20),
                  
                  // Events list
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (weightEvents.isNotEmpty)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue50,
                              ),
                              child: pw.Text(
                                'WEIGHT EVENTS (${weightEvents.length})',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            ...weightEvents.map((event) => _buildEventCardPdf(event)),
                            pw.SizedBox(height: 20),
                          ],
                        ),
                      
                      if (otherEvents.isNotEmpty)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.green50,
                              ),
                              child: pw.Text(
                                'OTHER EVENTS (${otherEvents.length})',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            ...otherEvents.map((event) => _buildEventCardPdf(event)),
                          ],
                        ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 30),
                  
                  // Footer
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Goat Manager - Comprehensive Goat Management System',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          'Page 2 of 2',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Goat_Details_${_currentGoat.tagNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating goat details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper for PDF detail rows
  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for PDF event cards
  pw.Widget _buildEventCardPdf(Event event) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Event header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '●',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.blue,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  event.eventType.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  _formatEventDate(event.date),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Event details
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (event.weighedResult != null && event.weighedResult!.isNotEmpty)
                  _buildEventDetailRowPdf('Weight:', event.weighedResult!),
                if (event.medicine != null && event.medicine!.isNotEmpty)
                  _buildEventDetailRowPdf('Medicine:', event.medicine!),
                if (event.symptoms != null && event.symptoms!.isNotEmpty)
                  _buildEventDetailRowPdf('Symptoms:', event.symptoms!),
                if (event.diagnosis != null && event.diagnosis!.isNotEmpty)
                  _buildEventDetailRowPdf('Diagnosis:', event.diagnosis!),
                if (event.technician != null && event.technician!.isNotEmpty)
                  _buildEventDetailRowPdf('Technician:', event.technician!),
                if (event.otherName != null && event.otherName!.isNotEmpty)
                  _buildEventDetailRowPdf('Description:', event.otherName!),
                if (event.notes != null && event.notes!.isNotEmpty)
                  _buildEventDetailRowPdf('Notes:', event.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for PDF event detail rows
  pw.Widget _buildEventDetailRowPdf(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit() async {
    final updatedGoat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGoatPage(goat: _currentGoat),
      ),
    );
    
    if (updatedGoat != null && mounted) {
      setState(() {
        _currentGoat = updatedGoat;
      });
      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final goatsJson = prefs.getString('goats');
      if (goatsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(goatsJson);
          for (var i = 0; i < decoded.length; i++) {
            if (decoded[i]['tagNo'] == _currentGoat.tagNo) {
              decoded[i] = _currentGoat.toJson();
              break;
            }
          }
          await prefs.setString('goats', jsonEncode(decoded));
        } catch (_) {}
      }
      
      // ignore: use_build_context_synchronously
      Navigator.pop(context, _currentGoat);
    }
  }

  void _navigateToAddEvent() async {
    final event = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(goat: _currentGoat),
      ),
    );
    
    if (event != null && mounted) {
      _loadGoatEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event added for ${_currentGoat.tagNo}'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  void _showChangeStageDialog() {
    final stages = ['Kid', 'Wether', 'Buckling', 'Buck', 'Doe'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Goat Stage'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final stage = stages[index];
                return ListTile(
                  title: Text(stage),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateGoatStage(stage);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // FIXED: Update goat stage function
  Future<void> _updateGoatStage(String newStage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goatsJson = prefs.getString('goats');
      if (goatsJson != null) {
        final List<dynamic> decoded = jsonDecode(goatsJson);
        
        bool updated = false;
        for (var item in decoded) {
          if (item['tagNo'] == _currentGoat.tagNo) {
            item['goatStage'] = newStage;
            updated = true;
            break;
          }
        }
        
        if (updated) {
          await prefs.setString('goats', jsonEncode(decoded));
          
          setState(() {
            _currentGoat = Goat(
              tagNo: _currentGoat.tagNo,
              name: _currentGoat.name,
              breed: _currentGoat.breed,
              gender: _currentGoat.gender,
              goatStage: newStage,
              dateOfBirth: _currentGoat.dateOfBirth,
              dateOfEntry: _currentGoat.dateOfEntry,
              weight: _currentGoat.weight,
              group: _currentGoat.group,
              obtained: _currentGoat.obtained,
              motherTag: _currentGoat.motherTag,
              fatherTag: _currentGoat.fatherTag,
              notes: _currentGoat.notes,
              photoPath: _currentGoat.photoPath,
            );
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Stage updated to $newStage'),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UPDATED: Proper Archive Dialog
  void _showArchiveDialog() {
    final reasons = ['sold', 'dead', 'lost', 'other'];
    final reasonLabels = ['Sold', 'Dead', 'Lost', 'Other'];
    
    String? selectedReason;
    String notes = '';
    DateTime archiveDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Archive Goat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Goat: ${_currentGoat.tagNo} - ${_currentGoat.name ?? "Unnamed"}'),
                    const SizedBox(height: 16),
                    // Reason selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Reason for Archive',
                        border: OutlineInputBorder(),
                      ),
                      items: reasons.asMap().entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(reasonLabels[entry.key]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() => selectedReason = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date selection
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: archiveDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateDialog(() => archiveDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text('${archiveDate.day}/${archiveDate.month}/${archiveDate.year}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Notes
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => notes = value,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedReason != null) {
                      Navigator.of(ctx).pop();
                      await _performArchive(selectedReason!, archiveDate, notes);
                    }
                  },
                  child: const Text('Archive'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Perform actual archiving
  Future<void> _performArchive(String reason, DateTime archiveDate, String notes) async {
    try {
      // Create archive record using ArchiveService
      await ArchiveService.archiveGoat(
        goat: _currentGoat,
        reason: reason,
        archiveDate: archiveDate,
        notes: notes.isEmpty ? null : notes,
      );
      
      // Also create an archive event for reporting
      await _createArchiveEvent(_currentGoat, reason, archiveDate, notes);
      
      // Remove from active goats list
      await _removeFromActiveGoats(_currentGoat.tagNo);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goat ${_currentGoat.tagNo} archived as $reason'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        
        // Navigate back to goats list page
        Navigator.pop(context, 'archived');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error archiving goat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create archive event
  Future<void> _createArchiveEvent(Goat goat, String reason, DateTime date, String notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing events
      final eventsData = prefs.getString('events') ?? '[]';
      final List<dynamic> eventsList = jsonDecode(eventsData);
      final List<Event> events = eventsList.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
      
      // Create archive event
      final archiveEvent = Event(
        date: date,
        tagNo: goat.tagNo,
        eventType: _getArchiveEventType(reason),
        notes: notes.isEmpty ? null : notes,
        isMassEvent: false,
      );
      
      // Add to events list
      events.add(archiveEvent);
      
      // Save back to SharedPreferences
      final updatedEvents = events.map((e) => e.toJson()).toList();
      await prefs.setString('events', jsonEncode(updatedEvents));
      
      // debugPrint('Archive event created for ${goat.tagNo} as $reason');
    } catch (e) {
      // debugPrint('Error creating archive event: $e');
    }
  }

  // Helper to convert archive reason to event type
  String _getArchiveEventType(String reason) {
    switch (reason) {
      case 'sold':
        return 'Sold';
      case 'dead':
        return 'Dead';
      case 'lost':
        return 'Lost';
      default:
        return 'Archived';
    }
  }

  // Remove goat from active goats list
  Future<void> _removeFromActiveGoats(String tagNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goatsJson = prefs.getString('goats');
      
      if (goatsJson != null) {
        final List<dynamic> decoded = jsonDecode(goatsJson);
        decoded.removeWhere((item) => item['tagNo'] == tagNo);
        await prefs.setString('goats', jsonEncode(decoded));
      }
      
      // Also remove stored photo if exists
      await prefs.remove('goat_image_$tagNo');
      
    } catch (e) {
      // debugPrint('Error removing goat from active list: $e');
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Goat'),
          content: Text('Are you sure you want to delete goat ${_currentGoat.tagNo}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteGoat();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete function with archiving - FIXED BuildContext async gap
  Future<void> _deleteGoat() async {
    try {
      // First archive as 'other' with delete note
      await ArchiveService.archiveGoat(
        goat: _currentGoat,
        reason: 'other',
        archiveDate: DateTime.now(),
        notes: 'Deleted permanently',
      );
      
      // Remove from active goats
      await _removeFromActiveGoats(_currentGoat.tagNo);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goat ${_currentGoat.tagNo} deleted'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Navigate back only if still mounted
        if (mounted) {
          Navigator.pop(context, 'deleted');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting goat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color genderColor = _currentGoat.gender.toLowerCase() == 'male'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA726);

    return Scaffold(
      body: Column(
        children: [
          // Top image section
          Container(
            height: 340,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=800&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 40,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context, _currentGoat),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                      onPressed: _showMenuOptions,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/goat.png',
                        color: genderColor,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Text(
                      _currentGoat.tagNo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: genderColor,
              labelColor: genderColor,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  icon: const Icon(Icons.info_outline),
                  text: AppLocalizations.of(context)!.details,
                ),
                Tab(
                  icon: const Icon(Icons.event),
                  text: AppLocalizations.of(context)!.events,
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildEventsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    Color genderColor = _currentGoat.gender.toLowerCase() == 'male'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA726);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: genderColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'General Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: _navigateToEdit,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow('Tag No', _currentGoat.tagNo),
                        _buildDetailRow('Name', _currentGoat.name ?? '-'),
                        _buildDetailRow('D.O.B', _formatDisplayDate(_currentGoat.dateOfBirth)),
                        _buildDetailRow('Age', _calculateAge()),
                        _buildDetailRow('Gender', _currentGoat.gender, valueColor: genderColor),
                        _buildDetailRow('Weight', _currentGoat.weight ?? '-'),
                        _buildDetailRow('Stage', _currentGoat.goatStage ?? '-'),
                        _buildDetailRow('Breed', _currentGoat.breed ?? '-'),
                        _buildDetailRow('Group', _currentGoat.group ?? '-'),
                        _buildDetailRow('Joined On', _formatDisplayDate(_currentGoat.dateOfEntry)),
                        _buildDetailRow('Source', _currentGoat.obtained ?? '-'),
                        _buildDetailRow('Mother', _currentGoat.motherTag ?? '-'),
                        _buildDetailRow('Father', _currentGoat.fatherTag ?? '-'),
                        _buildDetailRow('Notes', _currentGoat.notes ?? '-'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null)
              Container(
                width: double.infinity,
                height: 300,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: genderColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _pickImage,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedImage == null ? Icons.camera_alt : Icons.edit,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedImage == null 
                            ? 'Tap to upload'
                            : 'Change Picture',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_goatEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'No events yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goatEvents.length,
      itemBuilder: (context, index) {
        final event = _goatEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    Color cardColor = _currentGoat.gender.toLowerCase() == 'male' 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFFFFA726);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  event.isMassEvent ? Icons.group : Icons.person,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.eventType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventDetailRow('Date', _formatEventDate(event.date)),
                if (event.symptoms != null && event.symptoms!.isNotEmpty)
                  _buildEventDetailRow('Symptoms', event.symptoms!),
                if (event.diagnosis != null && event.diagnosis!.isNotEmpty)
                  _buildEventDetailRow('Diagnosis', event.diagnosis!),
                if (event.technician != null && event.technician!.isNotEmpty)
                  _buildEventDetailRow('Treated by', event.technician!),
                if (event.medicine != null && event.medicine!.isNotEmpty)
                  _buildEventDetailRow('Medicine', event.medicine!),
                if (event.weighedResult != null && event.weighedResult!.isNotEmpty)
                  _buildEventDetailRow('Weight', event.weighedResult!),
                if (event.otherName != null && event.otherName!.isNotEmpty)
                  _buildEventDetailRow('Event', event.otherName!),
                if (event.notes != null && event.notes!.isNotEmpty)
                  _buildEventDetailRow('Notes', event.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    Color defaultColor = _currentGoat.gender.toLowerCase() == 'male'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA726);
        
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor ?? defaultColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(sheetContext, 'remove'),
                ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    if (result == 'camera' || result == 'gallery') {
      final source = result == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() => _selectedImage = File(image.path));
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('goat_image_${_currentGoat.tagNo}', image.path);
        
        final goatsJson = prefs.getString('goats');
        if (goatsJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(goatsJson);
            for (var item in decoded) {
              if (item['tagNo'] == _currentGoat.tagNo) {
                item['photoPath'] = image.path;
                break;
              }
            }
            await prefs.setString('goats', jsonEncode(decoded));
          } catch (_) {}
        }
        
        _currentGoat = Goat(
          tagNo: _currentGoat.tagNo,
          name: _currentGoat.name,
          breed: _currentGoat.breed,
          gender: _currentGoat.gender,
          goatStage: _currentGoat.goatStage,
          dateOfBirth: _currentGoat.dateOfBirth,
          dateOfEntry: _currentGoat.dateOfEntry,
          weight: _currentGoat.weight,
          group: _currentGoat.group,
          obtained: _currentGoat.obtained,
          motherTag: _currentGoat.motherTag,
          fatherTag: _currentGoat.fatherTag,
          notes: _currentGoat.notes,
          photoPath: image.path,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result == 'camera' ? 'Photo captured' : 'Image selected'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      }
    } else if (result == 'remove' && mounted) {
      setState(() => _selectedImage = null);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('goat_image_${_currentGoat.tagNo}');
      
      final goatsJson = prefs.getString('goats');
      if (goatsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(goatsJson);
          for (var item in decoded) {
            if (item['tagNo'] == _currentGoat.tagNo) {
              item.remove('photoPath');
              break;
            }
          }
          await prefs.setString('goats', jsonEncode(decoded));
        } catch (_) {}
      }
      
      _currentGoat = Goat(
        tagNo: _currentGoat.tagNo,
        name: _currentGoat.name,
        breed: _currentGoat.breed,
        gender: _currentGoat.gender,
        goatStage: _currentGoat.goatStage,
        dateOfBirth: _currentGoat.dateOfBirth,
        dateOfEntry: _currentGoat.dateOfEntry,
        weight: _currentGoat.weight,
        group: _currentGoat.group,
        obtained: _currentGoat.obtained,
        motherTag: _currentGoat.motherTag,
        fatherTag: _currentGoat.fatherTag,
        notes: _currentGoat.notes,
        photoPath: null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo removed'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }
}