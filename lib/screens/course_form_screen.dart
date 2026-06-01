import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';
import '../widgets/form.dart';

class CourseFormScreen extends StatefulWidget {
  final Course? courseToEdit;
  const CourseFormScreen({super.key, this.courseToEdit});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _docenteCtrl;
  late final TextEditingController _cfuCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _materialeCtrl;
  late final TextEditingController _votoDesideratoCtrl;
  late final TextEditingController _votoOttenutoCtrl;

  String _semestre = '1° Semestre · Anno I';
  String _stato = 'da_iniziare';

  bool get _isEditing => widget.courseToEdit != null;

  static const List<String> _semestri = [
    '1° Semestre · Anno I',
    '2° Semestre · Anno I',
    '1° Semestre · Anno II',
    '2° Semestre · Anno II',
    '1° Semestre · Anno III',
    '2° Semestre · Anno III',
    '1° Semestre · Anno IV', 
    '2° Semestre · Anno IV', 
    '1° Semestre · Anno V',  
    '2° Semestre · Anno V',  
  ];

  static const List<String> _stati = [
    'da_iniziare',
    'in_corso',
    'completato', 
    'superato',
  ];

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    if (text == 'da_iniziare') return 'Da iniziare';
    if (text == 'in_corso') return 'In corso';
    if (text == 'completato') return 'Frequentato';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    final c = widget.courseToEdit;
    _nomeCtrl = TextEditingController(text: c?.nome ?? '');
    _docenteCtrl = TextEditingController(text: c?.docente ?? '');
    _cfuCtrl = TextEditingController(text: c?.cfu.toString() ?? '');
    _noteCtrl = TextEditingController(text: c?.note ?? '');
    _materialeCtrl = TextEditingController(text: c?.materialeAssociato ?? '');
    _votoDesideratoCtrl = TextEditingController(text: _formatVoto(c?.votoDesiderato));
    _votoOttenutoCtrl = TextEditingController(text: _formatVoto(c?.votoOttenuto));
    _semestre = c?.semestre ?? '1° Semestre · Anno I';
    _stato = c?.stato ?? 'da_iniziare';
  }

  int? _parseVoto(String input) {
    final cleaned = input.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    if (cleaned == '30l' || cleaned == '30 l' || cleaned == '30 e lode' || cleaned == '30elode') {
      return 31;
    }
    return int.tryParse(cleaned);
  }

  String _formatVoto(int? voto) {
    if (voto == null) return '';
    if (voto >= 31) return '30L';
    return voto.toString();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _docenteCtrl.dispose();
    _cfuCtrl.dispose();
    _noteCtrl.dispose();
    _materialeCtrl.dispose();
    _votoDesideratoCtrl.dispose();
    _votoOttenutoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<PlannerProvider>(context, listen: false);

    final vDesiderato = _votoDesideratoCtrl.text.isEmpty ? null : _parseVoto(_votoDesideratoCtrl.text);
    final vOttenuto = (_stato == 'superato' && _votoOttenutoCtrl.text.isNotEmpty) ? _parseVoto(_votoOttenutoCtrl.text) : null;

    if (_isEditing) {
      final updated = widget.courseToEdit!.copyWith(
        nome: _nomeCtrl.text.trim(),
        docente: _docenteCtrl.text.trim(),
        cfu: int.parse(_cfuCtrl.text.trim()),
        semestre: _semestre,
        stato: _stato,
        votoDesiderato: vDesiderato,
        votoOttenuto: vOttenuto,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
        materialeAssociato: _materialeCtrl.text.isEmpty ? null : _materialeCtrl.text.trim(),
      );
      await provider.updateCourse(updated);
    } else {
      await provider.addCourse(
        nome: _nomeCtrl.text.trim(),
        docente: _docenteCtrl.text.trim(),
        cfu: int.parse(_cfuCtrl.text.trim()),
        semestre: _semestre,
        stato: _stato,
        votoDesiderato: vDesiderato,
        votoOttenuto: vOttenuto,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
        materialeAssociato: _materialeCtrl.text.isEmpty ? null : _materialeCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          _isEditing ? 'Modifica Corso' : 'Nuovo Corso',
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.w600, 
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.3
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
            const FormGroupHeader(label: 'Dati corso'),
            FormSettingsGroup(
              children: [
                FormTextFieldRow(
                  label: 'Nome',
                  controller: _nomeCtrl,
                  hint: 'es. Analisi 1',
                  required: true,
                ),
                FormTextFieldRow(
                  label: 'Docente',
                  controller: _docenteCtrl,
                  hint: 'es. Mario Rossi',
                  required: true,
                ),
                FormTextFieldRow(
                  label: 'CFU',
                  controller: _cfuCtrl,
                  hint: '1-30',
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obbligatorio';
                    final n = int.tryParse(v);
                    if (n == null) return 'Numero non valido';
                    if (n < 1) return 'Minimo 1 CFU';
                    if (n > 30) return 'Massimo 30 CFU';
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Stato e periodo'),
            FormSettingsGroup(
              children: [
                FormPickerRow(
                  label: 'Semestre',
                  value: _semestre,
                  onTap: () => _showSemestrePicker(context),
                ),
                FormPickerRow(
                  label: 'Stato',
                  value: _capitalize(_stato),
                  valueColor: AppColors.statoCorso(_stato),
                  onTap: () => _showStatoPicker(context),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Voti'),
            FormSettingsGroup(
              children: [
                FormTextFieldRow(
                  label: 'Voto desiderato',
                  controller: _votoDesideratoCtrl,
                  hint: '18-30 o 30L',
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = _parseVoto(v);
                    if (n == null || n < 18 || n > 31) return 'Voto tra 18 e 30 (o 30L)';
                    return null;
                  },
                ),
                if (_stato == 'superato')
                  FormTextFieldRow(
                    label: 'Voto ottenuto',
                    controller: _votoOttenutoCtrl,
                    hint: '18-30 o 30L',
                    keyboardType: TextInputType.text,
                    required: true,
                    validator: (v) {
                      if (_stato == 'superato' && (v == null || v.isEmpty)) return 'Inserisci il voto';
                      if (v != null && v.isNotEmpty) {
                        final n = _parseVoto(v);
                        if (n == null || n < 18 || n > 31) return 'Voto tra 18 e 30 (o 30L)';
                      }
                      return null;
                    },
                  ),
              ],
            ),

            const SizedBox(height: 24),
            const FormGroupHeader(label: 'Risorse'),
            FormSettingsGroup(
              children: [
                FormTextFieldRow(
                  label: 'Materiale',
                  controller: _materialeCtrl,
                  hint: 'libri, link, ecc.',
                ),
                FormTextAreaRow(
                  label: 'Note',
                  controller: _noteCtrl,
                  hint: 'aggiungi una nota',
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
                    backgroundColor: AppColors.pastelRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Salva modifiche' : 'Aggiungi corso',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSemestrePicker(BuildContext context) {
    _showIosPicker<String>(
      context: context,
      title: 'Semestre',
      options: _semestri,
      current: _semestre,
      labelBuilder: (s) => s,
      onSelected: (v) => setState(() => _semestre = v),
    );
  }

  void _showStatoPicker(BuildContext context) {
    _showIosPicker<String>(
      context: context,
      title: 'Stato',
      options: _stati,
      current: _stato,
      labelBuilder: _capitalize,
      onSelected: (v) {
        setState(() => _stato = v);
        if ((v == 'superato' || v == 'completato') &&
            _votoOttenutoCtrl.text.isEmpty &&
            _isEditing &&
            widget.courseToEdit != null) {
          final media = context.read<PlannerProvider>().getAverageExamsGrade(widget.courseToEdit!.id);
          if (media != null) {
            final arrotondato = media.round().clamp(18, 31);
            _votoOttenutoCtrl.text = arrotondato >= 31 ? '30L' : '$arrotondato';
          }
        }
      },
    );
  }
}

void _showIosPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T current,
  required String Function(T) labelBuilder,
  required ValueChanged<T> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17, 
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final value = options[index];
                  final selected = value == current;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onSelected(value);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                labelBuilder(value),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (selected) const Icon(Icons.check_rounded, color: AppColors.iosBlue, size: 22),
                          ],
                        ),
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
    ),
  );
}