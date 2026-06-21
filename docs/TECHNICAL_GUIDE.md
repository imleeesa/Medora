# Guida tecnica - Meditrack

Questo documento descrive l'architettura attuale di Meditrack e le linee guida per mantenerlo ed evolverlo. E' pensato per sviluppatori che prenderanno in carico il progetto in futuro.

## Architettura del progetto

Meditrack e' un'app Flutter basata su una struttura semplice:

- UI costruita con widget Flutter e Material 3.
- Stato applicativo gestito con Provider e `ChangeNotifier`.
- Dati temporanei mantenuti in memoria.
- Model di dominio gia' predisposti per serializzazione JSON.
- Base database locale Drift predisposta ma non ancora collegata alla UI.
- Servizio notifiche locali separato dalla UI.

Il punto centrale dello stato e' `MedicineProvider`, registrato in `main.dart` tramite `ChangeNotifierProvider`. Le schermate leggono i dati con `Consumer<MedicineProvider>` e invocano metodi del provider per modificare lo stato.

```text
main.dart
  -> ChangeNotifierProvider
    -> MyApp
      -> DashboardScreen
        -> screens
          -> MedicineProvider
            -> models
            -> services futuri
```

## Organizzazione delle cartelle

```text
lib/
├── main.dart
├── app.dart
├── data/
├── models/
├── providers/
├── repositories/
├── screens/
├── services/
└── widgets/
```

### `lib/main.dart`

Contiene l'entry point dell'app. Inizializza Flutter e registra `MedicineProvider` come provider globale.

Responsabilita':

- chiamare `WidgetsFlutterBinding.ensureInitialized()`;
- creare il provider principale;
- avviare `MyApp`.

### `lib/app.dart`

Contiene la configurazione dell'app Flutter.

Responsabilita':

- configurare `MaterialApp`;
- definire tema chiaro e tema scuro;
- disabilitare il banner debug;
- impostare `DashboardScreen` come schermata iniziale.

Nota: il profilo contiene una preferenza `isDarkMode`, ma `themeMode` e' attualmente impostato a `ThemeMode.light`. Il supporto completo al tema scuro e' pianificato, non ancora operativo; nelle impostazioni il controllo e' disabilitato per evitare un toggle senza effetto reale.

### `lib/models/`

Contiene le entita' di dominio. I model rappresentano i dati principali dell'app e devono rimanere il piu' possibile indipendenti dalla UI.

File attuali:

- `medicine.dart`
- `therapy.dart`
- `intake_record.dart`
- `user_profile.dart`

### `lib/data/`

Contiene la base tecnica del database locale Drift.

File attuali:

- `local_database.dart`;
- `local_database.g.dart`;
- `database_service.dart`;
- `tables/user_profiles_table.dart`;
- `tables/app_settings_table.dart`;
- `tables/therapies_table.dart`;
- `tables/medicines_table.dart`;
- `tables/medicine_schedules_table.dart`;
- `tables/intake_records_table.dart`.

Il layer e' stato introdotto nello Sprint Database 1 e viene usato dai repository creati nello Sprint Database 2. Non e' ancora collegato a `MedicineProvider` o alle schermate, quindi il comportamento dell'app resta basato su dati in memoria.

### `lib/repositories/`

Contiene il layer che incapsula query e transazioni del database locale. I repository dipendono da `DatabaseService`, non dalla UI o dal Provider.

File attuali:

- `profile_repository.dart`;
- `settings_repository.dart`;
- `therapy_repository.dart`;
- `medicine_repository.dart`;
- `intake_repository.dart`.

Il layer non e' ancora iniettato in `MedicineProvider`. In questa fase espone le righe e i companion generati da Drift, per evitare mapper incompleti finche' i model di dominio non saranno allineati completamente allo schema persistente.

### `lib/providers/`

Contiene lo state management.

File attuale:

- `medicine_provider.dart`

Il provider gestisce lo stato temporaneo e notifica la UI quando i dati cambiano.

### `lib/screens/`

Contiene le schermate principali dell'app.

File attuali:

- `dashboard_screen.dart`
- `medicines_screen.dart`
- `add_medicine_screen.dart`
- `medicine_detail_screen.dart`
- `history_screen.dart`
- `stock_screen.dart`
- `profile_screen.dart`
- `settings_screen.dart`

### `lib/widgets/`

Contiene widget riutilizzabili e componenti comuni.

File attuali:

- `primary_button.dart`
- `medicine_card.dart`
- `empty_state.dart`
- `dashboard_card.dart`

### `lib/services/`

Contiene servizi applicativi che non dovrebbero dipendere direttamente dalla UI.

File attuale:

- `notification_service.dart`

Il servizio notifiche inizializza `flutter_local_notifications`, gestisce permessi e pianificazione di promemoria locali. Al momento e' presente ma non ancora collegato in modo completo alla creazione e modifica delle medicine.

## Responsabilita' dei model

### `Medicine`

Rappresenta una medicina programmata.

Responsabilita':

- identificativo univoco;
- nome e dosaggio;
- note opzionali;
- orari di assunzione;
- giorni della settimana;
- quantita' disponibile;
- soglia di avviso;
- stato attivo/inattivo;
- colore e icona opzionale;
- collegamento al profilo;
- date di creazione e aggiornamento;
- calcolo se la medicina e' prevista oggi;
- calcolo della prossima assunzione nella giornata;
- serializzazione e deserializzazione JSON.

### `Therapy`

Rappresenta un raggruppamento di medicine.

Responsabilita':

- identificativo;
- nome;
- colore;
- lista di medicine associate;
- stato attivo/inattivo;
- copia immutabile tramite `copyWith`.

In futuro il model potra' essere separato dalla lista completa di medicine e usare relazioni tramite ID, piu' adatte a un database.

### `IntakeRecord`

Rappresenta una singola assunzione prevista o registrata.

Responsabilita':

- identificativo;
- riferimento alla medicina;
- data e ora programmate;
- data e ora effettive;
- stato dell'assunzione;
- note opzionali;
- serializzazione JSON.

Questo model e' gia' pronto per alimentare lo storico, ma non e' ancora integrato nel flusso principale dell'app.

### `UserProfile`

Rappresenta il profilo utente locale.

Responsabilita':

- identificativo;
- nome;
- email e foto opzionali;
- preferenza tema scuro;
- lingua;
- preferenza notifiche;
- date di creazione e aggiornamento;
- serializzazione JSON.

## Responsabilita' degli screen

### `DashboardScreen`

Schermata principale con navigazione inferiore.

Responsabilita':

- gestire la tab selezionata;
- mostrare Home, Terapie, Storico e Profilo tramite `IndexedStack`;
- mostrare prossima medicina, terapie attive, riepilogo giornata e avvisi;
- aprire la schermata di aggiunta medicina.

### `MedicinesScreen`

Schermata dedicata all'elenco di terapie e medicine.

Responsabilita':

- visualizzare le terapie;
- filtrare per nome terapia o medicina;
- aprire il dettaglio medicina;
- attivare/disattivare medicine;
- eliminare medicine dalla sessione corrente;
- aprire il form di aggiunta.

### `AddMedicineScreen`

Form di inserimento di una nuova medicina.

Responsabilita':

- validare terapia, nome, dosaggio, orari, giorni e quantita';
- permettere selezione di colore e note;
- chiamare `MedicineProvider.addMedicine`;
- mostrare feedback di successo o errore.

### `MedicineDetailScreen`

Schermata di dettaglio di una medicina.

Responsabilita':

- mostrare nome, dosaggio e stato;
- mostrare orari e giorni di assunzione;
- mostrare quantita' e soglia minima;
- mostrare note se presenti.

### `HistoryScreen`

Schermata predisposta per lo storico.

Responsabilita' attuali:

- mostrare uno stato vuoto;
- differenziare il messaggio in base alla presenza di medicine.

Responsabilita' future:

- visualizzare assunzioni registrate;
- filtrare per periodo, terapia e medicina;
- supportare statistiche e report.

### `StockScreen`

Schermata di monitoraggio delle scorte.

Responsabilita':

- mostrare tutte le medicine;
- evidenziare scorte basse;
- mostrare progresso visivo rispetto alla soglia.

### `ProfileScreen`

Schermata profilo.

Responsabilita':

- mostrare il profilo corrente;
- mostrare numero di terapie;
- collegare a Scorte e Impostazioni.

### `SettingsScreen`

Schermata impostazioni.

Responsabilita':

- gestire preferenza notifiche;
- mostrare il tema scuro come funzionalita' pianificata ma non ancora attivabile;
- mostrare voci predisposte per backup e report PDF con feedback utente, senza implementare ancora le feature.

## Responsabilita' dei widget

### `PrimaryButton` e `SecondaryButton`

Componenti per azioni principali e secondarie.

Responsabilita':

- stile coerente dei pulsanti;
- stato loading;
- icona opzionale;
- stato abilitato/disabilitato.

### `MedicineCard`

Card riutilizzabile per mostrare una medicina.

Responsabilita':

- nome e dosaggio;
- stato attivo/inattivo;
- prossima assunzione;
- scorte e avviso;
- orari;
- azioni opzionali di toggle ed eliminazione.

Nota: alcune schermate usano implementazioni locali invece di questo widget. In futuro si puo' valutare un consolidamento per ridurre duplicazioni.

### `EmptyState`

Widget per stati vuoti.

Responsabilita':

- icona;
- titolo;
- descrizione;
- bottone opzionale.

### `DashboardCard`

Card generica per metriche di dashboard.

Responsabilita':

- titolo;
- valore;
- icona;
- colore;
- azione opzionale.

## State management

Lo state management usa Provider.

`MedicineProvider` estende `ChangeNotifier` e mantiene:

- lista privata `_therapies`;
- profilo corrente `_currentProfile`;
- stato `_isLoading`.

Espone:

- `therapies`;
- `medicines`;
- `currentProfile`;
- `isLoading`.

Metodi principali:

- `init`;
- `addMedicine`;
- `updateMedicine`;
- `deleteMedicine`;
- `toggleMedicineActive`;
- `decrementStock`;
- `updateProfile`;
- `getMedicinesTodayDue`;
- `getNextMedicine`;
- `getLowStockMedicines`.

Ogni modifica allo stato chiama `notifyListeners()`, causando l'aggiornamento delle schermate che consumano il provider.

## Flusso principale dell'app

1. `main.dart` avvia l'app e registra `MedicineProvider`.
2. `MyApp` configura tema e schermata iniziale.
3. `DashboardScreen` mostra la navigazione principale.
4. L'utente apre il form di aggiunta medicina.
5. `AddMedicineScreen` valida i dati inseriti.
6. Il form chiama `MedicineProvider.addMedicine`.
7. Il provider crea o riusa una terapia e aggiunge la medicina.
8. Il provider chiama `notifyListeners()`.
9. Dashboard, elenco terapie, profilo e scorte si aggiornano.

## Gestione temporanea dei dati

Attualmente i dati sono conservati solo in memoria:

- le terapie sono nella lista `_therapies`;
- le medicine sono contenute dentro ogni `Therapy`;
- il profilo e' un oggetto locale inizializzato nel provider;
- lo storico non viene ancora popolato;
- le preferenze non vengono salvate su disco.

Conseguenza: al riavvio dell'app i dati inseriti vengono persi.

Questa scelta e' accettabile per la fase prototipale, ma deve essere sostituita da persistenza locale prima di un uso reale.

## Introduzione futura del database

La futura persistenza dovrebbe essere introdotta senza appesantire le schermate.

Approccio consigliato:

1. Aggiungere un layer `repositories/`.
2. Aggiungere un layer `data/` o `database/` per accesso tecnico al database.
3. Spostare lettura e scrittura dal provider ai repository.
4. Mantenere il provider come coordinatore dello stato UI.
5. Usare i metodi `toJson` e `fromJson` dei model come base iniziale.
6. Definire tabelle o collection per profili, terapie, medicine e assunzioni.
7. Introdurre migrazioni versionate.

Esempio di struttura futura:

```text
lib/
├── data/
│   ├── local_database.dart
│   └── migrations/
├── repositories/
│   ├── medicine_repository.dart
│   ├── therapy_repository.dart
│   ├── intake_repository.dart
│   └── profile_repository.dart
├── providers/
└── models/
```

Relazioni consigliate:

- `profiles` 1 -> N `therapies`;
- `therapies` 1 -> N `medicines`;
- `medicines` 1 -> N `intake_records`;
- `profiles` 1 -> N `intake_records`, se si vuole filtrare rapidamente per profilo.

## Database locale - piano di introduzione

Questa sezione definisce il piano tecnico per introdurre la persistenza locale. Lo Sprint Database 1 ha creato la base Drift e le tabelle principali; lo Sprint Database 2 ha aggiunto i repository. Il database non e' ancora collegato a Provider o schermate.

### Stato attuale

I dati sono gestiti in memoria da `MedicineProvider`.

Dati mantenuti oggi:

- `_therapies`: lista di `Therapy`, ognuna con una lista annidata di `Medicine`;
- `_currentProfile`: profilo locale corrente;
- `_isLoading`: stato UI temporaneo.

Operazioni oggi gestite dal provider:

- `addMedicine`: crea una medicina e crea/riusa una terapia in base al nome;
- `updateMedicine`: aggiorna una medicina dentro la terapia che la contiene;
- `deleteMedicine`: elimina una medicina e rimuove la terapia se resta vuota;
- `toggleMedicineActive`: abilita/disabilita una medicina;
- `decrementStock`: scala la quantita' disponibile;
- `updateProfile`: aggiorna preferenze e nome profilo;
- `getMedicinesTodayDue`, `getNextMedicine`, `getLowStockMedicines`: calcolano viste derivate per la UI.

Con il database, le operazioni di lettura/scrittura dovranno spostarsi verso repository dedicati. Il provider dovra' restare il coordinatore dello stato UI, non il proprietario della persistenza.

### Sprint Database 1 - base Drift

File creati:

- `lib/data/local_database.dart`: definisce `LocalDatabase`, registra le tabelle Drift e apre il file SQLite locale `meditrack.sqlite`;
- `lib/data/local_database.g.dart`: file generato da Drift tramite `build_runner`;
- `lib/data/database_service.dart`: punto centrale preparato per accedere al database, senza ancora collegarlo all'app;
- `lib/data/tables/user_profiles_table.dart`;
- `lib/data/tables/app_settings_table.dart`;
- `lib/data/tables/therapies_table.dart`;
- `lib/data/tables/medicines_table.dart`;
- `lib/data/tables/medicine_schedules_table.dart`;
- `lib/data/tables/intake_records_table.dart`.

Dipendenze aggiunte:

- `drift`;
- `sqlite3_flutter_libs`;
- `path_provider`;
- `path`;
- `drift_dev`;
- `build_runner`.

Nota versioni: il progetto usa Dart 3.8.0. Per questo le dipendenze sono state impostate su versioni compatibili con la toolchain attuale; le release piu' recenti di alcuni pacchetti richiedono Dart 3.10 o superiore.

Tabelle definite:

- `user_profiles`: profilo locale utente;
- `app_settings`: preferenze associate al profilo;
- `therapies`: terapie raggruppatrici;
- `medicines`: medicine, con collegamento opzionale alla terapia;
- `medicine_schedules`: una riga per ogni combinazione medicina, giorno e orario;
- `intake_records`: storico assunzioni con snapshot di nome e dose.

Il database non e' ancora collegato alla UI per scelta progettuale. In questo modo il comportamento attuale resta invariato e il prossimo sprint puo' concentrarsi sui repository senza mescolare generazione schema, migrazione Provider e modifiche schermate.

### Sprint Database 2 - repository layer

Il repository layer separa Provider e database: contiene query, ordinamenti e transazioni, mentre il Provider futuro restera' responsabile di stato UI, loading ed errori mostrati all'utente.

Repository creati:

- `ProfileRepository`: recupero del profilo corrente o per ID, creazione e aggiornamento;
- `SettingsRepository`: lettura e upsert delle impostazioni per profilo;
- `TherapyRepository`: stream e lettura delle terapie, creazione, aggiornamento ed eliminazione transazionale con scollegamento delle medicine;
- `MedicineRepository`: stream e lettura delle medicine, filtro per terapia, gestione scorte, orari e cancellazione transazionale che conserva lo storico;
- `IntakeRepository`: lettura dello storico per profilo o medicina, creazione e aggiornamento dei record.

I repository non sono ancora collegati a `MedicineProvider`, non eseguono seed automatici e non cambiano il comportamento dell'app. Espongono temporaneamente le entita' generate da Drift e i relativi companion: i mapper verso `Medicine`, `Therapy`, `IntakeRecord` e `UserProfile` sono rimandati perche' gli attuali model non coprono ancora tutti i campi dello schema locale.

Prossimo step previsto: allineare i model allo schema o introdurre mapper completi, aggiungere test repository e collegare gradualmente `MedicineProvider` al database.

### Database consigliato

Database consigliato: Drift.

Motivazione:

- il dominio dell'app e' relazionale: terapie, medicine, orari, storico, profili e impostazioni hanno collegamenti chiari;
- servono query filtrate per data, terapia, medicina, profilo, scorte basse e prossime assunzioni;
- servono migrazioni versionate e controllabili;
- gli orari multipli e lo storico sono piu' robusti come tabelle normalizzate rispetto a stringhe serializzate;
- Drift permette di mantenere SQLite come base locale, con query tipizzate e stream reattivi utili per dashboard e liste.

Alternative valutate:

- `sqflite`: solido e diretto, ma richiede piu' codice manuale per query, mapping e migrazioni;
- `hive`: ottimo per key-value e preferenze semplici, meno adatto a relazioni e query articolate;
- `isar`: performante e orientato a oggetti, ma per questo progetto il modello relazionale e le migrazioni SQL esplicite sono piu' prevedibili.

### Architettura futura

Flusso desiderato:

```text
UI
  -> Provider
    -> Repository
      -> DatabaseService
        -> Database locale
```

Responsabilita':

- UI: mostra dati e invia azioni utente;
- Provider: espone stato alla UI, gestisce loading/errori, combina dati se necessario;
- Repository: contiene casi d'uso di lettura/scrittura per dominio;
- DatabaseService: apre il database, configura migrazioni e transazioni;
- Database locale: conserva tabelle e relazioni.

### Schema dati proposto

#### `user_profiles`

- `id` TEXT primary key;
- `name` TEXT not null;
- `email` TEXT nullable;
- `photo_url` TEXT nullable;
- `language` TEXT not null default `it`;
- `created_at` TEXT not null;
- `updated_at` TEXT not null.

#### `app_settings`

- `id` TEXT primary key;
- `profile_id` TEXT nullable, foreign key verso `user_profiles.id`;
- `is_dark_mode` INTEGER not null default 0;
- `notifications_enabled` INTEGER not null default 1;
- `created_at` TEXT not null;
- `updated_at` TEXT not null.

Nota: le impostazioni possono restare globali nella prima fase usando un record singolo, ma lo schema lascia spazio a profili multipli futuri.

#### `therapies`

- `id` TEXT primary key;
- `profile_id` TEXT not null, foreign key verso `user_profiles.id`;
- `name` TEXT not null;
- `color` TEXT not null;
- `is_active` INTEGER not null default 1;
- `created_at` TEXT not null;
- `updated_at` TEXT not null.

Indici consigliati:

- `profile_id`;
- `lower(name)` o normalizzazione applicativa per evitare duplicati visivi.

#### `medicines`

- `id` TEXT primary key;
- `therapy_id` TEXT not null, foreign key verso `therapies.id`;
- `profile_id` TEXT not null, foreign key verso `user_profiles.id`;
- `name` TEXT not null;
- `dose` TEXT not null;
- `notes` TEXT nullable;
- `stock_quantity` INTEGER not null;
- `stock_warning_threshold` INTEGER not null;
- `is_active` INTEGER not null default 1;
- `color` TEXT not null;
- `icon` TEXT nullable;
- `created_at` TEXT not null;
- `updated_at` TEXT not null.

Indici consigliati:

- `therapy_id`;
- `profile_id`;
- `is_active`;
- `stock_quantity`.

#### `medicine_schedules`

- `id` TEXT primary key;
- `medicine_id` TEXT not null, foreign key verso `medicines.id`;
- `weekday` INTEGER not null, valori 1-7;
- `hour` INTEGER not null, valori 0-23;
- `minute` INTEGER not null, valori 0-59;
- `is_active` INTEGER not null default 1;
- `created_at` TEXT not null;
- `updated_at` TEXT not null.

Indici consigliati:

- `medicine_id`;
- combinato `weekday, hour, minute`;
- vincolo logico su `medicine_id, weekday, hour, minute` per evitare duplicati.

Motivazione: gli orari e i giorni non dovrebbero restare serializzati dentro `Medicine`, perche' servono query su prossime assunzioni, notifiche e storico.

#### `intake_records`

- `id` TEXT primary key;
- `medicine_id` TEXT not null, foreign key verso `medicines.id`;
- `therapy_id` TEXT nullable, snapshot o foreign key verso `therapies.id`;
- `profile_id` TEXT not null, foreign key verso `user_profiles.id`;
- `scheduled_date_time` TEXT not null;
- `actual_date_time` TEXT nullable;
- `status` TEXT not null, valori previsti: `taken`, `missed`, `skipped`;
- `notes` TEXT nullable;
- `medicine_name_snapshot` TEXT nullable;
- `medicine_dose_snapshot` TEXT nullable;
- `created_at` TEXT not null;
- `updated_at` TEXT not null.

Indici consigliati:

- `medicine_id`;
- `profile_id`;
- `scheduled_date_time`;
- `status`.

Nota: gli snapshot aiutano a conservare uno storico leggibile anche se una medicina viene rinominata o cancellata.

### File da creare o completare in futuro

Le strutture `lib/data/` e `lib/repositories/` esistono gia'. In futuro andranno completate con mapper, test e migrazioni.

Possibile struttura evolutiva:

```text
lib/
  data/
    local_database.dart
    database_service.dart
    migrations/
    tables/
      therapies_table.dart
      medicines_table.dart
      medicine_schedules_table.dart
      intake_records_table.dart
      user_profiles_table.dart
      app_settings_table.dart
    mappers/
      medicine_mapper.dart
      therapy_mapper.dart
  repositories/
    therapy_repository.dart
    medicine_repository.dart
    intake_repository.dart
    profile_repository.dart
    settings_repository.dart
```

Eventuali file di supporto:

- mapper tra righe database e model di dominio;
- test repository/database;
- fixture o seed per profilo locale iniziale.

### File da modificare in futuro

- `pubspec.yaml`: aggiornare dipendenze database solo quando sara' necessario un upgrade della toolchain o di Drift;
- `lib/main.dart`: inizializzare `DatabaseService` e repository;
- `lib/providers/medicine_provider.dart`: sostituire lo stato puramente in memoria con caricamento/salvataggio tramite repository;
- `lib/models/medicine.dart`: rimuovere o limitare la serializzazione compatta di `times` e `daysOfWeek`;
- `lib/models/therapy.dart`: valutare separazione tra `Therapy` pura e aggregato `TherapyWithMedicines`;
- `lib/models/intake_record.dart`: allineare status e campi snapshot;
- `lib/models/user_profile.dart`: separare preferenze app da dati profilo, se necessario;
- schermate che leggono liste e dettagli: mantenere la UI invariata, ma leggere dati dal provider aggiornato.

### Strategia di migrazione

Fase consigliata:

1. Introdurre tabelle e database service senza collegare subito la UI. Stato: completato nello Sprint Database 1.
2. Creare repository per operazioni base. Stato: completato nello Sprint Database 2; i test repository restano da aggiungere.
3. Allineare i model di dominio allo schema o introdurre mapper completi.
4. Aggiungere seed del profilo locale `local-user` solo durante il collegamento al Provider.
5. Migrare `MedicineProvider.init` per caricare dati dal repository.
6. Spostare `addMedicine`, `updateMedicine`, `deleteMedicine`, `toggleMedicineActive`, `decrementStock`, `updateProfile` sui repository.
7. Integrare storico, scorte e notifiche solo dopo la persistenza base.

### Rischi e punti delicati

- Migrazione dati in memoria: in questa fase non ci sono dati persistenti da migrare, ma quando il database sara' introdotto bisognera' creare un profilo locale iniziale e gestire database vuoto.
- Giorni della settimana: oggi sono `List<int>` dentro `Medicine`; in futuro dovranno diventare righe in `medicine_schedules`.
- Orari multipli: oggi sono `List<TimeOfDay>`; in futuro ogni combinazione giorno/orario dovra' essere interrogabile e collegabile alle notifiche.
- Associazione medicine-terapie: oggi una terapia contiene medicine; nel database la relazione dovra' essere `therapy_id` dentro `medicines`.
- Storico assunzioni: non deve dipendere solo dalla medicina attuale; servono snapshot per conservare dati leggibili.
- Cancellazione medicine: prima di cancellare una medicina bisogna decidere se impedire la cancellazione quando esiste storico, fare soft delete o mantenere record storici con snapshot.
- Notifiche locali: gli ID notifica dovranno essere derivabili da `medicine_schedules`, non solo dalla medicina.
- Profili multipli futuri: tutte le query dovranno filtrare per `profile_id` anche se inizialmente esiste un solo profilo.

## Convenzioni di naming

Seguire le convenzioni Dart e Flutter:

- file e cartelle in `snake_case`;
- classi, enum e widget in `PascalCase`;
- variabili, metodi e parametri in `camelCase`;
- campi privati con prefisso `_`;
- widget privati di supporto con prefisso `_`;
- nomi descrittivi e coerenti con il dominio medico.

Esempi:

- `medicine_provider.dart`
- `MedicineProvider`
- `addMedicine`
- `_findMedicine`
- `_MedicineLocation`

Convenzioni consigliate per nuove feature:

- schermata: `feature_screen.dart`;
- provider: `feature_provider.dart`;
- repository futuro: `feature_repository.dart`;
- servizio: `feature_service.dart`;
- model: `feature.dart` o nome di dominio specifico.

## Linee guida per aggiungere nuove funzionalita'

Prima di aggiungere una nuova funzionalita':

- verificare se riguarda UI, stato, dati o servizio esterno;
- analizzare il codice esistente e rispettare pattern gia' presenti;
- mantenere i model indipendenti dalla UI;
- evitare logica di business complessa dentro gli screen;
- aggiungere metodi al provider solo se coordinano stato applicativo;
- creare widget riutilizzabili quando una UI viene ripetuta;
- preparare test per logiche di calcolo o trasformazione dati;
- non introdurre database, cloud o login senza una richiesta esplicita;
- mantenere lo stile verde/bianco medical-tech;
- aggiornare README e guida tecnica quando cambia l'architettura;
- aggiornare `docs/CHANGELOG_PROGRESS.md` per modifiche importanti;
- aggiornare `docs/KNOWN_ISSUES.md` quando emergono bug, discrepanze o limiti tecnici.

Flusso consigliato:

1. Definire il comportamento atteso.
2. Verificare quali model servono.
3. Aggiungere o aggiornare il provider.
4. Costruire la UI con widget piccoli e leggibili.
5. Collegare eventuali servizi esterni.
6. Verificare su emulatore e dispositivo.
7. Aggiornare la documentazione.
8. Riepilogare i file toccati.

## Linee guida responsive e tastiera

Le schermate con form lunghi devono essere progettate per schermi piccoli, tastiera aperta e dispositivi pieghevoli.

Regole consigliate:

- usare `SafeArea` nelle schermate che possono arrivare vicino ai bordi fisici del dispositivo;
- usare `SingleChildScrollView` o `ListView` per form e contenuti verticali lunghi;
- aggiungere padding inferiore legato a `MediaQuery.viewInsets.bottom` quando i bottoni sono in fondo al form;
- mantenere `resizeToAvoidBottomInset` esplicito nelle schermate con input;
- chiudere il focus/tastiera prima di navigare indietro da una schermata form;
- evitare `Expanded` o `Spacer` dentro contenuti scrollabili se non sono strettamente necessari;
- usare `LayoutBuilder` per trasformare righe affiancate in colonne sugli schermi stretti.

## Documentazione obbligatoria

Il progetto deve mantenere questi file:

- `README.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/KNOWN_ISSUES.md`.

### `README.md`

Deve descrivere:

- obiettivo dell'app;
- funzionalita' attuali;
- funzionalita' future;
- tecnologie usate;
- come avviare il progetto;
- stato attuale;
- roadmap.

Aggiornarlo quando cambia lo stato generale del progetto, la roadmap o il modo di avviare l'app.

### `docs/TECHNICAL_GUIDE.md`

Deve descrivere:

- architettura;
- cartelle;
- model;
- screen;
- provider e state management;
- widget;
- gestione dati in memoria;
- come aggiungere nuove funzionalita';
- futura integrazione database.

Aggiornarlo quando cambiano architettura, responsabilita' dei moduli o flusso dati.

### `docs/CHANGELOG_PROGRESS.md`

Deve registrare ogni modifica importante con:

- data;
- tipo modifica;
- descrizione;
- file modificati;
- motivazione;
- stato.

Aggiornarlo alla fine di ogni blocco di lavoro significativo.

### `docs/KNOWN_ISSUES.md`

Deve contenere:

- bug;
- problemi;
- discrepanze;
- possibili cause;
- possibili soluzioni;
- stato del problema.

Aggiornarlo quando si trova un bug, quando un problema viene corretto o quando una discrepanza viene accettata temporaneamente.

## Linee guida specifiche per le prossime aree

### Sistema Terapie

La terapia deve diventare un'entita' gestibile autonomamente. Evitare che venga creata solo come effetto secondario dell'aggiunta di una medicina.

### Medicine

Le medicine dovrebbero poter essere modificate, spostate tra terapie e collegate alle notifiche. Ogni modifica rilevante deve aggiornare `updatedAt`.

### Storico

Lo storico dovrebbe usare `IntakeRecord`. Ogni assunzione programmata puo' generare un record, aggiornabile quando l'utente conferma o salta la dose.

### Scorte

La quantita' dovrebbe diminuire quando un'assunzione viene confermata. Le scorte dovrebbero supportare anche ricariche manuali.

### Notifiche

`NotificationService` dovrebbe essere inizializzato all'avvio e usato quando una medicina viene creata, aggiornata, disattivata o cancellata.

### Profili

Il campo `profileId` presente in `Medicine` e il model `UserProfile` preparano la strada a profili multipli. Ogni query futura dovra' filtrare i dati in base al profilo corrente.

### Report PDF

I report dovrebbero essere generati da dati persistenti e non direttamente dalla UI. Il formato dovrebbe includere profilo, terapie, medicine, dosaggi, storico e intervallo temporale.

### Backup Cloud

Il backup richiedera' una strategia chiara su autenticazione, sicurezza dei dati sanitari, conflitti e ripristino. Prima del cloud e' consigliabile consolidare il database locale.

## Stato tecnico attuale

Punti solidi:

- struttura cartelle chiara;
- model separati dalla UI;
- Provider centralizzato;
- UI principale gia' navigabile;
- predisposizione per database e notifiche.

Limiti attuali:

- dati non persistenti;
- storico non ancora operativo;
- notifiche non ancora integrate nel flusso principale;
- terapie gestite indirettamente tramite aggiunta medicina;
- alcune componenti UI sono duplicate localmente nelle schermate;
- tema scuro predisposto nel profilo ma non ancora applicato all'interfaccia.

## Note di manutenzione

- Non introdurre nuove feature direttamente negli screen se richiedono stato condiviso.
- Evitare di accoppiare il database futuro ai widget.
- Mantenere i model serializzabili e testabili.
- Aggiornare questa guida quando vengono introdotti repository, database o nuove aree funzionali.
- Prima di rilasciare una versione utilizzabile, implementare persistenza, test e gestione completa delle notifiche.
