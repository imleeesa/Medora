import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../widgets/primary_button.dart';

class AddMedicineScreen extends StatefulWidget {
  final Therapy? therapy;

  const AddMedicineScreen({super.key, this.therapy});

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

  final List<TimeOfDay> _times = [];
  final List<int> _daysOfWeek = [];
  String? _selectedTherapyId;
  String? _selectedQuantity;
  String? _selectedUnit;
  bool _isCustomQuantity = false;
  String _selectedColor = '#2E7D32';
  bool _isLoading = false;

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
    final therapy = widget.therapy;
    if (therapy != null) {
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
        title: const Text('Aggiungi Medicina'),
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
                      if (widget.therapy == null) ...[
                        _buildLabel('Terapia *'),
                        const SizedBox(height: 8),
                        _buildTherapySelector(),
                      ] else ...[
                        _buildLabel('Terapia'),
                        const SizedBox(height: 8),
                        _SelectedTherapyField(therapy: widget.therapy!),
                      ],
                      const SizedBox(height: 20),
                      _buildLabel('Nome Medicina *'),
                      const SizedBox(height: 8),
                      TextFormField(
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
                      _buildLabel('Orari di Assunzione *'),
                      const SizedBox(height: 8),
                      _buildTimesSection(),
                      const SizedBox(height: 20),
                      _buildLabel('Giorni della Settimana *'),
                      const SizedBox(height: 8),
                      _buildWeekdayChips(),
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
                          label: 'Aggiungi Medicina',
                          icon: Icons.add,
                          isLoading: _isLoading,
                          onPressed: _addMedicine,
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
          'Opzionale. La quantita per assunzione non modifica la scorta.',
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

  Widget _buildTimesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (_times.isNotEmpty)
            Column(
              children: List.generate(
                _times.length,
                (index) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: index < _times.length - 1
                        ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _times[index].format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() => _times.removeAt(index));
                        },
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
                'Nessun orario',
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
                onPressed: _addTime,
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi Orario'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom']
          .asMap()
          .entries
          .map((entry) {
            final dayNum = entry.key + 1;
            final isSelected = _daysOfWeek.contains(dayNum);

            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _daysOfWeek.add(dayNum);
                  } else {
                    _daysOfWeek.remove(dayNum);
                  }
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFE8F5E9),
              side: BorderSide(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
              ),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            );
          })
          .toList(),
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

  void _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    if (time != null) {
      setState(() {
        _times.add(time);
        _times.sort(
          (a, b) => a.hour * 60 + a.minute > b.hour * 60 + b.minute ? 1 : -1,
        );
      });
    }
  }

  void _addMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty || _daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona orari e giorni')));
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
      await provider.addMedicineToTherapy(
        therapyId: therapyId,
        name: _nameController.text,
        dose: _buildDose(),
        times: _times,
        daysOfWeek: _daysOfWeek,
        stockQuantity: int.parse(_stockController.text),
        stockWarningThreshold: int.parse(_warningController.text),
        notes: _notesController.text,
        color: _selectedColor,
      );

      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicina aggiunta con successo'),
            duration: Duration(seconds: 2),
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
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 0) {
      return 'Inserisci un numero valido';
    }
    return null;
  }

  Color _parseColor(String colorHex) {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
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
          controller: controller,
          keyboardType: TextInputType.number,
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
