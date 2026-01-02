import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goat.dart';

class AddGoatPage extends StatefulWidget {
  const AddGoatPage({super.key});

  @override
  State<AddGoatPage> createState() => _AddGoatPageState();
}

class _AddGoatPageState extends State<AddGoatPage> {
  // Controllers
  final TextEditingController tagController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController entryDateController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController motherTagController = TextEditingController();
  final TextEditingController fatherTagController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController _breedSearchController = TextEditingController();
  final TextEditingController _groupSearchController = TextEditingController();
  final TextEditingController _newGroupController = TextEditingController();
  final TextEditingController _newBreedController = TextEditingController();

  // State variables
  String? selectedBreed;
  String? selectedGender;
  String? selectedGoatStage;
  String? selectedGroup;
  String? selectedObtained;
  String? selectedBreedingStatus = 'Not Bred';
  String _breedSearchQuery = '';
  String _groupSearchQuery = '';
  List<String> _breeds = [];
  List<String> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadBreedsAndGroups();
  }

  @override
  void dispose() {
    tagController.dispose();
    nameController.dispose();
    dobController.dispose();
    entryDateController.dispose();
    weightController.dispose();
    motherTagController.dispose();
    fatherTagController.dispose();
    notesController.dispose();
    _breedSearchController.dispose();
    _groupSearchController.dispose();
    _newGroupController.dispose();
    _newBreedController.dispose();
    super.dispose();
  }

  Future<void> _loadBreedsAndGroups() async {
    // Get context before async gap
    final currentContext = context;
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedBreeds = prefs.getStringList('goatBreeds') ?? [];
    final savedGroups = prefs.getStringList('goatGroups') ?? [];
    
    if (!mounted) return;
    setState(() {
      _breeds = [
        AppLocalizations.of(currentContext)!.alpine,
        AppLocalizations.of(currentContext)!.boer,
        AppLocalizations.of(currentContext)!.kiko,
        AppLocalizations.of(currentContext)!.nubian,
        ...savedBreeds,
      ];
      _groups = savedGroups;
    });
  }

  Future<void> _showCreateNewGroupDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    _newGroupController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.newGroup, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _newGroupController,
                decoration: InputDecoration(
                  hintText: loc.enterGroupName,
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                    child: Text(loc.cancel, style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final newGroup = _newGroupController.text.trim();
                      if (newGroup.isNotEmpty && !_groups.contains(newGroup)) {
                        if (!mounted) return;
                        setState(() {
                          _groups.add(newGroup);
                          selectedGroup = newGroup;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList('goatGroups', _groups);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                    child: Text(loc.save, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateNewBreedDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    _newBreedController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.createNewBreed, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _newBreedController,
                decoration: InputDecoration(
                  hintText: loc.enterBreedName,
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                    child: Text(loc.cancel, style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final newBreed = _newBreedController.text.trim();
                      if (newBreed.isNotEmpty && !_breeds.contains(newBreed)) {
                        if (!mounted) return;
                        setState(() {
                          _breeds.add(newBreed);
                          selectedBreed = newBreed;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList('goatBreeds', _breeds);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                    child: Text(loc.save, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreedPicker() {
    _breedSearchController.text = '';
    _breedSearchQuery = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filteredBreeds = _breeds
                .where((breed) => breed.toLowerCase().contains(_breedSearchQuery.toLowerCase()))
                .toList();
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        AppLocalizations.of(context)!.breedOptional,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _breedSearchController,
                        onChanged: (val) {
                          setStateDialog(() {
                            _breedSearchQuery = val;
                          });
                        },
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
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (filteredBreeds.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No results found',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...filteredBreeds.map((breed) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedBreed = breed;
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
                                    breed,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          InkWell(
                            onTap: () async {
                              Navigator.pop(context);
                              await _showCreateNewBreedDialog(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.createNewBreed,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
      },
    );
  }

  void _showGenderPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    AppLocalizations.of(context)!.selectGenderRequired,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ..._getGenders().map((gender) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedGender = gender;
                        selectedGoatStage = null;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Text(
                        gender,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGroupPicker() {
    _groupSearchController.text = '';
    _groupSearchQuery = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filteredGroups = _groups
                .where((group) => group.toLowerCase().contains(_groupSearchQuery.toLowerCase()))
                .toList();
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        AppLocalizations.of(context)!.groupOptional,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _groupSearchController,
                        onChanged: (val) {
                          setStateDialog(() {
                            _groupSearchQuery = val;
                          });
                        },
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
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (filteredGroups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No results found',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...filteredGroups.map((group) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedGroup = group;
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
                                    group,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          InkWell(
                            onTap: () async {
                              Navigator.pop(context);
                              await _showCreateNewGroupDialog(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.createNewGroup,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
      },
    );
  }

  void _showObtainedPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    AppLocalizations.of(context)!.selectObtainedRequired,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ..._getObtainedOptions().map((option) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedObtained = option;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGoatStagePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    AppLocalizations.of(context)!.selectGoatStage,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ..._getGenderSpecificGoatStages().map((stage) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedGoatStage = stage;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Text(
                        stage,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBreedingStatusPicker() {
    final breedingOptions = [
      'Not Bred',
      'Bred', 
      'Pregnant',
      'Lactating',
      'Not Applicable'
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Breeding Status',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...breedingOptions.map((status) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedBreedingStatus = status;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
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
                        status,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  );
                }),
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

  List<String> _getGenders() {
    return [
      AppLocalizations.of(context)!.male,
      AppLocalizations.of(context)!.female,
    ];
  }

  List<String> _getGenderSpecificGoatStages() {
    final loc = AppLocalizations.of(context)!;
    if (selectedGender == loc.male) {
      return [
        loc.kid,
        loc.wether,
        loc.buckling,
        loc.buck,
      ];
    } else if (selectedGender == loc.female) {
      return [
        loc.kid,
        loc.doelings,
        loc.does,
      ];
    }
    return [];
  }

  List<String> _getObtainedOptions() {
    return [
      AppLocalizations.of(context)!.bornOnFarm,
      AppLocalizations.of(context)!.purchased,
      AppLocalizations.of(context)!.gift,
      AppLocalizations.of(context)!.other,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final breedingStatusLabel = selectedBreedingStatus ?? 'Not Bred';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.newGoat,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white, size: 28),
            onPressed: () {
              if (tagController.text.isEmpty || selectedGender == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.fillRequiredFields),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              List<Map<String, dynamic>>? initialWeightHistory;
              if (weightController.text.isNotEmpty) {
                final weightDate = entryDateController.text.isNotEmpty 
                    ? entryDateController.text 
                    : (dobController.text.isNotEmpty ? dobController.text : DateFormat('yyyy-MM-dd').format(DateTime.now()));
                
                initialWeightHistory = [{
                  'date': weightDate,
                  'weight': double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0.0,
                }];
              }

              final goat = Goat(
                tagNo: tagController.text,
                name: nameController.text.isEmpty ? null : nameController.text,
                breed: selectedBreed,
                gender: selectedGender!,
                goatStage: selectedGoatStage,
                dateOfBirth: dobController.text.isEmpty ? null : dobController.text,
                dateOfEntry: entryDateController.text.isEmpty ? null : entryDateController.text,
                weight: weightController.text.isEmpty ? null : weightController.text,
                group: selectedGroup,
                obtained: selectedObtained,
                motherTag: motherTagController.text.isEmpty ? null : motherTagController.text,
                fatherTag: fatherTagController.text.isEmpty ? null : fatherTagController.text,
                notes: notesController.text.isEmpty ? null : notesController.text,
                photoPath: null,
                weightHistory: initialWeightHistory,
                breedingStatus: selectedBreedingStatus,
                breedingDate: null,
                breedingPartner: null,
                kiddingHistory: null,
                kiddingDueDate: null,
              );

              debugPrint('Goat created: ${goat.tagNo}, ${goat.gender}, Breeding Status: ${goat.breedingStatus}');

              Navigator.pop(context, goat);
            },
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              InkWell(
                onTap: _showBreedPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedBreed ?? AppLocalizations.of(context)!.breedOptional2,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
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
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: tagController,
                label: AppLocalizations.of(context)!.tagNoRequired,
                borderColor: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: nameController,
                label: AppLocalizations.of(context)!.nameLabel,
                borderColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _showGenderPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selectedGender == null ? const Color(0xFFFFA726) : const Color(0xFF4CAF50), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedGender ?? AppLocalizations.of(context)!.selectGender,
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedGender == null ? const Color(0xFFFFA726) : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: selectedGender == null ? const Color(0xFFFFA726) : const Color(0xFF4CAF50),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (selectedGender != null)
                Column(
                  children: [
                    InkWell(
                      onTap: _showGoatStagePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFA726), width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedGoatStage ?? AppLocalizations.of(context)!.selectGoatStage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFFFFA726),
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              _buildTextField(
                controller: dobController,
                label: AppLocalizations.of(context)!.dateOfBirthLabel,
                borderColor: Colors.grey,
                isDate: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: entryDateController,
                label: AppLocalizations.of(context)!.dateOfEntryLabel,
                borderColor: Colors.grey,
                isDate: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: weightController,
                label: AppLocalizations.of(context)!.weightLabel,
                borderColor: Colors.grey,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _showGroupPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedGroup ?? AppLocalizations.of(context)!.groupOptional2,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
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
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _showObtainedPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedObtained == null
                          ? const Color(0xFFFFA726)
                          : const Color(0xFF4CAF50),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedObtained ?? AppLocalizations.of(context)!.selectObtained,
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedObtained == null
                              ? const Color(0xFFFFA726)
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: selectedObtained == null
                            ? const Color(0xFFFFA726)
                            : const Color(0xFF4CAF50),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (selectedGender != null)
                Column(
                  children: [
                    InkWell(
                      onTap: _showBreedingStatusPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF9C27B0), width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              breedingStatusLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF9C27B0),
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              _buildTextField(
                controller: motherTagController,
                label: AppLocalizations.of(context)!.motherTagLabel,
                borderColor: Colors.grey,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: fatherTagController,
                label: AppLocalizations.of(context)!.fatherTagLabel,
                borderColor: Colors.grey,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: notesController,
                label: AppLocalizations.of(context)!.notesLabel,
                borderColor: Colors.grey,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color borderColor,
    bool isDate = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: isDate
              ? const Icon(Icons.calendar_today, color: Colors.grey)
              : null,
        ),
        readOnly: isDate,
        onTap: isDate
            ? () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  controller.text =
                      "${picked.day}/${picked.month}/${picked.year}";
                }
              }
            : null,
      ),
    );
  }
}