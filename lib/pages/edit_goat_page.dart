import 'package:flutter/material.dart';
import '../models/goat.dart';

class EditGoatPage extends StatefulWidget {
  final Goat goat;

  const EditGoatPage({super.key, required this.goat});

  @override
  State<EditGoatPage> createState() => _EditGoatPageState();
}

class _EditGoatPageState extends State<EditGoatPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tagNoController;
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _entryDateController;
  late TextEditingController _weightController;
  late TextEditingController _motherTagController;
  late TextEditingController _fatherTagController;
  late TextEditingController _notesController;

  String? _selectedBreed;
  String? _selectedGender;
  String? _selectedGoatStage;
  String? _selectedGroup;
  String? _selectedObtained;

  final List<String> _breeds = [
    'Boer',
    'Saanen',
    'Alpine',
    'Nubian',
    'LaMancha',
    'Nigerian Dwarf',
    'Oberhasli',
    'Toggenburg',
    'Anglo-Nubian',
  ];

  final List<String> _groups = [
    'Group A',
    'Group B',
    'Group C',
    'Breeding Group',
    'Kids Group',
  ];

  final List<String> _obtainedMethods = [
    'Born on Farm',
    'Purchased',
    'Traded',
    'Gift',
    'Adopted',
  ];

  @override
  void initState() {
    super.initState();
    _tagNoController = TextEditingController(text: widget.goat.tagNo);
    _nameController = TextEditingController(text: widget.goat.name);
    _dobController = TextEditingController(text: widget.goat.dateOfBirth);
    _entryDateController = TextEditingController(text: widget.goat.dateOfEntry);
    _weightController = TextEditingController(
      text: widget.goat.weight != null ? widget.goat.weight.toString() : '',
    );
    _motherTagController = TextEditingController(text: widget.goat.motherTag);
    _fatherTagController = TextEditingController(text: widget.goat.fatherTag);
    _notesController = TextEditingController(text: widget.goat.notes);

    _selectedBreed = widget.goat.breed;
    _selectedGender = widget.goat.gender;
    _selectedGoatStage = widget.goat.goatStage;
    _selectedGroup = widget.goat.group;
    _selectedObtained = widget.goat.obtained;
  }

  @override
  void dispose() {
    _tagNoController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _entryDateController.dispose();
    _weightController.dispose();
    _motherTagController.dispose();
    _fatherTagController.dispose();
    _notesController.dispose();
    super.dispose();
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
        title: const Text(
          'Edit Goat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white, size: 28),
            onPressed: _saveGoat,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
            // Breed Dropdown
            _buildDropdownField(
              label: 'Breed (optional)',
              value: _selectedBreed,
              items: _breeds,
              onChanged: (value) {
                setState(() {
                  _selectedBreed = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Tag No
            _buildTextField(
              controller: _tagNoController,
              label: 'Tag no. *',
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Name.',
            ),
            const SizedBox(height: 16),

            // Gender Dropdown
            _buildDropdownField(
              label: 'Gender *',
              value: _selectedGender,
              items: ['Male', 'Female'],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Goat Stage Dropdown
            _buildDropdownField(
              label: 'Goat Stage',
              value: _selectedGoatStage,
              items: ['Kid', 'Doeling', 'Buckling', 'Doe', 'Buck', 'Wether'],
              onChanged: (value) {
                setState(() {
                  _selectedGoatStage = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
            _buildTextField(
              controller: _dobController,
              label: 'Date of birth.',
              readOnly: true,
              onTap: () => _selectDate(context, _dobController),
            ),
            const SizedBox(height: 16),

            // Date of Entry
            _buildTextField(
              controller: _entryDateController,
              label: 'Date of entry on the farm.',
              readOnly: true,
              onTap: () => _selectDate(context, _entryDateController),
            ),
            const SizedBox(height: 16),

            // Weight
            _buildTextField(
              controller: _weightController,
              label: 'Weight.',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Group Dropdown
            _buildDropdownField(
              label: 'Group (optional)',
              value: _selectedGroup,
              items: _groups,
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Obtained Method Dropdown
            _buildDropdownField(
              label: 'Source (optional)',
              value: _selectedObtained,
              items: _obtainedMethods,
              onChanged: (value) {
                setState(() {
                  _selectedObtained = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Mother's Tag
            _buildTextField(
              controller: _motherTagController,
              label: "Mother's tag no.",
              suffixIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 16),

            // Father's Tag
            _buildTextField(
              controller: _fatherTagController,
              label: "Father's tag no.",
              suffixIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'Write some notes ...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRequired)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: isRequired ? null : label,
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: Colors.grey[600])
                  : null,
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        hint: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CAF50)),
        isExpanded: true,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      setState(() {
        controller.text = picked.toString().split(' ')[0];
      });
    }
  }

  void _saveGoat() {
    if (_formKey.currentState!.validate()) {
      final updatedGoat = Goat(
        tagNo: _tagNoController.text,
        name: _nameController.text.isEmpty ? null : _nameController.text,
        breed: _selectedBreed,
        gender: _selectedGender ?? 'Male',
        goatStage: _selectedGoatStage,
        dateOfBirth: _dobController.text.isEmpty ? null : _dobController.text,
        dateOfEntry:
            _entryDateController.text.isEmpty ? null : _entryDateController.text,
        weight: _weightController.text.isEmpty ? null : _weightController.text,
        group: _selectedGroup,
        obtained: _selectedObtained,
        motherTag:
            _motherTagController.text.isEmpty ? null : _motherTagController.text,
        fatherTag:
            _fatherTagController.text.isEmpty ? null : _fatherTagController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoPath: widget.goat.photoPath,
      );

      Navigator.pop(context, updatedGoat);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goat updated successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }
}
