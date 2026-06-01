import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../models/task.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../utils/app_colors.dart';
import '../widgets/form.dart'; 

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

  static const List<String> _prioritaOptions = [
    'alta',
    'media',
    'bassa',
  ];

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _titoloCtrl = TextEditingController(text: t?.titolo ?? '');
    _descrizioneCtrl = TextEditingController(text: t?.descrizione ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _tempoStimatoCtrl = TextEditingController(text: t?.tempoStimato?.toString() ?? '');

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

  Future<void> _pickDate() async {
    DateTime tempDate = _scadenza ?? DateTime.now();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) => Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
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
                      color: Theme.of(ctx).dividerColor, 
                      borderRadius: BorderRadius.circular(2)
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() => _scadenza = null);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Rimuovi', style: TextStyle(color: AppColors.danger, fontSize: 16)),
                        ),
                        Text('Scadenza', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface)),
                        TextButton(
                          onPressed: () {
                            setState(() => _scadenza = tempDate);
                            Navigator.pop(ctx);
                          },
                          child: const Text('OK', style: TextStyle(color: AppColors.iosBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.iosBlue),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_scadenza == null) {
      setState(() {});
      return;
    }

    final provider = Provider.of<PlannerProvider>(context, listen: false);
    final int? stimato = _tempoStimatoCtrl.text.isEmpty ? null : int.tryParse(_tempoStimatoCtrl.text.trim());

    if (_isEditing) {
      final updated = widget.taskToEdit!.copyWith(
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrizioneCtrl.text.trim(),
        courseId: _courseId,
        examId: _examId,
        scadenza: _scadenza,
        priorita: _priorita,
        completata: _completata,
        tempoStimato: stimato,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      );
      await provider.updateTask(updated);
    } else {
      await provider.addTask(
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrizioneCtrl.text.trim(),
        courseId: _courseId,
        examId: _examId,
        scadenza: _scadenza,
        priorita: _priorita,
        completata: _completata,
        tempoStimato: stimato,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.iosBlue,
            padding: const EdgeInsets.only(left: 16),
          ),
          child: const Text('Annulla', style: TextStyle(fontSize: 16)),
        ),
        leadingWidth: 88,
        title: Text(
          _isEditing ? 'Modifica Attività' : 'Nuova Attività',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
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
            child: const Text('Salva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            const FormGroupHeader(label: 'Dettagli'),
            FormSettingsGroup(
              children: [
                FormTextFieldRow(
                  label: 'Titolo',
                  controller: _titoloCtrl,
                  hint: 'Cosa devi fare?',
                  required: true,
                ),
                FormTextFieldRow(
                  label: 'Descrizione',
                  controller: _descrizioneCtrl,
                  hint: 'opzionale',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Pianificazione'),
            FormSettingsGroup(
              children: [
                FormPickerRow(
                  label: 'Scadenza',
                  value: _scadenza == null ? 'Nessuna' : DateFormat('dd MMM yyyy', 'it_IT').format(_scadenza!),
                  onTap: _pickDate,
                  hasError: _scadenza == null && _formKey.currentState != null,
                ),
                FormPickerRow(
                  label: 'Priorità',
                  value: _capitalize(_priorita),
                  valueColor: AppColors.priorita(_priorita),
                  onTap: () => _showPrioritaPicker(context),
                ),
                FormTextFieldRow(
                  label: 'Tempo stimato',
                  controller: _tempoStimatoCtrl,
                  hint: 'Minuti (opzionale)',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Collegamento'),
            FormSettingsGroup(
              children: [
                FormPickerRow(
                  label: 'Corso',
                  value: _courseId == null ? 'Nessuno' : (provider.getCourseById(_courseId!)?.nome ?? 'Nessuno'),
                  onTap: () => _showCoursePicker(context, provider.courses),
                ),
                FormPickerRow(
                  label: 'Esame',
                  value: _examId == null ? 'Nessuno' : (provider.getExamById(_examId!)?.titolo ?? 'Nessuno'),
                  disabled: _courseId == null,
                  onTap: () {
                    if (_courseId == null) return;
                    final examsForCourse = provider.exams.where((e) => e.courseId == _courseId).toList();
                    _showExamPicker(context, examsForCourse);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Avanzamento'),
            FormSettingsGroup(
              children: [
                FormSwitchRow(
                  label: 'Completata',
                  value: _completata,
                  onChanged: (v) => setState(() => _completata = v),
                ),
                FormTextAreaRow(
                  label: 'Note',
                  controller: _noteCtrl,
                  hint: 'Appunti aggiuntivi',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrioritaPicker(BuildContext context) {
    _showOptionsSheet<String>(
      context: context,
      title: 'Priorità',
      current: _priorita,
      options: _prioritaOptions,
      labelBuilder: _capitalize,
      onSelected: (v) => setState(() => _priorita = v),
    );
  }

  void _showCoursePicker(BuildContext context, List<Course> courses) {
    final options = [null, ...courses.map((c) => c.id)];
    _showOptionsSheet<String?>(
      context: context,
      title: 'Corso associato',
      current: _courseId,
      options: options,
      labelBuilder: (id) => id == null ? 'Nessuno' : courses.firstWhere((c) => c.id == id).nome,
      onSelected: (id) {
        setState(() {
          _courseId = id;
          if (id == null) _examId = null;
        });
      },
    );
  }

  void _showExamPicker(BuildContext context, List<Exam> exams) {
    final options = [null, ...exams.map((e) => e.id)];
    _showOptionsSheet<String?>(
      context: context,
      title: 'Esame associato',
      current: _examId,
      options: options,
      labelBuilder: (id) => id == null ? 'Nessuno' : exams.firstWhere((e) => e.id == id).titolo,
      onSelected: (id) => setState(() => _examId = id),
    );
  }

  void _showOptionsSheet<T>({
    required BuildContext context,
    required String title,
    required T? current,
    required List<T> options,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor, 
                  borderRadius: BorderRadius.circular(2)
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options.map((opt) {
                  final isSelected = opt == current;
                  return InkWell(
                    onTap: () {
                      onSelected(opt);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              labelBuilder(opt),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_rounded, color: AppColors.iosBlue, size: 22),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}