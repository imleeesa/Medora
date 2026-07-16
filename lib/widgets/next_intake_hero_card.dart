import 'package:flutter/material.dart';
import '../models/scheduled_intake.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_card.dart';
import 'medora_3d_asset.dart';
import 'status_chip.dart';

/// Card "prossima assunzione" della Dashboard, stile mockup 04: card bianca
/// con pill orario, niente gradiente. Riceve solo dati gia' calcolati dal
/// Provider (nessuna logica di dominio in questo widget).
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
    final time = TimeOfDay.fromDateTime(
      intake.scheduledDateTime,
    ).format(context);
    final hasDose = medicine.dose.trim().isNotEmpty;
    final subtitleParts = [
      if (hasDose) medicine.doseLabel,
      if (therapyName != null) therapyName!,
    ];

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Prossima assunzione',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.15,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Medora3DAsset(Medora3DAsset.capsuleMint, size: 64),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 15,
                color: AppColors.inkFaint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tra ${_timeUntil(intake.scheduledDateTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
              if (lowStock) ...[
                const SizedBox(width: AppSpacing.sm),
                const StatusChip(
                  label: 'Scorta bassa',
                  tone: StatusTone.warning,
                ),
              ],
            ],
          ),
        ],
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
