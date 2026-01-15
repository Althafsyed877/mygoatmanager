import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class TransactionsLineChart extends StatelessWidget {
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final List<String> dates;
  final String? title;
  final DateTimeRange? dateRange;

  const TransactionsLineChart({
    super.key,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.dates,
    this.title,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
      // Debug output for troubleshooting
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Center(child: CircularProgressIndicator());
    }

    try {
      // Validate data before rendering
      final validIncomeSpots = _validateSpots(incomeSpots);
      final validExpenseSpots = _validateSpots(expenseSpots);
      
      if (validIncomeSpots.isEmpty && validExpenseSpots.isEmpty) {
        return _buildEmptyState();
      }

      final maxY = _getMaxYValue(validIncomeSpots, validExpenseSpots);
      final minY = _getMinYValue(validIncomeSpots, validExpenseSpots);
      
      // Ensure minY is not greater than maxY
      final adjustedMinY = minY < maxY ? minY : 0.0;
      final adjustedMaxY = maxY > 0 ? maxY * 1.1 : 100.0;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, adjustedMaxY, l10n),
            const SizedBox(height: 16),
            
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: LineChart(
                _buildChartData(validIncomeSpots, validExpenseSpots, adjustedMinY, adjustedMaxY),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildLegendAndSummary(context, validIncomeSpots, validExpenseSpots),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error building TransactionsLineChart: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return _buildErrorState();
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No chart data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add transactions to see the chart',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(
    List<FlSpot> validIncomeSpots,
    List<FlSpot> validExpenseSpots,
    double minY,
    double maxY,
  ) {
    final List<LineChartBarData> bars = [];
    
    // Add income line if we have valid data
    if (validIncomeSpots.isNotEmpty) {
      bars.add(LineChartBarData(
        spots: validIncomeSpots,
        isCurved: validIncomeSpots.length > 2,
        color: const Color(0xFF4CAF50),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: validIncomeSpots.length <= 20,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 3,
              color: const Color(0xFF4CAF50),
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xFF4CAF50).withOpacity(0.1),
        ),
      ));
    }
    
    // Add expense line if we have valid data
    if (validExpenseSpots.isNotEmpty) {
      bars.add(LineChartBarData(
        spots: validExpenseSpots,
        isCurved: validExpenseSpots.length > 2,
        color: const Color(0xFFFF9800),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: validExpenseSpots.length <= 20,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 3,
              color: const Color(0xFFFF9800),
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xFFFF9800).withOpacity(0.1),
        ),
      ));
    }
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: _getGridInterval(maxY),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _getTitleInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < dates.length) {
                final dateStr = dates[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _formatDateForDisplay(dateStr),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _getLeftTitleInterval(maxY),
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Text(
                  '₹${_formatAmount(value)}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      minY: minY,
      maxY: maxY,
      lineBarsData: bars,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white,
          tooltipRoundedRadius: 4,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final index = touchedSpot.spotIndex;
              final date = index < dates.length ? dates[index] : '';
              final value = touchedSpot.y;
              final color = touchedSpot.barIndex == 0
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800);
              final label = touchedSpot.barIndex == 0 ? 'Income' : 'Expense';
              
              return LineTooltipItem(
                '$label\n${_formatDateForTooltip(date)}\n₹${value.toStringAsFixed(0)}',
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double maxY, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? l10n.lineChart,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (dateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${_formatDate(dateRange!.start)} - ${_formatDate(dateRange!.end)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
        if (maxY > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              'Max: ₹${_formatAmount(maxY)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegendAndSummary(BuildContext context, List<FlSpot> validIncomeSpots, List<FlSpot> validExpenseSpots) {
    final incomeMax = _getMaxValue(validIncomeSpots);
    final expenseMax = _getMaxValue(validExpenseSpots);
    final incomeAvg = _getAverageValue(validIncomeSpots);
    final expenseAvg = _getAverageValue(validExpenseSpots);
    
    final hasIncomeData = validIncomeSpots.isNotEmpty;
    final hasExpenseData = validExpenseSpots.isNotEmpty;
    
    if (!hasIncomeData && !hasExpenseData) {
      return const SizedBox();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (hasIncomeData) _buildStatItem(
            label: 'Income Peak',
            value: '₹${_formatAmount(incomeMax)}',
            color: const Color(0xFF4CAF50),
          ) else const SizedBox(width: 40),
          if (hasExpenseData) _buildStatItem(
            label: 'Expense Peak',
            value: '₹${_formatAmount(expenseMax)}',
            color: const Color(0xFFFF9800),
          ) else const SizedBox(width: 40),
          if (hasIncomeData) _buildStatItem(
            label: 'Income Avg',
            value: '₹${_formatAmount(incomeAvg)}',
            color: const Color(0xFF4CAF50),
          ) else const SizedBox(width: 40),
          if (hasExpenseData) _buildStatItem(
            label: 'Expense Avg',
            value: '₹${_formatAmount(expenseAvg)}',
            color: const Color(0xFFFF9800),
          ) else const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _validateSpots(List<FlSpot> spots) {
    final List<FlSpot> validSpots = [];
    
    for (var spot in spots) {
      // Check if spot values are valid numbers
      if (spot.x.isFinite && spot.y.isFinite && !spot.x.isNaN && !spot.y.isNaN) {
        validSpots.add(spot);
      }
    }
    
    return validSpots;
  }

  double _getMaxYValue(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots) {
    final incomeMax = _getMaxValue(incomeSpots);
    final expenseMax = _getMaxValue(expenseSpots);
    final maxValue = incomeMax > expenseMax ? incomeMax : expenseMax;
    return maxValue > 0 ? maxValue : 100;
  }

  double _getMinYValue(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots) {
    final incomeMin = _getMinValue(incomeSpots);
    final expenseMin = _getMinValue(expenseSpots);
    
    double minValue = 0;
    if (incomeSpots.isNotEmpty && expenseSpots.isNotEmpty) {
      minValue = incomeMin < expenseMin ? incomeMin : expenseMin;
    } else if (incomeSpots.isNotEmpty) {
      minValue = incomeMin;
    } else if (expenseSpots.isNotEmpty) {
      minValue = expenseMin;
    }
    
    // Ensure min is not negative unless we have negative values
    return minValue > 0 ? minValue * 0.9 : 0;
  }

  double _getMaxValue(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    try {
      return spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    } catch (e) {
      return 0;
    }
  }

  double _getMinValue(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    try {
      return spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    } catch (e) {
      return 0;
    }
  }

  double _getAverageValue(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    try {
      final sum = spots.fold(0.0, (total, spot) => total + spot.y);
      return sum / spots.length;
    } catch (e) {
      return 0;
    }
  }

  double _getGridInterval(double maxY) {
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    if (maxY <= 50000) return 10000;
    return 20000;
  }

  double _getLeftTitleInterval(double maxY) {
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    if (maxY <= 50000) return 10000;
    return 20000;
  }

  double _getTitleInterval() {
    final count = dates.length;
    if (count <= 5) return 1;
    if (count <= 10) return 2;
    if (count <= 20) return 3;
    if (count <= 30) return 5;
    return (count / 6).ceil().toDouble();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDateForDisplay(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateForTooltip(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}