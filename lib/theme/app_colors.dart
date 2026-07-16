import 'package:flutter/material.dart';

/// Design tokens colore - direzione finale "Medora Soft Clinical"
/// (evoluzione di Calm Precision basata sui mockup in docs/ui_mockup_reference).
/// Vedi docs/UI_FINAL_MOCKUP_REFERENCE.md per la specifica completa.
class AppColors {
  AppColors._();

  static const Color primary700 = Color(0xFF1E6B5A);
  static const Color primary800 = Color(0xFF124C3E);
  static const Color primaryTint = Color(0xFFE6F2EC);
  static const Color mint = Color(0xFFA8DCC6);

  /// Avvisi non critici (scorte basse, dose saltata): ambra calda.
  static const Color warning = Color(0xFFB4711E);
  static const Color warningTint = Color(0xFFFBF1DC);

  /// Alias legacy della coppia warning (era l'accento "ottone" di Calm
  /// Precision). Mantenuti per compatibilita' con i widget esistenti.
  static const Color gold = warning;
  static const Color goldTint = warningTint;

  /// Accento decorativo lavanda dei mockup (mai semantico).
  static const Color lavender = Color(0xFF7A70C9);
  static const Color lavenderTint = Color(0xFFECEAF9);

  static const Color ink = Color(0xFF24313F);
  static const Color inkSoft = Color(0xFF4A5568);
  static const Color inkFaint = Color(0xFF94A0AC);

  static const Color background = Color(0xFFFCFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE6E8EB);

  static const Color critical = Color(0xFFB14834);
  static const Color criticalTint = Color(0xFFF9E7E1);
  static const Color info = Color(0xFF4C6B85);
  static const Color infoTint = Color(0xFFE7EEF3);
}
