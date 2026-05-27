import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';

class CourseFormScreen extends StatefulWidget {
  // CORREZIONE: Rinominato in courseToEdit per uniformità con CoursesScreen
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
  // AGGIUNTA: Controller per il voto effettivamente registrato all'esame
  late final TextEditingController _votoOttenutoCtrl;

  String _semestre = 'Primo semestre 2024/25';
  String _stato = 'da_iniziare';

  bool get _isEditing => widget.courseToEdit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.courseToEdit;
    _nomeCtrl = TextEditingController(text: c?.nome ?? '');
    _docenteCtrl = TextEditingController(text: c?.docente ?? '');
    _cfuCtrl = TextEditingController(text: c?.cfu.toString() ?? '');
    _noteCtrl = TextEditingController(text: c?.note ?? '');
    _materialeCtrl = TextEditingController(text: c?.materialeAssociato ?? '');
    _votoDesideratoCtrl = TextEditingController(text: c?.votoDesiderato?.toString() ?? '');
    _votoOttenutoCtrl = TextEditingController(text: c?.votoOttenuto?.toString() ?? '');
    _semestre = c?.semestre ?? 'Primo semestre 2024/25';
    _stato = c?.stato ?? 'da_iniziare';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _docenteCtrl.dispose();
    _cfuCtrl.dispose();
    _noteCtrl.dispose();
    _materialeCtrl.dispose();
    _votoDesideratoCtrl.dispose();
    _votoOttenutoCtrl.dispose(); // Ricordiamoci di fare il dispose
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<PlannerProvider>();

    // Parsing sicuro dei voti
    final vDesiderato = _votoDesideratoCtrl.text.isEmpty ? null : int.tryParse(_votoDesideratoCtrl.text);
    // Il voto ottenuto ha senso solo se il corso è stato superato
    final vOttenuto = (_stato == 'superato' && _votoOttenutoCtrl.text.isNotEmpty) 
        ? int.tryParse(_votoOttenutoCtrl.text) 
        : null;

    if (_isEditing) {
      final updated = widget.courseToEdit!.copyWith(
        nome: _nomeCtrl.text.trim(),
        docente: _docenteCtrl.text.trim(),
        cfu: int.parse(_cfuCtrl.text.trim()),
        semestre: _semestre,
        stato: _stato,
        votoDesiderato: vDesiderato,
        votoOttenuto: vOttenuto, // AGGIUNTO
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
        votoOttenuto: vOttenuto, // AGGIUNTO (se inserito direttamente come superato)
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
        materialeAssociato: _materialeCtrl.text.isEmpty ? null : _materialeCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.coursesLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Corso' : 'Nuovo Corso'),
        backgroundColor: AppColors.coursesLight,
        foregroundColor: AppColors.coursesDark,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Salva', style: TextStyle(color: AppColors.coursesDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField(
              controller: _nomeCtrl,
              label: 'Nome del corso *',
              validator: (v) => v == null || v.isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _docenteCtrl,
              label: 'Docente *',
              validator: (v) => v == null || v.isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _cfuCtrl,
              label: 'CFU *',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obbligatorio';
                if (int.tryParse(v) == null) return 'Inserisci un numero';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _semestre,
              decoration: const InputDecoration(
                labelText: 'Semestre',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: const [
                DropdownMenuItem(value: 'Primo semestre 2024/25', child: Text('Primo semestre 2024/25')),
                DropdownMenuItem(value: 'Secondo semestre 2024/25', child: Text('Secondo semestre 2024/25')),
                DropdownMenuItem(value: 'Primo semestre 2025/26', child: Text('Primo semestre 2025/26')),
                DropdownMenuItem(value: 'Secondo semestre 2025/26', child: Text('Secondo semestre 2025/26')),
              ],
              onChanged: (v) => setState(() => _semestre = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _stato,
              decoration: const InputDecoration(
                labelText: 'Stato',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: const [
                DropdownMenuItem(value: 'da_iniziare', child: Text('Da iniziare')),
                DropdownMenuItem(value: 'in_corso', child: Text('In corso')),
                DropdownMenuItem(value: 'da_ripassare', child: Text('Da ripassare')),
                DropdownMenuItem(value: 'completato', child: Text('Completato')),
                DropdownMenuItem(value: 'superato', child: Text('Superato')),
              ],
              onChanged: (v) => setState(() => _stato = v!),
            ),
            const SizedBox(height: 12),
            
            // Layout dinamico per i voti
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _votoDesideratoCtrl,
                    label: 'Voto desiderato',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 18 || n > 30) return 'Voto tra 18 e 30';
                      return null;
                    },
                  ),
                ),
                // Mostra il campo Voto Ottenuto solo se lo stato è impostato su 'superato'
                if (_stato == 'superato') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _votoOttenutoCtrl,
                      label: 'Voto ottenuto *',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_stato == 'superato' && (v == null || v.isEmpty)) return 'Inserisci il voto';
                        final n = int.tryParse(v!);
                        if (n == null || n < 18 || n > 31) return 'Voto tra 18 e 30L'; // 31 può rappresentare il 30 e lode
                        return null;
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _materialeCtrl,
              label: 'Materiale/riferimenti (opzionale)',
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _noteCtrl,
              label: 'Note (opzionale)',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.courses,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isEditing ? 'Salva modifiche' : 'Aggiungi corso',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: const OutlineInputBorder(),
      ),
    );
  }
}