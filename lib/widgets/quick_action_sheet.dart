import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Voce del quick action sheet aperto dal pulsante centrale della navbar.
/// Ogni azione deve limitarsi a navigare verso un flusso gia' esistente:
/// il sheet non contiene logica di dominio.
class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Apre il bottom sheet "Calm Precision" con le azioni rapide passate.
Future<void> showQuickActionSheet(
  BuildContext context,
  List<QuickAction> actions,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _QuickActionSheet(actions: actions),
  );
}

class _QuickActionSheet extends StatelessWidget {
  final List<QuickAction> actions;

  const _QuickActionSheet({required this.actions});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final action in actions) _QuickActionTile(action: action),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () {
        Navigator.of(context).pop();
        action.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(action.icon, color: AppColors.primary700, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                action.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
