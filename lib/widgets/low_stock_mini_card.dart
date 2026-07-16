import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Riga "scorta bassa" da usare dentro la card ambra della Dashboard
/// (mockup 04/22): informativa e non allarmista, mostra le unita' residue.
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
    final remaining = Medicine.formatQuantity(medicine.stockQuantity);

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
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppColors.warning,
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
            Text(
              '$remaining rimaste',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 2),
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
