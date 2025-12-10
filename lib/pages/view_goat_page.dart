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
    if (widget.goat.dateOfBirth == null || widget.goat.dateOfBirth!.isEmpty) {
      return '-';
    }
    
    final dobString = widget.goat.dateOfBirth!;
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

  String _formatPdfDateTime(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year} $hour:$minute';
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
    
    DateTime? dob = _tryParseDate(widget.goat.dateOfBirth);
    
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Options for ${widget.goat.tagNo}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                
                _buildMenuItem(
                  icon: Icons.edit,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'Edit',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEdit();
                  },
                ),
                
                _buildMenuItem(
                  icon: Icons.event,
                  iconColor: const Color(0xFFFF9800),
                  title: 'Add Event',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAddEvent();
                  },
                ),
                
                _buildMenuItem(
                  icon: Icons.switch_account,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Change Stage',
                  onTap: () {
                    Navigator.pop(context);
                    _showChangeStageDialog();
                  },
                ),
                
                _buildMenuItem(
                  icon: Icons.scale,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Weight Report',
                  onTap: () {
                    Navigator.pop(context);
                    _exportWeightReportPdf();
                  },
                ),
                
                _buildMenuItem(
                  icon: Icons.picture_as_pdf,
                  iconColor: const Color(0xFFF44336),
                  title: 'Export Pdf',
                  onTap: () {
                    Navigator.pop(context);
                    _exportGoatDetailsPdf();
                  },
                ),
                
                _buildMenuItem(
                  icon: Icons.archive,
                  iconColor: const Color(0xFFFF9800),
                  title: 'Archive (Sold, dead...)',
                  onTap: () {
                    Navigator.pop(context);
                    _showArchiveDialog();
                  },
                ),
                
                _buildMenuItem(
                  icon: Icons.delete,
                  iconColor: Colors.red,
                  title: 'Delete Goat',
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteDialog();
                  },
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportWeightReportPdf() async {
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      
      // Load goat's photo for PDF (user uploaded photo takes priority)
      final selectedGoatPhotoBytes = await _loadSelectedGoatPhotoForPdf();
      final defaultGoatIconBytes = await _loadDefaultGoatIconForPdf();
      
      final weightData = _calculateWeightGainData();
      
      // Header section with goat photo
      final headerSection = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Goat photo at the top (from user upload)
          if (selectedGoatPhotoBytes != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Container(
                width: 120,
                height: 120,
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.ClipRRect(
                  child: pw.Image(
                    pw.MemoryImage(selectedGoatPhotoBytes),
                    width: 120,
                    height: 120,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            )
          else if (defaultGoatIconBytes != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Image(
                pw.MemoryImage(defaultGoatIconBytes),
                width: 60,
                height: 60,
              ),
            ),
          
          // Farm settings text
          pw.Text(
            'Set farm\'s logo under app settings!',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Set farm name under app settings!',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Set farm location under app settings!',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 16),
          
          // Title
          pw.Text(
            'Weight Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          
          // Goat info
          pw.Text(
            'Goat: ${widget.goat.tagNo} ${widget.goat.name != null && widget.goat.name!.isNotEmpty ? '(${widget.goat.name})' : ''}',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          
          // Date
          pw.Text(
            'Date: ${_formatPdfDateTime(now)}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey,
            ),
          ),
          pw.SizedBox(height: 16),
          
          // Divider line
          pw.Divider(thickness: 1, color: PdfColors.black),
          pw.SizedBox(height: 16),
          
          // Growth Table Title
          pw.Text(
            'Growth Table',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 16),
        ],
      );

      final tableHeaders = ['Date', 'Age', 'Result', 'Gain', 'Days Passed', 'Avg Daily Gain'];
      final tableData = <List<String>>[];
      
      for (var data in weightData) {
        tableData.add([
          data['dateFormatted'] as String,
          data['age'] as String,
          data['weightStr'] as String,
          data['gain'] as String,
          data['daysPassed'] as String,
          data['avgDailyGain'] as String,
        ]);
      }
      
      final table = pw.TableHelper.fromTextArray(
        headers: tableHeaders,
        data: tableData,
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: pw.TextStyle(fontSize: 9),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
          5: pw.Alignment.centerRight,
        },
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                headerSection,
                table,
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Weight_Report_${widget.goat.tagNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

  Future<void> _exportGoatDetailsPdf() async {
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      
      // Load goat's photo for PDF (user uploaded photo takes priority)
      final selectedGoatPhotoBytes = await _loadSelectedGoatPhotoForPdf();
      final defaultGoatIconBytes = await _loadDefaultGoatIconForPdf();
      
      final weightEvents = _goatEvents.where((e) => e.eventType.toLowerCase().contains('weigh')).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      final otherEvents = _goatEvents.where((e) => !e.eventType.toLowerCase().contains('weigh')).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // First Page - Goat Details with Photo
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Goat photo at the top (from user upload)
                if (selectedGoatPhotoBytes != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    child: pw.Container(
                      width: 150,
                      height: 150,
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.ClipRRect(
                        child: pw.Image(
                          pw.MemoryImage(selectedGoatPhotoBytes),
                          width: 150,
                          height: 150,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else if (defaultGoatIconBytes != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Image(
                      pw.MemoryImage(defaultGoatIconBytes),
                      width: 80,
                      height: 80,
                    ),
                  ),
                
                // Farm settings text
                pw.Text(
                  'Set farm\'s logo under app settings!',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Set farm name under app settings!',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Set farm location under app settings!',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 16),
                
                // Title
                pw.Text(
                  'Goat Details',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 8),
                
                // Tag and date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Tag: ${widget.goat.tagNo}',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.black),
                    ),
                    pw.Text(
                      'Date: ${_formatPdfDateTime(now)}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                
                // Goat name if available
                if (widget.goat.name != null && widget.goat.name!.isNotEmpty)
                  pw.Text(
                    'Name: ${widget.goat.name!}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                  ),
                
                pw.SizedBox(height: 16),
                
                // Divider
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 16),
                
                // General Details section
                pw.Text(
                  'General Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 12),
                
                // Details table
                pw.Table(
                  border: null,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    _buildPdfDetailRow('Tag No:', widget.goat.tagNo),
                    _buildPdfDetailRow('Name:', widget.goat.name ?? '-'),
                    _buildPdfDetailRow('D.O.B:', _formatDisplayDate(widget.goat.dateOfBirth)),
                    _buildPdfDetailRow('Age:', _calculateAge()),
                    _buildPdfDetailRow('Gender:', widget.goat.gender),
                    _buildPdfDetailRow('Weight:', widget.goat.weight ?? '-'),
                    _buildPdfDetailRow('Stage:', widget.goat.goatStage ?? '-'),
                    _buildPdfDetailRow('Breed:', widget.goat.breed ?? '-'),
                    _buildPdfDetailRow('Group:', widget.goat.group ?? '-'),
                    _buildPdfDetailRow('Joined On:', _formatDisplayDate(widget.goat.dateOfEntry)),
                    _buildPdfDetailRow('Source:', widget.goat.obtained ?? '-'),
                    _buildPdfDetailRow('Mother:', widget.goat.motherTag ?? '-'),
                    _buildPdfDetailRow('Father:', widget.goat.fatherTag ?? '-'),
                    _buildPdfDetailRow('Notes:', widget.goat.notes ?? '-'),
                    _buildPdfDetailRow('Archived', 'No'),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Second Page - Events
      if (weightEvents.isNotEmpty || otherEvents.isNotEmpty) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Goat photo at the top (from user upload)
                  if (selectedGoatPhotoBytes != null)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Container(
                        width: 100,
                        height: 100,
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.ClipRRect(
                          child: pw.Image(
                            pw.MemoryImage(selectedGoatPhotoBytes),
                            width: 100,
                            height: 100,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else if (defaultGoatIconBytes != null)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Image(
                        pw.MemoryImage(defaultGoatIconBytes),
                        width: 60,
                        height: 60,
                      ),
                    ),
                  
                  // Farm settings text
                  pw.Text(
                    'Set farm\'s logo under app settings!',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Set farm name under app settings!',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Set farm location under app settings!',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 16),
                  
                  // Events Title
                  pw.Text(
                    'Events',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Events list
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      ...weightEvents.map((event) => _buildEventCardPdf(event)),
                      ...otherEvents.map((event) => _buildEventCardPdf(event)),
                    ],
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
        filename: 'Goat_Details_${widget.goat.tagNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
  pw.TableRow _buildPdfDetailRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  // Helper for PDF event cards
  pw.Widget _buildEventCardPdf(Event event) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Event header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Text(
              event.eventType,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          
          // Event details
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Table(
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                _buildEventDetailRowPdf('Type:', event.eventType),
                _buildEventDetailRowPdf('Date:', _formatEventDate(event.date)),
                if (event.weighedResult != null)
                  _buildEventDetailRowPdf('Result:', event.weighedResult!),
                if (event.medicine != null)
                  _buildEventDetailRowPdf('Medicine:', event.medicine!),
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
  pw.TableRow _buildEventDetailRowPdf(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToEdit() async {
    final updatedGoat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGoatPage(goat: widget.goat),
      ),
    );
    
    if (updatedGoat != null && mounted) {
      Navigator.pop(context, updatedGoat);
    }
  }

  void _navigateToAddEvent() async {
    final event = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(goat: widget.goat),
      ),
    );
    
    if (event != null && mounted) {
      _loadGoatEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event added for ${widget.goat.tagNo}'),
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

  Future<void> _updateGoatStage(String newStage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goatsJson = prefs.getString('goats');
      if (goatsJson != null) {
        final List<dynamic> decoded = jsonDecode(goatsJson);
        
        for (var item in decoded) {
          if (item['tagNo'] == widget.goat.tagNo) {
            item['goatStage'] = newStage;
            break;
          }
        }
        
        await prefs.setString('goats', jsonEncode(decoded));
        
        setState(() {
          _currentGoat = Goat(
            tagNo: widget.goat.tagNo,
            name: widget.goat.name,
            breed: widget.goat.breed,
            gender: widget.goat.gender,
            goatStage: newStage,
            dateOfBirth: widget.goat.dateOfBirth,
            dateOfEntry: widget.goat.dateOfEntry,
            weight: widget.goat.weight,
            group: widget.goat.group,
            obtained: widget.goat.obtained,
            motherTag: widget.goat.motherTag,
            fatherTag: widget.goat.fatherTag,
            notes: widget.goat.notes,
            photoPath: widget.goat.photoPath,
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

  void _showArchiveDialog() {
    final reasons = ['Sold', 'Dead', 'Lost', 'Other'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archive Goat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select reason for archiving:'),
              const SizedBox(height: 16),
              ...reasons.map((reason) {
                return ListTile(
                  title: Text(reason),
                  onTap: () {
                    Navigator.pop(context);
                    _archiveGoat(reason);
                  },
                );
              }),
            ],
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

  Future<void> _archiveGoat(String reason) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archiving goat ${widget.goat.tagNo} as $reason'),
            backgroundColor: const Color(0xFFFF9800),
          ),
        );
      }
      
      if (mounted) {
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Goat'),
          content: Text('Are you sure you want to delete goat ${widget.goat.tagNo}? This action cannot be undone.'),
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

  Future<void> _deleteGoat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goatsJson = prefs.getString('goats');
      if (goatsJson != null) {
        final List<dynamic> decoded = jsonDecode(goatsJson);
        decoded.removeWhere((item) => item['tagNo'] == widget.goat.tagNo);
        await prefs.setString('goats', jsonEncode(decoded));
        
        await prefs.remove('goat_image_${widget.goat.tagNo}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Goat ${widget.goat.tagNo} deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
        
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
    Color genderColor = widget.goat.gender.toLowerCase() == 'male'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA726);

    return Scaffold(
      body: Column(
        children: [
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
                      widget.goat.tagNo,
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
    Color genderColor = widget.goat.gender.toLowerCase() == 'male'
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
                        _buildDetailRow('Tag No', widget.goat.tagNo),
                        _buildDetailRow('Name', widget.goat.name ?? '-'),
                        _buildDetailRow('D.O.B', _formatDisplayDate(widget.goat.dateOfBirth)),
                        _buildDetailRow('Age', _calculateAge()),
                        _buildDetailRow('Gender', widget.goat.gender, valueColor: genderColor),
                        _buildDetailRow('Weight', widget.goat.weight ?? '-'),
                        _buildDetailRow('Stage', widget.goat.goatStage ?? '-'),
                        _buildDetailRow('Breed', widget.goat.breed ?? '-'),
                        _buildDetailRow('Group', widget.goat.group ?? '-'),
                        _buildDetailRow('Joined On', _formatDisplayDate(widget.goat.dateOfEntry)),
                        _buildDetailRow('Source', widget.goat.obtained ?? '-'),
                        _buildDetailRow('Mother', widget.goat.motherTag ?? '-'),
                        _buildDetailRow('Father', widget.goat.fatherTag ?? '-'),
                        _buildDetailRow('Notes', widget.goat.notes ?? '-'),
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
    Color cardColor = widget.goat.gender.toLowerCase() == 'male' 
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
                if (event.symptoms != null) 
                  _buildEventDetailRow('Symptoms', event.symptoms!),
                if (event.diagnosis != null) 
                  _buildEventDetailRow('Diagnosis', event.diagnosis!),
                if (event.technician != null) 
                  _buildEventDetailRow('Treated by', event.technician!),
                if (event.medicine != null) 
                  _buildEventDetailRow('Medicine', event.medicine!),
                if (event.weighedResult != null) 
                  _buildEventDetailRow('Weight', event.weighedResult!),
                if (event.otherName != null) 
                  _buildEventDetailRow('Event', event.otherName!),
                if (event.notes != null) 
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
    Color defaultColor = widget.goat.gender.toLowerCase() == 'male'
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
        await prefs.setString('goat_image_${widget.goat.tagNo}', image.path);
        
        final goatsJson = prefs.getString('goats');
        if (goatsJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(goatsJson);
            for (var item in decoded) {
              if (item['tagNo'] == widget.goat.tagNo) {
                item['photoPath'] = image.path;
                break;
              }
            }
            await prefs.setString('goats', jsonEncode(decoded));
          } catch (_) {}
        }
        
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
      await prefs.remove('goat_image_${widget.goat.tagNo}');
      
      final goatsJson = prefs.getString('goats');
      if (goatsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(goatsJson);
          for (var item in decoded) {
            if (item['tagNo'] == widget.goat.tagNo) {
              item.remove('photoPath');
              break;
            }
          }
          await prefs.setString('goats', jsonEncode(decoded));
        } catch (_) {}
      }
      
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