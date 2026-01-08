import 'package:flutter/material.dart';

class PrivacypolicyPage extends StatefulWidget {
  const PrivacypolicyPage({super.key});

  @override
  State<PrivacypolicyPage> createState() => _PrivacypolicyPageState();
}

class _PrivacypolicyPageState extends State<PrivacypolicyPage> {
  bool _isExpanded1 = false;
  bool _isExpanded2 = false;
  bool _isExpanded3 = false;
  bool _isExpanded4 = false;
  bool _isExpanded5 = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.privacy_tip,
                    size: 48,
                    color: Color(0xFF388E3C),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Goat Manager App',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy is our priority. This policy explains how we handle your farm data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Last Updated
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.update,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last Updated: ${_getCurrentDate()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Policy Sections
            _buildExpandableSection(
              title: '1. Data Collection',
              content: '''
• Goat information (ID, breed, age, weight)
• Health records and medical treatments
• Breeding history and kidding records
• Milk production data (if tracked)
• Feeding schedules and diet information
• Farm operational data
              ''',
              isExpanded: _isExpanded1,
              onTap: () => setState(() => _isExpanded1 = !_isExpanded1),
            ),
            
            const SizedBox(height: 16),
            
            _buildExpandableSection(
              title: '2. Data Usage',
              content: '''
• Provide goat management features
• Generate reports and insights
• Improve app performance
• Backup your farm data (optional)
• Troubleshoot technical issues
              ''',
              isExpanded: _isExpanded2,
              onTap: () => setState(() => _isExpanded2 = !_isExpanded2),
            ),
            
            const SizedBox(height: 16),
            
            _buildExpandableSection(
              title: '3. Data Storage',
              content: '''
• All data stored locally on your device
• Optional cloud backup (encrypted)
• You control your data
• Export to CSV/PDF anytime
• Delete data permanently
              ''',
              isExpanded: _isExpanded3,
              onTap: () => setState(() => _isExpanded3 = !_isExpanded3),
            ),
            
            const SizedBox(height: 16),
            
            _buildExpandableSection(
              title: '4. Your Rights',
              content: '''
• Access your data anytime
• Export data in multiple formats
• Delete data permanently
• Opt-out of analytics
• Control backup settings
              ''',
              isExpanded: _isExpanded4,
              onTap: () => setState(() => _isExpanded4 = !_isExpanded4),
            ),
            
            const SizedBox(height: 16),
            
            _buildExpandableSection(
              title: '5. Security',
              content: '''
• Local data encryption
• Secure cloud storage (if enabled)
• Regular security updates
• No unauthorized access
• Your data stays private
              ''',
              isExpanded: _isExpanded5,
              onTap: () => setState(() => _isExpanded5 = !_isExpanded5),
            ),
            
            const SizedBox(height: 25),
            
            // Agreement Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[700],
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By using Goat Manager, you agree to this Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For development purposes only',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator(
                  icon: Icons.storage,
                  text: 'Local Storage',
                  isActive: true,
                ),
                _buildStatusIndicator(
                  icon: Icons.security,
                  text: 'Secured',
                  isActive: true,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String content,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF388E3C),
          ),
        ),
        leading: Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: const Color(0xFF4CAF50),
        ),
        trailing: const Icon(
          Icons.info_outline,
          color: Color(0xFF4CAF50),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        initiallyExpanded: false,
        onExpansionChanged: (expanded) => onTap(),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String text,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8F5E9) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF388E3C) : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}