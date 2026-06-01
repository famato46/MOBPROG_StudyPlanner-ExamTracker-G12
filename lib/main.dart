import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/planner_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  // Inizializzazione prima del runApp 
  WidgetsFlutterBinding.ensureInitialized();
  // Carica i dati di localizzazione per le date in italiano
  await initializeDateFormatting('it_IT', null);

  runApp(const StudyPlannerApp());
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlannerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'UniPath - Study Planner',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: const ColorScheme(
                brightness: Brightness.light,
                primary: AppColors.iosBlue,
                onPrimary: Colors.white,
                secondary: AppColors.pastelGreen,
                onSecondary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
                onSurfaceVariant: AppColors.textSecondary,
                error: AppColors.danger,
                onError: Colors.white,
                outline: AppColors.border,
                outlineVariant: AppColors.groupedDivider,
                surfaceContainerHighest: AppColors.groupedSurface,
                scrim: Colors.black,
                shadow: Colors.black,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            dividerColor: AppColors.groupedDivider,
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.15),
        ),
      ),
    ),
  ),
        darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.iosBlue,
        onPrimary: Colors.white,
        secondary: AppColors.pastelGreen,
        onSecondary: Colors.white,
        surface: Color(0xFF1C1C1E),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFAAAAAA),
        error: AppColors.danger,
        onError: Colors.white,
        outline: Color(0xFF3A3A3C),
        outlineVariant: Color(0xFF2C2C2E),
        surfaceContainerHighest: Color(0xFF2C2C2E),
        scrim: Colors.black,
        shadow: Colors.black,
    ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      dividerColor: const Color(0xFF3A3A3C),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}