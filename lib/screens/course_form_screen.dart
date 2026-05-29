import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';

/// CourseFormScreen — Form Apple-style.
///
/// Layout iOS Settings: gruppi grigi arrotondati, righe con label
/// a sx e input/picker a dx, divider sottili.
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

  String _semestre = 'I Semestre · Anno I';
  String _stato = 'da_iniziare';

  bool get _isEditing => widget.courseToEdit != null;

static const List<String> _semestri = [
  'I Semestre · Anno I',
  'II Semestre · Anno I',
  'I Semestre · Anno II',
  'II Semestre · Anno II',
  'I Semestre · Anno III',
  'II Semestre · Anno III',
];

  static const List<(String, String)> _stati = [
    ('da_iniziare', 'Da iniziare'),
    ('in_corso', 'In corso'),
    ('da_ripassare', 'Da ripassare'),
    ('completato', 'Completato'),
    ('superato', 'Superato'),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.courseToEdit;
    _nomeCtrl = TextEditingController(text: c?.nome ?? '');
    _docenteCtrl = TextEditingController(text: c?.docente ?? '');
    _cfuCtrl = TextEditingController(text: c?.cfu.toString() ?? '');
    _noteCtrl = TextEditingController(text: c?.note ?? '');
    _materialeCtrl =
        TextEditingController(text: c?.materialeAssociato ?? '');
    _votoDesideratoCtrl = TextEditingController(
        text: _formatVoto(c?.votoDesiderato));
    _votoOttenutoCtrl = TextEditingController(
        text: _formatVoto(c?.votoOttenuto));
    _semestre = c?.semestre ?? 'I Semestre · Anno I';
    _stato = c?.stato ?? 'da_iniziare';
  }

  // ─── HELPER VOTO (supporto 30L) ────────────────────────────────
  // Internamente memorizziamo i voti come int: 18..30 + 31 per la lode.
  // In UI usiamo "30L" quando il valore è 31, per coerenza con la
  // convenzione universitaria italiana. Questi due helper centralizzano
  // la conversione bidirezionale stringa<->int.

  /// Parsa la stringa inserita dall'utente in un voto numerico.
  /// Accetta sia "30L" / "30l" / "30 L" / "30 e lode" sia "31".
  /// Restituisce null se non parsabile.
  int? _parseVoto(String input) {
    final cleaned = input.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    // Lode esplicita
    if (cleaned == '30l' ||
        cleaned == '30 l' ||
        cleaned == '30 e lode' ||
        cleaned == '30elode') {
      return 31;
    }
    return int.tryParse(cleaned);
  }

  /// Formatta un voto numerico in stringa visualizzabile.
  /// 31 -> "30L", null -> "", altrimenti il numero.
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
    final provider = context.read<PlannerProvider>();

    // Parsing centralizzato che supporta sia "30L" che "31"
    final vDesiderato = _votoDesideratoCtrl.text.isEmpty
        ? null
        : _parseVoto(_votoDesideratoCtrl.text);
    final vOttenuto =
        (_stato == 'superato' && _votoOttenutoCtrl.text.isNotEmpty)
            ? _parseVoto(_votoOttenutoCtrl.text)
            : null;

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
        materialeAssociato: _materialeCtrl.text.isEmpty
            ? null
            : _materialeCtrl.text.trim(),
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
        materialeAssociato: _materialeCtrl.text.isEmpty
            ? null
            : _materialeCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  String _statoLabel(String s) =>
      _stati.firstWhere((e) => e.$1 == s, orElse: () => (s, s)).$2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF000000)
        : AppColors.groupedBackground;

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
          _isEditing ? 'Modifica Corso' : 'Nuovo Corso',
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
            // ─── GRUPPO DATI PRINCIPALI ─────────────────────
            _GroupHeader(label: 'Dati corso'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextFieldRow(
                  label: 'Nome',
                  controller: _nomeCtrl,
                  hint: 'es. Analisi 1',
                  required: true,
                  isDark: isDark,
                ),
                _TextFieldRow(
                  label: 'Docente',
                  controller: _docenteCtrl,
                  hint: 'es. Mario Rossi',
                  required: true,
                  isDark: isDark,
                ),
                _TextFieldRow(
                  label: 'CFU',
                  controller: _cfuCtrl,
                  hint: '9',
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Campo obbligatorio';
                    }
                    if (int.tryParse(v) == null) return 'Numero non valido';
                    return null;
                  },
                  isDark: isDark,
                ),
              ],
            ),

            // ─── GRUPPO STATO E PERIODO ─────────────────────
            const SizedBox(height: 24),
            _GroupHeader(label: 'Stato e periodo'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _PickerRow(
                  label: 'Semestre',
                  value: _semestre,
                  onTap: () => _showSemestrePicker(context, isDark),
                  isDark: isDark,
                ),
                _PickerRow(
                  label: 'Stato',
                  value: _statoLabel(_stato),
                  valueColor: AppColors.statoCorso(_stato),
                  onTap: () => _showStatoPicker(context, isDark),
                  isDark: isDark,
                ),
              ],
            ),

            // ─── GRUPPO VOTI ────────────────────────────────
            const SizedBox(height: 24),
            _GroupHeader(label: 'Voti'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextFieldRow(
                  label: 'Voto desiderato',
                  controller: _votoDesideratoCtrl,
                  // FIX 30L: ora accettiamo anche "30L" (oltre a "31" che è
                  // la rappresentazione interna). Il validator normalizza
                  // entrambe le forme e accetta range 18-30 più la lode.
                  hint: '18-30 o 30L',
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = _parseVoto(v);
                    if (n == null || n < 18 || n > 31) {
                      return 'Voto tra 18 e 30 (o 30L)';
                    }
                    return null;
                  },
                  isDark: isDark,
                ),
                if (_stato == 'superato')
                  _TextFieldRow(
                    label: 'Voto ottenuto',
                    controller: _votoOttenutoCtrl,
                    hint: '18-30 o 30L',
                    keyboardType: TextInputType.text,
                    required: true,
                    validator: (v) {
                      if (_stato == 'superato' &&
                          (v == null || v.isEmpty)) {
                        return 'Inserisci il voto';
                      }
                      if (v != null && v.isNotEmpty) {
                        final n = _parseVoto(v);
                        if (n == null || n < 18 || n > 31) {
                          return 'Voto tra 18 e 30 (o 30L)';
                        }
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
              ],
            ),

            // ─── GRUPPO RISORSE ─────────────────────────────
            const SizedBox(height: 24),
            _GroupHeader(label: 'Risorse'),
            _SettingsGroup(
              isDark: isDark,
              children: [
                _TextFieldRow(
                  label: 'Materiale',
                  controller: _materialeCtrl,
                  hint: 'libri, link, ecc.',
                  isDark: isDark,
                ),
                _TextAreaRow(
                  label: 'Note',
                  controller: _noteCtrl,
                  hint: 'aggiungi una nota',
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ─── CTA PRINCIPALE: pill rosa pastello ────────
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
                    _isEditing
                        ? 'Salva modifiche'
                        : 'Aggiungi corso',
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

  // ─── BOTTOM SHEET PICKER iOS-style ─────────────────────────
  void _showSemestrePicker(BuildContext context, bool isDark) {
    _showIosPicker<String>(
      context: context,
      isDark: isDark,
      title: 'Semestre',
      options: _semestri.map((s) => (s, s)).toList(),
      current: _semestre,
      onSelected: (v) => setState(() => _semestre = v),
    );
  }

  void _showStatoPicker(BuildContext context, bool isDark) {
    _showIosPicker<String>(
      context: context,
      isDark: isDark,
      title: 'Stato',
      options: _stati,
      current: _stato,
      onSelected: (v) => setState(() => _stato = v),
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
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : AppColors.groupedSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                color: AppColors.textMuted.withValues(alpha: 0.4),
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
                  color: isDark
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
            ...options.map((opt) {
              final (value, label) = opt;
              final selected = value == current;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    onSelected(value);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
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
                          Icon(
                            Icons.check_rounded,
                            color: AppColors.iosBlue,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// GROUP HEADER (uppercase label sopra ogni gruppo)
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
// SETTINGS GROUP (card bianca arrotondata con divider tra righe)
// ═══════════════════════════════════════════════════════════════
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsGroup({
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : AppColors.groupedSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _withDividers(children, isDark),
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