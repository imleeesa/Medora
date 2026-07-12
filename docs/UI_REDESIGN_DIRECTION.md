# Direzione UI/UX — Medora "Calm Precision"

Documento di direzione visiva per il Full UI Redesign. Sostituisce l'approccio "polish leggero" precedente. Nessun codice app è stato modificato per produrre questo documento.

## 1. Diagnosi UI attuale (sintesi)

- Il tema centralizzato in `lib/app.dart` esiste ma viene bypassato da tutte le schermate: colori `Color(0xFF...)` letterali ripetuti ovunque invece di `Theme.of(context).colorScheme`.
- Componenti riutilizzabili (`MedicineCard`, `TherapyCard`, `EmptyState`, `DashboardCard`, `PrimaryButton`) esistono ma sono usati in modo incoerente: quasi ogni schermata ricostruisce le proprie card/empty state da zero.
- `_parseColor` duplicato in 6+ file; logica di raggruppamento schedule duplicata tra `add_medicine_screen.dart` e `medicine_detail_screen.dart` (rischio di divergenza dati, non solo estetico).
- Bottom navigation della Dashboard è completamente custom, animata, ma visivamente scollegata da Material 3 dichiarato nel tema.
- Punti di overflow reali su schermi stretti: card riepilogo terapia (178px fissi), box giorni dettaglio medicina (132px fissi), tile stato notifiche Impostazioni (116px fissi).
- Impostazioni: voci Backup/Report PDF hanno aspetto di navigazione ma mostrano solo un messaggio "funzione pianificata" — incoerenza percepita.
- L'app "sembra" costruita sprint per sprint: stili di card, raggi e bottoni divergono da schermata a schermata.

(Analisi completa già svolta screen-by-screen in sessione precedente; questo file ne è la sintesi operativa.)

## 2. Direzione scelta: Calm Precision

Ibrido tra *calm clinical* e *premium health tracker*. Non "medical minimal" puro (troppo freddo per chi gestisce terapie con ansia/fatica quotidiana), non "soft wellness" (troppo lifestyle/pastello), non "personal care assistant" (troppo consumer/giocattoloso).

**Perché**: l'utente tipo gestisce terapie croniche, spesso in un contesto di leggero stress. Serve fiducia tramite precisione (tipografia chiara, spazio bianco, colore usato con intenzione) più che tramite decorazione. Il verde resta il colore di marca ma va reso meno "Material default" e più deliberato; un accento caldo (ottone) dà la sensazione "premium" senza scadere nel gioco.

## 3. Palette

| Token | Hex | Uso |
|---|---|---|
| `primary700` | `#1F5C4A` | Brand, CTA primarie, stato "assunta" |
| `primary800` | `#164536` | Testo su tint, hover/pressed |
| `primaryTint` | `#E4EFE9` | Sfondi chip/badge positivi, hero secondario |
| `gold` | `#B8894A` | Accento caldo, usato con parsimonia (badge premium, avvisi scorte, evidenze secondarie) |
| `goldTint` | `#F5EBDD` | Sfondo badge scorte/avviso |
| `ink` | `#1B211E` | Testo primario |
| `inkSoft` | `#5C6864` | Testo secondario |
| `inkFaint` | `#8A9490` | Testo terziario/caption |
| `background` | `#F3F5F3` | Sfondo app |
| `surface` | `#FFFFFF` | Card, superfici |
| `border` | `#E1E7E3` | Hairline/bordi |
| `critical` | `#B14834` | Stato "dimenticata", errori (terracotta, non rosso puro — meno ansiogeno) |
| `info` | `#4C6B85` | Stato "programmata"/informativo |

Il tema resta **solo light** (decisione già presa nel progetto); nessuna modifica a questa scelta in questa fase.

## 4. Design principles

1. Una terapia deve essere riconoscibile a colpo d'occhio (colore + icona coerenti in ogni punto dell'app).
2. Le azioni importanti stanno vicino al contesto (segna assunta/saltata accanto alla dose, non in un menu).
3. Le statistiche sono visive prima che numeriche (barre/anelli, non solo percentuali in testo).
4. Gli stati critici (scorta bassa, dose dimenticata) sono chiari ma mai allarmistici: terracotta/ottone, mai rosso acceso o icone lampeggianti.
5. Una sola card bianca, un solo stile di bordo/raggio, in tutta l'app.
6. Il colore comunica significato (stato), non decorazione.
7. L'app funziona bene a una mano su schermi stretti (Z Flip 280-320px): niente larghezze fisse fragili.
8. Ogni schermata riusa gli stessi componenti condivisi — mai una nuova "card" locale se ne esiste già una.

## 5. Navigazione: nuova bottom navbar

**Decisione: sostituire la bottom nav custom attuale** con una navbar "soft floating" con pulsante centrale `+`, ispirata allo sketch fornito.

### Perché cambiare
La nav attuale è già completamente custom (animazioni proprie) ma visivamente generica; il progetto ha già dimostrato di saper gestire pittura custom (il grafico aderenza usa `CustomPainter`), quindi il rischio tecnico è comparabile, mentre il guadagno visivo/di marca è alto: la navbar diventa un elemento distintivo di Medora invece di un componente anonimo.

### Struttura proposta
- 4 tab: **Home · Terapie · Storico · Profilo** (nessun cambio ai 4 contenuti esistenti, stesso `IndexedStack`).
- Barra "pill": container bianco, angoli superiori molto arrotondati (28-32px), bordo hairline, ombra leggera. 2 tab a sinistra, 2 a destra, gap centrale.
- Pulsante centrale `+`: cerchio verde (`primary700`), 56-60px, sollevato sopra il bordo superiore della barra (metà dentro, metà fuori), con leggero incavo/ombra nella barra sotto di esso per dare l'effetto "alloggiamento".
- Il bottone centrale **non è una quinta tab selezionabile**: è un'azione overlay, sempre visibile, mai in stato "attivo/selezionato".

### Ruolo del pulsante `+`
Apre un **quick action sheet** (bottom sheet) con 4 voci, tutte instradate verso flussi già esistenti (**zero nuova logica**):
1. **Aggiungi medicina** → apre `AddMedicineScreen` esistente.
2. **Aggiungi terapia** → apre `AddTherapyScreen` esistente.
3. **Registra assunzione** → naviga alla tab Home/Dashboard, sezione "Oggi" (pura navigazione, le azioni Assunta/Saltata restano quelle già esistenti sulle card).
4. **Ricarica scorta** → naviga alla tab Scorte (`StockScreen` esistente, dialog di ricarica già presente).

Scartate le alternative "solo aggiungi medicina" (troppo limitante, il `+` merita di essere un hub) e "azione diretta senza menu" (ambigua: aggiungere cosa?). Il quick sheet dà valore reale al pulsante più prominente dell'app senza inventare funzionalità nuove.

### Alternativa più sicura (fallback)
Se la forma con incavo/onda risulta fragile in pratica (allineamento pixel, safe area, gesture bar Android): stessa barra ma **senza incavo concavo** — angoli arrotondati semplici (28px) + pulsante `+` che si sovrappone semplicemente per posizione (`Stack` + `Positioned`, nessun `CustomClipper`). Visivamente il 90% dell'effetto "floating premium" con zero rischio di path/geometria.

### Rischi tecnici
- Deve riusare esattamente la stessa logica di switch-tab (`IndexedStack` + indice) già in `DashboardScreen`: nessuna modifica a `MedicineProvider`.
- Il bottone centrale deve restare puramente di navigazione/UI (apre uno sheet con `Navigator`/`showModalBottomSheet`), non deve introdurre metodi Provider nuovi.
- Serve `SafeArea`/`viewPadding.bottom` corretto per non sovrapporsi alla gesture bar Android.
- Contenuto scrollabile delle tab deve avere padding inferiore pari all'altezza reale della barra + margine del bottone sollevato, per non nascondere l'ultimo elemento della lista.

### Comportamento su Z Flip
Altezza totale barra + bottone sollevato: max ~76-80dp, per non erodere lo spazio verticale su schermi corti. Tab con solo icona + micro-label (10-11px), mai testo lungo. A 280-300px di larghezza i 4 tab + gap centrale restano leggibili (icone 22-24px, spaziatura equa `MainAxisAlignment.spaceAround` sui due gruppi di 2).

### Test manuale consigliato
Emulatore/finestra a 280px, 320px, 344px (Z Flip aperto) e tablet largo; verificare: tap target ≥48px, nessun overlap tra bottone `+` e contenuto scrollabile, comportamento con tastiera aperta (la barra deve restare ancorata sotto, non fluttuare sopra la tastiera), cambio tab preserva stato scroll di ciascuna tab come oggi.

## 6. Proposta Dashboard

- Hero card "Prossima assunzione": gradiente `primary700→primary800`, nome medicina, countdown, un solo CTA visibile.
- Sezione "Oggi": righe compatte (nome, orario, stato chip), azioni Assunta/Saltata inline.
- "Terapie attive": chip orizzontali a larghezza intrinseca (mai fissa), scroll orizzontale sicuro.
- Scorte basse: banner calmo color `goldTint`/`gold`, non rosso.
- Riferimento visivo: mockup già approvato nell'artifact "Calm Precision".

## 7. Terapie e Medicine

- Lista terapie: righe unificate (icona tinta colore terapia, nome, meta, chip stato Attiva/Archiviata), filtro Attive/Archiviate come chip in alto invece di lista mista.
- Dettaglio terapia: riusa lo stesso componente medicina della Dashboard/Scorte (oggi ricostruito 3 volte diverse).
- Dettaglio medicina: un solo stile di header (oggi diverso da quello Dashboard), box orari senza larghezza fissa, schedule raggruppati con la stessa logica del form (da unificare in Sprint 5-6).

## 8. Form Medicina

- Diviso in sezioni visive con intestazione (Informazioni base, Programmazione, Scorte, Note) invece di lista piatta di campi.
- Stock fields già responsive (pattern `LayoutBuilder` a 340px) da estendere a color/icon picker.
- Bottone "Aggiungi programmazione" diventa `SecondaryButton` invece di `ElevatedButton` grezzo.

## 9. Storico e Statistiche

- Filtri storico: chip con conteggio attivo + bottone "Filtri" che apre sheet, invece di 4 dropdown sempre visibili.
- Righe storico: stato come chip colorato coerente (taken=verde, skipped=grigio, missed=terracotta).
- Statistiche: anello/percentuale aderenza come hero, breakdown con barre inline (non solo testo), grafico trend con stile coerente al design system (riempimento leggero sotto la linea, etichette adattive alla larghezza reale).

## 10. Scorte / Impostazioni / Profilo

- Scorte: barra progresso mantenuta (già chiara), riuso del componente medicina unificato.
- Impostazioni: Backup/Report PDF con badge "Prossimamente" e stile disabilitato (niente chevron di navigazione fuorviante).
- Profilo: riuso `AppCard`/`DashboardCard` invece di container locali.

## 11. Cose da NON fare

- Non cambiare tutte le schermate in un unico commit.
- Non spostare logica di business nelle schermate durante il redesign.
- Non introdurre dipendenze UI esterne (niente librerie di charting/nav bar di terze parti — tutto già fattibile con Flutter/CustomPainter, coerente con le scelte esistenti del progetto).
- Non rendere l'app giocattolosa: niente animazioni eccessive, niente colori sgargianti sugli stati critici.
- Non sacrificare leggibilità dei dati medici per estetica (numeri sempre leggibili, contrasto verificato).
