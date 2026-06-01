import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FormGroupHeader extends StatelessWidget {
  final String label;
  const FormGroupHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class FormSettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const FormSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: _withDividers(children, context)),
    );
  }

  List<Widget> _withDividers(List<Widget> rows, BuildContext context) {
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
            color: Theme.of(context).dividerColor,
          ),
        ));
      }
    }
    return result;
  }
}

class FormTextFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;
  final bool required;
  final String? Function(String?)? validator;

  const FormTextFieldRow({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorOnSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label, 
              style: TextStyle(fontSize: 16, color: colorOnSurface, letterSpacing: -0.3)
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.end,
              cursorColor: AppColors.iosBlue,
              style: TextStyle(fontSize: 16, color: colorOnSurface, letterSpacing: -0.3),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 16, color: AppColors.textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error, height: 0.8),
              ),
              validator: validator ?? (required ? (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null : null),
            ),
          ),
        ],
      ),
    );
  }
}

class FormTextAreaRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;

  const FormTextAreaRow({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colorOnSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(fontSize: 16, color: colorOnSurface, letterSpacing: -0.3)
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            cursorColor: AppColors.iosBlue,
            style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: -0.2, height: 1.4),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 15, color: AppColors.textMuted),
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

class FormPickerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;
  final bool disabled;
  final bool hasError;

  const FormPickerRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    required this.onTap,
    this.disabled = false,
    this.hasError = false, 
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor = disabled ? AppColors.textMuted : Theme.of(context).colorScheme.onSurface;
    final effectiveValueColor = disabled ? AppColors.textMuted : (valueColor ?? Theme.of(context).colorScheme.onSurfaceVariant);
    final errorColor = AppColors.danger;
    final showError = hasError && !disabled;

  return Material(
    color: Colors.transparent,
    child: Column(                
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label, 
                    style: TextStyle(fontSize: 16, color: effectiveLabelColor, letterSpacing: -0.3)
                  )
                ),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 16, 
                      color: effectiveValueColor, 
                      letterSpacing: -0.3, 
                      fontWeight: valueColor != null && !disabled ? FontWeight.w600 : FontWeight.w400
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      if (showError)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            'Campo obbligatorio',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: errorColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FormSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const FormSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
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
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.3)
            )
          ),
          Switch.adaptive(
            value: value, 
            onChanged: onChanged, 
            activeThumbColor: AppColors.iosBlue
          ),
        ],
      ),
    );
  }
}