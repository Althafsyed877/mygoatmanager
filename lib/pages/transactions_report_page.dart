import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionsReportPage extends StatefulWidget {
  const TransactionsReportPage({Key? key}) : super(key: key);

  @override
  State<TransactionsReportPage> createState() => _TransactionsReportPageState();
}

class _TransactionsReportPageState extends State<TransactionsReportPage> {
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final incomesStr = prefs.getString('saved_incomes');
    final expensesStr = prefs.getString('saved_expenses');
    double incomeSum = 0.0;
    double expenseSum = 0.0;
    if (incomesStr != null) {
      try {
        final List<dynamic> list = jsonDecode(incomesStr);
        for (var item in list) {
          final amt = double.tryParse((item['amount'] ?? '').toString()) ?? 0.0;
          incomeSum += amt;
        }
      } catch (_) {}
    }
    if (expensesStr != null) {
      try {
        final List<dynamic> list = jsonDecode(expensesStr);
        for (var item in list) {
          final amt = double.tryParse((item['amount'] ?? '').toString()) ?? 0.0;
          expenseSum += amt;
        }
      } catch (_) {}
    }
    setState(() {
      totalIncome = incomeSum;
      totalExpense = expenseSum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final net = totalIncome - totalExpense;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transactions Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(height: 4, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFFF9800)))),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
                        child: Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: Center(child: Text('Net\n₹${net.toStringAsFixed(2)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Income:', style: TextStyle(fontSize: 16)),
                        Text('₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Expenses:', style: TextStyle(fontSize: 16)),
                        Text('₹${totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('₹${net.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
