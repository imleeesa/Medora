import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/dashboard_section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/low_stock_mini_card.dart';
import '../widgets/medora_3d_asset.dart';
import '../widgets/next_intake_hero_card.dart';
import '../widgets/quick_action_sheet.dart';
import '../widgets/today_intake_card.dart';
import 'add_medicine_screen.dart';
import 'add_therapy_screen.dart';
import 'history_screen.dart';
import 'medicine_detail_screen.dart';
import 'medicines_screen.dart';
import 'profile_screen.dart';
import 'stock_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeDashboard(
        onQuickActions: () => _openQuickActions(context),
        onOpenProfile: () => setState(() => _selectedIndex = 3),
        onOpenHistory: () => setState(() => _selectedIndex = 2),
        onAddTherapy: () => _openAddTherapy(context),
        onAddMedicine: () => _openAddMedicine(context),
      ),
      const MedicinesScreen(showAppBar: false),
      const HistoryScreen(showAppBar: false),
      const ProfileScreen(showAppBar: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  void _openQuickActions(BuildContext context) {
    showQuickActionSheet(context, [
      QuickAction(
        icon: Icons.health_and_safety_outlined,
        label: 'Aggiungi terapia',
        onTap: () => _openAddTherapy(context),
      ),
      QuickAction(
        icon: Icons.medication_outlined,
        label: 'Aggiungi medicina',
        onTap: () => _openAddMedicine(context),
      ),
      QuickAction(
        icon: Icons.check_circle_outline,
        label: 'Registra assunzione',
        onTap: () => setState(() => _selectedIndex = 0),
      ),
      QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Ricarica scorta',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockScreen()),
        ),
      ),
    ]);
  }

  void _openAddTherapy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTherapyScreen()),
    );
  }

  void _openAddMedicine(BuildContext context) {
    if (context.read<MedicineProvider>().therapies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Per aggiungere una medicina devi prima creare una terapia.',
          ),
          action: SnackBarAction(
            label: 'Crea terapia',
            onPressed: () => _openAddTherapy(context),
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  final VoidCallback onQuickActions;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenHistory;
  final VoidCallback onAddTherapy;
  final VoidCallback onAddMedicine;

  const _HomeDashboard({
    required this.onQuickActions,
    required this.onOpenProfile,
    required this.onOpenHistory,
    required this.onAddTherapy,
    required this.onAddMedicine,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary700),
          );
        }

        final therapies = provider.therapies;
        final nextIntake = provider.getNextScheduledIntake();
        final lowStockMedicines = provider.getLowStockMedicines();
        final todayIntakes = provider.getTodayScheduledIntakes();

        String? therapyNameFor(Medicine medicine) {
          final therapyId = medicine.therapyId;
          if (therapyId == null) return null;
          return provider.getTherapyById(therapyId)?.name;
        }

        if (therapies.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  _Header(
                    name: provider.currentProfile.name,
                    onQuickActions: onQuickActions,
                    onOpenProfile: onOpenProfile,
                  ),
                  Expanded(
                    child: EmptyState(
                      title: 'Nessuna terapia ancora',
                      description:
                          'Inizia aggiungendo la tua prima terapia per ricevere promemoria e tenere tutto sotto controllo.',
                      icon: Icons.health_and_safety_outlined,
                      imageAsset: Medora3DAsset.emptyPillsIllustration,
                      buttonLabel: 'Aggiungi terapia',
                      onButtonPressed: onAddTherapy,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    name: provider.currentProfile.name,
                    onQuickActions: onQuickActions,
                    onOpenProfile: onOpenProfile,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _TodayTitle(date: DateTime.now()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: nextIntake == null
                      ? const _NoNextIntakeCard()
                      : NextIntakeHeroCard(
                          intake: nextIntake,
                          therapyName: therapyNameFor(nextIntake.medicine),
                          lowStock:
                              nextIntake.medicine.stockQuantity <=
                              nextIntake.medicine.stockWarningThreshold,
                          onTap: () => _openMedicineDetail(
                            context,
                            nextIntake.medicine.id,
                          ),
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: TodayIntakesCard(
                    intakes: todayIntakes,
                    onOpenMedicine: (medicineId) =>
                        _openMedicineDetail(context, medicineId),
                  ),
                ),
              ),
              if (lowStockMedicines.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: _LowStockCard(
                      lowStockMedicines: lowStockMedicines,
                      onOpenMedicine: (medicineId) =>
                          _openMedicineDetail(context, medicineId),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: _QuickActionsSection(
                    onAddMedicine: onAddMedicine,
                    onAddTherapy: onAddTherapy,
                    onOpenHistory: onOpenHistory,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _openMedicineDetail(BuildContext context, String medicineId) {
  final provider = context.read<MedicineProvider>();
  final medicine = provider.getMedicineById(medicineId);
  if (medicine == null) return;

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: medicine)),
  );
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onQuickActions;
  final VoidCallback onOpenProfile;

  const _Header({
    required this.name,
    required this.onQuickActions,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Profilo',
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onOpenProfile,
              customBorder: const CircleBorder(),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(DateTime.now().hour),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderIconButton(
          icon: Icons.add,
          semanticLabel: 'Azioni rapide',
          onTap: onQuickActions,
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Buongiorno,';
    if (hour < 18) return 'Buon pomeriggio,';
    return 'Buonasera,';
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'M';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.primaryTint,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary700),
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, child: circle);
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: circle,
        ),
      ),
    );
  }
}

class _TodayTitle extends StatelessWidget {
  final DateTime date;

  const _TodayTitle({required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oggi',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _dateLabel(date),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    const weekdays = [
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
      'Domenica',
    ];
    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];

    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

class _NoNextIntakeCard extends StatelessWidget {
  const _NoNextIntakeCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.primary700),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Nessun\'altra assunzione prevista per oggi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final List<Medicine> lowStockMedicines;
  final void Function(String medicineId) onOpenMedicine;

  const _LowStockCard({
    required this.lowStockMedicines,
    required this.onOpenMedicine,
  });

  @override
  Widget build(BuildContext context) {
    final count = lowStockMedicines.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Medora3DAsset(Medora3DAsset.pillAmber, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scorte basse',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      count == 1
                          ? 'Una medicina sta per finire.'
                          : '$count medicine stanno per finire.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final medicine in lowStockMedicines)
            LowStockMiniCard(
              medicine: medicine,
              onTap: () => onOpenMedicine(medicine.id),
            ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddMedicine;
  final VoidCallback onAddTherapy;
  final VoidCallback onOpenHistory;

  const _QuickActionsSection({
    required this.onAddMedicine,
    required this.onAddTherapy,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader('Azioni rapide'),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.medication_outlined,
                  label: 'Aggiungi\nmedicina',
                  onTap: onAddMedicine,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.health_and_safety_outlined,
                  label: 'Aggiungi\nterapia',
                  onTap: onAddTherapy,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.history,
                  label: 'Vedi\nstorico',
                  onTap: onOpenHistory,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary700, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
