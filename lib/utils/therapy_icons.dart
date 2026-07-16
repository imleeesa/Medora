import 'package:flutter/material.dart';

/// Icone disponibili per una terapia. Elenco unico e costante, usato sia dal
/// selettore in `AddTherapyScreen` sia per risolvere l'icona salvata in
/// `Therapy.iconCodePoint` in sola lettura. Tenerlo come lista di `IconData`
/// costanti (mai `IconData(codePoint)` dinamico) e' necessario perche' il
/// tree-shaking dei font icona di Flutter richiede riferimenti costanti:
/// un `IconData` costruito da un intero a runtime puo' rendere glifi errati
/// (icone/ideogrammi non corrispondenti) nelle build reali.
const List<IconData> kTherapyIconChoices = [
  Icons.spa,
  Icons.favorite_outline,
  Icons.monitor_heart_outlined,
  Icons.medical_services_outlined,
];

/// Risolve il codePoint salvato in `Therapy.iconCodePoint` verso una delle
/// icone costanti di [kTherapyIconChoices]. Fallback su `Icons.spa` se il
/// codePoint non corrisponde a nessuna icona nota (es. dato legacy).
IconData therapyIconForCodePoint(int? codePoint) {
  for (final icon in kTherapyIconChoices) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.spa;
}
