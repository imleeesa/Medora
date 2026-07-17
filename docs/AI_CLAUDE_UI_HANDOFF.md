# AI/Claude UI Handoff — Medora

Leggi solo questo file per riprendere il lavoro UI. Gerarchia documenti: **`UI_FINAL_MOCKUP_REFERENCE.md` (UI bible, vincolante)** → `UI_DESIGN_SYSTEM.md` (token/componenti) → `UI_SPRINT_ROADMAP.md` (sprint A-I) → `UI_REDESIGN_DIRECTION.md` (storico fase 1, solo contesto). Mockup sorgente: `docs/ui_mockup_reference/` (26 PNG, già analizzati e distillati nella bible — non rileggerli se non per dettagli visivi di uno sprint specifico).

## Direzione attuale

**"Soft Clinical"** (Fase 2, dai mockup finali): canvas caldo `#FCFAF7`, card bianche soft-shadow radius 20, cerchi icona tinta, chip e CTA a pillola, verde `#1E6B5A`, ink ardesia `#24313F`, ambra per avvisi, niente gradienti. Sostituisce Calm Precision (fase 1, completata: sprint 0-4 + hotfix gate + fix icone).

## Regole non negoziabili

- Architettura: UI → Provider → Services/Repositories → Drift. Mai classi Drift nella UI. Niente logica nelle schermate.
- Nessuna nuova dipendenza (grafici/navbar/font/PDF-preview: tutto con widget Flutter standard + CustomPainter).
- MAI `IconData(codePoint)` dinamico — solo `Icons.xxx` costanti (bug tree-shaking già risolto; per le terapie usare `kTherapyIconChoices`/`therapyIconForCodePoint` in `lib/utils/therapy_icons.dart`).
- Mockup = riferimento visivo, NON funzionale. Lista completa del "non copiare" in bible §28 (campanella badge, 5ª tab Statistiche, calendario storico, backup/crittografia/assistenza finti, anteprima PDF renderizzata, ecc.).
- Un solo stile card (`AppCard`), mappa StatusChip vincolante (bible §10), una CTA primaria per vista.
- Uno sprint = un commit. Tocchi a Provider/servizi vanno dichiarati prima.

## Stato: Sprint A completato

Token aggiornati (`app_colors.dart` palette Soft Clinical + `warning`/`lavender`; `app_dimens.dart` radius 12/20/24/pill), `AppCard` soft-shadow di default, `StatusChip` con tono `warning`, bottoni tutti a pillola (tema + `PrimaryButton` ora solido, gradiente eliminato), navbar senza indicatore pill. Nessuna schermata ridisegnata in questo sprint: le schermate fase-1 hanno assorbito i token automaticamente; le legacy (storico/statistiche/scorte/profilo/impostazioni/form) restano vecchie fino al loro sprint. `gold`/`goldTint` sono alias di `warning`/`warningTint`.

## Sprint B — fatto

Dashboard = mockup 04: header con avatar-iniziali (→Profilo), saluto time-aware, `+` quick actions; titolo grande "Oggi"+data; hero bianca `NextIntakeHeroCard` (pill orario, dose·terapia, countdown, chip scorta bassa — gradiente eliminato); `TodayIntakesCard` unica a righe+divider (icona tinta per stato, chip: Assunta=positive, Saltata=warning, Dimenticata=critical, Da assumere=info; azioni Assunta/Saltata identiche a prima, solo compatte); card Scorte basse in `warningTint` con "N rimaste" (mostrata SOLO se esistono scorte basse); sezione Azioni rapide (3 tile: Aggiungi medicina/Aggiungi terapia/Vedi storico→tab). **Rimossa la sezione "Terapie attive"** (ridondante con la tab, assente nel mockup). Empty state copy mockup 05 ("Nessuna terapia ancora"/"Aggiungi terapia"). 4 asserzioni di copy nei test aggiornate di conseguenza (`widget_test.dart`, `medicine_provider_notification_test.dart:910`) — nessun test di logica toccato.

## Sprint asset 3D — fatto

Asset AI approvati in `assets/images/medora/` (7 PNG RGBA 1024-1254px; **manca `calendar_3d_check.png`** dell'elenco originale — l'illustrazione empty contiene comunque un calendario). Registrati in `pubspec.yaml` (`- assets/images/medora/`). Nuovo widget `lib/widgets/medora_3d_asset.dart` (`Medora3DAsset`): path in costanti statiche, decorativo di default (`ExcludeSemantics`), `semanticLabel` opzionale, `errorBuilder` che degrada a spazio vuoto. Usati SOLO in punti editoriali: `empty_pills_illustration` → empty Dashboard; `heartPulse` → empty Terapie (non in ricerca); `capsuleMint` 64px → destra della hero card (mockup 04); `pillAmber` 28px in cerchio bianco → header card Scorte basse (mockup 22). `EmptyState` ha ora il param opzionale `imageAsset`. **Riservati per sprint futuri**: `blisterSoft` (F Scorte), `bellSoft` (H onboarding), `pillLavender` (D dettaglio medicina). MAI asset 3D in navbar, chip, righe dense, bottoni.

## Sprint C — fatto

Terapie (mockup 07/08): `TherapyCard` con cerchio icona nel colore terapia (attenuato per archiviate), chip "N medicine" tinta con icona link, chip stato in alto a destra, chevron; titolo 28 coerente con Dashboard; ricerca a pillola; empty "nessuna terapia attiva" = card con `capsuleMint` 96px + CTA tonale (`_NoActiveTherapiesCard`). Dettaglio (mockup 10): header con cerchio 56; tile medicina su due livelli (riga identità + `Wrap` di chip: orari max 2 + "+N", fascia giornata Mattina/Pomeriggio/Sera derivata dall'ora — pura presentazione, scorta "N rimaste" in ambra se sotto soglia); "Aggiungi medicina" ora riga tratteggiata full-width (`_DashedRRectPainter`, disabilitata se archiviata); empty medicine con `blisterSoft` 96px. **Logica non toccata**: `_handleAction`/`_exportPdf`/`_confirmDeleteMedicine`/ricerca/sezioni invariati. Rimandati: espansione icone terapia (~8) + picker (bible §24, farlo con Sprint D o micro-sprint), card Note (il model Therapy non ha campo note: solo description, già nell'header).

## Sprint D — fatto

Form Medicina (mockup 11/12) e Dettaglio Medicina (mockup 13) riscritti su `FormSectionCard` (nuovo widget: cerchio icona tinta + titolo + contenuto, in `lib/widgets/form_section_card.dart`). Form: sezioni Terapia associata / Dati principali / Dose opzionale / Programmazione (righe `_ScheduleGroupRow` con pill giorni+orari, editor `_ScheduleGroupEditor` con toggle giorni a quadratini) / Scorte / Colore (cerchi con check) / Note; validazione, `_saveMedicine`, `_buildDose`/`_seedDose`, breakpoint scorte <340px invariati. Dettaglio: header cerchio 52 + `StatusChip` Attiva/Inattiva, sezione Assunzione (dose SOLO se non vuota, programmazione via helper condiviso, terapia), sezione Scorta con barra (stessa euristica di `stock_screen.dart`), sezione Storico recente (ultime 3 da `provider.intakeHistory`, solo se non vuoto), CTA Modifica/Cambia terapia; **nuova wiring** di `toggleMedicineActive` (già esistente in `MedicineProvider`, prima non collegato a nessuna UI) nel menu azioni. Nessun asset 3D nel dettaglio (i colori fissi mint/lavanda/ambra non si accordano con il colore libero scelto dall'utente per la medicina).

**Debito chiuso**: raggruppamento schedule per display era duplicato identico in `add_medicine_screen.dart` e `medicine_detail_screen.dart`. Ora vive in `lib/utils/schedule_grouping.dart` (`ScheduleGrouping.groupsFor`/`groupSchedules`, solo presentazione). Regola invariata: opera sempre su `MedicineSchedule` atomici reali, mai un prodotto cartesiano tra un elenco di giorni e uno di orari non correlati; il fallback su `medicine.times`/`medicine.daysOfWeek` esiste solo quando `medicine.schedules` non ha entry attive ed è usato solo per display (mai per generare nuove assunzioni operative, che restano sempre a carico di `MedicineProvider`/repository sugli schedule atomici). Test dedicato: `test/schedule_grouping_test.dart` (8 casi: singola/multiple programmazioni, merge per stesso giorno-set, merge per stesso orario, fallback legacy, niente cartesian product, schedule disattivati esclusi, "Tutti i giorni").

## Prossimo sprint: E — Storico + Statistiche (mockup 14/15)

Filtri in bottom sheet, righe con cerchio icona+terapia, anello aderenza CustomPainter, area chart sfumata, chip tripletta, messaggio incoraggiante rule-based. Nessuna nuova dipendenza (chart/anello con CustomPainter). Non toccare `HistoryFilterService`/`HistoryStatisticsService`/formula aderenza. Dettagli: bible.

## File da NON toccare in nessuno sprint UI

`lib/providers/medicine_provider.dart`, `lib/repositories/`, `lib/data/`, `lib/services/*`, `lib/models/`, `AndroidManifest.xml`, `pubspec.yaml`/lock, `assets/fonts/`, Gradle/Kotlin/AGP, `test/` (salvo nuovi widget test per le modifiche UI).

## Comandi test dopo ogni sprint

```bash
flutter pub get && dart format lib test && dart analyze && flutter analyze && flutter test && flutter build apk --debug
```

## Note Z Flip / accessibilità

Niente larghezze fisse (residuo noto: `SizedBox(width:116)` in settings → Sprint G). Breakpoint unico 340px (`context.isNarrowScreen`). Touch target ≥48. `inkFaint` mai per informazioni essenziali. Test manuale 280/320/344px + tastiera aperta. Device reale: SM F766B via ADB wireless (può cadere: riattivare debug wireless dal telefono).

## Asset mancanti / decisioni aperte

- Logo cuore Medora: nessun asset reale — Splash/Onboarding (Sprint H) parzialmente bloccati; in-app solo wordmark testuale.
- Brand nei testi UI = "Medora" (rename tecnico package/appId resta rimandato, KNOWN_ISSUES).
- Debito raggruppamento schedule form/dettaglio: chiuso nello Sprint D (`lib/utils/schedule_grouping.dart`).
