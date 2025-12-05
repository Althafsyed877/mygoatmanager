import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  int _selectedTab = 0; // 0 for Income, 1 for Expenses
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _expenses = [];
  final List<Map<String, dynamic>> _incomes = [];
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  String _selectedDateRangeFilter = 'Current Month';
  String? _selectedIncomeTypeFilter;
  String? _selectedExpenseTypeFilter;

  String _formatDateDisplay(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    DateTime dt;
    try {
      dt = DateTime.parse(iso);
    } catch (_) {
      try {
        dt = DateTime.parse(iso.split(' ').first);
      } catch (_) {
        return iso;
      }
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = months[dt.month - 1];
    return '$m ${dt.day}, ${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final incomesStr = prefs.getString('saved_incomes');
    final expensesStr = prefs.getString('saved_expenses');
    if (incomesStr != null) {
      try {
        final List<dynamic> js = jsonDecode(incomesStr);
        _incomes.clear();
        _incomes.addAll(js.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    if (expensesStr != null) {
      try {
        final List<dynamic> js = jsonDecode(expensesStr);
        _expenses.clear();
        _expenses.addAll(js.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    setState(() {});
  }

  Future<void> _saveIncomes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_incomes', jsonEncode(_incomes));
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_expenses', jsonEncode(_expenses));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Transactions'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by description, amount...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _searchController.clear();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    String selectedDateRange = _selectedDateRangeFilter;
    DateTime? fromDate = _filterFromDate;
    DateTime? toDate = _filterToDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter by Date'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Range Chips
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildDateChip('Today', 'Today', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = now;
                          toDate = now;
                        }),
                        _buildDateChip('Yesterday', 'Yesterday', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = now.subtract(const Duration(days: 1));
                          toDate = now.subtract(const Duration(days: 1));
                        }),
                        _buildDateChip('Last Week', 'Last Week', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = now.subtract(const Duration(days: 7));
                          toDate = now;
                        }),
                        _buildDateChip('Current Month', 'Current Month', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = DateTime(now.year, now.month, 1);
                          toDate = DateTime(now.year, now.month + 1, 0);
                        }),
                        _buildDateChip('Last Month', 'Last Month', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = DateTime(now.year, now.month - 1, 1);
                          toDate = DateTime(now.year, now.month, 0);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Custom Date Range
                    const Text(
                      'Custom Date Range',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('From:'),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: fromDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null && picked != fromDate) {
                                    setState(() {
                                      fromDate = picked;
                                      selectedDateRange = 'Custom Range';
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    fromDate != null 
                                        ? '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}'
                                        : 'Select Date',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To:'),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: toDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null && picked != toDate) {
                                    setState(() {
                                      toDate = picked;
                                      selectedDateRange = 'Custom Range';
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    toDate != null 
                                        ? '${toDate!.day}/${toDate!.month}/${toDate!.year}'
                                        : 'Select Date',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedDateRange = 'Current Month';
                      fromDate = null;
                      toDate = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply filter with selectedDateRange, fromDate, toDate
                    setState(() {
                      _selectedDateRangeFilter = selectedDateRange;
                      _filterFromDate = fromDate;
                      _filterToDate = toDate;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateChip(String label, String value, String selectedDateRange, StateSetter setState, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedDateRange == value,
      onSelected: (selected) {
        setState(() {
          selectedDateRange = value;
        });
        onSelected();
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFFFA726),
      labelStyle: TextStyle(
        color: selectedDateRange == value ? Colors.white : Colors.black,
      ),
    );
  }

  void _showMoreOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedTab == 0) // Income tab
                ..._buildIncomeMoreOptions()
              else // Expenses tab
                ..._buildExpensesMoreOptions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilteredListView() {
    final source = _selectedTab == 0 ? _incomes : _expenses;
    final DateTime? from = _filterFromDate;
    final DateTime? to = _filterToDate;
    final DateTime? fromMidnight = from != null ? DateTime(from.year, from.month, from.day) : null;
    final DateTime? toEOD = to != null ? DateTime(to.year, to.month, to.day, 23, 59, 59) : null;

    // Filter by date range and type
    List<Map<String, dynamic>> filtered = source.where((e) {
      // Date filtering with optimized comparison
      final dateStr = e['date']?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          final d = DateTime.parse(dateStr);
          if (fromMidnight != null && d.isBefore(fromMidnight)) return false;
          if (toEOD != null && d.isAfter(toEOD)) return false;
        } catch (_) {
          return false;
        }
      }

      // Type filtering
      if (_selectedTab == 0 && _selectedIncomeTypeFilter != null) {
        final itemType = e['type']?.toString() ?? '';
        if (itemType != _selectedIncomeTypeFilter) return false;
      } else if (_selectedTab == 1 && _selectedExpenseTypeFilter != null) {
        final itemType = e['type']?.toString() ?? '';
        if (itemType != _selectedExpenseTypeFilter) return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt, color: Color(0xFF9E9E9E), size: 48),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 0
                ? 'There is no income to display\nfor the selected date range.'
                : 'There are no expenses to display\nfor the selected date range.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, idx) {
        final e = filtered[idx];
        final origIndex = source.indexOf(e);
        final amount = double.tryParse((e['amount'] ?? '0').toString()) ?? 0.0;
        final displayTitle = (e['type'] ?? (_selectedTab == 0 ? 'Income' : 'Expense')) +
            ((e['quantity'] ?? '') != '' ? ' (${e['quantity']})' : '');
        final dateDisplay = _formatDateDisplay(e['date']?.toString());

        return Card(
          color: Colors.white,
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? Colors.green : Colors.orange,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(dateDisplay, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${amount.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _selectedTab == 0 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                  Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (val) async {
                      if (val == 'delete') {
                        setState(() {
                          if (_selectedTab == 0) {
                            _incomes.removeAt(origIndex);
                          } else {
                            _expenses.removeAt(origIndex);
                          }
                        });
                        if (_selectedTab == 0) await _saveIncomes(); else await _saveExpenses();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted')));
                      } else if (val == 'edit') {
                        if (_selectedTab == 0) {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => NewIncomePage(initialData: e)));
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() => _incomes[origIndex] = result);
                            await _saveIncomes();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Income updated')));
                          }
                        } else {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => NewExpensePage(initialData: e)));
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() => _expenses[origIndex] = result);
                            await _saveExpenses();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense updated')));
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit / View record')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildIncomeMoreOptions() {
    return [
      ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: const Text('Export Pdf'),
        onTap: () async {
          Navigator.pop(context);
          await _exportIncomePdf();
        },
      ),
      ListTile(
        leading: const Icon(Icons.category, color: Colors.blue),
        title: const Text('Income type'),
        onTap: () {
          Navigator.pop(context);
          _showIncomeTypeFilter();
        },
      ),
    ];
  }

  List<Widget> _buildExpensesMoreOptions() {
    return [
      ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: const Text('Export Pdf'),
        onTap: () async {
          Navigator.pop(context);
          await _exportExpensePdf();
        },
      ),
      ListTile(
        leading: const Icon(Icons.category, color: Colors.blue),
        title: const Text('Expense type'),
        onTap: () {
          Navigator.pop(context);
          _showExpenseTypeFilter();
        },
      ),
    ];
  }

  void _showIncomeTypeFilter() {
    final types = ['All Types', 'Milk Sale', 'Goat Sale', 'Category Income', 'Other (specify)'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Income Type'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            itemCount: types.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = (type == 'All Types' && _selectedIncomeTypeFilter == null) ||
                  _selectedIncomeTypeFilter == type;
              return ListTile(
                title: Text(type),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    _selectedIncomeTypeFilter = type == 'All Types' ? null : type;
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showExpenseTypeFilter() {
    final types = ['All Types', 'Category', 'Other'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Expense Type'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            itemCount: types.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = (type == 'All Types' && _selectedExpenseTypeFilter == null) ||
                  _selectedExpenseTypeFilter == type;
              return ListTile(
                title: Text(type),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.orange) : null,
                onTap: () {
                  setState(() {
                    _selectedExpenseTypeFilter = type == 'All Types' ? null : type;
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _exportIncomePdf() async {
    final pdf = pw.Document();
    final items = List<Map<String, dynamic>>.from(_incomes);
    pw.Widget? headerImage;
    try {
      final data = await rootBundle.load('assets/images/goat.png');
      final bytes = data.buffer.asUint8List();
      final img = pw.MemoryImage(bytes);
      headerImage = pw.Center(child: pw.Image(img, width: 80, height: 80));
    } catch (e) {
      headerImage = null;
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final List<pw.Widget> children = [];
          if (headerImage != null) {
            children.add(headerImage);
            children.add(pw.SizedBox(height: 8));
          }
          children.add(pw.Center(child: pw.Text('Income Records', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))));
          children.add(pw.SizedBox(height: 6));
          children.add(pw.Text('Generated: ${DateTime.now().toLocal()}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)));
          children.add(pw.SizedBox(height: 12));

          if (items.isEmpty) {
            children.add(pw.Center(child: pw.Text('No income records to export.')));
          } else {
            children.add(
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.8)),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Table.fromTextArray(
                    headers: ['Date', 'Source', 'Qty', 'Price', 'Total', 'Notes'],
                    data: items.map((e) {
                      final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime.now();
                      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final qty = e['quantity']?.toString() ?? '';
                      final priceRaw = e['price']?.toString() ?? '';
                      final amountRaw = e['amount']?.toString() ?? '';
                      double? price = double.tryParse(priceRaw);
                      double? qtyNum = double.tryParse(qty);
                      double? amount = double.tryParse(amountRaw);
                      String priceStr = price != null ? price.toStringAsFixed(2) : (priceRaw.isNotEmpty ? priceRaw : '');
                      String totalStr;
                      if (amount != null) {
                        totalStr = amount.toStringAsFixed(2);
                      } else if (price != null && qtyNum != null) {
                        totalStr = (price * qtyNum).toStringAsFixed(2);
                      } else {
                        totalStr = amountRaw.isNotEmpty ? amountRaw : '';
                      }
                      return [dateStr, e['type'] ?? '', qty, priceStr, totalStr, e['notes'] ?? ''];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
                    cellStyle: pw.TextStyle(fontSize: 10),
                    cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  ),
                ),
              );
          }

          return children;
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'income_${DateTime.now().toIso8601String()}.pdf');
  }

  Future<void> _exportExpensePdf() async {
    final pdf = pw.Document();
    final items = List<Map<String, dynamic>>.from(_expenses);
    pw.Widget? headerImage;
    try {
      final data = await rootBundle.load('assets/images/goat.png');
      final bytes = data.buffer.asUint8List();
      final img = pw.MemoryImage(bytes);
      headerImage = pw.Center(child: pw.Image(img, width: 80, height: 80));
    } catch (e) {
      headerImage = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final List<pw.Widget> children = [];
          if (headerImage != null) {
            children.add(headerImage);
            children.add(pw.SizedBox(height: 8));
          }
          children.add(pw.Center(child: pw.Text('Expense Records', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))));
          children.add(pw.SizedBox(height: 6));
          children.add(pw.Text('Generated: ${DateTime.now().toLocal()}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)));
          children.add(pw.SizedBox(height: 12));

          if (items.isEmpty) {
            children.add(pw.Center(child: pw.Text('No expense records to export.')));
          } else {
            children.add(
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.8)),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Table.fromTextArray(
                  headers: ['Date', 'Name', 'Amount', 'Notes'],
                  data: items.map((e) {
                    final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime.now();
                    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final name = e['type'] ?? (e['category'] ?? '');
                    return [dateStr, name, e['amount']?.toString() ?? '', e['notes'] ?? ''];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                ),
              ),
            );
          }

          return children;
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'expense_${DateTime.now().toIso8601String()}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
        ),
            title: const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showSearchDialog,
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: _showFilterDialog,
                icon: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: _showMoreOptionsMenu,
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
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
      body: SafeArea(
        child: Column(
          children: [
            // Income/Expenses Tabs - DIRECTLY BELOW APP BAR
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 
                            ? const Color(0xFFFFA726) 
                            : Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Income',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _selectedTab == 0 ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 
                            ? const Color(0xFFFFA726) 
                            : Colors.white,
                      ),
                      child: Text(
                        'Expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _selectedTab == 1 ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 16.0),
                child: Column(
                  children: [
                    // Content
                    Expanded(
                      child: _buildFilteredListView(),
                    ),

                    // Add Button
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => _selectedTab == 0
                                      ? NewIncomePage()
                                      : NewExpensePage(),
                                ),
                              );
                              if (result != null && result is Map<String, dynamic>) {
                                if (result['kind'] == 'income') {
                                  setState(() => _incomes.add(result));
                                  await _saveIncomes();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Income saved')));
                                } else {
                                  setState(() => _expenses.add(result));
                                  await _saveExpenses();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense saved')));
                                }
                              }
                            }();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA726),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTab == 0 ? 'Income' : 'Expense',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewIncomePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  NewIncomePage({super.key, this.initialData});

  @override
  State<NewIncomePage> createState() => _NewIncomePageState();
}

class _NewIncomePageState extends State<NewIncomePage> {
  DateTime? _incomeDate;
  String? _selectedIncomeType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _receiptController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _otherSourceController = TextEditingController();

  final List<String> _incomeTypes = [
    'Milk Sale',
    'Goat Sale',
    'Category Income',
    'Other (specify)',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _otherSourceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      if (data['date'] != null) {
        try {
          _incomeDate = DateTime.parse(data['date']);
        } catch (_) {}
      }
      final t = data['type']?.toString();
      if (t != null && _incomeTypes.contains(t)) {
        _selectedIncomeType = t;
      } else if (t != null) {
        _selectedIncomeType = 'Other (specify)';
        _otherSourceController.text = t;
      }
      _quantityController.text = data['quantity']?.toString() ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _amountController.text = data['amount']?.toString() ?? '';
      _receiptController.text = data['receipt']?.toString() ?? '';
      _notesController.text = data['notes']?.toString() ?? '';
    }
  }

  Widget _buildIncomeTypeForm() {
    switch (_selectedIncomeType) {
      case 'Milk Sale':
        return _buildMilkSaleForm();
      case 'Goat Sale':
        return _buildGoatSaleForm();
      case 'Category Income':
        return _buildCategoryIncomeForm();
      case 'Other (specify)':
        return _buildOtherIncomeForm();
      default:
        return Container();
    }
  }

  Widget _buildMilkSaleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Milk quantity sold .*',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          decoration: InputDecoration(
            hintText: 'Enter milk quantity',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        const Text(
          'Selling price per litre/unit. *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          decoration: InputDecoration(
            hintText: 'Enter price per litre',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            if (_quantityController.text.isNotEmpty && value.isNotEmpty) {
              final quantity = double.tryParse(_quantityController.text) ?? 0;
              final price = double.tryParse(value) ?? 0;
              final total = quantity * price;
              _amountController.text = total.toStringAsFixed(2);
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'How much did you earn? *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildGoatSaleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Text(
            'Please go to the record of the goat sold and archive it with a reason \'Sold\' and an income record will be created automatically!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'How much did you earn? *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildCategoryIncomeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Quantity of items. *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          decoration: InputDecoration(
            hintText: '1',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        const Text(
          'How much did you earn? *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildOtherIncomeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Please specify the source of income.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otherSourceController,
          decoration: InputDecoration(
            hintText: 'Specify income source',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'How much did you earn? *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Income'),
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              if (_incomeDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a date')),
                );
                return;
              }
              if (_selectedIncomeType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select income type')),
                );
                return;
              }
              if (_amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter amount')),
                );
                return;
              }
              if (_selectedIncomeType == 'Milk Sale' && 
                  (_quantityController.text.isEmpty || _priceController.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter quantity and price')),
                );
                return;
              }
              if (_selectedIncomeType == 'Category Income' && _quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter quantity')),
                );
                return;
              }
              if (_selectedIncomeType == 'Other (specify)' && _otherSourceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please specify income source')),
                );
                return;
              }

              final typeValue = _selectedIncomeType == 'Other (specify)'
                  ? _otherSourceController.text.trim()
                  : _selectedIncomeType;

              final income = <String, dynamic>{
                'kind': 'income',
                'date': _incomeDate!.toIso8601String(),
                'type': typeValue,
                'quantity': _selectedIncomeType == 'Milk Sale' || _selectedIncomeType == 'Category Income' ? _quantityController.text.trim() : null,
                'price': _selectedIncomeType == 'Milk Sale' ? _priceController.text.trim() : null,
                'amount': _amountController.text.trim(),
                'receipt': _receiptController.text.trim(),
                'notes': _notesController.text.trim(),
              };

              Navigator.pop(context, income);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date of Income
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _incomeDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _incomeDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _incomeDate != null
                          ? '${_incomeDate!.day}/${_incomeDate!.month}/${_incomeDate!.year}'
                          : 'Date of Income . *',
                      style: TextStyle(
                        color: _incomeDate != null ? Colors.black87 : Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Select Income Type
          GestureDetector(
            onTap: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Select income type'),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 250,
                      child: ListView.separated(
                        itemCount: _incomeTypes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final type = _incomeTypes[index];
                          return ListTile(
                            title: Text(type),
                            onTap: () => Navigator.pop(ctx, type),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
              if (selected != null) {
                setState(() => _selectedIncomeType = selected);
                _quantityController.clear();
                _priceController.clear();
                _amountController.clear();
                _otherSourceController.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade700, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedIncomeType ?? '- Select income type -',
                      style: TextStyle(
                        color: _selectedIncomeType != null ? Colors.black87 : Colors.orange.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.orange),
                ],
              ),
            ),
          ),

          if (_selectedIncomeType != null) _buildIncomeTypeForm(),

          const SizedBox(height: 16),

          if (_selectedIncomeType != 'Goat Sale')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipt no. (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _receiptController,
                  decoration: InputDecoration(
                    hintText: 'Enter receipt number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          const Text(
            'Write some notes ...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Enter your notes here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class NewExpensePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  NewExpensePage({super.key, this.initialData});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage> {
  DateTime? _expenseDate;
  String? _selectedExpenseType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _receiptController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _otherExpenseController = TextEditingController();

  final List<String> _topExpenseOptions = [
    'Category Expense',
    'Other (specify)',
  ];

  // Example categories - you can replace these with persisted categories later
  final List<String> _expenseCategories = ['milk type'];
  String? _selectedCategory;

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _otherExpenseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      if (data['date'] != null) {
        try {
          _expenseDate = DateTime.parse(data['date']);
        } catch (_) {}
      }
      // If category exists, preselect Category Expense
      if (data['category'] != null) {
        _selectedExpenseType = 'Category Expense';
        _selectedCategory = data['category']?.toString();
        _quantityController.text = data['quantity']?.toString() ?? '';
      } else if (data['type'] != null) {
        _selectedExpenseType = 'Other (specify)';
        _otherExpenseController.text = data['type']?.toString() ?? '';
      }
      _amountController.text = data['amount']?.toString() ?? '';
      _receiptController.text = data['receipt']?.toString() ?? '';
      _notesController.text = data['notes']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Expense'),
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              if (_expenseDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a date')),
                );
                return;
              }
              if (_selectedExpenseType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select expense type')),
                );
                return;
              }
              if (_selectedExpenseType == 'Other (specify)' && _otherExpenseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter name of expense')),
                );
                return;
              }
              if (_selectedExpenseType == 'Category Expense' && _selectedCategory == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a category')),
                );
                return;
              }
              if (_selectedExpenseType == 'Category Expense' && _quantityController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter quantity')),
                );
                return;
              }
              if (_amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter amount')),
                );
                return;
              }

              final typeValue = _selectedExpenseType == 'Other (specify)'
                  ? _otherExpenseController.text.trim()
                  : (_selectedExpenseType == 'Category Expense'
                      ? (_selectedCategory ?? 'Category Expense')
                      : _selectedExpenseType);

              final expense = <String, dynamic>{
                'kind': 'expense',
                'date': _expenseDate!.toIso8601String(),
                'type': typeValue,
                'category': _selectedExpenseType == 'Category Expense' ? _selectedCategory : null,
                'quantity': _selectedExpenseType == 'Category Expense' ? _quantityController.text.trim() : null,
                'amount': _amountController.text.trim(),
                'receipt': _receiptController.text.trim(),
                'notes': _notesController.text.trim(),
              };
              Navigator.pop(context, expense);
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date of expense
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expenseDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _expenseDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _expenseDate != null
                          ? '${_expenseDate!.day}/${_expenseDate!.month}/${_expenseDate!.year}'
                          : 'Date of expense. *',
                      style: TextStyle(
                        color: _expenseDate != null ? Colors.black87 : Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Select Expense Type
          GestureDetector(
            onTap: () async {
              // First dialog: choose Category Expense or Other
              final topSelected = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Select expense type'),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 160,
                      child: ListView.separated(
                        itemCount: _topExpenseOptions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final opt = _topExpenseOptions[index];
                          return ListTile(
                            title: Text(opt == '- Select expense type -' ? opt : opt),
                            onTap: () => Navigator.pop(ctx, opt),
                          );
                        },
                      ),
                    ),
                  );
                },
              );

              if (topSelected == null) return;

              // If user picked the header, ignore
              if (topSelected == '- Select expense type -') return;

              if (topSelected == 'Category Expense') {
                // Set the selected type to Category Expense and show inline category selector
                setState(() {
                  _selectedExpenseType = 'Category Expense';
                  _selectedCategory ??= (_expenseCategories.isNotEmpty ? _expenseCategories.first : null);
                });
                _otherExpenseController.clear();
              } else if (topSelected == 'Other (specify)') {
                // Show the inline 'other' field instead of navigating to a new page
                setState(() => _selectedExpenseType = 'Other (specify)');
                // leave _otherExpenseController for user input
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade700, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedExpenseType ?? '- Select expense type -',
                      style: TextStyle(
                        color: _selectedExpenseType != null ? Colors.black87 : Colors.orange.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.orange),
                ],
              ),
            ),
          ),

          // If Category Expense is selected, show a second dropdown for categories + add button
          if (_selectedExpenseType == 'Category Expense') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final cat = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('Select category'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 250,
                              child: ListView.separated(
                                itemCount: _expenseCategories.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final c = _expenseCategories[index];
                                  return ListTile(
                                    title: Text(c),
                                    onTap: () => Navigator.pop(ctx, c),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                      if (cat != null) setState(() => _selectedCategory = cat);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade700, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCategory ?? '- Select category -',
                              style: TextStyle(
                                color: _selectedCategory != null ? Colors.black87 : Colors.green.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () async {
                      // Add new category
                      final newCat = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Add category'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(hintText: 'Category name'),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  final text = controller.text.trim();
                                  if (text.isNotEmpty) Navigator.pop(ctx, text);
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          );
                        },
                      );
                      if (newCat != null && newCat.trim().isNotEmpty) {
                        setState(() {
                          _expenseCategories.add(newCat.trim());
                          _selectedCategory = newCat.trim();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Quantity of items. *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                hintText: '1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          if (_selectedExpenseType == 'Other (specify)') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otherExpenseController,
              decoration: InputDecoration(
                hintText: 'Name of expense . *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              hintText: 'How much did you spend? . *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          // Receipt
          TextField(
            controller: _receiptController,
            decoration: InputDecoration(
              hintText: 'Receipt no. (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Write some notes ...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Enter your notes here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}