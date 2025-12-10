import 'package:flutter/material.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import 'package:mygoatmanager/pages/auth_page.dart';
import 'package:mygoatmanager/pages/events_page.dart';
import 'package:mygoatmanager/pages/farm_setup_page.dart';
import 'package:mygoatmanager/pages/reports_page.dart';
import 'package:mygoatmanager/pages/transactions_page.dart';
import 'package:mygoatmanager/pages/goats_page.dart';
import 'package:mygoatmanager/pages/milk_records_page.dart';
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
  String _selectedLanguageCode = 'en';
  
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
    
    // Repeat the animation
    _animationController.repeat(reverse: true);
  }

  // Load saved language from shared preferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    final savedLanguageCode = prefs.getString('selectedLanguageCode') ?? 'en';
    
    setState(() {
      _selectedLanguage = savedLanguage;
      _selectedLanguageCode = savedLanguageCode;
    });
    
    // If we have a saved language, update the app locale
    if (savedLanguageCode != 'en' && widget.onLocaleChanged != null) {
      widget.onLocaleChanged!(Locale(savedLanguageCode));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final padding = mediaQuery.padding;

    // Calculate responsive values based on screen size
    final isSmallPhone = screenWidth < 360;
    final isLargePhone = screenWidth >= 360 && screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu, 
            color: Colors.white, 
            size: isSmallPhone ? 20 : (isLargePhone ? 24 : 28)
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallPhone ? 16 : (isLargePhone ? 20 : 22),
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Language Icon
          IconButton(
            icon: Icon(
              Icons.language,
              color: Colors.white,
              size: isSmallPhone ? 20 : (isLargePhone ? 24 : 28),
            ),
            onPressed: _showLanguageSelector,
            tooltip: AppLocalizations.of(context)!.selectLanguage,
          ),
          
          // Animated Notification Bell Icon
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value,
                child: IconButton(
                  icon: Icon(
                    Icons.notifications, 
                    color: Colors.amber, 
                    size: isSmallPhone ? 20 : (isLargePhone ? 24 : 28)
                  ),
                  onPressed: _showNotifications,
                  tooltip: AppLocalizations.of(context)!.notifications,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSmallPhone ? 2 : 4),
          child: Container(
            height: isSmallPhone ? 2 : 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight - padding.top - padding.bottom;
              final availableWidth = constraints.maxWidth;

              return _buildResponsiveGrid(availableWidth, availableHeight);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncData,
        backgroundColor: const Color(0xFFFFA726),
        icon: Icon(
          Icons.sync, 
          color: Colors.white, 
          size: isSmallPhone ? 16 : 20
        ),
        label: Text(
          AppLocalizations.of(context)!.syncData,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallPhone ? 12 : (isLargePhone ? 14 : 16),
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
                color: Colors.black.withValues(alpha: 0.2),
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
                    Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.selectLanguage,
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
                      color: isSelected ? const Color(0xFF4CAF50).withValues(alpha: 0.1) : Colors.grey[100],
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
                        languageData['nativeName']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? const Color(0xFF4CAF50).withValues(alpha: 0.8) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: const Color(0xFF4CAF50),
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    _changeLanguage(languageName, languageData['code']!);
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
                      AppLocalizations.of(context)!.cancel,
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
    // Save language preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageName);
    await prefs.setString('selectedLanguageCode', languageCode);
    
    setState(() {
      _selectedLanguage = languageName;
      _selectedLanguageCode = languageCode;
    });
    
    // Create a Locale object
    final newLocale = Locale(languageCode);
    
    // Notify parent to change locale
    if (widget.onLocaleChanged != null) {
      widget.onLocaleChanged!(newLocale);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context)!.languageChangedTo} $languageName'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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

  Widget _buildResponsiveGrid(double availableWidth, double availableHeight) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    int crossAxisCount;
    double childAspectRatio;
    EdgeInsets padding;
    double spacing;

    if (screenWidth < 360) {
      crossAxisCount = 2;
      childAspectRatio = 0.7;
      padding = const EdgeInsets.all(8.0);
      spacing = 6.0;
    } else if (screenWidth < 400) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
      padding = const EdgeInsets.all(10.0);
      spacing = 8.0;
    } else if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.8;
      padding = const EdgeInsets.all(12.0);
      spacing = 10.0;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.9;
      padding = const EdgeInsets.all(16.0);
      spacing = 12.0;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 1.0;
      padding = const EdgeInsets.all(20.0);
      spacing = 16.0;
    }

    return Padding(
      padding: padding,
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMenuCard(context, AppLocalizations.of(context)!.goats, 'assets/images/goat.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GoatsPage()));
          }),
          _buildMenuCard(context, AppLocalizations.of(context)!.milkRecords, 'assets/images/milk.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MilkRecordsPage()));
          }),
          _buildMenuCard(context, AppLocalizations.of(context)!.events, 'assets/images/events.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsPage()));
          }),
          _buildMenuCard(context, AppLocalizations.of(context)!.transactions, 'assets/images/transactions.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage()));
          }),
          _buildMenuCard(context, AppLocalizations.of(context)!.farmSetup, 'assets/images/farm_setup.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FarmSetupPage()));
          }),
          _buildMenuCard(context, AppLocalizations.of(context)!.reports, 'assets/images/reports.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    final isSmallPhone = screenWidth < 360;
    final isLargePhone = screenWidth >= 360 && screenWidth < 600;
    final isTablet = screenWidth >= 600;

    return Drawer(
      width: screenWidth * (isSmallPhone ? 0.85 : (isLargePhone ? 0.8 : 0.75)),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: isSmallPhone ? 140 : (isLargePhone ? 160 : 180),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallPhone ? 10.0 : (isLargePhone ? 12.0 : 16.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isSmallPhone ? 12 : (isLargePhone ? 15 : 20)),
                  Text(
                    AppLocalizations.of(context)!.createYourFarmAccount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallPhone ? 13 : (isLargePhone ? 15 : 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isSmallPhone ? 6 : (isLargePhone ? 8 : 10)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: isSmallPhone ? 32 : (isLargePhone ? 36 : 40),
                      height: isSmallPhone ? 32 : (isLargePhone ? 36 : 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: const Color(0xFF4CAF50),
                        size: isSmallPhone ? 18 : (isLargePhone ? 20 : 24),
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.loginOrCreateAccount,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallPhone ? 11 : (isLargePhone ? 13 : 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToAuthPage();
                    },
                  ),
                ],
              ),
            ),
          ),

          _buildDrawerSection(
            title: AppLocalizations.of(context)!.upgradeAndAccount,
            isSmallPhone: isSmallPhone,
            isLargePhone: isLargePhone,
            children: [
              _buildDrawerItem(
                icon: Icons.workspace_premium,
                title: AppLocalizations.of(context)!.createYourFarmAccount,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAuthPage();
                },
              ),
              _buildDrawerItem(
                icon: Icons.login,
                title: AppLocalizations.of(context)!.loginOrCreateAccount,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAuthPage();
                },
              ),
            ],
          ),

          _buildDrawerSection(
            title: AppLocalizations.of(context)!.appAndFarmTools,
            isSmallPhone: isSmallPhone,
            isLargePhone: isLargePhone,
            children: [
              _buildDrawerItem(
                icon: Icons.settings,
                title: AppLocalizations.of(context)!.settings,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.note,
                title: AppLocalizations.of(context)!.farmNotes,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.apps,
                title: AppLocalizations.of(context)!.seeAllOurApps,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.school,
                title: AppLocalizations.of(context)!.farmingKnowledge,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
            ],
          ),

          _buildDrawerSection(
            title: AppLocalizations.of(context)!.helpAndSupport,
            isSmallPhone: isSmallPhone,
            isLargePhone: isLargePhone,
            children: [
              _buildDrawerItem(
                icon: Icons.help_outline,
                title: AppLocalizations.of(context)!.howToUseThisApp,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
              _buildDrawerItem(
                icon: Icons.contact_support,
                title: AppLocalizations.of(context)!.contactOurTeam,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
            ],
          ),

          _buildDrawerSection(
            title: AppLocalizations.of(context)!.shareAndRecommend,
            isSmallPhone: isSmallPhone,
            isLargePhone: isLargePhone,
            children: [
              _buildDrawerItem(
                icon: Icons.share,
                title: AppLocalizations.of(context)!.shareAppWithFriends,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: _shareApp,
              ),
              _buildDrawerItem(
                icon: Icons.star,
                title: AppLocalizations.of(context)!.rateAppInPlayStore,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: _rateApp,
              ),
            ],
          ),

          _buildDrawerSection(
            title: AppLocalizations.of(context)!.legal,
            isSmallPhone: isSmallPhone,
            isLargePhone: isLargePhone,
            children: [
              _buildDrawerItem(
                icon: Icons.privacy_tip,
                title: AppLocalizations.of(context)!.privacyPolicy,
                isSmallPhone: isSmallPhone,
                isLargePhone: isLargePhone,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar();
                },
              ),
            ],
          ),

          SizedBox(height: isSmallPhone ? 12 : (isLargePhone ? 16 : 20)),
        ],
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required bool isSmallPhone,
    required bool isLargePhone,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallPhone ? 10 : (isLargePhone ? 12 : 16), 
            isSmallPhone ? 12 : (isLargePhone ? 15 : 20), 
            isSmallPhone ? 10 : (isLargePhone ? 12 : 16), 
            isSmallPhone ? 6 : (isLargePhone ? 8 : 10)
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isSmallPhone ? 13 : (isLargePhone ? 15 : 16),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF424242),
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
    required bool isSmallPhone,
    required bool isLargePhone,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF4CAF50),
        size: isSmallPhone ? 18 : (isLargePhone ? 20 : 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSmallPhone ? 12 : (isLargePhone ? 14 : 16),
          color: const Color(0xFF424242),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 10 : (isLargePhone ? 12 : 16)
      ),
      minLeadingWidth: 0,
      dense: isSmallPhone,
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    final isSmallPhone = screenWidth < 360;
    final isLargePhone = screenWidth >= 360 && screenWidth < 600;
    final isTablet = screenWidth >= 600;

    return Card(
      elevation: isSmallPhone ? 3 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallPhone ? 10 : (isLargePhone ? 15 : 20)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isSmallPhone ? 10 : (isLargePhone ? 15 : 20)),
        splashColor: const Color(0xFF4CAF50).withOpacity(0.2),
        highlightColor: const Color(0xFF4CAF50).withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.all(isSmallPhone ? 6 : (isLargePhone ? 10 : 16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallPhone ? 10 : (isLargePhone ? 15 : 20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isSmallPhone ? 50 : (isLargePhone ? 80 : 120),
                height: isSmallPhone ? 50 : (isLargePhone ? 80 : 120),
                padding: EdgeInsets.all(isSmallPhone ? 4 : (isLargePhone ? 8 : 16)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(isSmallPhone ? 6 : (isLargePhone ? 10 : 16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: isSmallPhone ? 2 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      size: isSmallPhone ? 20 : (isLargePhone ? 30 : 60),
                      color: Colors.grey,
                    );
                  },
                ),
              ),
              SizedBox(height: isSmallPhone ? 4 : (isLargePhone ? 8 : 16)),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallPhone ? 10 : (isLargePhone ? 14 : 18),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF424242),
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
                AppLocalizations.of(context)!.notifications,
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
                AppLocalizations.of(context)!.noNewNotifications,
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

  void _syncData() async {
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
                AppLocalizations.of(context)!.syncingData,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.dataSyncedSuccessfully,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _shareApp() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Share app functionality coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _rateApp() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Rate app functionality coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Feature coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}