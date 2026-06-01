import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PlanningCalendarGrid extends StatefulWidget {
  final DateTime selectedDay;
  final Set<DateTime> giorniConSessioni;
  final ValueChanged<DateTime> onDaySelected;
  final bool isDark;

  const PlanningCalendarGrid({
    super.key,
    required this.selectedDay,
    required this.giorniConSessioni,
    required this.onDaySelected,
    required this.isDark,
  });

  @override
  State<PlanningCalendarGrid> createState() => _PlanningCalendarGridState();
}

class _PlanningCalendarGridState extends State<PlanningCalendarGrid> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final oggi = DateTime.now();
    final oggiNorm = DateTime(oggi.year, oggi.month, oggi.day);

    final primoDelMese = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final offset = (primoDelMese.weekday - 1) % 7;
    final giorniNelMese =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final totalCells = offset + giorniNelMese;
    final rows = (totalCells / 7).ceil();

    const mesi = [
      '',
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    const giorniSettimana = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Icon(Icons.chevron_left_rounded,
                    color: AppColors.planningDeep, size: 24),
              ),
              Expanded(
                child: Text(
                  '${mesi[_viewMonth.month]} ${_viewMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.planningDeep, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: giorniSettimana
                .map((g) => Expanded(
                      child: Center(
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 2,
              childAspectRatio: 1.0,
              children: List.generate(rows * 7, (index) {
                final dayNumber = index - offset + 1;
                final isValidDay = dayNumber >= 1 && dayNumber <= giorniNelMese;
            
                if (!isValidDay) return const SizedBox.shrink();
            
                final thisDay =
                    DateTime(_viewMonth.year, _viewMonth.month, dayNumber);
                final thisDayNorm =
                    DateTime(thisDay.year, thisDay.month, thisDay.day);
                final isSelected = thisDayNorm ==
                    DateTime(widget.selectedDay.year, widget.selectedDay.month,
                        widget.selectedDay.day);
                final isOggi = thisDayNorm == oggiNorm;
                final hasSession =
                    widget.giorniConSessioni.contains(thisDayNorm);
            
                return GestureDetector(
                  onTap: () => widget.onDaySelected(thisDay),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.planning
                          : isOggi
                              ? AppColors.planning.withValues(alpha: 0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isOggi
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isOggi
                                    ? AppColors.planningDeep
                                    : (isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                          ),
                        ),
                        if (hasSession && !isSelected)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: AppColors.planningDeep,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasSession && isSelected)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: const BoxDecoration(
                              color: Colors.white70,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}