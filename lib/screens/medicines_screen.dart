import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../widgets/therapy_card.dart';
import 'add_medicine_screen.dart';
import 'add_therapy_screen.dart';
import 'therapy_detail_screen.dart';

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
      appBar: widget.showAppBar ? AppBar(title: const Text('Terapie')) : null,
      body: Consumer<MedicineProvider>(
        builder: (context, provider, _) {
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
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Aggiungi medicina',
                        onPressed: _openAddMedicine,
                        icon: const Icon(Icons.medication_outlined),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Crea terapia',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openAddTherapy,
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
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: therapies.isEmpty
                      ? _EmptyTherapiesState(
                          isSearching: _searchQuery.isNotEmpty,
                          onCreate: _openAddTherapy,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: therapies.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final therapy = therapies[index];
                            return TherapyCard(
                              therapy: therapy,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TherapyDetailScreen(
                                    therapyId: therapy.id,
                                  ),
                                ),
                              ),
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
              tooltip: 'Crea terapia',
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: _openAddTherapy,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  List<Therapy> _filterTherapies(List<Therapy> therapies) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return therapies;

    return therapies
        .where((therapy) {
          final therapyMatches =
              therapy.name.toLowerCase().contains(query) ||
              (therapy.description?.toLowerCase().contains(query) ?? false);
          final medicineMatches = therapy.medicines.any(
            (medicine) => medicine.name.toLowerCase().contains(query),
          );
          return therapyMatches || medicineMatches;
        })
        .toList(growable: false);
  }

  Future<void> _openAddTherapy() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTherapyScreen()),
    );
  }

  Future<void> _openAddMedicine() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
    );
  }
}

class _EmptyTherapiesState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCreate;

  const _EmptyTherapiesState({
    required this.isSearching,
    required this.onCreate,
  });

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
                  : 'Crea una terapia, poi aggiungi le medicine quando serve.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Crea Terapia'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
