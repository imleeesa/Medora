# AI/Claude UI Handoff — Medora

Leggi solo questo file per riprendere il lavoro UI senza rileggere tutto il repo. Dettagli completi in `docs/UI_REDESIGN_DIRECTION.md` e `docs/UI_DESIGN_SYSTEM.md`. Roadmap in `docs/UI_SPRINT_ROADMAP.md`.

## Direzione scelta

**Calm Precision** — ibrido calm clinical + premium health tracker. Verde profondo (`#1F5C4A`) come brand, accento ottone (`#B8894A`) usato con parsimonia, neutri caldi, card unica (`radius 16`, bordo `#E1E7E3`, no ombre pesanti). Palette e token completi in `UI_DESIGN_SYSTEM.md`.

Artifact di riferimento (mockup visivo palette/componenti/Dashboard/Terapie/Statistiche): "Medora — Calm Precision" — se non più recuperabile, la direzione è comunque interamente ricostruita in questi 4 file markdown, non serve rigenerarlo.

## Regole principali (non negoziabili)

- Architettura: UI → Provider → Services/Repositories → Drift. Mai classi Drift nella UI.
- Nessuna logica di business nelle schermate durante il redesign.
- Nessuna nuova dipendenza UI esterna (niente librerie charting/navbar di terze parti).
- Un solo stile di card/bottone/chip in tutta l'app (vedi `UI_DESIGN_SYSTEM.md`).
- Uno sprint = una modifica tematica, mai tutto in un commit.
- Qualsiasi tocco a Provider/repository/servizi durante uno sprint UI va segnalato come rischio prima di procedere, non fatto silenziosamente.

## Navbar (decisione finale, dopo 2 iterazioni scartate)

Le prime due versioni (pill con bottone `+` sospeso, poi variante bianca piatta con bottone sospeso) non convincevano esteticamente — troppo "custom per forza" per un'app medical-tech seria. **Decisione finale**: `NavigationBar` Material 3 nativo (`lib/widgets/app_bottom_nav_bar.dart`), 4 tab Home/Terapie/Storico/Profilo, restilizzato solo via `NavigationBarThemeData` (indicatorColor `primaryTint`, icona/label attivi `primary700`/`primary800`, inattivi `inkFaint`), **nessun bottone centrale**. Più stabile, meno codice custom, coerente con "seria e ordinata".

Le quick action (Aggiungi terapia, Aggiungi medicina, Registra assunzione, Ricarica scorta) sono rimaste **invariate** (`quick_action_sheet.dart` non toccato) ma ora si aprono da un'icona `+` nell'header della Dashboard (`_Header` in `dashboard_screen.dart`), accanto all'avatar profilo — non più dalla navbar.

## Sprint Redesign 1 — fatto

Creati: `lib/theme/app_colors.dart`, `app_dimens.dart`, `responsive.dart` (token colore/spacing/radius/breakpoint); `lib/utils/color_parser.dart`, `weekday_labels.dart` (utility pure non ancora cablate); `lib/widgets/app_card.dart`, `status_chip.dart` (nuovi, non ancora cablati). Restylati con i nuovi token (stessa API, solo colori/radius): `primary_button.dart`, `empty_state.dart`, `app.dart` (ColorScheme, AppBar, TextTheme, InputDecorationTheme, ElevatedButtonTheme). Cambio visivo reale ma contenuto: verde più profondo su bottoni/empty state/focus border ovunque già cablati; nessuna schermata redisegnata. `flutter analyze`, `flutter test` (121 test) e `flutter build apk --debug` verdi.

## Sprint Redesign 2 — fatto

Creati `lib/widgets/app_bottom_nav_bar.dart` (navbar pill flottante, Opzione A: nessun `CustomClipper`, bottone centrale sovrapposto solo via `Stack`/`Positioned`) e `lib/widgets/quick_action_sheet.dart` (bottom sheet generico `QuickAction`). `dashboard_screen.dart` aggiornato: `_PremiumBottomNavigationBar` rimossa, sostituita da `AppBottomNavBar`; nuovo `_openQuickActions` con 4 voci (Aggiungi terapia, Aggiungi medicina con guardia "nessuna terapia" riusata da `medicines_screen.dart`, Registra assunzione → switch a tab Home, Ricarica scorta → `StockScreen`) — tutte pura navigazione, zero logica nuova. `IndexedStack`/indice tab invariati.

## Sprint Redesign 3 — fatto

Dashboard riorganizzata in: Header (invariato, con `+`), `NextIntakeHeroCard` (hero, mostra anche terapia e scorta bassa se pertinente), `_TodayIntakesSection`/`TodayIntakeCard` (con `StatusChip`), `_LowStockSection`/`LowStockMiniCard` (tono ottone, mai rosso/arancio), `_TherapiesSection`/`_TherapyChipCard` (larghezza `IntrinsicWidth` + `ConstrainedBox(min:152, max:220)`, non più fissa a 178px). **Rimossa** la sezione mini-stat "Attività di oggi" (ridondante con Oggi/Terapie). Marcatura Assunta/Saltata invariata (stesso `MedicineProvider.markMedicineAsTaken/Skipped`), solo relocata in `today_intake_card.dart`. Nomi terapia risolti con `provider.getTherapyById` (getter già esistente, sola lettura).

Nuovi widget in `lib/widgets/`: `next_intake_hero_card.dart`, `today_intake_card.dart`, `low_stock_mini_card.dart`, `dashboard_section_header.dart`. Prima adozione reale di `parseHexColor` (Sprint 1) e `AppCard`/`StatusChip` (Sprint 1, prima volta cablati in una schermata).

## Sprint Hotfix Design Gate — fatto

Dopo una design review (Fable), 4 fix applicati prima di Sprint 4, tutti solo presentazione:
- `lib/app.dart`: aggiunti `filledButtonTheme`/`outlinedButtonTheme` sui token (`primary700`, `AppRadius.md`) — prima `FilledButton`/`OutlinedButton` (incluso Assunta/Saltata) usavano il verde tonale M3 derivato dal seed, non il token esatto.
- `dashboard_screen.dart`: sezione "Terapie attive" ora filtra `therapy.isActive` (prima mostrava anche archiviate).
- `dashboard_screen.dart`: avatar profilo nell'header ora tappabile, passa a tab Profilo (`onOpenProfile` come `onQuickActions`).
- `next_intake_hero_card.dart` / `today_intake_card.dart`: la dose si mostra solo se `medicine.dose.trim().isNotEmpty` (mai più "Dose non specificata" in UI); nessun cambio al model/a `doseLabel`.

## Prossimo sprint: Sprint Redesign 4 — Terapie e Dettaglio Terapia

Riusare `AppCard`/`StatusChip`/`DashboardSectionHeader`/`parseHexColor`; separare visivamente terapie attive/archiviate; allineare `TherapyCard` esistente ai token; medicine nel dettaglio terapia con lo stesso linguaggio di `TodayIntakeCard`. Non toccare archiviazione/eliminazione/export PDF.

Roadmap completa (sprint 0-9) in `docs/UI_SPRINT_ROADMAP.md`.

## File da NON toccare in nessuno sprint UI

`lib/providers/medicine_provider.dart`, tutto `lib/repositories/`, tutto `lib/data/` (incl. `local_database.g.dart`), `lib/services/*` (notifiche, CSV, PDF, storico, missed planner), tutto `lib/models/`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`/`pubspec.lock`, `assets/fonts/`, `test/` (salvo nuovi widget test aggiunti per le modifiche UI stesse).

## Comandi test dopo ogni sprint

```bash
flutter pub get
dart format lib test
dart analyze
flutter analyze
flutter test
flutter build apk --debug
```

## Note Samsung Z Flip

- Nessuna larghezza fissa in px per contenitori di contenuto (oggi presenti: card riepilogo terapia 178px, box giorni dettaglio medicina 132px, tile notifiche impostazioni 116px — da correggere negli sprint dedicati).
- Breakpoint responsive unico consigliato: 340px (pattern già esistente in `add_medicine_screen.dart` per i campi scorte, da centralizzare in un helper `context.isNarrow`).
- Touch target minimo 48x48.
- Test manuale a 280px, 320px, 344px (Z Flip aperto) + verifica con tastiera aperta.
- Navbar: altezza totale (barra + bottone sollevato) ≤ 80dp per non erodere spazio verticale.

## Come continuare senza rileggere tutto

1. Leggi questo file.
2. Se lo sprint richiede palette/tipografia/spacing esatti → apri `UI_DESIGN_SYSTEM.md`.
3. Se serve il "perché" di una scelta (navbar, dashboard, form, ecc.) → apri `UI_REDESIGN_DIRECTION.md`.
4. Se serve solo sapere cosa viene dopo → `UI_SPRINT_ROADMAP.md`.
5. Non rifare l'audit delle schermate: è già confluito in questi documenti.
