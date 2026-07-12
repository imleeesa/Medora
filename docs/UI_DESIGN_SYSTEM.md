# Design System — Medora "Calm Precision"

Specifica tecnica dei token e componenti da implementare negli Sprint Redesign. Riferimento normativo per l'implementazione (evita di re-decidere stile ad ogni sprint).

## Color tokens

Definire in un file nuovo, es. `lib/theme/app_colors.dart` (Sprint Redesign 1), senza toccare provider/servizi:

```dart
primary700   #1F5C4A   // brand, CTA primarie, stato "assunta"
primary800   #164536   // testo su tint, pressed/hover
primaryTint  #E4EFE9   // sfondi chip/badge positivi
gold         #B8894A   // accento caldo, avvisi scorte
goldTint     #F5EBDD   // sfondo badge scorte/avviso
ink          #1B211E   // testo primario
inkSoft      #5C6864   // testo secondario
inkFaint     #8A9490   // caption/placeholder
background   #F3F5F3   // sfondo app (scaffold)
surface      #FFFFFF   // card/superfici
border       #E1E7E3   // hairline
critical     #B14834   // stato "dimenticata", errori
info         #4C6B85   // stato "programmata"
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
- Radius: `sm=10` (input/chip), `md=16` (card standard — **unico raggio per tutte le card**), `lg=24` (hero card, sheet, navbar).
- Elevazione: bordo hairline (`border`) + ombra sottile opzionale (blur 12-16, alpha 0.03-0.05). Mai ombre pesanti.

## Regole componenti

### AppCard (nuovo, sostituisce le 15+ varianti locali)
Bianco, `radius md`, bordo `border` 1px, padding 16. Usare ovunque serva "card bianca con bordo grigio" (oggi reimplementata in dashboard, statistics, history, profile, settings).

### Bottoni
- `PrimaryButton`: CTA principale di ogni schermata/form — gradiente `primary700→primary800`, radius 14-16. **Uno solo per vista.**
- `SecondaryButton`: outline `primary700`, azioni secondarie (es. "Aggiungi programmazione").
- Azioni distruttive: solo testo/icona in `critical`, mai bottone pieno rosso.
- Vietato: `ElevatedButton`/`FilledButton` grezzi fuori da questi due componenti.

### StatusChip
| Stato | Sfondo | Testo |
|---|---|---|
| Assunta | `primaryTint` | `primary800` |
| Saltata | `border` | `inkSoft` |
| Dimenticata | tint terracotta chiaro (`#F6E4DF`) | `critical` |
| Programmata | tint blu-grigio chiaro (`#E7EEF3`) | `info` |

### Empty state
Riusare sempre `EmptyState` esistente (icona in cerchio tinta `primaryTint`, titolo, descrizione, bottone opzionale). Vietato ricrearne varianti locali (oggi duplicato in `medicines_screen.dart`, `history_screen.dart` x2).

### Dialog
`AlertDialog` standard per conferme distruttive (pattern già corretto in tutta l'app, mantenere).

### Snackbar
Due varianti: successo (`primaryTint` bg, `primary800` testo/icona check) ed errore (tint terracotta, `critical` testo/icona). Mai messaggi di errore tecnici grezzi (`'$error'`) — sempre testo utente comprensibile.

### Form
Sezioni con intestazione (icona + titolo) racchiuse in `AppCard`, non lista piatta di campi. Pattern responsive esistente (`LayoutBuilder` breakpoint 340px per campi affiancati) da centralizzare in un helper unico (es. `context.isNarrow`) e riusare per color/icon picker.

## Bottom navbar — spec componente

Nuovo widget `AppBottomNavBar` (Sprint Redesign 2):

- **Struttura**: `Stack` — barra pill in basso (`Container`/`CustomPainter` per il bordo superiore arrotondato/inciso) + `Positioned` con il pulsante centrale `+` sollevato (56-60px, cerchio `primary700`, icona bianca).
- **Tab**: Home, Terapie, Storico, Profilo — 2 a sinistra e 2 a destra del pulsante centrale, icona + micro-label 10-11px, stato attivo = icona filled + colore `primary700`, inattivo = icona outline + `inkFaint`.
- **Pulsante centrale**: non è una tab selezionabile, sempre neutro, apre `showModalBottomSheet` con 4 voci (Aggiungi medicina, Aggiungi terapia, Registra assunzione, Ricarica scorta) — tutte navigazione pura verso schermate esistenti.
- **Altezza totale**: barra + bottone sollevato ≤ 80dp.
- **Fallback sicuro**: se l'incavo concavo (`CustomClipper`/path) risulta fragile, usare angoli arrotondati semplici (28px) senza incavo, bottone solo sovrapposto via `Positioned` — stesso effetto visivo al 90%, zero rischio di geometria custom.
- **Vincoli**: nessuna modifica a `IndexedStack`/logica indice tab esistente in `DashboardScreen`; `SafeArea`/`viewPadding.bottom` gestiti nel widget; contenuto scrollabile delle tab deve avere `padding.bottom` ≥ altezza barra + offset bottone.
