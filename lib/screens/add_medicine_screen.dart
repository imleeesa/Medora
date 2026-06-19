import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../widgets/primary_button.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _therapyController = TextEditingController();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();
  final _stockController = TextEditingController(text: '30');
  final _warningController = TextEditingController(text: '5');

  final List<TimeOfDay> _times = [];
  final List<int> _daysOfWeek = [];
  String _selectedColor = '#2E7D32';
  bool _isLoading = false;

  final List<String> _colors = [
    '#2E7D32', // Verde
    '#4CAF50', // Verde chiaro
    '#00796B', // Teal medicale
    '#607D8B', // Grigio tecnico
    '#8BC34A', // Verde lime soft
    '#9E9E9E', // Neutro
  ];

  @override
  void dispose() {
    _therapyController.dispose();
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    _stockController.dispose();
    _warningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Aggiungi Medicina'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terapia *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _therapyController,
                decoration: InputDecoration(
                  hintText: 'Es. Terapia Vasculite',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Inserisci la terapia'
                    : null,
              ),
              const SizedBox(height: 20),

              // Nome
              const Text(
                'Nome Medicina *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Es. Tachipirina',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Inserisci il nome' : null,
              ),
              const SizedBox(height: 20),

              // Dosaggio
              const Text(
                'Dosaggio *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _doseController,
                decoration: InputDecoration(
                  hintText: 'Es. 500mg',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Inserisci il dosaggio' : null,
              ),
              const SizedBox(height: 20),

              // Orari
              const Text(
                'Orari di Assunzione *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                                  ? Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    )
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
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
              ),
              const SizedBox(height: 20),

              // Giorni della settimana
              const Text(
                'Giorni della Settimana *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom']
                    .asMap()
                    .entries
                    .map((e) {
                      final index = e.key;
                      final day = e.value;
                      final dayNum = index + 1;

                      return FilterChip(
                        label: Text(day),
                        selected: _daysOfWeek.contains(dayNum),
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
                          color: _daysOfWeek.contains(dayNum)
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[300]!,
                        ),
                        labelStyle: TextStyle(
                          color: _daysOfWeek.contains(dayNum)
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Stock
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quantita iniziale',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: _validatePositiveNumber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Soglia Avviso',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _warningController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: _validatePositiveNumber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Colore
              const Text(
                'Colore',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
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
              ),
              const SizedBox(height: 20),

              // Note
              const Text(
                'Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Es. Prendere dopo i pasti',
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Bottoni
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aggiunge un orario
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

  /// Salva la medicina
  void _addMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty || _daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona orari e giorni')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<MedicineProvider>(context, listen: false).addMedicine(
        therapyName: _therapyController.text,
        name: _nameController.text,
        dose: _doseController.text,
        times: _times,
        daysOfWeek: _daysOfWeek,
        stockQuantity: int.parse(_stockController.text),
        stockWarningThreshold: int.parse(_warningController.text),
        notes: _notesController.text,
        color: _selectedColor,
      );

      if (mounted) {
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

  /// Converte codice colore hex a Color
  Color _parseColor(String colorHex) {
    colorHex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$colorHex', radix: 16));
  }
}
