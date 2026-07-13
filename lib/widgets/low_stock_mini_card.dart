import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Riga "scorta bassa" della Dashboard: informativa e non allarmista
/// (tono ottone, non rosso/arancio da alert).
class LowStockMiniCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const LowStockMiniCard({
    super.key,
    required this.medicine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.goldTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.gold,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                medicine.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Scorta bassa',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppColors.inkFaint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
