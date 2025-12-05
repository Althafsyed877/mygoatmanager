import 'package:flutter/material.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mygoatmanager/services/localization_service.dart';
import 'pages/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedLocale = await LocalizationService.getSavedLocale();

  runApp(MyApp(savedLocale: savedLocale));
}

class MyApp extends StatefulWidget {
  final Locale? savedLocale;
  const MyApp({super.key, this.savedLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _appLocale;

  @override
  void initState() {
    super.initState();
    _appLocale = widget.savedLocale ?? const Locale('en');
  }

  void _updateLocale(Locale newLocale) {
    setState(() {
      _appLocale = newLocale;
    });
    LocalizationService.saveLanguage(newLocale.languageCode, newLocale.countryCode ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      key: ValueKey(_appLocale?.languageCode ?? 'en'),
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
      home: Homepage(
        currentLocale: _appLocale,
        onLocaleChanged: _updateLocale,
      ),
    );
  }
}
