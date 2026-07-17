import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/color_parser.dart';
import '../utils/schedule_grouping.dart';
import '../utils/weekday_labels.dart';
import '../widgets/form_section_card.dart';
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

  final List<ScheduleDisplayGroup> _scheduleGroups = [];
  String? _selectedTherapyId;
  String? _selectedQuantity;
  String? _selectedUnit;
  bool _isCustomQuantity = false;
  String _selectedColor = '#1E6B5A';
  bool _isLoading = false;

  bool get _isEditing => widget.medicine != null;

  final List<String> _colors = [
    '#1E6B5A',
    '#4CAF50',
    '#00796B',
    '#607D8B',
    '#7A70C9',
    '#B4711E',
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
      // Helper condiviso di sola presentazione (docs/UI_FINAL_MOCKUP_REFERENCE):
      // stessa logica usata dal dettaglio medicina, mai divergente.
      _scheduleGroups.addAll(ScheduleGrouping.groupsFor(medicine));
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeKeyboardAndPop,
        ),
        title: Text(_isEditing ? 'Modifica medicina' : 'Aggiungi medicina'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormSectionCard(
                        icon: Icons.health_and_safety_outlined,
                        title: 'Terapia associata',
                        child: _buildTherapyField(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FormSectionCard(
                        icon: Icons.edit_note_outlined,
                        title: 'Dati principali',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Nome medicina *'),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              key: const ValueKey('medicine-name-field'),
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Es. Tachipirina',
                              ),
                              validator: (value) =>
                                  value?.trim().isEmpty ?? true
                                  ? 'Inserisci il nome'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FormSectionCard(
                        icon: Icons.science_outlined,
                        title: 'Dose opzionale',
                        child: _buildDoseFields(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FormSectionCard(
                        icon: Icons.calendar_month_outlined,
                        title: 'Programmazione *',
                        child: _buildScheduleGroupsSection(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FormSectionCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'Scorte',
                        child: _buildStockFields(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FormSectionCard(
                        icon: Icons.palette_outlined,
                        title: 'Colore',
                        child: _buildColorPicker(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FormSectionCard(
                        icon: Icons.note_alt_outlined,
                        title: 'Note',
                        child: TextFormField(
                          key: const ValueKey('medicine-notes-field'),
                          controller: _notesController,
                          decoration: const InputDecoration(
                            hintText: 'Es. Prendere dopo i pasti',
                          ),
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: _isEditing
                              ? 'Salva modifiche'
                              : 'Aggiungi medicina',
                          icon: _isEditing ? Icons.save_outlined : Icons.add,
                          isLoading: _isLoading,
                          onPressed: _saveMedicine,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: SecondaryButton(
                          label: 'Annulla',
                          onPressed: _closeKeyboardAndPop,
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
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.inkSoft,
      ),
    );
  }

  Widget _buildTherapyField() {
    if (widget.therapy == null && !_isEditing) {
      return Consumer<MedicineProvider>(
        builder: (context, provider, _) => DropdownButtonFormField<String>(
          initialValue: _selectedTherapyId,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Seleziona una terapia'),
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
    if (widget.therapy != null) {
      return _InfoField(
        icon: Icons.spa_outlined,
        text: widget.therapy!.name,
        tinted: true,
        color: parseHexColor(widget.therapy!.color),
      );
    }
    return const _InfoField(
      icon: Icons.spa_outlined,
      text: 'Terapia non disponibile',
    );
  }

  Widget _buildDoseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
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
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const ValueKey('medicine-custom-quantity-field'),
            controller: _customQuantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Es. 1.5'),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedUnit,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Unita (opzionale)'),
          items: _unitOptions
              .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
              .toList(growable: false),
          onChanged: (unit) => setState(() => _selectedUnit = unit),
        ),
        if (_selectedUnit == 'Altro') ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const ValueKey('medicine-custom-unit-field'),
            controller: _customUnitController,
            decoration: const InputDecoration(hintText: 'Inserisci l\'unita'),
          ),
        ],
        const SizedBox(height: 6),
        const Text(
          'Opzionale. Se interpretabile, viene usata per aggiornare la scorta.',
          style: TextStyle(fontSize: 12, color: AppColors.inkFaint),
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
    if (_scheduleGroups.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nessuna programmazione. Aggiungine una per continuare.',
            style: TextStyle(color: AppColors.inkFaint, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Aggiungi programmazione',
              icon: Icons.add,
              onPressed: _addScheduleGroup,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _scheduleGroups.length; i++) ...[
          _ScheduleGroupRow(
            index: i,
            group: _scheduleGroups[i],
            onEdit: () => _editScheduleGroup(i),
            onDelete: () => setState(() => _scheduleGroups.removeAt(i)),
          ),
          if (i < _scheduleGroups.length - 1)
            Divider(
              height: AppSpacing.lg,
              color: AppColors.border.withValues(alpha: 0.7),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: SecondaryButton(
            label: 'Aggiungi programmazione',
            icon: Icons.add,
            onPressed: _addScheduleGroup,
          ),
        ),
      ],
    );
  }

  Widget _buildStockFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fields = [
          _StockNumberField(
            label: 'Quantita iniziale',
            fieldKey: const ValueKey('medicine-stock-field'),
            controller: _stockController,
            validator: _validatePositiveNumber,
          ),
          _StockNumberField(
            label: 'Soglia avviso',
            fieldKey: const ValueKey('medicine-warning-threshold-field'),
            controller: _warningController,
            validator: _validatePositiveNumber,
          ),
        ];

        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              fields.first,
              const SizedBox(height: AppSpacing.md),
              fields.last,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: fields.first),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: fields.last),
          ],
        );
      },
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: _colors
          .map(
            (color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: parseHexColor(color),
                  shape: BoxShape.circle,
                  border: _selectedColor == color
                      ? Border.all(color: AppColors.ink, width: 3)
                      : null,
                ),
                child: _selectedColor == color
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
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

  Future<ScheduleDisplayGroup?> _showScheduleGroupEditor([
    ScheduleDisplayGroup? initialGroup,
  ]) {
    return showModalBottomSheet<ScheduleDisplayGroup>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _ScheduleGroupEditor(initialGroup: initialGroup),
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

  /// Converte i gruppi editati dall'utente (giorni+orari scelti insieme,
  /// intenzionalmente) in schedule atomici reali da salvare. A parita' di
  /// orario tra gruppi diversi unisce i giorni (dedup equivalente, non un
  /// prodotto cartesiano): resta operativo, non spostato nell'helper di
  /// sola presentazione.
  List<MedicineSchedule> _buildSchedules() {
    final daysByTime = <String, Set<int>>{};
    final timeByKey = <String, TimeOfDay>{};

    for (final group in _scheduleGroups) {
      final days = ScheduleGrouping.uniqueSortedDays(group.daysOfWeek);
      final times = ScheduleGrouping.uniqueSortedTimes(group.times);
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
        daysOfWeek: ScheduleGrouping.uniqueSortedDays(entry.value),
      );
    }).toList();

    schedules.sort(
      (first, second) =>
          ScheduleGrouping.compareTimeOfDay(first.time, second.time),
    );
    return schedules;
  }

  List<TimeOfDay> _timesFromSchedules(List<MedicineSchedule> schedules) {
    return ScheduleGrouping.uniqueSortedTimes(
      schedules.map((schedule) => schedule.time),
    );
  }

  List<int> _daysFromSchedules(List<MedicineSchedule> schedules) {
    return ScheduleGrouping.uniqueSortedDays(
      schedules.expand((schedule) => schedule.daysOfWeek),
    );
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
}

class _ScheduleGroupRow extends StatelessWidget {
  final int index;
  final ScheduleDisplayGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleGroupRow({
    required this.index,
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Programmazione ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Modifica programmazione',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Rimuovi programmazione',
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.critical,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final day in group.daysOfWeek)
              _SchedulePill(
                label: kWeekdayShortLabels[day - 1],
                emphasized: true,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final time in group.times)
              _SchedulePill(label: time.format(context)),
          ],
        ),
      ],
    );
  }
}

class _SchedulePill extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _SchedulePill({required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primaryTint
            : AppColors.border.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: emphasized ? AppColors.primary800 : AppColors.inkSoft,
        ),
      ),
    );
  }
}

class _ScheduleGroupEditor extends StatefulWidget {
  final ScheduleDisplayGroup? initialGroup;

  const _ScheduleGroupEditor({required this.initialGroup});

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
    _times.sort(ScheduleGrouping.compareTimeOfDay);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
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
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Giorni',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _WeekdayToggleRow(
                selectedDays: _selectedDays,
                onToggle: (day) => setState(() {
                  if (_selectedDays.contains(day)) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                  _selectedDays.sort();
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Orari',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_times.isEmpty)
                const Text(
                  'Nessun orario',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _times
                      .map(
                        (time) => InputChip(
                          label: Text(time.format(context)),
                          onDeleted: () => setState(() => _times.remove(time)),
                        ),
                      )
                      .toList(growable: false),
                ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'Aggiungi orario',
                  icon: Icons.add,
                  onPressed: _addTime,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.primary700,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Puoi creare più programmazioni per gestire giorni e orari diversi.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primary800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Annulla',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(label: 'Salva', onPressed: _save),
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
        _times.sort(ScheduleGrouping.compareTimeOfDay);
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
      ScheduleDisplayGroup(
        daysOfWeek: List<int>.from(_selectedDays)..sort(),
        times: List<TimeOfDay>.from(_times)
          ..sort(ScheduleGrouping.compareTimeOfDay),
      ),
    );
  }
}

class _WeekdayToggleRow extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<int> onToggle;

  const _WeekdayToggleRow({required this.selectedDays, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = selectedDays.contains(day);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Semantics(
              button: true,
              selected: selected,
              label: kWeekdayShortLabels[i],
              child: InkWell(
                onTap: () => onToggle(day),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary700 : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: selected ? AppColors.primary700 : AppColors.border,
                    ),
                  ),
                  child: Text(
                    kWeekdayShortLabels[i][0],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: selected ? Colors.white : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool tinted;
  final Color? color;

  const _InfoField({
    required this.icon,
    required this.text,
    this.tinted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = tinted
        ? (color ?? AppColors.primary700)
        : AppColors.inkFaint;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: tinted
            ? effectiveColor.withValues(alpha: 0.1)
            : AppColors.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: tinted
            ? Border.all(color: effectiveColor.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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

class _StockNumberField extends StatelessWidget {
  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  const _StockNumberField({
    required this.label,
    required this.fieldKey,
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator,
        ),
      ],
    );
  }
}
