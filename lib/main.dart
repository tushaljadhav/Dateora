import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/items_provider.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'screens/splash_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    firebaseAvailable = true;
  } catch (e) {
    debugPrint('Firebase initialization warning (safe fallback if google-services.json is absent): $e');
  }

  // Analytics initialization
  try {
    final prefs = await SharedPreferences.getInstance();
    final analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
    AnalyticsService.instance.initialize(
      isFirebaseAvailable: firebaseAvailable,
      enabled: analyticsEnabled,
    );
  } catch (_) {}

  try {
    await NotificationService.instance.initialize();
  } catch (_) {}

  runApp(const DateoraApp());
}

class DateoraApp extends StatelessWidget {
  const DateoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()..loadItems()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Dateora',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
