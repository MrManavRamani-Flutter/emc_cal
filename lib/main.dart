import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/app_theme.dart';
import 'providers/production_provider.dart';
import 'screens/main_layout.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for Windows desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const EmbroideryCalculatorApp());
}

class EmbroideryCalculatorApp extends StatelessWidget {
  final bool skipSplash;
  const EmbroideryCalculatorApp({super.key, this.skipSplash = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductionProvider()),
      ],
      child: Consumer<ProductionProvider>(
        builder: (context, provider, child) {
          final isDark = provider.settings.isDarkMode;
          final accent = AppTheme.parseColor(provider.settings.themeColorHex);

            return MaterialApp(
              title: 'OM MAVTAR GROUP',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getTheme(isDark: false, accentColor: accent),
              darkTheme: AppTheme.getTheme(isDark: true, accentColor: accent),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(provider.settings.fontScale),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: skipSplash ? const MainLayout() : const SplashScreen(),
            );
        },
      ),
    );
  }
}
