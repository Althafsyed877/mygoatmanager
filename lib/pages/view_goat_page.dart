import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentGoat = widget.goat;
    // load persisted image if any
    _loadPersistedImage();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _calculateAge() {
    if (widget.goat.dateOfBirth == null || widget.goat.dateOfBirth!.isEmpty) {
      return '-';
    }
    try {
      DateTime dob = DateTime.parse(widget.goat.dateOfBirth!);
      DateTime now = DateTime.now();
      int days = now.difference(dob).inDays;
      
      if (days == 0) return '1 day';
      if (days == 1) return '1 day';
      if (days < 30) return '$days days';
      if (days < 365) {
        int months = (days / 30).floor();
        return months == 1 ? '1 month' : '$months months';
      }
      int years = (days / 365).floor();
      return years == 1 ? '1 year' : '$years years';
    } catch (e) {
      return '-';
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(AppLocalizations.of(context)!.takePhoto),
                onTap: () async {
                  // Use the sheet's context to close the sheet, but capture
                  // the parent scaffold/navigator context before awaiting.
                  final parentContext = context;
                  final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
                  Navigator.pop(sheetContext);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    if (mounted) {
                      setState(() {
                        _selectedImage = File(image.path);
                      });
                      // persist image path for this goat so other pages can load it
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('goat_image_${widget.goat.tagNo}', image.path);
                      // also update stored goats JSON so photoPath persists in goat data
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
                      // Show a snackbar using the captured scaffold messenger.
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.photoCaptured),
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.chooseFromGallery),
                onTap: () async {
                  final parentContext = context;
                  final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
                  Navigator.pop(sheetContext);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    if (mounted) {
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
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.imageSelected),
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      );
                    }
                  }
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.removePhoto, style: const TextStyle(color: Colors.red)),
                  onTap: () async {
                    final parentContext = context;
                    final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
                    Navigator.pop(sheetContext);
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
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.photoRemoved),
                        backgroundColor: Colors.grey,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
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
                            final navigator = Navigator.of(context);
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) => EditGoatPage(goat: widget.goat),
                              ),
                            ).then((updatedGoat) {
                              if (updatedGoat != null) {
                                if (!mounted) return;
                                navigator.pop(updatedGoat);
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

  Widget _buildEventsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event, size: 80, color: Colors.grey[300]),
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
}
