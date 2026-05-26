import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigaVersoHome();
  }

  _navigaVersoHome() async {
    await Future.delayed(const Duration(milliseconds: 2500), () {});
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/UniPath_ICON.png',
              width: 130,
              height: 130,
            ),
            const SizedBox(height: 24),
            const Text(
              'UniPath',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Study Planner & Exam Tracker',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              color: AppColors.home,
            ),
          ],
        ),
      ),
    );
  }
}