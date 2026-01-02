import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/goat.dart';
import '../services/archive_service.dart';
import '../models/event.dart';
import 'add_event_page.dart';

class EventsReportPage extends StatefulWidget {
  const EventsReportPage({super.key});

  @override
  State<EventsReportPage> createState() => _EventsReportPageState();
}

class _EventsReportPageState extends State<EventsReportPage> {
  List<Event> _events = [];
  List<Goat> _goats = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilterOptions = false;
  int _soldGoatsCount = 0;
  int _deadGoatsCount = 0;
  int _lostGoatsCount = 0;
  int _otherArchivedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadEvents();
    await _loadGoats();
    await _loadArchiveCounts();
    if (mounted) setState(() {});
  }

  Future<void> _loadArchiveCounts() async {
    final sold = await ArchiveService.getArchiveCount('sold');
    final dead = await ArchiveService.getArchiveCount('dead');
    final lost = await ArchiveService.getArchiveCount('lost');
    final other = await ArchiveService.getArchiveCount('other');
    
    setState(() {
      _soldGoatsCount = sold;
      _deadGoatsCount = dead;
      _lostGoatsCount = lost;
      _otherArchivedCount = other;
    });
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('events');
    
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data) as List<dynamic>;
        _events = list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error loading events: $e');
      }
    }
  }

  Future<void> _loadGoats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('goats');
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data) as List<dynamic>;
        _goats = list.map((e) => Goat.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error loading goats: $e');
      }
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  // Filtered events by date range
  List<Event> get _filteredEvents {
    if (_fromDate == null || _toDate == null) return _events;
    final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
    return _events.where((event) {
      final eventDate = event.date;
      return (eventDate.isAtSameMomentAs(from) || eventDate.isAfter(from)) &&
             (eventDate.isAtSameMomentAs(to) || eventDate.isBefore(to));
    }).toList();
  }

  // Format date for PDF
  String _formatPdfDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Format date for UI
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _generatePdf() async {
    try {
      final pdf = pw.Document();
      final ByteData imageData = await rootBundle.load('assets/images/events.png');
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      final filteredEvents = _filteredEvents;
      final individualEvents = filteredEvents.where((e) => !e.isMassEvent).toList();
      final massEvents = filteredEvents.where((e) => e.isMassEvent).toList();
      final archives = await ArchiveService.getAllArchives();

      // First page - Header, Individual Events, and Mass Events
      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.all(32),
            theme: pw.ThemeData.withFont(
              base: await PdfGoogleFonts.openSansRegular(),
              bold: await PdfGoogleFonts.openSansBold(),
            ),
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Image(pw.MemoryImage(imageBytes), width: 120, height: 120),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Events Report',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Date Range: ${_fromDate != null && _toDate != null ? '${_formatPdfDate(_fromDate!)} - ${_formatPdfDate(_toDate!)}' : 'All Dates'}',
                    style: pw.TextStyle(
                      fontSize: 13,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.Divider(thickness: 1.2, color: PdfColors.indigo),
                pw.SizedBox(height: 12),

                // Individual Events Section
                pw.Text(
                  'Individual Events',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (individualEvents.isEmpty)
                  pw.Text(
                    'No individual events found.',
                    style: pw.TextStyle(color: PdfColors.grey600),
                  )
                else
                  pw.Table.fromTextArray(
                    headers: ['Event', 'Date', 'Goat', 'Notes'],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.blue600),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellStyle: pw.TextStyle(fontSize: 10),
                    data: individualEvents
                        .map((e) => [e.eventType, _formatPdfDate(e.date), e.tagNo, e.notes ?? ''])
                        .toList(),
                  ),

                pw.SizedBox(height: 20),

                // Mass Events Section
                pw.Text(
                  'Mass Events',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (massEvents.isEmpty)
                  pw.Text(
                    'No mass events found.',
                    style: pw.TextStyle(color: PdfColors.grey600),
                  )
                else
                  pw.Table.fromTextArray(
                    headers: ['Event', 'Date', 'Goat', 'Notes'],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.green600),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellStyle: pw.TextStyle(fontSize: 10),
                    data: massEvents
                        .map((e) => [e.eventType, _formatPdfDate(e.date), e.tagNo, e.notes ?? ''])
                        .toList(),
                  ),
              ],
            );
          },
        ),
      );

      // Second page - Archives
      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.all(32),
            theme: pw.ThemeData.withFont(
              base: await PdfGoogleFonts.openSansRegular(),
              bold: await PdfGoogleFonts.openSansBold(),
            ),
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Archives Header
                pw.Text(
                  'Archives',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Date Range: ${_fromDate != null && _toDate != null ? '${_formatPdfDate(_fromDate!)} - ${_formatPdfDate(_toDate!)}' : 'All Dates'}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 12),

                if (archives.isEmpty)
                  pw.Text(
                    'No archives found.',
                    style: pw.TextStyle(color: PdfColors.grey600),
                  )
                else
                  pw.Table.fromTextArray(
                    headers: ['Tag No', 'Name', 'Breed', 'Reason', 'Date', 'Notes'],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.red600),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellStyle: pw.TextStyle(fontSize: 9),
                    data: archives
                        .map((a) => [
                              a.tagNo,
                              a.goatData['name'] ?? '',
                              a.goatData['breed'] ?? '',
                              a.reason,
                              _formatPdfDate(a.archiveDate),
                              a.notes ?? ''
                            ])
                        .toList(),
                  ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'events_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        subject: 'Events Report',
        body: 'Please find attached the generated events report PDF.',
      );
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper to get possible English event types for a localized string
  List<String> _getPossibleEnglishEventTypes(String localizedEventType, AppLocalizations loc) {
    final Map<String, List<String>> localizedToEnglish = {
      loc.treated: ['Treated', 'TREATED'],
      loc.weighed: ['Weighed', 'WEIGHED'],
      loc.weaned: ['Weaned', 'WEANED'],
      loc.givesBirth: ['Gives Birth'],
      loc.dryOff: ['Dry off'],
      loc.breeding: ['Breeding'],
      loc.pregnant: ['Pregnant'],
      loc.aborted: ['Aborted'],
      loc.castrated: ['Castrated', 'CASTRATED'],
      loc.vaccinated: ['Vaccinated', 'VACCINATED'],
      loc.deworming: ['Deworming', 'DEWORMING'],
      loc.hoofTrimming: ['Hoof Trimming', 'HOOF TRIMMING'],
      loc.tagging: ['Tagging', 'TAGGING'],
      loc.other: ['Other', 'OTHER'],
    };
    
    return localizedToEnglish[localizedEventType] ?? [localizedEventType];
  }

  // Get count for individual event type
  int _getIndividualEventCount(String localizedEventType, AppLocalizations loc) {
    final filteredEvents = _filteredEvents;
    
    final possibleEnglishTypes = _getPossibleEnglishEventTypes(localizedEventType, loc);
    
    return filteredEvents.where((event) => 
      !event.isMassEvent && possibleEnglishTypes.contains(event.eventType)
    ).length;
  }

  // Get count for mass event type
  int _getMassEventCount(String localizedEventType, AppLocalizations loc) {
    final filteredEvents = _filteredEvents;
    
    final possibleEnglishTypes = _getPossibleEnglishEventTypes(localizedEventType, loc);
    
    return filteredEvents.where((event) => 
      event.isMassEvent && possibleEnglishTypes.contains(event.eventType)
    ).length;
  }

  // Show archive details
  void _showArchiveDetails(BuildContext context, String title, String reason) async {
    final loc = AppLocalizations.of(context)!;
    final archives = await ArchiveService.getArchivedGoats(reason);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: archives.isEmpty
                  ? Center(
                      child: Text(
                        loc.noArchivedGoatsFound,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: archives.length,
                      itemBuilder: (context, index) {
                        final archive = archives[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(archive.displayName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${archive.breed ?? loc.unknownBreed} • ${archive.gender}'),
                                Text('Archived: ${_formatDate(archive.archiveDate)}'),
                                if (archive.notes != null && archive.notes!.isNotEmpty)
                                  Text('${loc.notes}: ${archive.notes}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              onPressed: () async {
                                final restoredGoat = await ArchiveService.restoreGoat(archive.tagNo);
                                if (restoredGoat != null) {
                                  setState(() {
                                    _goats.add(restoredGoat);
                                  });
                                  final prefs = await SharedPreferences.getInstance();
                                  final updatedJson = _goats.map((g) => g.toJson()).toList();
                                  await prefs.setString('goats', jsonEncode(updatedJson));
                                  
                                  await _loadArchiveCounts();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${archive.tagNo} ${loc.restoredSuccessfully}'),
                                        backgroundColor: const Color(0xFF4CAF50),
                                      ),
                                    );
                                    Navigator.of(ctx).pop();
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.close),
              ),
            ],
          );
        },
      );
    }
  }

  // Date filter chips and custom range UI
  Widget _buildFilterOptions(BuildContext context, AppLocalizations loc) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.filterByDate,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: [
                _buildDateChip(loc.today, isSmallScreen, loc),
                _buildDateChip(loc.yesterday, isSmallScreen, loc),
                _buildDateChip(loc.lastWeek, isSmallScreen, loc),
                _buildDateChip(loc.currentMonth, isSmallScreen, loc),
                _buildDateChip(loc.lastMonth, isSmallScreen, loc),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              loc.customDateRange,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.from, style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectFromDate(context),
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Expanded(
                              child: Text(
                                _fromDate != null
                                    ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                                    : loc.selectDate,
                                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.to, style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectToDate(context),
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Expanded(
                              child: Text(
                                _toDate != null
                                    ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                                    : loc.selectDate,
                                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showFilterOptions = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                    ),
                    child: Text(
                      loc.apply,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _showFilterOptions = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                    ),
                    child: Text(
                      loc.clear,
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, bool isSmallScreen, AppLocalizations loc) {
    bool isSelected = false;
    final now = DateTime.now();
    switch (label) {
      case 'Today':
      case 'आज':
        isSelected = _fromDate != null && _toDate != null &&
            _fromDate!.year == now.year && _fromDate!.month == now.month && _fromDate!.day == now.day &&
            _toDate!.year == now.year && _toDate!.month == now.month && _toDate!.day == now.day;
        break;
      case 'Yesterday':
      case 'कल':
        final yest = now.subtract(const Duration(days: 1));
        isSelected = _fromDate != null && _toDate != null &&
            _fromDate!.year == yest.year && _fromDate!.month == yest.month && _fromDate!.day == yest.day &&
            _toDate!.year == yest.year && _toDate!.month == yest.month && _toDate!.day == yest.day;
        break;
      case 'Last Week':
      case 'पिछला सप्ताह':
        final lastWeek = now.subtract(const Duration(days: 7));
        isSelected = _fromDate != null && _toDate != null &&
            _fromDate!.year == lastWeek.year && _fromDate!.month == lastWeek.month && _fromDate!.day == lastWeek.day &&
            _toDate!.year == now.year && _toDate!.month == now.month && _toDate!.day == now.day;
        break;
      case 'Current Month':
      case 'वर्तमान माह':
        final first = DateTime(now.year, now.month, 1);
        final last = DateTime(now.year, now.month + 1, 0);
        isSelected = _fromDate != null && _toDate != null &&
            _fromDate!.year == first.year && _fromDate!.month == first.month && _fromDate!.day == first.day &&
            _toDate!.year == last.year && _toDate!.month == last.month && _toDate!.day == last.day;
        break;
      case 'Last Month':
      case 'पिछला माह':
        final first = DateTime(now.year, now.month - 1, 1);
        final last = DateTime(now.year, now.month, 0);
        isSelected = _fromDate != null && _toDate != null &&
            _fromDate!.year == first.year && _fromDate!.month == first.month && _fromDate!.day == first.day &&
            _toDate!.year == last.year && _toDate!.month == last.month && _toDate!.day == last.day;
        break;
    }
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final now = DateTime.now();
          switch (label) {
            case 'Today':
            case 'आज':
              _fromDate = now;
              _toDate = now;
              break;
            case 'Yesterday':
            case 'कल':
              final yest = now.subtract(const Duration(days: 1));
              _fromDate = yest;
              _toDate = yest;
              break;
            case 'Last Week':
            case 'पिछला सप्ताह':
              final lastWeek = now.subtract(const Duration(days: 7));
              _fromDate = lastWeek;
              _toDate = now;
              break;
            case 'Current Month':
            case 'वर्तमान माह':
              _fromDate = DateTime(now.year, now.month, 1);
              _toDate = DateTime(now.year, now.month + 1, 0);
              break;
            case 'Last Month':
            case 'पिछला माह':
              _fromDate = DateTime(now.year, now.month - 1, 1);
              _toDate = DateTime(now.year, now.month, 0);
              break;
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final individualEventTypes = [
      loc.treated,
      loc.weighed,
      loc.weaned,
      loc.givesBirth,
      loc.dryOff,
      loc.breeding,
      loc.pregnant,
      loc.aborted,
      loc.castrated,
      loc.vaccinated,
      loc.deworming,
    ];
    
    final massEventTypes = [
      loc.treated,
      loc.weighed,
      loc.weaned,
      loc.castrated,
      loc.vaccinated,
      loc.deworming,
      loc.hoofTrimming,
      loc.tagging,
      loc.other,
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.eventsReport),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilterOptions = !_showFilterOptions;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () => _showAllArchives(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_showFilterOptions) _buildFilterOptions(context, loc),
            
            // Header Section
            Card(
              elevation: 3,
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.eventsReport,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          loc.filterByDate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fromDate != null && _toDate != null
                          ? '(${_formatDate(_fromDate!)} - ${_formatDate(_toDate!)})'
                          : loc.selectDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Events: ${_filteredEvents.length}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      'Showing: ${_fromDate != null && _toDate != null ? 'Date Range' : 'All Events'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Individual Events Section
            _buildSectionHeader(loc.individualEvents, context),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: individualEventTypes.map((eventType) {
                    final count = _getIndividualEventCount(eventType, loc);
                    return InkWell(
                      onTap: () => _showEventDetails(context, eventType, false),
                      child: _buildEventRow(
                        eventType: eventType,
                        count: count,
                        icon: _getEventIcon(eventType, loc),
                        color: _getEventColor(eventType, loc),
                        context: context,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Mass Events Section
            _buildSectionHeader(loc.massEvents, context),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: massEventTypes.map((eventType) {
                    final count = _getMassEventCount(eventType, loc);
                    return InkWell(
                      onTap: () => _showEventDetails(context, eventType, true),
                      child: _buildMassEventCard(
                        eventType: eventType,
                        count: count,
                        loc: loc,
                        context: context,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Archives Section
            _buildSectionHeader(loc.archives, context),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Sold goats - clickable
                    InkWell(
                      onTap: () => _showArchiveDetails(context, loc.soldGoats, 'sold'),
                      child: _buildArchiveItem(
                        title: loc.soldGoats,
                        count: _soldGoatsCount,
                        icon: Icons.sell,
                        color: Colors.orange,
                        context: context,
                      ),
                    ),
                    const Divider(),
                    // Dead goats - clickable
                    InkWell(
                      onTap: () => _showArchiveDetails(context, loc.deadGoats, 'dead'),
                      child: _buildArchiveItem(
                        title: loc.deadGoats,
                        count: _deadGoatsCount,
                        icon: Icons.cancel,
                        color: Colors.red,
                        context: context,
                      ),
                    ),
                    const Divider(),
                    // Lost goats - clickable
                    InkWell(
                      onTap: () => _showArchiveDetails(context, loc.lostGoats, 'lost'),
                      child: _buildArchiveItem(
                        title: loc.lostGoats,
                        count: _lostGoatsCount,
                        icon: Icons.location_off,
                        color: Colors.blue,
                        context: context,
                      ),
                    ),
                    const Divider(),
                    // Other archived - clickable
                    InkWell(
                      onTap: () => _showArchiveDetails(context, loc.otherArchived, 'other'),
                      child: _buildArchiveItem(
                        title: loc.othersArchived,
                        count: _otherArchivedCount,
                        icon: Icons.archive,
                        color: Colors.purple,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildEventRow({
    required String eventType,
    required int count,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              eventType,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMassEventCard({
    required String eventType,
    required int count,
    required AppLocalizations loc,
    required BuildContext context,
  }) {
    final color = _getMassEventColor(eventType, loc);
    return SizedBox(
      width: 150,
      child: Card(
        elevation: 1,
        color: color.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                eventType,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to get icons and colors for events
  IconData _getEventIcon(String eventType, AppLocalizations loc) {
    if (eventType == loc.treated) return Icons.healing;
    if (eventType == loc.weighed) return Icons.scale;
    if (eventType == loc.weaned) return Icons.child_care;
    if (eventType == loc.givesBirth) return Icons.family_restroom;
    if (eventType == loc.dryOff) return Icons.water_drop;
    if (eventType == loc.breeding) return Icons.favorite;
    if (eventType == loc.pregnant) return Icons.pregnant_woman;
    if (eventType == loc.aborted) return Icons.cancel;
    if (eventType == loc.castrated) return Icons.cut;
    if (eventType == loc.vaccinated) return Icons.medical_services;
    if (eventType == loc.deworming) return Icons.bug_report;
    return Icons.event;
  }

  Color _getEventColor(String eventType, AppLocalizations loc) {
    if (eventType == loc.treated) return Colors.red;
    if (eventType == loc.weighed) return Colors.teal;
    if (eventType == loc.weaned) return Colors.orange;
    if (eventType == loc.givesBirth) return Colors.pink;
    if (eventType == loc.dryOff) return Colors.blue;
    if (eventType == loc.breeding) return Colors.purple;
    if (eventType == loc.pregnant) return Colors.pinkAccent;
    if (eventType == loc.aborted) return Colors.redAccent;
    if (eventType == loc.castrated) return Colors.brown;
    if (eventType == loc.vaccinated) return Colors.green;
    if (eventType == loc.deworming) return Colors.deepOrange;
    return Colors.grey;
  }

  Color _getMassEventColor(String eventType, AppLocalizations loc) {
    if (eventType == loc.treated) return Colors.green;
    if (eventType == loc.weighed) return Colors.blue;
    if (eventType == loc.weaned) return Colors.deepOrange;
    if (eventType == loc.castrated) return Colors.red;
    if (eventType == loc.vaccinated) return Colors.pinkAccent;
    if (eventType == loc.deworming) return Colors.brown;
    if (eventType == loc.hoofTrimming) return Colors.purple;
    if (eventType == loc.other) return Colors.grey;
    return Colors.grey;
  }

  // Function to show all archives
  void _showAllArchives(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final archives = await ArchiveService.getAllArchives();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(loc.allArchivedGoats),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: archives.isEmpty
                  ? Center(
                      child: Text(
                        loc.noArchivedGoatsFound,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: archives.length,
                      itemBuilder: (context, index) {
                        final archive = archives[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              _getArchiveIcon(archive.reason),
                              color: _getArchiveColor(archive.reason),
                            ),
                            title: Text(archive.displayName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reason: ${_getArchiveReasonText(archive.reason, loc)}'),
                                Text('Date: ${_formatDate(archive.archiveDate)}'),
                                if (archive.notes != null && archive.notes!.isNotEmpty)
                                  Text('Notes: ${archive.notes}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              onPressed: () async {
                                final restoredGoat = await ArchiveService.restoreGoat(archive.tagNo);
                                if (restoredGoat != null) {
                                  setState(() {
                                    _goats.add(restoredGoat);
                                  });
                                  final prefs = await SharedPreferences.getInstance();
                                  final updatedJson = _goats.map((g) => g.toJson()).toList();
                                  await prefs.setString('goats', jsonEncode(updatedJson));
                                  
                                  await _loadArchiveCounts();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${archive.tagNo} ${loc.restoredSuccessfully}'),
                                        backgroundColor: const Color(0xFF4CAF50),
                                      ),
                                    );
                                    Navigator.of(ctx).pop();
                                    _showAllArchives(context);
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.close),
              ),
            ],
          );
        },
      );
    }
  }

  IconData _getArchiveIcon(String reason) {
    if (reason == 'sold') return Icons.sell;
    if (reason == 'dead') return Icons.cancel;
    if (reason == 'lost') return Icons.location_off;
    return Icons.archive;
  }

  Color _getArchiveColor(String reason) {
    if (reason == 'sold') return Colors.orange;
    if (reason == 'dead') return Colors.red;
    if (reason == 'lost') return Colors.blue;
    return Colors.purple;
  }

  String _getArchiveReasonText(String reason, AppLocalizations loc) {
    if (reason == 'sold') return loc.sold;
    if (reason == 'dead') return loc.dead;
    if (reason == 'lost') return loc.lost;
    return loc.other;
  }

  void _showEventDetails(BuildContext context, String eventType, bool isMassEvent) {
    final loc = AppLocalizations.of(context)!;

    final possibleEnglishTypes = _getPossibleEnglishEventTypes(eventType, loc);

    final filteredEvents = _filteredEvents.where((event) =>
      possibleEnglishTypes.contains(event.eventType) && event.isMassEvent == isMassEvent
    ).toList();

    filteredEvents.sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$eventType ${loc.events}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: filteredEvents.isEmpty
            ? Center(
                child: Text(
                  loc.noResultsFound,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            : ListView.builder(
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  final goat = _goats.firstWhere(
                    (g) => g.tagNo == event.tagNo,
                    orElse: () => Goat(tagNo: event.tagNo, name: 'Unknown', gender: 'Unknown'),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getEventColor(eventType, loc).withAlpha(50),
                        child: Icon(
                          _getEventIcon(eventType, loc),
                          color: _getEventColor(eventType, loc),
                          size: 20,
                        ),
                      ),
                      title: Text('${goat.name ?? 'Unknown'} (${event.tagNo})'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${loc.date}: ${_formatDate(event.date)}'),
                          if (event.notes != null && event.notes!.isNotEmpty)
                            Text('${loc.notes}: ${event.notes}'),
                          if (event.weighedResult != null && event.weighedResult!.isNotEmpty)
                            Text('Weight: ${event.weighedResult} kg'),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEventPage(
                              goat: goat,
                              existingEvent: event,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }
}