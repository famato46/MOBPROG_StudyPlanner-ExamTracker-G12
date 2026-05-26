import 'package:flutter/material.dart';

/// Palette centralizzata di UniPath.
/// Un colore pastello per sezione, su base neutra calda.
/// Tutte le schermate leggono i colori da qui per garantire coerenza.
class AppColors {
  AppColors._(); // Costruttore privato: la classe è solo un contenitore di costanti

  // ─── Base neutra ──────────────────────────────────────────────
  static const Color background = Color(0xFFFBFBF9); // sfondo app (bianco caldo)
  static const Color surface = Color(0xFFFFFFFF);    // card
  static const Color textPrimary = Color(0xFF2C2C2A); // testo principale (non nero)
  static const Color textMuted = Color(0xFF888780);   // testo secondario

  // ─── Colori per sezione ───────────────────────────────────────
  // Ogni sezione ha: tinta piena (per icone/accenti) e tinta chiara (per sfondi)

  // Home — Lavanda
  static const Color home = Color(0xFF7F77DD);
  static const Color homeLight = Color(0xFFEEEDFE);
  static const Color homeDark = Color(0xFF3C3489);

  // Corsi — Menta
  static const Color courses = Color(0xFF1D9E75);
  static const Color coursesLight = Color(0xFFE1F5EE);
  static const Color coursesDark = Color(0xFF085041);

  // Esami — Rosa
  static const Color exams = Color(0xFFD4537E);
  static const Color examsLight = Color(0xFFFBEAF0);
  static const Color examsDark = Color(0xFF72243E);

  // Pianifica — Ambra
  static const Color planning = Color(0xFFEF9F27);
  static const Color planningLight = Color(0xFFFAEEDA);
  static const Color planningDark = Color(0xFF633806);

  // Stats — Azzurro
  static const Color stats = Color(0xFF378ADD);
  static const Color statsLight = Color(0xFFE6F1FB);
  static const Color statsDark = Color(0xFF0C447C);

  // ─── Colori semantici (stati, priorità) ──────────────────────
  static const Color success = Color(0xFF1D9E75); // verde (superato/completato)
  static const Color warning = Color(0xFFEF9F27); // ambra (da ripassare)
  static const Color danger = Color(0xFFE24B4A);  // rosso (urgente/scaduto)
  static const Color info = Color(0xFF378ADD);    // azzurro (in corso)

  // ─── Colore dei riquadrini header (titoli sezione) ───────────
  // Cambia QUI per cambiare il colore di TUTTI i riquadrini dell'app
  static const Color headerBg = Color(0xFFF1EFE8);   // sfondo riquadro (grigio neutro chiaro)
  static const Color headerText = Color(0xFF444441);  // testo + icona (grigio scuro)

  // ─── Helper: colore per priorità ──────────────────────────────
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

  // ─── Helper: colore per stato corso ───────────────────────────
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