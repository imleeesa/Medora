import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';
import '../providers/medicine_provider.dart';
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

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F8),
          appBar: AppBar(
            title: const Text('Dettagli Medicina'),
            elevation: 0,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                key: const ValueKey('medicine-detail-edit-button'),
                tooltip: 'Modifica medicina',
                onPressed: () => _editMedicine(context, currentMedicine),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Cambia terapia',
                onPressed: () => _changeTherapy(context, currentMedicine),
                icon: const Icon(Icons.swap_horiz_outlined),
              ),
              IconButton(
                tooltip: 'Elimina medicina',
                onPressed: () => _confirmDelete(context, currentMedicine),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _parseColor(currentMedicine.color),
                        _parseColor(
                          currentMedicine.color,
                        ).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMedicine.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dosaggio: ${currentMedicine.doseLabel}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentMedicine.isActive ? 'Attiva' : 'Inattiva',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Builder(
                  builder: (context) {
                    final therapy = currentMedicine.therapyId == null
                        ? null
                        : provider.getTherapyById(currentMedicine.therapyId!);
                    return _buildSection(
                      title: 'Terapia',
                      icon: Icons.medical_information_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              therapy?.name ?? 'Terapia non disponibile',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () =>
                                _changeTherapy(context, currentMedicine),
                            icon: const Icon(Icons.swap_horiz_outlined),
                            label: const Text('Cambia'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Orari
                _buildSection(
                  title: 'Orari di Assunzione',
                  icon: Icons.schedule,
                  child: _ScheduleList(
                    schedules: _displaySchedules(currentMedicine),
                  ),
                ),
                const SizedBox(height: 16),

                // Giorni
                _buildSection(
                  title: 'Giorni della Settimana',
                  icon: Icons.calendar_today,
                  child: Wrap(
                    spacing: 8,
                    children: _getDayNames(currentMedicine.daysOfWeek)
                        .map(
                          (day) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Stock
                _buildSection(
                  title: 'Giacenza',
                  icon: Icons.inventory_2_outlined,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantita attuale',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Medicine.formatQuantity(
                                currentMedicine.stockQuantity,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              currentMedicine.stockQuantity <=
                                  currentMedicine.stockWarningThreshold
                              ? Colors.orange[50]
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                currentMedicine.stockQuantity <=
                                    currentMedicine.stockWarningThreshold
                                ? Colors.orange[300]!
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Soglia Minima',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Medicine.formatQuantity(
                                currentMedicine.stockWarningThreshold,
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color:
                                    currentMedicine.stockQuantity <=
                                        currentMedicine.stockWarningThreshold
                                    ? Colors.orange
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Note
                if (currentMedicine.notes != null &&
                    currentMedicine.notes!.isNotEmpty)
                  _buildSection(
                    title: 'Note',
                    icon: Icons.note_outlined,
                    child: Text(
                      currentMedicine.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E1E1E),
                        height: 1.6,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Costruisce una sezione
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
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
                    final color = _parseColor(therapy.color);
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

  /// Ottiene i nomi dei giorni
  List<String> _getDayNames(List<int> days) {
    const names = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final safeDays = days.toSet().where((day) => day >= 1 && day <= 7).toList()
      ..sort();
    return safeDays.map((d) => names[d - 1]).toList();
  }

  List<MedicineSchedule> _displaySchedules(Medicine medicine) {
    final sourceSchedules = medicine.schedules
        .where((schedule) => schedule.isActive)
        .toList(growable: false);
    final schedules = sourceSchedules.isNotEmpty
        ? sourceSchedules
        : medicine.times
              .map(
                (time) => MedicineSchedule(
                  time: time,
                  daysOfWeek: medicine.daysOfWeek,
                ),
              )
              .toList(growable: false);

    final daysByTime = <String, Set<int>>{};
    final timeByKey = <String, TimeOfDay>{};
    for (final schedule in schedules) {
      final key = '${schedule.time.hour}:${schedule.time.minute}';
      timeByKey[key] = schedule.time;
      daysByTime.putIfAbsent(key, () => <int>{}).addAll(schedule.daysOfWeek);
    }

    final result = daysByTime.entries.map((entry) {
      final time = timeByKey[entry.key]!;
      final days = entry.value.where((day) => day >= 1 && day <= 7).toList()
        ..sort();
      return MedicineSchedule(time: time, daysOfWeek: days);
    }).toList();

    result.sort((first, second) {
      final firstMinutes = first.time.hour * 60 + first.time.minute;
      final secondMinutes = second.time.hour * 60 + second.time.minute;
      return firstMinutes.compareTo(secondMinutes);
    });
    return result;
  }

  /// Converte codice colore hex a Color
  Color _parseColor(String colorHex) {
    colorHex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$colorHex', radix: 16));
  }
}

class _ScheduleList extends StatelessWidget {
  final List<MedicineSchedule> schedules;

  const _ScheduleList({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Text(
        'Nessun orario programmato',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Column(
      children: schedules
          .map(
            (schedule) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    key: ValueKey(
                      'medicine-schedule-time-${schedule.time.hour}-${schedule.time.minute}',
                    ),
                    width: 72,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        schedule.time.format(context),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dayNames(schedule.daysOfWeek).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  List<String> _dayNames(List<int> days) {
    const names = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final safeDays = days.toSet().where((day) => day >= 1 && day <= 7).toList()
      ..sort();
    return safeDays.map((day) => names[day - 1]).toList(growable: false);
  }
}
