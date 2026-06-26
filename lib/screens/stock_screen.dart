import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/medicine_provider.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(title: const Text('Scorte')),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final medicines = provider.medicines;

          if (medicines.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nessuna scorta da monitorare',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: medicines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return _StockCard(key: ValueKey(medicine.id), medicine: medicine);
            },
          );
        },
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final Medicine medicine;

  const _StockCard({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final isLow = medicine.stockQuantity <= medicine.stockWarningThreshold;
    final progress = medicine.stockWarningThreshold == 0
        ? 1.0
        : (medicine.stockQuantity / (medicine.stockWarningThreshold * 3))
              .clamp(0.0, 1.0)
              .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isLow
                    ? Colors.orange.shade50
                    : const Color(0xFFE8F5E9),
                child: Icon(
                  isLow ? Icons.warning_amber_rounded : Icons.inventory_2,
                  color: isLow
                      ? Colors.orange.shade700
                      : const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isLow
                          ? 'Restano solo ${Medicine.formatQuantity(medicine.stockQuantity)} unita'
                          : '${Medicine.formatQuantity(medicine.stockQuantity)} unita disponibili',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLow
                            ? Colors.orange.shade800
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Ricarica scorta',
                onPressed: () => _showRestockDialog(context, medicine),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLow ? Colors.orange.shade600 : const Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Soglia minima: ${Medicine.formatQuantity(medicine.stockWarningThreshold)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestockDialog(
    BuildContext context,
    Medicine medicine,
  ) async {
    final provider = context.read<MedicineProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final quantity = await showDialog<double>(
        context: context,
        builder: (_) => const _RestockDialog(),
      );

      if (quantity == null) return;

      await provider.addStock(medicineId: medicine.id, quantity: quantity);
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Scorta aggiornata di ${Medicine.formatQuantity(quantity)} unita',
          ),
        ),
      );
    } catch (_) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossibile ricaricare la scorta.')),
      );
    }
  }
}

class _RestockDialog extends StatefulWidget {
  const _RestockDialog();

  @override
  State<_RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<_RestockDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final quantity = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (quantity == null || quantity <= 0) {
      setState(() => _errorMessage = 'Inserisci una quantita maggiore di zero');
      return;
    }

    Navigator.pop(context, quantity);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ricarica scorta'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Quantita da aggiungere',
          hintText: 'Es. 10 o 2.5',
          errorText: _errorMessage,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Aggiungi')),
      ],
    );
  }
}
