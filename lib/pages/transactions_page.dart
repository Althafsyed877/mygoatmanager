import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';

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
  // Helper to convert old maps to Transaction objects
  Transaction _mapToTransaction(Map<String, dynamic> map) {
    return Transaction.fromUIMap(map);
  }
  
  // Helper to convert Transaction to old map format for saving
  Map<String, dynamic> _transactionToOldMap(Transaction transaction) {
    return transaction.toOldFormat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.search_transactions),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: loc.search_by_description,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _searchController.clear();
              },
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(loc.search),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    String selectedDateRange = _selectedDateRangeFilter;
    DateTime? fromDate = _filterFromDate;
    DateTime? toDate = _filterToDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildDateChip(String label, String value, String selectedDateRange, 
                                StateSetter setState, VoidCallback onSelected) {
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

            return AlertDialog(
              title: Text(loc.filter_by_date),
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
                        buildDateChip(loc.today, 'Today', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = now;
                          toDate = now;
                        }),
                        buildDateChip(loc.yesterday, 'Yesterday', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = now.subtract(const Duration(days: 1));
                          toDate = now.subtract(const Duration(days: 1));
                        }),
                        buildDateChip(loc.lastWeek, 'Last Week', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = now.subtract(const Duration(days: 7));
                          toDate = now;
                        }),
                        buildDateChip(loc.currentMonth, 'Current Month', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = DateTime(now.year, now.month, 1);
                          toDate = DateTime(now.year, now.month + 1, 0);
                        }),
                        buildDateChip(loc.lastMonth, 'Last Month', selectedDateRange, setState, () {
                          final now = DateTime.now();
                          fromDate = DateTime(now.year, now.month - 1, 1);
                          toDate = DateTime(now.year, now.month, 0);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Custom Date Range
                    Text(
                      loc.custom_date_range,
                      style: const TextStyle(
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
                              Text(loc.from),
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
                                      selectedDateRange = loc.custom_range;
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
                                        : loc.selectDate,
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
                              Text(loc.to),
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
                                      selectedDateRange = loc.custom_range;
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
                                        : loc.selectDate,
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
                      selectedDateRange = loc.currentMonth;
                      fromDate = null;
                      toDate = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(loc.clear),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(loc.cancel),
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
                  child: Text(
                    loc.apply,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMoreOptionsMenu(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedTab == 0) // Income tab
                ..._buildIncomeMoreOptions(context)
              else // Expenses tab
                ..._buildExpensesMoreOptions(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilteredListView(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
                ? loc.no_income_to_display
                : loc.no_expenses_to_display,
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
        final displayTitle = (e['type'] ?? (_selectedTab == 0 ? loc.income : loc.expenses)) +
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
                        if (_selectedTab == 0) {
                          await _saveIncomes();
                        } else {
                          await _saveExpenses();
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.record_deleted)));
                        }
                      } else if (val == 'edit') {
                        if (_selectedTab == 0) {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => NewIncomePage(initialData: e)));
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() => _incomes[origIndex] = result);
                            await _saveIncomes();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.income_updated)));
                            }
                          }
                        } else {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => NewExpensePage(initialData: e)));
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() => _expenses[origIndex] = result);
                            await _saveExpenses();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.expense_updated)));
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'edit', child: Text(loc.edit_view_record)),
                      PopupMenuItem(value: 'delete', child: Text(loc.delete)),
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

  List<Widget> _buildIncomeMoreOptions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(loc.export_pdf),
        onTap: () async {
          Navigator.pop(context);
          await _exportIncomePdf(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.category, color: Colors.blue),
        title: Text(loc.income_type),
        onTap: () {
          Navigator.pop(context);
          _showIncomeTypeFilter(context);
        },
      ),
    ];
  }

  List<Widget> _buildExpensesMoreOptions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(loc.export_pdf),
        onTap: () async {
          Navigator.pop(context);
          await _exportExpensePdf(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.category, color: Colors.blue),
        title: Text(loc.expense_type),
        onTap: () {
          Navigator.pop(context);
          _showExpenseTypeFilter(context);
        },
      ),
    ];
  }

  void _showIncomeTypeFilter(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final types = [
      loc.all_types,
      loc.milk_sale,
      loc.goat_sale,
      loc.category_income,
      loc.other_specify
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.filter_by_income_type),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            itemCount: types.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = (type == loc.all_types && _selectedIncomeTypeFilter == null) ||
                  _selectedIncomeTypeFilter == type;
              return ListTile(
                title: Text(type),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    _selectedIncomeTypeFilter = type == loc.all_types ? null : type;
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

  void _showExpenseTypeFilter(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final types = [
      loc.all_types,
      loc.category_expense,
      loc.other_expense
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.filter_by_expense_type),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            itemCount: types.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = (type == loc.all_types && _selectedExpenseTypeFilter == null) ||
                  _selectedExpenseTypeFilter == type;
              return ListTile(
                title: Text(type),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.orange) : null,
                onTap: () {
                  setState(() {
                    _selectedExpenseTypeFilter = type == loc.all_types ? null : type;
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

  Future<void> _exportIncomePdf(BuildContext context) async {
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
            children.add(pw.Center(child: pw.Text('No income records')));
          } else {
            children.add(
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.8)),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.TableHelper.fromTextArray(
                    headers: ['Date', 'Source', 'Quantity', 'Price per litre', 'Total', 'Notes'],
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

  Future<void> _exportExpensePdf(BuildContext context) async {
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
            children.add(pw.Center(child: pw.Text('No expense records')));
          } else {
            children.add(
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.8)),
                padding: const pw.EdgeInsets.all(6),
                child: pw.TableHelper.fromTextArray(
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
    final loc = AppLocalizations.of(context)!;
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
        title: Text(
          loc.transactions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () => _showMoreOptionsMenu(context),
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
                        loc.income,
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
                        loc.expenses,
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
                      child: _buildFilteredListView(context),
                    ),

                    // Add Button
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => _selectedTab == 0
                                    ? const NewIncomePage()
                                    : const NewExpensePage(),
                              ),
                            );
                            if (result != null && result is Map<String, dynamic>) {
                              if (result['kind'] == 'income') {
                                setState(() => _incomes.add(result));
                                await _saveIncomes();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.income_saved)));
                                }
                              } else {
                                setState(() => _expenses.add(result));
                                await _saveExpenses();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.expense_saved)));
                                }
                              }
                            }
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
                                _selectedTab == 0 ? loc.add_income : loc.add_expense,
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
  const NewIncomePage({super.key, this.initialData});

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

  final List<String> _incomeCategories = [];
  String? _selectedIncomeCategory;

  @override
  void initState() {
    super.initState();
    _loadIncomeCategories();
    // Initialize with existing data if editing
    final data = widget.initialData;
    if (data != null) {
      if (data['date'] != null) {
        try {
          _incomeDate = DateTime.parse(data['date']);
        } catch (_) {}
      }
      final t = data['type']?.toString();
      if (t != null) {
        _selectedIncomeType = t;
      }
      _quantityController.text = data['quantity']?.toString() ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _amountController.text = data['amount']?.toString() ?? '';
      _receiptController.text = data['receipt']?.toString() ?? '';
      _notesController.text = data['notes']?.toString() ?? '';
      
      // Set category if it exists
      if (data['category'] != null) {
        _selectedIncomeCategory = data['category']?.toString();
      }
      
      // Check if it's an "other" type
      if (_selectedIncomeType != null && 
          _selectedIncomeType != 'Milk Sale' && 
          _selectedIncomeType != 'Goat Sale' && 
          _selectedIncomeType != 'Category Income') {
        _otherSourceController.text = _selectedIncomeType!;
        _selectedIncomeType = 'Other (specify)';
      }
    }
  }

  Future<void> _loadIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('incomeCategories') ?? [];
    setState(() => _incomeCategories.addAll(data));
  }

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

  Widget _buildIncomeTypeForm(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // Get income types from localization
    final milkSale = loc.milk_sale;
    final goatSale = loc.goat_sale;
    final categoryIncome = loc.category_income;
    final otherSpecify = loc.other_specify;
    
    if (_selectedIncomeType == milkSale) {
      return _buildMilkSaleForm(context);
    } else if (_selectedIncomeType == goatSale) {
      return _buildGoatSaleForm(context);
    } else if (_selectedIncomeType == categoryIncome) {
      return _buildCategoryIncomeForm(context);
    } else if (_selectedIncomeType == otherSpecify) {
      return _buildOtherIncomeForm(context);
    }
    return Container();
  }

  Widget _buildMilkSaleForm(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '${loc.milk_quantity_sold} .*',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          decoration: InputDecoration(
            hintText: loc.enter_milk_quantity,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Text(
          '${loc.selling_price_per_litre} . *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          decoration: InputDecoration(
            hintText: loc.enter_price_per_litre,
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
        Text(
          '${loc.how_much_did_you_earn} . *',
          style: const TextStyle(
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

  Widget _buildGoatSaleForm(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
          child: Text(
            loc.please_go_to_record,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${loc.how_much_did_you_earn} . *',
          style: const TextStyle(
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

  Widget _buildCategoryIncomeForm(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '${loc.select_category} .*',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            if (_incomeCategories.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No income categories available. Please add categories in Farm Setup.')),
              );
              return;
            }
            final cat = await showDialog<String>(
              context: context,
              builder: (ctx) {
                String searchQuery = '';
                return StatefulBuilder(
                  builder: (ctx, setState) {
                    final filteredCategories = _incomeCategories
                        .where((category) => category.toLowerCase().contains(searchQuery.toLowerCase()))
                        .toList();
                    return AlertDialog(
                      title: Text(loc.select_category),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 350,
                        child: Column(
                          children: [
                            // Search TextField
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search categories...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                              onChanged: (value) {
                                setState(() => searchQuery = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            // Categories List
                            Expanded(
                              child: filteredCategories.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No categories found',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: filteredCategories.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final c = filteredCategories[index];
                                        return ListTile(
                                          title: Text(c),
                                          onTap: () => Navigator.pop(ctx, c),
                                        );
                                      },
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
            if (cat != null) {
              setState(() => _selectedIncomeCategory = cat);
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
                Expanded(
                  child: Text(
                    _selectedIncomeCategory ?? loc.select_category,
                    style: TextStyle(
                      color: _selectedIncomeCategory != null ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${loc.quantity_of_items} .*',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          decoration: InputDecoration(
            hintText: loc.enter_quantity,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Text(
          '${loc.how_much_did_you_earn} . *',
          style: const TextStyle(
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

  Widget _buildOtherIncomeForm(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          loc.please_specify_source,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otherSourceController,
          decoration: InputDecoration(
            hintText: loc.specify_income_source,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${loc.how_much_did_you_earn} . *',
          style: const TextStyle(
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

  List<String> _getIncomeTypes(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      loc.milk_sale,
      loc.goat_sale,
      loc.category_income,
      loc.other_specify,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.new_income),
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
                  SnackBar(content: Text(loc.please_select_date)),
                );
                return;
              }
              if (_selectedIncomeType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_select_income_type)),
                );
                return;
              }
              if (_amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_enter_amount)),
                );
                return;
              }
              if (_selectedIncomeType == loc.milk_sale && 
                  (_quantityController.text.isEmpty || _priceController.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_enter_quantity_price)),
                );
                return;
              }
              if (_selectedIncomeType == loc.category_income && _quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_enter_quantity)),
                );
                return;
              }
              if (_selectedIncomeType == loc.category_income && _selectedIncomeCategory == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_select_category)),
                );
                return;
              }
              if (_selectedIncomeType == loc.other_specify && _otherSourceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_specify_income_source)),
                );
                return;
              }

              final typeValue = _selectedIncomeType == loc.other_specify
                  ? _otherSourceController.text.trim()
                  : _selectedIncomeType;

              final income = <String, dynamic>{
                'kind': 'income',
                'date': _incomeDate!.toIso8601String(),
                'type': typeValue,
                'category': _selectedIncomeType == loc.category_income ? _selectedIncomeCategory : null,
                'quantity': _selectedIncomeType == loc.milk_sale || _selectedIncomeType == loc.category_income ? _quantityController.text.trim() : null,
                'price': _selectedIncomeType == loc.milk_sale ? _priceController.text.trim() : null,
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
                          : '${loc.date_of_income} . *',
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
              final incomeTypes = _getIncomeTypes(context);
              final selected = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text(loc.select_income_type),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 250,
                      child: ListView.separated(
                        itemCount: incomeTypes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final type = incomeTypes[index];
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
                      _selectedIncomeType ?? '- ${loc.select_income_type} -',
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

          if (_selectedIncomeType != null) _buildIncomeTypeForm(context),

          const SizedBox(height: 16),

          if (_selectedIncomeType != loc.goat_sale)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.receipt_no_optional,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _receiptController,
                  decoration: InputDecoration(
                    hintText: loc.enter_receipt_number,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          Text(
            loc.write_some_notes,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: loc.enter_your_notes,
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
  const NewExpensePage({super.key, this.initialData});

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

  final List<String> _expenseCategories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadExpenseCategories();
    // Initialize with existing data if editing
    final data = widget.initialData;
    if (data != null) {
      if (data['date'] != null) {
        try {
          _expenseDate = DateTime.parse(data['date']);
        } catch (_) {}
      }
      // If category exists, preselect Category Expense
      if (data['category'] != null) {
        _selectedCategory = data['category']?.toString();
        _quantityController.text = data['quantity']?.toString() ?? '';
      } else if (data['type'] != null) {
        _otherExpenseController.text = data['type']?.toString() ?? '';
      }
      _amountController.text = data['amount']?.toString() ?? '';
      _receiptController.text = data['receipt']?.toString() ?? '';
      _notesController.text = data['notes']?.toString() ?? '';
    }
  }

  Future<void> _loadExpenseCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('expenseCategories') ?? [];
    setState(() => _expenseCategories.addAll(data));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _otherExpenseController.dispose();
    super.dispose();
  }

  List<String> _getExpenseTypes(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      loc.category_expense,
      loc.other_expense,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.new_expense),
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
                  SnackBar(content: Text(loc.please_select_date)),
                );
                return;
              }
              if (_selectedExpenseType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_select_expense_type)),
                );
                return;
              }
              if (_selectedExpenseType == loc.other_expense && _otherExpenseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_enter_name_of_expense)),
                );
                return;
              }
              if (_selectedExpenseType == loc.category_expense && _selectedCategory == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_select_category)),
                );
                return;
              }
              if (_selectedExpenseType == loc.category_expense && _quantityController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_enter_quantity)),
                );
                return;
              }
              if (_amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.please_enter_amount)),
                );
                return;
              }

              final typeValue = _selectedExpenseType == loc.other_expense
                  ? _otherExpenseController.text.trim()
                  : (_selectedExpenseType == loc.category_expense
                      ? (_selectedCategory ?? loc.category_expense)
                      : _selectedExpenseType);

              final expense = <String, dynamic>{
                'kind': 'expense',
                'date': _expenseDate!.toIso8601String(),
                'type': typeValue,
                'category': _selectedExpenseType == loc.category_expense ? _selectedCategory : null,
                'quantity': _selectedExpenseType == loc.category_expense ? _quantityController.text.trim() : null,
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
                          : '${loc.date_of_expense} . *',
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
              final expenseTypes = _getExpenseTypes(context);
              // First dialog: choose Category Expense or Other
              final topSelected = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text(loc.select_expense_type),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 160,
                      child: ListView.separated(
                        itemCount: expenseTypes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final opt = expenseTypes[index];
                          return ListTile(
                            title: Text(opt),
                            onTap: () => Navigator.pop(ctx, opt),
                          );
                        },
                      ),
                    ),
                  );
                },
              );

              if (topSelected == null) return;

              if (topSelected == loc.category_expense) {
                // Set the selected type to Category Expense and show inline category selector
                setState(() {
                  _selectedExpenseType = loc.category_expense;
                  _selectedCategory ??= (_expenseCategories.isNotEmpty ? _expenseCategories.first : null);
                });
                _otherExpenseController.clear();
              } else if (topSelected == loc.other_expense) {
                // Show the inline 'other' field instead of navigating to a new page
                setState(() => _selectedExpenseType = loc.other_expense);
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
                      _selectedExpenseType ?? '- ${loc.select_expense_type} -',
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
          if (_selectedExpenseType == loc.category_expense) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final cat = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          String searchQuery = '';
                          return StatefulBuilder(
                            builder: (ctx, setState) {
                              final filteredCategories = _expenseCategories
                                  .where((category) => category.toLowerCase().contains(searchQuery.toLowerCase()))
                                  .toList();
                              return AlertDialog(
                                title: Text(loc.select_category),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 350,
                                  child: Column(
                                    children: [
                                      // Search TextField
                                      TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Search categories...',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        ),
                                        onChanged: (value) {
                                          setState(() => searchQuery = value);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      // Categories List
                                      Expanded(
                                        child: filteredCategories.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No categories found',
                                                  style: TextStyle(color: Colors.grey.shade600),
                                                ),
                                              )
                                            : ListView.separated(
                                                itemCount: filteredCategories.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1),
                                                itemBuilder: (context, index) {
                                                  final c = filteredCategories[index];
                                                  return ListTile(
                                                    title: Text(c),
                                                    onTap: () => Navigator.pop(ctx, c),
                                                  );
                                                },
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
                              _selectedCategory ?? '- ${loc.select_category} -',
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
                            title: Text(loc.add_category),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(hintText: loc.category_name),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx), 
                                child: Text(loc.cancel)
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final text = controller.text.trim();
                                  if (text.isNotEmpty) Navigator.pop(ctx, text);
                                },
                                child: Text(loc.add),
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
            Text(
              '${loc.quantity_of_items} . *',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                hintText: loc.enter_quantity,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          if (_selectedExpenseType == loc.other_expense) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otherExpenseController,
              decoration: InputDecoration(
                hintText: '${loc.name_of_expense} . *',
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
              hintText: '${loc.how_much_did_you_spend} . *',
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
              hintText: loc.receipt_no_optional,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            loc.write_some_notes,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: loc.enter_your_notes,
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