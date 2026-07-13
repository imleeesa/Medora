import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/scheduled_intake.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/color_parser.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/dashboard_section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/low_stock_mini_card.dart';
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTherapyScreen()),
        ),
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

  void _openAddMedicine(BuildContext context) {
    if (context.read<MedicineProvider>().therapies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Per aggiungere una medicina devi prima creare una terapia.',
          ),
          action: SnackBarAction(
            label: 'Crea terapia',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTherapyScreen()),
            ),
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

  const _HomeDashboard({
    required this.onQuickActions,
    required this.onOpenProfile,
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

        return SafeArea(
          child: therapies.isEmpty
              ? Padding(
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
                          title: 'Non hai ancora aggiunto terapie',
                          description:
                              'Crea la tua prima terapia e aggiungi i farmaci da seguire',
                          icon: Icons.health_and_safety_outlined,
                          buttonLabel: 'Crea Terapia',
                          onButtonPressed: () => _openAddTherapy(context),
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: _Header(
                          name: provider.currentProfile.name,
                          onQuickActions: onQuickActions,
                          onOpenProfile: onOpenProfile,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverToBoxAdapter(
                        child: nextIntake == null
                            ? const _NoNextIntakeCard()
                            : NextIntakeHeroCard(
                                intake: nextIntake,
                                therapyName: therapyNameFor(
                                  nextIntake.medicine,
                                ),
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
                        child: _TodayIntakesSection(
                          intakes: todayIntakes,
                          therapyNameFor: therapyNameFor,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverToBoxAdapter(
                        child: _LowStockSection(
                          lowStockMedicines: lowStockMedicines,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _TherapiesSection(
                          therapies: therapies
                              .where((therapy) => therapy.isActive)
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _openAddTherapy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTherapyScreen()),
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
    final date = _dateLabel(DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buongiorno, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _capitalize(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.add,
          semanticLabel: 'Azioni rapide',
          onTap: onQuickActions,
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.person,
          semanticLabel: 'Profilo',
          onTap: onOpenProfile,
        ),
      ],
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _dateLabel(DateTime date) {
    const weekdays = [
      'Luned\u00EC',
      'Marted\u00EC',
      'Mercoled\u00EC',
      'Gioved\u00EC',
      'Venerd\u00EC',
      'Sabato',
      'Domenica',
    ];
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];

    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
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

class _TodayIntakesSection extends StatelessWidget {
  final List<ScheduledIntake> intakes;
  final String? Function(Medicine medicine) therapyNameFor;

  const _TodayIntakesSection({
    required this.intakes,
    required this.therapyNameFor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader('Assunzioni di oggi'),
        const SizedBox(height: AppSpacing.md),
        if (intakes.isEmpty)
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primary700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Nessuna assunzione programmata per oggi.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...intakes.map(
            (intake) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TodayIntakeCard(
                intake: intake,
                therapyName: therapyNameFor(intake.medicine),
                onTap: () => _openMedicineDetail(context, intake.medicine.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _TherapiesSection extends StatelessWidget {
  final List<Therapy> therapies;

  const _TherapiesSection({required this.therapies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader('Terapie attive'),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: therapies.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) =>
                _TherapyChipCard(therapy: therapies[index]),
          ),
        ),
      ],
    );
  }
}

class _TherapyChipCard extends StatelessWidget {
  final Therapy therapy;

  const _TherapyChipCard({required this.therapy});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(therapy.color);

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 152, maxWidth: 220),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(Icons.spa, color: color, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                therapy.name,
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
                '${therapy.medicines.length} medicine',
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
      ),
    );
  }
}

class _LowStockSection extends StatelessWidget {
  final List<Medicine> lowStockMedicines;

  const _LowStockSection({required this.lowStockMedicines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader('Scorte'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: lowStockMedicines.isEmpty
              ? Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.primary700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Tutte le scorte sono a posto',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final medicine in lowStockMedicines)
                      LowStockMiniCard(
                        medicine: medicine,
                        onTap: () => _openMedicineDetail(context, medicine.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
