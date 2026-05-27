import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/planner_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';

void main() {
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
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.home,
                brightness: Brightness.light,
                surface: AppColors.surface,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.background,
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
                    color: AppColors.textMuted.withOpacity(0.15),
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.home,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
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
            // Qui forziamo la larghezza massima dell'intera app
            builder: (context, child) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: child!,
                ),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}