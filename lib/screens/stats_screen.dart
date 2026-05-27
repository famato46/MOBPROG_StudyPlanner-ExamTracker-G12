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
  // Ephemeral state per il simulatore voto laurea (Slider)
  double _bonusLaurea = 0;

  // ─── Riquadrino titolo AppBar ──────────────────────────────────
  Widget _buildTitleBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart,
              size: 20, color: isDark ? Colors.white : AppColors.stats),
          const SizedBox(width: 8),
          Text('Statistiche',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.stats,
              )),
        ],
      ),
    );
  }

  // ─── Ore pianificate questa settimana ─────────────────────────
  int _orePianificateSettimana(PlannerProvider provider) {
    final oggi = DateTime.now();
    final inizioSettimana =
        oggi.subtract(Duration(days: oggi.weekday - 1));
    return provider.studySessions
            .where((s) => s.data.isAfter(
                inizioSettimana.subtract(const Duration(days: 1))))
            .fold(0, (sum, s) => sum + s.durataPianificata) ~/
        60;
  }

  // ─── Ore effettive questa settimana ───────────────────────────
  int _oreEffettiveSettimana(PlannerProvider provider) {
    final oggi = DateTime.now();
    final inizioSettimana =
        oggi.subtract(Duration(days: oggi.weekday - 1));
    return provider.studySessions
            .where((s) =>
                s.data.isAfter(
                    inizioSettimana.subtract(const Duration(days: 1))) &&
                s.durataEffettiva != null)
            .fold(0, (sum, s) => sum + (s.durataEffettiva ?? 0)) ~/
        60;
  }

  // ─── Grafico a torta: minuti per corso ────────────────────────
  Widget _buildPieChart(PlannerProvider provider) {
    final List<Color> colors = [
      AppColors.home,
      AppColors.courses,
      AppColors.exams,
      AppColors.planning,
      AppColors.stats,
    ];

    final Map<String, int> minutiPerCorso = {};
    for (final session in provider.studySessions) {
      if (session.courseId != null && session.durataEffettiva != null) {
        final corso = provider.getCourseById(session.courseId!);
        if (corso != null) {
          minutiPerCorso[corso.nome] =
              (minutiPerCorso[corso.nome] ?? 0) +
                  session.durataEffettiva!;
        }
      }
    }

    if (minutiPerCorso.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('Nessuna sessione registrata.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final entries = minutiPerCorso.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final percent = (e.value / total * 100);
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: e.value.toDouble(),
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(e.key, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Grafico a barre: sessioni per giorno settimana ───────────
  Widget _buildBarChart(PlannerProvider provider) {
    final oggi = DateTime.now();
    final giorni = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    final List<double> minutiPerGiorno = List.generate(7, (i) {
      final giorno =
          oggi.subtract(Duration(days: oggi.weekday - 1 - i));
      return provider.studySessions
          .where((s) =>
              s.data.year == giorno.year &&
              s.data.month == giorno.month &&
              s.data.day == giorno.day &&
              s.durataEffettiva != null)
          .fold(0, (sum, s) => sum + (s.durataEffettiva ?? 0))
          .toDouble();
    });

    final maxY =
        minutiPerGiorno.reduce((a, b) => a > b ? a : b);

    if (maxY == 0) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('Nessuna sessione questa settimana.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY + 10,
          barGroups: minutiPerGiorno.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: AppColors.stats,
                  width: 18,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    giorni[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // ─── Confronto tempo stimato vs effettivo ─────────────────────
  Widget _buildTempoComparison(PlannerProvider provider) {
    final tasksConTempo = provider.tasks
        .where((t) =>
            t.tempoStimato != null && t.tempoEffettivo != null)
        .toList();

    if (tasksConTempo.isEmpty) {
      return const Text(
        'Nessuna attività con tempo registrato.',
        style: TextStyle(color: Colors.grey),
      );
    }

    final totaleStimato =
        tasksConTempo.fold(0, (sum, t) => sum + t.tempoStimato!);
    final totaleEffettivo =
        tasksConTempo.fold(0, (sum, t) => sum + t.tempoEffettivo!);
    final differenza = totaleEffettivo - totaleStimato;

    return Column(
      children: [
        _StatRow('Tempo stimato totale', '$totaleStimato min'),
        _StatRow('Tempo effettivo totale', '$totaleEffettivo min'),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Differenza'),
            Flexible(
              child: Text(
                differenza >= 0
                    ? '+$differenza min (più lento)'
                    : '$differenza min (più veloce)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: differenza > 0
                      ? AppColors.danger
                      : AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Corsi con più attività aperte ────────────────────────────
  Widget _buildCorsiAttivita(PlannerProvider provider) {
    final Map<String, int> attivitaPerCorso = {};
    for (final task in provider.tasks.where((t) => !t.completata)) {
      if (task.courseId != null) {
        final corso = provider.getCourseById(task.courseId!);
        if (corso != null) {
          attivitaPerCorso[corso.nome] =
              (attivitaPerCorso[corso.nome] ?? 0) + 1;
        }
      }
    }

    if (attivitaPerCorso.isEmpty) {
      return Text(
        'Nessuna attività aperta collegata a un corso.',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    final entries = attivitaPerCorso.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(e.key)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.stats.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${e.value} attività',
                  style: TextStyle(
                    color: AppColors.stats,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Scadenze imminenti ────────────────────────────────────────
  Widget _buildScadenzeImminenti(PlannerProvider provider) {
    final imminenti = provider.exams
        .where((e) =>
            e.isImminente && e.stato == 'programmato')
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    if (imminenti.isEmpty) {
      return Text(
        'Nessuna scadenza nei prossimi 7 giorni. 🎉',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    return Column(
      children: imminenti.map((e) {
        final corso = provider.getCourseById(e.courseId);
        final giorni =
            e.data.difference(DateTime.now()).inDays;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.circle,
                  size: 10, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.titolo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (corso != null)
                      Text(corso.nome,
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12)),
                  ],
                ),
              ),
              Text(
                giorni == 0
                    ? 'Oggi!'
                    : giorni == 1
                        ? 'Domani'
                        : 'tra $giorni giorni',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Simulatore voto di laurea con Slider ─────────────────────
  Widget _buildSimulatore(PlannerProvider provider) {
    final mediaBase = provider.estimatedGraduationGrade;
    final votoFinale = (mediaBase + _bonusLaurea).clamp(0, 110);
    final conLode = votoFinale >= 110;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media attuale in /110: ${mediaBase.toStringAsFixed(1)}',
          style:
              TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Bonus commissione:'),
            const SizedBox(width: 8),
            Text(
              '+${_bonusLaurea.toInt()} punti',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.stats),
            ),
          ],
        ),
        Slider(
          value: _bonusLaurea,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppColors.stats,
          label: '+${_bonusLaurea.toInt()}',
          onChanged: (val) => setState(() => _bonusLaurea = val),
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(
                conLode
                    ? '${votoFinale.toInt()}/110 con Lode 🎓'
                    : '${votoFinale.toStringAsFixed(1)}/110',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: conLode
                      ? AppColors.success
                      : AppColors.stats,
                ),
              ),
              if (conLode)
                Text(
                  'Congratulazioni! Lode possibile 🎉',
                  style:
                      TextStyle(color: AppColors.success),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _buildTitleBadge(context)),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ─── 1. RIEPILOGO GENERALE ───────────────────────
              _SectionTitle(
                  title: 'Riepilogo Generale',
                  icon: Icons.dashboard_outlined),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _StatRow('Corsi totali',
                          provider.totalCourses.toString()),
                      _StatRow('Corsi superati',
                          provider.passedCourses.toString()),
                      _StatRow('Esami programmati',
                          provider.upcomingExams.toString()),
                      _StatRow('Esami completati',
                          provider.completedExams.toString()),
                      const Divider(),
                      _StatRow('Attività completate',
                          provider.completedTasksCount.toString()),
                      _StatRow('Attività da completare',
                          provider.pendingTasks.toString()),
                      const Divider(),
                      _StatRow('CFU ottenuti',
                          '${provider.earnedCfu} / ${provider.totalCfu}'),
                      _StatRow('Ore di studio totali',
                          '${provider.totalStudyHours} h'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 2. SCADENZE IMMINENTI ───────────────────────
              _SectionTitle(
                  title: 'Scadenze imminenti',
                  icon: Icons.notification_important_outlined),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildScadenzeImminenti(provider),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 3. STUDIO QUESTA SETTIMANA ──────────────────
              _SectionTitle(
                  title: 'Studio questa settimana',
                  icon: Icons.timer_outlined),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _StatRow('Ore pianificate',
                          '${_orePianificateSettimana(provider)} h'),
                      _StatRow('Ore effettive',
                          '${_oreEffettiveSettimana(provider)} h'),
                      const SizedBox(height: 12),
                      _ProgressBar(
                        label: 'Completamento settimana',
                        value: _oreEffettiveSettimana(provider) /
                            (_orePianificateSettimana(provider) > 0
                                ? _orePianificateSettimana(provider)
                                : 1),
                        color: AppColors.stats,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 4. VOTI ─────────────────────────────────────
              _SectionTitle(
                  title: 'Voti',
                  icon: Icons.school_outlined),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _StatRow(
                          'Media ponderata',
                          provider.weightedAverage > 0
                              ? provider.weightedAverage
                                  .toStringAsFixed(2)
                              : 'N/D'),
                      _StatRow(
                          'Voto laurea stimato',
                          provider.estimatedGraduationGrade > 0
                              ? provider.estimatedGraduationGrade
                                  .toStringAsFixed(1)
                              : 'N/D'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 5. GRAFICO A TORTA ───────────────────────────
              _SectionTitle(
                  title: 'Tempo di studio per corso',
                  icon: Icons.pie_chart_outline),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPieChart(provider),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 6. GRAFICO A BARRE ───────────────────────────
              _SectionTitle(
                  title: 'Andamento settimanale sessioni',
                  icon: Icons.bar_chart),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBarChart(provider),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 7. TEMPO STIMATO VS EFFETTIVO ───────────────
              _SectionTitle(
                  title: 'Tempo stimato vs effettivo',
                  icon: Icons.compare_arrows),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildTempoComparison(provider),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 8. CORSI CON PIÙ ATTIVITÀ APERTE ────────────
              _SectionTitle(
                  title: 'Corsi con più attività aperte',
                  icon: Icons.assignment_late_outlined),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCorsiAttivita(provider),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 9. SIMULATORE VOTO DI LAUREA ─────────────────
              _SectionTitle(
                  title: 'Simulatore voto di laurea',
                  icon: Icons.calculate_outlined),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSimulatore(provider),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ─── Widget condivisi ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.stats),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.stats,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.stats,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ProgressBar(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}