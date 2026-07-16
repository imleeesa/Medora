# Design System — Medora "Soft Clinical"

Specifica tecnica dei token e componenti. **Aggiornato ai mockup finali** (`docs/ui_mockup_reference/`): per anatomia delle schermate e decisioni visive vincolanti vedi `docs/UI_FINAL_MOCKUP_REFERENCE.md` (UI bible), che prevale su questo file in caso di conflitto.

## Color tokens (implementati in `lib/theme/app_colors.dart`)

```dart
primary700    #1E6B5A   // brand, CTA, tab attiva, positivo
primary800    #124C3E   // pressed, testo su tint verde
primaryTint   #E6F2EC   // sfondi chip/badge positivi, cerchi icona
mint          #A8DCC6   // riempimenti decorativi (barre, ring)
warning       #B4711E   // scorta bassa, saltata, in arrivo (testo/icona)
warningTint   #FBF1DC   // sfondo avvisi ambra
gold/goldTint = alias di warning/warningTint (compatibilita' legacy)
lavender      #7A70C9   // accento decorativo raro, mai semantico
lavenderTint  #ECEAF9
ink           #24313F   // titoli (ardesia)
inkSoft       #4A5568   // testo secondario
inkFaint      #94A0AC   // caption, tab inattive (mai per info essenziali)
background    #FCFAF7   // canvas bianco caldo
surface       #FFFFFF   // card
border        #E6E8EB   // hairline (60% alpha dentro AppCard)
critical      #B14834   // dimenticata, errori
criticalTint  #F9E7E1
info          #4C6B85   // programmata/informativo
infoTint      #E7EEF3
```

Tema resta **solo light** (nessuna modifica a questa decisione già presa nel progetto).

## Typography scale

| Ruolo | Size/Weight | Uso |
|---|---|---|
| Display | 28-32 / 400 (o 700 se serve peso) | Titoli hero, nome medicina in evidenza |
| Title | 18-20 / 700 | Titoli sezione, nomi terapia/medicina in card |
| Body | 15 / 500 | Testo principale |
| Label | 12.5 / 600 | Etichette campi, micro-nav label |
| Caption | 12 / 500, `inkFaint` | Metadati, timestamp |

Font: resta il default di sistema/Roboto (già in bundle per l'export PDF) — nessuna nuova dipendenza font.

## Spacing & radius

- Spacing scale: 4, 8, 12, 16, 24, 32, 40.
- Radius (aggiornati Sprint A): `sm=12` (input, tile icona), `md=20` (card standard — **unico raggio per tutte le card**), `lg=24` (sheet/dialog/hero), `pill=999` (bottoni e chip).
- Elevazione card: ombra diffusa `ink` 5% alpha blur 18 offset (0,6) + hairline `border` al 60% (linguaggio soft-shadow dei mockup). Mai ombre dure o annidate in liste dense (`elevated: false` dove serve).

## Regole componenti

### AppCard (unica card ammessa)
Bianca, `radius md=20`, ombra soft di default (`elevated: true`), hairline attenuata. Anatomia riga tipo mockup: cerchio icona tinta 40-48px + titolo/sottotitolo + chip/valore a destra + chevron opzionale.

### Bottoni
- `PrimaryButton`: CTA principale — **pillola piena `primary700`** (gradiente eliminato negli Sprint mockup), testo bianco. **Uno solo per vista.**
- `SecondaryButton`: pillola outline `primary700`.
- `FilledButton`/`OutlinedButton`/`ElevatedButton` ereditano la pillola dal tema globale (`app.dart`).
- Azioni distruttive: solo testo/icona in `critical`, mai bottone pieno rosso.

### StatusChip (mappa vincolante, UI bible §10)
| Stato | Tone | Sfondo/Testo |
|---|---|---|
| Assunta / Attiva / Nella norma | `positive` | `primaryTint` / `primary800` |
| Saltata / Scorta bassa / In arrivo | `warning` | `warningTint` / `warning` |
| Archiviata / Inattiva | `neutral` | `border` / `inkSoft` |
| Dimenticata / errore | `critical` | `criticalTint` / `critical` |
| Programmata / informativo | `info` | `infoTint` / `info` |

### Empty state
Riusare sempre `EmptyState` esistente (icona in cerchio tinta `primaryTint`, titolo, descrizione, bottone opzionale). Vietato ricrearne varianti locali (oggi duplicato in `medicines_screen.dart`, `history_screen.dart` x2).

### Dialog
`AlertDialog` standard per conferme distruttive (pattern già corretto in tutta l'app, mantenere).

### Snackbar
Due varianti: successo (`primaryTint` bg, `primary800` testo/icona check) ed errore (tint terracotta, `critical` testo/icona). Mai messaggi di errore tecnici grezzi (`'$error'`) — sempre testo utente comprensibile.

### Form
Sezioni con intestazione (icona + titolo) racchiuse in `AppCard`, non lista piatta di campi. Pattern responsive esistente (`LayoutBuilder` breakpoint 340px per campi affiancati) da centralizzare in un helper unico (es. `context.isNarrow`) e riusare per color/icon picker.

## Bottom navbar — spec componente (allineata ai mockup, Sprint A)

`AppBottomNavBar` (`lib/widgets/app_bottom_nav_bar.dart`) è un `NavigationBar` Material 3 nativo avvolto in `Material(elevation: 8)` + `SafeArea(top: false)`: **indicatore trasparente** (via il pill M3, come da mockup), tab attiva icona+label `primary700` w700, inattive `inkFaint`, `height: 64`, 4 tab fisse Home/Terapie/Storico/Profilo. Nessun bottone centrale, nessuna quinta tab Statistiche (decisione UI bible §12). Nessun `CustomClipper` — le due iterazioni custom restano scartate.

Le quick action (`quick_action_sheet.dart`) si aprono dall'icona `+` nell'header della Dashboard; dallo Sprint B si aggiunge anche la sezione "Azioni rapide" a tile in fondo alla Dashboard (mockup 04/06).
