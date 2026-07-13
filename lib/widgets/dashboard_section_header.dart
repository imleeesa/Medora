import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Intestazione di sezione della Dashboard "Calm Precision".
/// Sostituisce la vecchia `_SectionTitle` locale con un componente condiviso.
class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const DashboardSectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
