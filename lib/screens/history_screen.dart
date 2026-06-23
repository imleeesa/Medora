import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intake_record.dart';
import '../providers/medicine_provider.dart';

class HistoryScreen extends StatelessWidget {
  final bool showAppBar;

  const HistoryScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: showAppBar ? AppBar(title: const Text('Storico')) : null,
      body: SafeArea(
        top: !showAppBar,
        child: Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            final records = provider.intakeHistory;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              children: [
                const Text(
                  'Storico',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                if (records.isEmpty)
                  _EmptyHistoryState(
                    hasMedicines: provider.medicines.isNotEmpty,
                  )
                else
                  ...records.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _IntakeHistoryCard(record: record),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final bool hasMedicines;

  const _EmptyHistoryState({required this.hasMedicines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.history, color: Color(0xFF2E7D32), size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessuna assunzione registrata',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            hasMedicines
                ? 'Quando confermerai o salterai le assunzioni, le vedrai qui.'
                : 'Aggiungi una terapia per iniziare a costruire lo storico.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntakeHistoryCard extends StatelessWidget {
  final IntakeRecord record;

  const _IntakeHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MedicineProvider>();
    final medicine = record.medicineId == null
        ? null
        : provider.getMedicineById(record.medicineId!);
    final therapy = medicine?.therapyId == null
        ? null
        : provider.getTherapyById(medicine!.therapyId!);
    final (label, color, icon) = switch (record.status) {
      IntakeStatus.taken => ('Assunta', const Color(0xFF2E7D32), Icons.check),
      IntakeStatus.skipped => (
        'Saltata',
        Colors.orange.shade800,
        Icons.skip_next_outlined,
      ),
      IntakeStatus.scheduled => (
        'Prevista',
        Colors.grey.shade700,
        Icons.schedule_outlined,
      ),
    };
    final displayedDateTime = record.actualDateTime ?? record.scheduledDateTime;
    final name = record.medicineNameSnapshot.trim().isEmpty
        ? medicine?.name ?? 'Medicina non disponibile'
        : record.medicineNameSnapshot;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  therapy?.name ?? 'Terapia non disponibile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  record.doseLabel,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(displayedDateTime),
                  style: const TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} - $hour:$minute';
  }
}
