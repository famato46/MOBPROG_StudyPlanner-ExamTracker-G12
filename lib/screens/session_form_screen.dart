import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../models/study_session.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';

/// SessionFormScreen — Form a tutto schermo per creare/modificare una
/// sessione di studio (StudySession). Stile iOS Settings coerente con
/// CourseFormScreen / ExamFormScreen / TaskFormScreen.
class SessionFormScreen extends StatefulWidget {
  final StudySession? sessione; // null = creazione
  final DateTime? dataIniziale; // pre-compila la data se passata

  const SessionFormScreen({super.key, this.sessione, this.dataIniziale});

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titoloCtrl;
  late final TextEditingController _durataCtrl;

  String? _courseId;
  DateTime _data = DateTime.now();
  String _tipo = 'studio';

  bool get _isEditing => widget.sessione != null;

  static const List<(String, String)> _tipi = [
    ('studio', 'Studio'),
    ('ripasso', 'Ripasso'),
    ('esercitazione', 'Esercitazione'),
    ('progetto', 'Progetto'),
    ('consegna', 'Consegna'),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.sessione;
    _titoloCtrl = TextEditingController(text: s?.titolo ?? '');
    _durataCtrl = TextEditingController(
        text: (s?.durataPianificata ?? 60).toString());
    _courseId = s?.courseId;
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
            content: Text('Seleziona un corso prima di salvare.')),
      );
      return;
    }

    final provider = context.read<PlannerProvider>();
    final durata = int.tryParse(_durataCtrl.text.trim()) ?? 60;

    if (_isEditing) {
      await provider.updateStudySession(
        widget.sessione!.copyWith(
          titolo: _titoloCtrl.text.trim(),
          courseId: _courseId,
          data: _data,
          durataPianificata: durata,
          tipo: _tipo,
        ),
      );
    } else {
      await provider.addStudySession(
        titolo: _titoloCtrl.text.trim(),
        courseId: _courseId,
        data: _data,
        durataPianificata: durata,
        tipo: _tipo,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  String _tipoLabel(String t) =>
      _tipi.firstWhere((e) => e.$1 == t, orElse: () => (t, t)).$2;

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
          _isEditing ? 'Modifica Sessione' : 'Nuova Sessione',
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
            child: const Text('Salva',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            const _GroupHeader(label: 'Sessione'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextFieldRow(
                  label: 'Titolo',
                  controller: _titoloCtrl,
                  hint: 'es. Studio Analisi',
                  required: true,
                  isDark: isDark,
                ),
                _TextFieldRow(
                  label: 'Durata (min)',
                  controller: _durataCtrl,
                  hint: '60',
                  isNumeric: true,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _GroupHeader(label: 'Dettagli'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _PickerRow(
                  label: 'Corso',
                  value: _courseId == null
                      ? 'Seleziona...'
                      : (provider.getCourseById(_courseId!)?.nome ??
                          'Seleziona...'),
                  valueColor:
                      _courseId == null ? AppColors.danger : null,
                  onTap: () =>
                      _showCoursePicker(context, isDark, provider.courses),
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Data',
                  value: DateFormat('dd MMM yyyy', 'it_IT').format(_data),
                  onTap: _pickDate,
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Tipo',
                  value: _tipoLabel(_tipo),
                  onTap: () => _showTipoPicker(context, isDark),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
      title: 'Corso',
      current: _courseId,
      options: courses.map((c) => (c.id, c.nome)).toList(),
      onSelected: (id) => setState(() => _courseId = id),
    );
  }

  void _showTipoPicker(BuildContext context, bool isDark) {
    _showOptionsSheet<String>(
      context: context,
      isDark: isDark,
      title: 'Tipo attività',
      current: _tipo,
      options: _tipi,
      onSelected: (v) => setState(() => _tipo = v),
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
// WIDGET CONDIVISI (stessa estetica di exam_form_screen)
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

class _TextFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool required;
  final bool isNumeric;
  final bool isDark;

  const _TextFieldRow({
    required this.label,
    required this.controller,
    this.hint,
    this.required = false,
    this.isNumeric = false,
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
            width: 120,
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
              keyboardType:
                  isNumeric ? TextInputType.number : TextInputType.text,
              textAlign: TextAlign.end,
              cursorColor: AppColors.iosBlue,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(fontSize: 16, color: AppColors.textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: TextStyle(
                    fontSize: 11, color: AppColors.danger, height: 0.8),
              ),
              validator: required
                  ? (v) =>
                      (v == null || v.isEmpty) ? 'Campo obbligatorio' : null
                  : null,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Icon(Icons.unfold_more_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}