import 'package:flutter/material.dart';
import '../models/scheduled_intake.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Hero card "prossima assunzione" della Dashboard. Riceve solo dati gia'
/// calcolati dal Provider (nessuna logica di dominio in questo widget).
class NextIntakeHeroCard extends StatelessWidget {
  final ScheduledIntake intake;
  final String? therapyName;
  final bool lowStock;
  final VoidCallback onTap;

  const NextIntakeHeroCard({
    super.key,
    required this.intake,
    required this.therapyName,
    required this.lowStock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final medicine = intake.medicine;
    final time = TimeOfDay.fromDateTime(intake.scheduledDateTime);

    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary700, AppColors.primary800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary700.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Prossima assunzione',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  medicine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (therapyName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    therapyName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _HeroPill(
                      icon: Icons.schedule,
                      label: time.format(context),
                    ),
                    _HeroPill(
                      icon: Icons.timer_outlined,
                      label: 'Tra ${_timeUntil(intake.scheduledDateTime)}',
                    ),
                    if (medicine.dose.trim().isNotEmpty)
                      _HeroPill(
                        icon: Icons.medication_outlined,
                        label: medicine.doseLabel,
                      ),
                    if (lowStock)
                      _HeroPill(
                        icon: Icons.inventory_2_outlined,
                        label: 'Scorta bassa',
                        emphasized: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeUntil(DateTime dateTime) {
    final difference = dateTime.difference(DateTime.now());
    final minutes = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _HeroPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized ? AppColors.gold : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized
            ? Colors.white.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
