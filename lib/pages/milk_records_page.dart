// lib/pages/milk_records_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'add_milk_page.dart';
import '../l10n/app_localizations.dart';
import '../models/milk_record.dart'; // Import the model

class MilkRecordsPage extends StatefulWidget {
  const MilkRecordsPage({super.key});

  @override
  State<MilkRecordsPage> createState() => _MilkRecordsPageState();
}

class _MilkRecordsPageState extends State<MilkRecordsPage> {
  List<MilkRecord> _records = [];
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
        _records = jsonList.map((e) => MilkRecord.fromJson(e as Map<String, dynamic>)).toList();
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
        !r.milkingDate.isBefore(_filterStartDate!) && !r.milkingDate.isAfter(_filterEndDate!)
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
        (r.notes ?? '').toLowerCase().contains(q) ||
        r.milkingDate.toIso8601String().contains(q)
      ).toList();
    }
    
    return filtered;
  }

  Future<void> _showMilkTypeFilterDialog() async {
    final loc = AppLocalizations.of(context)!;
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
                  title: Text('Whole Farm Milk'),
                  value: 'Whole Farm Milk',
                  groupValue: tmp,
                  onChanged: (v) => setStateDialog(() => tmp = v),
                ),
                RadioListTile<String?>(
                  title: Text('Individual Goat Milk'),
                  value: 'Individual Goat Milk',
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

    // Try to load the milk image asset
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
          
          if (headerImage != null) {
            items.add(headerImage);
            items.add(pw.SizedBox(height: 8));
          }

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
            items.add(
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.8)),
                padding: const pw.EdgeInsets.all(6),
                child: pw.TableHelper.fromTextArray(
                  headers: [loc.date, loc.milkType, 'Morning', 'Evening', loc.total, loc.available, loc.notes],
                  data: records.map((r) {
                    final dateStr = r.formattedDate;
                    return [
                      dateStr,
                      r.milkType,
                      r.morningQuantity.toStringAsFixed(2),
                      r.eveningQuantity.toStringAsFixed(2),
                      r.total.toStringAsFixed(2),
                      r.available.toStringAsFixed(2),
                      r.notes ?? ''
                    ];
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
                    5: pw.Alignment.center,
                    6: pw.Alignment.centerLeft,
                  },
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1),
                    6: const pw.FlexColumnWidth(3),
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
                final available = record.available;
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
                                  Text(
                                    record.milkType,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    record.formattedDate,
                                    style: const TextStyle(color: Colors.green, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('${record.morningQuantity.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontSize: 16)),
                                            const SizedBox(width: 4),
                                            Text('Morning'),
                                            const SizedBox(width: 12),
                                            Text('${record.eveningQuantity.toStringAsFixed(2)}', style: const TextStyle(color: Colors.purple, fontSize: 16)),
                                            const SizedBox(width: 4),
                                            Text('Evening'),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('${record.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 18)),
                                            const SizedBox(width: 4),
                                            Text('Produced'),
                                            const SizedBox(width: 16),
                                            Text('${record.used.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontSize: 18)),
                                            const SizedBox(width: 4),
                                            Text('Used'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('${record.available.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontSize: 18)),
                                  const SizedBox(width: 4),
                                  Text('Remaining'),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                                  builder: (context) => AddMilkPage(existingRecord: record),
                                ),
                              );
                              if (editResult != null && editResult is MilkRecord) {
                                setState(() {
                                  // Find and replace the existing record
                                  final index = _records.indexWhere((r) => 
                                    r.milkingDate == record.milkingDate);
                                  if (index != -1) {
                                    _records[index] = editResult;
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
                                  _records.removeWhere((r) => 
                                    r.milkingDate == record.milkingDate);
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
            MaterialPageRoute(
              builder: (context) => const AddMilkPage(),
            ),
          );
          if (result != null && result is MilkRecord) {
            setState(() {
              _records.add(result);
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