import 'package:flutter/material.dart';

import '../models/therapy.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/color_parser.dart';
import '../utils/therapy_icons.dart';
import 'app_card.dart';
import 'status_chip.dart';

/// Card terapia (mockup 07): cerchio icona nel colore terapia, nome,
/// descrizione, chip "N medicine" tinta + chip stato, chevron.
/// Le archiviate sono attenuate ma leggibili.
class TherapyCard extends StatelessWidget {
  final Therapy therapy;
  final VoidCallback onTap;

  const TherapyCard({super.key, required this.therapy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(therapy.color);
    final isActive = therapy.isActive;
    final iconTint = isActive
        ? color.withValues(alpha: 0.14)
        : AppColors.border.withValues(alpha: 0.6);
    final iconColor = isActive ? color : AppColors.inkFaint;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconTint, shape: BoxShape.circle),
            child: Icon(
              therapyIconForCodePoint(therapy.iconCodePoint),
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        therapy.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(
                      label: isActive ? 'Attiva' : 'Archiviata',
                      tone: isActive ? StatusTone.positive : StatusTone.neutral,
                    ),
                  ],
                ),
                if (therapy.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 3),
                  Text(
                    therapy.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _MedicineCountChip(
                      count: therapy.medicines.length,
                      color: isActive ? color : AppColors.inkFaint,
                      tint: iconTint,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.inkFaint,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCountChip extends StatelessWidget {
  final int count;
  final Color color;
  final Color tint;

  const _MedicineCountChip({
    required this.count,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 medicina' : '$count medicine';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
