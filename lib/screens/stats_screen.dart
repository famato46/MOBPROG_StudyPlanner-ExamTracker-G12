import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Ephemeral state simulatore
  double _votoIpotetico = 24;
  int _cfuIpotetici = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper
  int _orePianificateSettimana(PlannerProvider provider) {
    final oggi = DateTime.now();
    final inizio = oggi.subtract(Duration(days: oggi.weekday - 1));
    return provider.studySessions
            .where((s) =>
                s.data.isAfter(inizio.subtract(const Duration(days: 1))))
            .fold(0, (sum, s) => sum + s.durataPianificata) ~/
        60;
  }

  int _oreEffettiveSettimana(PlannerProvider provider) {
    final oggi = DateTime.now();
    final inizio = oggi.subtract(Duration(days: oggi.weekday - 1));
    return provider.studySessions
            .where((s) =>
                s.completata &&
                s.tipo == 'pomodoro' &&
                s.data.isAfter(inizio.subtract(const Duration(days: 1))) &&
                s.durataEffettiva != null)
            .fold(0, (sum, s) => sum + (s.durataEffettiva ?? 0)) ~/
        60;
  }

  // RIEPILOGO
  Widget _buildTabRiepilogo(PlannerProvider provider, bool isDark) {
    final esamiDaSostenere = provider.exams
        .where((e) =>
            e.isPassato &&
            e.stato != 'completato' &&
            e.stato != 'annullato')
        .length;

    final orePianificate = _orePianificateSettimana(provider);
    final oreEffettive = _oreEffettiveSettimana(provider);
    final percentualeOre =
        orePianificate > 0 ? (oreEffettive / orePianificate) : 0.0;
    const int cfuObiettivoLaurea = 180;
    final percentualeCfu = provider.earnedCfu / cfuObiettivoLaurea;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Scadenze imminenti
        const _SectionLabel(title: 'Scadenze Imminenti'),
        const SizedBox(height: 12),
        _buildScadenzeImminenti(provider),
        const SizedBox(height: 24),

        // KPI Grid
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Corsi Totali',
                value: provider.totalCourses.toString(),
                icon: Icons.book_outlined,
                bg: AppColors.pastelRed,
                fg: AppColors.pastelRedDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Corsi Superati',
                value: provider.passedCourses.toString(),
                icon: Icons.check_circle_outline_rounded,
                bg: AppColors.pastelRed,
                fg: AppColors.pastelRedDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Esami Programmati',
                value: provider.upcomingExams.toString(),
                icon: Icons.calendar_month_outlined,
                bg: AppColors.pastelBlue,
                fg: AppColors.pastelBlueDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Esami Completati',
                value: provider.completedExams.toString(),
                icon: Icons.task_alt_rounded,
                bg: AppColors.pastelBlue,
                fg: AppColors.pastelBlueDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Obiettivi Completati',
                value: provider.completedTasksCount.toString(),
                icon: Icons.check_box_outlined,
                bg: AppColors.pastelGreen,
                fg: AppColors.pastelGreenDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Obiettivi Da Fare',
                value: provider.pendingTasks.toString(),
                icon: Icons.assignment_late_outlined,
                bg: AppColors.pastelGreen,
                fg: AppColors.pastelGreenDeep,
              ),
            ),
          ],
        ),
        if (esamiDaSostenere > 0) ...[
          const SizedBox(height: 12),
          _KpiCard(
            label: 'Esami Da Sostenere (scaduti)',
            value: esamiDaSostenere.toString(),
            icon: Icons.warning_amber_rounded,
            bg: AppColors.pastelYellow,
            fg: AppColors.pastelYellowDeep,
            fullWidth: true,
          ),
        ],
        const SizedBox(height: 24),

        // Indicatori circolari
        const _SectionLabel(title: 'Obiettivi & Progresso'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CircularCard(
                title: 'CFU Ottenuti',
                subtitle:
                    '${provider.earnedCfu} / $cfuObiettivoLaurea CFU',
                value: percentualeCfu.clamp(0.0, 1.0),
                color: AppColors.pastelLavenderDeep,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CircularCard(
                title: 'Studio Settimana',
                subtitle: '$oreEffettive h / ${orePianificate}h',
                value: percentualeOre.clamp(0.0, 1.0),
                color: AppColors.statsDeep,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // STORICO FOCUS (Pomodoro)
        const _SectionLabel(title: 'Storico Focus'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FocusStatCard(
                label: 'Pomodori',
                value: provider.pomodoriCompletati.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.danger,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FocusStatCard(
                label: 'Pause',
                value: provider.pauseCompletate.toString(),
                icon: Icons.local_cafe_outlined,
                color: AppColors.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FocusStatCard(
                label: 'Minuti',
                value: provider.minutiTotaliFocus.toString(),
                icon: Icons.timer_outlined,
                color: AppColors.planningDeep,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFocusHistory(provider, isDark),
      ],
    );
  }

  // LISTA STORICO FOCUS RECENTE
  Widget _buildFocusHistory(PlannerProvider provider, bool isDark) {
    // Filtra e ordina le sessioni (ultime 5 completate)
    final history = provider.studySessions
        .where((s) => s.completata && (s.tipo == 'pomodoro' || s.tipo == 'pausa'))
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    final recent = history.take(5).toList();

    if (recent.isEmpty) {
      return const _EmptyCard(text: 'Nessuna sessione Focus registrata di recente.');
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: recent.asMap().entries.map((entry) {
          final isLast = entry.key == recent.length - 1;
          final s = entry.value;
          final isPomodoro = s.tipo == 'pomodoro';
          final icon = isPomodoro ? Icons.check_circle_rounded : Icons.local_cafe_rounded;
          final color = isPomodoro ? AppColors.danger : AppColors.success;
          final timeStr = DateFormat('dd MMM, HH:mm', 'it_IT').format(s.data);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.titolo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${s.durataEffettiva ?? 0}m',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 52, // Allineato col testo
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.groupedDivider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // TAB 1 — GRAFICI
  Widget _buildTabGrafici(PlannerProvider provider, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _SectionLabel(title: 'Tempo di Studio per Corso'),
        const SizedBox(height: 12),
        _buildPieChart(provider, isDark),
        const SizedBox(height: 24),

        const _SectionLabel(title: 'Andamento Settimanale'),
        const SizedBox(height: 12),
        _buildBarChart(provider, isDark),
        const SizedBox(height: 24),

        const _SectionLabel(title: 'Focus Obiettivi per Corso'),
        const SizedBox(height: 12),
        _buildCorsiAttivita(provider, isDark),
      ],
    );
  }

  // TAB 2 — SIMULATORE
  Widget _buildTabSimulatore(PlannerProvider provider, bool isDark) {
    final corsiSuperati = provider.courses
        .where((c) => c.stato == 'superato' && c.votoOttenuto != null)
        .toList();

    final cfuRealiTotali =
        corsiSuperati.fold(0, (sum, c) => sum + c.cfu);
    final sommaPonderataReale = corsiSuperati.fold<double>(
        0,
        (sum, c) => sum +
            ((c.votoOttenuto! > 30 ? 30 : c.votoOttenuto!) * c.cfu));
    final mediaReale =
        cfuRealiTotali > 0 ? sommaPonderataReale / cfuRealiTotali : 0.0;
    final votoLaureaAttuale = mediaReale * (110 / 30);

    final votoNorm = _votoIpotetico > 30 ? 30.0 : _votoIpotetico;
    final cfuSim = cfuRealiTotali + _cfuIpotetici;
    final sommaSim = sommaPonderataReale + (votoNorm * _cfuIpotetici);
    final mediaSim = cfuSim > 0 ? sommaSim / cfuSim : 0.0;
    final votoSim = mediaSim * (110 / 30);
    final diff = votoSim - votoLaureaAttuale;
    final isLode = _votoIpotetico >= 31;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _SectionLabel(title: 'Simulatore Voto di Laurea'),
        const SizedBox(height: 12),

        // Box situazione attuale
        if (corsiSuperati.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Registra almeno un esame superato con voto per usare il simulatore.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        if (corsiSuperati.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.pastelLavender.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SITUAZIONE ATTUALE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pastelLavenderDeep,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  '${corsiSuperati.length} esami · $cfuRealiTotali CFU · Media ${mediaReale.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Voto proiettato: ${votoLaureaAttuale.toStringAsFixed(1)} / 110',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        Text('SE AL PROSSIMO ESAME...',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.statsDeep,
                letterSpacing: 1.2)),
        const SizedBox(height: 16),

        // Slider voto
        _buildSliderRow(
          label: 'Voto',
          valueLabel: isLode ? '30L' : '${_votoIpotetico.toInt()}/30',
          slider: Slider(
            value: _votoIpotetico,
            min: 18,
            max: 31,
            divisions: 13,
            activeColor: AppColors.statsDeep,
            label: isLode ? '30L' : _votoIpotetico.toInt().toString(),
            onChanged: (v) => setState(() => _votoIpotetico = v),
          ),
        ),
        const SizedBox(height: 8),

        // Slider CFU
        _buildSliderRow(
          label: 'CFU',
          valueLabel: '$_cfuIpotetici CFU',
          slider: Slider(
            value: _cfuIpotetici.toDouble(),
            min: 3,
            max: 15,
            divisions: 12,
            activeColor: AppColors.statsDeep,
            label: '$_cfuIpotetici CFU',
            onChanged: (v) => setState(() => _cfuIpotetici = v.toInt()),
          ),
        ),
        const SizedBox(height: 24),

        // Risultato
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.statsDeep, AppColors.stats],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('NUOVO VOTO DI LAUREA',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Text(
                votoSim >= 110
                    ? '110 / 110${isLode ? ' L' : ''}'
                    : '${votoSim.toStringAsFixed(1)} / 110',
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              if (corsiSuperati.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  diff >= 0
                      ? '+${diff.toStringAsFixed(2)} rispetto a ora'
                      : '${diff.toStringAsFixed(2)} rispetto a ora',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueLabel,
    required Widget slider,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.pastelYellow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(valueLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.statsDeep)),
            ),
          ],
        ),
        slider,
      ],
    );
  }

  // Grafico a torta 
  Widget _buildPieChart(PlannerProvider provider, bool isDark) {
    final List<Color> colors = [
      AppColors.pastelRedDeep,
      AppColors.pastelBlueDeep,
      AppColors.pastelGreenDeep,
      AppColors.pastelYellowDeep,
      AppColors.pastelLavenderDeep,
    ];

    final Map<String, int> minutiPerCorso = {};
    for (final s in provider.studySessions) {
      if (s.completata && s.tipo == 'pomodoro' && s.courseId != null && s.durataEffettiva != null) {
        final corso = provider.getCourseById(s.courseId!);
        if (corso != null) {
          minutiPerCorso[corso.nome] =
              (minutiPerCorso[corso.nome] ?? 0) + s.durataEffettiva!;
        }
      }
    }

    if (minutiPerCorso.isEmpty) {
      return const _EmptyCard(text: 'Nessuna sessione di studio registrata per i corsi.');
    }

    final entries = minutiPerCorso.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    return _Card(
      isDark: isDark,
      child: Column(
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
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: e.value.toDouble(),
                    title:
                        '${(e.value / total * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('${e.key} (${e.value}m)',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Grafico a barre 
  Widget _buildBarChart(PlannerProvider provider, bool isDark) {
    final oggi = DateTime.now();
    final giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

    // Calcoliamo i minuti di Pomodoro e Pausa separatamente per ogni giorno
    final List<Map<String, double>> minutiSettimana = List.generate(7, (i) {
      final g = oggi.subtract(Duration(days: oggi.weekday - 1 - i));
      
      final sessioniGiorno = provider.studySessions.where((s) =>
          s.completata &&
          s.durataEffettiva != null &&
          s.data.year == g.year &&
          s.data.month == g.month &&
          s.data.day == g.day);

      double pomodoro = 0;
      double pausa = 0;
      
      for (var s in sessioniGiorno) {
        if (s.tipo == 'pomodoro') {
          pomodoro += s.durataEffettiva!;
        } else if (s.tipo == 'pausa') {
          pausa += s.durataEffettiva!;
        }
      }

      return {'pomodoro': pomodoro, 'pausa': pausa};
    });

    final maxT = minutiSettimana.fold(0.0, (m, e) {
      final sum = e['pomodoro']! + e['pausa']!;
      return sum > m ? sum : m;
    });

    if (maxT == 0) {
      return const _EmptyCard(text: 'Nessuna sessione questa settimana.');
    }

    return _Card(
      isDark: isDark,
      child: Column(
        children: [
          // Legenda del grafico
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10, 
                height: 10,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('Focus', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 10, 
                height: 10,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('Pausa', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxT * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => isDark ? const Color(0xFF2A2A2C) : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayData = minutiSettimana[group.x.toInt()];
                      return BarTooltipItem(
                        '${giorni[group.x.toInt()]}\n',
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black, 
                          fontWeight: FontWeight.bold
                        ),
                        children: [
                          TextSpan(
                            text: 'Focus: ${dayData['pomodoro']!.toInt()} min\n',
                            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
                          ),
                          TextSpan(
                            text: 'Pausa: ${dayData['pausa']!.toInt()} min',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= giorni.length || value.toInt() < 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(giorni[value.toInt()],
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: minutiSettimana.asMap().entries.map((entry) {
                  final pom = entry.value['pomodoro']!;
                  final pau = entry.value['pausa']!;
                  final total = pom + pau;

                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: total,
                        width: 14,
                        color: Colors.transparent, // Lo sfondo del rod intero è trasparente
                        borderRadius: BorderRadius.circular(6),
                        rodStackItems: [
                          if (pom > 0)
                            BarChartRodStackItem(0, pom, AppColors.danger),
                          if (pau > 0)
                            BarChartRodStackItem(pom, total, AppColors.success),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Corsi con più obiettivi attivi 
  Widget _buildCorsiAttivita(PlannerProvider provider, bool isDark) {
    final Map<String, int> map = {};
    for (final t in provider.tasks.where((t) => !t.completata)) {
      if (t.courseId != null) {
        final corso = provider.getCourseById(t.courseId!);
        if (corso != null) {
          map[corso.nome] = (map[corso.nome] ?? 0) + 1;
        }
      }
    }

    if (map.isEmpty) {
      return const _EmptyCard(
          text: 'Nessun obiettivo aperto collegato a un corso.');
    }

    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      isDark: isDark,
      child: Column(
        children: entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                    child: Text(e.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pastelYellow.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${e.value} aperte',
                      style: TextStyle(
                          color: AppColors.pastelYellowDeep,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Scadenze imminenti 
  Widget _buildScadenzeImminenti(PlannerProvider provider) {
    final oggi = DateTime.now();
    final oggiDate = DateTime(oggi.year, oggi.month, oggi.day);

    final imminenti = provider.exams.where((e) {
      final d = DateTime(e.data.year, e.data.month, e.data.day);
      final diff = d.difference(oggiDate).inDays;
      return diff >= 0 && diff <= 7 && e.stato == 'programmato';
    }).toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    if (imminenti.isEmpty) {
      return const _EmptyCard(text: 'Nessuna scadenza nei prossimi 7 giorni.');
    }

    return Column(
      children: imminenti.map((e) {
        final corso = provider.getCourseById(e.courseId);
        final d = DateTime(e.data.year, e.data.month, e.data.day);
        final giorni = d.difference(oggiDate).inDays;
        final testo = giorni == 0
            ? 'Oggi!'
            : giorni == 1
                ? 'Domani'
                : 'In $giorni gg';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.alarm_on_rounded,
                  color: AppColors.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.titolo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    if (corso != null)
                      Text(corso.nome,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Text(testo,
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer<PlannerProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header — allineato a sinistra come le altre schermate ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistiche',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1.05,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Il tuo andamento accademico',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Segmented control ──
                // Tab bar con icone + testo, animazione nativa fluida
                _StatsTabBar(
                  controller: _tabController,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildTabRiepilogo(provider, isDark),
                            _buildTabGrafici(provider, isDark),
                            _buildTabSimulatore(provider, isDark),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// WIDGET CARD STATISTICHE FOCUS 
class _FocusStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _FocusStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// STATS TAB BAR — TabBar nativo con icona sopra e testo sotto
class _StatsTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;

  const _StatsTabBar({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textUnsel =
        isDark ? Colors.white70 : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: AppColors.pastelYellow,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          // Colore testo/icona: scuro su sfondo giallo chiaro.
          labelColor: AppColors.statsDeep,
          unselectedLabelColor: textUnsel,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: [
            _IconTab(
              icon: Icons.grid_view_rounded,
              label: 'Riepilogo',
              isDark: isDark,
            ),
            _IconTab(
              icon: Icons.bar_chart_rounded,
              label: 'Grafici',
              isDark: isDark,
            ),
            _IconTab(
              icon: Icons.school_rounded,
              label: 'Voto di Laurea',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _IconTab({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, letterSpacing: -0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// KPI CARD
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool fullWidth;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: fg)),
              ),
              Icon(icon, size: 20, color: fg),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}

// CIRCULAR CARD
class _CircularCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final Color color;
  final bool isDark;

  const _CircularCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Text('${(value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// WIDGET AUSILIARI
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(text,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center),
      ),
    );
  }
}

