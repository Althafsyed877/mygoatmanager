import 'package:flutter/material.dart';


class AddMilkPage extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialMilkType;
  final String? initialTotalProduced;
  final String? initialTotalUsed;
  final String? initialNotes;
  final bool isEdit;

  const AddMilkPage({
    super.key,
    this.initialDate,
    this.initialMilkType,
    this.initialTotalProduced,
    this.initialTotalUsed,
    this.initialNotes,
    this.isEdit = false,
  });

  @override
  State<AddMilkPage> createState() => _AddMilkPageState();
}

class _AddMilkPageState extends State<AddMilkPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _milkingDate;
  String? _milkType;
  String? _totalProduced;
  String? _totalUsed;
  String? _notes;

  final List<String> _milkTypes = ['- Select milk type -', 'Whole Farm Milk', 'Individual Goat Milk'];

  @override
  void initState() {
    super.initState();
    _milkingDate = widget.initialDate;
    _milkType = widget.initialMilkType ?? '- Select milk type -';
    _totalProduced = widget.initialTotalProduced;
    _totalUsed = widget.initialTotalUsed ?? '0';
    _notes = widget.initialNotes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEdit ? 'Edit Milk' : 'New Milk',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_box, color: Colors.white),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState?.save();
                Navigator.of(context).pop({
                  'date': _milkingDate ?? DateTime.now(),
                  'milkType': _milkType ?? '- Select milk type -',
                  'total': _totalProduced ?? '0',
                  'used': _totalUsed ?? '0',
                  'notes': _notes ?? '',
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Milking date . *',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _milkingDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _milkingDate = picked);
                  }
                },
                validator: (value) => _milkingDate == null ? 'Please select a date' : null,
                controller: TextEditingController(
                  text: _milkingDate == null ? '' : _milkingDate!.toLocal().toString().split(' ')[0],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _milkType,
                decoration: InputDecoration(
                 border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 13, 13, 13), width: 2),
                  ),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                items: _milkTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type,
                    style: TextStyle(
                      color: type == '- Select milk type -' ? Colors.orange : Colors.black,
                      fontWeight: type == '- Select milk type -' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _milkType = value),
                validator: (value) => value == null || value == '- Select milk type -' ? 'Please select milk type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _totalProduced,
                decoration: const InputDecoration(
                  labelText: 'Total milk produced . *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter total produced' : null,
                onSaved: (value) => setState(() => _totalProduced = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _totalUsed ?? '0',
                decoration: const InputDecoration(
                  labelText: 'Total used (Kids/consumption) . *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter total used' : null,
                onSaved: (value) => setState(() => _totalUsed = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(
                  labelText: 'Write some notes ...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) => setState(() => _notes = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
