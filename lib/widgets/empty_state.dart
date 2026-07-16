import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'medora_3d_asset.dart';
import 'primary_button.dart';

/// Widget per mostrare uno stato vuoto. Puo' usare un'icona Material nel
/// classico cerchio tinta oppure, se `imageAsset` e' valorizzato, un asset
/// 3D Medora (decorativo, escluso dalla semantica: il messaggio resta
/// affidato a titolo e descrizione).
class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? imageAsset;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.imageAsset,
    this.buttonLabel,
    this.onButtonPressed,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Medora3DAsset(imageAsset!, size: 160)
            else
              Container(
                width: iconSize + 20,
                height: iconSize + 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(iconSize / 2 + 10),
                ),
                child: Icon(icon, size: iconSize, color: AppColors.primary700),
              ),
            const SizedBox(height: 24),

            // Titolo
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),

            // Descrizione
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.inkSoft,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 32),

            // Bottone
            if (buttonLabel != null && onButtonPressed != null)
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: buttonLabel!,
                  onPressed: onButtonPressed!,
                  icon: Icons.add,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
