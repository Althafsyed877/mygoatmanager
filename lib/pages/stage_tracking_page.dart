import 'package:flutter/material.dart';
import '../models/goat.dart';

class StageTrackingPage extends StatefulWidget {
  final List<Goat> goats;

  const StageTrackingPage({super.key, required this.goats});

  @override
  State<StageTrackingPage> createState() => _StageTrackingPageState();
}

class _StageTrackingPageState extends State<StageTrackingPage> {
  Set<String> selectedGoats = {};

  // Get goats that need stage updates (Kids that can progress to Does/Bucks)
  List<Goat> get goatsNeedingUpdate {
    return widget.goats.where((goat) {
      // Only show Kids that can progress to next stage
      if (goat.goatStage == null || goat.goatStage!.isEmpty) return false;
      if (goat.goatStage!.toLowerCase() != 'kid') return false;
      
      // Filter out wethers (castrated males)
      if (goat.gender.toLowerCase() == 'wether') return false;
      
      // Filter out animals without birth dates
      if (goat.dateOfBirth == null || goat.dateOfBirth!.isEmpty) return false;
      
      return true;
    }).toList();
  }

  String _getNextStage(String gender) {
    final lowerGender = gender.toLowerCase();
    
    if (lowerGender == 'female') return 'Doe';
    if (lowerGender == 'male') return 'Buck';
    if (lowerGender == 'buckling') return 'Buck';
    
    return 'Buck'; // default for other male types
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Stage Tracking', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(
            height: 4, 
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFFF9800))
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Update Selected Button - Aligned to right
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_box, color: Colors.white, size: 20),
                  label: const Text('Update Selected', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: selectedGoats.isEmpty ? null : _updateSelectedStages,
                ),
              ),
              const SizedBox(height: 12),
              
              // Info Banner - Exact style from screenshot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Animals that might need stage update.',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Warning Text - Exact from screenshot
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Wethers and animals without birth dates are not listed!',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Divider
              const Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              
              // Goats List
              Expanded(
                child: goatsNeedingUpdate.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: goatsNeedingUpdate.length,
                        itemBuilder: (context, index) {
                          final goat = goatsNeedingUpdate[index];
                          return _buildGoatCard(goat);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green[700]),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'No goats need stage updates at this time.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoatCard(Goat goat) {
    final isSelected = selectedGoats.contains(goat.tagNo);
    final daysSinceBirth = _calculateDaysSinceBirth(goat.dateOfBirth);
    final nextStage = _getNextStage(goat.gender);
    final isMale = goat.gender.toLowerCase() == 'male' || 
                   goat.gender.toLowerCase() == 'buckling' || 
                   goat.gender.toLowerCase() == 'buck';
    final genderColor = isMale ? const Color(0xFF4CAF50) : const Color(0xFFFFA726);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), 
        side: const BorderSide(color: Color(0xFF4CAF50))
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Checkbox - Circular style
            InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedGoats.remove(goat.tagNo);
                  } else {
                    selectedGoats.add(goat.tagNo);
                  }
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2),
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            
            // Goat image - Using goat.png with gender-based color
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/goat.png',
                color: genderColor,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            
            // Goat Details - Exact layout from screenshot
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goat.tagNo,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF4CAF50)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'goat',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$daysSinceBirth days',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, 
                      color: Color(0xFFFFA726)
                    ),
                  ),
                ],
              ),
            ),
            
            // Next Stage Arrow - Exact from screenshot
            Row(
              children: [
                const Text(
                  '→',
                  style: TextStyle(
                    color: Color(0xFF4CAF50), 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  nextStage,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50), 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateDaysSinceBirth(String? dateOfBirth) {
    if (dateOfBirth == null) return 0;
    
    try {
      final parts = dateOfBirth.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        
        if (day != null && month != null && year != null) {
          final dob = DateTime(year, month, day);
          final now = DateTime.now();
          final difference = now.difference(dob);
          return difference.inDays;
        }
      }
    } catch (e) {
      debugPrint('Error calculating days: $e');
    }
    
    return 0;
  }

  void _updateSelectedStages() {
    if (selectedGoats.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stages'),
        content: Text('Update ${selectedGoats.length} goats from Kid to next stage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update logic here
              for (final tagNo in selectedGoats) {
                final goat = widget.goats.firstWhere((g) => g.tagNo == tagNo);
                final newStage = _getNextStage(goat.gender);
                
                // Update the goat stage (in real app, save to database)
                debugPrint('Updating ${goat.tagNo} from Kid to $newStage');
              }
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Updated ${selectedGoats.length} goats successfully!'),
                  backgroundColor: Colors.green,
                )
              );
              
              // Clear selection
              setState(() {
                selectedGoats.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}