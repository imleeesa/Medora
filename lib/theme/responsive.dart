import 'package:flutter/widgets.dart';

/// Breakpoint responsive unico del design system (vedi docs/UI_DESIGN_SYSTEM.md).
/// Utility di sola lettura, non ancora cablata in nessuna schermata:
/// da adottare progressivamente al posto delle soglie ad-hoc esistenti.
const double kNarrowScreenBreakpoint = 340;

extension ResponsiveContext on BuildContext {
  /// True su schermi stretti (es. Samsung Z Flip, ~280-320px).
  bool get isNarrowScreen =>
      MediaQuery.sizeOf(this).width < kNarrowScreenBreakpoint;
}
