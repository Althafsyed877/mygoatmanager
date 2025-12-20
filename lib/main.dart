import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:mygoatmanager/services/localization_service.dart';
import 'package:mygoatmanager/services/auth_service.dart';
import 'pages/homepage.dart';
import 'pages/auth_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _appLocale;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load locale
      final savedLocale = await LocalizationService.getSavedLocale();
      
      // Check auth
      bool authStatus = false;
      try {
        final authService = AuthService();
        authStatus = await authService.validateSession();
      } catch (e) {
        authStatus = false;
      }
      
      if (mounted) {
        setState(() {
          _appLocale = savedLocale ?? const Locale('en');
          _isAuthenticated = authStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appLocale = const Locale('en');
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  void _updateLocale(Locale newLocale) {
    if (mounted) {
      setState(() {
        _appLocale = newLocale;
      });
    }
    LocalizationService.saveLanguage(newLocale.languageCode, newLocale.countryCode ?? "");
  }

  // **ADD THIS METHOD** - To update auth state after login
  void _updateAuthState(bool isAuthenticated) {
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF4CAF50),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  'Starting Goat Manager...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _appLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('te'),
        Locale('hi'),
        Locale('ta'),
        Locale('kn'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: _isAuthenticated
          ? Homepage(
              currentLocale: _appLocale,
              onLocaleChanged: _updateLocale,
            )
          : AuthPage(
              // **PASS CALLBACK** - So auth page can update auth state
              onLoginSuccess: () {
                _updateAuthState(true);
              },
            ),
    );
  }
}