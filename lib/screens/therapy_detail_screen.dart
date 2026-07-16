import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/medicine.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../services/therapy_pdf_export_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/color_parser.dart';
import '../utils/therapy_icons.dart';
import '../widgets/app_card.dart';
import '../widgets/dashboard_section_header.dart';
import '../widgets/medora_3d_asset.dart';
import '../widgets/status_chip.dart';
import 'add_medicine_screen.dart';
import 'add_therapy_screen.dart';
import 'medicine_detail_screen.dart';

class TherapyDetailScreen extends StatelessWidget {
  final String therapyId;

  const TherapyDetailScreen({super.key, required this.therapyId});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, _) {
        final therapy = _findTherapy(provider.therapies);
        if (therapy == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Terapia')),
            body: const SafeArea(
              child: Center(child: Text('Terapia non disponibile')),
            ),
          );
        }

        final medicines = provider.getMedicinesByTherapy(therapy.id);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Dettaglio Terapia'),
            actions: [
              IconButton(
                tooltip: 'Modifica terapia',
                onPressed: () => _openEdit(context, therapy),
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<_TherapyAction>(
                tooltip: 'Azioni terapia',
                onSelected: (action) =>
                    _handleAction(context, therapy, medicines, action),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _TherapyAction.exportPdf,
                    child: _TherapyActionRow(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Esporta PDF',
                    ),
                  ),
                  if (therapy.isActive)
                    const PopupMenuItem(
                      value: _TherapyAction.archive,
                      child: _TherapyActionRow(
                        icon: Icons.archive_outlined,
                        label: 'Archivia',
                      ),
                    ),
                  if (!therapy.isActive)
                    const PopupMenuItem(
                      value: _TherapyAction.reactivate,
                      child: _TherapyActionRow(
                        icon: Icons.unarchive_outlined,
                        label: 'Riattiva',
                      ),
                    ),
                  PopupMenuItem(
                    value: _TherapyAction.deletePermanently,
                    child: const _TherapyActionRow(
                      icon: Icons.delete_outline,
                      label: 'Elimina definitivamente',
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _TherapyHeader(
                  therapy: therapy,
                  medicineCount: medicines.length,
                ),
                const SizedBox(height: AppSpacing.xl),
                const DashboardSectionHeader('Medicine associate'),
                const SizedBox(height: AppSpacing.md),
                if (medicines.isEmpty)
                  _EmptyMedicines(therapy: therapy)
                else ...[
                  ...medicines.map(
                    (medicine) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TherapyMedicineTile(
                        medicine: medicine,
                        color: parseHexColor(therapy.color),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MedicineDetailScreen(medicine: medicine),
                          ),
                        ),
                        onDelete: () =>
                            _confirmDeleteMedicine(context, medicine),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _AddMedicineDashedButton(
                    enabled: therapy.isActive,
                    onTap: () => _openAddMedicine(context, therapy),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Therapy? _findTherapy(List<Therapy> therapies) {
    for (final therapy in therapies) {
      if (therapy.id == therapyId) return therapy;
    }
    return null;
  }

  Future<void> _openEdit(BuildContext context, Therapy therapy) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTherapyScreen(therapy: therapy)),
    );
  }

  Future<void> _openAddMedicine(BuildContext context, Therapy therapy) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddMedicineScreen(therapy: therapy)),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    Therapy therapy,
    List<Medicine> medicines,
    _TherapyAction action,
  ) async {
    if (action == _TherapyAction.exportPdf) {
      await _exportPdf(context, therapy, medicines);
      return;
    }

    if (action == _TherapyAction.reactivate) {
      try {
        await context.read<MedicineProvider>().reactivateTherapy(therapy.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Terapia riattivata')));
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    }

    final hasMedicines = therapy.medicines.isNotEmpty;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          action == _TherapyAction.archive
              ? 'Archiviare terapia?'
              : 'Eliminare terapia?',
        ),
        content: Text(
          action == _TherapyAction.archive
              ? 'Le medicine resteranno associate, ma la terapia verra archiviata.'
              : hasMedicines
              ? 'Questa terapia contiene ${therapy.medicines.length} medicine. '
                    'Eliminando la terapia verranno eliminate anche tutte le medicine associate. '
                    'L\'azione non puo essere annullata.'
              : 'Vuoi eliminare questa terapia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              action == _TherapyAction.archive
                  ? 'Archivia'
                  : hasMedicines
                  ? 'Elimina tutto'
                  : 'Elimina',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      if (action == _TherapyAction.archive) {
        await context.read<MedicineProvider>().archiveTherapy(therapy.id);
      } else {
        await context.read<MedicineProvider>().deleteTherapy(therapy.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == _TherapyAction.archive
                ? 'Terapia archiviata'
                : hasMedicines
                ? 'Terapia e medicine eliminate'
                : 'Terapia eliminata',
          ),
        ),
      );
      if (action == _TherapyAction.deletePermanently) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    Therapy therapy,
    List<Medicine> medicines,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<MedicineProvider>();
    File? generatedFile;

    try {
      final now = DateTime.now();
      final bytes = await TherapyPdfExportService.generateTherapySummary(
        therapy: therapy,
        medicines: medicines,
        intakeRecords: provider.intakeHistory,
        referenceDate: now,
      );
      final directory = await getTemporaryDirectory();
      final fileName = TherapyPdfExportService.buildFileName(
        therapyName: therapy.name,
        date: now,
      );
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      generatedFile = file;

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF generato. Scegli dove salvarlo o condividerlo.'),
        ),
      );

      final renderObject = context.findRenderObject();
      final sharePositionOrigin = renderObject is RenderBox
          ? renderObject.localToGlobal(Offset.zero) & renderObject.size
          : null;
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Riepilogo terapia Meditrack',
          subject: 'Riepilogo terapia Meditrack',
          text: 'Riepilogo terapia esportato da Meditrack.',
          files: [
            XFile(file.path, mimeType: 'application/pdf', name: fileName),
          ],
          fileNameOverrides: [fileName],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (!context.mounted) return;
      if (result.status == ShareResultStatus.unavailable) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Condivisione non disponibile. PDF generato localmente: ${file.path}',
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            generatedFile == null
                ? 'Impossibile generare il PDF. Riprova tra poco.'
                : 'PDF generato ma condivisione non riuscita: ${generatedFile.path}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteMedicine(
    BuildContext context,
    Medicine medicine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare medicina?'),
        content: Text('Vuoi eliminare ${medicine.name}?'),
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
      await context.read<MedicineProvider>().deleteMedicine(medicine.id);
      if (!context.mounted) return;
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
}

enum _TherapyAction { exportPdf, archive, deletePermanently, reactivate }

class _TherapyActionRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TherapyActionRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon), const SizedBox(width: 8), Text(label)]);
  }
}

class _TherapyHeader extends StatelessWidget {
  final Therapy therapy;
  final int medicineCount;

  const _TherapyHeader({required this.therapy, required this.medicineCount});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(therapy.color);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  therapyIconForCodePoint(therapy.iconCodePoint),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  therapy.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: therapy.isActive ? 'Attiva' : 'Archiviata',
                tone: therapy.isActive
                    ? StatusTone.positive
                    : StatusTone.neutral,
              ),
            ],
          ),
          if (therapy.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              therapy.description!,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.35),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _HeaderMeta(
                icon: Icons.medication_outlined,
                label: '$medicineCount medicine',
              ),
              if (therapy.startDate != null)
                _HeaderMeta(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(therapy.startDate!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _HeaderMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.inkFaint),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.inkSoft,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyMedicines extends StatelessWidget {
  final Therapy therapy;

  const _EmptyMedicines({required this.therapy});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Medora3DAsset(Medora3DAsset.blisterSoft, size: 96),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Nessuna medicina associata',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aggiungi la prima medicina per impostare orari e promemoria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: therapy.isActive
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMedicineScreen(therapy: therapy),
                    ),
                  )
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi medicina'),
          ),
        ],
      ),
    );
  }
}

/// Bottone "Aggiungi medicina" a riga tratteggiata (mockup 10).
class _AddMedicineDashedButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddMedicineDashedButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primary700 : AppColors.inkFaint;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Aggiungi medicina',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: CustomPaint(
            painter: _DashedRRectPainter(
              color: color.withValues(alpha: enabled ? 0.7 : 0.4),
              radius: AppRadius.md,
            ),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: color, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Aggiungi medicina',
                    style: TextStyle(
                      color: color,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashLength = 6.0;
    const gapLength = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _TherapyMedicineTile extends StatelessWidget {
  final Medicine medicine;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TherapyMedicineTile({
    required this.medicine,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final times = medicine.times;
    final visibleTimes = times.take(2).toList();
    final extraTimes = times.length - visibleTimes.length;
    final hasDose = medicine.dose.trim().isNotEmpty;
    final isLowStock = medicine.stockQuantity <= medicine.stockWarningThreshold;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medication_outlined, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (hasDose) ...[
                      const SizedBox(height: 2),
                      Text(
                        medicine.doseLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkFaint,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: medicine.isActive ? 'Attiva' : 'Inattiva',
                tone: medicine.isActive
                    ? StatusTone.positive
                    : StatusTone.neutral,
              ),
              PopupMenuButton<String>(
                tooltip: 'Azioni medicina',
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 8),
                        Text('Elimina'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (times.isEmpty)
                const _MedicineMetaChip(
                  icon: Icons.schedule,
                  label: 'Nessun orario',
                )
              else ...[
                for (final time in visibleTimes)
                  _MedicineMetaChip(
                    icon: Icons.schedule,
                    label: time.format(context),
                  ),
                if (extraTimes > 0)
                  _MedicineMetaChip(icon: null, label: '+$extraTimes'),
                _DayPeriodChip(time: times.first),
              ],
              _MedicineMetaChip(
                icon: Icons.inventory_2_outlined,
                label:
                    '${Medicine.formatQuantity(medicine.stockQuantity)} '
                    'rimaste',
                foreground: isLowStock ? AppColors.warning : null,
                background: isLowStock ? AppColors.warningTint : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip informativo compatto per la tile medicina (orario, scorta, extra).
class _MedicineMetaChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? foreground;
  final Color? background;

  const _MedicineMetaChip({
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? AppColors.border.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip fascia giornata (Mattina/Pomeriggio/Sera) derivato dall'orario:
/// pura presentazione, nessuna logica di dominio (mockup 10).
class _DayPeriodChip extends StatelessWidget {
  final TimeOfDay time;

  const _DayPeriodChip({required this.time});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (time.hour) {
      < 12 => ('Mattina', Icons.wb_sunny_outlined),
      < 18 => ('Pomeriggio', Icons.wb_twilight_outlined),
      _ => ('Sera', Icons.nightlight_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary800),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary800,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
