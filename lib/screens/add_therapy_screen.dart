import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../widgets/primary_button.dart';

class AddTherapyScreen extends StatefulWidget {
  final Therapy? therapy;

  const AddTherapyScreen({super.key, this.therapy});

  @override
  State<AddTherapyScreen> createState() => _AddTherapyScreenState();
}

class _AddTherapyScreenState extends State<AddTherapyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  final _colors = const [
    '#2E7D32',
    '#00897B',
    '#1976D2',
    '#7B1FA2',
    '#C62828',
    '#546E7A',
  ];
  final _icons = const [
    Icons.spa,
    Icons.favorite_outline,
    Icons.monitor_heart_outlined,
    Icons.medical_services_outlined,
  ];

  late String _selectedColor;
  late int _selectedIconCodePoint;
  DateTime? _startDate;
  bool _isSaving = false;

  bool get _isEditing => widget.therapy != null;

  @override
  void initState() {
    super.initState();
    final therapy = widget.therapy;
    _nameController = TextEditingController(text: therapy?.name ?? '');
    _descriptionController = TextEditingController(
      text: therapy?.description ?? '',
    );
    _selectedColor = therapy?.color ?? _colors.first;
    _selectedIconCodePoint = therapy?.iconCodePoint ?? Icons.spa.codePoint;
    _startDate = therapy?.startDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Terapia' : 'Crea Terapia'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(text: 'Nome terapia *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Es. Terapia Vasculite',
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Inserisci il nome della terapia'
                      : null,
                ),
                const SizedBox(height: 20),
                _Label(text: 'Descrizione'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Es. Indicazioni o obiettivo della terapia',
                  ),
                ),
                const SizedBox(height: 20),
                _Label(text: 'Colore'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colors.map(_buildColorChoice).toList(),
                ),
                const SizedBox(height: 20),
                _Label(text: 'Icona'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _icons.map(_buildIconChoice).toList(),
                ),
                const SizedBox(height: 20),
                _Label(text: 'Data inizio'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_formatDate(_startDate)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _isEditing ? 'Salva Terapia' : 'Crea Terapia',
                    icon: _isEditing ? Icons.save_outlined : Icons.add,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorChoice(String colorHex) {
    final color = _parseColor(colorHex);
    final selected = _selectedColor == colorHex;

    return Tooltip(
      message: colorHex,
      child: InkWell(
        onTap: () => setState(() => _selectedColor = colorHex),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF1E1E1E) : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      ),
    );
  }

  Widget _buildIconChoice(IconData icon) {
    final selected = _selectedIconCodePoint == icon.codePoint;

    return Tooltip(
      message: 'Icona terapia',
      child: IconButton.filledTonal(
        onPressed: () =>
            setState(() => _selectedIconCodePoint = icon.codePoint),
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? _parseColor(_selectedColor).withValues(alpha: 0.18)
              : Colors.white,
          foregroundColor: selected
              ? _parseColor(_selectedColor)
              : const Color(0xFF546E7A),
          side: BorderSide(
            color: selected
                ? _parseColor(_selectedColor)
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _startDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<MedicineProvider>();
      if (_isEditing) {
        await provider.updateTherapy(
          widget.therapy!.copyWith(
            name: _nameController.text,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            color: _selectedColor,
            iconCodePoint: _selectedIconCodePoint,
            startDate: _startDate,
          ),
        );
      } else {
        await provider.createTherapy(
          name: _nameController.text,
          description: _descriptionController.text,
          color: _selectedColor,
          iconCodePoint: _selectedIconCodePoint,
          startDate: _startDate,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleziona data';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _parseColor(String colorHex) {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1E1E1E),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
