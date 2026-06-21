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

### Tipo

Funzionalita' incompleta / Limite architetturale

### Gravita'

Media

### Stato

Aperto / Pianificato

### Area

Terapie, Medicine, Provider, Database futuro

### Cosa e' stato trovato

Le terapie vengono create o usate principalmente durante l'aggiunta di una medicina. Non esiste ancora un flusso autonomo per creare, modificare, eliminare o archiviare una terapia, aprirne il dettaglio, aggiungere medicine al suo interno o visualizzare tutte le medicine associate.

### Motivazione

La gestione completa delle terapie e' una feature di prodotto prevista dalla roadmap. Richiede flussi UI dedicati, nuove azioni del Provider e il collegamento graduale alla persistenza locale. Non deve essere risolta nello Sprint Database 3: verra' affrontata in uno sprint dedicato al sistema Terapie dopo l'integrazione del Provider con il database.

### Possibili soluzioni

- introdurre una schermata o un flusso dedicato alle terapie;
- mantenere il modello `TERAPIE -> MEDICINE`;
- aggiungere creazione, modifica, archiviazione ed eliminazione controllata della terapia;
- aggiungere dettaglio terapia con elenco delle medicine associate;
- consentire l'aggiunta di medicine all'interno di una terapia;
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

## Migrazione futura al database locale

### Categoria

Rischio tecnico da verificare.

### Stato

Risolto

### Data risoluzione

2026-06-21

### Come e' stato risolto

Lo Sprint Database 3 collega `MedicineProvider` ai repository. Il Provider carica il database all'avvio, crea il profilo `local-user` e le impostazioni di default se mancanti, ricostruisce la cache UI e salva le modifiche principali nel database locale.

### File modificati

- `lib/main.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/repositories/therapy_repository.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

### Note

Non esistevano dati persistiti da migrare. Il test su database temporaneo e le feature ancora fuori dal flusso restano pianificati separatamente.

## Normalizzazione di orari, giorni e storico

### Categoria

Rischio tecnico da verificare.

### Stato

Rimandato

### Cosa e' stato trovato

`Medicine` oggi contiene `List<TimeOfDay>` e `List<int>` per orari e giorni, serializzati come stringhe compatte nei metodi `toJson` e `fromJson`. Questo formato e' semplice, ma poco adatto a query, notifiche ricorrenti e storico.

### Motivazione

La normalizzazione richiede una tabella futura `medicine_schedules` e una strategia per collegare ogni schedule a notifiche e assunzioni. Non va fatta finche' non viene introdotto il database locale.

### Possibili soluzioni

- salvare ogni combinazione giorno/orario in `medicine_schedules`;
- usare indici su `weekday`, `hour` e `minute`;
- collegare notifiche locali agli schedule invece che solo alla medicina;
- usare snapshot in `intake_records` per mantenere storico leggibile anche dopo modifiche o cancellazioni.

## Compatibilita' dipendenze database con Dart 3.8

### Categoria

Problema tecnico da verificare.

### Stato

Da verificare

### Cosa e' stato trovato

Durante lo Sprint Database 1 il progetto e' risultato basato su Dart 3.8.0. Alcune release recenti dei pacchetti database, inclusi Drift, `drift_dev`, `sqlite3_flutter_libs` e `path_provider`, richiedono Dart 3.10 o superiore.

### Motivazione

Per completare lo sprint senza aggiornare l'intera toolchain sono state usate versioni compatibili con Dart 3.8. Il database compila e il file Drift generato e' stato creato correttamente, ma un futuro upgrade delle dipendenze richiedera' prima l'aggiornamento di Flutter/Dart.

### Possibili soluzioni

- mantenere le versioni attuali finche' il progetto resta su Dart 3.8;
- aggiornare Flutter/Dart prima di aggiornare Drift e pacchetti collegati;
- rieseguire `pub get`, generazione Drift e analisi dopo ogni upgrade.

## Timeout dei comandi Flutter wrapper nell'ambiente locale

### Categoria

Problema tecnico da verificare.

### Stato

Da verificare

### Cosa e' stato trovato

I comandi eseguiti tramite wrapper Flutter/Dart hanno mostrato timeout o blocchi nell'ambiente corrente. L'eseguibile Dart diretto ha invece permesso di completare `pub get`, `build_runner` e `dart analyze`.

### Motivazione

Il problema sembra legato all'ambiente locale e alla cache globale di Dart, dove e' stato rilevato anche un errore di permessi. Per non bloccare lo sprint e' stata usata una cache locale ignorata da Git.

### Possibili soluzioni

- verificare permessi della cartella cache Dart globale dell'utente;
- rigenerare la cache globale con una sessione terminale normale;
- riprovare `flutter pub get` e `flutter analyze` fuori dal sandbox;
- mantenere `.dart_cli_config/` fuori da Git.

## Allineamento incompleto tra model di dominio e schema Drift

### Categoria

Problema tecnico da verificare.

### Stato

Risolto

### Data risoluzione

2026-06-21

### Come e' stato risolto

Lo Sprint Database 2.5 ha introdotto mapper dedicati e aggiornato i repository affinche' espongano model dell'app invece di entita' e companion Drift. I model ora rappresentano metadati terapia, profilo, snapshot dello storico e schedule logici delle medicine.

### File modificati

- `lib/models/`;
- `lib/data/mappers/`;
- `lib/repositories/`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

### Note

I campi legacy non ancora presenti nello schema persistente restano tracciati in un problema separato.

## Campi legacy profilo e icona non persistiti completamente

### Categoria

Problema tecnico da verificare.

### Stato

Rimandato

### Cosa e' stato trovato

`UserProfile.email` e `UserProfile.language` non hanno colonne dedicate nello schema `user_profiles`. Inoltre il vecchio campo `Medicine.icon` usa un nome testuale, mentre il database persiste `iconCodePoint`. Il model conserva entrambi i percorsi per compatibilita', ma il mapper salva il code point.

### Motivazione

Estendere le tabelle richiederebbe una migrazione di schema Drift, non necessaria prima che il database venga collegato al Provider. Forzare una conversione da nome icona a code point sarebbe fragile e non e' usata dalla UI attuale.

### Possibili soluzioni

- introdurre una migrazione che aggiunga email e lingua al profilo, se diventano dati locali necessari;
- scegliere un unico formato per le icone e migrare il campo legacy;
- coprire i mapper con test prima dell'integrazione nel Provider.
