import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/exam.dart';
import '../utils/app_colors.dart';

class ExamFormScreen extends StatefulWidget {
  final Exam? exam; // null = inserimento, altrimenti modifica
  const ExamFormScreen({super.key, this.exam});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titoloCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _votoCtrl;

  String? _courseId;
  DateTime _data = DateTime.now().add(const Duration(days: 7));
  String _tipologia = 'esame';
  String _priorita = 'media';
  String _stato = 'programmato';

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _titoloCtrl = TextEditingController(text: e?.titolo ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _votoCtrl =
        TextEditingController(text: e?.voto?.toString() ?? '');
    _courseId = e?.courseId;
    _data = e?.data ?? DateTime.now().add(const Duration(days: 7));
    _tipologia = e?.tipologia ?? 'esame';
    _priorita = e?.priorita ?? 'media';
    _stato = e?.stato ?? 'programmato';
  }

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _noteCtrl.dispose();
    _votoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un corso')),
      );
      return;
    }

    final provider = context.read<PlannerProvider>();

    if (_isEditing) {
      final updated = widget.exam!.copyWith(
        titolo: _titoloCtrl.text.trim(),
        courseId: _courseId!,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: _votoCtrl.text.isEmpty
            ? null
            : int.tryParse(_votoCtrl.text),
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      );
      await provider.updateExam(updated);
    } else {
      await provider.addExam(
        titolo: _titoloCtrl.text.trim(),
        courseId: _courseId!,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: _votoCtrl.text.isEmpty
            ? null
            : int.tryParse(_votoCtrl.text),
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Widget _buildTitleBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 20,
              color: isDark ? Colors.white : AppColors.exams),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'Modifica Esame' : 'Nuovo Esame',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.exams,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _buildTitleBadge(context),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Salva'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Titolo
            TextFormField(
              controller: _titoloCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),

            // Corso associato (obbligatorio per Exam)
            DropdownButtonFormField<String>(
              value: _courseId,
              decoration: const InputDecoration(
                labelText: 'Corso associato *',
                border: OutlineInputBorder(),
              ),
              items: provider.courses
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nome),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _courseId = v),
              validator: (v) =>
                  v == null ? 'Seleziona un corso' : null,
            ),
            const SizedBox(height: 12),

            // Data — bottone che apre il DatePicker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_data.day}/${_data.month}/${_data.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tipologia
            DropdownButtonFormField<String>(
              value: _tipologia,
              decoration: const InputDecoration(
                labelText: 'Tipologia',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'esame', child: Text('Esame')),
                DropdownMenuItem(
                    value: 'appello', child: Text('Appello')),
                DropdownMenuItem(
                    value: 'consegna', child: Text('Consegna')),
                DropdownMenuItem(
                    value: 'progetto', child: Text('Progetto')),
              ],
              onChanged: (v) => setState(() => _tipologia = v!),
            ),
            const SizedBox(height: 12),

            // Priorità
            DropdownButtonFormField<String>(
              value: _priorita,
              decoration: const InputDecoration(
                labelText: 'Priorità',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'alta', child: Text('Alta')),
                DropdownMenuItem(value: 'media', child: Text('Media')),
                DropdownMenuItem(value: 'bassa', child: Text('Bassa')),
              ],
              onChanged: (v) => setState(() => _priorita = v!),
            ),
            const SizedBox(height: 12),

            // Stato
            DropdownButtonFormField<String>(
              value: _stato,
              decoration: const InputDecoration(
                labelText: 'Stato',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'programmato', child: Text('Programmato')),
                DropdownMenuItem(
                    value: 'completato', child: Text('Completato')),
                DropdownMenuItem(
                    value: 'annullato', child: Text('Annullato')),
              ],
              onChanged: (v) => setState(() => _stato = v!),
            ),
            const SizedBox(height: 12),

            // Voto (opzionale, visibile solo se completato)
            if (_stato == 'completato')
              Column(
                children: [
                  TextFormField(
                    controller: _votoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Voto ottenuto (opzionale)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 18 || n > 30) {
                        return 'Inserisci un voto tra 18 e 30';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (opzionale)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Pulsante salva
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.exams,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? 'Salva modifiche' : 'Aggiungi esame',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}