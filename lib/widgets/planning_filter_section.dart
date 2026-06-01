import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/course.dart';

class PlanningFilterSection extends StatelessWidget {
  final bool espanso;
  final bool filtriAttivi;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final List<Course> corsi;
  final Course? filtroCorso;
  final String filtroTipo;
  final ValueChanged<Course?> onCorsoChanged;
  final ValueChanged<String> onTipoChanged;
  final bool isDark;

  const PlanningFilterSection({
    super.key,
    required this.espanso,
    required this.filtriAttivi,
    required this.onToggle,
    required this.onReset,
    required this.corsi,
    required this.filtroCorso,
    required this.filtroTipo,
    required this.onCorsoChanged,
    required this.onTipoChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded,
                        size: 18, color: AppColors.planningDeep),
                    const SizedBox(width: 8),
                    Text(
                      'Filtra attività',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (filtriAttivi)
                      GestureDetector(
                        onTap: onReset,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    Icon(
                      espanso
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (espanso)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                children: [
                  PlanningFilterPickerRow(
                    label: 'Corso',
                    displayValue: filtroCorso?.nome ?? 'Tutti',
                    options: [
                      ('__tutti__', 'Tutti i corsi'),
                      ...corsi.map((c) => (c.id, c.nome)),
                    ],
                    currentValue: filtroCorso?.id ?? '__tutti__',
                    onSelected: (v) {
                      if (v == '__tutti__') {
                        onCorsoChanged(null);
                      } else {
                        onCorsoChanged(corsi.firstWhere((c) => c.id == v));
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  PlanningFilterPickerRow(
                    label: 'Tipo',
                    displayValue: filtroTipo,
                    options: const [
                      ('Tutti', 'Tutti'),
                      ('Studio', 'Studio'),
                      ('Ripasso', 'Ripasso'),
                      ('Esercitazione', 'Esercitazione'),
                      ('Progetto', 'Progetto'),
                      ('Consegna', 'Consegna'),
                    ],
                    currentValue: filtroTipo,
                    onSelected: onTipoChanged,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PlanningFilterPickerRow extends StatelessWidget {
  final String label;
  final String displayValue;
  final List<(String, String)> options;
  final String currentValue;
  final ValueChanged<String> onSelected;
  final bool isDark;

  const PlanningFilterPickerRow({
    super.key,
    required this.label,
    required this.displayValue,
    required this.options,
    required this.currentValue,
    required this.onSelected,
    required this.isDark,
  });

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            ...options.map((opt) {
              final (value, labelText) = opt;
              final selected = value == currentValue;
              return InkWell(
                onTap: () {
                  onSelected(value);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelText,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded,
                            color: AppColors.iosBlue, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayValue,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}