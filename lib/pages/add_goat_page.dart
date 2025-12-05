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

  final List<String> breeds = ['Alpine', 'Boer', 'Kiko', 'Nubian'];
  final List<String> genders = ['Male', 'Female'];
  final List<String> goatStages = ['Kid', 'Wether', 'Buckling', 'Buck'];
  final List<String> obtained = ['Born on Farm', 'Purchased', 'Gift', 'Other'];

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
                      ...breeds.map((breed) {
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
                          child: const Text(
                            'Create new breed...',
                            style: TextStyle(
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
                        'CLOSE',
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Select Gender. *',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Gender options
                ...genders.map((gender) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedGender = gender;
                        selectedGoatStage = null; // Reset goat stage when gender changes
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
                      hintText: 'Search...',
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
                          child: const Text(
                            'Group (optional)',
                            style: TextStyle(
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
                          child: const Text(
                            'Create new group...',
                            style: TextStyle(
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
                        'CLOSE',
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Select how the goat was obtained. *',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Obtained options
                ...obtained.map((option) {
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    '- Select goat stage -',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Goat stage options
                ...goatStages.map((stage) {
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

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'New Goat',
          style: TextStyle(
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
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
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
              );

              debugPrint('Goat created: ${goat.tagNo}, ${goat.gender}');

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
              // ...existing code...
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
                label: 'Tag no. *',
                borderColor: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 16),

              // Name
              _buildTextField(
                controller: nameController,
                label: 'Name.',
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
                              selectedGoatStage ?? '- Select goat stage -',
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
                label: 'Date of birth.',
                borderColor: Colors.grey,
                isDate: true,
              ),
              const SizedBox(height: 16),

              // Date of entry on the farm
              _buildTextField(
                controller: entryDateController,
                label: 'Date of entry on the farm.',
                borderColor: Colors.grey,
                isDate: true,
              ),
              const SizedBox(height: 16),

              // Weight
              _buildTextField(
                controller: weightController,
                label: 'Weight.',
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
                        selectedGroup ?? AppLocalizations.of(context)!.groupOptional,
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

              // Mother's tag no.
              _buildTextField(
                controller: motherTagController,
                label: "Mother's tag no.",
                borderColor: Colors.grey,
              ),
              const SizedBox(height: 16),

              // Father's tag no.
              _buildTextField(
                controller: fatherTagController,
                label: "Father's tag no.",
                borderColor: Colors.grey,
              ),
              const SizedBox(height: 16),

              // Notes
              _buildTextField(
                controller: notesController,
                label: 'Write some notes ...',
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
