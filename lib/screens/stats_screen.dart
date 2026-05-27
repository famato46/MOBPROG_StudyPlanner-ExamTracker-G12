import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  double _bonusLaurea = 0;

  // ─── AppBar Badge ──────────────────────────────────────────────
  Widget _buildTitleBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_rounded,
              size: 20, color: isDark ? Colors.white : AppColors.stats),
          const SizedBox(width: 8),
          Text('Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.stats,
              )),
        ],
      ),
    );
  }

  int _orePianificateSettimana(PlannerProvider provider) {
    final oggi = DateTime.now();
    final inizioSettimana = oggi.subtract(Duration(days: oggi.weekday - 1));
    return provider.studySessions
            .where((s) => s.data.isAfter(
                inizioSettimana.subtract(const Duration(days: 1))))
            .fold(0, (sum, s) => sum + s.durataPianificata) ~/ 60;
  }

  int _oreEffettiveSettimana(PlannerProvider provider) {
    final oggi = DateTime.now();
    final inizioSettimana = oggi.subtract(Duration(days: oggi.weekday - 1));
    return provider.studySessions
            .where((s) =>
                s.data.isAfter(
                    inizioSettimana.subtract(const Duration(days: 1))) &&
                s.durataEffettiva != null)
            .fold(0, (sum, s) => sum + (s.durataEffettiva ?? 0)) ~/ 60;
  }

  // ─── 1. KPI GRID ──────────────────────────────────────────────
  Widget _buildKpiGrid(PlannerProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildKpiCard('Corsi Totali', provider.totalCourses.toString(), Icons.book_outlined, Colors.blue),
        _buildKpiCard('Esami Superati', provider.passedCourses.toString(), Icons.check_circle_outline_rounded, AppColors.success),
        _buildKpiCard('Esami Pianificati', provider.upcomingExams.toString(), Icons.calendar_month_outlined, Colors.orange),
        _buildKpiCard('Task Pendenti', provider.pendingTasks.toString(), Icons.assignment_late_outlined, Colors.redAccent),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ─── 2. PROGRESSO OBIETTIVI (Indicatori Circolari) ─────────────
  Widget _buildProgressoObiettivi(PlannerProvider provider) {
    final orePianificate = _orePianificateSettimana(provider);
    final oreEffettive = _oreEffettiveSettimana(provider);
    final percentualeOre = orePianificate > 0 ? (oreEffettive / orePianificate) : 0.0;
    
    final cfuTotali = provider.totalCfu > 0 ? provider.totalCfu : 180;
    final percentualeCfu = provider.earnedCfu / cfuTotali;

    return Row(
      children: [
        Expanded(
          child: _buildCircularIndicator(
            title: 'CFU Ottenuti',
            subtitle: '${provider.earnedCfu} / $cfuTotali CFU',
            value: percentualeCfu.toDouble(),
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCircularIndicator(
            title: 'Studio Settimana',
            subtitle: '$oreEffettive h / ${orePianificate}h',
            value: percentualeOre.toDouble(),
            color: AppColors.stats,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularIndicator({required String title, required String subtitle, required double value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ─── 3. GRAFICO A TORTA ────────────────────────────────────────
  Widget _buildPieChart(PlannerProvider provider) {
    final List<Color> colors = [
      Colors.blueAccent, Colors.teal, Colors.orangeAccent, Colors.pinkAccent, Colors.purpleAccent
    ];

    final Map<String, int> minutiPerCorso = {};
    for (final session in provider.studySessions) {
      if (session.courseId != null && session.durataEffettiva != null) {
        final corso = provider.getCourseById(session.courseId!);
        if (corso != null) {
          minutiPerCorso[corso.nome] = (minutiPerCorso[corso.nome] ?? 0) + session.durataEffettiva!;
        }
      }
    }

    if (minutiPerCorso.isEmpty) {
  return const SizedBox(
    height: 100,
    child: Center(
      child: Text(
        'Nessuna sessione registrata. 📚', 
        style: TextStyle(color: Colors.grey, fontSize: 13)
      )
    ),
  );
}

    final entries = minutiPerCorso.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final percent = (e.value / total * 100);
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: e.value.toDouble(),
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('${e.key} (${e.value}m)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── 4. GRAFICO A BARRE ────────────────────────────────────────
  Widget _buildBarChart(PlannerProvider provider) {
  final oggi = DateTime.now();
  final giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  final List<double> minutiPerGiorno = List.generate(7, (i) {
    final giorno = oggi.subtract(Duration(days: oggi.weekday - 1 - i));
    return provider.studySessions
        .where((s) =>
            s.data.year == giorno.year &&
            s.data.month == giorno.month &&
            s.data.day == giorno.day &&
            s.durataEffettiva != null)
        .fold(0, (sum, s) => sum + (s.durataEffettiva ?? 0))
        .toDouble();
  });

  final maxTrovato = minutiPerGiorno.reduce((a, b) => a > b ? a : b);
  // Se è 0, impostiamo un massimo fittizio a 60 minuti per evitare crash di fl_chart
  final maxY = maxTrovato == 0 ? 60.0 : maxTrovato * 1.15;

  if (maxTrovato == 0) {
    return const SizedBox(
      height: 150,
      child: Center(
        child: Text(
          'Nessuna sessione questa settimana. 🛌',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  return SizedBox(
    height: 180,
    child: BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= giorni.length || value.toInt() < 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(giorni[value.toInt()], style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
        ),
        barGroups: minutiPerGiorno.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                gradient: LinearGradient(
                  colors: [AppColors.stats, AppColors.stats.withOpacity(0.6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 14,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

  // ─── 5. TEMPO STIMATO VS EFFETTIVO ─────────────────────────────
  Widget _buildTempoComparison(PlannerProvider provider) {
    final tasksConTempo = provider.tasks.where((t) => t.tempoStimato != null && t.tempoEffettivo != null).toList();

    if (tasksConTempo.isEmpty) {
      return const Center(child: Text('Nessuna attività con tempo registrato.', style: TextStyle(color: Colors.grey)));
    }

    final totaleStimato = tasksConTempo.fold(0, (sum, t) => sum + t.tempoStimato!);
    final totaleEffettivo = tasksConTempo.fold(0, (sum, t) => sum + t.tempoEffettivo!);
    final differenza = totaleEffettivo - totaleStimato;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMiniTimeStat('Stimato', '$totaleStimato min', Colors.blueGrey),
            _buildMiniTimeStat('Effettivo', '$totaleEffettivo min', AppColors.stats),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (differenza > 0 ? AppColors.danger : AppColors.success).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scostamento complessivo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                differenza >= 0 ? '+$differenza min 🐢' : '$differenza min ⚡',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: differenza > 0 ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTimeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
// ─── 6. SCADENZE IMMINENTI ─────────────────────────────────────
Widget _buildScadenzeImminenti(PlannerProvider provider) {
  // Prendiamo la data di oggi a mezzanotte per un calcolo pulito dei giorni
  final oraAttuale = DateTime.now();
  final oggi = DateTime(oraAttuale.year, oraAttuale.month, oraAttuale.day);

  final imminenti = provider.exams.where((e) {
    // Calcoliamo la data dell'esame a mezzanotte
    final dataEsame = DateTime(e.data.year, e.data.month, e.data.day);
    final differenzaGiorni = dataEsame.difference(oggi).inDays;
    
    // Filtriamo solo gli esami futuri o odierni entro i prossimi 7 giorni
    return differenzaGiorni >= 0 && differenzaGiorni <= 7 && e.stato == 'programmato';
  }).toList()
    ..sort((a, b) => a.data.compareTo(b.data));

  if (imminenti.isEmpty) {
    return const SizedBox(
      height: 80,
      child: Center(
        child: Text(
          'Nessuna scadenza nei prossimi 7 giorni. 🎉',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  return Column(
    children: imminenti.map((e) {
      final corso = provider.getCourseById(e.courseId);
      
      // Ricalcoliamo i giorni esatti di calendario
      final dataEsame = DateTime(e.data.year, e.data.month, e.data.day);
      final giorni = dataEsame.difference(oggi).inDays;

      // Gestione del testo della scadenza
      String testoGiorni;
      if (giorni == 0) {
        testoGiorni = 'Oggi! 🚨';
      } else if (giorni == 1) {
        testoGiorni = 'Domani';
      } else {
        testoGiorni = 'In $giorni gg';
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_on_rounded, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.titolo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (corso != null) 
                    Text(corso.nome, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              testoGiorni,
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

  // ─── 7. CORSI CON PIÙ ATTIVITÀ APERTE ──────────────────────────
  Widget _buildCorsiAttivita(PlannerProvider provider) {
    final Map<String, int> attivitaPerCorso = {};
    for (final task in provider.tasks.where((t) => !t.completata)) {
      if (task.courseId != null) {
        final corso = provider.getCourseById(task.courseId!);
        if (corso != null) {
          attivitaPerCorso[corso.nome] = (attivitaPerCorso[corso.nome] ?? 0) + 1;
        }
      }
    }

    if (attivitaPerCorso.isEmpty) {
      return const Center(child: Text('Nessuna attività aperta collegata a un corso.', style: TextStyle(color: Colors.grey)));
    }

    final entries = attivitaPerCorso.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text('${e.value} aperte', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── 8. SIMULATORE VOTO DI LAUREA ──────────────────────────────
  Widget _buildSimulatore(PlannerProvider provider) {
    final mediaBase = provider.estimatedGraduationGrade;
    final votoFinale = (mediaBase + _bonusLaurea).clamp(0, 110);
    final conLode = votoFinale >= 110;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Media di Partenza: ${mediaBase.toStringAsFixed(1)}/110', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Bonus Tesi: +${_bonusLaurea.toInt()} pt', style: TextStyle(color: AppColors.stats, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        Slider(
          value: _bonusLaurea,
          min: 0, max: 10, divisions: 10,
          activeColor: AppColors.stats,
          onChanged: (val) => setState(() => _bonusLaurea = val),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: conLode 
                ? [Colors.amber.shade700, Colors.amber.shade400]
                : [AppColors.stats, AppColors.stats.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('PROIEZIONE VOTO FINALE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(
                conLode ? '110 / 110 con Lode 🎓' : '${votoFinale.toStringAsFixed(1)} / 110',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        )
      ],
    );
  }

  // ─── BUILD MAIN SCREEN ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitleBadge(context),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle(title: 'Riepilogo Generale', icon: Icons.grid_view_rounded),
              const SizedBox(height: 12),
              _buildKpiGrid(provider),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Obiettivi & Progresso', icon: Icons.track_changes_rounded),
              const SizedBox(height: 12),
              _buildProgressoObiettivi(provider),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Tempo di Studio per Corso', icon: Icons.pie_chart_rounded),
              const SizedBox(height: 12),
              _buildDashboardCard(_buildPieChart(provider)),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Andamento Settimanale', icon: Icons.bar_chart_rounded),
              const SizedBox(height: 12),
              _buildDashboardCard(_buildBarChart(provider)),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Scadenze Imminenti', icon: Icons.notification_important_rounded),
              const SizedBox(height: 12),
              _buildDashboardCard(_buildScadenzeImminenti(provider)),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Stima Tempi (Task)', icon: Icons.hourglass_bottom_rounded),
              const SizedBox(height: 12),
              _buildDashboardCard(_buildTempoComparison(provider)),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Focus Attività per Corso', icon: Icons.assignment_rounded),
              const SizedBox(height: 12),
              _buildDashboardCard(_buildCorsiAttivita(provider)),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Simulatore Laurea', icon: Icons.gavel_rounded),
              const SizedBox(height: 12),
              _buildDashboardCard(_buildSimulatore(provider)),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.stats.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.stats),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ],
    );
  }
}