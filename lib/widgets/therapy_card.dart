import 'package:flutter/material.dart';

import '../models/therapy.dart';

class TherapyCard extends StatelessWidget {
  final Therapy therapy;
  final VoidCallback onTap;

  const TherapyCard({super.key, required this.therapy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(therapy.color);
    final statusLabel = therapy.isActive ? 'Attiva' : 'Archiviata';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(
                    therapy.iconCodePoint ?? Icons.spa.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      therapy.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (therapy.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 3),
                      Text(
                        therapy.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _TherapyMeta(
                          icon: Icons.medication_outlined,
                          label: '${therapy.medicines.length} medicine',
                        ),
                        _TherapyStatus(label: statusLabel, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorHex) {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

class _TherapyMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TherapyMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TherapyStatus extends StatelessWidget {
  final String label;
  final Color color;

  const _TherapyStatus({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
