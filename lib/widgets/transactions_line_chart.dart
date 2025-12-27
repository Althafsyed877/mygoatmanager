import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class TransactionsLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final bool isIncome;
  const TransactionsLineChart({super.key, required this.spots, this.isIncome = true});

  @override
  Widget build(BuildContext context) {
  return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: isIncome ? Colors.green : Colors.orange,
              barWidth: 4,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
