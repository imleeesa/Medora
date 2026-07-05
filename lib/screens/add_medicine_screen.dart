import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../widgets/primary_button.dart';

class AddMedicineScreen extends StatefulWidget {
  final Therapy? therapy;
  final Medicine? medicine;

  const AddMedicineScreen({super.key, this.therapy, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customQuantityController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _notesController = TextEditingController();
  final _stockController = TextEditingController(text: '30');
  final _warningController = TextEditingController(text: '5');

  final List<_ScheduleFormGroup> _scheduleGroups = [];
  String? _selectedTherapyId;
  String? _selectedQuantity;
  String? _selectedUnit;
  bool _isCustomQuantity = false;
  String _selectedColor = '#2E7D32';
  bool _isLoading = false;

  bool get _isEditing => widget.medicine != null;

  final List<String> _colors = [
    '#2E7D32',
    '#4CAF50',
    '#00796B',
    '#607D8B',
    '#8BC34A',
    '#9E9E9E',
  ];

  static const _quantityPresets = ['1', '1/2', '1/4', '2', '3'];
  static const _unitOptions = [
    'pastiglia',
    'compressa',
    'capsula',
    'gocce',
    'ml',
    'mg',
    'bustina',
    'spray',
    'cucchiaino',
    'unita',
    'Altro',
  ];

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;
    final therapy = widget.therapy;
    if (medicine != null) {
      _nameController.text = medicine.name;
      _notesController.text = medicine.notes ?? '';
      _stockController.text = Medicine.formatQuantity(medicine.stockQuantity);
      _warningController.text = Medicine.formatQuantity(
        medicine.stockWarningThreshold,
      );
      _selectedTherapyId = medicine.therapyId ?? therapy?.id;
      _selectedColor = medicine.color;
      final activeSchedules = medicine.schedules
          .where((schedule) => schedule.isActive)
          .toList(growable: false);
      _scheduleGroups.addAll(
        _groupsFromSchedules(
          activeSchedules.isEmpty
              ? medicine.times.map(
                  (time) => MedicineSchedule(
                    time: time,
                    daysOfWeek: medicine.daysOfWeek,
                  ),
                )
              : activeSchedules,
        ),
      );
      _seedDose(medicine.dose);
    } else if (therapy != null) {
      _selectedTherapyId = therapy.id;
      _selectedColor = therapy.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customQuantityController.dispose();
    _customUnitController.dispose();
    _notesController.dispose();
    _stockController.dispose();
    _warningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeKeyboardAndPop,
        ),
        title: Text(_isEditing ? 'Modifica Medicina' : 'Aggiungi Medicina'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.therapy == null && !_isEditing) ...[
                        _buildLabel('Terapia *'),
                        const SizedBox(height: 8),
                        _buildTherapySelector(),
                      ] else if (widget.therapy != null) ...[
                        _buildLabel('Terapia'),
                        const SizedBox(height: 8),
                        _SelectedTherapyField(therapy: widget.therapy!),
                      ] else ...[
                        _buildLabel('Terapia'),
                        const SizedBox(height: 8),
                        _ReadOnlyInfoField(
                          icon: Icons.spa_outlined,
                          text: 'Terapia non disponibile',
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildLabel('Nome Medicina *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('medicine-name-field'),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Es. Tachipirina',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true
                            ? 'Inserisci il nome'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Quantita per assunzione'),
                      const SizedBox(height: 8),
                      _buildDoseFields(),
                      const SizedBox(height: 20),
                      _buildLabel('Programmazione assunzioni *'),
                      const SizedBox(height: 8),
                      _buildScheduleGroupsSection(),
                      const SizedBox(height: 20),
                      _buildStockFields(),
                      const SizedBox(height: 20),
                      _buildLabel('Colore'),
                      const SizedBox(height: 8),
                      _buildColorPicker(),
                      const SizedBox(height: 20),
                      _buildLabel('Note'),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('medicine-notes-field'),
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: 'Es. Prendere dopo i pasti',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: _isEditing
                              ? 'Salva Modifiche'
                              : 'Aggiungi Medicina',
                          icon: _isEditing ? Icons.save_outlined : Icons.add,
                          isLoading: _isLoading,
                          onPressed: _saveMedicine,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _closeKeyboardAndPop,
                          child: const Text('Annulla'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E1E1E),
      ),
    );
  }

  Widget _buildTherapySelector() {
    return Consumer<MedicineProvider>(
      builder: (context, provider, _) => DropdownButtonFormField<String>(
        value: _selectedTherapyId,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Seleziona una terapia',
          filled: true,
          fillColor: Colors.white,
        ),
        items: provider.therapies
            .map(
              (therapy) => DropdownMenuItem(
                value: therapy.id,
                child: Text(
                  therapy.isActive
                      ? therapy.name
                      : '${therapy.name} (archiviata)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: (therapyId) {
          setState(() => _selectedTherapyId = therapyId);
        },
        validator: (value) => value == null ? 'Seleziona una terapia' : null,
      ),
    );
  }

  Widget _buildDoseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._quantityPresets.map(
              (quantity) => ChoiceChip(
                label: Text(quantity),
                selected: !_isCustomQuantity && _selectedQuantity == quantity,
                onSelected: (_) {
                  setState(() {
                    _selectedQuantity = quantity;
                    _isCustomQuantity = false;
                  });
                },
              ),
            ),
            ChoiceChip(
              label: const Text('Personalizzata'),
              selected: _isCustomQuantity,
              onSelected: (_) => setState(() => _isCustomQuantity = true),
            ),
          ],
        ),
        if (_isCustomQuantity) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('medicine-custom-quantity-field'),
            controller: _customQuantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Es. 1.5',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedUnit,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Unita (opzionale)',
            filled: true,
            fillColor: Colors.white,
          ),
          items: _unitOptions
              .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
              .toList(growable: false),
          onChanged: (unit) => setState(() => _selectedUnit = unit),
        ),
        if (_selectedUnit == 'Altro') ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('medicine-custom-unit-field'),
            controller: _customUnitController,
            decoration: const InputDecoration(
              hintText: 'Inserisci l\'unita',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          'Opzionale. Se interpretabile, viene usata per aggiornare la scorta.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _buildDose() {
    final quantity = _isCustomQuantity
        ? _customQuantityController.text.trim()
        : _selectedQuantity ?? '';
    final unit = _selectedUnit == 'Altro'
        ? _customUnitController.text.trim()
        : _selectedUnit ?? '';
    return [
      quantity.trim(),
      unit.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
  }

  Widget _buildScheduleGroupsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (_scheduleGroups.isNotEmpty)
            Column(
              children: List.generate(
                _scheduleGroups.length,
                (index) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: index < _scheduleGroups.length - 1
                        ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Programmazione ${index + 1}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Modifica programmazione',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editScheduleGroup(index),
                          ),
                          IconButton(
                            tooltip: 'Rimuovi programmazione',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() => _scheduleGroups.removeAt(index));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ScheduleSummaryLine(
                        icon: Icons.calendar_today_outlined,
                        label: _dayNames(_scheduleGroups[index].daysOfWeek),
                      ),
                      const SizedBox(height: 6),
                      _ScheduleSummaryLine(
                        icon: Icons.schedule,
                        label: _timeNames(
                          context,
                          _scheduleGroups[index].times,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nessuna programmazione',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addScheduleGroup,
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi programmazione'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fields = [
          _StockNumberField(
            label: 'Quantita iniziale',
            controller: _stockController,
            validator: _validatePositiveNumber,
          ),
          _StockNumberField(
            label: 'Soglia Avviso',
            controller: _warningController,
            validator: _validatePositiveNumber,
          ),
        ];

        if (constraints.maxWidth < 340) {
          return Column(
            children: [fields.first, const SizedBox(height: 16), fields.last],
          );
        }

        return Row(
          children: [
            Expanded(child: fields.first),
            const SizedBox(width: 16),
            Expanded(child: fields.last),
          ],
        );
      },
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colors
          .map(
            (color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _parseColor(color),
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedColor == color
                      ? Border.all(color: Colors.black, width: 3)
                      : Border.all(color: Colors.grey[300]!),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _closeKeyboardAndPop() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    Navigator.maybePop(context);
  }

  Future<void> _addScheduleGroup() async {
    final group = await _showScheduleGroupEditor();
    if (!mounted || group == null) return;
    setState(() => _scheduleGroups.add(group));
  }

  Future<void> _editScheduleGroup(int index) async {
    final group = await _showScheduleGroupEditor(_scheduleGroups[index]);
    if (!mounted || group == null) return;
    setState(() => _scheduleGroups[index] = group);
  }

  Future<_ScheduleFormGroup?> _showScheduleGroupEditor([
    _ScheduleFormGroup? initialGroup,
  ]) {
    return showModalBottomSheet<_ScheduleFormGroup>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _ScheduleGroupEditor(
        initialGroup: initialGroup,
        dayNames: _dayNames,
        timeNames: (times) => _timeNames(sheetContext, times),
      ),
    );
  }

  void _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    final schedules = _buildSchedules();
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aggiungi almeno una programmazione')),
      );
      return;
    }

    final therapyId = widget.therapy?.id ?? _selectedTherapyId;
    if (therapyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona una terapia prima di continuare'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<MedicineProvider>(context, listen: false);
      final medicine = widget.medicine;
      if (medicine == null) {
        await provider.addMedicineToTherapy(
          therapyId: therapyId,
          name: _nameController.text,
          dose: _buildDose(),
          times: _timesFromSchedules(schedules),
          daysOfWeek: _daysFromSchedules(schedules),
          schedules: schedules,
          stockQuantity: _parseQuantity(_stockController.text),
          stockWarningThreshold: _parseQuantity(_warningController.text),
          notes: _notesController.text,
          color: _selectedColor,
        );
      } else {
        await provider.updateMedicine(
          id: medicine.id,
          name: _nameController.text,
          dose: _buildDose(),
          times: _timesFromSchedules(schedules),
          daysOfWeek: _daysFromSchedules(schedules),
          schedules: schedules,
          stockQuantity: _parseQuantity(_stockController.text),
          stockWarningThreshold: _parseQuantity(_warningController.text),
          notes: _notesController.text,
          color: _selectedColor,
          icon: medicine.icon,
          isActive: medicine.isActive,
        );
      }

      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Medicina aggiornata con successo'
                  : 'Medicina aggiunta con successo',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePositiveNumber(String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return 'Inserisci un numero valido';
    }
    return null;
  }

  double _parseQuantity(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));

  List<MedicineSchedule> _buildSchedules() {
    final daysByTime = <String, Set<int>>{};
    final timeByKey = <String, TimeOfDay>{};

    for (final group in _scheduleGroups) {
      final days = _uniqueSortedDays(group.daysOfWeek);
      final times = _uniqueSortedTimes(group.times);
      if (days.isEmpty || times.isEmpty) continue;

      for (final time in times) {
        final key = '${time.hour}:${time.minute}';
        timeByKey[key] = time;
        daysByTime.putIfAbsent(key, () => <int>{}).addAll(days);
      }
    }

    final schedules = daysByTime.entries.map((entry) {
      return MedicineSchedule(
        time: timeByKey[entry.key]!,
        daysOfWeek: _uniqueSortedDays(entry.value),
      );
    }).toList();

    schedules.sort((first, second) {
      return _compareTimeOfDay(first.time, second.time);
    });
    return schedules;
  }

  List<_ScheduleFormGroup> _groupsFromSchedules(
    Iterable<MedicineSchedule> schedules,
  ) {
    final timesByDays = <String, List<TimeOfDay>>{};
    final daysByKey = <String, List<int>>{};

    for (final schedule in schedules) {
      if (!schedule.isActive) continue;
      final days = _uniqueSortedDays(schedule.daysOfWeek);
      if (days.isEmpty) continue;
      final key = days.join(',');
      daysByKey[key] = days;
      timesByDays.putIfAbsent(key, () => <TimeOfDay>[]).add(schedule.time);
    }

    final groups = timesByDays.entries.map((entry) {
      return _ScheduleFormGroup(
        daysOfWeek: daysByKey[entry.key]!,
        times: _uniqueSortedTimes(entry.value),
      );
    }).toList();

    groups.sort((first, second) {
      final firstDay = first.daysOfWeek.isEmpty ? 8 : first.daysOfWeek.first;
      final secondDay = second.daysOfWeek.isEmpty ? 8 : second.daysOfWeek.first;
      if (firstDay != secondDay) return firstDay.compareTo(secondDay);
      final firstTime = first.times.isEmpty
          ? const TimeOfDay(hour: 23, minute: 59)
          : first.times.first;
      final secondTime = second.times.isEmpty
          ? const TimeOfDay(hour: 23, minute: 59)
          : second.times.first;
      return _compareTimeOfDay(firstTime, secondTime);
    });
    return groups;
  }

  List<TimeOfDay> _timesFromSchedules(List<MedicineSchedule> schedules) {
    return _uniqueSortedTimes(schedules.map((schedule) => schedule.time));
  }

  List<int> _daysFromSchedules(List<MedicineSchedule> schedules) {
    return _uniqueSortedDays(
      schedules.expand((schedule) => schedule.daysOfWeek),
    );
  }

  List<int> _uniqueSortedDays(Iterable<int> days) {
    return days.toSet().where((day) => day >= 1 && day <= 7).toList()..sort();
  }

  List<TimeOfDay> _uniqueSortedTimes(Iterable<TimeOfDay> times) {
    final unique = <String, TimeOfDay>{};
    for (final time in times) {
      unique['${time.hour}:${time.minute}'] = time;
    }
    return unique.values.toList(growable: false)..sort(_compareTimeOfDay);
  }

  int _compareTimeOfDay(TimeOfDay first, TimeOfDay second) {
    final firstMinutes = first.hour * 60 + first.minute;
    final secondMinutes = second.hour * 60 + second.minute;
    return firstMinutes.compareTo(secondMinutes);
  }

  String _dayNames(List<int> days) {
    const names = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final safeDays = _uniqueSortedDays(days);
    if (safeDays.length == 7) return 'Tutti i giorni';
    return safeDays.map((day) => names[day - 1]).join(', ');
  }

  String _timeNames(BuildContext context, List<TimeOfDay> times) {
    return _uniqueSortedTimes(
      times,
    ).map((time) => time.format(context)).join(', ');
  }

  void _seedDose(String dose) {
    final trimmed = dose.trim();
    if (trimmed.isEmpty) return;

    final match = RegExp(
      r'^(\d+\s*/\s*\d+|\d+(?:[,.]\d+)?)(?:\s+(.+))?$',
    ).firstMatch(trimmed);
    if (match == null) {
      _isCustomQuantity = true;
      _customQuantityController.text = trimmed;
      return;
    }

    final quantity = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
    if (_quantityPresets.contains(quantity)) {
      _selectedQuantity = quantity;
      _isCustomQuantity = false;
    } else {
      _isCustomQuantity = true;
      _customQuantityController.text = quantity;
    }

    final unit = match.group(2)?.trim();
    if (unit == null || unit.isEmpty) return;
    if (_unitOptions.contains(unit) && unit != 'Altro') {
      _selectedUnit = unit;
    } else {
      _selectedUnit = 'Altro';
      _customUnitController.text = unit;
    }
  }

  Color _parseColor(String colorHex) {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

class _ScheduleFormGroup {
  final List<int> daysOfWeek;
  final List<TimeOfDay> times;

  const _ScheduleFormGroup({required this.daysOfWeek, required this.times});
}

class _ScheduleSummaryLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ScheduleSummaryLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label.isEmpty ? 'Non impostato' : label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleGroupEditor extends StatefulWidget {
  final _ScheduleFormGroup? initialGroup;
  final String Function(List<int> days) dayNames;
  final String Function(List<TimeOfDay> times) timeNames;

  const _ScheduleGroupEditor({
    required this.initialGroup,
    required this.dayNames,
    required this.timeNames,
  });

  @override
  State<_ScheduleGroupEditor> createState() => _ScheduleGroupEditorState();
}

class _ScheduleGroupEditorState extends State<_ScheduleGroupEditor> {
  late final List<int> _selectedDays;
  late final List<TimeOfDay> _times;

  @override
  void initState() {
    super.initState();
    _selectedDays = List<int>.from(widget.initialGroup?.daysOfWeek ?? const []);
    _times = List<TimeOfDay>.from(widget.initialGroup?.times ?? const []);
    _selectedDays.sort();
    _times.sort(_compareTimeOfDay);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialGroup == null
                    ? 'Aggiungi programmazione'
                    : 'Modifica programmazione',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Giorni',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom']
                    .asMap()
                    .entries
                    .map((entry) {
                      final day = entry.key + 1;
                      final selected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                            _selectedDays.sort();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFFE8F5E9),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 18),
              const Text(
                'Orari',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_times.isEmpty)
                Text(
                  'Nessun orario',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _times
                      .map(
                        (time) => InputChip(
                          label: Text(time.format(context)),
                          onDeleted: () => setState(() => _times.remove(time)),
                        ),
                      )
                      .toList(growable: false),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi orario'),
                ),
              ),
              const SizedBox(height: 18),
              _ScheduleSummaryLine(
                icon: Icons.fact_check_outlined,
                label:
                    '${widget.dayNames(_selectedDays)} - ${widget.timeNames(_times)}',
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Salva'),
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

  Future<void> _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || time == null) return;

    setState(() {
      final exists = _times.any(
        (item) => item.hour == time.hour && item.minute == time.minute,
      );
      if (!exists) {
        _times.add(time);
        _times.sort(_compareTimeOfDay);
      }
    });
  }

  void _save() {
    if (_selectedDays.isEmpty || _times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un giorno e un orario')),
      );
      return;
    }

    Navigator.pop(
      context,
      _ScheduleFormGroup(
        daysOfWeek: List<int>.from(_selectedDays)..sort(),
        times: List<TimeOfDay>.from(_times)..sort(_compareTimeOfDay),
      ),
    );
  }

  int _compareTimeOfDay(TimeOfDay first, TimeOfDay second) {
    final firstMinutes = first.hour * 60 + first.minute;
    final secondMinutes = second.hour * 60 + second.minute;
    return firstMinutes.compareTo(secondMinutes);
  }
}

class _SelectedTherapyField extends StatelessWidget {
  final Therapy therapy;

  const _SelectedTherapyField({required this.therapy});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(therapy.color);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(Icons.spa_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              therapy.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
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

class _ReadOnlyInfoField extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReadOnlyInfoField({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  const _StockNumberField({
    required this.label,
    required this.controller,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: label == 'Quantita iniziale'
              ? const ValueKey('medicine-stock-field')
              : const ValueKey('medicine-warning-threshold-field'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
