# Problemi noti - Meditrack

Questo file raccoglie bug, discrepanze e rischi tecnici noti. Ogni problema resta tracciato fino a quando viene corretto, accettato come limite temporaneo o spostato nella roadmap.

## Naming non uniforme tra Medora e Meditrack

### Categoria

Incoerenza da chiarire/correggere ora.

### Stato

Rimandato

### Cosa e' stato trovato

La cartella del progetto usa il nome Medora, mentre package Flutter, titolo app, label Android e documentazione usano Meditrack.

### Motivazione

La correzione richiede una decisione di prodotto sul nome definitivo. Rinominare package, application id Android, label, documentazione e riferimenti interni senza una scelta esplicita sarebbe rischioso e potrebbe generare modifiche ampie non necessarie in questo sprint.

### Possibili soluzioni

- decidere se il nome finale sara' Medora o Meditrack;
- aggiornare documentazione, app title, app label e riferimenti UI in modo coerente;
- rinominare package/application id solo quando il branding sara' stabile.

## Tema scuro salvato ma non applicato

### Categoria

Bug da correggere ora.

### Stato

Risolto

### Data risoluzione

2026-06-19

### Come e' stato risolto

Il toggle del tema scuro nelle impostazioni e' stato disabilitato, per evitare che l'utente possa attivare una preferenza che non cambia realmente il tema dell'app. Il tema scuro resta una funzionalita' futura da implementare e verificare con un passaggio UI dedicato.

### File modificati

- `lib/screens/settings_screen.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

### Note

Il campo `isDarkMode` resta nel model `UserProfile` come predisposizione futura, ma non viene piu' esposto come controllo operativo.

## Terapie non gestibili come entita' autonome

### Categoria

Feature futura da lasciare aperta.

### Stato

Aperto

### Cosa e' stato trovato

Le terapie vengono create indirettamente quando si aggiunge una medicina. Non esiste ancora un flusso dedicato per creare, modificare, archiviare o cancellare una terapia.

### Motivazione

La gestione completa delle terapie e' una feature di prodotto prevista dalla roadmap. Implementarla ora richiederebbe nuovi flussi UI, nuove azioni nel provider e possibili cambiamenti di navigazione. Non rientra nello sprint di revisione dei problemi sicuri.

### Possibili soluzioni

- introdurre una schermata o un flusso dedicato alle terapie;
- mantenere il modello `TERAPIE -> MEDICINE`;
- aggiungere dettaglio terapia prima di introdurre database;
- documentare ogni nuova responsabilita' nella guida tecnica.

## Storico assunzioni non operativo

### Categoria

Feature futura da lasciare aperta.

### Stato

Aperto

### Cosa e' stato trovato

Il model `IntakeRecord` esiste, ma la schermata Storico mostra solo uno stato vuoto e non registra assunzioni.

### Motivazione

Lo storico completo richiede azioni di conferma, salto o ritardo assunzione, gestione dei record in memoria e collegamento con le scorte. Sarebbe una feature nuova, quindi non viene implementata in questo sprint.

### Possibili soluzioni

- aggiungere gestione in memoria degli `IntakeRecord`;
- creare azioni rapide dalla dashboard o dal dettaglio medicina;
- collegare la conferma assunzione al decremento scorte;
- introdurre persistenza solo in una fase successiva.

## Notifiche locali non integrate nel flusso principale

### Categoria

Feature futura da lasciare aperta.

### Stato

Aperto

### Cosa e' stato trovato

`NotificationService` e' presente, ma non viene inizializzato all'avvio e non viene usato quando una medicina viene creata, modificata, disattivata o cancellata.

### Motivazione

L'integrazione completa delle notifiche richiede una strategia stabile per ID notifica, permessi, scheduling ricorrente e cancellazione. Non va introdotta come fix rapido.

### Possibili soluzioni

- inizializzare il servizio in fase di avvio;
- pianificare notifiche alla creazione/modifica medicina;
- cancellare notifiche quando una medicina viene disattivata o rimossa;
- verificare permessi Android e iOS.

## Backup e report PDF sono voci non operative

### Categoria

Bug da correggere ora.

### Stato

Risolto

### Data risoluzione

2026-06-19

### Come e' stato risolto

Le voci Backup e Report medico PDF nelle impostazioni ora mostrano un messaggio che comunica che la funzionalita' sara' disponibile in una prossima versione. Non e' stato implementato backup, cloud o generazione PDF.

### File modificati

- `lib/screens/settings_screen.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

### Note

Backup e report PDF restano nella roadmap come feature future, ma non sono piu' controlli senza feedback.

## Overflow temporaneo in Aggiungi Medicina con tastiera aperta

### Categoria

Bug da correggere ora.

### Stato

Risolto

### Data risoluzione

2026-06-19

### Come e' stato risolto

La schermata `AddMedicineScreen` e' stata resa piu' stabile con tastiera aperta usando `SafeArea`, `LayoutBuilder`, `SingleChildScrollView` con padding legato a `MediaQuery.viewInsets.bottom` e `resizeToAvoidBottomInset`. La freccia indietro e il pulsante Annulla chiudono prima la tastiera e poi eseguono il pop della schermata. I campi delle scorte passano da layout affiancato a layout verticale sugli schermi piu' stretti.

### File modificati

- `lib/screens/add_medicine_screen.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`.

### Note

Il fix mira a evitare il warning giallo/nero visibile per un frame quando si torna indietro dalla schermata con la tastiera ancora aperta, soprattutto su schermi piccoli e telefoni pieghevoli.

## Vecchio log di build con errore NDK

### Categoria

Problema gia' risolto.

### Stato

Risolto

### Data risoluzione

2026-06-19

### Come e' stato risolto

Il problema risulta legato a un vecchio log di build in `build_output.txt`, generato in un percorso precedente del progetto. La versione NDK configurata nel progetto risulta avere il file `source.properties` presente nell'ambiente locale.

### File modificati

- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

### Note

Non e' stata eseguita una nuova build Android completa in questo sprint. Prima di un rilascio Android e' consigliato rigenerare una build pulita.

## Application ID Android ancora generico

### Categoria

Incoerenza da chiarire/correggere ora.

### Stato

Rimandato

### Cosa e' stato trovato

Il progetto Android usa ancora `com.example.meditrack` come namespace e application id.

### Motivazione

Cambiare application id e namespace e' una modifica di configurazione importante, legata al nome definitivo dell'app e alla distribuzione futura. Non e' opportuno farla prima di risolvere il naming Medora/Meditrack.

### Possibili soluzioni

- decidere il nome definitivo dell'app;
- impostare namespace e application id coerenti;
- aggiornare MainActivity/package e configurazioni store quando il progetto sara' pronto.
