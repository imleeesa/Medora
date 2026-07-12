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

## Navbar (decisione presa)

Sostituire la bottom nav custom attuale con una **soft floating navbar** (angoli pill, 4 tab Home/Terapie/Storico/Profilo, pulsante centrale `+` verde sollevato). Il `+` apre un quick action sheet con 4 voci, tutte pura navigazione verso flussi già esistenti: Aggiungi medicina, Aggiungi terapia, Registra assunzione (→ Dashboard/Oggi), Ricarica scorta (→ StockScreen). Nessuna nuova logica Provider.

Fallback se l'incavo concavo è troppo fragile in Flutter: stessa barra ma con angoli arrotondati semplici (no `CustomClipper`), bottone solo sovrapposto via `Stack`/`Positioned`. Spec tecnica completa in `UI_DESIGN_SYSTEM.md` sezione "Bottom navbar".

## Prossimo sprint da fare: Sprint Redesign 1

Design tokens + componenti base. Creare `lib/theme/app_colors.dart` (token da `UI_DESIGN_SYSTEM.md`), aggiornare/creare `AppCard`, `StatusChip`, restyle `PrimaryButton`/`SecondaryButton`/`EmptyState`. **Zero cambi visivi alle schermate finché i componenti non vengono cablati** — sprint a rischio basso, base per tutto il resto.

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
