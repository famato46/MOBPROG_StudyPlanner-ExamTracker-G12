import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/task.dart';

class PlanningTaskPickerButton extends StatelessWidget {
  final Task? selectedTask;
  final List<Task> pendingTasks;
  final bool enabled;
  final ValueChanged<Task?> onSelected;
  final bool isDark;

  const PlanningTaskPickerButton({
    super.key,
    required this.selectedTask,
    required this.pendingTasks,
    required this.enabled,
    required this.onSelected,
    required this.isDark,
  });

  void _openPicker(BuildContext context) {
    if (!enabled) return;
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
                'Seleziona obiettivo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            if (pendingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nessuna attività da completare.\nCreane una prima!',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pendingTasks.length,
                  itemBuilder: (context, index) {
                    final t = pendingTasks[index];
                    final selected = t.id == selectedTask?.id;
                    return InkWell(
                      onTap: () {
                        onSelected(t);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.priorita(t.priorita),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                t.titolo,
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
                  },
                ),
              ),
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
        onTap: enabled ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: enabled ? 0.05 : 0.02)
                : (enabled ? AppColors.surface : AppColors.background),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedTask?.titolo ?? 'Seleziona obiettivo',
                  style: TextStyle(
                    fontSize: 15,
                    color: selectedTask != null
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                color: enabled
                    ? AppColors.textMuted
                    : AppColors.textMuted.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}