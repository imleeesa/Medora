import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import 'add_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class MedicinesScreen extends StatefulWidget {
  final bool showAppBar;

  const MedicinesScreen({super.key, this.showAppBar = true});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Terapie'),
              elevation: 0,
              backgroundColor: Colors.white,
            )
          : null,
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final therapies = _filterTherapies(provider.therapies);

          return SafeArea(
            top: !widget.showAppBar,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Terapie',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openAddMedicine,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca terapia o medicina...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: therapies.isEmpty
                      ? _EmptyTherapiesState(isSearching: _searchQuery.isNotEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: therapies.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _TherapyCard(
                              therapy: therapies[index],
                              onMedicineTap: (medicine) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicineDetailScreen(
                                      medicine: medicine,
                                    ),
                                  ),
                                );
                              },
                              onToggleMedicine: provider.toggleMedicineActive,
                              onDeleteMedicine: (medicine) {
                                _showDeleteDialog(
                                  context,
                                  medicine.name,
                                  () {
                                    provider.deleteMedicine(medicine.id);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: widget.showAppBar
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: _openAddMedicine,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  List<Therapy> _filterTherapies(List<Therapy> therapies) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return therapies;

    return therapies.where((therapy) {
      final therapyMatches = therapy.name.toLowerCase().contains(query);
      final medicineMatches = therapy.medicines.any(
        (medicine) => medicine.name.toLowerCase().contains(query),
      );
      return therapyMatches || medicineMatches;
    }).toList();
  }

  void _openAddMedicine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String medicineName,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminare medicina?'),
        content: Text(
          'Vuoi eliminare $medicineName? Questa azione vale solo per la sessione attuale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: onConfirm,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

class _TherapyCard extends StatelessWidget {
  final Therapy therapy;
  final ValueChanged<Medicine> onMedicineTap;
  final ValueChanged<String> onToggleMedicine;
  final ValueChanged<Medicine> onDeleteMedicine;

  const _TherapyCard({
    required this.therapy,
    required this.onMedicineTap,
    required this.onToggleMedicine,
    required this.onDeleteMedicine,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(therapy.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(Icons.spa, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      therapy.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${therapy.medicines.length} medicine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...therapy.medicines.map(
            (medicine) => _MedicineRow(
              medicine: medicine,
              color: color,
              onTap: () => onMedicineTap(medicine),
              onToggle: () => onToggleMedicine(medicine.id),
              onDelete: () => onDeleteMedicine(medicine),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorHex) {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

class _MedicineRow extends StatelessWidget {
  final Medicine medicine;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MedicineRow({
    required this.medicine,
    required this.color,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = medicine.times.isEmpty
        ? '--:--'
        : medicine.times.map((time) => time.format(context)).join(', ');

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.medication_outlined, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${medicine.dose} - $timeLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: medicine.isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: const Color(0xFF2E7D32),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Elimina')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTherapiesState extends StatelessWidget {
  final bool isSearching;

  const _EmptyTherapiesState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Nessun risultato' : 'Nessuna terapia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Prova con un nome diverso.'
                  : 'Aggiungi una medicina e assegnala a una terapia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
