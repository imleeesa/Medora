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

## 2026-06-21 - Sprint Database 2.5

Tipo modifica: Database / Model alignment / Mapper layer / Documentation.

Descrizione:

- allineati i model di dominio allo schema Drift in modo retrocompatibile;
- aggiunti model per impostazioni e schedule logici delle medicine;
- creati mapper per profilo, impostazioni, terapie, medicine, schedule, storico e colori;
- aggiornati tutti i repository affinche' espongano model dell'app e mantengano privati i tipi Drift;
- reso reattivo lo stream medicine anche alle modifiche di `medicine_schedules`;
- mantenuti invariati Provider, schermate e comportamento dell'app.

File creati:

- `lib/models/app_settings.dart`;
- `lib/models/medicine_schedule.dart`;
- `lib/data/mappers/color_value_mapper.dart`;
- `lib/data/mappers/user_profile_mapper.dart`;
- `lib/data/mappers/settings_mapper.dart`;
- `lib/data/mappers/therapy_mapper.dart`;
- `lib/data/mappers/medicine_mapper.dart`;
- `lib/data/mappers/intake_record_mapper.dart`.

File modificati:

- `lib/models/medicine.dart`;
- `lib/models/therapy.dart`;
- `lib/models/intake_record.dart`;
- `lib/repositories/profile_repository.dart`;
- `lib/repositories/settings_repository.dart`;
- `lib/repositories/therapy_repository.dart`;
- `lib/repositories/medicine_repository.dart`;
- `lib/repositories/intake_repository.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

Problemi risolti:

- repository che esponevano entita' e companion Drift;
- perdita della relazione logica tra orari e giorni durante la conversione da `medicine_schedules`;
- stream medicine non reattivo alle modifiche degli schedule.

Problemi rimandati:

- persistenza di alcuni campi legacy del profilo e dell'icona testuale della medicina;
- test automatici dei repository;
- seed del profilo locale;
- collegamento di `MedicineProvider` ai repository.

Motivazione:

Il mapper layer chiude il confine tra dominio e persistenza. Provider e UI potranno essere collegati ai repository nello sprint successivo senza importare classi Drift generate.

Stato finale: completato con analisi Dart pulita.

## 2026-06-21 - Documentazione limite sistema Terapie

Tipo modifica: Documentation.

Descrizione:

- aggiornata la problematica gia' nota sulla gestione non autonoma delle terapie;
- classificato il limite come funzionalita' incompleta / limite architetturale, gravita' media, stato aperto e pianificato;
- chiarito l'obiettivo futuro `TERAPIE -> MEDICINE` e le azioni previste per la gestione terapia;
- confermato che il problema non verra' risolto nello Sprint Database 3.

File modificati:

- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Motivazione:

La gestione completa delle terapie dipende dal successivo collegamento tra Provider e database. Documentarla ora evita che venga trattata come un bug puntuale durante gli sprint di persistenza.

Stato finale: completato, nessuna modifica al codice applicativo.

## 2026-06-21 - Sprint Database 3

Tipo modifica: Database / Provider integration / Bug Fix / Documentation.

Descrizione:

- collegato `MedicineProvider` ai repository di profilo, impostazioni, terapie e medicine;
- aggiunto caricamento automatico del database all'avvio dell'app;
- creato seed sicuro del profilo locale `local-user` e delle impostazioni predefinite quando il database e' vuoto;
- rese persistenti le operazioni esistenti su medicine, terapie collegate, scorte e profilo;
- mantenuta la cache in memoria per la UI e aggiunti loading/error state semplici;
- salvata in transazione la prima coppia terapia piu' medicina;
- mantenute invariati schermate, UI, notifiche e storico assunzioni.

File modificati:

- `lib/main.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/models/medicine.dart`;
- `lib/repositories/therapy_repository.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

Problemi risolti:

- Provider basato solo su memoria;
- persistenza non attiva per medicine, terapie collegate, schedule, profilo e impostazioni;
- seed del profilo locale mancante.

Problemi rimandati:

- test repository su database temporaneo;
- gestione autonoma delle terapie;
- storico assunzioni operativo;
- notifiche locali collegate agli schedule;
- persistenza dei campi legacy profilo e icona testuale.

Motivazione:

Lo sprint rende persistente il flusso esistente senza cambiare la UI. Il Provider continua a essere l'unica fonte dati per le schermate, mentre repository e mapper proteggono l'app dai dettagli Drift.

Stato finale: completato con analisi e test Flutter eseguiti.

## 2026-06-22 - Sprint Gestione Autonoma Terapie

Tipo modifica: Feature / Provider integration / UI / Documentation.

Descrizione:

- resa autonoma la gestione delle terapie con elenco, creazione, modifica e dettaglio;
- aggiunta creazione di una terapia senza medicine e persistenza immediata in Drift;
- aggiunto dettaglio terapia con medicine associate e ingresso diretto al form medicina;
- aggiunta archiviazione sicura per terapie con medicine ed eliminazione per terapie vuote;
- eliminazione di una medicina senza cancellazione automatica della terapia;
- aggiornato il vecchio flusso medicina per riusare o riattivare terapie omonime;
- mantenute UI e Provider indipendenti da classi Drift generate.

File creati:

- `lib/screens/add_therapy_screen.dart`;
- `lib/screens/therapy_detail_screen.dart`;
- `lib/widgets/therapy_card.dart`.

File modificati:

- `lib/providers/medicine_provider.dart`;
- `lib/screens/add_medicine_screen.dart`;
- `lib/screens/medicines_screen.dart`;
- `lib/screens/dashboard_screen.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`;
- `README.md`.

Problemi risolti:

- terapie non gestibili come entita' autonome;
- impossibilita' di aggiungere una medicina nel contesto di una terapia esistente;
- rischio di duplicare una terapia gia' esistente dal vecchio form medicina.

Problemi rimandati:

- spostamento medicine tra terapie;
- riattivazione esplicita di una terapia archiviata dall'interfaccia;
- filtri e ordinamenti avanzati delle terapie;
- storico, notifiche e backup.

Motivazione:

Il progetto ora rispetta il modello `TERAPIE -> MEDICINE`: una terapia puo' esistere e venire gestita prima di contenere medicine, mantenendo la persistenza locale introdotta negli sprint database.

Stato finale: completato con verifiche statiche e test Flutter.

## 2026-06-24 - Sprint Scorte automatiche da assunzioni

Tipo modifica: Feature / Bug Fix / Documentation.

Descrizione:

- collegato l'aggiornamento della scorta alla registrazione di un'assunzione `taken`;
- resa atomica la persistenza di record storico e medicina aggiornata tramite `IntakeRepository`;
- evitato il doppio decremento per record gia' `taken`;
- aggiunto il ripristino della scorta quando un record passa da `taken` a `skipped`;
- bloccata l'assunzione quando una quantita' intera nota supera la scorta disponibile;
- mantenuto un comportamento sicuro per dose assente, frazionaria o decimale: storico aggiornato, scorta invariata.

File modificati:

- `lib/models/medicine.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/repositories/intake_repository.dart`;
- `lib/screens/dashboard_screen.dart`;
- `test/medicine_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- scorta invariata dopo un'assunzione registrata;
- rischio di doppio decremento dello stesso slot;
- assenza di ripristino per il passaggio da assunta a saltata.

Problemi rimandati:

- quantita' frazionarie e decimali in scorta;
- carico manuale, correzioni e notifiche di riacquisto;
- notifiche automatiche, report e backup.

Motivazione:

Lo sprint mantiene separati dose e scorta, senza modificare lo schema Drift a valori decimali.

Stato finale: completato con `dart analyze`, `flutter analyze` e test Flutter superati; restano consigliate le verifiche manuali del flusso su dispositivo.

## 2026-06-24 - Sprint Storico Assunzioni Base

Tipo modifica: Feature / Provider integration / Documentation.

Descrizione:

- collegato `IntakeRepository` a `MedicineProvider` e aggiunta la cache dello storico;
- allineati gli stati di dominio a `scheduled`, `taken` e `skipped`, mantenendo compatibilita' in lettura con il valore legacy `missed`;
- aggiunti metodi Provider per ottenere le assunzioni previste di oggi, leggere lo storico e segnare una dose come assunta o saltata;
- introdotta verifica database per evitare record duplicati della stessa medicina allo stesso orario previsto;
- aggiunte azioni rapide Dashboard e lista persistente nella schermata Storico;
- mantenuti gli snapshot di nome e dose per conservare leggibilita' dopo l'eliminazione della medicina.

File modificati:

- `lib/models/intake_record.dart`;
- `lib/models/scheduled_intake.dart`;
- `lib/data/mappers/intake_record_mapper.dart`;
- `lib/repositories/intake_repository.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/dashboard_screen.dart`;
- `lib/screens/history_screen.dart`;
- `test/intake_record_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- storico assunzioni non operativo;
- assenza di azioni per assunta e saltata nella dashboard;
- perdita di leggibilita' dello storico dopo eliminazione della medicina.

Problemi rimandati:

- filtri, statistiche, ritardi e note avanzate;
- decremento scorte collegato all'assunzione;
- notifiche automatiche, report e backup.

Motivazione:

Lo sprint rende operativo lo storico minimo senza introdurre notifiche o modifiche allo schema Drift.

Stato finale: completato con verifiche automatiche; restano consigliate le prove manuali di persistenza su dispositivo.

## 2026-06-24 - Sprint Spostamento medicine e cancellazione terapie

Tipo modifica: Feature / Bug Fix / Documentation.

Descrizione:

- aggiunta l'azione `Cambia terapia` nel dettaglio medicina;
- rese disponibili come destinazione solo le terapie attive diverse da quella corrente;
- aggiunto al Provider `moveMedicineToTherapy`, che valida la destinazione, aggiorna `therapyId` con il repository e ricarica la cache UI;
- resa sempre disponibile l'eliminazione definitiva della terapia, con conferma rafforzata quando contiene medicine;
- aggiornata la cancellazione repository per eliminare in transazione schedule, medicine e terapia, evitando record medicine orfani.

File modificati:

- `lib/providers/medicine_provider.dart`;
- `lib/repositories/therapy_repository.dart`;
- `lib/screens/medicine_detail_screen.dart`;
- `lib/screens/therapy_detail_screen.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.
- `test/medicine_test.dart`.

Problemi risolti:

- impossibilita' di spostare una medicina tra terapie;
- eliminazione terapia con medicine bloccata dalla UI;
- rischio di medicine senza terapia durante l'eliminazione diretta.

Problemi rimandati:

- gestione guidata di record legacy eventualmente privi di terapia;
- storico, notifiche, report e backup.

Motivazione:

Lo sprint completa le due azioni di gestione richieste senza cambiare lo schema Drift o introdurre funzionalita' fuori perimetro.

Stato finale: completato con `dart analyze`, `flutter analyze` e test Flutter superati; restano consigliate le verifiche manuali del flusso su dispositivo.

## 2026-06-22 - Sprint Rifinitura funzionale Terapie e Medicine

Tipo modifica: Bug Fix / Refactor leggero / Documentation.

Descrizione:

- resa obbligatoria l'associazione di ogni nuova medicina a una terapia esistente;
- bloccata l'apertura del form globale medicina quando non esistono terapie, con azione diretta per crearne una;
- rimosso dal Provider il comportamento che creava una terapia implicita partendo da testo libero;
- resa opzionale la dose senza modificare lo schema Drift: il form combina quantita' e unita' per assunzione, mentre la UI gestisce il valore non definito;
- distinta l'archiviazione dall'eliminazione definitiva della terapia e bloccata quest'ultima quando sono presenti medicine associate;
- documentato il limite dei record legacy eventualmente privi di terapia.

File modificati:

- `lib/models/medicine.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/add_medicine_screen.dart`;
- `lib/screens/medicines_screen.dart`;
- `lib/screens/therapy_detail_screen.dart`;
- `lib/screens/dashboard_screen.dart`;
- `lib/screens/medicine_detail_screen.dart`;
- `lib/widgets/medicine_card.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.
- `test/medicine_test.dart`.

Problemi risolti:

- creazione implicita di terapie dal flusso medicina;
- eliminazione definitiva non esplicitamente bloccata per terapie con medicine;
- dose obbligatoria e possibile visualizzazione vuota nel dettaglio;
- ambiguita' tra quantita' per assunzione e scorta.

Problemi rimandati:

- spostamento delle medicine tra terapie;
- migrazione guidata di eventuali medicine legacy senza terapia;
- storico, notifiche, report e backup.

Motivazione:

Lo sprint consolida le regole fondamentali del dominio senza cambiare lo schema database o introdurre nuove aree funzionali.

Stato finale: completato con `dart analyze`, `flutter analyze` e test Flutter superati; restano consigliate le verifiche manuali del flusso su dispositivo.

## 2026-06-22 - QA e bug fix Terapie/Medicine

Tipo modifica: Bug Fix / QA / Documentation.

Descrizione:

- aggiunta eliminazione della medicina dal dettaglio terapia e dal dettaglio medicina, con conferma;
- aggiunta riattivazione di una terapia archiviata dal menu azioni;
- resa esplicita la CTA globale `Aggiungi medicina` nella sezione Terapie;
- mantenuti il flusso medicina dentro terapia e il riuso/riattivazione della terapia omonima nel form globale;
- documentato uno sprint futuro di rifinitura UI/UX Terapie e Medicine.

File modificati:

- `lib/providers/medicine_provider.dart`;
- `lib/screens/medicine_detail_screen.dart`;
- `lib/screens/therapy_detail_screen.dart`;
- `lib/screens/medicines_screen.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- eliminazione medicina non accessibile dal dettaglio terapia;
- terapia archiviata senza azione di riattivazione;
- flusso globale per aggiungere una medicina poco evidente.

Problemi rimandati:

- revisione UI/UX completa di Terapie e Medicine;
- spostamento medicine tra terapie;
- storico, notifiche, PDF e backup.

Motivazione:

Lo sprint corregge i primi blocchi emersi dal test manuale senza alterare l'architettura Provider -> Repository -> Drift o introdurre feature fuori perimetro.

Stato finale: completato con verifiche statiche e test Flutter.
