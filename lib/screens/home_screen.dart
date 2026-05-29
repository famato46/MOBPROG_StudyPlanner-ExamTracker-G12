import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam.dart';
import '../providers/planner_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

/// HomeScreen — Dashboard Apple-style.
///
/// Layout:
///  1. Large title "Dashboard" + sottotitolo + avatar profilo
///  2. Grid 2x2 di stat card pastello (Corsi, Esami, Attività, CFU)
///  3. Flashcard Motivazionale (Spunto del Giorno)
///  4. Card prossimo esame con countdown
///  5. Lista suggerimenti automatici (dal Provider)
class HomeScreen extends StatelessWidget {
  /// Callback per cambiare tab nella BottomNavigationBar del MainScreen.
  /// Permette alle card della dashboard di portare alle sezioni:
  /// 1 = Corsi, 2 = Esami, 3 = Pianifica, 4 = Stats.
  final void Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          // ── Calcolo dati dinamici per il prossimo esame ────────
          final prossimoEsame = _findProssimoEsame(provider);
          final suggerimentiUnici =
              provider.suggerimentiAutomatici.toSet().toList();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                _HeaderSection(isDark: isDark),
                const SizedBox(height: 28),
                _StatGrid(
                  provider: provider,
                  isDark: isDark,
                  onNavigateToTab: onNavigateToTab,
                ),
                const SizedBox(height: 28),

                // ─── NUOVA FEATURE: FLASHCARD MOTIVAZIONALE ───────────
                _SectionLabel(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Spunto del giorno',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                const MotivationalFlashcard(),
                const SizedBox(height: 28),
                // ──────────────────────────────────────────────────────

                if (prossimoEsame != null) ...[
                  _SectionLabel(
                    icon: Icons.timer_outlined,
                    label: "Prossimo obiettivo d'esame",
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _NextExamCard(exam: prossimoEsame, isDark: isDark),
                  const SizedBox(height: 28),
                ],
                if (suggerimentiUnici.isNotEmpty) ...[
                  _SectionLabel(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Suggerimenti per te',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  ...suggerimentiUnici.map(
                    (s) => _SuggestionTile(text: s, isDark: isDark),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Trova il prossimo esame in ordine cronologico (oggi o futuro,
  /// stato 'programmato').
  Exam? _findProssimoEsame(PlannerProvider provider) {
    if (provider.exams.isEmpty) return null;
    final oggi = DateTime.now();
    final futuri = provider.exams
        .where((e) =>
            e.stato == 'programmato' &&
            (e.data.isAfter(oggi) || DateUtils.isSameDay(e.data, oggi)))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    return futuri.isEmpty ? null : futuri.first;
  }
}

// ═══════════════════════════════════════════════════════════════
// MOTIVATIONAL FLASHCARD
// ═══════════════════════════════════════════════════════════════
class MotivationalFlashcard extends StatefulWidget {
  const MotivationalFlashcard({super.key});

  @override
  State<MotivationalFlashcard> createState() => _MotivationalFlashcardState();
}

class _MotivationalFlashcardState extends State<MotivationalFlashcard> {
  bool _flipped = false;
  late final String _front;
  late final String _back;

  @override
  void initState() {
    super.initState();
    // Lista di frasi motivazionali hardcoded (NO EMOJI)
    final pairs = [
      (
        "Qual e' il segreto per superare questo esame difficile?",
        "La costanza. Un piccolo passo ogni giorno ti portera' al successo. Inizia ora!"
      ),
      (
        "Ti senti bloccato su un argomento?",
        "Fai una pausa, respira profondo e riparti dalle basi. Nessun concetto e' impossibile da capire."
      ),
      (
        "Perche' studiare proprio oggi?",
        "Perche' lo studio di oggi costruisce la liberta' del tuo domani. Continua a investire in te stesso."
      ),
      (
        "La stanchezza si fa sentire?",
        "Ricorda perche' hai iniziato. Ogni pagina letta ti avvicina al traguardo della laurea."
      ),
      (
        "Hai paura di non farcela?",
        "Il fallimento fa parte del percorso. Affronta l'esame con coraggio, hai tutte le capacita' per superarlo."
      ),
      (
        "Ti sembra di non ricordare nulla?",
        "E' normale. Ripeti a voce alta o spiega il concetto a qualcun altro, vedrai che i pezzi si incastreranno."
      ),
    ];

    // Selezione random al caricamento della schermata
    final random = Random();
    final selectedPair = pairs[random.nextInt(pairs.length)];
    _front = selectedPair.$1;
    _back = selectedPair.$2;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colori Apple-style coerenti con la nostra palette AppColors
    final frontBg = isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface;
    final backBg = AppColors.pastelBlueDeep;

    final bgColor = _flipped ? backBg : frontBg;
    final borderColor = _flipped
        ? Colors.transparent
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border);
    final textColor = _flipped
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);
    final hintColor = _flipped ? Colors.white70 : AppColors.textMuted;
    final labelColor = _flipped ? Colors.white70 : AppColors.pastelBlueDeep;

    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 180, // Altezza compatta e proporzionata
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (!isDark && !_flipped)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Etichetta in alto a sinistra
            Positioned(
              top: 16,
              left: 20,
              child: Text(
                _flipped ? 'MOTIVAZIONE' : 'SPUNTO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: labelColor,
                ),
              ),
            ),
            // Testo centrale
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Text(
                  _flipped ? _back : _front,
                  style: TextStyle(
                    fontSize: _flipped ? 15 : 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Suggerimento in basso
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: hintColor),
                  const SizedBox(width: 4),
                  Text(
                    'Tocca per girare',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER: Large title iOS-style + Avatar
// ═══════════════════════════════════════════════════════════════
class _HeaderSection extends StatelessWidget {
  final bool isDark;
  const _HeaderSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor =
        isDark ? Colors.white70 : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.05,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bentornato, Studente!',
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.surface,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: IconButton(
                tooltip: themeProvider.isDarkMode
                    ? 'Passa al tema chiaro'
                    : 'Passa al tema scuro',
                padding: EdgeInsets.zero,
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 20,
                  color: themeProvider.isDarkMode
                      ? Colors.amber
                      : secondaryColor,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRIGLIA 2x2 STAT CARDS PASTELLO
// ═══════════════════════════════════════════════════════════════
class _StatGrid extends StatelessWidget {
  final PlannerProvider provider;
  final bool isDark;
  final void Function(int)? onNavigateToTab;

  const _StatGrid({
    required this.provider,
    required this.isDark,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.45,
      children: [
        _GlowStatCard(
          title: 'Corsi',
          value: provider.activeCourses.toString(),
          icon: Icons.menu_book_rounded,
          pastel: AppColors.pastelRed,
          isDark: isDark,
          onTap: () => onNavigateToTab?.call(1),
        ),
        _GlowStatCard(
          title: 'Esami',
          value: provider.upcomingExams.toString(),
          icon: Icons.calendar_month_rounded,
          pastel: AppColors.pastelBlue,
          isDark: isDark,
          onTap: () => onNavigateToTab?.call(2),
        ),
        _GlowStatCard(
          title: 'Attività',
          value: provider.pendingTasks.toString(),
          icon: Icons.check_circle_outline_rounded,
          pastel: AppColors.pastelGreen,
          isDark: isDark,
          onTap: () => onNavigateToTab?.call(3),
        ),
        _GlowStatCard(
          title: 'CFU',
          value: '${provider.earnedCfu}/180',
          icon: Icons.school_rounded,
          pastel: AppColors.pastelYellow,
          isDark: isDark,
          onTap: () => onNavigateToTab?.call(4),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD STATISTICA CON HALO PASTELLO
// ═══════════════════════════════════════════════════════════════
class _GlowStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color pastel;
  final bool isDark;
  final VoidCallback? onTap;

  const _GlowStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.pastel,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: pastel.withValues(alpha: isDark ? 0.18 : 0.45),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  pastel.withValues(alpha: isDark ? 0.85 : 1.0),
                  Color.lerp(pastel, Colors.white, isDark ? 0.0 : 0.18)!,
                  pastel.withValues(alpha: isDark ? 0.85 : 1.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: textColor.withValues(alpha: 0.45)),
                  ],
                ),
                _ValueText(value: value, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mostra il valore. Se contiene una "/" (es. "24/180"), il dopo-slash
/// viene reso più piccolo per non rubare attenzione.
class _ValueText extends StatelessWidget {
  final String value;
  final Color color;
  const _ValueText({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final slashIndex = value.indexOf('/');
    if (slashIndex == -1) {
      return Text(
        value,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -1.5,
          height: 1.0,
        ),
      );
    }
    final main = value.substring(0, slashIndex);
    final rest = value.substring(slashIndex);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: main,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1.5,
              height: 1.0,
              fontFamilyFallback: const ['Inter', 'SF Pro'],
            ),
          ),
          TextSpan(
            text: rest,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION LABEL (icona + titolo)
// ═══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDark ? Colors.white : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD PROSSIMO ESAME
// ═══════════════════════════════════════════════════════════════
class _NextExamCard extends StatelessWidget {
  final Exam exam;
  final bool isDark;

  const _NextExamCard({required this.exam, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final adesso = DateTime.now();
    final dataSenzaOre =
        DateTime(exam.data.year, exam.data.month, exam.data.day);
    final oggiSenzaOre =
        DateTime(adesso.year, adesso.month, adesso.day);
    final giorni = dataSenzaOre.difference(oggiSenzaOre).inDays;
    final dataFormattata =
        "${exam.data.day.toString().padLeft(2, '0')}/${exam.data.month.toString().padLeft(2, '0')}/${exam.data.year}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          // Cerchio countdown
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.pastelRed,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  giorni.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  giorni == 1 ? 'giorno' : 'giorni',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.titolo,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.pastelRedDeep,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dataFormattata,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUGGESTION TILE
// ═══════════════════════════════════════════════════════════════
class _SuggestionTile extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SuggestionTile({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUrgent = text.startsWith('!!');
    final color = isUrgent
        ? AppColors.pastelRedDeep
        : AppColors.pastelLavenderDeep;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white
                    : AppColors.textPrimary,
                letterSpacing: -0.2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}