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

/// Card unica "Assunzioni di oggi" della Dashboard (mockup 04): righe con
/// divider dentro una sola AppCard. La marcatura Assunta/Saltata chiama lo
/// stesso `MedicineProvider` di prima: nessuna nuova logica di dominio.
class TodayIntakesCard extends StatelessWidget {
  final List<ScheduledIntake> intakes;
  final void Function(String medicineId) onOpenMedicine;

  const TodayIntakesCard({
    super.key,
    required this.intakes,
    required this.onOpenMedicine,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Assunzioni di oggi',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (intakes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${intakes.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (intakes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: AppColors.primary700,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Nessuna assunzione programmata per oggi.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < intakes.length; i++) ...[
              _TodayIntakeRow(
                intake: intakes[i],
                onTap: () => onOpenMedicine(intakes[i].medicine.id),
              ),
              if (i < intakes.length - 1)
                Divider(
                  height: AppSpacing.lg,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
            ],
        ],
      ),
    );
  }
}

class _TodayIntakeRow extends StatelessWidget {
  final ScheduledIntake intake;
  final VoidCallback onTap;

  const _TodayIntakeRow({required this.intake, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(
      intake.scheduledDateTime,
    ).format(context);
    final status = intake.status;
    final isScheduled = status == IntakeStatus.scheduled;
    final hasDose = intake.medicine.dose.trim().isNotEmpty;
    final subtitle = [if (hasDose) intake.medicine.doseLabel, time].join(' · ');
    final visuals = _visualsFor(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: visuals.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visuals.icon, size: 19, color: visuals.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intake.medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
                const SizedBox(width: AppSpacing.sm),
                StatusChip(label: _statusLabel(status), tone: _tone(status)),
              ],
            ),
            if (isScheduled)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _mark(context, IntakeStatus.skipped),
                      icon: const Icon(Icons.skip_next_outlined, size: 18),
                      label: const Text('Saltata'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _mark(context, IntakeStatus.taken),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Assunta'),
                    ),
                  ],
                ),
              )
            else if (status == IntakeStatus.taken)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _mark(context, IntakeStatus.skipped),
                  icon: const Icon(Icons.undo_outlined, size: 18),
                  label: const Text('Segna come saltata'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _mark(context, IntakeStatus.taken),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Segna come assunta'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ({Color tint, Color color, IconData icon}) _visualsFor(IntakeStatus status) =>
      switch (status) {
        IntakeStatus.taken => (
          tint: AppColors.primaryTint,
          color: AppColors.primary700,
          icon: Icons.check_rounded,
        ),
        IntakeStatus.skipped => (
          tint: AppColors.warningTint,
          color: AppColors.warning,
          icon: Icons.skip_next_outlined,
        ),
        IntakeStatus.missed => (
          tint: AppColors.criticalTint,
          color: AppColors.critical,
          icon: Icons.schedule,
        ),
        IntakeStatus.scheduled => (
          tint: AppColors.primaryTint,
          color: AppColors.primary700,
          icon: Icons.medication_outlined,
        ),
      };

  String _statusLabel(IntakeStatus status) => switch (status) {
    IntakeStatus.taken => 'Assunta',
    IntakeStatus.skipped => 'Saltata',
    IntakeStatus.missed => 'Dimenticata',
    IntakeStatus.scheduled => 'Da assumere',
  };

  StatusTone _tone(IntakeStatus status) => switch (status) {
    IntakeStatus.taken => StatusTone.positive,
    IntakeStatus.skipped => StatusTone.warning,
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
