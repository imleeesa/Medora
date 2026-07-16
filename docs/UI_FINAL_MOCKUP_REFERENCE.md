# UI Bible — Medora "Soft Clinical" (riferimento mockup finali)

Fonte visiva ufficiale: `docs/ui_mockup_reference/` (26 tavole, 00-25). Questo documento traduce i mockup in una direzione implementabile. Dove i mockup si contraddicono, qui c'è la decisione vincolante. I mockup sono riferimento **visivo**, mai specifica funzionale.

## 1. Sintesi direzione finale

"**Soft Clinical**" — evoluzione di Calm Precision guidata dai mockup: canvas bianco caldo, card bianche morbide con ombra diffusa (non più bordered-flat), icona in cerchio tinta come ancora visiva di ogni riga, chip a pillola con icona, CTA a pillola piena, verde smeraldo `#1E6B5A` come unico colore di marca, ambra per gli avvisi, lavanda come accento decorativo raro. Più aria, raggi più ampi, gerarchia tipografica più forte (titoli schermata grandi). Niente gradienti: il verde pieno sostituisce il gradiente ovunque.

## 2. Analisi mockup (giudizio critico)

Materiale AI-generated di buona qualità direzionale: coerente su palette, card, chip e navigazione; ottimo il tono del microcopy (calmo, mai colpevolizzante). Difetti da non copiare: incoerenze interne (navbar a 4 tab in metà tavole e a 5 in altre; "Dimenticata" grigia nello Storico ma rossa nella components sheet; "Saltata" arancione in Storico ma il flusso reale la tratta come scelta volontaria), feature inesistenti mostrate come attive (backup cloud, crittografia, assistenza, campanella notifiche con badge, calendario storico, "Riprogramma orario", "Ultimo accesso"), decorazioni non implementabili (foglie watermark, sfere 3D, foto pillole), frame iPhone. Tutto catalogato in §28.

## 3. Palette finale (token `lib/theme/app_colors.dart`)

| Token | Hex | Uso |
|---|---|---|
| `primary700` | `#1E6B5A` | Brand, CTA, tab attiva, stato positivo |
| `primary800` | `#124C3E` | Pressed, testo su tint verde |
| `primaryTint` | `#E6F2EC` | Sfondi chip/badge positivi, cerchi icona |
| `mint` | `#A8DCC6` | Riempimenti decorativi (barre, ring) |
| `warning` / `warningTint` | `#B4711E` / `#FBF1DC` | Scorta bassa, dose saltata, "in arrivo" |
| `lavender` / `lavenderTint` | `#7A70C9` / `#ECEAF9` | Accento decorativo (icone terapia, note) |
| `ink` | `#24313F` | Titoli (ardesia, non più verde-nero) |
| `inkSoft` | `#4A5568` | Testo secondario |
| `inkFaint` | `#94A0AC` | Caption, tab inattive |
| `background` | `#FCFAF7` | Canvas bianco caldo |
| `surface` | `#FFFFFF` | Card |
| `border` | `#E6E8EB` | Hairline (usata al 60% alpha nelle card) |
| `critical` / `criticalTint` | `#B14834` / `#F9E7E1` | Dose dimenticata, errori |
| `info` / `infoTint` | `#4C6B85` / `#E7EEF3` | Stato programmato/informativo |

`gold`/`goldTint` restano come alias di `warning`/`warningTint` (compatibilità).

## 4. Tipografia

Font di sistema/Roboto (nessuna nuova dipendenza; i mockup usano un sans arrotondato non riproducibile senza asset — la morbidezza si ottiene con pesi e spaziatura). Scala: titolo schermata 28-32/w800 (grande, come "Oggi"/"Storico" nei mockup); titolo card 18-20/w700; body 15/w500; label 12.5/w600; caption 12/w500 `inkFaint`. Numeri grandi (aderenza, scorte) 26-32/w800.

## 5. Spacing — scala invariata: 4/8/12/16/24/32/40. Padding card 16-20; respiro tra sezioni 24.

## 6. Radius — `sm=12` (input, tile icona), `md=20` (card, unico), `lg=24` (sheet/dialog/hero), `pill=999` (bottoni, chip). Aggiornati nei token.

## 7. Ombre — card: ombra diffusa `ink` 5% alpha, blur 18, offset (0,6) + hairline `border` al 60%. Mai ombre dure. CTA primaria: ombra verde 22% blur 12.

## 8. Card system — solo `AppCard` (aggiornata: ombra di default, bordo attenuato, radius 20). Anatomia riga tipo: cerchio icona tinta 40-48px a sinistra, titolo+sottotitolo al centro, chip stato/valore a destra, chevron opzionale. Vietate nuove varianti locali.

## 9. Button system — CTA primaria: pillola piena `primary700`, testo bianco, altezza 52-56, **una sola per vista**, icona opzionale a sinistra. Secondaria: pillola outline verde. Terziaria: solo testo verde. `FilledButton`/`OutlinedButton`/`ElevatedButton` ereditano la pillola dal tema. Distruttive: testo/icona `critical`, mai bottone pieno rosso.

## 10. Chip/status system — `StatusChip` a pillola, tinta + testo scuro dello stesso colore. Mappa vincolante (risolve le incoerenze dei mockup): **Assunta**=positive (verde) · **Saltata**=warning (ambra) · **Dimenticata**=critical (terracotta soft) · **Programmata/In arrivo**=info · **Attiva**=positive · **Archiviata/Inattiva**=neutral · **Scorta bassa**=warning · **Nella norma**=positive. Icona nel chip: ammessa (check, orologio, !), da aggiungere al widget quando serve.

## 11. Input/form system — campi bianchi, radius 12, hairline `border`, focus verde 2px, icona leading tinta quando aiuta il riconoscimento. Form divisi in sezioni-card con intestazione (cerchio icona tinta + titolo), come mockup 09/11. Giorni settimana: quadratini toggle (attivo verde pieno, inattivo bianco bordo). Orari: pill chip con orologio + "Aggiungi orario" outline tratteggiato.

## 12. Bottom navigation — 4 tab (Home, Terapie, Storico, Profilo), `NavigationBar` M3, indicatore trasparente, attiva verde w700, inattive `inkFaint`. **Decisione**: NO quinta tab Statistiche (i mockup sono incoerenti; su Z Flip 5 tab affollano; Statistiche resta raggiungibile dallo Storico). NO campanella con badge (feature inesistente).

## 13. Dashboard reference (mockup 04) — ordine: header (avatar iniziali + "Ciao {nome}", `+` azioni rapide) → titolo grande "Oggi" → card **Prossima assunzione** (BIANCA: label piccola, orario in pill verde in alto a destra, nome medicina 24-26/w800, riga dose·indicazione — **il gradiente verde della hero attuale viene eliminato**) → card unica "Assunzioni di oggi" (righe con divider, chip stato a destra, azioni Assunta/Saltata inline solo sulla riga attiva) → card **Scorte basse** (tinta `warningTint`, non rossa: elenco medicine + rimanenze, tap → Scorte) → sezione **Azioni rapide** (griglia 3 tile: Aggiungi medicina, Segna come assunta→oggi, Vedi storico). Le tile Azioni rapide si aggiungono; l'`+` nell'header resta.

## 14. Terapie reference (mockup 07/08) — titolo grande centrato, ricerca pill, sezioni "Attive"/"Archiviate" (già implementate ✓), card terapia: cerchio icona nel colore terapia, nome, descrizione, chip "N medicine" tinta + chip stato, chevron. Empty attive con illustrazione leggera e CTA tonale "Aggiungi terapia".

## 15. Dettaglio terapia reference (mockup 10) — header card (icona grande, nome, chip stato, chip N medicine, pallini colore), lista medicine: cerchio icona, nome, dose, pill orario + pill fascia giorno (Mattina/Sera — derivabile dall'ora dello schedule, solo presentazione), stato attiva + scorta residua a destra. Bottone "Aggiungi medicina" come **riga tratteggiata verde** full-width (sostituisce l'IconButton). Card "Note terapia" in fondo se presenti.

## 16. Form medicina reference (mockup 11) — sezioni-card: Dati principali (nome; "Forma farmaceutica" del mockup ≈ unità esistente, non nuovo campo), Terapia associata (select), Dose opzionale (dose/unità/indicazioni), Scorte (quantità, soglia; il toggle "Avviso scorte basse" del mockup NON esiste come preferenza → non copiarlo), Note. CTA "Salva medicina" pillola piena con icona.

## 17. Dettaglio medicina reference (mockup 13) — header card (nome, terapia, chip stato) → card Dose/Orari/Giorni/Terapia associata a righe → card **Scorta disponibile** (numero grande, soglia, barra progresso, chip "Scorta nella norma/bassa") → card **Storico recente** (ultime 3 registrazioni con chip) → coppia bottoni "Modifica medicina" (piena) + "Cambia terapia" (outline) → card Note. Storico recente = dati già in cache provider (intakeHistory filtrata per medicina) — pura presentazione, nessuna query nuova.

## 18. Storico reference (mockup 14/23) — titolo grande + bottone "Filtri" outline pill che apre sheet (sostituisce i 4 dropdown sempre visibili), conteggio registrazioni, card-righe: cerchio icona, nome, terapia (icona cuore piccola + nome), data/ora, chip stato. Banner info calmo in fondo. NON copiare: toggle Panoramica/Calendario (vista calendario inesistente), "Riprogramma orario". Lo stato "dimenticata di oggi" con CTA "Registra adesso" (mockup 23) è già coperto dalle azioni esistenti sulla card.

## 19. Statistiche reference (mockup 15) — filtri periodo come pill toggle (7/30 giorni) + dropdown terapia/medicina, **anello aderenza** grande con % al centro e messaggio incoraggiante rule-based sotto (testo derivato dalla % esistente, ammesso), grafico trend con area riempita sfumata verde sotto la linea (CustomPainter esistente da restilizzare, no nuove dipendenze), card 7/30 giorni con "X su Y assunzioni", tripletta chip Assunta/Saltata/Dimenticata con conteggi. NON copiare: tab Statistiche in navbar, "Insight" generativi.

## 20. Scorte reference (mockup 16/17/22) — header con riepilogo (N medicine · N scorte basse · aggiornato oggi), card per medicina: cerchio icona, nome, terapia, "N compresse residue" colorato per stato, soglia minima, barra progresso (verde/ambra), chip stato, bottone "Ricarica" outline pill. Dialog ricarica → **bottom sheet** stile mockup 17 (card medicina + quantità attuale, campo quantità, CTA piena, Annulla testo) — stessa logica `addStock` esistente. "Ordina" del mockup: opzionale, solo se banale (sort in memoria), bassa priorità.

## 21. Profilo/Impostazioni reference (mockup 18/19) — Profilo: card identità (iniziali grandi in cerchio, nome, matita edit), tripletta stat card (Terapie attive / Medicine monitorate / Aderenza — tutti dati già in provider), "Accessi rapidi" (Impostazioni, Scorte; NON "Notifiche"/"Esportazioni" come voci autonome se non esistono flussi dedicati — Esportazioni può puntare allo Storico). NON copiare: "Ultimo accesso", "Backup dati attivo". Impostazioni: righe con cerchio icona tinta, restare onesti su Backup/Report PDF (badge "Prossimamente", niente chevron ingannevole — già deciso in gate review). Schermata permessi (mockup 20): buona reference per ristilizzare la sezione permessi esistente (card per permesso + stato chip + azione), stessa logica.

## 22. Onboarding/Splash reference (mockup 01/02/03) — Splash: logo + wordmark + tagline su canvas caldo. Onboarding 2-3 pagine (benvenuto, notifiche) con CTA pillola e "Più tardi". **Nota**: onboarding oggi non esiste; è UI pura attorno a flussi esistenti (richiesta permesso notifiche già implementata nel provider/servizio). Sprint dedicato in coda alla roadmap; richiede asset logo (vedi §24). Nessuna nuova logica: "Attiva notifiche" chiama la richiesta permesso esistente.

## 23. Empty states — pattern mockup: illustrazione leggera in cerchio tinta, titolo w800, 1-2 righe, CTA. Il widget `EmptyState` esistente è già conforme; copy da rifinire per schermata (§25). Empty "Nessuna terapia attiva" con CTA tonale verde chiaro (mockup 08).

## 24. Icone — Material Icons costanti (vincolo tree-shaking: MAI `IconData(codePoint)` dinamico, vedi bug risolto). Espandere `kTherapyIconChoices` a ~8 icone costanti ispirate ai mockup: spa, favorite, monitor_heart, medical_services, water_drop, eco/leaf, shield, healing. **Logo Medora (cuore)**: non esiste asset — serve SVG/PNG dal designer; fino ad allora niente logo in-app (solo wordmark testuale dove serve). Le foto-pillola 3D dei mockup si sostituiscono con cerchi tinta + icona pillola.

## 25. Microcopy — tono calmo, mai colpevolizzante (dal mockup 22: "Promemoria, non un allarme"; dal 23: "Nessun problema, puoi registrarla ora"). Saluto time-aware (Buongiorno/Buonasera). Titoli schermata grandi e semplici. Brand nei testi UI: **"Medora"** (i mockup lo sanciscono; il rename tecnico package/appId resta rimandato come da KNOWN_ISSUES — solo copy visibile).

## 26. Cosa manteniamo del lavoro attuale

Architettura token/componenti (AppColors/AppSpacing/AppRadius/AppCard/StatusChip/EmptyState/DashboardSectionHeader — solo valori aggiornati); navbar M3 a 4 tab; quick action sheet e sue 4 azioni; sezioni Attive/Archiviate in Terapie; struttura Dashboard (ordine sezioni quasi identico ai mockup); tutte le regole "non ansiogeno"; fix del gate review (bottoni a tema, dose fallback nascosta, avatar tappabile).

## 27. Cosa cambiamo

Hero Dashboard: da gradiente verde a card bianca con orario in pill (il verde pieno resta solo su CTA). Palette: ink ardesia, canvas caldo, ambra al posto dell'ottone. Card: da bordered-flat a soft-shadow, radius 20. Bottoni: tutti a pillola, PrimaryButton solido (gradiente eliminato). Navbar: via l'indicatore pill M3. Storico: filtri in sheet. Statistiche: anello + area chart. Scorte: righe con barra + Ricarica inline, sheet al posto del dialog. Dettaglio medicina/terapia: layout a card-sezioni dei mockup.

## 28. Cosa NON copiare dai mockup (finto o inesistente)

Campanella notifiche con badge; tab "Statistiche" in navbar (5 tab); toggle Panoramica/**Calendario** in Storico; "Riprogramma orario"; toggle "Avviso scorte basse" nel form; "Ordina" scorte (opzionale); backup cloud "attivo"; "crittografia end-to-end"; "Assistenza"; "Profili familiari"; "Tema e preferenze/Aspetto"; "Ultimo accesso"; schermata anteprima PDF renderizzata (richiederebbe una dipendenza: il flusso resta genera+share, si ristilizza solo il punto d'ingresso); foto avatar (usare iniziali); foglie/sfere 3D decorative; emoji nel saluto (facoltativa, tendenza playful); dati clinici d'esempio (Metformina ecc.).

## 29. Rischi tecnici

Cambiare i token sposta TUTTE le schermate già ridisegnate in automatico (voluto) ma le schermate legacy (storico/statistiche/scorte/profilo/impostazioni/form) restano col vecchio grigio `#F5F7F8` hardcoded finché non arriva il loro sprint → transizione visivamente disomogenea, accettata e temporanea. Radius/pillola cambiano silhouette di tutti i bottoni: verifica visiva su device dopo ogni sprint. Ombre diffuse su molte card: performance ok in Flutter, ma evitare ombre annidate in liste lunghe (usare `elevated: false` nelle righe dense se serve). Anello aderenza e area chart: solo CustomPainter, vietate librerie. Asset logo mancante: blocco solo per Splash/Onboarding (Sprint H).

## 30. Roadmap — vedi `docs/UI_SPRINT_ROADMAP.md` (Sprint A-I, aggiornata con questo sprint come "Sprint A completato").
