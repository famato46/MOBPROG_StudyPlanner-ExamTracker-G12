import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Riquadrino colorato attorno al titolo di una sezione.
/// Il colore è centralizzato in AppColors.headerBg / headerText,
/// quindi cambiandolo lì cambia ovunque.
class SectionHeader extends StatelessWidget {
  final String titolo;
  final IconData icona;

  const SectionHeader({
    super.key,
    required this.titolo,
    required this.icona,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icona, size: 20, color: AppColors.headerText),
          const SizedBox(width: 8),
          Text(
            titolo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.headerText,
            ),
          ),
        ],
      ),
    );
  }
}