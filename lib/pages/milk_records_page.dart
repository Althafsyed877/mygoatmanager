import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'add_milk_page.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';

class MilkRecord {
  final DateTime date;
  final String milkType;
  final int total;
  final int used;
  final String? notes;
  MilkRecord({required this.date, required this.milkType, required this.total, required this.used, this.notes});

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
}

class MilkRecordsPage extends StatefulWidget {
  const MilkRecordsPage({super.key});

  @override
  State<MilkRecordsPage> createState() => _MilkRecordsPageState();
}

class _MilkRecordsPageState extends State<MilkRecordsPage> {
  final List<MilkRecord> _records = [];
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _filterMilkType;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

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
      filtered = filtered.where((r) =>
        !r.date.isBefore(_filterStartDate!) && !r.date.isAfter(_filterEndDate!)
      ).toList();
    }
    // Apply milk type filter if set
    if (_filterMilkType != null && _filterMilkType!.isNotEmpty) {
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
        r.date.toIso8601String().contains(q)
      ).toList();
    }
    return filtered;
  }

  Future<void> _showMilkTypeFilterDialog() async {
    final loc = AppLocalizations.of(context)!;
    // Show fixed radio options as in the screenshot: All Types, Whole Farm, Individual Goat
    String? tmp = _filterMilkType;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Text(loc.milkType),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String?>(
                  title: Text(loc.allTypes),
                  value: null,
                  groupValue: tmp,
                  onChanged: (v) => setStateDialog(() => tmp = v),
                ),
                RadioListTile<String?>(
                  title: Text(loc.wholeFarm),
                  value: loc.wholeFarm,
                  groupValue: tmp,
                  onChanged: (v) => setStateDialog(() => tmp = v),
                ),
                RadioListTile<String?>(
                  title: Text(loc.individualGoat),
                  value: loc.individualGoat,
                  groupValue: tmp,
                  onChanged: (v) => setStateDialog(() => tmp = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(), 
                child: Text(loc.cancel)
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    // treat null as All Types (no filter)
                    _filterMilkType = tmp;
                  });
                  Navigator.of(ctx).pop();
                },
                child: Text(loc.apply),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _exportMilkRecordsPdf() async {
    final loc = AppLocalizations.of(context)!;
    final pdf = pw.Document();
    final records = _filteredRecords();

    // Try to load the milk image asset; if not available, continue without image
    pw.Widget? headerImage;
    try {
      final data = await rootBundle.load('assets/images/milk.png');
      final bytes = data.buffer.asUint8List();
      final img = pw.MemoryImage(bytes);
      headerImage = pw.Center(child: pw.Image(img, width: 140, height: 140));
    } catch (e) {
      headerImage = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final List<pw.Widget> items = [];
          // add centered milk image if available
          if (headerImage != null) {
            items.add(headerImage);
            items.add(pw.SizedBox(height: 8));
          }

          // Title and generated timestamp with improved styling
          items.add(pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(loc.milkRecords, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ));
          items.add(pw.SizedBox(height: 6));
          items.add(pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text('${loc.generated}: ${DateTime.now().toLocal()}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ));
          items.add(pw.SizedBox(height: 12));

          if (records.isEmpty) {
            items.add(pw.Center(child: pw.Text(loc.noRecordsToExport, style: pw.TextStyle(fontSize: 12))));
          } else {
            // Wrap table with a light border and padding
            items.add(
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.8)),
                padding: const pw.EdgeInsets.all(6),
                child: pw.TableHelper.fromTextArray(
                  headers: [loc.date, loc.milkType, loc.total, loc.used, loc.available, loc.notes],
                  data: records.map((r) {
                    final available = (r.total - r.used).toString();
                    final dateStr = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
                    return [dateStr, r.milkType, r.total.toString(), r.used.toString(), available, r.notes ?? ''];
                  }).toList(),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.center,
                    5: pw.Alignment.centerLeft,
                  },
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(3),
                  },
                ),
              ),
            );
          }

          return items;
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes, 
      filename: '${loc.milkRecords.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().toIso8601String()}.pdf'
    );
  }

  String get _appBarTitle {
    final loc = AppLocalizations.of(context)!;
    
    if (_filterStartDate != null && _filterEndDate != null) {
      return '${loc.milkRecords} (${_filterStartDate!.year}-${_filterStartDate!.month.toString().padLeft(2, '0')}-${_filterStartDate!.day.toString().padLeft(2, '0')} ${loc.to} '
        '${_filterEndDate!.year}-${_filterEndDate!.month.toString().padLeft(2, '0')}-${_filterEndDate!.day.toString().padLeft(2, '0')})';
    }
    return loc.milkRecords;
  }

  Future<void> _showFilterDialog() async {
    final loc = AppLocalizations.of(context)!;
    DateTime? tempStart = _filterStartDate;
    DateTime? tempEnd = _filterEndDate;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.filterByDateRange),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(tempStart == null
                    ? loc.startDate
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
                    setState(() {
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
                    ? loc.endDate
                    : '${tempEnd!.year}-${tempEnd!.month.toString().padLeft(2, '0')}-${tempEnd!.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempEnd ?? (tempStart ?? DateTime.now()),
                    firstDate: tempStart ?? DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
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
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterStartDate = tempStart;
                  _filterEndDate = tempEnd;
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.apply),
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
                child: Text(loc.clear),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
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
                decoration: InputDecoration(
                  hintText: loc.searchHint,
                  hintStyle: const TextStyle(color: Colors.white54),
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
            onSelected: (value) async {
              if (value == 'period') {
                await _showFilterDialog();
              } else if (value == 'milk_type') {
                await _showMilkTypeFilterDialog();
              } else if (value == 'export_pdf') {
                await _exportMilkRecordsPdf();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'period',
                child: Text(loc.filterByPeriod),
              ),
              PopupMenuItem(
                value: 'milk_type',
                child: Text(loc.filterByMilkType),
              ),
              PopupMenuItem(
                value: 'export_pdf',
                child: Text(loc.exportPdf),
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
      body: _filteredRecords().isEmpty
          ? Center(
              child: Text(
                loc.noMilkRecordsDisplay,
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredRecords().length,
              itemBuilder: (context, index) {
                final record = _filteredRecords()[index];
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
                                  Text('${loc.farm} (1)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                  Text(loc.total),
                                  const SizedBox(width: 24),
                                  Text('${record.used}', style: const TextStyle(color: Colors.orange, fontSize: 20)),
                                  const SizedBox(width: 4),
                                  Text(loc.used),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('$available', style: const TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
                              if (record.notes != null && record.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('${loc.notes}: ${record.notes!}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
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
                                  // Find the index in the original list
                                  final origIndex = _records.indexWhere((r) =>
                                    r.date == record.date &&
                                    r.milkType == record.milkType &&
                                    r.total == record.total &&
                                    r.used == record.used &&
                                    r.notes == record.notes);
                                  if (origIndex != -1) {
                                    _records[origIndex] = MilkRecord(
                                      date: editResult['date'] as DateTime,
                                      milkType: editResult['milkType'] as String? ?? loc.selectMilkType,
                                      total: int.tryParse(editResult['total']?.toString() ?? '0') ?? 0,
                                      used: int.tryParse(editResult['used']?.toString() ?? '0') ?? 0,
                                      notes: editResult['notes'] as String?,
                                    );
                                  }
                                });
                                await _saveRecords();
                              }
                            } else if (value == 'delete') {
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(loc.deleteRecord),
                                  content: Text(loc.deleteRecordConfirmation),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: Text(loc.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: Text(loc.delete),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmDelete == true && mounted) {
                                setState(() {
                                  // Find the index in the original list
                                  final origIndex = _records.indexWhere((r) =>
                                    r.date == record.date &&
                                    r.milkType == record.milkType &&
                                    r.total == record.total &&
                                    r.used == record.used &&
                                    r.notes == record.notes);
                                  if (origIndex != -1) {
                                    _records.removeAt(origIndex);
                                  }
                                });
                                await _saveRecords();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(loc.recordDeleted))
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(loc.editViewRecord),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(loc.delete),
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
                  milkType: result['milkType'] as String? ?? loc.selectMilkType,
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
        label: Text(
          loc.add,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MilkTypeRadioGroup extends StatefulWidget {
  final List<String> milkTypes;
  final String? selectedType;
  final ValueChanged<String?> onSelected;
  const _MilkTypeRadioGroup({required this.milkTypes, required this.selectedType, required this.onSelected});

  @override
  State<_MilkTypeRadioGroup> createState() => _MilkTypeRadioGroupState();
}

class _MilkTypeRadioGroupState extends State<_MilkTypeRadioGroup> {
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioListTile<String?>(
          title: Text(loc.all),
          value: null,
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
            widget.onSelected(value);
          },
        ),
        ...widget.milkTypes.map((type) => RadioListTile<String?>(
          title: Text(type),
          value: type,
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
            widget.onSelected(value);
          },
        )),
      ],
    );
  }
}