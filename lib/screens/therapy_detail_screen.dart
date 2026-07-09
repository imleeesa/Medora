import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/medicine.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../services/therapy_pdf_export_service.dart';
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
          backgroundColor: const Color(0xFFF5F7F8),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Medicine associate',
                        style: TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Aggiungi medicina',
                      onPressed: therapy.isActive
                          ? () => _openAddMedicine(context, therapy)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (medicines.isEmpty)
                  _EmptyMedicines(therapy: therapy)
                else
                  ...medicines.map(
                    (medicine) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TherapyMedicineTile(
                        medicine: medicine,
                        color: _parseColor(therapy.color),
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

  Color _parseColor(String colorHex) {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
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
    final color = _parseColor(therapy.color);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(
                    therapy.iconCodePoint ?? Icons.spa.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  therapy.name,
                  style: const TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(isActive: therapy.isActive, color: color),
            ],
          ),
          if (therapy.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            Text(
              therapy.description!,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 8,
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

  Color _parseColor(String colorHex) {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _StatusPill({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? color : Colors.grey).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Attiva' : 'Archiviata',
        style: TextStyle(
          color: isActive ? color : Colors.grey.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 38,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'Nessuna medicina associata',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
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
            label: const Text('Aggiungi Medicina'),
          ),
        ],
      ),
    );
  }
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
    final schedules = medicine.times
        .map((time) => time.format(context))
        .join(', ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.medication_outlined, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${medicine.doseLabel} - $schedules',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                medicine.isActive
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                color: medicine.isActive ? color : Colors.grey.shade500,
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
        ),
      ),
    );
  }
}
