import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../models/task.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../utils/app_colors.dart';

/// TaskFormScreen — Form per creare/modificare un'Attività.
class TaskFormScreen extends StatefulWidget {
  final Task? taskToEdit;
  final String? defaultCourseId;
  final String? defaultExamId;

  const TaskFormScreen({
    super.key,
    this.taskToEdit,
    this.defaultCourseId,
    this.defaultExamId,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titoloCtrl;
  late final TextEditingController _descrizioneCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _tempoStimatoCtrl;

  String? _courseId;
  String? _examId;
  DateTime? _scadenza;
  String _priorita = 'media';
  bool _completata = false;

  bool get _isEditing => widget.taskToEdit != null;

  static const List<(String, String)> _prioritaOptions = [
    ('alta', 'Alta'),
    ('media', 'Media'),
    ('bassa', 'Bassa'),
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _titoloCtrl = TextEditingController(text: t?.titolo ?? '');
    _descrizioneCtrl =
        TextEditingController(text: t?.descrizione ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _tempoStimatoCtrl = TextEditingController(
        text: t?.tempoStimato?.toString() ?? '');
    _courseId = t?.courseId ?? widget.defaultCourseId;
    _examId = t?.examId ?? widget.defaultExamId;
    _scadenza = t?.scadenza;
    _priorita = t?.priorita ?? 'media';
    _completata = t?.completata ?? false;
  }

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _descrizioneCtrl.dispose();
    _noteCtrl.dispose();
    _tempoStimatoCtrl.dispose();
    super.dispose();
  }

  // Helper per mostrare una stringa pulita nel selettore dell'esame
  String _formatTipologia(String t) {
    switch (t.toLowerCase()) {
      case 'scritto':
        return 'Scritto';
      case 'orale':
        return 'Orale';
      case 'intercorso':
        return 'Intercorso';
      case 'consegna':
        return 'Consegna';
      case 'progetto':
        return 'Progetto';
      default:
        if (t.isEmpty) return t;
        return t[0].toUpperCase() + t.substring(1).toLowerCase();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scadenza == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Devi selezionare una data di scadenza!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.danger, // Usa il rosso per l'errore
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return; // <-- Questo blocca il salvataggio se manca la data!
    }
    final provider = context.read<PlannerProvider>();

    final tempoStimato = _tempoStimatoCtrl.text.isEmpty
        ? null
        : int.tryParse(_tempoStimatoCtrl.text);

    if (_isEditing) {
      final updated = widget.taskToEdit!.copyWith(
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrizioneCtrl.text.isEmpty
            ? null
            : _descrizioneCtrl.text.trim(),
        courseId: _courseId,
        examId: _examId,
        scadenza: _scadenza,
        priorita: _priorita,
        completata: _completata,
        tempoStimato: tempoStimato,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      );
      await provider.updateTask(updated);
    } else {
      await provider.addTask(
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrizioneCtrl.text.isEmpty
            ? null
            : _descrizioneCtrl.text.trim(),
        courseId: _courseId,
        examId: _examId,
        scadenza: _scadenza,
        priorita: _priorita,
        completata: _completata,
        tempoStimato: tempoStimato,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  String _prioritaLabel(String p) => _prioritaOptions
      .firstWhere((e) => e.$1 == p, orElse: () => (p, p))
      .$2;

  Future<void> _pickScadenza() async {
    DateTime tempDate = _scadenza ?? DateTime.now().add(const Duration(days: 3));
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : AppColors.groupedSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Annulla',
                              style: TextStyle(
                                  color: AppColors.iosBlue, fontSize: 16)),
                        ),
                        Text('Data scadenza',
                            style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            )),
                        TextButton(
                          onPressed: () {
                            setState(() => _scadenza = tempDate);
                            Navigator.pop(ctx);
                          },
                          child: Text('OK',
                              style: TextStyle(
                                  color: AppColors.iosBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: Theme.of(ctx).colorScheme.copyWith(
                        primary: AppColors.pastelGreen,
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: tempDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      onDateChanged: (d) => setSheet(() => tempDate = d),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF000000)
        : AppColors.groupedBackground;

    final provider = context.watch<PlannerProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.iosBlue,
            padding: const EdgeInsets.only(left: 16),
          ),
          child: const Text(
            'Annulla',
            style: TextStyle(fontSize: 16),
          ),
        ),
        leadingWidth: 88,
        title: Text(
          _isEditing ? 'Modifica Attività' : 'Nuova Attività',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.iosBlue,
              padding: const EdgeInsets.only(right: 16),
            ),
            child: const Text(
              'Salva',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            _GroupHeader(label: 'Attività'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextFieldRow(
                  label: 'Titolo',
                  controller: _titoloCtrl,
                  hint: 'es. Capitolo 3',
                  required: true,
                  isDark: isDark,
                ),
                _TextFieldRow(
                  label: 'Descrizione',
                  controller: _descrizioneCtrl,
                  hint: 'opzionale',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GroupHeader(label: 'Collegamenti'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _PickerRow(
                  label: 'Corso',
                  value: _courseId == null
                      ? 'Nessuno'
                      : (provider.getCourseById(_courseId!)?.nome ??
                          'Nessuno'),
                  onTap: () => _showCoursePicker(
                      context, isDark, provider.courses),
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Esame',
                  value: _examId == null
                      ? 'Nessuno'
                      : (() {
                          final ex = provider.getExamById(_examId!);
                          if (ex == null) return 'Nessuno';
                          final tipo = _formatTipologia(ex.tipologia);
                          final dataStr = DateFormat('dd/MM/yyyy', 'it_IT').format(ex.data);
                          return '$tipo ($dataStr)';
                        })(),
                  onTap: () => _showExamPicker(
                      context, isDark, provider.exams),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GroupHeader(label: 'Pianificazione'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _PickerRow(
                  label: 'Scadenza',
                  value: _scadenza == null
                      ? 'Nessuna'
                      : DateFormat('dd MMM yyyy', 'it_IT')
                          .format(_scadenza!),
                  onTap: _pickScadenza,
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Priorità',
                  value: _prioritaLabel(_priorita),
                  valueColor: AppColors.priorita(_priorita),
                  onTap: () => _showPrioritaPicker(context, isDark),
                  isDark: isDark,
                ),
                _TextFieldRow(
                  label: 'Tempo stimato',
                  controller: _tempoStimatoCtrl,
                  hint: 'minuti',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (int.tryParse(v) == null) {
                      return 'Numero non valido';
                    }
                    return null;
                  },
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GroupHeader(label: 'Stato'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _SwitchRow(
                  label: 'Completata',
                  value: _completata,
                  onChanged: (v) => setState(() => _completata = v),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GroupHeader(label: 'Note'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextAreaRow(
                  label: 'Note aggiuntive',
                  controller: _noteCtrl,
                  hint: 'opzionale',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pastelGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isEditing
                        ? 'Salva modifiche'
                        : 'Aggiungi attività',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoursePicker(
      BuildContext context, bool isDark, List<Course> courses) {
    _showIosPicker<String?>(
      context: context,
      isDark: isDark,
      title: 'Corso',
      options: [
        (null, 'Nessuno'),
        ...courses.map((c) => (c.id, c.nome)),
      ],
      current: _courseId,
      onSelected: (v) {
        setState(() {
          _courseId = v;
          _examId = null; // Resetta l'esame se cambia il corso
        });
      },
    );
  }

  void _showExamPicker(
      BuildContext context, bool isDark, List<Exam> exams) {
    final filteredExams = _courseId == null
        ? exams
        : exams.where((e) => e.courseId == _courseId).toList();
    _showIosPicker<String?>(
      context: context,
      isDark: isDark,
      title: 'Esame',
      options: [
        (null, 'Nessuno'),
        ...filteredExams.map((e) {
          final tipo = _formatTipologia(e.tipologia);
          final dataStr = DateFormat('dd/MM/yyyy', 'it_IT').format(e.data);
          return (e.id, '$tipo ($dataStr)');
        }),
      ],
      current: _examId,
      onSelected: (v) => setState(() => _examId = v),
    );
  }

  void _showPrioritaPicker(BuildContext context, bool isDark) {
    _showIosPicker<String>(
      context: context,
      isDark: isDark,
      title: 'Priorità',
      options: _prioritaOptions,
      current: _priorita,
      onSelected: (v) => setState(() => _priorita = v),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IOS-STYLE BOTTOM SHEET PICKER 
// ═══════════════════════════════════════════════════════════════
void _showIosPicker<T>({
  required BuildContext context,
  required bool isDark,
  required String title,
  required List<(T, String)> options,
  required T current,
  required ValueChanged<T> onSelected,
}) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...options.map((opt) {
            final (value, label) = opt;
            final selected = value == current;
            return InkWell(
              onTap: () {
                onSelected(value);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
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

// ═══════════════════════════════════════════════════════════════
// COMPONENTI UI iOS-Settings
// ═══════════════════════════════════════════════════════════════
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsGroup({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E)
              : AppColors.groupedSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: _withDividers(children, isDark),
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> rows, bool isDark) {
    if (rows.length <= 1) return rows;
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.groupedDivider,
          ),
        ));
      }
    }
    return result;
  }
}

class _TextFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;
  final bool required;
  final String? Function(String?)? validator;
  final bool isDark;

  const _TextFieldRow({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.validator,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.end,
              cursorColor: AppColors.iosBlue,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: TextStyle(
                  fontSize: 11,
                  color: AppColors.danger,
                  height: 0.8,
                ),
              ),
              validator: validator ??
                  (required
                      ? (v) => (v == null || v.isEmpty)
                          ? 'Campo obbligatorio'
                          : null
                      : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAreaRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool isDark;

  const _TextAreaRow({
    required this.label,
    required this.controller,
    this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            cursorColor: AppColors.iosBlue,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? Colors.white60
                  : AppColors.textSecondary,
              letterSpacing: -0.2,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;
  final bool isDark;

  const _PickerRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ??
                        (isDark
                            ? Colors.white60
                            : AppColors.textSecondary),
                    letterSpacing: -0.3,
                    fontWeight: valueColor != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.iosBlue,
          ),
        ],
      ),
    );
  }
}