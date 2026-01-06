import 'package:flutter/material.dart';
import '../models/milk_record.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddMilkPage extends StatefulWidget {
  final MilkRecord? existingRecord; // Optional existing record for editing

  const AddMilkPage({super.key, this.existingRecord});

  @override
  _AddMilkPageState createState() => _AddMilkPageState();
}

class _AddMilkPageState extends State<AddMilkPage> {
  DateTime? _milkingDate;
  String? _milkType;
  final TextEditingController _morningQuantityController = TextEditingController();
  final TextEditingController _eveningQuantityController = TextEditingController();
  final TextEditingController _usedController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _milkTypes = [
    '- Select milk type -',
    'Whole Farm Milk',
    'Individual Goat Milk'
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.existingRecord != null) {
      // Populate fields from existing record
      final record = widget.existingRecord!;
      _milkingDate = record.milkingDate;
      _milkType = record.milkType;
      _morningQuantityController.text = record.morningQuantity.toStringAsFixed(1);
      _eveningQuantityController.text = record.eveningQuantity.toStringAsFixed(1);
      _usedController.text = record.used.toStringAsFixed(1);
      _notesController.text = record.notes ?? '';
    } else {
      _milkingDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _morningQuantityController.dispose();
    _eveningQuantityController.dispose();
    _usedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMilkRecord() async {
    // Basic validation
    if (_milkingDate == null) {
      _showError('Please select milking date');
      return;
    }
    
    if (_milkType == null || _milkType!.isEmpty || _milkType == '- Select milk type -') {
      _showError('Please select milk type');
      return;
    }
    
    // Parse quantities
    final morningText = _morningQuantityController.text.trim();
    final eveningText = _eveningQuantityController.text.trim();
    final usedText = _usedController.text.trim();
    
    if (morningText.isEmpty) {
      _showError('Please enter morning quantity');
      return;
    }
    
    if (eveningText.isEmpty) {
      _showError('Please enter evening quantity');
      return;
    }
    
    if (usedText.isEmpty) {
      _showError('Please enter used quantity');
      return;
    }
    
    final morningQuantity = double.tryParse(morningText.replaceAll(',', '.')) ?? 0.0;
    final eveningQuantity = double.tryParse(eveningText.replaceAll(',', '.')) ?? 0.0;
    final used = double.tryParse(usedText.replaceAll(',', '.')) ?? 0.0;
    final total = morningQuantity + eveningQuantity;
    
    if (used > total) {
      _showError('Used quantity cannot be greater than total quantity');
      return;
    }

    // Create the milk record
    final milkRecord = MilkRecord(
      milkingDate: _milkingDate!,
      morningQuantity: morningQuantity,
      eveningQuantity: eveningQuantity,
      total: total,
      used: used,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      milkType: _milkType!,
    );

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString('milk_records');
      List<dynamic> recordsList = [];
      
      if (existingData != null) {
        recordsList = jsonDecode(existingData) as List<dynamic>;
      }
      
      if (widget.existingRecord != null) {
        // Update existing record
        final index = recordsList.indexWhere((e) {
          final recordJson = e as Map<String, dynamic>;
          return recordJson['milkingDate'] == widget.existingRecord!.milkingDate.toIso8601String() &&
                 recordJson['milkType'] == widget.existingRecord!.milkType;
        });
        
        if (index != -1) {
          recordsList[index] = milkRecord.toJson();
        } else {
          // If not found, add as new
          recordsList.add(milkRecord.toJson());
        }
      } else {
        // Add new record
        recordsList.add(milkRecord.toJson());
      }
      
      await prefs.setString('milk_records', jsonEncode(recordsList));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord != null 
              ? 'Milk record updated successfully'
              : 'Milk record added successfully'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, milkRecord);
      }
    } catch (e) {
      print('❌ Error saving milk record: $e');
      if (mounted) {
        _showError('Error saving milk record: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
          widget.existingRecord != null ? 'Edit Milk Record' : 'Add Milk Record',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white, size: 28),
            onPressed: _saveMilkRecord,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Header Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_drink,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.existingRecord != null 
                          ? 'Edit Milk Record'
                          : 'New Milk Record',
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

              // Milking Date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _milkingDate ?? DateTime.now(),
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
                    setState(() => _milkingDate = picked);
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
                          _milkingDate != null 
                              ? DateFormat('dd/MM/yyyy').format(_milkingDate!)
                              : 'Select milking date *',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Milk Type
              GestureDetector(
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Select milk type'),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 200,
                          child: ListView.separated(
                            itemCount: _milkTypes.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final type = _milkTypes[index];
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
                    setState(() => _milkType = selected);
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
                          _milkType ?? 'Select milk type *',
                          style: TextStyle(
                            color: _milkType != null ? Colors.black87 : Colors.orange.shade700,
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

              // Morning Quantity
              TextField(
                controller: _morningQuantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Morning quantity in liters *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  labelText: 'Morning Quantity (Liters)',
                ),
              ),
              const SizedBox(height: 16),

              // Evening Quantity
              TextField(
                controller: _eveningQuantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Evening quantity in liters *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  labelText: 'Evening Quantity (Liters)',
                ),
              ),
              const SizedBox(height: 16),

              // Total Used
              TextField(
                controller: _usedController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Total used (kids/consumption) in liters *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  labelText: 'Total Used (Liters)',
                ),
              ),
              const SizedBox(height: 16),

              // Total Calculation Info
              if (_morningQuantityController.text.isNotEmpty || _eveningQuantityController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Production: ${_calculateTotal()} liters',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_usedController.text.isNotEmpty)
                              Text(
                                'Available: ${_calculateAvailable()} liters',
                                style: const TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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

  double _calculateTotal() {
    final morning = double.tryParse(_morningQuantityController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final evening = double.tryParse(_eveningQuantityController.text.trim().replaceAll(',', '.')) ?? 0.0;
    return morning + evening;
  }

  double _calculateAvailable() {
    final total = _calculateTotal();
    final used = double.tryParse(_usedController.text.trim().replaceAll(',', '.')) ?? 0.0;
    return total - used;
  }
}