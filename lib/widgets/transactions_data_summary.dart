import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class TransactionsDataSummary extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double net;
  final List<Map<String, dynamic>>? incomeDetails;
  final List<Map<String, dynamic>>? expenseDetails;
  final DateTimeRange? dateRange;

  const TransactionsDataSummary({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    this.incomeDetails,
    this.expenseDetails,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final incomeByCategory = _groupByCategory(incomeDetails ?? []);
      final expenseByCategory = _groupByCategory(expenseDetails ?? []);
      
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF4CAF50),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  l10n.dataSummary,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50),
                        Colors.green.shade600,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Financial Summary',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            if (dateRange != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${_formatDate(dateRange!.start)} - ${_formatDate(dateRange!.end)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  onPressed: () {
                    // Filter functionality
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCards(context),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Income Breakdown', Colors.green.shade700),
                  const SizedBox(height: 12),
                  _buildCategoryBreakdown(incomeByCategory, Colors.green, totalIncome),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Expense Breakdown', Colors.orange.shade700),
                  const SizedBox(height: 12),
                  _buildCategoryBreakdown(expenseByCategory, Colors.orange, totalExpense),
                  const SizedBox(height: 24),
                  
                  _buildNetAnalysis(context),
                  const SizedBox(height: 24),
                  
                  _buildInsights(context),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error building TransactionsDataSummary: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          title: const Text('Financial Summary'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Unable to load financial summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Error: ${e.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => TransactionsDataSummary(
                          totalIncome: totalIncome,
                          totalExpense: totalExpense,
                          net: net,
                          incomeDetails: incomeDetails,
                          expenseDetails: expenseDetails,
                          dateRange: dateRange,
                        ),
                      ),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Income',
            amount: totalIncome,
            color: const Color(0xFF4CAF50),
            icon: Icons.arrow_upward,
            percentage: totalIncome > 0 && totalExpense > 0 
                ? (totalIncome / (totalIncome + totalExpense) * 100)
                : 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Expenses',
            amount: totalExpense,
            color: Colors.orange,
            icon: Icons.arrow_downward,
            percentage: totalExpense > 0 && totalIncome > 0
                ? (totalExpense / (totalIncome + totalExpense) * 100)
                : 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: net >= 0 ? 'Net Profit' : 'Net Loss',
            amount: net.abs(),
            color: net >= 0 ? Colors.green.shade700 : Colors.red,
            icon: net >= 0 ? Icons.trending_up : Icons.trending_down,
            percentage: totalIncome > 0 ? (net / totalIncome * 100).abs() : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required double percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
    Map<String, double> categoryMap,
    Color color,
    double total,
  ) {
    if (categoryMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...sortedCategories.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0;
            return _buildCategoryItem(
              category: entry.key,
              amount: entry.value,
              percentage: percentage.toDouble(),
              color: color,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    final percentageInt = percentage.round();
    final remainingPercentage = 100 - percentageInt;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatAmount(amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: percentageInt,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: remainingPercentage,
                      child: const SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetAnalysis(BuildContext context) {
    final savingsRate = totalIncome > 0 ? (net / totalIncome * 100) : 0;
    final expenseRate = totalIncome > 0 ? (totalExpense / totalIncome * 100) : 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Financial Health Analysis', Colors.blue.shade700),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalysisItem(
                label: 'Savings Rate',
                value: '${savingsRate.toStringAsFixed(1)}%',
                icon: Icons.savings,
                color: savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red,
              ),
              _buildAnalysisItem(
                label: 'Expense Ratio',
                value: '${expenseRate.toStringAsFixed(1)}%',
                icon: Icons.pie_chart,
                color: expenseRate <= 80 ? Colors.green : expenseRate <= 90 ? Colors.orange : Colors.red,
              ),
              _buildAnalysisItem(
                label: 'Profit Margin',
                value: '${(net >= 0 ? savingsRate : savingsRate.abs()).toStringAsFixed(1)}%',
                icon: net >= 0 ? Icons.trending_up : Icons.trending_down,
                color: net >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(BuildContext context) {
    final insights = <String>[];
    
    if (net > 0) {
      insights.add('You are operating at a profit. Great work!');
    } else if (net < 0) {
      insights.add('Expenses are exceeding income. Consider reviewing costs.');
    }
    
    if (totalIncome > 0 && totalExpense / totalIncome > 0.9) {
      insights.add('Expense ratio is high. Look for cost-saving opportunities.');
    }
    
    if (totalIncome > 0 && net / totalIncome > 0.3) {
      insights.add('Strong profit margin indicates efficient operations.');
    }
    
    if (insights.isEmpty) {
      insights.add('Add more transactions to get personalized insights.');
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Insights & Recommendations', Colors.purple.shade700),
          const SizedBox(height: 16),
          
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Map<String, double> _groupByCategory(List<Map<String, dynamic>> transactions) {
    final Map<String, double> result = {};
    
    try {
      for (var transaction in transactions) {
        final category = transaction['category']?.toString() ?? 
                        transaction['type']?.toString() ?? 'Uncategorized';
        final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
        
        result[category] = (result[category] ?? 0.0) + amount;
      }
    } catch (e) {
      debugPrint('Error in _groupByCategory: $e');
    }
    
    return result;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}