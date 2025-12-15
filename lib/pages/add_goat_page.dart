import 'package:flutter/material.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';

class AddGoatPage extends StatefulWidget {
  const AddGoatPage({super.key});

  @override
  State<AddGoatPage> createState() => _AddGoatPageState();
}

class _AddGoatPageState extends State<AddGoatPage> {
  final TextEditingController tagController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController entryDateController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController motherTagController = TextEditingController();
  final TextEditingController fatherTagController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? selectedBreed;
  String? selectedGender;
  String? selectedGoatStage;
  String? selectedGroup;
  String? selectedObtained;
  String? selectedBreedingStatus = 'Not Bred'; // New: Breeding status

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
    super.dispose();
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
                    AppLocalizations.of(context)!.breedOptional,
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
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Breed (optional) - first item
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedBreed = null;
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
                            AppLocalizations.of(context)!.breedOptional2,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      ),
                      // Breed options
                      ..._getBreeds().map((breed) {
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
                      // Create new breed option
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Show create new breed dialog
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
                // Dialog Title
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
                // Gender options
                ..._getGenders().map((gender) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedGender = gender;
                        selectedGoatStage = null; // Reset goat stage when gender changes
                        // Reset breeding status to default if gender changes
                        if (gender.toLowerCase().contains('male')) {
                          selectedBreedingStatus = 'Not Applicable';
                        } else {
                          selectedBreedingStatus = 'Not Bred';
                        }
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
                    AppLocalizations.of(context)!.groupOptional,
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
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Group (optional) - first item
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedGroup = null;
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
                            AppLocalizations.of(context)!.groupOptional2,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      ),
                      // Create new group option
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Show create new group dialog
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
                // Dialog Title
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
                // Obtained options
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
                // Dialog Title
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
                // Goat stage options - Gender specific
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

  // NEW: Breeding Status Picker
  void _showBreedingStatusPicker() {
    final isMale = selectedGender?.toLowerCase().contains('male') ?? false;
    final breedingOptions = isMale 
        ? ['Not Applicable', 'Breeding Active', 'Breeding Rest']
        : ['Not Bred', 'Bred', 'Pregnant', 'Lactating'];
    
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
                // Dialog Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    isMale ? 'Breeding Status (Male)' : 'Breeding Status',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Breeding status options
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

  // Helper methods to get localized lists
  List<String> _getBreeds() {
    return [
      AppLocalizations.of(context)!.alpine,
      AppLocalizations.of(context)!.boer,
      AppLocalizations.of(context)!.kiko,
      AppLocalizations.of(context)!.nubian,
    ];
  }

  List<String> _getGenders() {
    return [
      AppLocalizations.of(context)!.male,
      AppLocalizations.of(context)!.female,
    ];
  }

  // Gender-specific goat stages
  List<String> _getGenderSpecificGoatStages() {
    if (selectedGender?.toLowerCase().contains('male') ?? false) {
      return [
        AppLocalizations.of(context)!.kid,
        AppLocalizations.of(context)!.wether,
        AppLocalizations.of(context)!.buckling,
        AppLocalizations.of(context)!.buck,
      ];
    } else if (selectedGender?.toLowerCase().contains('female') ?? false) {
      return [
        AppLocalizations.of(context)!.kid,
        'Doelings', // You need to add this to your AppLocalizations
        'Does',      // You need to add this to your AppL
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
    final isMale = selectedGender?.toLowerCase().contains('male') ?? false;
    final breedingStatusLabel = selectedBreedingStatus ?? 
        (isMale ? 'Not Applicable' : 'Not Bred');

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
              // Validate required fields
              if (tagController.text.isEmpty || selectedGender == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.fillRequiredFields),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Create Goat object
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
                weightHistory: null,
                // NEW: Breeding fields
                breedingStatus: selectedBreedingStatus,
                breedingDate: null,
                breedingPartner: null,
                kiddingHistory: null,
                kiddingDueDate: null,
              );

              debugPrint('Goat created: ${goat.tagNo}, ${goat.gender}, Breeding Status: ${goat.breedingStatus}');

              // Return goat to previous page
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
              // Breed dropdown (optional)
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
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedBreed == null ? Colors.black87 : Colors.black87,
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

              // Tag no. *
              _buildTextField(
                controller: tagController,
                label: AppLocalizations.of(context)!.tagNoRequired,
                borderColor: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 16),

              // Name
              _buildTextField(
                controller: nameController,
                label: AppLocalizations.of(context)!.nameLabel,
                borderColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),

              // Select Gender *
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

              // Goat Stage (only show if gender is selected)
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
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedGoatStage == null ? Colors.black87 : Colors.black87,
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

              // Date of birth
              _buildTextField(
                controller: dobController,
                label: AppLocalizations.of(context)!.dateOfBirthLabel,
                borderColor: Colors.grey,
                isDate: true,
              ),
              const SizedBox(height: 16),

              // Date of entry on the farm
              _buildTextField(
                controller: entryDateController,
                label: AppLocalizations.of(context)!.dateOfEntryLabel,
                borderColor: Colors.grey,
                isDate: true,
              ),
              const SizedBox(height: 16),

              // Weight
              _buildTextField(
                controller: weightController,
                label: AppLocalizations.of(context)!.weightLabel,
                borderColor: Colors.grey,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Group (optional)
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
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedGroup == null ? Colors.black87 : Colors.black87,
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

              // Select how the goat was obtained *
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

              // NEW: Breeding Status
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

              // Mother's tag no.
              _buildTextField(
                controller: motherTagController,
                label: AppLocalizations.of(context)!.motherTagLabel,
                borderColor: Colors.grey,
              ),
              const SizedBox(height: 16),

              // Father's tag no.
              _buildTextField(
                controller: fatherTagController,
                label: AppLocalizations.of(context)!.fatherTagLabel,
                borderColor: Colors.grey,
              ),
              const SizedBox(height: 16),

              // Notes
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