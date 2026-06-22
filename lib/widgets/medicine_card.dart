import 'package:flutter/material.dart';
import '../models/medicine.dart';

/// Card moderna per una medicina
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
    this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final nextIntake = medicine.getNextIntake();
    final hasWarning = medicine.stockQuantity <= medicine.stockWarningThreshold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Nome e stato
                  Row(
                    children: [
                      // Colore indicatore
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(medicine.color),
                          borderRadius: BorderRadius.circular(2),
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
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E1E),
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medicine.doseLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: medicine.isActive,
                          onChanged: (_) => onToggle?.call(),
                          activeColor: const Color(0xFF2E7D32),
                          activeTrackColor: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      if (onDelete != null)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'delete') onDelete?.call();
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline),
                                  SizedBox(width: 8),
                                  Text('Elimina'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Prossima assunzione
                  if (nextIntake != null && medicine.shouldTakeToday())
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Prossima: ${nextIntake.format(context)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nessuna assunzione oggi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Stock
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: hasWarning ? Colors.orange : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Stock: ${medicine.stockQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: hasWarning ? Colors.orange : Colors.grey[600],
                        ),
                      ),
                      if (hasWarning) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Basso',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Orari
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Orari: ${medicine.times.map((t) => t.format(context)).join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Converte codice colore hex a Color
  Color _parseColor(String colorHex) {
    colorHex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$colorHex', radix: 16));
  }
}
