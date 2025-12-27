import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class TransactionsDataSummary extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double net;
  const TransactionsDataSummary({super.key, required this.totalIncome, required this.totalExpense, required this.net});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.totalIncome, style: const TextStyle(fontSize: 16)),
            Text('₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.totalExpenses, style: const TextStyle(fontSize: 16)),
            Text('₹${totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.net, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('₹${net.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
