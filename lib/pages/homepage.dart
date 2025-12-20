import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import 'package:mygoatmanager/pages/auth_page.dart';
import 'package:mygoatmanager/pages/events_page.dart';
import 'package:mygoatmanager/pages/transactions_page.dart';
import 'package:mygoatmanager/pages/farm_setup_page.dart';
import 'package:mygoatmanager/pages/reports_page.dart';
import 'package:mygoatmanager/pages/goats_page.dart';
import 'package:mygoatmanager/pages/milk_records_page.dart';
import 'package:mygoatmanager/services/api_service.dart';
import 'package:mygoatmanager/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  final Locale? currentLocale;
  
  const Homepage({
    super.key,
    this.onLocaleChanged,
    this.currentLocale,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Current selected language
  String _selectedLanguage = 'English';
  
  // User data
  String? userEmail;
  
  // Language data
  final Map<String, Map<String, String>> _languages = {
    'English': {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
    },
    'Telugu': {
      'code': 'te',
      'name': 'Telugu',
      'nativeName': 'తెలుగు',
    },
    'Hindi': {
      'code': 'hi',
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
    },
    'Tamil': {
      'code': 'ta',
      'name': 'Tamil',
      'nativeName': 'தமிழ்',
    },
    'Kannada': {
      'code': 'kn',
      'name': 'Kannada',
      'nativeName': 'ಕನ್ನಡ',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Load saved language
    _loadSavedLanguage();
    
    // Load user data
    _loadUserData();
    
    // Download latest data from server after login
    _downloadDataFromServer();
    
    // Repeat the animation
    _animationController.repeat(reverse: true);
  }

  // Load saved language from shared preferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      
      setState(() {
        _selectedLanguage = savedLanguage;
      });
      
      // If we have a saved language, update the app locale
      final savedLanguageCode = prefs.getString('selectedLanguageCode') ?? 'en';
      if (savedLanguageCode != 'en' && widget.onLocaleChanged != null) {
        widget.onLocaleChanged!(Locale(savedLanguageCode));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading saved language: $e');
    }
  }

  // Load user data
  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      if (userData != null && userData['email'] != null) {
        setState(() {
          userEmail = userData['email'].toString();
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get localizations with null check
    final appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu, 
            color: Colors.white, 
            size: 24,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          appLocalizations?.appTitle ?? 'Goat Manager',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Language Icon
          IconButton(
            icon: const Icon(
              Icons.language,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _showLanguageSelector,
            tooltip: appLocalizations?.selectLanguage ?? 'Select Language',
          ),
          
          // Animated Notification Bell Icon
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value,
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications, 
                    color: Colors.amber, 
                    size: 24,
                  ),
                  onPressed: _showNotifications,
                  tooltip: appLocalizations?.notifications ?? 'Notifications',
                ),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context, appLocalizations),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
          ),
        ),
        child: SafeArea(
          child: _buildResponsiveGrid(context, appLocalizations),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncData,
        backgroundColor: const Color(0xFFFFA726),
        icon: const Icon(
          Icons.sync, 
          color: Colors.white, 
          size: 20,
        ),
        label: Text(
          appLocalizations?.syncData ?? 'Sync Data',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Method to navigate to auth page
  void _navigateToAuthPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthPage(),
      ),
    );
  }

  // Method to show language selector
  void _showLanguageSelector() {
    final appLocalizations = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      appLocalizations?.selectLanguage ?? 'Select Language',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Language List
              ..._languages.entries.map((entry) {
                final languageName = entry.key;
                final languageData = entry.value;
                final isSelected = _selectedLanguage == languageName;
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getLanguageFlag(languageName),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? const Color(0xFF4CAF50) : Colors.black,
                        ),
                      ),
                      Text(
                        languageData['nativeName'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.8) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    _changeLanguage(languageName, languageData['code'] ?? 'en');
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              
              // Cancel Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      appLocalizations?.cancel ?? 'Cancel',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to change language
  void _changeLanguage(String languageName, String languageCode) async {
    try {
      // Save language preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', languageName);
      await prefs.setString('selectedLanguageCode', languageCode);
      
      setState(() {
        _selectedLanguage = languageName;
      });
      
      // Create a Locale object
      final newLocale = Locale(languageCode);
      
      // Notify parent to change locale
      if (widget.onLocaleChanged != null) {
        widget.onLocaleChanged?.call(newLocale);
      }
      
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appLocalizations?.languageChangedTo ?? 'Language changed to'} $languageName'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error changing language: $e');
    }
  }

  // Helper method to get language flag emoji
  String _getLanguageFlag(String language) {
    switch (language) {
      case 'English':
        return '🇺🇸';
      case 'Telugu':
        return '🇮🇳';
      case 'Hindi':
        return '🇮🇳';
      case 'Tamil':
        return '🇮🇳';
      case 'Kannada':
        return '🇮🇳';
      default:
        return '🌐';
    }
  }

  Widget _buildResponsiveGrid(BuildContext context, AppLocalizations? appLocalizations) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.8,
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildMenuCard(
          context, 
          appLocalizations?.goats ?? 'Goats', 
          'assets/images/goat.png', 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GoatsPage()));
          }
        ),
        _buildMenuCard(
          context, 
          appLocalizations?.milkRecords ?? 'Milk Records', 
          'assets/images/milk.png', 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MilkRecordsPage()));
          }
        ),
        _buildMenuCard(
          context, 
          appLocalizations?.events ?? 'Events', 
          'assets/images/events.png', 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsPage()));
          }
        ),
        _buildMenuCard(
          context, 
          appLocalizations?.transactions ?? 'Transactions', 
          'assets/images/transactions.png', 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage()));
          }
        ),
        _buildMenuCard(
          context, 
          appLocalizations?.farmSetup ?? 'Farm Setup', 
          'assets/images/farm_setup.png', 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FarmSetupPage()));
          }
        ),
        _buildMenuCard(
          context, 
          appLocalizations?.reports ?? 'Reports', 
          'assets/images/reports.png', 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsPage()));
          }
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations? appLocalizations) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    appLocalizations?.createYourFarmAccount ?? 'Create Your Farm Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (userEmail == null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        appLocalizations?.loginOrCreateAccount ?? 'Login or Create Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToAuthPage();
                      },
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        userEmail!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          _buildDrawerSection(
            title: appLocalizations?.upgradeAndAccount ?? 'Upgrade & Account',
            children: [
              _buildDrawerItem(
                icon: Icons.workspace_premium,
                title: appLocalizations?.createYourFarmAccount ?? 'Create Your Farm Account',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAuthPage();
                },
              ),
              if (userEmail == null)
                _buildDrawerItem(
                  icon: Icons.login,
                  title: appLocalizations?.loginOrCreateAccount ?? 'Login or Create Account',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAuthPage();
                  },
                )
              else
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        userEmail!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: AppLocalizations.of(context)?.logout ?? 'Logout', 
                      onTap: _logoutUser,
                    ),
                  ],
                ),
            ],
          ),

          _buildDrawerSection(
            title: appLocalizations?.appAndFarmTools ?? 'App & Farm Tools',
            children: [
              _buildDrawerItem(
                icon: Icons.settings,
                title: appLocalizations?.settings ?? 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.note,
                title: appLocalizations?.farmNotes ?? 'Farm Notes',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.apps,
                title: appLocalizations?.seeAllOurApps ?? 'See All Our Apps',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.school,
                title: appLocalizations?.farmingKnowledge ?? 'Farming Knowledge',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
            ],
          ),

          _buildDrawerSection(
            title: appLocalizations?.helpAndSupport ?? 'Help & Support',
            children: [
              _buildDrawerItem(
                icon: Icons.help_outline,
                title: appLocalizations?.howToUseThisApp ?? 'How to Use This App',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.contact_support,
                title: appLocalizations?.contactOurTeam ?? 'Contact Our Team',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
            ],
          ),

          _buildDrawerSection(
            title: appLocalizations?.shareAndRecommend ?? 'Share & Recommend',
            children: [
              _buildDrawerItem(
                icon: Icons.share,
                title: appLocalizations?.shareAppWithFriends ?? 'Share App with Friends',
                onTap: _shareApp,
              ),
              _buildDrawerItem(
                icon: Icons.star,
                title: appLocalizations?.rateAppInPlayStore ?? 'Rate App in Play Store',
                onTap: _rateApp,
              ),
            ],
          ),

          _buildDrawerSection(
            title: appLocalizations?.legal ?? 'Legal',
            children: [
              _buildDrawerItem(
                icon: Icons.privacy_tip,
                title: appLocalizations?.privacyPolicy ?? 'Privacy Policy',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF4CAF50),
        size: 20,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF424242),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: const Color(0xFF4CAF50).withOpacity(0.2),
        highlightColor: const Color(0xFF4CAF50).withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 30,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    final appLocalizations = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizations?.notifications ?? 'Notifications',
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 16),
              Icon(
                Icons.notifications_none,
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizations?.noNewNotifications ?? 'No new notifications',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('OK'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _syncData() async {
    try {
      final appLocalizations = AppLocalizations.of(context);
      
      // Show loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appLocalizations?.syncingData ?? 'Syncing data...',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 30),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final apiService = ApiService();
      bool hasErrors = false;
      String errorMessage = '';

      // 1. Sync Goats
      try {
        final goatsData = prefs.getString('goats');
        if (goatsData != null) {
          final List<dynamic> goatsJson = jsonDecode(goatsData);
          final List<Map<String, dynamic>> goats = goatsJson.map((e) => Map<String, dynamic>.from(e)).toList();
          if (goats.isNotEmpty) {
            final response = await apiService.syncGoats(goats);
            if (!response.success) {
              hasErrors = true;
              errorMessage += 'Goats sync failed: ${response.message}\n';
            }
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Goats sync error: $e\n';
      }

      // 2. Sync Events
      try {
        final eventsData = prefs.getString('events');
        if (eventsData != null) {
          final List<dynamic> eventsJson = jsonDecode(eventsData);
          final List<Map<String, dynamic>> events = eventsJson.map((e) => Map<String, dynamic>.from(e)).toList();
          if (events.isNotEmpty) {
            final response = await apiService.syncEvents(events);
            if (!response.success) {
              hasErrors = true;
              errorMessage += 'Events sync failed: ${response.message}\n';
            }
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Events sync error: $e\n';
      }

      // 3. Sync Milk Records
      try {
        final milkRecordsData = prefs.getString('milk_records');
        if (milkRecordsData != null) {
          final List<dynamic> milkRecordsJson = jsonDecode(milkRecordsData);
          final List<Map<String, dynamic>> milkRecords = milkRecordsJson.map((e) => Map<String, dynamic>.from(e)).toList();
          if (milkRecords.isNotEmpty) {
            final response = await apiService.syncMilkRecords(milkRecords);
            if (!response.success) {
              hasErrors = true;
              errorMessage += 'Milk records sync failed: ${response.message}\n';
            }
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Milk records sync error: $e\n';
      }

      // 4. Sync Transactions
      try {
        final incomesData = prefs.getString('saved_incomes');
        final expensesData = prefs.getString('saved_expenses');
        
        List<Map<String, dynamic>> incomes = [];
        List<Map<String, dynamic>> expenses = [];
        
        if (incomesData != null) {
          final List<dynamic> incomesJson = jsonDecode(incomesData);
          incomes = incomesJson.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        if (expensesData != null) {
          final List<dynamic> expensesJson = jsonDecode(expensesData);
          expenses = expensesJson.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        if (incomes.isNotEmpty || expenses.isNotEmpty) {
          final response = await apiService.syncTransactions(incomes, expenses);
          if (!response.success) {
            hasErrors = true;
            errorMessage += 'Transactions sync failed: ${response.message}\n';
          }
        }
      } catch (e) {
        hasErrors = true;
        errorMessage += 'Transactions sync error: $e\n';
      }

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Show result
      if (hasErrors) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${appLocalizations?.syncCompletedWithErrors ?? 'Sync completed with errors'}:\n$errorMessage',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      appLocalizations?.dataSyncedSuccessfully ?? 'Data synced successfully',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)?.syncFailed ?? 'Sync failed'}: $e',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Download/sync data from server (called after login)
  Future<void> _downloadDataFromServer() async {
    try {
      final apiService = ApiService();
      final response = await apiService.downloadAllData();
      
      if (response.success && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        final data = response.data!;
        
        // Save downloaded data to local storage
        if (data['goats'] != null) {
          await prefs.setString('goats', jsonEncode(data['goats']));
        }
        if (data['events'] != null) {
          await prefs.setString('events', jsonEncode(data['events']));
        }
        if (data['milk_records'] != null) {
          await prefs.setString('milk_records', jsonEncode(data['milk_records']));
        }
        if (data['incomes'] != null) {
          await prefs.setString('saved_incomes', jsonEncode(data['incomes']));
        }
        if (data['expenses'] != null) {
          await prefs.setString('saved_expenses', jsonEncode(data['expenses']));
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Data downloaded from server successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Download error: $e');
    }
  }

 Future<void> _logoutUser() async {
  try {
    // Close drawer
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Clear auth
    final authService = AuthService();
    await authService.logout();
    
    // **Use MaterialPageRoute instead of named routes**
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (route) => false,
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
  void _shareApp() {
    Navigator.pop(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.share, color: Colors.white),
              SizedBox(width: 8),
              Text('Share app functionality coming soon!'),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _rateApp() {
    Navigator.pop(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.star, color: Colors.white),
              SizedBox(width: 8),
              Text('Rate app functionality coming soon!'),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showComingSoonSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Feature coming soon!'),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}