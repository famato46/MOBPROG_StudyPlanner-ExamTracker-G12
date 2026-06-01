import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../models/exam.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';
import '../widgets/form.dart'; 

class ExamFormScreen extends StatefulWidget {
  final Exam? exam;
  const ExamFormScreen({super.key, this.exam});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _noteCtrl;
  late final TextEditingController _votoCtrl;

  String? _courseId;
  DateTime _data = DateTime.now().add(const Duration(days: 7));
  String _tipologia = 'scritto';
  String _priorita = 'media';
  String _stato = 'programmato';

  bool get _isEditing => widget.exam != null;

  static const List<String> _tipologie = [
    'scritto', 'orale', 'intercorso', 'consegna', 'progetto',
  ];

  static const List<String> _prioritaOptions = [
    'alta', 'media', 'bassa',
  ];

  static const List<String> _stati = [
    'programmato', 'completato', 'annullato',
  ];

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    if (text == 'da_iniziare') return 'Da iniziare';
    if (text == 'in_corso') return 'In corso';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  int? _parseVoto(String input) {
    final cleaned = input.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    if (cleaned == '30l' || cleaned == '30 l' || cleaned == '30 e lode' || cleaned == '30elode') return 31;
    return int.tryParse(cleaned);
  }

  String _formatVoto(int? voto) {
    if (voto == null) return '';
    if (voto >= 31) return '30L';
    return voto.toString();
  }

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _votoCtrl = TextEditingController(text: _formatVoto(e?.voto));
    _courseId = e?.courseId;
    _data = e?.data ?? DateTime.now().add(const Duration(days: 7));
    _tipologia = e?.tipologia ?? 'scritto';
    _priorita = e?.priorita ?? 'media';
    _stato = e?.stato ?? 'programmato';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _votoCtrl.dispose();
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
                        Text('Data esame', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface)),
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
                      colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.pastelBlue),
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
        const SnackBar(content: Text('Seleziona un corso associato prima di salvare.')),
      );
      return;
    }

    final provider = context.read<PlannerProvider>();
    final nomeCorso = provider.getCourseById(_courseId!)?.nome ?? 'Esame';

    final votoFinale = _stato == 'completato' && _votoCtrl.text.isNotEmpty
        ? _parseVoto(_votoCtrl.text) : null;

    if (_isEditing) {
      final updated = widget.exam!.copyWith(
        titolo: nomeCorso,
        courseId: _courseId!,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: votoFinale,
        clearVoto: votoFinale == null,
        note: _noteCtrl.text.isEmpty ? '' : _noteCtrl.text.trim(),
      );
      await provider.updateExam(updated);
    } else {
      await provider.addExam(
        titolo: nomeCorso,
        courseId: _courseId!,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: votoFinale,
        note: _noteCtrl.text.isEmpty ? '' : _noteCtrl.text.trim(),
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
          _isEditing ? 'Modifica Prova' : 'Nuova Prova',
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
            const FormGroupHeader(label: 'Esame'),
            FormSettingsGroup(
              children: [
                FormPickerRow(
                  label: 'Corso',
                  value: _courseId == null ? 'Seleziona...' : (provider.getCourseById(_courseId!)?.nome ?? 'Seleziona...'),
                  valueColor: _courseId == null ? AppColors.danger : null,
                  onTap: () => _showCoursePicker(context, provider.courses),
                ),
                FormPickerRow(
                  label: 'Tipologia',
                  value: _capitalize(_tipologia),
                  onTap: () => _showTipologiaPicker(context),
                ),
                FormPickerRow(
                  label: 'Data',
                  value: DateFormat('dd MMM yyyy', 'it_IT').format(_data),
                  onTap: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Classificazione'),
            FormSettingsGroup(
              children: [
                FormPickerRow(
                  label: 'Priorità',
                  value: _capitalize(_priorita),
                  valueColor: AppColors.priorita(_priorita),
                  onTap: () => _showPrioritaPicker(context),
                ),
                FormPickerRow(
                  label: 'Stato',
                  value: _capitalize(_stato),
                  onTap: () => _showStatoPicker(context),
                ),
              ],
            ),
            if (_stato == 'completato') ...[
              const SizedBox(height: 24),
              const FormGroupHeader(label: 'Risultato'),
              FormSettingsGroup(
                children: [
                  FormTextFieldRow(
                    label: 'Voto',
                    controller: _votoCtrl,
                    hint: _tipologia == 'consegna' ? 'es. 28 (opzionale)' : 'es. 28 o 30L',
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        if (_tipologia == 'consegna') return null; 
                        return 'Inserisci il voto';
                      }
                      final n = _parseVoto(v);
                      if (n == null || n < 18 || n > 31) return 'Tra 18 e 30 (o 30L)';
                      return null;
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Note'),
            FormSettingsGroup(
              children: [
                FormTextAreaRow(
                  label: 'Note',
                  controller: _noteCtrl,
                  hint: 'opzionale',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCoursePicker(BuildContext context, List<Course> courses) {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun corso disponibile. Crealo prima!')));
      return;
    }
    _showOptionsSheet<String>(
      context: context,
      title: 'Corso associato',
      current: _courseId,
      options: courses.map((c) => c.id).toList(),
      labelBuilder: (id) => courses.firstWhere((c) => c.id == id).nome,
      onSelected: (id) => setState(() => _courseId = id),
    );
  }

  void _showTipologiaPicker(BuildContext context) {
    _showOptionsSheet<String>(
      context: context,
      title: 'Tipologia',
      current: _tipologia,
      options: _tipologie,
      labelBuilder: _capitalize,
      onSelected: (v) {
        setState(() {
          _tipologia = v;
          _formKey.currentState?.validate();
        });
      },
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

  void _showStatoPicker(BuildContext context) {
    _showOptionsSheet<String>(
      context: context,
      title: 'Stato',
      current: _stato,
      options: _stati,
      labelBuilder: _capitalize,
      onSelected: (v) {
        setState(() {
          _stato = v;
          if (_stato != 'completato') _votoCtrl.clear();
        });
      },
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
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