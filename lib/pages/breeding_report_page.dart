import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import '../models/goat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BreedingReportPage extends StatefulWidget {
  const BreedingReportPage({super.key});

  @override
  State<BreedingReportPage> createState() => _BreedingReportPageState();
}

class _BreedingReportPageState extends State<BreedingReportPage> {
  final List<Goat> _allGoats = [];
  final List<Goat> _femaleGoats = [];
  final List<Goat> _maleGoats = [];
  bool _isLoading = true;
  
  // Breeding statistics
  int _pregnantCount = 0;
  int _bredCount = 0;
  int _lactatingCount = 0;
  int _notBredCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    
    final prefs = await SharedPreferences.getInstance();
    final String? goatsJson = prefs.getString('goats');
    
    if (goatsJson != null) {
      final List<dynamic> decoded = jsonDecode(goatsJson);
      _allGoats.clear();
      _allGoats.addAll(decoded.map((item) => Goat.fromJson(item)).toList());
      _analyzeBreedingData();
      
      debugPrint('=== Breeding Report Data ===');
      debugPrint('Total goats: ${_allGoats.length}');
      debugPrint('Female goats: ${_femaleGoats.length}');
      debugPrint('Male goats: ${_maleGoats.length}');
    }
    
    setState(() { _isLoading = false; });
  }
  
  void _analyzeBreedingData() {
    // Clear all lists
    _femaleGoats.clear();
    _maleGoats.clear();
    
    // Reset counts
    _pregnantCount = 0;
    _bredCount = 0;
    _lactatingCount = 0;
    _notBredCount = 0;
    
    // Separate goats by gender and count breeding status
    for (var goat in _allGoats) {
      final isFemale = goat.gender.toLowerCase().contains('female');
      
      if (isFemale) {
        _femaleGoats.add(goat);
        
        // Count breeding status
        final status = goat.breedingStatus?.toLowerCase() ?? 'not bred';
        if (status.contains('pregnant')) {
          _pregnantCount++;
        } else if (status.contains('lactating')) {
          _lactatingCount++;
        } else if (status.contains('bred')) {
          _bredCount++;
        } else {
          _notBredCount++;
        }
      } else {
        _maleGoats.add(goat);
      }
    }
  }
  
  List<Goat> _getGoatsByStatus(String status) {
    return _femaleGoats.where((goat) {
      final goatStatus = goat.breedingStatus?.toLowerCase() ?? 'not bred';
      return goatStatus.contains(status.toLowerCase());
    }).toList();
  }
  
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoatCard(Goat goat) {
    final status = goat.breedingStatus ?? 'Not Bred';
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'pregnant':
        statusColor = Colors.purple;
        statusIcon = Icons.pregnant_woman;
        break;
      case 'lactating':
        statusColor = Colors.pink;
        statusIcon = Icons.opacity;
        break;
      case 'bred':
        statusColor = Colors.orange;
        statusIcon = Icons.favorite;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(statusIcon, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goat.tagNo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    goat.name ?? 'Unnamed',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    side: BorderSide(color: statusColor.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (goat.breed != null)
                  Text(
                    goat.breed!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                Text(
                  'Age: ${_calculateAge(goat.dateOfBirth)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _calculateAge(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return 'Unknown';
    
    try {
      final dob = DateFormat('dd/MM/yyyy').parse(dobStr);
      final now = DateTime.now();
      final years = now.year - dob.year;
      final months = now.month - dob.month;
      
      if (years > 0) return '$years year${years > 1 ? 's' : ''}';
      return '$months month${months > 1 ? 's' : ''}';
    } catch (_) {
      return 'Unknown';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C27B0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc?.breedingReportTitle ?? 'Breeding Report',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: loc?.refreshData ?? 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Females',
                              '${_femaleGoats.length}',
                              Colors.purple,
                              Icons.female,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total Males',
                              '${_maleGoats.length}',
                              Colors.blue,
                              Icons.male,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Pregnant',
                              '$_pregnantCount',
                              Colors.pink,
                              Icons.pregnant_woman,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Lactating',
                              '$_lactatingCount',
                              Colors.orange,
                              Icons.opacity,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Bred',
                              '$_bredCount',
                              Colors.green,
                              Icons.favorite,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Not Bred',
                              '$_notBredCount',
                              Colors.grey,
                              Icons.help_outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
                
                // Filter tabs
                DefaultTabController(
                  length: 4,
                  child: Expanded(
                    child: Column(
                      children: [
                        Material(
                          color: Colors.white,
                          child: TabBar(
                            labelColor: const Color(0xFF9C27B0),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFF9C27B0),
                            tabs: const [
                              Tab(text: 'Pregnant'),
                              Tab(text: 'Lactating'),
                              Tab(text: 'Bred'),
                              Tab(text: 'Not Bred'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Pregnant tab
                              _pregnantCount == 0
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.pregnant_woman,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc?.noPregnantGoats ?? 'No pregnant goats found',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _getGoatsByStatus('pregnant').length,
                                      itemBuilder: (context, index) {
                                        return _buildGoatCard(_getGoatsByStatus('pregnant')[index]);
                                      },
                                    ),
                              
                              // Lactating tab
                              _lactatingCount == 0
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.opacity,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc?.noLactatingGoats ?? 'No lactating goats found',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _getGoatsByStatus('lactating').length,
                                      itemBuilder: (context, index) {
                                        return _buildGoatCard(_getGoatsByStatus('lactating')[index]);
                                      },
                                    ),
                              
                              // Bred tab
                              _bredCount == 0
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc?.noBredGoats ?? 'No bred goats found',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _getGoatsByStatus('bred').length,
                                      itemBuilder: (context, index) {
                                        return _buildGoatCard(_getGoatsByStatus('bred')[index]);
                                      },
                                    ),
                              
                              // Not Bred tab
                              _notBredCount == 0
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 60,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc?.allGoatsBred ?? 'All female goats have breeding records',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _getGoatsByStatus('not bred').length,
                                      itemBuilder: (context, index) {
                                        return _buildGoatCard(_getGoatsByStatus('not bred')[index]);
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}