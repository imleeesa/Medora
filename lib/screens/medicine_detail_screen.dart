import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intake_record.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/color_parser.dart';
import '../utils/schedule_grouping.dart';
import '../utils/weekday_labels.dart';
import '../widgets/app_card.dart';
import '../widgets/form_section_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';
import 'add_medicine_screen.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, _) {
        final currentMedicine =
            provider.getMedicineById(medicine.id) ?? medicine;
        final therapy = currentMedicine.therapyId == null
            ? null
            : provider.getTherapyById(currentMedicine.therapyId!);
        final hasDose = currentMedicine.dose.trim().isNotEmpty;
        final scheduleGroups = ScheduleGrouping.groupsFor(currentMedicine);
        final isLowStock =
            currentMedicine.stockQuantity <=
            currentMedicine.stockWarningThreshold;
        final recentRecords = provider.intakeHistory
            .where((record) => record.medicineId == currentMedicine.id)
            .take(3)
            .toList(growable: false);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Dettaglio medicina'),
            actions: [
              PopupMenuButton<_MedicineAction>(
                tooltip: 'Azioni medicina',
                onSelected: (action) =>
                    _handleAction(context, currentMedicine, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _MedicineAction.toggleActive,
                    child: Row(
                      children: [
                        Icon(
                          currentMedicine.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentMedicine.isActive
                              ? 'Disattiva medicina'
                              : 'Attiva medicina',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _MedicineAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 8),
                        Text('Elimina medicina'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MedicineHeader(medicine: currentMedicine),
                const SizedBox(height: AppSpacing.lg),
                FormSectionCard(
                  icon: Icons.schedule,
                  title: 'Assunzione',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasDose) ...[
                        _DetailLabel(
                          icon: Icons.medication_outlined,
                          label: 'Dose',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentMedicine.doseLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Divider(
                          height: 1,
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const _DetailLabel(
                        icon: Icons.calendar_month_outlined,
                        label: 'Programmazione',
                      ),
                      const SizedBox(height: 8),
                      if (scheduleGroups.isEmpty)
                        const Text(
                          'Nessun orario programmato',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkFaint,
                          ),
                        )
                      else
                        for (var i = 0; i < scheduleGroups.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.md),
                          _ScheduleGroupTile(group: scheduleGroups[i]),
                        ],
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _DetailLabel(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Terapia associata',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        therapy?.name ?? 'Terapia non disponibile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FormSectionCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Scorta disponibile',
                  trailing: StatusChip(
                    label: isLowStock ? 'Scorta bassa' : 'Nella norma',
                    tone: isLowStock ? StatusTone.warning : StatusTone.positive,
                  ),
                  child: _StockDetails(medicine: currentMedicine),
                ),
                if (recentRecords.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FormSectionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Storico recente',
                    child: Column(
                      children: [
                        for (var i = 0; i < recentRecords.length; i++) ...[
                          _RecentIntakeRow(record: recentRecords[i]),
                          if (i < recentRecords.length - 1)
                            Divider(
                              height: AppSpacing.md,
                              color: AppColors.border.withValues(alpha: 0.7),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (currentMedicine.notes != null &&
                    currentMedicine.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FormSectionCard(
                    icon: Icons.note_alt_outlined,
                    title: 'Note',
                    child: Text(
                      currentMedicine.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        key: const ValueKey('medicine-detail-edit-button'),
                        label: 'Modifica medicina',
                        icon: Icons.edit_outlined,
                        onPressed: () =>
                            _editMedicine(context, currentMedicine),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Cambia terapia',
                        icon: Icons.swap_horiz_outlined,
                        onPressed: () =>
                            _changeTherapy(context, currentMedicine),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    Medicine currentMedicine,
    _MedicineAction action,
  ) async {
    switch (action) {
      case _MedicineAction.toggleActive:
        await _toggleActive(context, currentMedicine);
      case _MedicineAction.delete:
        await _confirmDelete(context, currentMedicine);
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    Medicine currentMedicine,
  ) async {
    try {
      await context.read<MedicineProvider>().toggleMedicineActive(
        currentMedicine.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentMedicine.isActive
                ? 'Medicina disattivata'
                : 'Medicina attivata',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Medicine currentMedicine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare medicina?'),
        content: Text('Vuoi eliminare ${currentMedicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<MedicineProvider>().deleteMedicine(currentMedicine.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medicina eliminata')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _editMedicine(
    BuildContext context,
    Medicine currentMedicine,
  ) async {
    final provider = context.read<MedicineProvider>();
    final therapy = currentMedicine.therapyId == null
        ? null
        : provider.getTherapyById(currentMedicine.therapyId!);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddMedicineScreen(therapy: therapy, medicine: currentMedicine),
      ),
    );
  }

  Future<void> _changeTherapy(
    BuildContext context,
    Medicine currentMedicine,
  ) async {
    final provider = context.read<MedicineProvider>();
    final targetTherapies = provider.therapies
        .where(
          (therapy) =>
              therapy.isActive && therapy.id != currentMedicine.therapyId,
        )
        .toList(growable: false);

    if (targetTherapies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non ci sono altre terapie attive disponibili.'),
        ),
      );
      return;
    }

    final targetTherapyId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Scegli una terapia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: targetTherapies.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final therapy = targetTherapies[index];
                    final color = parseHexColor(therapy.color);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.14),
                        foregroundColor: color,
                        child: const Icon(Icons.medical_information_outlined),
                      ),
                      title: Text(therapy.name),
                      subtitle: therapy.description?.isNotEmpty ?? false
                          ? Text(
                              therapy.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => Navigator.pop(sheetContext, therapy.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (targetTherapyId == null || !context.mounted) return;

    try {
      await context.read<MedicineProvider>().moveMedicineToTherapy(
        medicineId: currentMedicine.id,
        targetTherapyId: targetTherapyId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Terapia aggiornata')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

enum _MedicineAction { toggleActive, delete }

class _MedicineHeader extends StatelessWidget {
  final Medicine medicine;

  const _MedicineHeader({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(medicine.color);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_outlined, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              medicine.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            label: medicine.isActive ? 'Attiva' : 'Inattiva',
            tone: medicine.isActive ? StatusTone.positive : StatusTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.inkFaint),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkFaint,
          ),
        ),
      ],
    );
  }
}

class _ScheduleGroupTile extends StatelessWidget {
  final ScheduleDisplayGroup group;

  const _ScheduleGroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          ScheduleGrouping.dayNames(group.daysOfWeek),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        for (final time in group.times)
          Container(
            key: ValueKey('medicine-schedule-time-${time.hour}-${time.minute}'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary800,
              ),
            ),
          ),
      ],
    );
  }
}

class _StockDetails extends StatelessWidget {
  final Medicine medicine;

  const _StockDetails({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final threshold = medicine.stockWarningThreshold;
    // Stessa euristica visiva gia' usata in StockScreen: presentazione,
    // nessuna modifica alla logica scorte.
    final progress = threshold <= 0
        ? 1.0
        : (medicine.stockQuantity / (threshold * 3)).clamp(0.0, 1.0);
    final isLowStock = medicine.stockQuantity <= threshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Medicine.formatQuantity(medicine.stockQuantity)} unità residue',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Soglia avviso: ${Medicine.formatQuantity(threshold)} unità',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaint,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
            color: isLowStock ? AppColors.warning : AppColors.primary700,
          ),
        ),
      ],
    );
  }
}

class _RecentIntakeRow extends StatelessWidget {
  final IntakeRecord record;

  const _RecentIntakeRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final displayed = record.actualDateTime ?? record.scheduledDateTime;
    final (label, tone) = switch (record.status) {
      IntakeStatus.taken => ('Assunta', StatusTone.positive),
      IntakeStatus.skipped => ('Saltata', StatusTone.warning),
      IntakeStatus.missed => ('Dimenticata', StatusTone.critical),
      IntakeStatus.scheduled => ('Prevista', StatusTone.info),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: AppColors.inkFaint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _dateLabel(displayed, context),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          StatusChip(label: label, tone: tone),
        ],
      ),
    );
  }

  String _dateLabel(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time = TimeOfDay.fromDateTime(dateTime).format(context);

    if (day == today) return 'Oggi, $time';
    if (day == today.subtract(const Duration(days: 1))) return 'Ieri, $time';
    return '${kWeekdayShortLabels[dateTime.weekday - 1]}, $time';
  }
}
