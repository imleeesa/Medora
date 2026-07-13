import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/intake_record.dart';
import '../models/intake_stock_change.dart';
import '../models/scheduled_intake.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/quick_action_sheet.dart';
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
      _HomeDashboard(onQuickActions: () => _openQuickActions(context)),
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

  const _HomeDashboard({required this.onQuickActions});

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

        return SafeArea(
          child: therapies.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    children: [
                      _Header(
                        name: provider.currentProfile.name,
                        onQuickActions: onQuickActions,
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
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: _Header(
                          name: provider.currentProfile.name,
                          onQuickActions: onQuickActions,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      sliver: SliverToBoxAdapter(
                        child: nextIntake == null
                            ? const _NoNextMedicineCard()
                            : _NextMedicineCard(intake: nextIntake),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      sliver: SliverToBoxAdapter(
                        child: _TodayIntakesSection(intakes: todayIntakes),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      sliver: SliverToBoxAdapter(
                        child: _TherapiesSection(therapies: therapies),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      sliver: SliverToBoxAdapter(
                        child: _TodaySummary(
                          todayCount: todayIntakes.length,
                          activeTherapies: therapies
                              .where((therapy) => therapy.isActive)
                              .length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverToBoxAdapter(
                        child: _WarningsSection(
                          lowStockMedicines: lowStockMedicines,
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

  const _Header({required this.name, required this.onQuickActions});

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
        const _HeaderIconButton(icon: Icons.person, semanticLabel: 'Profilo'),
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

class _NextMedicineCard extends StatelessWidget {
  final ScheduledIntake intake;

  const _NextMedicineCard({required this.intake});

  @override
  Widget build(BuildContext context) {
    final medicine = intake.medicine;
    final nextTime = TimeOfDay.fromDateTime(intake.scheduledDateTime);

    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openMedicineDetail(context, medicine.id),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Prossima Medicina',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  medicine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dose: ${medicine.doseLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      icon: Icons.schedule,
                      label: nextTime.format(context),
                    ),
                    _Pill(
                      icon: Icons.timer_outlined,
                      label: 'Tra ${_timeUntil(intake.scheduledDateTime)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeUntil(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    final minutes = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoNextMedicineCard extends StatelessWidget {
  const _NoNextMedicineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.check, color: Color(0xFF2E7D32)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Nessuna altra terapia programmata per oggi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayIntakesSection extends StatelessWidget {
  final List<ScheduledIntake> intakes;

  const _TodayIntakesSection({required this.intakes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Assunzioni di oggi'),
        const SizedBox(height: 12),
        if (intakes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'Nessuna assunzione programmata per oggi.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        else
          ...intakes.map(
            (intake) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TodayIntakeCard(intake: intake),
            ),
          ),
      ],
    );
  }
}

class _TodayIntakeCard extends StatelessWidget {
  final ScheduledIntake intake;

  const _TodayIntakeCard({required this.intake});

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(
      intake.scheduledDateTime,
    ).format(context);
    final status = intake.status;
    final isScheduled = status == IntakeStatus.scheduled;
    final statusColor = switch (status) {
      IntakeStatus.taken => const Color(0xFF2E7D32),
      IntakeStatus.skipped => Colors.orange.shade800,
      IntakeStatus.missed => Colors.red.shade700,
      IntakeStatus.scheduled => Colors.grey.shade700,
    };
    final statusLabel = switch (status) {
      IntakeStatus.taken => 'Assunta',
      IntakeStatus.skipped => 'Saltata',
      IntakeStatus.missed => 'Dimenticata',
      IntakeStatus.scheduled => 'Prevista',
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openMedicineDetail(context, intake.medicine.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      intake.medicine.name,
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
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                intake.medicine.doseLabel,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (isScheduled) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _mark(context, IntakeStatus.skipped),
                      icon: const Icon(Icons.skip_next_outlined),
                      label: const Text('Saltata'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _mark(context, IntakeStatus.taken),
                      icon: const Icon(Icons.check),
                      label: const Text('Assunta'),
                    ),
                  ],
                ),
              ] else if (status == IntakeStatus.taken) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _mark(context, IntakeStatus.skipped),
                  icon: const Icon(Icons.undo_outlined),
                  label: const Text('Segna come saltata'),
                ),
              ] else ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _mark(context, IntakeStatus.taken),
                  icon: const Icon(Icons.check),
                  label: const Text('Segna come assunta'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mark(BuildContext context, IntakeStatus status) async {
    final provider = context.read<MedicineProvider>();
    try {
      final stockChange = status == IntakeStatus.taken
          ? await provider.markMedicineAsTaken(
              medicineId: intake.medicine.id,
              scheduledDateTime: intake.scheduledDateTime,
            )
          : await provider.markMedicineAsSkipped(
              medicineId: intake.medicine.id,
              scheduledDateTime: intake.scheduledDateTime,
            );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_feedbackMessage(status, stockChange))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  String _feedbackMessage(IntakeStatus status, IntakeStockChange stockChange) {
    return switch (stockChange) {
      IntakeStockChange.decreased =>
        'Assunzione registrata. Scorta aggiornata.',
      IntakeStockChange.restored => 'Assunzione saltata. Scorta ripristinata.',
      IntakeStockChange.noQuantity =>
        status == IntakeStatus.taken
            ? 'Assunzione registrata. Scorta non aggiornata: quantita non gestibile.'
            : 'Assunzione segnata come saltata.',
      IntakeStockChange.unchanged =>
        status == IntakeStatus.taken
            ? 'Assunzione gia registrata.'
            : 'Assunzione segnata come saltata.',
    };
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
        const _SectionTitle('Terapie attive'),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: therapies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final therapy = therapies[index];
              return _TherapySummaryCard(therapy: therapy);
            },
          ),
        ),
      ],
    );
  }
}

class _TherapySummaryCard extends StatelessWidget {
  final Therapy therapy;

  const _TherapySummaryCard({required this.therapy});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(therapy.color);

    return Container(
      width: 178,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.spa, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            therapy.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${therapy.medicines.length} medicine',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
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

class _TodaySummary extends StatelessWidget {
  final int todayCount;
  final int activeTherapies;

  const _TodaySummary({
    required this.todayCount,
    required this.activeTherapies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Attivita di oggi'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CompactSummaryCard(
                icon: Icons.medication_outlined,
                label: 'Assunzioni',
                value: '$todayCount',
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactSummaryCard(
                icon: Icons.spa_outlined,
                label: 'Terapie',
                value: '$activeTherapies',
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompactSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningsSection extends StatelessWidget {
  final List<Medicine> lowStockMedicines;

  const _WarningsSection({required this.lowStockMedicines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Avvisi'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: lowStockMedicines.isEmpty
              ? Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.check, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nessun avviso importante per oggi',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lowStockMedicines
                      .map(
                        (medicine) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Scorta bassa: ${medicine.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E1E1E),
        letterSpacing: 0,
      ),
    );
  }
}
