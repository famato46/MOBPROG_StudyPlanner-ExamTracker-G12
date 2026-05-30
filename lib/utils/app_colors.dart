import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base neutra (Apple-like)
  static const Color background = Color(0xFFF5F4F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6B6B70);
  static const Color textMuted = Color(0xFF9B9B9F);
  static const Color border = Color(0xFFE5E5E1);

  // Background grouped (iOS Settings style) 
  /// Sfondo gruppi nei form/dettagli (tipo Settings iOS, leggermente
  /// più scuro del background generale).
  static const Color groupedBackground = Color(0xFFF2F2F7);

  /// Sfondo singolo gruppo (card grigio molto chiaro).
  static const Color groupedSurface = Color(0xFFFFFFFF);

  /// Separatore tra righe dentro un gruppo.
  static const Color groupedDivider = Color(0xFFE5E5EA);

  // Pastelli ufficiali della Dashboard 
  static const Color pastelRed = Color(0xFFFF8B9C);
  static const Color pastelRedDeep = Color(0xFFD14A60);
  static const Color pastelRedLight = Color(0xFFFFE5EA);

  static const Color pastelBlue = Color(0xFF8CCCFD);
  static const Color pastelBlueDeep = Color(0xFF2980C7);
  static const Color pastelBlueLight = Color(0xFFE3F2FE);

  static const Color pastelGreen = Color(0xFF90E891);
  static const Color pastelGreenDeep = Color(0xFF2F9E54);
  static const Color pastelGreenLight = Color(0xFFE5F8E6);

  static const Color pastelYellow = Color(0xFFFFEE8E);
  static const Color pastelYellowDeep = Color(0xFFB58F00);
  static const Color pastelYellowLight = Color(0xFFFFF8DC);

  static const Color pastelLavender = Color(0xFFB8B0E8);
  static const Color pastelLavenderDeep = Color(0xFF6C5BC9);
  static const Color pastelLavenderLight = Color(0xFFEEEDFE);

  // Alias semantici per sezione 
  static const Color home = pastelLavender;
  static const Color homeDeep = pastelLavenderDeep;
  static const Color homeLight = pastelLavenderLight;

  static const Color courses = pastelRed;
  static const Color coursesDeep = pastelRedDeep;
  static const Color coursesDark = pastelRedDeep;
  static const Color coursesLight = pastelRedLight;

  static const Color exams = pastelBlue;
  static const Color examsDeep = pastelBlueDeep;
  static const Color examsDark = pastelBlueDeep;
  static const Color examsLight = pastelBlueLight;

  static const Color planning = pastelGreen;
  static const Color planningDeep = pastelGreenDeep;
  static const Color planningDark = pastelGreenDeep;
  static const Color planningLight = pastelGreenLight;

  static const Color stats = pastelYellow;
  static const Color statsDeep = pastelYellowDeep;
  static const Color statsDark = pastelYellowDeep;
  static const Color statsLight = pastelYellowLight;

  // Colori sistema iOS 
  /// Blu di sistema iOS — usato per la tab bar selezionata e per i
  /// link/CTA testuali tipici di iOS (es. "Salva").
  static const Color iosBlue = Color(0xFF007AFF);

  // Colori semantici 
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color danger = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Header riquadrati 
  static const Color headerBg = Color(0xFFF1EFE8);
  static const Color headerText = Color(0xFF444441);

  // Helper: colore per priorità 
  static Color priorita(String p) {
    switch (p) {
      case 'alta':
        return danger;
      case 'media':
        return warning;
      case 'bassa':
        return success;
      default:
        return textMuted;
    }
  }

  // Helper: colore per stato corso 
  static Color statoCorso(String s) {
    switch (s) {
      case 'superato':
        return success;
      case 'in_corso':
        return info;
      case 'da_ripassare':
        return warning;
      case 'completato':
        return courses;
      default:
        return textMuted;
    }
  }
}