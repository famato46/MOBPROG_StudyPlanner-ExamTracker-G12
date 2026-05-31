import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ThemeProvider - Gestisce il tema (Light e Dark Mode)
// Usa SharedPreferences per mantenere la scelta dell'utente
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Costruttore: carica il tema salvato all'avvio
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Carica il tema salvato da SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Toggle tra Light e Dark Mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;

    // Salva la preferenza
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);

    notifyListeners();
  }

  // Per impostare manualmente il tema
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;

    _isDarkMode = isDark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);

    notifyListeners();
  }
}
