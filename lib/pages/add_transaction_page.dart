// lib/pages/transactions/add_transaction_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../../models/transaction.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionType type;
  final Transaction? initialTransaction;
  
  const AddTransactionPage({
    super.key,
    required this.type,
    this.initialTransaction,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _receiptNumberController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pricePerUnitController = TextEditingController();
  
  // Form fields
  DateTime _transactionDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedSubCategory;
  
  // Categories based on transaction type
  List<String> _categories = [];
  
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialTransaction != null;
    _loadCategories();
    _initializeForm();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (widget.type == TransactionType.income) {
      _categories = prefs.getStringList('income_categories') ?? [
        'Milk Sale',
        'Goat Sale',
        'Manure Sale',
        'Category Income',
        'Other'
      ];
    } else {
      _categories = prefs.getStringList('expense_categories') ?? [
        'Feed',
        'Medicine',
        'Equipment',
        'Labor',
        'Transport',
        'Utilities',
        'Category Expense',
        'Other'
      ];
    }
    
    if (!_isEditing) {
      _selectedCategory = _categories.first;
    }
    
    setState(() {});
  }

  void _initializeForm() {
    final transaction = widget.initialTransaction;
    if (transaction != null) {
      _transactionDate = transaction.transactionDate;
      _selectedCategory = transaction.category;
      _selectedSubCategory = transaction.subCategory;
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.description ?? '';
      _contactNameController.text = transaction.contactName ?? '';
      _contactInfoController.text = transaction.contactInfo ?? '';
      _notesController.text = transaction.notes ?? '';
      _receiptNumberController.text = transaction.receiptNumber ?? '';
      _quantityController.text = transaction.quantity?.toString() ?? '';
      _pricePerUnitController.text = transaction.pricePerUnit?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactInfoController.dispose();
    _notesController.dispose();
    _receiptNumberController.dispose();
    _quantityController.dispose();
    _pricePerUnitController.dispose();
    super.dispose();
  }
Future<void> _saveTransaction() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);

  try {
    final transaction = Transaction(
      type: widget.type,
      category: _selectedCategory,
      subCategory: _selectedSubCategory,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      transactionDate: _transactionDate,
      contactName: _contactNameController.text.isEmpty ? null : _contactNameController.text,
      contactInfo: _contactInfoController.text.isEmpty ? null : _contactInfoController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      receiptNumber: _receiptNumberController.text.isEmpty ? null : _receiptNumberController.text,
      quantity: _quantityController.text.isEmpty ? null : double.parse(_quantityController.text),
      pricePerUnit: _pricePerUnitController.text.isEmpty ? null : double.parse(_pricePerUnitController.text),
    );

    // DEBUG: Print what we're saving
    print('=== SAVING TRANSACTION ===');
    print('Type: ${transaction.type}');
    print('Category: ${transaction.category}');
    print('Amount: ${transaction.amount}');
    print('JSON: ${transaction.toJson()}');

    // Save to SharedPreferences
    await _saveToLocalStorage(transaction);
    
    if (mounted) {
      Navigator.pop(context, transaction);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _saveToLocalStorage(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing transactions
    final transactionsKey = 'transactions';
    final transactionsJson = prefs.getString(transactionsKey) ?? '[]';
    final List<dynamic> transactionsList = jsonDecode(transactionsJson);
    
    if (_isEditing && widget.initialTransaction != null) {
      // Update existing transaction
      // Find the index of the transaction to update
      // This is simplified - in real app you'd use ID
      final oldTransaction = widget.initialTransaction!;
      // For now, we'll just add new and remove old
      transactionsList.removeWhere((item) {
        final itemTransaction = Transaction.fromJson(item);
        // Simple comparison - in real app use ID
        return itemTransaction.transactionDate == oldTransaction.transactionDate &&
               itemTransaction.amount == oldTransaction.amount &&
               itemTransaction.type == oldTransaction.type;
      });
    }
    
    // Add new transaction
    transactionsList.add(transaction.toJson());
    
    // Save back
    await prefs.setString(transactionsKey, jsonEncode(transactionsList));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isIncome = widget.type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? isIncome ? loc.edit_income : loc.edit_expense
              : isIncome ? loc.new_income : loc.new_expense,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTransaction,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _transactionDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _transactionDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_transactionDate.day}/${_transactionDate.month}/${_transactionDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: loc.category,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _selectedSubCategory = null;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.please_select_category;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sub-category/Description field
                  if (_selectedCategory == 'Other' || 
                      _selectedCategory == 'Category Income' || 
                      _selectedCategory == 'Category Expense')
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: _selectedCategory == 'Other'
                            ? loc.description
                            : loc.sub_category,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  // Quantity and Price (for certain categories)
                  if (_selectedCategory == 'Milk Sale' || 
                      _selectedCategory == 'Category Income' ||
                      _selectedCategory == 'Category Expense')
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: loc.quantity,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        if (_selectedCategory == 'Milk Sale')
                          TextFormField(
                            controller: _pricePerUnitController,
                            decoration: InputDecoration(
                              labelText: loc.price_per_unit,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (_quantityController.text.isNotEmpty && 
                                  _pricePerUnitController.text.isNotEmpty) {
                                final quantity = double.tryParse(_quantityController.text) ?? 0;
                                final price = double.tryParse(value) ?? 0;
                                _amountController.text = (quantity * price).toStringAsFixed(2);
                              }
                            },
                          ),
                      ],
                    ),

                  // Amount
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: loc.amount,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.please_enter_amount;
                      }
                      if (double.tryParse(value) == null) {
                        return loc.please_enter_valid_amount;
                      }
                      return null;
                    },
                  ),

                  // Contact Information
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactNameController,
                    decoration: InputDecoration(
                      labelText: isIncome ? loc.buyer_name : loc.vendor_name,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactInfoController,
                    decoration: InputDecoration(
                      labelText: isIncome ? loc.buyer_contact : loc.vendor_contact,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  // Receipt Number
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _receiptNumberController,
                    decoration: InputDecoration(
                      labelText: loc.receipt_number,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Notes
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: loc.notes,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),

                  // Save Button
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIncome ? Colors.green : Colors.orange,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditing ? loc.update : loc.save,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}