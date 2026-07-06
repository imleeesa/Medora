import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intake_record.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../services/history_filter_service.dart';

class HistoryScreen extends StatefulWidget {
  final bool showAppBar;

  const HistoryScreen({super.key, this.showAppBar = true});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _allValue = '__all__';

  HistoryStatusFilter _statusFilter = HistoryStatusFilter.all;
  HistoryPeriodFilter _periodFilter = HistoryPeriodFilter.all;
  String? _selectedTherapyId;
  String _selectedMedicineValue = _allValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: widget.showAppBar ? AppBar(title: const Text('Storico')) : null,
      body: SafeArea(
        top: !widget.showAppBar,
        child: Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            final allRecords = provider.intakeHistory;
            final medicineOptions = HistoryFilterService.buildMedicineOptions(
              records: allRecords,
              therapies: provider.therapies,
            );
            final selectedMedicine = _selectedMedicineOption(medicineOptions);
            final therapyIds = provider.therapies
                .map((therapy) => therapy.id)
                .toSet();
            final selectedTherapyId =
                _selectedTherapyId != null &&
                    therapyIds.contains(_selectedTherapyId)
                ? _selectedTherapyId
                : null;
            final filters = HistoryFilters(
              status: _statusFilter,
              period: _periodFilter,
              therapyId: selectedTherapyId,
              medicineId: selectedMedicine?.medicineId,
              medicineSnapshotName: selectedMedicine?.snapshotName,
            );
            final records = HistoryFilterService.filterRecords(
              records: allRecords,
              therapies: provider.therapies,
              filters: filters,
              referenceDate: DateTime.now(),
            );
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
                _HistoryFiltersPanel(
                  statusFilter: _statusFilter,
                  periodFilter: _periodFilter,
                  selectedTherapyId: selectedTherapyId,
                  selectedMedicineValue: selectedMedicine == null
                      ? _allValue
                      : _selectedMedicineValue,
                  therapies: provider.therapies,
                  medicineOptions: medicineOptions,
                  hasActiveFilters: filters.hasActiveFilters,
                  onStatusChanged: (value) =>
                      setState(() => _statusFilter = value),
                  onPeriodChanged: (value) =>
                      setState(() => _periodFilter = value),
                  onTherapyChanged: (value) => setState(
                    () =>
                        _selectedTherapyId = value == _allValue ? null : value,
                  ),
                  onMedicineChanged: (value) =>
                      setState(() => _selectedMedicineValue = value),
                  onReset: _resetFilters,
                ),
                const SizedBox(height: 16),
                if (allRecords.isEmpty)
                  _EmptyHistoryState(
                    hasMedicines: provider.medicines.isNotEmpty,
                  )
                else if (records.isEmpty)
                  const _EmptyFilteredHistoryState()
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

  HistoryMedicineFilterOption? _selectedMedicineOption(
    List<HistoryMedicineFilterOption> options,
  ) {
    if (_selectedMedicineValue == _allValue) return null;
    for (final option in options) {
      if (option.value == _selectedMedicineValue) return option;
    }
    return null;
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = HistoryStatusFilter.all;
      _periodFilter = HistoryPeriodFilter.all;
      _selectedTherapyId = null;
      _selectedMedicineValue = _allValue;
    });
  }
}

class _HistoryFiltersPanel extends StatelessWidget {
  static const _allValue = _HistoryScreenState._allValue;

  final HistoryStatusFilter statusFilter;
  final HistoryPeriodFilter periodFilter;
  final String? selectedTherapyId;
  final String selectedMedicineValue;
  final List<Therapy> therapies;
  final List<HistoryMedicineFilterOption> medicineOptions;
  final bool hasActiveFilters;
  final ValueChanged<HistoryStatusFilter> onStatusChanged;
  final ValueChanged<HistoryPeriodFilter> onPeriodChanged;
  final ValueChanged<String> onTherapyChanged;
  final ValueChanged<String> onMedicineChanged;
  final VoidCallback onReset;

  const _HistoryFiltersPanel({
    required this.statusFilter,
    required this.periodFilter,
    required this.selectedTherapyId,
    required this.selectedMedicineValue,
    required this.therapies,
    required this.medicineOptions,
    required this.hasActiveFilters,
    required this.onStatusChanged,
    required this.onPeriodChanged,
    required this.onTherapyChanged,
    required this.onMedicineChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTherapies = List<Therapy>.from(therapies)
      ..sort(
        (first, second) =>
            first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      );
    final medicineValues = {
      _allValue,
      for (final option in medicineOptions) option.value,
    };
    final safeMedicineValue = medicineValues.contains(selectedMedicineValue)
        ? selectedMedicineValue
        : _allValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns = constraints.maxWidth >= 520;
          final itemWidth = useTwoColumns
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _FilterDropdown<HistoryStatusFilter>(
                      key: const ValueKey('history-status-filter'),
                      label: 'Stato',
                      value: statusFilter,
                      items: HistoryStatusFilter.values,
                      itemLabel: _statusLabel,
                      onChanged: onStatusChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _FilterDropdown<HistoryPeriodFilter>(
                      key: const ValueKey('history-period-filter'),
                      label: 'Periodo',
                      value: periodFilter,
                      items: HistoryPeriodFilter.values,
                      itemLabel: _periodLabel,
                      onChanged: onPeriodChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _FilterDropdown<String>(
                      key: const ValueKey('history-therapy-filter'),
                      label: 'Terapia',
                      value: selectedTherapyId ?? _allValue,
                      items: [
                        _allValue,
                        for (final therapy in sortedTherapies) therapy.id,
                      ],
                      itemLabel: (value) => value == _allValue
                          ? 'Tutte le terapie'
                          : sortedTherapies
                                .firstWhere((therapy) => therapy.id == value)
                                .name,
                      onChanged: onTherapyChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _FilterDropdown<String>(
                      key: const ValueKey('history-medicine-filter'),
                      label: 'Medicina',
                      value: safeMedicineValue,
                      items: [
                        _allValue,
                        for (final option in medicineOptions) option.value,
                      ],
                      itemLabel: (value) {
                        if (value == _allValue) return 'Tutte le medicine';
                        return medicineOptions
                            .firstWhere((option) => option.value == value)
                            .label;
                      },
                      onChanged: onMedicineChanged,
                    ),
                  ),
                ],
              ),
              if (hasActiveFilters) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('history-reset-filters'),
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset filtri'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(HistoryStatusFilter value) {
    return switch (value) {
      HistoryStatusFilter.all => 'Tutti',
      HistoryStatusFilter.taken => 'Assunte',
      HistoryStatusFilter.skipped => 'Saltate',
      HistoryStatusFilter.missed => 'Dimenticate',
    };
  }

  String _periodLabel(HistoryPeriodFilter value) {
    return switch (value) {
      HistoryPeriodFilter.today => 'Oggi',
      HistoryPeriodFilter.last7Days => 'Ultimi 7 giorni',
      HistoryPeriodFilter.last30Days => 'Ultimi 30 giorni',
      HistoryPeriodFilter.all => 'Tutto',
    };
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F7F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
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

class _EmptyFilteredHistoryState extends StatelessWidget {
  const _EmptyFilteredHistoryState();

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
            child: Icon(
              Icons.filter_alt_off_outlined,
              color: Color(0xFF2E7D32),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessuna assunzione trovata con questi filtri.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova a cambiare periodo, stato, terapia o medicina.',
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
      IntakeStatus.missed => (
        'Dimenticata',
        Colors.red.shade700,
        Icons.error_outline,
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
