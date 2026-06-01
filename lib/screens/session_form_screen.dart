import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../models/study_session.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../utils/app_colors.dart';
import '../widgets/form.dart'; // WIDGET CONDIVISI

class SessionFormScreen extends StatefulWidget {
  final StudySession? sessione; 
  final DateTime? dataIniziale; 

  const SessionFormScreen({super.key, this.sessione, this.dataIniziale});

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titoloCtrl;
  late final TextEditingController _durataCtrl;

  String? _courseId;
  String? _examId; 
  DateTime _data = DateTime.now();
  String _tipo = 'studio';

  bool get _isEditing => widget.sessione != null;

  static const List<String> _tipi = [
    'studio','ripasso','esercitazione','progetto','consegna',
  ];

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    final s = widget.sessione;
    _titoloCtrl = TextEditingController(text: s?.titolo ?? '');
    _durataCtrl = TextEditingController(text: s?.durataPianificata.toString() ?? '60');
    _courseId = s?.courseId;
    _examId = s?.examId;
    _data = s?.data ?? widget.dataIniziale ?? DateTime.now();
    _tipo = s?.tipo ?? 'studio';
  }

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _durataCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime tempDate = _data;
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
                          child: const Text('Annulla', style: TextStyle(color: AppColors.iosBlue, fontSize: 16)),
                        ),
                        Text('Data sessione', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface)),
                        TextButton(
                          onPressed: () {
                            setState(() => _data = tempDate);
                            Navigator.pop(ctx);
                          },
                          child: const Text('OK', style: TextStyle(color: AppColors.iosBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.planning),
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
    
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona il Corso per questa sessione')),
      );
      return;
    }

    final provider = context.read<PlannerProvider>();
    final int durata = int.parse(_durataCtrl.text.trim());

    if (_isEditing) {
      final updated = widget.sessione!.copyWith(
        titolo: _titoloCtrl.text.trim(),
        courseId: _courseId,
        examId: _examId,
        data: _data,
        durataPianificata: durata,
        tipo: _tipo,
      );
      await provider.updateStudySession(updated);
    } else {
      await provider.addStudySession(
        titolo: _titoloCtrl.text.trim(),
        courseId: _courseId,
        examId: _examId,
        data: _data,
        durataPianificata: durata,
        tipo: _tipo,
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
          _isEditing ? 'Modifica Sessione' : 'Nuova Sessione',
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
            const FormGroupHeader(label: 'Dettagli sessione'),
            FormSettingsGroup(
              children: [
                FormTextFieldRow(
                  label: 'Titolo',
                  controller: _titoloCtrl,
                  hint: 'es. Capitolo 1 e 2',
                  required: true,
                ),
                FormPickerRow(
                  label: 'Tipo',
                  value: _capitalize(_tipo),
                  onTap: () => _showTipiPicker(context),
                ),
                FormPickerRow(
                  label: 'Data',
                  value: DateFormat('dd MMM yyyy', 'it_IT').format(_data),
                  onTap: _pickDate,
                ),
                FormTextFieldRow(
                  label: 'Durata (min)',
                  controller: _durataCtrl,
                  hint: 'es. 60',
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obbligatorio';
                    if (int.tryParse(v) == null) return 'Numero non valido';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Collegamento'),
            FormSettingsGroup(
              children: [
                FormPickerRow(
                  label: 'Corso',
                  value: _courseId == null
                      ? 'Seleziona...'
                      : (provider.getCourseById(_courseId!)?.nome ?? 'Seleziona...'),
                  valueColor: _courseId == null ? AppColors.danger : null,
                  onTap: () => _showCoursePicker(context, provider.courses),
                ),
                FormPickerRow(
                  label: 'Esame',
                  value: _examId == null
                      ? 'Nessuno'
                      : (provider.getExamById(_examId!)?.titolo ?? 'Nessuno'),
                  disabled: _courseId == null,
                  onTap: () {
                    if (_courseId == null) return;
                    final examsForCourse = provider.exams.where((e) => e.courseId == _courseId).toList();
                    _showExamPicker(context, examsForCourse);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTipiPicker(BuildContext context) {
    _showOptionsSheet<String>(
      context: context,
      title: 'Tipo Sessione',
      current: _tipo,
      options: _tipi,
      labelBuilder: _capitalize,
      onSelected: (v) => setState(() => _tipo = v),
    );
  }

  void _showCoursePicker(BuildContext context, List<Course> courses) {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun corso disponibile. Crealo prima!')));
      return;
    }
    _showOptionsSheet<String>(
      context: context,
      title: 'Corso',
      current: _courseId,
      options: courses.map((c) => c.id).toList(),
      labelBuilder: (id) => courses.firstWhere((c) => c.id == id).nome,
      onSelected: (id) {
        setState(() {
          _courseId = id;
          _examId = null;
        });
      },
    );
  }

  void _showExamPicker(BuildContext context, List<Exam> exams) {
    if (exams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun esame in programma per questo corso.')));
      return;
    }
    final options = [null, ...exams.map((e) => e.id)];
    _showOptionsSheet<String?>(
      context: context,
      title: 'Esame',
      current: _examId,
      options: options,
      labelBuilder: (id) => id == null ? 'Nessun esame' : exams.firstWhere((e) => e.id == id).titolo,
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