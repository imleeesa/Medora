import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Bottom navigation "Calm Precision": barra pill flottante con 4 tab e
/// pulsante centrale sollevato. Nessun CustomClipper/incavo (Opzione A della
/// direzione UI): il bottone centrale si sovrappone alla barra solo per
/// posizione (Stack + Positioned), per restare stabile su ogni dispositivo.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onQuickAction;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onQuickAction,
  });

  static const _tabs = [
    _NavTab(Icons.home_outlined, Icons.home, 'Home'),
    _NavTab(Icons.spa_outlined, Icons.spa, 'Terapie'),
    _NavTab(Icons.history_outlined, Icons.history, 'Storico'),
    _NavTab(Icons.person_outline, Icons.person, 'Profilo'),
  ];

  static const double _barHeight = 58;
  static const double _buttonSize = 54;

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _barHeight + _buttonSize / 2 + bottomSafeArea,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          _NavBarShell(
            tabs: _tabs,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            bottomSafeArea: bottomSafeArea,
          ),
          Positioned(top: 0, child: _CenterActionButton(onTap: onQuickAction)),
        ],
      ),
    );
  }
}

class _NavBarShell extends StatelessWidget {
  final List<_NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double bottomSafeArea;

  const _NavBarShell({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.bottomSafeArea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: bottomSafeArea),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: AppBottomNavBar._barHeight,
        child: Row(
          children: [
            _tabGroup(tabs.sublist(0, 2), startIndex: 0),
            const SizedBox(width: AppBottomNavBar._buttonSize + AppSpacing.sm),
            _tabGroup(tabs.sublist(2, 4), startIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _tabGroup(List<_NavTab> group, {required int startIndex}) {
    return Expanded(
      child: Row(
        children: List.generate(group.length, (i) {
          final index = startIndex + i;
          return Expanded(
            child: _NavTabButton(
              tab: group[i],
              isSelected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
          );
        }),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  final _NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary700 : AppColors.inkFaint;

    return Semantics(
      selected: isSelected,
      button: true,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Azioni rapide',
      child: Container(
        width: AppBottomNavBar._buttonSize,
        height: AppBottomNavBar._buttonSize,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const Icon(Icons.add, color: AppColors.primary700, size: 26),
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
