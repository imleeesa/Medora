import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/intake_record.dart';
import '../models/intake_stock_change.dart';
import '../models/scheduled_intake.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_card.dart';
import 'status_chip.dart';

/// Riga "assunzione di oggi" della Dashboard. La marcatura Assunta/Saltata
/// chiama lo stesso `MedicineProvider` gia' usato prima del redesign:
/// nessuna nuova logica di dominio, solo restyling con i token condivisi.
class TodayIntakeCard extends StatelessWidget {
  final ScheduledIntake intake;
  final String? therapyName;
  final VoidCallback onTap;

  const TodayIntakeCard({
    super.key,
    required this.intake,
    required this.therapyName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(
      intake.scheduledDateTime,
    ).format(context);
    final status = intake.status;
    final isScheduled = status == IntakeStatus.scheduled;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.primary800,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intake.medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (therapyName != null)
                      Text(
                        therapyName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isScheduled) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusChip(
                  label: _statusLabel(status),
                  tone: _statusTone(status),
                ),
              ],
            ],
          ),
          if (intake.medicine.dose.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              intake.medicine.doseLabel,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (isScheduled)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _mark(context, IntakeStatus.skipped),
                  icon: const Icon(Icons.skip_next_outlined),
                  label: const Text('Saltata'),
                ),
                FilledButton.icon(
                  onPressed: () => _mark(context, IntakeStatus.taken),
                  icon: const Icon(Icons.check),
                  label: const Text('Assunta'),
                ),
              ],
            )
          else if (status == IntakeStatus.taken)
            OutlinedButton.icon(
              onPressed: () => _mark(context, IntakeStatus.skipped),
              icon: const Icon(Icons.undo_outlined),
              label: const Text('Segna come saltata'),
            )
          else
            FilledButton.icon(
              onPressed: () => _mark(context, IntakeStatus.taken),
              icon: const Icon(Icons.check),
              label: const Text('Segna come assunta'),
            ),
        ],
      ),
    );
  }

  String _statusLabel(IntakeStatus status) => switch (status) {
    IntakeStatus.taken => 'Assunta',
    IntakeStatus.skipped => 'Saltata',
    IntakeStatus.missed => 'Dimenticata',
    IntakeStatus.scheduled => 'Prevista',
  };

  StatusTone _statusTone(IntakeStatus status) => switch (status) {
    IntakeStatus.taken => StatusTone.positive,
    IntakeStatus.skipped => StatusTone.neutral,
    IntakeStatus.missed => StatusTone.critical,
    IntakeStatus.scheduled => StatusTone.info,
  };

  Future<void> _mark(BuildContext context, IntakeStatus status) async {
    final provider = context.read<MedicineProvider>();
    try {
      final stockChange = status == IntakeStatus.taken
          ? await provider.markMedicineAsTaken(
              medicineId: intake.medicine.id,
              scheduledDateTime: intake.scheduledDateTime,
            )
          : await provider.markMedicineAsSkipped(
              medicineId: intake.medicine.id,
              scheduledDateTime: intake.scheduledDateTime,
            );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_feedbackMessage(status, stockChange))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  String _feedbackMessage(IntakeStatus status, IntakeStockChange stockChange) {
    return switch (stockChange) {
      IntakeStockChange.decreased =>
        'Assunzione registrata. Scorta aggiornata.',
      IntakeStockChange.restored => 'Assunzione saltata. Scorta ripristinata.',
      IntakeStockChange.noQuantity =>
        status == IntakeStatus.taken
            ? 'Assunzione registrata. Scorta non aggiornata: quantita non gestibile.'
            : 'Assunzione segnata come saltata.',
      IntakeStockChange.unchanged =>
        status == IntakeStatus.taken
            ? 'Assunzione gia registrata.'
            : 'Assunzione segnata come saltata.',
    };
  }
}
