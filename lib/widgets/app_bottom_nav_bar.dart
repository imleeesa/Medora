import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Bottom navigation "Calm Precision": barra Material 3 standard, 4 tab,
/// nessun bottone centrale sospeso. Scelta deliberata: un `NavigationBar`
/// nativo e' piu' stabile, piu' leggibile e piu' coerente con un'app
/// medical-tech seria di una forma custom "particolare a tutti i costi".
/// Le azioni rapide (quick action sheet) sono ora raggiungibili dall'header
/// della Dashboard, non da questa barra.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _tabs = [
    _NavTab(Icons.home_outlined, Icons.home, 'Home'),
    _NavTab(Icons.spa_outlined, Icons.spa, 'Terapie'),
    _NavTab(Icons.history_outlined, Icons.history, 'Storico'),
    _NavTab(Icons.person_outline, Icons.person, 'Profilo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: AppColors.ink.withValues(alpha: 0.10),
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.primaryTint,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            height: 64,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.primary800 : AppColors.inkFaint,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 22,
                color: selected ? AppColors.primary700 : AppColors.inkFaint,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: [
              for (final tab in _tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.activeIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavTab(this.icon, this.activeIcon, this.label);
}
