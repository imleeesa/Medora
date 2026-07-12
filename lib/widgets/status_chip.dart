import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tono semantico di uno stato (non lega il widget a un enum di dominio
/// specifico, cosi' resta riusabile da storico, dashboard, scorte, ecc.).
enum StatusTone { positive, neutral, critical, info }

/// Chip di stato standard del design system "Calm Precision".
/// Es. Assunta -> positive, Saltata -> neutral, Dimenticata -> critical,
/// Programmata -> info. Non ancora cablata in nessuna schermata esistente.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;

  const StatusChip({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _ChipColors _colorsFor(StatusTone tone) {
    switch (tone) {
      case StatusTone.positive:
        return const _ChipColors(AppColors.primaryTint, AppColors.primary800);
      case StatusTone.neutral:
        return const _ChipColors(AppColors.border, AppColors.inkSoft);
      case StatusTone.critical:
        return const _ChipColors(AppColors.criticalTint, AppColors.critical);
      case StatusTone.info:
        return const _ChipColors(AppColors.infoTint, AppColors.info);
    }
  }
}

class _ChipColors {
  final Color background;
  final Color foreground;
  const _ChipColors(this.background, this.foreground);
}
