# Changelog progresso - Meditrack

Questo file registra le modifiche importanti fatte al progetto. Ogni blocco di lavoro dovrebbe aggiungere una voce nuova, cosi' da mantenere chiaro cosa e' cambiato, perche' e con quale stato.

## Formato delle voci

Ogni voce deve includere:

- data;
- tipo modifica;
- descrizione;
- file modificati;
- motivazione;
- stato.

## 2026-06-19 - Documentazione

Tipo modifica: preparazione del flusso di lavoro documentato.

Descrizione:

- creato il registro di avanzamento del progetto;
- creato il registro dei problemi noti;
- aggiunte regole operative per mantenere README, guida tecnica, changelog e problemi noti allineati;
- aggiornata la documentazione principale con i riferimenti ai nuovi file.

File modificati:

- `README.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

Motivazione:

Il progetto sta entrando in una fase di sviluppo piu' ordinata. Serve una traccia stabile per documentare modifiche importanti, problemi aperti, decisioni tecniche e stato generale dell'app.

Stato: completato.

## 2026-06-19 - Revisione known issues

Tipo modifica: Bug Fix / Documentation / Refactor leggero.

Descrizione:

- analizzati i problemi presenti in `docs/KNOWN_ISSUES.md`;
- disabilitato il toggle del tema scuro per evitare un controllo senza effetto reale;
- aggiunto feedback utente alle voci Backup e Report medico PDF nelle impostazioni;
- riclassificati i problemi noti distinguendo bug corretti, feature future, incoerenze rimandate e problema tecnico gia' risolto;
- aggiornata la guida tecnica per riflettere il comportamento attuale delle impostazioni.

File modificati:

- `lib/screens/settings_screen.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`.

Problemi risolti:

- tema scuro salvato ma non applicato: il controllo e' stato disabilitato finche' la feature non sara' implementata;
- Backup e Report medico PDF senza feedback: ora mostrano un messaggio di funzione pianificata;
- vecchio log NDK: riclassificato come risolto perche' l'ambiente locale contiene il file NDK richiesto.

Problemi rimandati:

- naming non uniforme tra Medora e Meditrack;
- terapie non gestibili come entita' autonome;
- storico assunzioni non operativo;
- notifiche locali non integrate nel flusso principale;
- application id Android ancora generico.

Motivazione:

Lo sprint doveva sistemare solo problemi sicuri e opportuni, senza introdurre database, cloud, login o feature complesse. Le correzioni applicate riducono incoerenze visibili mantenendo intatta l'architettura attuale.

Stato finale: completato.

## 2026-06-19 - Fix responsive Aggiungi Medicina

Tipo modifica: Bug Fix / Documentation / Refactor leggero.

Descrizione:

- analizzata la schermata `AddMedicineScreen` e le schermate con contenuto lungo o input;
- reso il form di aggiunta medicina piu' stabile con tastiera aperta;
- aggiunti `SafeArea`, layout scrollabile con padding legato alla tastiera e chiusura tastiera prima del ritorno alla schermata precedente;
- adattati i campi scorte per schermi stretti;
- documentata una regola tecnica generale per layout responsive con form e tastiera.

File modificati:

- `lib/screens/add_medicine_screen.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`.

Problemi risolti:

- overflow temporaneo giallo/nero vicino al pulsante "Aggiungi Medicina" quando si torna indietro con tastiera aperta.

Problemi rimandati:

- verifica manuale su dispositivo Android reale e Samsung Z Flip;
- verifica automatica completa con `flutter analyze`, bloccata da timeout nell'ambiente corrente.

Motivazione:

Prima di introdurre il database locale era necessario stabilizzare il comportamento responsive del form principale, riducendo layout rigidi e transizioni problematiche quando la tastiera si apre o si chiude.

Stato finale: completato con verifica automatica parziale.

## 2026-06-19 - Piano database locale

Tipo modifica: Decisione tecnica / Progettazione / Documentation.

Descrizione:

- analizzati model esistenti e `MedicineProvider`;
- definita una strategia futura per passare dai dati in memoria alla persistenza locale;
- valutate le alternative `sqflite`, `drift`, `hive` e `isar`;
- scelto Drift come opzione consigliata per il futuro database locale;
- proposto schema dati per terapie, medicine, schedule, storico, profili e impostazioni;
- documentata l'architettura futura `UI -> Provider -> Repository -> DatabaseService -> Database locale`;
- identificati rischi tecnici da gestire prima dell'implementazione.

File modificati:

- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

Problemi risolti:

- nessun bug applicativo risolto: sprint solo progettuale.

Problemi rimandati:

- implementazione database locale;
- aggiunta dipendenze a `pubspec.yaml`;
- creazione repository, database service, tabelle e migrazioni;
- migrazione effettiva di `MedicineProvider`;
- integrazione con notifiche, storico e scorte persistenti.

Motivazione:

Prima di implementare la persistenza era necessario definire una direzione tecnica chiara, evitando di introdurre uno storage non adatto a relazioni, schedule, storico e future migrazioni.

Stato finale: completato come progettazione, senza modifiche al comportamento dell'app.

## 2026-06-19 - Sprint Database 1

Tipo modifica: Database / Infrastructure / Documentation.

Descrizione:

- aggiunte le dipendenze base per Drift e SQLite locale;
- creata la struttura `lib/data/` per database locale e servizio di accesso centralizzato;
- definite le tabelle principali per profili, impostazioni, terapie, medicine, orari e storico;
- generato il file Drift `local_database.g.dart`;
- mantenuto invariato il comportamento dell'app: Provider, UI e schermate non sono stati collegati al database;
- documentati vincoli di compatibilita' con Dart 3.8 e tooling locale.

File modificati:

- `.gitignore`;
- `pubspec.yaml`;
- `pubspec.lock`;
- `linux/flutter/generated_plugin_registrant.cc`;
- `linux/flutter/generated_plugins.cmake`;
- `macos/Flutter/GeneratedPluginRegistrant.swift`;
- `windows/flutter/generated_plugin_registrant.cc`;
- `windows/flutter/generated_plugins.cmake`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

File creati:

- `lib/data/local_database.dart`;
- `lib/data/local_database.g.dart`;
- `lib/data/database_service.dart`;
- `lib/data/tables/user_profiles_table.dart`;
- `lib/data/tables/app_settings_table.dart`;
- `lib/data/tables/therapies_table.dart`;
- `lib/data/tables/medicines_table.dart`;
- `lib/data/tables/medicine_schedules_table.dart`;
- `lib/data/tables/intake_records_table.dart`.

Problemi risolti:

- predisposta una base Drift compilabile senza migrare ancora lo stato in memoria;
- introdotta una cache Dart locale ignorata da Git per aggirare il problema di permessi sulla cache globale.

Problemi rimandati:

- collegamento del database a repository e Provider;
- migrazione dei dati in memoria verso persistenza locale;
- gestione seed profilo locale e migrazioni future;
- integrazione con notifiche, storico e scorte persistenti;
- timeout del comando `flutter analyze` nell'ambiente corrente.

Motivazione:

Lo sprint introduce solo la base tecnica del database locale, mantenendo separato il nuovo layer dati dal comportamento attuale dell'app. Questo permette di verificare schema e generazione Drift prima di spostare logica e stato nei repository.

Stato finale: completato con generazione Drift e analisi Dart pulita.

## 2026-06-21 - Sprint Database 2

Tipo modifica: Database / Repository layer / Documentation.

Descrizione:

- creato il layer `lib/repositories/` sopra `DatabaseService` e `LocalDatabase`;
- aggiunti repository per profilo, impostazioni, terapie, medicine e storico assunzioni;
- incapsulate query, ordinamenti e transazioni di cancellazione nel layer dati;
- mantenuta invariata l'app: `MedicineProvider`, schermate e dati in memoria non sono stati collegati al database;
- documentato il ruolo del repository layer e il prossimo step di migrazione graduale del Provider.

File creati:

- `lib/repositories/profile_repository.dart`;
- `lib/repositories/settings_repository.dart`;
- `lib/repositories/therapy_repository.dart`;
- `lib/repositories/medicine_repository.dart`;
- `lib/repositories/intake_repository.dart`.

File modificati:

- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

Problemi risolti:

- introdotto un punto unico per query e operazioni database, separato da Provider e UI;
- gestita la cancellazione dei record relazionati senza perdere gli snapshot dello storico assunzioni.

Problemi rimandati:

- mapper completi fra righe Drift e model di dominio;
- test automatici dei repository;
- seed del profilo locale;
- collegamento di `MedicineProvider` ai repository;
- timeout intermittente dei wrapper Flutter nell'ambiente locale.

Motivazione:

Il layer repository prepara una migrazione ordinata verso la persistenza locale, mantenendo fuori dal Provider i dettagli di query e transazioni. In questa fase non viene modificato alcun flusso utente.

Stato finale: completato con `dart analyze` senza problemi.
