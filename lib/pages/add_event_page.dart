import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/goat.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class AddEventPage extends StatefulWidget {
  final Goat goat;
  final Event? existingEvent; // Optional existing event for editing

  const AddEventPage({super.key, required this.goat, this.existingEvent});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  DateTime? _eventDate;
  String? _eventType;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _weighedController = TextEditingController();
  final TextEditingController _otherEventController = TextEditingController();
  final TextEditingController _technicianController = TextEditingController();
  final TextEditingController _medicineController = TextEditingController();

  final List<String> _eventTypes = [
    'Treated',
    'Weighed',
    'Weaned',
    'Castrated',
    'Vaccinated',
    'Deworming',
    'Hoof Trimming',
    'Bred',
    'Pregnancy Confirmed',
    'Started Lactating',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.existingEvent != null) {
      // Populate fields from existing event
      final event = widget.existingEvent!;
      _eventDate = event.date;
      _eventType = event.eventType;
      _notesController.text = event.notes ?? '';
      _symptomsController.text = event.symptoms ?? '';
      _diagnosisController.text = event.diagnosis ?? '';
      _weighedController.text = event.weighedResult ?? '';
      _otherEventController.text = event.otherName ?? '';
      _technicianController.text = event.technician ?? '';
      _medicineController.text = event.medicine ?? '';
    } else {
      _eventDate = DateTime.now();
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

  // ✅ FIXED FUNCTION: Properly saves weight to goat's weightHistory
  Future<void> _addWeightToGoatHistory() async {
    if (_eventType != 'Weighed' || _weighedController.text.trim().isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? goatsJson = prefs.getString('goats');
      
      if (goatsJson == null) {
        debugPrint('❌ No goats data found in SharedPreferences');
        return;
      }

      debugPrint('📥 Loading goats data...');
      final List<dynamic> decodedList = jsonDecode(goatsJson);
      List<Map<String, dynamic>> goatsData = List<Map<String, dynamic>>.from(decodedList);
      
      // Find the goat in the list
      int goatIndex = -1;
      for (int i = 0; i < goatsData.length; i++) {
        if (goatsData[i]['tagNo'] == widget.goat.tagNo) {
          goatIndex = i;
          break;
        }
      }
      
      if (goatIndex == -1) {
        debugPrint('❌ Goat ${widget.goat.tagNo} not found in data');
        return;
      }

      debugPrint('✅ Found goat at index $goatIndex');
      
      // Get or initialize weightHistory
      List<Map<String, dynamic>> weightHistory = [];
      if (goatsData[goatIndex]['weightHistory'] != null) {
        try {
          weightHistory = List<Map<String, dynamic>>.from(goatsData[goatIndex]['weightHistory']);
          debugPrint('📊 Existing weightHistory has ${weightHistory.length} records');
        } catch (e) {
          debugPrint('⚠️ Error reading weightHistory: $e');
          weightHistory = [];
        }
      } else {
        debugPrint('📝 No existing weightHistory, creating new one');
      }
      
      // Format date for storage
      final dateStr = _eventDate != null 
          ? '${_eventDate!.year}-${_eventDate!.month.toString().padLeft(2, '0')}-${_eventDate!.day.toString().padLeft(2, '0')}'
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Parse weight
      final weightText = _weighedController.text.trim();
      final weight = double.tryParse(weightText.replaceAll(',', '.')) ?? 0.0;
      
      // Add new weight record
      Map<String, dynamic> newRecord = {
        'date': dateStr,
        'weight': weight,
      };
      
      if (_notesController.text.trim().isNotEmpty) {
        newRecord['notes'] = _notesController.text.trim();
      }
      
      weightHistory.add(newRecord);

      debugPrint('➕ Adding weight record:');
      debugPrint('   - Date: $dateStr');
      debugPrint('   - Weight: $weight');
      debugPrint('   - Notes: ${_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : "None"}');

      // ✅ CRITICAL: Update the goat's data in the list
      goatsData[goatIndex]['weightHistory'] = weightHistory;
      goatsData[goatIndex]['weight'] = weightText; // Also update current weight
      
      debugPrint('✅ UPDATING GOAT ${widget.goat.tagNo}:');
      debugPrint('   - Weight: $weightText');
      debugPrint('   - Date: $dateStr');
      debugPrint('   - weightHistory now has ${weightHistory.length} records');
      
      // ✅ Save back to SharedPreferences
      final updatedJson = jsonEncode(goatsData);
      await prefs.setString('goats', updatedJson);

      debugPrint('💾 Saved to SharedPreferences successfully');

      // Verify the update
      final verifiedJson = prefs.getString('goats');
      if (verifiedJson != null) {
        final verifiedList = jsonDecode(verifiedJson);
        for (var goat in verifiedList) {
          if (goat['tagNo'] == widget.goat.tagNo) {
            debugPrint('✅ VERIFICATION:');
            debugPrint('   - Goat: ${goat['tagNo']}');
            debugPrint('   - Current weight: ${goat['weight']}');
            debugPrint('   - weightHistory: ${goat['weightHistory']}');
            debugPrint('   - weightHistory length: ${goat['weightHistory'] != null ? (goat['weightHistory'] as List).length : 0}');
            break;
          }
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error in _addWeightToGoatHistory: $e');
      debugPrint('Stack trace: ${e.toString()}');
    }
  }

  // ✅ NEW FUNCTION: Update breeding status based on breeding events
  Future<void> _updateBreedingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? goatsJson = prefs.getString('goats');

      if (goatsJson == null) {
        debugPrint('❌ No goats data found in SharedPreferences');
        return;
      }

      debugPrint('📥 Loading goats data for breeding status update...');
      final List<dynamic> decodedList = jsonDecode(goatsJson);
      List<Map<String, dynamic>> goatsData = List<Map<String, dynamic>>.from(decodedList);

      // Find the goat in the list
      int goatIndex = -1;
      for (int i = 0; i < goatsData.length; i++) {
        if (goatsData[i]['tagNo'] == widget.goat.tagNo) {
          goatIndex = i;
          break;
        }
      }

      if (goatIndex == -1) {
        debugPrint('❌ Goat ${widget.goat.tagNo} not found in data');
        return;
      }

      debugPrint('✅ Found goat at index $goatIndex');

      // Determine new breeding status based on event type
      String newBreedingStatus;
      switch (_eventType) {
        case 'Bred':
          newBreedingStatus = 'Bred';
          break;
        case 'Pregnancy Confirmed':
          newBreedingStatus = 'Pregnant';
          break;
        case 'Started Lactating':
          newBreedingStatus = 'Lactating';
          break;
        default:
          return; // Should not happen
      }

      // Update the breeding status
      final oldStatus = goatsData[goatIndex]['breedingStatus'] ?? 'Not Bred';
      goatsData[goatIndex]['breedingStatus'] = newBreedingStatus;

      debugPrint('✅ UPDATING BREEDING STATUS for ${widget.goat.tagNo}:');
      debugPrint('   - Old status: $oldStatus');
      debugPrint('   - New status: $newBreedingStatus');
      debugPrint('   - Event type: $_eventType');

      // ✅ Save back to SharedPreferences
      final updatedJson = jsonEncode(goatsData);
      await prefs.setString('goats', updatedJson);

      debugPrint('💾 Breeding status saved to SharedPreferences successfully');

    } catch (e) {
      debugPrint('❌ Error in _updateBreedingStatus: $e');
      debugPrint('Stack trace: ${e.toString()}');
    }
  }

  Future<void> _saveEvent() async {
    // Basic validation
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event date')),
      );
      return;
    }
    
    if (_eventType == null || _eventType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event type')),
      );
      return;
    }
    
    if (_eventType == 'Other' && _otherEventController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter event name')),
      );
      return;
    }

    // ✅ ADD WEIGHT TO GOAT HISTORY FIRST
    if (_eventType == 'Weighed' && _weighedController.text.trim().isNotEmpty) {
      debugPrint('⚡ Adding weight record for ${widget.goat.tagNo}...');
      await _addWeightToGoatHistory();
    }

    // ✅ UPDATE BREEDING STATUS FOR BREEDING EVENTS
    if (['Bred', 'Pregnancy Confirmed', 'Started Lactating'].contains(_eventType)) {
      debugPrint('⚡ Updating breeding status for ${widget.goat.tagNo}...');
      await _updateBreedingStatus();
    }

    // Create the event
    final event = Event(
      date: _eventDate!,
      tagNo: widget.goat.tagNo,
      eventType: _eventType!,
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
      technician: _technicianController.text.trim().isEmpty ? null : _technicianController.text.trim(),
      medicine: _medicineController.text.trim().isEmpty ? null : _medicineController.text.trim(),
      weighedResult: _weighedController.text.trim().isEmpty ? null : _weighedController.text.trim(),
      otherName: _eventType == 'Other' ? _otherEventController.text.trim() : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isMassEvent: false,
    );

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString('events');
      List<dynamic> eventsList = [];
      
      if (existingData != null) {
        eventsList = jsonDecode(existingData) as List<dynamic>;
      }
      
      if (widget.existingEvent != null) {
        // Update existing event
        final index = eventsList.indexWhere((e) {
          final eventJson = e as Map<String, dynamic>;
          return eventJson['date'] == widget.existingEvent!.date.toIso8601String() &&
                 eventJson['tagNo'] == widget.existingEvent!.tagNo &&
                 eventJson['eventType'] == widget.existingEvent!.eventType;
        });
        
        if (index != -1) {
          eventsList[index] = event.toJson();
        } else {
          // If not found, add as new
          eventsList.add(event.toJson());
        }
      } else {
        // Add new event
        eventsList.add(event.toJson());
      }
      
      await prefs.setString('events', jsonEncode(eventsList));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingEvent != null 
              ? 'Event updated successfully for ${widget.goat.tagNo}'
              : 'Event added successfully for ${widget.goat.tagNo}'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, event);
      }
    } catch (e) {
      debugPrint('❌ Error saving event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingEvent != null ? 'Edit Event' : 'Add Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white, size: 28),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Goat Info Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${widget.goat.tagNo} (${widget.goat.name ?? 'goat'})',
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
              const SizedBox(height: 24),

              // Event Date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF4CAF50),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _eventDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    borderRadius: BorderRadius.circular(8),
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
                              : 'Select date *',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Type
              GestureDetector(
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Select event type'),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 320,
                          child: ListView.separated(
                            itemCount: _eventTypes.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final type = _eventTypes[index];
                              return ListTile(
                                title: Text(type),
                                onTap: () => Navigator.of(ctx).pop(type),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                  if (selected != null) {
                    setState(() => _eventType = selected);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange.shade700, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _eventType ?? 'Select event type *',
                          style: TextStyle(
                            color: _eventType != null ? Colors.black87 : Colors.orange.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic fields based on event type
              if (_eventType == 'Treated') ..._buildTreatedFields(),
              if (_eventType == 'Weighed') ..._buildWeighedFields(),
              if (_eventType == 'Vaccinated' || _eventType == 'Deworming') ..._buildMedicineFields(),
              if (_eventType == 'Other') ..._buildOtherFields(),

              const SizedBox(height: 16),
              
              // Notes
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write some notes...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  labelText: 'Notes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTreatedFields() {
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _symptomsController,
        decoration: const InputDecoration(
          hintText: 'Symptoms *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
          labelText: 'Symptoms',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _diagnosisController,
        decoration: const InputDecoration(
          hintText: 'Diagnosis *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
          labelText: 'Diagnosis',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _technicianController,
        decoration: const InputDecoration(
          hintText: 'Treated by *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
          labelText: 'Treated by',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _medicineController,
        decoration: const InputDecoration(
          hintText: 'Medicine given *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
          labelText: 'Medicine',
        ),
      ),
    ];
  }

  List<Widget> _buildWeighedFields() {
    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.green[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This weight will be saved to the goat\'s weight history for tracking.',
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _weighedController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          hintText: 'Weight in kg (e.g., 25.5) *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
          labelText: 'Weight',
        ),
      ),
    ];
  }

  List<Widget> _buildMedicineFields() {
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _medicineController,
        decoration: const InputDecoration(
          hintText: 'Medicine given *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
          labelText: 'Medicine',
        ),
      ),
    ];
  }

  List<Widget> _buildOtherFields() {
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _otherEventController,
        decoration: const InputDecoration(
          hintText: 'Event name *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
          labelText: 'Event name',
        ),
      ),
    ];
  }
}