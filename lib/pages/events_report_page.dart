import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
import '../services/archive_service.dart';

class EventsReportPage extends StatefulWidget {
  const EventsReportPage({super.key});

  @override
  State<EventsReportPage> createState() => _EventsReportPageState();
}

class _EventsReportPageState extends State<EventsReportPage> {
  List<Event> _events = [];
  List<Goat> _goats = [];
  DateTime _selectedMonth = DateTime.now();
  
  // Archive counts
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
    print('=== LOADING EVENTS REPORT DATA ===');
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
    
    print('=== LOADING EVENTS FROM SHAREDPREFS ===');
    print('Data exists: ${data != null}');
    
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data) as List<dynamic>;
        _events = list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
        
        // DEBUG: Print all event types
        print('Total events loaded: ${_events.length}');
        print('Event types found:');
        final typeCounts = <String, int>{};
        for (var event in _events) {
          final type = event.eventType;
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
        typeCounts.forEach((type, count) {
          print('  "$type": $count events');
        });
        
        // Print current month events
        final monthEvents = _monthEvents;
        print('Current month events (${_formatDate(_firstDayOfMonth)} - ${_formatDate(_lastDayOfMonth)}): ${monthEvents.length}');
        for (var event in monthEvents) {
          print('  - ${event.tagNo}: ${event.eventType} on ${event.date}');
        }
        
      } catch (e) {
        print('Error loading events: $e');
      }
    } else {
      print('No events data found in SharedPreferences');
    }
    print('===================================');
  }

  Future<void> _loadGoats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('goats');
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data) as List<dynamic>;
        _goats = list.map((e) => Goat.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        print('Error loading goats: $e');
      }
    }
  }

  // Get first and last day of current month
  DateTime get _firstDayOfMonth => DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _lastDayOfMonth => DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

  // Format date
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Get events for current month - FIXED VERSION
  List<Event> get _monthEvents => _events.where((event) {
    final eventDate = event.date;
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    
    return (eventDate.isAtSameMomentAs(startOfMonth) || eventDate.isAfter(startOfMonth)) &&
           (eventDate.isAtSameMomentAs(endOfMonth) || eventDate.isBefore(endOfMonth));
  }).toList();

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

  // Get count for individual event type - UPDATED VERSION
  int _getIndividualEventCount(String localizedEventType, AppLocalizations loc) {
    final monthEvents = _monthEvents;
    
    // Get all English event types that map to this localized string
    final possibleEnglishTypes = _getPossibleEnglishEventTypes(localizedEventType, loc);
    
    final filtered = monthEvents.where((event) => 
      !event.isMassEvent && possibleEnglishTypes.contains(event.eventType)
    ).toList();
    
    print('DEBUG: Checking "$localizedEventType" (English variants: $possibleEnglishTypes) - Found ${filtered.length} events');
    if (filtered.isNotEmpty) {
      for (var event in filtered) {
        print('  - ${event.tagNo}: ${event.eventType} on ${event.date}');
      }
    }
    
    return filtered.length;
  }

  // Get count for mass event type - UPDATED VERSION
  int _getMassEventCount(String localizedEventType, AppLocalizations loc) {
    final monthEvents = _monthEvents;
    
    // Get all English event types that map to this localized string
    final possibleEnglishTypes = _getPossibleEnglishEventTypes(localizedEventType, loc);
    
    return monthEvents.where((event) => 
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
                                  // Add back to active goats
                                  setState(() {
                                    _goats.add(restoredGoat);
                                  });
                                  // Save goats
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Initialize localized event types HERE in build method
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
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectMonth(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('=== MANUAL REFRESH TRIGGERED ===');
              _loadData();
            },
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
                          loc.currentMonth,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${_formatDate(_firstDayOfMonth)} - ${_formatDate(_lastDayOfMonth)})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Events: ${_monthEvents.length}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    // Debug info
                    Text(
                      'Total All Events: ${_events.length}',
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
                    return _buildEventRow(
                      eventType: eventType,
                      count: count,
                      icon: _getEventIcon(eventType, loc),
                      color: _getEventColor(eventType, loc),
                      context: context,
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
                    return _buildMassEventCard(
                      eventType: eventType,
                      count: count,
                      loc: loc,
                      context: context,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('=== DEBUG INFO ===');
          print('Total events in memory: ${_events.length}');
          print('Current month: ${_selectedMonth.month}/${_selectedMonth.year}');
          print('Month events: ${_monthEvents.length}');
          print('Weighed events count: ${_getIndividualEventCount(loc.weighed, loc)}');
          print('All event types:');
          for (var type in individualEventTypes) {
            print('  $type: ${_getIndividualEventCount(type, loc)}');
          }
          print('==================');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.bug_report),
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

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
      });
      print('Month changed to: ${_formatDate(picked)}');
    }
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
                                  // Add back to active goats
                                  setState(() {
                                    _goats.add(restoredGoat);
                                  });
                                  // Save goats
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
}

// Event class (same as in your EventsPage)
class Event {
  final DateTime date;
  final String tagNo;
  final String eventType;
  final String? symptoms;
  final String? diagnosis;
  final String? technician;
  final String? medicine;
  final String? weighedResult;
  final String? otherName;
  final String? notes;
  final bool isMassEvent;

  Event({
    required this.date,
    required this.tagNo,
    required this.eventType,
    this.symptoms,
    this.diagnosis,
    this.technician,
    this.medicine,
    this.weighedResult,
    this.otherName,
    this.notes,
    this.isMassEvent = false,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'tagNo': tagNo,
    'eventType': eventType,
    'symptoms': symptoms,
    'diagnosis': diagnosis,
    'technician': technician,
    'medicine': medicine,
    'weighedResult': weighedResult,
    'otherName': otherName,
    'notes': notes,
    'isMassEvent': isMassEvent,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    date: DateTime.parse(json['date'] as String),
    tagNo: json['tagNo'] as String,
    eventType: json['eventType'] as String,
    symptoms: json['symptoms'] as String?,
    diagnosis: json['diagnosis'] as String?,
    technician: json['technician'] as String?,
    medicine: json['medicine'] as String?,
    weighedResult: json['weighedResult'] as String?,
    otherName: json['otherName'] as String?,
    notes: json['notes'] as String?,
    isMassEvent: json['isMassEvent'] as bool? ?? false,
  );
}