import 'package:flutter/material.dart';
import 'transactions_report_page.dart';
import 'goats_report_page.dart';
import 'pregnancies_page.dart';
import 'stage_tracking_page.dart';
import '../models/goat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mygoatmanager/l10n/app_localizations.dart';



class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Green Header with back arrow and title
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20, // Dynamic top padding
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50), // Exact green from screenshot
            ),
            child: Row(
              children: [
                // Back Arrow
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Title - Expanded to prevent overflow
                Expanded(
                  child: Text(
                    loc.reports,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Orange Line below header - NO SPACING AFTER
          Container(
            height: 4,
            width: double.infinity,
            color: const Color(0xFFFF9800), // Exact orange
          ),
          
          // Main Content with 8 menu cards - DIRECTLY AFTER ORANGE LINE
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate crossAxisCount based on screen width
                final double screenWidth = constraints.maxWidth;
                final int crossAxisCount = screenWidth < 400 ? 2 : 2; // Keep 2 columns for all sizes
                
                // Calculate spacing and card size dynamically
                final double spacing = screenWidth < 350 ? 12 : 20;
                final double aspectRatio = screenWidth < 350 ? 0.9 : 1.0;
                
                return Padding(
                  padding: EdgeInsets.all(spacing),
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                    children: [
                      _buildMenuCard(context, loc.transactionsReport, 'assets/images/transactions.png'),
                      _buildMenuCard(context, loc.milkReport, 'assets/images/milk.png'),
                      _buildMenuCard(context, loc.goatsReport, 'assets/images/goat.png'),
                      _buildMenuCard(context, loc.eventsReport, 'assets/images/events.png'),
                      _buildMenuCard(context, loc.breedingReport, 'assets/images/breeding_report.png'),
                      _buildMenuCard(context, loc.pregnanciesReport, 'assets/images/pregnancies.png'),
                      _buildMenuCard(context, loc.weightReport, 'assets/images/weight_report.png'),
                      _buildMenuCard(context, loc.stageTrackingReport, 'assets/images/stage_tracking.png'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String iconPath) {
    final loc = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50), // Exact green color for cards
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navigate to the appropriate report page based on title
              if (title == loc.transactionsReport) {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TransactionsReportPage()));
                return;
              }
              if (title == loc.goatsReport) {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const GoatsReportPage()));
                return;
              }
              if (title == loc.pregnanciesReport) {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PregnanciesPage()));
                return;
              }
              if (title == loc.stageTrackingReport) {
                _navigateToStageTracking(context);
                return;
              }
              // default
              debugPrint('Tapped: $title');
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding for smaller screens
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PNG Icon with original colors - Responsive size
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double iconSize = constraints.maxWidth < 150 ? 50 : 70;
                      return Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white, // White background for icon
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0), // Reduced padding
                          child: Image.asset(
                            iconPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.error_outline,
                                color: const Color(0xFF4CAF50),
                                size: iconSize * 0.4, // Proportional size
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8), // Reduced spacing
                  
                  // Title with proper overflow handling
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white, // White text on green background
                          fontSize: 14, // Slightly smaller font for small screens
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToStageTracking(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    
    // Load goats from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? goatsJson = prefs.getString('goats');
    
    if (goatsJson == null) {
      // Show error if no goats found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.noGoatsFound),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final List<dynamic> decodedList = jsonDecode(goatsJson);
    final List<Goat> goats = decodedList.map((item) => Goat.fromJson(item)).toList();

    // FIXED: Now passing the required goats parameter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StageTrackingPage(goats: goats),
      ),
    );
  }
}