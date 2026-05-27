import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../models/exam.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';

/// ExamFormScreen — Form Apple-style.
///
/// Riscritto per essere coerente con CourseFormScreen e TaskFormScreen:
/// layout iOS Settings con gruppi grigi arrotondati, righe label/valore,
/// picker bottom-sheet per i campi non testuali.
class ExamFormScreen extends StatefulWidget {
  final Exam? exam;
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

  static const List<(String, String)> _tipologie = [
    ('esame', 'Esame'),
    ('appello', 'Appello'),
    ('consegna', 'Consegna'),
    ('progetto', 'Progetto'),
  ];

  static const List<(String, String)> _priorita_options = [
    ('alta', 'Alta'),
    ('media', 'Media'),
    ('bassa', 'Bassa'),
  ];

  static const List<(String, String)> _stati = [
    ('programmato', 'Programmato'),
    ('completato', 'Completato'),
    ('annullato', 'Annullato'),
  ];

  // ─── HELPER VOTO (supporto 30L) ────────────────────────────────
  // Internamente memorizziamo il voto come int: 18..30 + 31 per la lode.
  // In UI accettiamo sia "30L" sia "31" e mostriamo "30L" quando voto == 31.
  int? _parseVoto(String input) {
    final cleaned = input.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    if (cleaned == '30l' ||
        cleaned == '30 l' ||
        cleaned == '30 e lode' ||
        cleaned == '30elode') {
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
  void initState() {
    super.initState();
    final e = widget.exam;
    _titoloCtrl = TextEditingController(text: e?.titolo ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _votoCtrl = TextEditingController(text: _formatVoto(e?.voto));
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
        const SnackBar(
            content: Text('Seleziona un corso associato prima di salvare.')),
      );
      return;
    }

    final provider = context.read<PlannerProvider>();

    final votoFinale = _stato == 'completato' && _votoCtrl.text.isNotEmpty
        ? _parseVoto(_votoCtrl.text)
        : null;

    if (_isEditing) {
      final updated = widget.exam!.copyWith(
        titolo: _titoloCtrl.text.trim(),
        courseId: _courseId!,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: votoFinale,
        note: _noteCtrl.text.isEmpty ? '' : _noteCtrl.text.trim(),
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
        voto: votoFinale,
        note: _noteCtrl.text.isEmpty ? '' : _noteCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  String _tipologiaLabel(String t) =>
      _tipologie.firstWhere((e) => e.$1 == t, orElse: () => (t, t)).$2;
  String _prioritaLabel(String p) => _priorita_options
      .firstWhere((e) => e.$1 == p, orElse: () => (p, p))
      .$2;
  String _statoLabel(String s) =>
      _stati.firstWhere((e) => e.$1 == s, orElse: () => (s, s)).$2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF000000) : AppColors.groupedBackground;

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
          child: const Text('Annulla', style: TextStyle(fontSize: 16)),
        ),
        leadingWidth: 88,
        title: Text(
          _isEditing ? 'Modifica Esame' : 'Nuovo Esame',
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            // ─── GRUPPO DATI PRINCIPALI ─────────────────────
            const _GroupHeader(label: 'Esame'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextFieldRow(
                  label: 'Titolo',
                  controller: _titoloCtrl,
                  hint: 'es. Analisi 1',
                  required: true,
                  isDark: isDark,
                ),
              ],
            ),

            // ─── GRUPPO CORSO E DATA ─────────────────────
            const SizedBox(height: 24),
            const _GroupHeader(label: 'Collegamento'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _PickerRow(
                  label: 'Corso',
                  value: _courseId == null
                      ? 'Seleziona...'
                      : (provider.getCourseById(_courseId!)?.nome ??
                          'Seleziona...'),
                  valueColor: _courseId == null ? AppColors.danger : null,
                  onTap: () => _showCoursePicker(context, isDark, provider.courses),
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Data',
                  value: DateFormat('dd MMM yyyy', 'it_IT').format(_data),
                  onTap: _pickDate,
                  isDark: isDark,
                ),
              ],
            ),

            // ─── GRUPPO CLASSIFICAZIONE ─────────────────────
            const SizedBox(height: 24),
            const _GroupHeader(label: 'Classificazione'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _PickerRow(
                  label: 'Tipologia',
                  value: _tipologiaLabel(_tipologia),
                  onTap: () => _showTipologiaPicker(context, isDark),
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Priorità',
                  value: _prioritaLabel(_priorita),
                  valueColor: AppColors.priorita(_priorita),
                  onTap: () => _showPrioritaPicker(context, isDark),
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Stato',
                  value: _statoLabel(_stato),
                  onTap: () => _showStatoPicker(context, isDark),
                  isDark: isDark,
                ),
              ],
            ),

            // ─── VOTO (solo se completato) ─────────────────────
            if (_stato == 'completato') ...[
              const SizedBox(height: 24),
              const _GroupHeader(label: 'Risultato'),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _TextFieldRow(
                    label: 'Voto',
                    controller: _votoCtrl,
                    hint: 'es. 28 o 30L',
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Inserisci il voto';
                      }
                      final n = _parseVoto(v);
                      if (n == null || n < 18 || n > 31) {
                        return 'Tra 18 e 30 (o 30L)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],

            // ─── NOTE ─────────────────────
            const SizedBox(height: 24),
            const _GroupHeader(label: 'Note'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextAreaRow(
                  label: 'Note',
                  controller: _noteCtrl,
                  hint: 'opzionale',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PICKER BOTTOM SHEETS (stile iOS Settings)
  // ═══════════════════════════════════════════════════════════════

  void _showCoursePicker(
      BuildContext context, bool isDark, List<Course> courses) {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nessun corso disponibile. Crealo prima!')),
      );
      return;
    }
    _showOptionsSheet<String>(
      context: context,
      isDark: isDark,
      title: 'Corso associato',
      current: _courseId,
      options: courses.map((c) => (c.id, c.nome)).toList(),
      onSelected: (id) => setState(() => _courseId = id),
    );
  }

  void _showTipologiaPicker(BuildContext context, bool isDark) {
    _showOptionsSheet<String>(
      context: context,
      isDark: isDark,
      title: 'Tipologia',
      current: _tipologia,
      options: _tipologie,
      onSelected: (v) => setState(() => _tipologia = v),
    );
  }

  void _showPrioritaPicker(BuildContext context, bool isDark) {
    _showOptionsSheet<String>(
      context: context,
      isDark: isDark,
      title: 'Priorità',
      current: _priorita,
      options: _priorita_options,
      onSelected: (v) => setState(() => _priorita = v),
    );
  }

  void _showStatoPicker(BuildContext context, bool isDark) {
    _showOptionsSheet<String>(
      context: context,
      isDark: isDark,
      title: 'Stato',
      current: _stato,
      options: _stati,
      onSelected: (v) {
        setState(() {
          _stato = v;
          // Se l'utente cambia stato e non è completato, svuotiamo il voto.
          if (_stato != 'completato') _votoCtrl.clear();
        });
      },
    );
  }

  void _showOptionsSheet<T>({
    required BuildContext context,
    required bool isDark,
    required String title,
    required T? current,
    required List<(T, String)> options,
    required ValueChanged<T> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  color: isDark ? Colors.white24 : Colors.black26,
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
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options.map((opt) {
                  final isSelected = opt.$1 == current;
                  return InkWell(
                    onTap: () {
                      onSelected(opt.$1);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.$2,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                color: AppColors.iosBlue, size: 22),
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

// ═══════════════════════════════════════════════════════════════
// GROUP HEADER
// ═══════════════════════════════════════════════════════════════
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS GROUP (card grigio chiaro con righe + divider)
// ═══════════════════════════════════════════════════════════════
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsGroup({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : AppColors.groupedSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: _withDividers(children, isDark)),
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

// ═══════════════════════════════════════════════════════════════
// TEXT FIELD ROW (label sx, input dx allineato a destra)
// ═══════════════════════════════════════════════════════════════
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

// ═══════════════════════════════════════════════════════════════
// TEXT AREA ROW (per Note: label sopra, area multiline sotto)
// ═══════════════════════════════════════════════════════════════
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              color: isDark ? Colors.white60 : AppColors.textSecondary,
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

// ═══════════════════════════════════════════════════════════════
// PICKER ROW (label sx, valore + chevron dx, tap apre bottom sheet)
// ═══════════════════════════════════════════════════════════════
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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