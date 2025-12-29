import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/goat.dart';
import 'view_goat_page.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  int _selectedTab = 0;
  bool _showSearchBar = false;
  bool _showFilterOptions = false;
  final TextEditingController _searchController = TextEditingController();
  
  DateTime? _fromDate;
  DateTime? _toDate;
  
  List<Goat> _goats = [];
  List<Event> _events = [];
  String? _filterEventType;

  @override
  void initState() {
    super.initState();
    _loadGoats();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventData = prefs.getString('events');
    if (eventData != null && eventData.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(eventData);
        setState(() {
          _events = decodedList
            .map((item) {
              try {
                return Event.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing event: $e'); // FIXED: Added error handling
                return null;
              }
            })
            .where((event) => event != null && event.tagNo.isNotEmpty)
            .cast<Event>()
            .toList();
        });
      } catch (e) {
        print('Error loading events: $e'); // FIXED: Added error logging
        // If there's an error, initialize with empty list
        setState(() {
          _events = [];
        });
      }
    } else {
      setState(() {
        _events = []; // FIXED: Initialize empty list if no data
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _events.map((e) => e.toJson()).toList();
    await prefs.setString('events', jsonEncode(jsonList));
  }

  Future<void> _updateGoatWeightForEvent(Event event) async {
    if (event.eventType.toLowerCase() != 'weighed' && event.weighedResult == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final goatsJson = prefs.getString('goats');
      
      if (goatsJson == null) return;

      final List<dynamic> decodedList = jsonDecode(goatsJson);
      List<Map<String, dynamic>> goatsData = List<Map<String, dynamic>>.from(decodedList);
      
      // Find the goat
      int goatIndex = -1;
      for (int i = 0; i < goatsData.length; i++) {
        if (goatsData[i]['tagNo'] == event.tagNo) {
          goatIndex = i;
          break;
        }
      }
      
      if (goatIndex == -1) return;

      // Get or initialize weightHistory
      List<Map<String, dynamic>> weightHistory = [];
      if (goatsData[goatIndex]['weightHistory'] != null) {
        try {
          weightHistory = List<Map<String, dynamic>>.from(goatsData[goatIndex]['weightHistory']);
        } catch (e) {
          weightHistory = [];
        }
      }

      // Format date
      final dateStr = event.date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
      
      // Parse weight
      final weightText = event.weighedResult!.trim();
      final weight = double.tryParse(weightText.replaceAll(',', '.')) ?? 0.0;
      
      // Check if this date already exists in history
      final existingIndex = weightHistory.indexWhere((entry) => entry['date'] == dateStr);
      if (existingIndex >= 0) {
        // Update existing entry
        weightHistory[existingIndex]['weight'] = weight;
      } else {
        // Add new entry
        weightHistory.add({
          'date': dateStr,
          'weight': weight,
        });
      }

      // Update goat data
      goatsData[goatIndex]['weightHistory'] = weightHistory;
      goatsData[goatIndex]['weight'] = weightText;
      
      // Save back to SharedPreferences
      final updatedJson = jsonEncode(goatsData);
      await prefs.setString('goats', updatedJson);
      
    } catch (e) {
      print('Error updating goat weight: $e'); // FIXED: Added error logging
    }
  }

  Future<void> _loadGoats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('goats');
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data) as List<dynamic>;
        setState(() {
          _goats = list.map((e) => Goat.fromJson(e as Map<String, dynamic>)).toList();
        });
      } catch (e) {
        print('Error loading goats: $e'); // FIXED: Added error logging
      }
    }
  }

  // Refresh events when coming back to the page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents(); // FIXED: Reload events when page becomes visible again
  }

  // SIMPLE PDF EXPORT - NO ERRORS
  Future<void> _exportEventsPdf() async {
    try {
      final loc = AppLocalizations.of(context)!;
      final pdf = pw.Document();
      final events = _getFilteredEvents();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(loc.eventsRecords, 
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text('${loc.generated}: ${DateTime.now().toString().split('.').first}'),
                pw.SizedBox(height: 20),
                
                if (events.isEmpty)
                  pw.Center(child: pw.Text(loc.noEventsToDisplay)),
                  
                if (events.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: [loc.date, loc.tagNo, loc.eventType, loc.medicineLabel, loc.notes],
                    data: events.map((e) {
                      final dateStr = '${e.date.day}/${e.date.month}/${e.date.year}';
                      return [
                        dateStr, 
                        e.tagNo, 
                        e.eventType, 
                        e.medicine ?? '-', 
                        e.notes ?? '-'
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'events-${DateTime.now().millisecondsSinceEpoch}.pdf');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar ? _buildSearchField() : Text(loc.events),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: _showSearchBar 
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = false;
                      _searchController.clear();
                    });
                  },
                )
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    setState(() {
                      _showFilterOptions = !_showFilterOptions;
                    });
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'export_pdf') {
                      _exportEventsPdf();
                    } else if (value == 'event_type') {
                      _showEventTypeFilterDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'export_pdf',
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(loc.exportPdf),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'event_type',
                      child: Row(
                        children: [
                          const Icon(Icons.category, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(loc.eventType),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSmallScreen ? 2 : 4),
          child: Container(
            height: isSmallScreen ? 2 : 4,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA726),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 
                            ? const Color(0xFFFFA726) 
                            : Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        loc.individual,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: _selectedTab == 0 ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 
                            ? const Color(0xFFFFA726) 
                            : Colors.white,
                      ),
                      child: Text(
                        loc.mass,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: _selectedTab == 1 ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_showFilterOptions) _buildFilterOptions(),
          
          Expanded(
            child: _getFilteredEvents().isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: isSmallScreen ? 48 : 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == 0 
                                  ? loc.noIndividualEvents
                                  : loc.noMassEvents,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: const Color(0xFFFFA726),
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: Text(
          loc.add,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Event> _getFilteredEvents() {
    final DateTime? fromMidnight = _fromDate != null ? DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day) : null;
    final DateTime? toEOD = _toDate != null ? DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59) : null;
    
    List<Event> filtered = _events.where((e) {
      if (_selectedTab == 0 && e.isMassEvent) return false;
      if (_selectedTab == 1 && !e.isMassEvent) return false;
      
      if (_filterEventType != null && e.eventType != _filterEventType) return false;
      if (fromMidnight != null && e.date.isBefore(fromMidnight)) return false;
      if (toEOD != null && e.date.isAfter(toEOD)) return false;
      return true;
    }).toList();

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((e) {
        final goat = _goats.firstWhere((g) => g.tagNo == e.tagNo, orElse: () => Goat(tagNo: e.tagNo, gender: 'Unknown'));
        final matchesEventType = e.eventType.toLowerCase().contains(searchTerm);
        final matchesTagNo = e.tagNo.toLowerCase().contains(searchTerm);
        final matchesGoatName = (goat.name ?? '').toLowerCase().contains(searchTerm);
        final matchesNotes = (e.notes ?? '').toLowerCase().contains(searchTerm);
        final matchesMedicine = (e.medicine ?? '').toLowerCase().contains(searchTerm);
        final matchesSymptoms = (e.symptoms ?? '').toLowerCase().contains(searchTerm);
        final matchesDiagnosis = (e.diagnosis ?? '').toLowerCase().contains(searchTerm);
        
        return matchesEventType || matchesTagNo || matchesGoatName || 
               matchesNotes || matchesMedicine || matchesSymptoms || matchesDiagnosis;
      }).toList();
    }

    return filtered;
  }

  Widget _buildEventsList() {
    final displayed = _getFilteredEvents();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: displayed.length,
      itemBuilder: (context, index) {
        final ev = displayed[index];
        final goat = _goats.firstWhere((g) => g.tagNo == ev.tagNo, orElse: () => Goat(tagNo: ev.tagNo, gender: 'Unknown'));
        return _buildEventCard(ev, goat, index);
      },
    );
  }

  Widget _buildEventCard(Event ev, Goat goat, int index) {
    final loc = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

    Color cardColor;
    if (goat.gender.toLowerCase() == 'male') {
      cardColor = const Color(0xFF4CAF50);
    } else if (goat.gender.toLowerCase() == 'female') {
      cardColor = const Color(0xFFFFA726);
    } else {
      cardColor = const Color(0xFF2E7D32);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: cardColor,
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 8 : 10),
            child: Row(
              children: [
                Icon(
                  ev.isMassEvent ? Icons.group : Icons.person,
                  color: Colors.white,
                  size: isSmallScreen ? 16 : 20,
                ),
                SizedBox(width: isSmallScreen ? 4 : 8),
                Expanded(
                  child: Text(
                    '${ev.eventType}${ev.isMassEvent ? ' (${loc.massEvent})' : ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white, size: isSmallScreen ? 18 : 24),
                  itemBuilder: (_) => _buildPopupMenuItems(ev),
                  onSelected: (v) => _handleEventAction(v, index, ev, goat),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(loc.dateLabel, _formatDate(ev.date), isSmallScreen),
                _detailRow(loc.tagNoLabel, '${goat.tagNo} (${goat.name ?? 'goat'})', isSmallScreen),
                if (ev.medicine != null) _detailRow(loc.medicineLabel, ev.medicine!, isSmallScreen),
                if (ev.diagnosis != null) _detailRow(loc.diagnosisLabel, ev.diagnosis!, isSmallScreen),
                if (ev.symptoms != null) _detailRow(loc.symptomsLabel, ev.symptoms!, isSmallScreen),
                if (ev.technician != null) _detailRow(loc.treatedByLabel, ev.technician!, isSmallScreen),
                if (ev.weighedResult != null) _detailRow(loc.weighedLabel, ev.weighedResult!, isSmallScreen),
                if (ev.otherName != null) _detailRow(loc.eventNameLabel, ev.otherName!, isSmallScreen),
                if (ev.notes != null) _detailRow(loc.notesLabel, ev.notes!, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(Event ev) {
    final loc = AppLocalizations.of(context)!;
    if (ev.isMassEvent) {
      return [
        PopupMenuItem<String>(value: 'edit', child: Text(loc.editEvent)),
        PopupMenuItem<String>(value: 'delete', child: Text(loc.delete)),
      ];
    } else {
      return [
        PopupMenuItem<String>(value: 'edit', child: Text(loc.editEvent)),
        PopupMenuItem<String>(value: 'view', child: Text(loc.viewGoat)),
        PopupMenuItem<String>(value: 'delete', child: Text(loc.delete)),
      ];
    }
  }

  Widget _detailRow(String title, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 70 : 90,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontSize: isSmallScreen ? 12 : 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month-1]} ${d.day}, ${d.year}';
  }

  void _handleEventAction(String action, int index, Event ev, Goat goat) async {
    final displayed = _getFilteredEvents();
    final actualIndex = _events.indexOf(displayed[index]);

    switch (action) {
      case 'delete':
        setState(() {
          _events.removeAt(actualIndex);
        });
        await _saveEvents(); // FIXED: Save after deleting
        break;
      
      case 'edit':
        final updated = await Navigator.push<Event?>(
          context,
          MaterialPageRoute(builder: (ctx) => NewEventPage(
            goat: goat,
            event: ev,
            isMassEvent: ev.isMassEvent,
          )),
        );
        if (updated != null) {
          setState(() {
            _events[actualIndex] = updated;
          });
          await _saveEvents(); // FIXED: Save after editing
          // Update goat weight if this is a weighed event
          await _updateGoatWeightForEvent(updated);
        }
        break;
      
      case 'view':
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => ViewGoatPage(goat: goat)),
        );
        break;
    }
  }

  Widget _buildSearchField() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: loc.searchEventsHint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFilterOptions() {
    final loc = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

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
                _buildDateChip(loc.today, isSmallScreen),
                _buildDateChip(loc.yesterday, isSmallScreen),
                _buildDateChip(loc.lastWeek, isSmallScreen),
                _buildDateChip(loc.currentMonth, isSmallScreen),
                _buildDateChip(loc.lastMonth, isSmallScreen),
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

  Widget _buildDateChip(String label, bool isSmallScreen) {
    bool isSelected = false;
    final now = DateTime.now();
    
    switch (label) {
      case 'Today':
        isSelected = _fromDate == now && _toDate == now;
        break;
      case 'Yesterday':
        isSelected = _fromDate == now.subtract(const Duration(days: 1)) && 
                    _toDate == now.subtract(const Duration(days: 1));
        break;
      case 'Last Week':
        isSelected = _fromDate == now.subtract(const Duration(days: 7)) && _toDate == now;
        break;
      case 'Current Month':
        isSelected = _fromDate == DateTime(now.year, now.month, 1) && 
                    _toDate == DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        isSelected = _fromDate == DateTime(now.year, now.month - 1, 1) && 
                    _toDate == DateTime(now.year, now.month, 0);
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
              _fromDate = now;
              _toDate = now;
              break;
            case 'Yesterday':
              _fromDate = now.subtract(const Duration(days: 1));
              _toDate = now.subtract(const Duration(days: 1));
              break;
            case 'Last Week':
              _fromDate = now.subtract(const Duration(days: 7));
              _toDate = now;
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
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFFFA726),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
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

  void _showEventTypeFilterDialog() {
    final loc = AppLocalizations.of(context)!;
    final eventTypes = [
      loc.treated,
      loc.weighed,
      loc.weaned,
      loc.castrated,
      loc.vaccinated,
      loc.deworming,
      loc.hoofTrimming,
      loc.other,
    ];
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.filterByEventType),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: eventTypes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: Text(loc.all),
                    onTap: () {
                      setState(() => _filterEventType = null);
                      Navigator.of(ctx).pop();
                    },
                  );
                }
                final type = eventTypes[index - 1];
                return ListTile(
                  title: Text(type),
                  onTap: () {
                    setState(() => _filterEventType = type);
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context) {
    if (_selectedTab == 1) {
      _createMassEvent();
    } else {
      _showIndividualEventDialog(context);
    }
  }

  void _createMassEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => NewEventPage(
        isMassEvent: true,
      )),
    ).then((result) async { // FIXED: Added async
      if (result != null && result is Event) {
        setState(() {
          _events.insert(0, result);
        });
        await _saveEvents(); // FIXED: Save after adding mass event
      }
    });
  }

  void _showIndividualEventDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    loc.selectGoatToContinue,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StatefulBuilder(builder: (ctx, setStateDialog) {
                    String query = '';
                    List<Goat> filtered = _goats;
                    if (query.isNotEmpty) {
                      filtered = _goats.where((g) => ('${g.tagNo} ${g.name ?? ''}').toLowerCase().contains(query.toLowerCase())).toList();
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            onChanged: (val) => setStateDialog(() => query = val),
                            decoration: InputDecoration(
                              hintText: loc.searchGoatHint,
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                        
                        SizedBox(
                          height: 250,
                          child: filtered.isEmpty
                              ? Center(child: Text(loc.noGoatsFound, style: TextStyle(color: Colors.grey.shade600)))
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final goat = filtered[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                      ),
                                      child: ListTile(
                                        title: Text('${goat.tagNo} (${goat.name ?? 'goat'})'),
                                        subtitle: Text('${goat.gender}, ${goat.goatStage ?? ''}'),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (ctx) => NewEventPage(goat: goat)),
                                          ).then((newEvent) async { // FIXED: Added async
                                            if (newEvent != null && newEvent is Event) {
                                              setState(() {
                                                _events.insert(0, newEvent);
                                              });
                                              await _saveEvents(); // FIXED: Save after adding individual event
                                              // Update goat weight if this is a weighed event
                                              _updateGoatWeightForEvent(newEvent);
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// NewEventPage Class
class NewEventPage extends StatefulWidget {
  final Goat? goat;
  final Event? event;
  final bool isMassEvent;
  final List<String>? selectedTagNos;

  const NewEventPage({
    super.key, 
    this.goat, 
    this.event,
    this.isMassEvent = false,
    this.selectedTagNos,
  });

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  DateTime? _eventDate;
  String? _eventType;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _weighedController = TextEditingController();
  final TextEditingController _otherEventController = TextEditingController();
  final TextEditingController _technicianController = TextEditingController();
  final TextEditingController _medicineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _eventDate = DateTime.now();
    
    final ev = widget.event;
    if (ev != null) {
      _eventDate = ev.date;
      _eventType = ev.eventType;
      _symptomsController.text = ev.symptoms ?? '';
      _diagnosisController.text = ev.diagnosis ?? '';
      _weighedController.text = ev.weighedResult ?? '';
      _technicianController.text = ev.technician ?? '';
      _medicineController.text = ev.medicine ?? '';
      _otherEventController.text = ev.otherName ?? '';
      _notesController.text = ev.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _weighedController.dispose();
    _otherEventController.dispose();
    _technicianController.dispose();
    _medicineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final headerLabel = widget.isMassEvent 
        ? loc.newMassEvent
        : widget.goat != null 
            ? '${widget.goat!.tagNo} (${widget.goat!.name ?? ''}) - ${widget.goat!.goatStage ?? ''}'
            : loc.selectGoatToContinue;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMassEvent ? loc.newMassEvent : loc.newEvent),
        backgroundColor: widget.isMassEvent ? const Color(0xFF1976D2) : const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEvent,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: widget.isMassEvent ? const Color(0xFF1976D2) : const Color(0xFF4CAF50),
              child: Text(
                headerLabel,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _eventDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _eventDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _eventDate != null 
                            ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}' 
                            : loc.eventDateRequired,
                        style: TextStyle(
                          color: _eventDate != null ? Colors.black87 : Colors.grey.shade600
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () async {
                final List<String> types = [
                  loc.treated,
                  loc.weighed,
                  loc.weaned,
                  loc.castrated,
                  loc.vaccinated,
                  loc.deworming,
                  loc.hoofTrimming,
                  loc.other,
                ];
                final selected = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: Text(loc.selectEventTypeRequired),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 320,
                        child: ListView.separated(
                          itemCount: types.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final t = types[index];
                            return ListTile(
                              title: Text(t),
                              onTap: () => Navigator.of(ctx).pop(t),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
                if (selected != null) setState(() => _eventType = selected);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade700),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _eventType ?? loc.selectEventTypeRequired,
                        style: TextStyle(
                          color: _eventType != null ? Colors.black87 : Colors.orange.shade700
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_eventType == loc.treated) ..._buildTreatedFields(),
            if (_eventType == loc.weighed) ..._buildWeighedFields(),
            if (_eventType == loc.vaccinated || _eventType == loc.deworming) ..._buildMedicineFields(),
            if (_eventType == loc.other) ..._buildOtherFields(),

            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: loc.writeNotes, 
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTreatedFields() {
    final loc = AppLocalizations.of(context)!;
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _symptomsController,
        decoration: InputDecoration(
          hintText: loc.symptomsRequired, 
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _diagnosisController,
        decoration: InputDecoration(
          hintText: loc.diagnosisRequired, 
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _technicianController,
        decoration: InputDecoration(
          hintText: loc.technicianRequired, 
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _medicineController,
        decoration: InputDecoration(
          hintText: loc.medicineGivenRequired, 
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ];
  }

  List<Widget> _buildWeighedFields() {
    final loc = AppLocalizations.of(context)!;
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _weighedController,
        decoration: InputDecoration(
          hintText: loc.weighedResultRequired, 
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ];
  }

  List<Widget> _buildMedicineFields() {
    final loc = AppLocalizations.of(context)!;
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _medicineController,
        decoration: InputDecoration(
          hintText: loc.medicineGivenRequired, 
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ];
  }

  List<Widget> _buildOtherFields() {
    final loc = AppLocalizations.of(context)!;
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _otherEventController,
        decoration: InputDecoration(
          hintText: loc.eventNameRequired, 
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ];
  }

  void _saveEvent() {
    final loc = AppLocalizations.of(context)!;
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.pleaseSelectEventDate)));
      return;
    }
    if (_eventType == null || _eventType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.pleaseSelectEventType)));
      return;
    }
    if (_eventType == loc.other && (_otherEventController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.pleaseEnterEventName)));
      return;
    }

    final event = Event(
      date: _eventDate!,
      tagNo: widget.isMassEvent ? 'MASS' : (widget.goat?.tagNo ?? '01'),
      eventType: _eventType!,
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
      technician: _technicianController.text.trim().isEmpty ? null : _technicianController.text.trim(),
      medicine: _medicineController.text.trim().isEmpty ? null : _medicineController.text.trim(),
      weighedResult: _weighedController.text.trim().isEmpty ? null : _weighedController.text.trim(),
      otherName: _eventType == loc.other ? _otherEventController.text.trim() : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isMassEvent: widget.isMassEvent,
    );

    Navigator.of(context).pop(event);
  }
}