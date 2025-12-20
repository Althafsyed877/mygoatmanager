import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_goat_page.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
import 'view_goat_page.dart';
import 'edit_goat_page.dart';
import 'add_event_page.dart';
import 'goat_preview_page.dart';
import '../services/archive_service.dart'; // Add this import

class GoatsPage extends StatefulWidget {
  const GoatsPage({super.key});

  @override
  State<GoatsPage> createState() => _GoatsPageState();
}

class _GoatsPageState extends State<GoatsPage> {
  String selectedBreed = 'All Breeds';
  String selectedGroup = 'All Groups';
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  List<Goat> goats = [];
  Set<String> selectedGoats = {};
  List<String> _breeds = [];
  List<String> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGoats();
    _loadBreedsAndGroups();
  }

  Future<void> _loadGoats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? goatsJson = prefs.getString('goats');
    if (goatsJson != null) {
      final List<dynamic> decodedList = jsonDecode(goatsJson);
      setState(() {
        goats = decodedList
            .map((item) => Goat.fromJson(item))
            .where((goat) => goat.tagNo.isNotEmpty) // Filter out goats with empty tagNo
            .toList();
      });
    }
  }

  Future<void> _loadBreedsAndGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final breedsData = prefs.getStringList('goatBreeds') ?? [];
    final groupsData = prefs.getStringList('goatGroups') ?? [];
    
    setState(() {
      _breeds = [AppLocalizations.of(context)!.allBreeds, ...breedsData];
      _groups = [AppLocalizations.of(context)!.allGroups, ...groupsData];
    });
  }

  Future<void> _saveGoats() async {
    final prefs = await SharedPreferences.getInstance();
    final String goatsJson = jsonEncode(goats.map((goat) => goat.toJson()).toList());
    await prefs.setString('goats', goatsJson);
  }

  List<String> get breeds => _breeds.isNotEmpty ? _breeds : [
    AppLocalizations.of(context)!.allBreeds,
    AppLocalizations.of(context)!.alpine,
    AppLocalizations.of(context)!.boer,
    AppLocalizations.of(context)!.kiko,
    AppLocalizations.of(context)!.nubian,
  ];

  List<String> get groups => _groups.isNotEmpty ? _groups : [
    AppLocalizations.of(context)!.allGroups,
  ];

  List<Goat> get filteredGoats {
    List<Goat> filtered = List.from(goats);
    final loc = AppLocalizations.of(context);

    // Apply search filter
    if (isSearching && searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();
      filtered = filtered.where((goat) {
        return goat.tagNo.toLowerCase().contains(query) ||
               (goat.name?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply breed filter
    if (selectedBreed != (loc?.allBreeds ?? 'All Breeds')) {
      filtered = filtered.where((goat) {
        final localizedBreed = _getLocalizedBreed(goat.breed ?? '');
        return localizedBreed == selectedBreed;
      }).toList();
    }

    // Apply group filter
    if (selectedGroup != (loc?.allGroups ?? 'All Groups')) {
      filtered = filtered.where((goat) => goat.group == selectedGroup).toList();
    }

    return filtered;
  }

  String _getLocalizedBreed(String englishBreed) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return englishBreed;
    
    switch (englishBreed) {
      case 'Alpine': return loc.alpine;
      case 'Boer': return loc.boer;
      case 'Kiko': return loc.kiko;
      case 'Nubian': return loc.nubian;
      default: return englishBreed;
    }
  }

  void _showBreedPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    AppLocalizations.of(context)!.selectBreed,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Breed list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: breeds.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedBreed = breeds[index];
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            breeds[index],
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.close.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal[700],
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

  void _showGroupPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    AppLocalizations.of(context)!.selectGroup,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Group list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedGroup = groups[index];
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            groups[index],
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.close.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal[700],
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () {
            if (isSearching) {
              setState(() {
                isSearching = false;
                searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchTagOrName,
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(
                AppLocalizations.of(context)!.goatsTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
            onPressed: () {
              if (goats.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.noGoatsAvailableToPreview)),
                );
                return;
              }

              int initial = 0;
              if (selectedGoats.isNotEmpty) {
                final firstTag = selectedGoats.first;
                final idx = goats.indexWhere((g) => g.tagNo == firstTag);
                if (idx != -1) initial = idx;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoatPreviewPage(goats: goats, initialIndex: initial),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  await _exportGoatsPdf();
                  break;
                case 'filter':
                  _showBreedPicker();
                  break;
                case 'sort_age':
                  setState(() {
                    goats.sort((a, b) {
                      DateTime? da = _tryParseDate(a.dateOfBirth);
                      DateTime? db = _tryParseDate(b.dateOfBirth);
                      if (da == null && db == null) return 0;
                      if (da == null) return 1;
                      if (db == null) return -1;
                      return da.compareTo(db);
                    });
                  });
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'export',
                child: Text(AppLocalizations.of(context)!.exportPdf),
              ),
              PopupMenuItem<String>(
                value: 'filter',
                child: Text(AppLocalizations.of(context)!.filterBy),
              ),
              PopupMenuItem<String>(
                value: 'sort_age',
                child: Text(AppLocalizations.of(context)!.sortByAge),
              ),
            ],
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
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            // Filter section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      label: selectedBreed,
                      onTap: _showBreedPicker,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFilterDropdown(
                      label: selectedGroup,
                      onTap: _showGroupPicker,
                    ),
                  ),
                ],
              ),
            ),
            // Goats list or empty state
            Expanded(
              child: filteredGoats.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          isSearching || selectedBreed != AppLocalizations.of(context)!.allBreeds || selectedGroup != AppLocalizations.of(context)!.allGroups
                              ? 'No goats match the current filters'
                              : AppLocalizations.of(context)!.noGoatsRegistered,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredGoats.length,
                      itemBuilder: (context, index) {
                        final goat = filteredGoats[index];
                        return _buildGoatCard(goat);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoatPage()),
          );
          
          debugPrint('Result from AddGoatPage: $result');
          
          if (result != null && result is Goat) {
            setState(() {
              goats.add(result);
              debugPrint('Goat added! Total goats: ${goats.length}');
            });
            await _saveGoats();
          }
        },
        backgroundColor: const Color(0xFFFFA726),
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        label: Text(
          AppLocalizations.of(context)!.addGoat,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF424242),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF4CAF50),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoatCard(Goat goat) {
    final isMale = goat.gender.toLowerCase() == AppLocalizations.of(context)!.male.toLowerCase();
    final genderColor = isMale ? const Color(0xFF4CAF50) : const Color(0xFFFFA726);
    final isSelected = selectedGoats.contains(goat.tagNo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewGoatPage(goat: goat),
            ),
          );
          if (result != null && result is Goat) {
            setState(() {
              final index = goats.indexWhere((g) => g.tagNo == goat.tagNo);
              if (index != -1) goats[index] = result;
            });
            await _saveGoats();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
          children: [
            // Checkbox
            InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedGoats.remove(goat.tagNo);
                  } else {
                    selectedGoats.add(goat.tagNo);
                  }
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(4),
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Goat icon - Green for male, Orange for female
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/goat.png',
                color: genderColor,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            // Tag and Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goat.tagNo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goat.name ?? AppLocalizations.of(context)!.goat,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Gender badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: genderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: genderColor, width: 1.5),
              ),
              child: Text(
                goat.gender,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: genderColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Three-dot menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewGoatPage(goat: goat),
                      ),
                    ).then((updated) async {
                      if (updated != null && updated is Goat) {
                        setState(() {
                          final index = goats.indexWhere((g) => g.tagNo == goat.tagNo);
                          if (index != -1) goats[index] = updated;
                        });
                        await _saveGoats();
                      }
                    });
                    break;
                  case 'edit':
                    // Validate goat data before editing
                    if (goat.tagNo.isEmpty || goat.gender.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot edit goat with invalid data.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      break;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditGoatPage(goat: goat),
                      ),
                    ).then((updatedGoat) async {
                      if (updatedGoat != null) {
                        setState(() {
                          final index = goats.indexWhere((g) => g.tagNo == goat.tagNo);
                          if (index != -1) {
                            goats[index] = updatedGoat;
                          }
                        });
                        await _saveGoats();
                      }
                    });
                    break;
                  case 'event':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventPage(goat: goat),
                      ),
                    );
                    break;
                  case 'delete':
                    _showArchiveOrDeleteDialog(goat);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'view',
                  child: Text(AppLocalizations.of(context)!.viewRecord),
                ),
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text(AppLocalizations.of(context)!.editRecord),
                ),
                PopupMenuItem<String>(
                  value: 'event',
                  child: Text(AppLocalizations.of(context)!.addEvent),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(AppLocalizations.of(context)!.delete),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  // NEW: Archive or Delete Dialog
  void _showArchiveOrDeleteDialog(Goat goat) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archive or Delete'),
          content: Text('What would you like to do with ${goat.tagNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showArchiveDialog(goat);
              },
              child: const Text(
                'Archive',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _permanentDeleteGoat(goat);
              },
              child: Text(
                loc.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // NEW: Archive Dialog
  void _showArchiveDialog(Goat goat) {
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
                    Text('Goat: ${goat.tagNo} - ${goat.name ?? "Unnamed"}'),
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
                      await ArchiveService.archiveGoat(
                        goat: goat,
                        reason: selectedReason!,
                        archiveDate: archiveDate,
                        notes: notes.isEmpty ? null : notes,
                      );
                      
                      // Remove from active list
                      setState(() {
                        goats.removeWhere((g) => g.tagNo == goat.tagNo);
                      });
                      
                      await _saveGoats();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Goat ${goat.tagNo} archived as ${selectedReason!}'),
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                        );
                        Navigator.of(ctx).pop();
                      }
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

  // NEW: Permanent Delete (keeps old functionality)
  void _permanentDeleteGoat(Goat goat) async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      goats.removeWhere((g) => g.tagNo == goat.tagNo);
    });
    await _saveGoats();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.deleteGoatDeleted} ${goat.tagNo}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // OLD: Delete Dialog (now replaced by archive dialog)
  // void _showDeleteDialog(Goat goat) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(AppLocalizations.of(context)!.deleteGoatTitle),
  //         content: Text('${AppLocalizations.of(context)!.deleteGoatConfirm} ${goat.tagNo}?'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: Text(AppLocalizations.of(context)!.cancel),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               setState(() {
  //                 goats.removeWhere((g) => g.tagNo == goat.tagNo);
  //               });
  //               await _saveGoats();
  //               Navigator.pop(context);
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text('${AppLocalizations.of(context)!.deleteGoatDeleted} ${goat.tagNo}'),
  //                   backgroundColor: Colors.red,
  //                 ),
  //               );
  //             },
  //             child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  DateTime? _tryParseDate(String? s) {
    if (s == null) return null;
    final str = s.trim();
    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    String? sep;
    if (str.contains('/')) sep = '/';
    else if (str.contains('-')) sep = '-';

    if (sep != null) {
      final parts = str.split(sep);
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            try {
              return DateTime(y, m, d);
            } catch (_) {}
          }
        }
        if (parts[2].length == 4) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            try {
              return DateTime(y, m, d);
            } catch (_) {}
          }
        }
      }
    }

    final daysMatch = RegExp(r'^(\d+)\s*days?\b', caseSensitive: false).firstMatch(str);
    if (daysMatch != null) {
      final days = int.tryParse(daysMatch.group(1) ?? '');
      if (days != null) return DateTime.now().subtract(Duration(days: days));
    }

    return null;
  }

  String _formatAgeFromDob(String? dobStr) {
    final dt = _tryParseDate(dobStr);
    if (dt == null) return '-';
    final now = DateTime.now();

    int years = now.year - dt.year;
    int months = now.month - dt.month;
    int days = now.day - dt.day;

    if (days < 0) {
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }

    if (years > 0) return '${years}y ${months}m';
    if (months > 0) return '${months}m ${days}d';
    return '${days} ${AppLocalizations.of(context)!.days}';
  }

  Future<void> _exportGoatsPdf() async {
    final doc = pw.Document();

    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/images/goat.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    final localizations = AppLocalizations.of(context)!;
    final goatsListTitle = localizations.goatsListPdf;
    final breedLabel = localizations.breedLabel2;
    final groupLabel = localizations.groupLabel2;
    final dateLabel = localizations.dateLabel;
    final totalLabel = localizations.totalGoats;
    final setFarmLogo = localizations.setFarmLogo;
    final setFarmName = localizations.setFarmName;
    final setFarmLocation = localizations.setFarmLocation;
    final tagLabel = localizations.tagLabel;
    final nameLabel = localizations.nameLabel;
    final genderLabel = localizations.genderLabel;
    final stageLabel = localizations.stageLabel;
    final dobLabel = localizations.dobLabel;
    final ageLabel = localizations.ageLabel;
    final breedLabel2 = localizations.breedLabel;
    final groupLabel2 = localizations.groupLabel;
    final weightLabel = localizations.weightLabel;
    final goatsFilename = localizations.goatsFilename;

    final headers = [
      tagLabel,
      nameLabel,
      genderLabel,
      stageLabel,
      dobLabel,
      ageLabel,
      breedLabel2,
      groupLabel2,
      weightLabel,
    ];

    final data = goats.map((g) {
      final dob = g.dateOfBirth ?? '-';
      final ageStr = _formatAgeFromDob(g.dateOfBirth);

      return [g.tagNo, g.name ?? '-', g.gender, g.goatStage ?? '-', dob, ageStr, g.breed ?? '-', g.group ?? '-', g.weight ?? '-'];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => [
          pw.Column(
            children: [
              if (logoBytes != null)
                pw.Center(
                  child: pw.Image(pw.MemoryImage(logoBytes), width: 48, height: 48),
                ),
              pw.SizedBox(height: 6),
              pw.Text(setFarmLogo, style: pw.TextStyle(fontSize: 10)),
              pw.Text(setFarmName, style: pw.TextStyle(fontSize: 10)),
              pw.Text(setFarmLocation, style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Text(goatsListTitle, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('$breedLabel $selectedBreed', style: pw.TextStyle(fontSize: 10)),
              pw.Text('$groupLabel $selectedGroup', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Text('$dateLabel ${DateTime.now().toLocal().toString().substring(0, 19)}', style: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.red)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: pdf.PdfColors.green),
                cellStyle: pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 8),
              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('$totalLabel  ${goats.length}', style: pw.TextStyle(fontSize: 10))),
            ],
          )
        ],
      ),
    );

    final bytes = await doc.save();

    await Printing.sharePdf(
      bytes: bytes, 
      filename: '${goatsFilename}_${DateTime.now().millisecondsSinceEpoch}.pdf'
    );
  }
}