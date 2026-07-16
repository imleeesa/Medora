import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_card.dart';
import '../widgets/dashboard_section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/medora_3d_asset.dart';
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
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar ? AppBar(title: const Text('Terapie')) : null,
      body: Consumer<MedicineProvider>(
        builder: (context, provider, _) {
          final filtered = _filterTherapies(provider.therapies);
          final activeTherapies = filtered
              .where((therapy) => therapy.isActive)
              .toList();
          final archivedTherapies = filtered
              .where((therapy) => !therapy.isActive)
              .toList();
          final isSearching = _searchQuery.trim().isNotEmpty;

          return SafeArea(
            top: !widget.showAppBar,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Terapie',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Aggiungi medicina',
                        onPressed: _openAddMedicine,
                        icon: const Icon(Icons.medication_outlined),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        tooltip: 'Crea terapia',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openAddTherapy,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca terapia o medicina',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: const BorderSide(
                          color: AppColors.primary700,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          title: isSearching
                              ? 'Nessun risultato'
                              : 'Nessuna terapia',
                          description: isSearching
                              ? 'Prova con un nome diverso.'
                              : 'Crea la tua prima terapia e aggiungi le medicine quando serve.',
                          icon: isSearching
                              ? Icons.search_off
                              : Icons.spa_outlined,
                          imageAsset: isSearching
                              ? null
                              : Medora3DAsset.heartPulse,
                          buttonLabel: isSearching ? null : 'Crea Terapia',
                          onButtonPressed: isSearching ? null : _openAddTherapy,
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          children: [
                            if (activeTherapies.isNotEmpty) ...[
                              const DashboardSectionHeader('Attive'),
                              const SizedBox(height: AppSpacing.md),
                              ..._therapyTiles(context, activeTherapies),
                            ] else if (archivedTherapies.isNotEmpty)
                              _NoActiveTherapiesCard(onCreate: _openAddTherapy),
                            if (archivedTherapies.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              const DashboardSectionHeader('Archiviate'),
                              const SizedBox(height: AppSpacing.md),
                              ..._therapyTiles(context, archivedTherapies),
                            ],
                          ],
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
              backgroundColor: AppColors.primary700,
              onPressed: _openAddTherapy,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  List<Widget> _therapyTiles(BuildContext context, List<Therapy> therapies) {
    return [
      for (final therapy in therapies)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TherapyCard(
            therapy: therapy,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TherapyDetailScreen(therapyId: therapy.id),
              ),
            ),
          ),
        ),
    ];
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
    if (context.read<MedicineProvider>().therapies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Per aggiungere una medicina devi prima creare una terapia.',
          ),
          action: SnackBarAction(
            label: 'Crea terapia',
            onPressed: _openAddTherapy,
          ),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
    );
  }
}

/// Empty state "nessuna terapia attiva" quando esistono archiviate
/// (mockup 08): illustrazione leggera, messaggio calmo e CTA tonale.
class _NoActiveTherapiesCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _NoActiveTherapiesCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Medora3DAsset(Medora3DAsset.capsuleMint, size: 96),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Nessuna terapia attiva',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quando vorrai, potrai aggiungerne una nuova. Quelle concluse restano disponibili qui sotto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTint,
              foregroundColor: AppColors.primary800,
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Aggiungi terapia'),
          ),
        ],
      ),
    );
  }
}
