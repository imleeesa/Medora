/// Design tokens spacing/radius - direzione "Calm Precision".
/// Vedi docs/UI_DESIGN_SYSTEM.md per la specifica completa.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadius {
  AppRadius._();

  /// Input, chip quadrati, tile icona.
  static const double sm = 12;

  /// Card standard - unico raggio per tutte le card dell'app.
  static const double md = 20;

  /// Hero card, sheet, dialog.
  static const double lg = 24;

  /// Bottoni e chip a pillola (mockup finali: CTA sempre pill).
  static const double pill = 999;
}
