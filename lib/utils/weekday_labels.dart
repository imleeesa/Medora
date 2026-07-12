/// Etichette brevi dei giorni della settimana (Lun-Dom), condivise per
/// sostituire gli array locali duplicati in piu' schermate. Indice 0 = Lunedi,
/// coerente con `DateTime.weekday` (1=Lun...7=Dom) tramite `weekdayShortLabel`.
/// Non ancora cablata: adozione progressiva sprint per sprint.
const List<String> kWeekdayShortLabels = [
  'Lun',
  'Mar',
  'Mer',
  'Gio',
  'Ven',
  'Sab',
  'Dom',
];

/// Ritorna l'etichetta breve per un `DateTime.weekday` (1=Lunedi..7=Domenica).
String weekdayShortLabel(int dartWeekday) =>
    kWeekdayShortLabels[(dartWeekday - 1) % 7];
