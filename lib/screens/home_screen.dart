import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sfondo panna/beige chiarissimo per il tema chiaro (come da mockup)
    final bgColor = isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF6F5F2);

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ------------------------------------------------------------------
          // LOGICA DINAMICA: PROSSIMO ESAME IN ARRIVO
          // ------------------------------------------------------------------
          dynamic prossimoEsame;
          int giorniMancantiEsame = 0;
          String dataEsameFormattata = '';

          if (provider.exams.isNotEmpty) {
            final adesso = DateTime.now();
            final esamiFuturi = provider.exams
                .where((e) => e.data.isAfter(adesso) || DateUtils.isSameDay(e.data, adesso))
                .toList();
                
            if (esamiFuturi.isNotEmpty) {
              esamiFuturi.sort((a, b) => a.data.compareTo(b.data));
              prossimoEsame = esamiFuturi.first; 
              
              final dataEsameSenzaOre = DateTime(prossimoEsame.data.year, prossimoEsame.data.month, prossimoEsame.data.day);
              final oggiSenzaOre = DateTime(adesso.year, adesso.month, adesso.day);
              giorniMancantiEsame = dataEsameSenzaOre.difference(oggiSenzaOre).inDays;

              dataEsameFormattata = "${prossimoEsame.data.day.toString().padLeft(2, '0')}/${prossimoEsame.data.month.toString().padLeft(2, '0')}/${prossimoEsame.data.year}";
            }
          }

          // Filtro anti-duplicati per i suggerimenti automatici
          final suggerimentiUnici = provider.suggerimentiAutomatici.toSet().toList();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                
                // 1. HEADER FISSO: TITOLO E BENTORNATO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bentornato Studente',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Switch del Tema
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () => themeProvider.toggleTheme(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 2. GRIGLIA STATISTICHE CON PALETTE COERENTI RICHIESTE
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.35, 
                  children: [
                    // CORSI -> VERDE
                    _PastelStatCard(
                      title: 'Corsi',
                      value: provider.activeCourses.toString(),
                      icon: Icons.menu_book_rounded,
                      color: isDark ? const Color(0xFF1E3A24) : const Color(0xFFE2F5E8),
                      textColor: isDark ? Colors.white : const Color(0xFF2E7D32),
                      iconColor: isDark ? Colors.green[300]! : const Color(0xFF2E7D32),
                    ),
                    // ESAMI -> PALETTE DELLA FOTO (ROSA/ROSSO)
                    _PastelStatCard(
                      title: 'Esami',
                      value: provider.upcomingExams.toString(),
                      icon: Icons.calendar_month_rounded,
                      color: isDark ? const Color(0xFF4A3232) : const Color(0xFFFFEAEA),
                      textColor: isDark ? Colors.white : const Color(0xFFD96383),
                      iconColor: isDark ? Colors.red[300]! : const Color(0xFFD96383),
                    ),
                    // ATTIVITÀ -> GIALLO SCHERMATA PIANIFICA
                    _PastelStatCard(
                      title: 'Attività',
                      value: provider.pendingTasks.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: isDark ? const Color(0xFF3E351A) : const Color(0xFFFFF9C4),
                      textColor: isDark ? Colors.white : const Color(0xFFFBC02D),
                      iconColor: isDark ? Colors.amber[300]! : const Color(0xFFFBC02D),
                    ),
                    // CFU -> BLU COME ESAME ORA
                    _PastelStatCard(
                      title: 'CFU',
                      value: '${provider.earnedCfu}/${provider.totalCfu}',
                      icon: Icons.school_rounded,
                      color: isDark ? const Color(0xFF1D2D44) : const Color(0xFFE4F0FF),
                      textColor: isDark ? Colors.white : const Color(0xFF1976D2),
                      iconColor: isDark ? Colors.blue[300]! : const Color(0xFF1976D2),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 3. SEZIONE: COUNTDOWN PROSSIMO ESAME (Usa la palette esami della foto)
                if (prossimoEsame != null) ...[
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        'Prossimo obiettivo d\'esame',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w700, 
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _NextExamCard(
                    isDark: isDark,
                    examName: prossimoEsame.titolo, 
                    daysLeft: giorniMancantiEsame, 
                    dateString: dataEsameFormattata, 
                  ),
                  const SizedBox(height: 32),
                ],

                // 4. SEZIONE: SUGGERIMENTI (PULITI SENZA DUPLICATI)
                if (suggerimentiUnici.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        'Suggerimenti',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w700, 
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...suggerimentiUnici.map((suggerimento) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggerimento, 
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white38 : Colors.black26),
                      ],
                    ),
                  )),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET PERSONALIZZATI COMPONENTI
// -----------------------------------------------------------------------------

class _PastelStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color iconColor;

  const _PastelStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextExamCard extends StatelessWidget {
  final bool isDark;
  final String examName;
  final int daysLeft;
  final String dateString;

  const _NextExamCard({
    required this.isDark,
    required this.examName,
    required this.daysLeft,
    required this.dateString,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4A3232) : const Color(0xFFFFEAEA),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  daysLeft.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.red[200] : const Color(0xFFD96383),
                    height: 1.1,
                  ),
                ),
                Text(
                  daysLeft == 1 ? 'giorno' : 'giorni',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.red[200]?.withOpacity(0.8) : const Color(0xFFD96383).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                    const SizedBox(width: 6),
                    Text(
                      dateString,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black45,
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