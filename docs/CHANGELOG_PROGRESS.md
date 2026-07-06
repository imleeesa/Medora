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

## 2026-07-06 - Sprint Statistiche Base

Tipo modifica: Feature / UX / Test / Documentation.

Descrizione:

- aggiunta schermata `Statistiche`, accessibile dalla schermata Storico;
- aggiunto `HistoryStatisticsService` per calcolare statistiche in memoria senza query Drift dedicate;
- calcolati totale record, assunte, saltate, dimenticate e percentuale di aderenza;
- aggiunti riepiloghi per oggi, ultimi 7 giorni, ultimi 30 giorni e tutto lo storico;
- aggiunti breakdown per medicina, incluse medicine eliminate tramite snapshot nome;
- aggiunti breakdown per terapia quando il record e' ancora attribuibile a una terapia corrente;
- aggiunto empty state quando non esiste storico.

File modificati:

- `README.md`;
- `lib/screens/history_screen.dart`;
- `lib/screens/statistics_screen.dart`;
- `lib/services/history_statistics_service.dart`;
- `test/history_statistics_service_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- assenza di una vista sintetica sull'aderenza terapeutica;
- mancanza di calcoli testabili su aderenza, periodi e breakdown.

Problemi rimandati:

- grafici, export, report PDF e statistiche avanzate;
- attribuzione certa per terapia dei record relativi a medicine eliminate, da risolvere con snapshot terapia o soft delete.

Motivazione:

Lo sprint introduce statistiche utili e leggibili senza modificare database, repository, notifiche, storico o scorte.

Stato finale: completato con `dart format lib test`, `dart analyze`, `flutter analyze`, `flutter test` e `flutter build apk --debug` superati.

## 2026-07-06 - Sprint Filtri Storico

Tipo modifica: Feature / UX / Test / Documentation.

Descrizione:

- aggiunti filtri in memoria alla schermata Storico per stato, periodo, terapia e medicina;
- aggiunto reset filtri e stato vuoto dedicato quando nessun record corrisponde alla selezione;
- mantenuto l'ordine cronologico con record piu' recenti prima;
- aggiunto `HistoryFilterService` per isolare e testare la logica di filtro senza query Drift dedicate;
- supportato il filtro medicina anche per record di medicine eliminate tramite snapshot del nome;
- documentato il limite del filtro terapia sui record di medicine eliminate, perche' lo storico non conserva uno snapshot terapia.

File modificati:

- `README.md`;
- `lib/screens/history_screen.dart`;
- `lib/services/history_filter_service.dart`;
- `test/history_filter_service_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- storico difficile da consultare quando contiene molti record;
- mancanza di filtri combinabili per stato, periodo, terapia e medicina;
- assenza di copertura automatica sulla logica di filtro.

Problemi rimandati:

- filtro terapia affidabile per record di medicine eliminate o terapie eliminate, da valutare con snapshot terapia o soft delete;
- statistiche, grafici, export e report restano fuori perimetro.

Motivazione:

Lo sprint migliora l'usabilita' dello storico senza modificare schema database, repository o comportamento di notifiche, scorte e missed planner.

Stato finale: completato con `dart analyze`, `flutter analyze`, `flutter test` e build APK debug superati.

## 2026-07-05 - QA breve Schedule avanzati

Tipo modifica: QA / Test / Documentation.

Descrizione:

- verificata la stabilita' degli schedule avanzati dopo il fix del prodotto cartesiano giorni/orari;
- aggiunti test di dominio per `Medicine.shouldTakeOn` e `Medicine.getNextIntakeFor`, cosi' gli helper sono verificabili con una data esplicita;
- aggiunta copertura Provider per due slot reali nello stesso giorno, con storico e scorte indipendenti;
- aggiunta copertura per modifica schedule: gli slot vecchi non restano in Dashboard e le notifiche vengono cancellate/ripianificate sul nuovo slot reale;
- confermati i test gia' presenti su Dashboard domenica 15:33, notifiche reali, missed planner e payload notifica non reale ignorato.

File modificati:

- `lib/models/medicine.dart`;
- `test/medicine_test.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- nessun nuovo bug trovato durante il QA;
- rafforzata la copertura contro regressioni future sugli slot inventati.

Problemi rimandati:

- nessuno per questo sprint QA.

Motivazione:

Lo sprint consolida la regola tecnica secondo cui `medicine.schedules` e' l'unica fonte operativa degli slot, mentre `times` e `daysOfWeek` restano campi derivati di compatibilita'.

Stato finale: completato con `dart analyze`, `flutter analyze`, `flutter test` e build APK debug superati.

## 2026-07-05 - Bug fix urgente Schedule avanzati

Tipo modifica: Bug Fix / Test / Documentation.

Descrizione:

- corretto il calcolo della `Prossima Medicina` in Dashboard per usare lo slot reale `ScheduledIntake`;
- impedito il prodotto cartesiano tra `Medicine.times` e `Medicine.daysOfWeek` nei calcoli di oggi/prossima assunzione;
- aggiornati gli helper del model `Medicine` per leggere gli schedule attivi reali;
- verificato che notifiche, missed planner e azioni rapide lavorino su combinazioni atomiche `medicineId + dayOfWeek + hour + minute`;
- aggiunti test sul caso reale `Lun/Sab -> 15:30, 15:35` e `Mar/Dom -> 14:30, 16:35`.

File modificati:

- `lib/models/medicine.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/dashboard_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `test/missed_intake_planner_test.dart`;
- `test/notification_action_handler_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- Dashboard poteva mostrare `Dom 15:35` anche se lo slot reale era solo `Lun/Sab 15:35`;
- le card medicina potevano calcolare la prossima assunzione usando campi derivati;
- mancanza di test espliciti contro combinazioni giorno/orario inventate.

Problemi rimandati:

- nessuno in questo sprint; restano futuri solo miglioramenti UX dell'editor programmazioni.

Motivazione:

Gli schedule avanzati richiedono che ogni logica applicativa usi solo slot atomici reali e tratti `times` e `daysOfWeek` come viste derivate di compatibilita'.

Stato finale: completato; nessuna modifica a database, schema Drift o redesign.

## 2026-07-05 - Sprint Schedule avanzati per medicina

Tipo modifica: Feature / Bug Fix / Test / Documentation.

Descrizione:

- introdotta nel form medicina la sezione `Programmazione assunzioni`, con card modificabili composte da giorni e orari propri;
- rimossa la limitazione operativa dei giorni globali applicati a tutti gli orari della medicina;
- mantenuta una singola medicina con piu' schedule interni, senza duplicare record medicina;
- il Provider accetta schedule espliciti, li normalizza e deduplica per combinazione giorno/orario;
- il database Drift non e' stato modificato: `medicine_schedules` supporta gia' righe atomiche `medicineId + dayOfWeek + hour + minute`;
- il dettaglio medicina raggruppa le programmazioni in modo leggibile, unendo giorni e orari equivalenti senza duplicati;
- la Dashboard usa gli schedule attivi sulla data richiesta e mostra slot separati della stessa medicina nello stesso giorno;
- storico, missed planner, notifiche e scorte basse continuano a lavorare sugli slot reali;
- aggiunti test per schedule multipli, deduplica, due slot nello stesso giorno, dettaglio raggruppato e missed planner multi-slot.

File modificati:

- `lib/providers/medicine_provider.dart`;
- `lib/screens/add_medicine_screen.dart`;
- `lib/screens/medicine_detail_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `test/missed_intake_planner_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- selezione giorni globale per tutti gli orari nel form medicina;
- rischio di duplicare medicine per rappresentare orari/giorni diversi;
- `getTodayScheduledIntakes(date:)` filtrava le medicine usando il giorno corrente invece della data richiesta.

Problemi rimandati:

- un editor calendario piu' ricco o template rapidi di programmazione;
- validazioni visuali piu' avanzate per conflitti tra programmazioni;
- eventuali statistiche su aderenza per singola programmazione.

Motivazione:

Lo sprint rende il modello `Terapie -> Medicine -> Programmazioni` piu' aderente all'uso reale senza cambiare schema database, notifiche, storico o scorte.

Stato finale: completato con `dart analyze`, `flutter analyze`, `flutter test` e build APK debug superati.

## 2026-07-03 - Sprint Medicine Detail: orari e modifica medicina

Tipo modifica: Bug Fix / Feature / UX / Test / Documentation.

Descrizione:

- corretto il dettaglio medicina per mostrare gli orari reali degli schedule una sola volta, senza duplicare lo stesso valore nella riga;
- il dettaglio medicina ora legge la versione aggiornata dal Provider, cosi' nome, dose, colore, scorte, giorni e note restano coerenti dopo modifiche o deep link;
- aggiunta azione `Modifica medicina` dal dettaglio con icona matita;
- esteso `AddMedicineScreen` in modalita' edit, con precompilazione dei campi e salvataggio tramite `MedicineProvider.updateMedicine`;
- preservato l'ID della medicina e mantenuto il cambio terapia nel flusso dedicato `Cambia terapia`;
- impedito l'inserimento duplicato dello stesso orario nel form;
- aggiornato il testo del form sulla quantita' per assunzione, ora usata dal decremento scorte quando interpretabile;
- aggiunti test widget per deduplica orari, apertura da Dashboard/deep link, modifica dal dettaglio e annullamento modifica.

File modificati:

- `lib/screens/medicine_detail_screen.dart`;
- `lib/screens/add_medicine_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- orari duplicati o ambigui nella sezione `Orari di Assunzione`;
- assenza di una vera azione di modifica medicina dal dettaglio;
- rischio di salvare orari duplicati dal form.

Problemi rimandati:

- modifica della terapia associata resta nel flusso separato `Cambia terapia`;
- gestione schedule con giorni diversi per singolo orario resta rappresentata nel form come selezione giorni globale, coerente con il flusso attuale;
- filtri o statistiche avanzate restano fuori perimetro.

Motivazione:

Lo sprint migliora il dettaglio medicina e abilita la modifica dei dati principali senza cambiare schema Drift, UI globale o comportamento di storico, scorte e notifiche.

Stato finale: completato con `dart analyze`, `flutter analyze`, `flutter test` e build APK debug superati.

## 2026-07-02 - Sprint Promemoria Scorte Basse e Dashboard cliccabile

Tipo modifica: Feature / UX / Test / Documentation.

Descrizione:

- aggiunta notifica locale immediata `Scorta bassa` quando una medicina attiva in terapia attiva attraversa la soglia minima dall'alto verso il basso;
- introdotto `MedicineNotificationScheduler` in un file dedicato per permettere a Provider e `IntakeActionService` di usare lo scheduler senza esporre classi plugin alla UI;
- aggiunto payload medicine-only per notifiche che devono aprire il dettaglio medicina senza rappresentare uno slot di assunzione;
- mantenute separate le azioni rapide `Assunta`/`Saltata` dai tap di navigazione;
- cancellata anche l'eventuale notifica scorta bassa quando vengono cancellate le notifiche di una medicina;
- rese cliccabili nella Dashboard la card Prossima Medicina e le card Assunzioni di oggi, senza interferire con i pulsanti Assunta/Saltata;
- aggiunti test per attraversamento soglia, toggle notifiche disattivato, azioni da notifica, payload medicine-only e navigazione Dashboard.

File modificati:

- `lib/services/medicine_notification_scheduler.dart`;
- `lib/services/notification_service.dart`;
- `lib/services/notification_payload.dart`;
- `lib/services/notification_navigation_service.dart`;
- `lib/services/notification_action_handler.dart`;
- `lib/services/intake_action_service.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/dashboard_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `test/notification_action_handler_test.dart`;
- `test/notification_service_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- assenza di promemoria locali per scorta bassa;
- rischio di notifiche duplicate continue quando una medicina resta sotto soglia;
- medicine nella Dashboard non cliccabili verso il dettaglio.

Problemi rimandati:

- promemoria di riacquisto avanzati e configurabili;
- rilevazione puntuale battery optimization Android/Samsung;
- deep link verso storico o flussi di correzione guidata.

Motivazione:

Lo sprint collega scorte, storico e notifiche senza modificare lo schema Drift e migliora la navigazione quotidiana dalla Dashboard.

Stato finale: completato con `dart analyze`, `flutter analyze`, `flutter test` e build APK debug superati.

## 2026-06-29 - Sprint Deep Link Notifiche

Tipo modifica: Feature / Stabilizzazione notifiche / Test / Documentation.

Descrizione:

- aggiunto `NotificationNavigationEvents` per convertire il tap normale sul corpo della notifica in una richiesta di navigazione verso una medicina;
- separato il flusso del tap normale dalle azioni rapide `Assunta` e `Saltata` usando `NotificationResponseType`;
- collegata `MyApp` a una `GlobalKey<NavigatorState>` per aprire `MedicineDetailScreen` dopo che `MedicineProvider` ha completato il caricamento;
- aggiunto `MedicineProvider.ensureInitialized()` per rendere sicura la navigazione quando l'app viene aperta da notifica;
- gestiti payload invalidi e medicine non piu' presenti senza crash e senza messaggi tecnici;
- aggiunti test per payload deep link, distinzione tap/azione e navigazione widget verso dettaglio medicina.

File modificati:

- `lib/app.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/services/notification_service.dart`;
- `lib/services/notification_navigation_service.dart`;
- `test/notification_navigation_service_test.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- tap sul corpo della notifica senza navigazione al dettaglio medicina;
- rischio di confondere tap normale e azioni rapide della notifica;
- assenza di un canale di navigazione testabile e indipendente dal servizio notifiche.

Problemi rimandati:

- deep link verso storico o flusso di correzione guidata;
- promemoria automatici per scorte basse;
- verifiche manuali Android su app chiusa/background e battery optimization Samsung.

Motivazione:

Lo sprint rende le notifiche piu' utili senza cambiare database, schema Drift o comportamento delle azioni rapide gia' operative.

Stato finale: completato con `dart analyze`, `flutter analyze`, `flutter test` e build APK debug superati.

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

## 2026-06-24 - Sprint Notifiche Locali 1

Tipo modifica: Feature / Provider integration / Documentation.

Descrizione:

- completato `NotificationService` con inizializzazione idempotente, timezone, richiesta permessi e pianificazione ricorrente;
- introdotti ID deterministici basati su medicina, giorno e orario;
- collegata la sincronizzazione a inizializzazione app, creazione, modifica, attivazione, disattivazione, archiviazione ed eliminazione di medicine e terapie;
- il toggle notifiche del profilo cancella tutti i reminder quando viene disabilitato e li ricrea quando viene riabilitato;
- aggiunti test per stabilita' degli ID e contenuto del promemoria;
- confermati permessi Android e receiver di boot gia' presenti nel manifest.

File modificati:

- `lib/services/notification_service.dart`;
- `lib/providers/medicine_provider.dart`;
- `test/notification_service_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- notifiche locali non inizializzate e non collegate al flusso medicine;
- assenza di una strategia idempotente per ID, cancellazione e ripianificazione.

Problemi rimandati:

- azioni rapide Assunta/Saltata e deep link dalla notifica;
- avvisi di scorta bassa;
- stato UI avanzato per permessi negati, timezone configurabile e battery optimization Android.

Motivazione:

Lo sprint introduce promemoria persistenti e ricorrenti senza far dipendere UI o storico dal plugin notifiche.

Stato finale: completato con `dart analyze`, `flutter analyze`, test Flutter e build APK debug superati; restano consigliate le verifiche manuali su dispositivo Android.

## 2026-06-26 - QA stabilizzazione notifiche locali

Tipo modifica: QA / Test / Documentation.

Descrizione:

- aggiunta una suite di test sul contratto tra `MedicineProvider` e `MedicineNotificationScheduler`;
- verificato che l'inizializzazione non ripianifichi piu' volte nello stesso lifecycle del Provider;
- verificati cancellazione e ripianificazione per modifica medicina, eliminazione, disattivazione e riattivazione;
- verificati archiviazione, riattivazione ed eliminazione terapia rispetto ai reminder delle medicine associate;
- verificato il toggle notifiche profilo: off cancella tutti i reminder, on ripianifica solo quelli attivi;
- verificato che errori o permessi negati del layer notifiche non blocchino salvataggi, startup o cache UI;
- confermati ID e testo notifica con dose e senza dose tramite i test esistenti di `NotificationService`.

File modificati:

- `test/medicine_provider_notification_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- assenza di copertura automatica sulle regole anti-duplicato e cancellazione/ripianificazione delle notifiche.

Problemi rimandati:

- azioni rapide Assunta/Saltata dalla notifica;
- deep link dalla notifica verso dettaglio o storico;
- UI dedicata per permessi negati, exact alarm non disponibile e battery optimization;
- promemoria automatici per scorte basse.

Motivazione:

Prima di aggiungere azioni rapide o notifiche piu' avanzate, era necessario stabilizzare il comportamento base e renderlo verificabile senza dipendere dal plugin nativo o da un dispositivo reale.

Stato finale: completato con test automatici verdi; restano richieste le verifiche manuali su dispositivo Android per ricezione reale, permessi ed exact alarm.

## 2026-06-26 - Sprint Notifiche Locali 2

Tipo modifica: Feature / Refactor leggero / Test / Documentation.

Descrizione:

- aggiunte azioni rapide `Assunta` e `Saltata` alle notifiche locali delle medicine;
- introdotto un payload JSON versionato con `medicineId`, giorno della settimana, ora e minuto;
- aggiunto `NotificationActionHandler` per gestire le azioni senza `BuildContext`, anche da background isolate quando supportato dal plugin;
- estratta la logica di registrazione assunzione e aggiornamento scorte in `IntakeActionService`, riusata sia dal Provider sia dalle notifiche;
- aggiunto listener Provider sugli eventi di azione notifica per ricaricare cache e storico quando l'app e' gia' aperta;
- registrato `ActionBroadcastReceiver` nel Manifest Android;
- aggiunti test per payload, azione Assunta, azione Saltata, anti-duplicato, decremento/ripristino scorte e scorta insufficiente.

File modificati:

- `android/app/src/main/AndroidManifest.xml`;
- `lib/models/intake_stock_change.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/dashboard_screen.dart`;
- `lib/services/intake_action_service.dart`;
- `lib/services/notification_action_handler.dart`;
- `lib/services/notification_payload.dart`;
- `lib/services/notification_service.dart`;
- `test/notification_action_handler_test.dart`;
- `test/notification_service_test.dart`;
- `README.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- notifiche locali senza azioni rapide Assunta/Saltata;
- logica assunzione/scorte vincolata al Provider e quindi non riutilizzabile dal callback notifica;
- assenza di payload sufficiente a ricostruire lo slot notificato;
- assenza del receiver Android richiesto dal plugin per le notification actions.

Problemi rimandati:

- deep link verso dettaglio medicina o storico;
- UI dedicata per permessi negati, exact alarm non disponibile e battery optimization;
- promemoria automatici per scorte basse;
- gestione perfetta di notifiche molto vecchie rimaste nel drawer: oggi viene ricostruito lo slot programmato piu' recente per giorno/orario.

Motivazione:

Lo sprint rende le notifiche locali utili nel flusso quotidiano, mantenendo separata la logica applicativa da UI e plugin nativo e riusando le regole gia' testate per storico e scorte.

Stato finale: completato con test automatici verdi; restano richieste verifiche manuali su dispositivo Android reale per background, app chiusa e permessi.

## 2026-06-26 - Bug fix live UI azioni notifica

Tipo modifica: Bug Fix / Test / Documentation.

Descrizione:

- corretto il mancato refresh live della UI dopo pressione di `Assunta` o `Saltata` dalla notifica locale;
- aggiunto un ponte tramite `IsolateNameServer` in `NotificationActionEvents`, cosi' il background isolate puo' notificare il main isolate quando l'app e' viva;
- il Provider registra la porta eventi durante l'inizializzazione e la rimuove in `dispose`;
- quando riceve l'evento, il Provider ricarica cache medicine/terapie, storico, scorte e assunzioni programmate e poi chiama `notifyListeners`;
- aggiunto un test Provider che simula un'azione notifica esterna e verifica aggiornamento immediato di storico e scorta senza riavvio.

File modificati:

- `lib/services/notification_action_handler.dart`;
- `lib/providers/medicine_provider.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- Dashboard, Storico e Scorte non si aggiornavano subito quando l'azione notifica veniva gestita in un background isolate mentre l'app era gia' aperta o ancora viva in background.

Problemi rimandati:

- deep link verso dettaglio medicina o storico;
- UI dedicata per permessi negati, exact alarm non disponibile e battery optimization;
- comportamento live non applicabile ad app completamente terminata: in quel caso la cache viene caricata correttamente al successivo avvio.

Motivazione:

Le notification actions Android senza UI possono essere eseguite su un isolate separato. Lo stream statico precedente funzionava solo nello stesso isolate e quindi non raggiungeva il Provider vivo.

Stato finale: completato con test automatici verdi; restano richieste verifiche manuali su dispositivo reale per foreground, background e app terminata.

## 2026-06-26 - Stabilizzazione notifiche vecchie

Tipo modifica: Bug Fix / Stabilizzazione / Test / Documentation.

Descrizione:

- aggiunta una protezione per evitare che una vecchia notifica rimasta nel drawer modifichi uno slot ambiguo;
- mantenuto il payload ricorrente con `medicineId`, `dayOfWeek`, `hour` e `minute`, documentando che non puo' contenere uno `scheduledDateTime` assoluto affidabile per tutte le ricorrenze;
- accettate le azioni notifica solo per slot ricostruiti di oggi o ieri;
- ignorate senza effetti le azioni quando lo slot sarebbe futuro, troppo vecchio, non compatibile con lo schedule attuale, riferito a medicina eliminata o terapia archiviata;
- mantenute invariate le regole anti-duplicato, decremento scorte e ripristino scorte;
- aggiunti test per notifiche valide, troppo vecchie, future, con schedule cambiato, medicina eliminata e terapia archiviata.

File modificati:

- `lib/services/intake_action_service.dart`;
- `lib/services/notification_action_handler.dart`;
- `lib/providers/medicine_provider.dart`;
- `test/notification_action_handler_test.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- una vecchia notifica poteva ricostruire uno slot recente diverso da quello inteso dall'utente e quindi modificare storico/scorte in modo ambiguo.

Problemi rimandati:

- deep link verso dettaglio medicina o storico;
- flusso UI guidato per correggere manualmente notifiche troppo vecchie;
- stato UI dedicato per permessi negati, exact alarm non disponibile e battery optimization.

Motivazione:

Le notifiche locali ricorrenti usano un payload statico. Senza un controllo temporale e di compatibilita' con lo schedule corrente, un tap tardivo poteva diventare ambiguo.

Stato finale: completato con test automatici verdi; restano consigliate verifiche manuali su dispositivo reale e Samsung Z Flip.

## 2026-06-24 - Bug fix mirato storico e ricarica scorte

Tipo modifica: Bug Fix / Documentation.

Descrizione:

- corretto il rollover delle assunzioni Dimenticate: gli slot precedenti alla creazione della medicina, dello schedule o alla data di inizio terapia non vengono piu' creati;
- mantenuti limite di sette giorni, esclusione della giornata corrente e protezione dai record duplicati;
- reso sicuro il dialog di ricarica scorte: raccoglie il valore, si chiude e solo dopo aggiorna Provider, database e cache;
- spostata la proprieta' del `TextEditingController` nel dialog, cosi' viene disposto solo dopo la sua rimozione effettiva;
- rimosso il listener non necessario dal root `MaterialApp` e stabilizzate le card scorte con chiavi per ID medicina;
- resa esplicita la soglia minima come avviso visivo: una ricarica valida non viene bloccata se la quantita' finale resta sotto soglia;
- evitato l'uso del contesto del dialog dopo una scrittura asincrona e la conseguente schermata rossa Flutter.

File modificati:

- `lib/services/missed_intake_planner.dart`;
- `test/missed_intake_planner_test.dart`;
- `lib/screens/stock_screen.dart`;
- `lib/app.dart`;
- `test/stock_screen_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

Problemi risolti:

- record `missed` falsi per slot antecedenti alla creazione di medicina o schedule;
- assert Flutter `_dependents.isEmpty` durante la ricarica manuale delle scorte, anche quando la scorta resta sotto soglia.

Problemi rimandati:

- filtri e statistiche storico;
- registro dedicato per ricariche e correzioni manuali delle scorte;
- notifiche locali, report, backup e cloud.

Motivazione:

Le correzioni eliminano due regressioni emerse dai test manuali senza alterare il dominio, lo schema Drift o i flussi UI esistenti.

Stato finale: completato con `dart analyze`, `flutter analyze` e test Flutter superati; restano consigliate le verifiche manuali su dispositivo.

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

## 2026-06-24 - Sprint Scorte decimali e ricarica manuale

Tipo modifica: Feature / Database migration / Documentation.

Descrizione:

- migrato lo schema Drift alla versione 2 con colonne `REAL` per quantita' e soglia delle scorte;
- preservati i dati v1 convertendo i valori interi esistenti in valori reali tramite `TableMigration`;
- esteso il parser dose a interi, frazioni e decimali con virgola o punto;
- aggiornati decremento, ripristino e controllo scorta insufficiente per quantità decimali;
- aggiunta ricarica manuale persistente dalla schermata Scorte;
- uniformata la visualizzazione delle quantita' senza decimali inutili.

File modificati:

- `lib/data/tables/medicines_table.dart`;
- `lib/data/local_database.dart`;
- `lib/data/local_database.g.dart`;
- `lib/models/medicine.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/repositories/intake_repository.dart`;
- `lib/screens/add_medicine_screen.dart`;
- `lib/screens/medicine_detail_screen.dart`;
- `lib/screens/stock_screen.dart`;
- `lib/widgets/medicine_card.dart`;
- `test/database_migration_test.dart`;
- `test/medicine_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- mancato decremento per dose frazionaria o decimale;
- assenza di ricarica manuale delle scorte;
- visualizzazione di valori come `10.0`.

Problemi rimandati:

- registro separato per ricariche e correzioni manuali;
- quantita' e unita' come campi strutturati invece di testo dose;
- notifiche di riacquisto, report e backup.

Motivazione:

La migrazione consente una gestione precisa delle scorte mantenendo compatibilita' con i dati locali gia' salvati.

Stato finale: completato con migrazione Drift, `dart analyze`, `flutter analyze` e test Flutter superati; restano consigliate le verifiche manuali su dispositivo.

## 2026-06-24 - Sprint Assunzioni dimenticate al cambio giorno

Tipo modifica: Feature / Provider integration / Documentation.

Descrizione:

- introdotto lo stato `missed` per rappresentare una dose dimenticata;
- aggiunto il rollover all'inizializzazione del Provider;
- creati record `missed` solo per slot programmati dei sette giorni precedenti senza record esistente;
- mantenuti snapshot di nome e dose e nessuna modifica alle scorte;
- aggiunta visualizzazione Dimenticata nello storico;
- mantenuto invariato il comportamento della Dashboard per le assunzioni della giornata corrente.

File modificati:

- `lib/models/intake_record.dart`;
- `lib/data/mappers/intake_record_mapper.dart`;
- `lib/repositories/intake_repository.dart`;
- `lib/services/missed_intake_planner.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/dashboard_screen.dart`;
- `lib/screens/history_screen.dart`;
- `test/intake_record_test.dart`;
- `test/missed_intake_planner_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- assunzioni passate non registrate e assenti dallo storico;
- assenza di uno stato dedicato per una dose dimenticata;
- rischio di duplicare record al riavvio, mitigato dal controllo medicina e orario previsto.

Problemi rimandati:

- recupero automatico di slot piu' vecchi di sette giorni;
- gestione delle assunzioni in ritardo;
- filtri, statistiche, notifiche, report e backup.

Motivazione:

Lo sprint completa il cambio giorno senza anticipare notifiche o modificare le assunzioni ancora recuperabili nella giornata corrente.

Stato finale: implementato, verifiche automatiche e manuali da completare.

## 2026-06-26 - Sprint UX permessi notifiche

Tipo modifica: UX / Stabilizzazione / Test / Documentation.

Descrizione:

- aggiunto `NotificationPermissionStatus` come model di dominio per esporre supporto notifiche locali, permesso notifiche Android ed exact alarm senza classi plugin nella UI;
- estesa l'interfaccia `MedicineNotificationScheduler` con lettura stato permessi e richieste esplicite per notifiche ed exact alarm;
- aggiunta in Impostazioni una sezione Notifiche con toggle app, stato permesso Android, stato exact alarm, azioni di aggiornamento/richiesta e nota su ottimizzazione batteria Android/Samsung;
- mantenuto il comportamento del toggle: off cancella i reminder, on prova a ripianificare i reminder attivi senza bloccare app o salvataggi se i permessi OS sono negati;
- aggiunti test Provider e widget per simulare permessi negati/concessi e verificare la sezione Impostazioni.

File modificati:

- `lib/models/notification_permission_status.dart`;
- `lib/services/notification_service.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/settings_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

Problemi risolti:

- l'utente non aveva una UX chiara per capire se i promemoria erano bloccati da permesso notifiche o exact alarm;
- il Provider non esponeva uno stato permessi testabile e leggibile dalla UI.

Problemi rimandati:

- deep link verso dettaglio medicina o storico;
- apertura diretta delle impostazioni Android specifiche senza introdurre una dipendenza dedicata;
- rilevazione puntuale della battery optimization, che dipende da sistema e produttore;
- promemoria automatici per scorte basse.

Motivazione:

Lo sprint rende comprensibile lo stato dei promemoria senza introdurre notifiche remote, redesign o nuove feature complesse.

Stato finale: completato con `dart analyze`, `flutter analyze`, `flutter test` e build APK debug superati.

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
