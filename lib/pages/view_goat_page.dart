import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
import '../models/event.dart'; // Import Event model from models
import 'edit_goat_page.dart';

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
        
        // Filter events for this specific goat
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

  // Fixed Age Calculation
  DateTime? _tryParseDate(String dateString) {
    try {
      // Try ISO format first
      final isoDate = DateTime.tryParse(dateString);
      if (isoDate != null) return isoDate;
      
      // Try common formats
      final parts = dateString.split(RegExp(r'[/\-.]'));
      if (parts.length == 3) {
        // Try DD/MM/YYYY
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        
        if (year != null && month != null && day != null) {
          if (year > 1000 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
        
        // Try YYYY-MM-DD
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
    
    // Calculate years, months, days
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    int days = now.day - dob.day;
    
    // Adjust for negative days
    if (days < 0) {
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    
    // Adjust for negative months
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    
    // Format the age
    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''} ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''} ${days > 0 ? '$days day${days > 1 ? 's' : ''}' : ''}';
    } else {
      return '$days day${days != 1 ? 's' : ''}';
    }
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
                title: Text(AppLocalizations.of(context)!.takePhoto),
                onTap: () {
                  Navigator.pop(sheetContext, 'camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.chooseFromGallery),
                onTap: () {
                  Navigator.pop(sheetContext, 'gallery');
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.removePhoto, style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext, 'remove');
                  },
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
        setState(() {
          _selectedImage = File(image.path);
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('goat_image_${widget.goat.tagNo}', image.path);
        
        final String? goatsJson = prefs.getString('goats');
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == 'camera' 
                ? AppLocalizations.of(context)!.photoCaptured
                : AppLocalizations.of(context)!.imageSelected),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } else if (result == 'remove' && mounted) {
      setState(() {
        _selectedImage = null;
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('goat_image_${widget.goat.tagNo}');
      
      final String? goatsJson = prefs.getString('goats');
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.photoRemoved),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color genderColor = widget.goat.gender == 'Male'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA726);

    return Scaffold(
      body: Column(
        children: [
          // Header with background image and goat icon
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
                  // Back button
                  Positioned(
                    top: 40,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context, _currentGoat),
                    ),
                  ),
                  // Menu button
                  Positioned(
                    top: 40,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                      onPressed: () {
                        // TODO: Show menu options
                      },
                    ),
                  ),
                  // Goat icon in center
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
                  // Tag number at bottom
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
          // Tabs
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
    Color genderColor = widget.goat.gender == 'Male'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA726);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // General Details Section
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
                  // Section header
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
                        Text(
                          AppLocalizations.of(context)!.generalDetails,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditGoatPage(goat: widget.goat),
                              ),
                            ).then((updatedGoat) {
                              if (updatedGoat != null && mounted) {
                                Navigator.pop(context, updatedGoat);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Details content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(AppLocalizations.of(context)!.tagNoLabel, widget.goat.tagNo),
                        _buildDetailRow(AppLocalizations.of(context)!.nameLabel, widget.goat.name ?? '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.dobLabel, widget.goat.dateOfBirth ?? '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.ageLabel, _calculateAge()),
                        _buildDetailRow(AppLocalizations.of(context)!.genderLabel, widget.goat.gender, 
                          valueColor: genderColor),
                        _buildDetailRow(AppLocalizations.of(context)!.weightLabel, 
                          widget.goat.weight != null ? '${widget.goat.weight}' : '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.stageLabel, widget.goat.goatStage ?? '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.breedLabel, widget.goat.breed ?? '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.groupLabel, widget.goat.group ?? '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.joinedOnLabel, widget.goat.dateOfEntry ?? '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.sourceLabel, widget.goat.obtained ?? '-'),
                        _buildDetailRowWithSearch(AppLocalizations.of(context)!.motherLabel, 
                          widget.goat.motherTag ?? '-'),
                        _buildDetailRowWithSearch(AppLocalizations.of(context)!.fatherLabel, 
                          widget.goat.fatherTag ?? '-'),
                        _buildDetailRow(AppLocalizations.of(context)!.notesLabel, widget.goat.notes ?? '-'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Display selected image if available
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
            // Upload picture button
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
                            ? AppLocalizations.of(context)!.tapToUpload
                            : AppLocalizations.of(context)!.changePicture,
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
            // Goat's Offspring Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Section header
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
                        Text(
                          AppLocalizations.of(context)!.goatOffspring,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_tree, color: Colors.white),
                          onPressed: () {
                            // TODO: Show family tree
                          },
                        ),
                      ],
                    ),
                  ),
                  // Offspring list
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildOffspringRow('01', 'goat'),
                        // Add more offspring here when available
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Events Tab
  Widget _buildEventsTab() {
    if (_goatEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.noEventsYet,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.eventsPlaceholder,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
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
    final loc = AppLocalizations.of(context)!;
    Color cardColor = widget.goat.gender == 'Male' 
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
          // Event header
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
                if (event.isMassEvent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      loc.massEvent,
                      style: TextStyle(
                        fontSize: 12,
                        color: cardColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventDetailRow(loc.dateLabel, _formatEventDate(event.date)),
                if (event.symptoms != null) 
                  _buildEventDetailRow(loc.symptomsLabel, event.symptoms!),
                if (event.diagnosis != null) 
                  _buildEventDetailRow(loc.diagnosisLabel, event.diagnosis!),
                if (event.technician != null) 
                  _buildEventDetailRow(loc.treatedByLabel, event.technician!),
                if (event.medicine != null) 
                  _buildEventDetailRow(loc.medicineLabel, event.medicine!),
                if (event.weighedResult != null) 
                  _buildEventDetailRow(loc.weighedLabel, event.weighedResult!),
                if (event.otherName != null) 
                  _buildEventDetailRow(loc.eventNameLabel, event.otherName!),
                if (event.notes != null) 
                  _buildEventDetailRow(loc.notesLabel, event.notes!),
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

  String _formatEventDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    Color defaultColor = widget.goat.gender == 'Male'
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
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

  Widget _buildDetailRowWithSearch(String label, String value) {
    Color searchColor = label.contains('Mother') 
        ? Colors.orange 
        : const Color(0xFF4CAF50);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.goat.gender == 'Male'
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFFA726),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: searchColor),
            onPressed: () {
              // TODO: Search for parent goat
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOffspringRow(String tag, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
            onPressed: () {
              // TODO: Navigate to offspring details
            },
          ),
        ],
      ),
    );
  }
}