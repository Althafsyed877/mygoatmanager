import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pages/add_milk_page.dart';

class MilkRecord {
  final DateTime date;
  final String milkType;
  final int total;
  final int used;
  final String? notes;
  
  MilkRecord({
    required this.date, 
    required this.milkType, 
    required this.total, 
    required this.used, 
    this.notes
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'milkType': milkType,
    'total': total,
    'used': used,
    'notes': notes,
  };

  factory MilkRecord.fromJson(Map<String, dynamic> json) => MilkRecord(
    date: DateTime.parse(json['date'] as String),
    milkType: json['milkType'] as String? ?? '- Select milk type -',
    total: json['total'] as int,
    used: json['used'] as int,
    notes: json['notes'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilkRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          milkType == other.milkType &&
          total == other.total &&
          used == other.used &&
          notes == other.notes;

  @override
  int get hashCode =>
      date.hashCode ^
      milkType.hashCode ^
      total.hashCode ^
      used.hashCode ^
      notes.hashCode;
}

class MilkRecordsPage extends StatefulWidget {
  const MilkRecordsPage({super.key});

  @override
  State<MilkRecordsPage> createState() => _MilkRecordsPageState();
}

class _MilkRecordsPageState extends State<MilkRecordsPage> {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterMilkType;
  final List<MilkRecord> _records = [];
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('milk_records');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        _records.clear();
        _records.addAll(jsonList.map((e) => MilkRecord.fromJson(e as Map<String, dynamic>)));
      });
    }
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _records.map((e) => e.toJson()).toList();
    await prefs.setString('milk_records', jsonEncode(jsonList));
  }

  List<MilkRecord> _filteredRecords() {
    List<MilkRecord> filtered = _records;
    
    // Apply date filter if set
    if (_filterStartDate != null && _filterEndDate != null) {
      final startDate = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
      final endDate = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day).add(const Duration(days: 1));
      
      filtered = filtered.where((r) {
        final recordDate = DateTime(r.date.year, r.date.month, r.date.day);
        return !recordDate.isBefore(startDate) && recordDate.isBefore(endDate);
      }).toList();
    }
    
    // Apply milk type filter if set
    if (_filterMilkType != null) {
      filtered = filtered.where((r) => r.milkType == _filterMilkType).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) =>
        r.milkType.toLowerCase().contains(q) ||
        r.total.toString().contains(q) ||
        r.used.toString().contains(q) ||
        (r.notes ?? '').toLowerCase().contains(q) ||
        '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}'.contains(q)
      ).toList();
    }
    
    return filtered;
  }

  Future<void> _showMilkTypeFilterDialog() async {
    // Collect unique milk types from records
    final milkTypes = _records.map((r) => r.milkType).where((type) => type.isNotEmpty).toSet().toList();
    
    if (milkTypes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No milk types available for filtering')),
      );
      return;
    }

    String? tempSelectedType = _filterMilkType;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter by Milk Type'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed RadioListTile syntax for newer Flutter versions
                    RadioListTile<String?>(
                      title: const Text('All'),
                      value: null,
                      groupValue: tempSelectedType,
                      onChanged: (String? value) {
                        setDialogState(() {
                          tempSelectedType = value;
                        });
                      },
                    ),
                    ...milkTypes.map((type) => RadioListTile<String?>(
                      title: Text(type),
                      value: type,
                      groupValue: tempSelectedType,
                      onChanged: (String? value) {
                        setDialogState(() {
                          tempSelectedType = value;
                        });
                      },
                    )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterMilkType = null;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Clear'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterMilkType = tempSelectedType;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  String get _appBarTitle {
    if (_filterStartDate != null && _filterEndDate != null) {
      return 'Milk Records (${_filterStartDate!.year}-${_filterStartDate!.month.toString().padLeft(2, '0')}-${_filterStartDate!.day.toString().padLeft(2, '0')} to '
          '${_filterEndDate!.year}-${_filterEndDate!.month.toString().padLeft(2, '0')}-${_filterEndDate!.day.toString().padLeft(2, '0')})';
    } else if (_filterMilkType != null) {
      return 'Milk Records ($_filterMilkType)';
    } else if (_searchQuery.isNotEmpty) {
      return 'Milk Records (Search: "$_searchQuery")';
    }
    return 'Milk Records';
  }

  Future<void> _showFilterDialog() async {
    DateTime? tempStart = _filterStartDate;
    DateTime? tempEnd = _filterEndDate;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Date Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(tempStart == null
                        ? 'Start Date'
                        : '${tempStart!.year}-${tempStart!.month.toString().padLeft(2, '0')}-${tempStart!.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStart ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tempStart = picked;
                          // If end date is before start, reset end
                          if (tempEnd != null && tempEnd!.isBefore(picked)) {
                            tempEnd = null;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(tempEnd == null
                        ? 'End Date'
                        : '${tempEnd!.year}-${tempEnd!.month.toString().padLeft(2, '0')}-${tempEnd!.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final firstDate = tempStart ?? DateTime(2000);
                      final initialDate = tempEnd ?? (tempStart ?? DateTime.now());
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: firstDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tempEnd = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterStartDate = tempStart;
                      _filterEndDate = tempEnd;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
                if (_filterStartDate != null || _filterEndDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterStartDate = null;
                        _filterEndDate = null;
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _filteredRecords();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                cursorColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                _appBarTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) async {
              if (value == 'period') {
                await _showFilterDialog();
              } else if (value == 'milk_type') {
                await _showMilkTypeFilterDialog();
              } else if (value == 'export_pdf') {
                // Show export PDF dialog (placeholder)
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Export PDF'),
                    content: const Text('Export to PDF coming soon.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                );
              } else if (value == 'clear_filters') {
                setState(() {
                  _filterStartDate = null;
                  _filterEndDate = null;
                  _filterMilkType = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'period',
                child: Text('Filter by Period'),
              ),
              const PopupMenuItem<String>(
                value: 'milk_type',
                child: Text('Filter by Milk Type'),
              ),
              const PopupMenuItem<String>(
                value: 'export_pdf',
                child: Text('Export PDF'),
              ),
              if (_filterStartDate != null || _filterEndDate != null || _filterMilkType != null || _searchQuery.isNotEmpty)
                const PopupMenuItem<String>(
                  value: 'clear_filters',
                  child: Text('Clear All Filters'),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA726),
            ),
          ),
        ),
      ),
      body: filteredRecords.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _records.isEmpty
                      ? 'No milk records found. Tap the + button to add your first record.'
                      : 'No milk records match your current filters or search query.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredRecords.length,
              itemBuilder: (context, index) {
                final record = filteredRecords[index];
                final available = record.total - record.used;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Farm (1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.green, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(record.milkType, style: const TextStyle(color: Colors.black87, fontSize: 16)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('${record.total}', style: const TextStyle(color: Colors.green, fontSize: 20)),
                                  const SizedBox(width: 4),
                                  const Text('Total'),
                                  const SizedBox(width: 24),
                                  Text('${record.used}', style: const TextStyle(color: Colors.orange, fontSize: 20)),
                                  const SizedBox(width: 4),
                                  const Text('Used'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('$available', style: const TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
                              if (record.notes != null && record.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Notes: ${record.notes!}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String value) async {
                            if (value == 'edit') {
                              final editResult = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddMilkPage(
                                    initialDate: record.date,
                                    initialMilkType: record.milkType,
                                    initialTotalProduced: record.total.toString(),
                                    initialTotalUsed: record.used.toString(),
                                    initialNotes: record.notes,
                                    isEdit: true,
                                  ),
                                ),
                              );
                              if (editResult != null && editResult is Map<String, dynamic>) {
                                setState(() {
                                  final index = _records.indexOf(record);
                                  if (index != -1) {
                                    _records[index] = MilkRecord(
                                      date: editResult['date'] as DateTime,
                                      milkType: editResult['milkType'] as String,
                                      total: int.tryParse(editResult['total']?.toString() ?? '0') ?? 0,
                                      used: int.tryParse(editResult['used']?.toString() ?? '0') ?? 0,
                                      notes: editResult['notes'] as String?,
                                    );
                                  }
                                });
                                await _saveRecords();
                              }
                            } else if (value == 'delete') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Record'),
                                  content: const Text('Are you sure you want to delete this milk record?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmed == true) {
                                setState(() {
                                  _records.remove(record);
                                });
                                await _saveRecords();
                              }
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit/View Record'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMilkPage()),
          );
          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              _records.add(
                MilkRecord(
                  date: result['date'] as DateTime,
                  milkType: result['milkType'] as String,
                  total: int.tryParse(result['total']?.toString() ?? '0') ?? 0,
                  used: int.tryParse(result['used']?.toString() ?? '0') ?? 0,
                  notes: result['notes'] as String?,
                ),
              );
            });
            await _saveRecords();
          }
        },
        backgroundColor: const Color(0xFFFFA726),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}