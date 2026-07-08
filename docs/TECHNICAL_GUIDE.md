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
- `notification_permission_status.dart`

### `lib/data/`

Contiene la base tecnica del database locale Drift.

File attuali:

- `local_database.dart`;
- `local_database.g.dart`;
- `database_service.dart`;
- `mappers/color_value_mapper.dart`;
- `mappers/user_profile_mapper.dart`;
- `mappers/settings_mapper.dart`;
- `mappers/therapy_mapper.dart`;
- `mappers/medicine_mapper.dart`;
- `mappers/intake_record_mapper.dart`;
- `tables/user_profiles_table.dart`;
- `tables/app_settings_table.dart`;
- `tables/therapies_table.dart`;
- `tables/medicines_table.dart`;
- `tables/medicine_schedules_table.dart`;
- `tables/intake_records_table.dart`.

Il layer e' stato introdotto nello Sprint Database 1, usato dai repository creati nello Sprint Database 2 e isolato da Drift tramite mapper nello Sprint Database 2.5. Non e' ancora collegato a `MedicineProvider` o alle schermate, quindi il comportamento dell'app resta basato su dati in memoria.

### `lib/repositories/`

Contiene il layer che incapsula query e transazioni del database locale. I repository dipendono da `DatabaseService`, non dalla UI o dal Provider.

File attuali:

- `profile_repository.dart`;
- `settings_repository.dart`;
- `therapy_repository.dart`;
- `medicine_repository.dart`;
- `intake_repository.dart`.

Il layer e' usato da `MedicineProvider`. Le API pubbliche dei repository ricevono e restituiscono model di dominio; le righe e i companion Drift restano confinati nei mapper e nei metodi privati.

### `lib/providers/`

Contiene lo state management.

File attuale:

- `medicine_provider.dart`

Il provider mantiene una cache in memoria per la UI, coordina repository e notifica le schermate quando i dati persistiti cambiano.

### `lib/screens/`

Contiene le schermate principali dell'app.

File attuali:

- `dashboard_screen.dart`
- `medicines_screen.dart`
- `add_medicine_screen.dart`
- `add_therapy_screen.dart`
- `therapy_detail_screen.dart`
- `medicine_detail_screen.dart`
- `history_screen.dart`
- `statistics_screen.dart`
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
- `therapy_card.dart`

### `lib/services/`

Contiene servizi applicativi che non dovrebbero dipendere direttamente dalla UI.

File attuale:

- `notification_service.dart`
- `notification_navigation_service.dart`
- `history_filter_service.dart`
- `history_statistics_service.dart`

Il servizio notifiche inizializza `flutter_local_notifications` e il timezone `Europe/Rome`, richiede i permessi solo quando il profilo abilita i promemoria e pianifica reminder ricorrenti. Espone l'interfaccia `MedicineNotificationScheduler`, cosi' `MedicineProvider` non dipende dal plugin e il comportamento puo' essere verificato con test di dominio. `NotificationNavigationEvents` trasforma il tap normale su una notifica in una richiesta di navigazione verso il dettaglio medicina, senza usare `BuildContext` dentro il servizio notifiche.

`HistoryFilterService` applica in memoria i filtri della schermata Storico su record gia' caricati dal Provider. Supporta filtri per stato, periodo, terapia e medicina, incluse medicine eliminate tramite snapshot del nome. Non introduce query Drift dedicate.

`HistoryStatisticsService` calcola statistiche in memoria partendo da `IntakeRecord` e dalla cache delle terapie. Espone totali, stati, aderenza, finestre temporali, breakdown per medicina/terapia e trend giornaliero senza usare classi Drift nella UI.

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
- aprire il dettaglio medicina dalla card Prossima Medicina e dalle assunzioni di oggi;
- aprire la schermata di aggiunta medicina.

### `MedicinesScreen`

Schermata dedicata all'elenco autonomo delle terapie.

Responsabilita':

- visualizzare le terapie;
- filtrare per nome terapia o medicina;
- aprire il dettaglio terapia;
- aprire il flusso di creazione terapia;
- mostrare descrizione, stato e numero medicine associate.

### `AddMedicineScreen`

Form di inserimento o modifica di una medicina.

Responsabilita':

- validare terapia, nome, dosaggio, orari, giorni e quantita';
- ricevere opzionalmente una terapia esistente per associare una medicina senza reinserirne il nome;
- ricevere opzionalmente una medicina esistente per aprirsi in modalita' edit;
- gestire una o piu' programmazioni interne, ognuna con giorni e orari propri;
- permettere selezione di colore e note;
- chiamare `MedicineProvider.addMedicine` / `addMedicineToTherapy` in creazione oppure `updateMedicine` in modifica;
- mantenere invariato `medicineId` durante la modifica e lasciare il cambio terapia al flusso dedicato `Cambia terapia`;
- convertire le programmazioni in `MedicineSchedule` e deduplicare gli slot giorno/orario prima del salvataggio;
- mostrare feedback di successo o errore.

### `AddTherapyScreen`

Form responsivo per creare o modificare una terapia.

Responsabilita':

- validare nome, descrizione opzionale, colore, icona e data inizio;
- chiamare `MedicineProvider.createTherapy` o `updateTherapy`;
- mantenere il form scrollabile con tastiera aperta.

### `TherapyDetailScreen`

Schermata di dettaglio per una terapia salvata.

Responsabilita':

- mostrare stato, descrizione, data inizio e medicine associate;
- aprire il form medicina con terapia gia' selezionata;
- modificare una terapia;
- archiviare terapie con medicine oppure eliminare in sicurezza terapie vuote.

### `MedicineDetailScreen`

Schermata di dettaglio di una medicina.

Responsabilita':

- mostrare nome, dosaggio e stato;
- mostrare programmazioni di assunzione usando gli schedule attivi della medicina corrente;
- mostrare quantita' e soglia minima;
- mostrare note se presenti;
- aprire il form di modifica della medicina;
- cambiare terapia o eliminare la medicina tramite azioni dedicate.

### `HistoryScreen`

Schermata dello storico assunzioni.

Responsabilita' attuali:

- mostrare le assunzioni registrate in ordine cronologico, con le piu' recenti prima;
- filtrare in memoria per stato, periodo, terapia e medicina;
- permettere reset dei filtri;
- mostrare uno stato vuoto quando non esistono record o quando i filtri non producono risultati;
- mantenere leggibili gli snapshot delle medicine eliminate.

Responsabilita' future:

- supportare note avanzate, correzioni manuali e report.

### `StatisticsScreen`

Schermata di statistiche base accessibile dallo Storico.

Responsabilita':

- mostrare aderenza generale;
- mostrare riepiloghi per oggi, ultimi 7 giorni, ultimi 30 giorni e tutto;
- mostrare conteggi per stato;
- mostrare statistiche per medicina, incluse medicine eliminate tramite snapshot;
- mostrare statistiche per terapia quando il record e' attribuibile a una terapia corrente;
- mostrare uno stato vuoto quando non esiste storico.

Responsabilita' future:

- grafici, trend, note avanzate, export e report.

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
- mostrare stato del permesso notifiche Android e exact alarm quando verificabile;
- permettere richiesta del permesso notifiche e aggiornamento dello stato;
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
- eventuale `_errorMessage` per errori di caricamento o salvataggio.

Espone:

- `therapies`;
- `medicines`;
- `currentProfile`;
- `isLoading`.
- `errorMessage`.

Metodi principali:

- `initialize` e `init` per compatibilita';
- `addMedicine`;
- `updateMedicine`;
- `deleteMedicine`;
- `toggleMedicineActive`;
- `decrementStock`;
- `updateProfile`;
- `createTherapy`;
- `updateTherapy`;
- `archiveTherapy`;
- `deleteTherapy`;
- `reactivateTherapy`;
- `getMedicinesByTherapy`;
- `getMedicineById` e `getTherapyById`;
- `addMedicineToTherapy`;
- `moveMedicineToTherapy`;
- `getMedicinesTodayDue`;
- `getNextMedicine`;
- `getLowStockMedicines`.

Ogni modifica allo stato chiama `notifyListeners()`, causando l'aggiornamento delle schermate che consumano il provider.

## Flusso principale dell'app

1. `main.dart` registra `MedicineProvider` e avvia `initialize`.
2. Il provider recupera o crea il profilo locale `local-user` e le impostazioni di default.
3. Il provider carica terapie, medicine e schedule dai repository Drift e ricostruisce la cache `_therapies`.
4. `MyApp` configura tema e schermata iniziale.
5. `DashboardScreen` mostra la navigazione principale quando il caricamento e' completo.
6. L'utente apre il form di aggiunta medicina.
7. `AddMedicineScreen` valida i dati inseriti e chiama `MedicineProvider.addMedicine`.
8. Il provider salva tramite repository, ricarica la cache e chiama `notifyListeners()`.
9. Dashboard, elenco terapie, profilo e scorte si aggiornano.

## Gestione dati e persistenza

Il Provider mantiene in memoria solo una cache destinata alla UI:

- le terapie sono nella lista `_therapies` con medicine gia' associate;
- il profilo corrente e' `_currentProfile`;
- loading ed errore restano stato UI temporaneo.

Terapie, medicine, schedule, profilo e impostazioni vengono ora letti e scritti nel database locale tramite repository. Al riavvio l'app ricostruisce la cache dal database, quindi medicine e terapie create dal flusso esistente restano disponibili.

Lo storico assunzioni base e' collegato al flusso persistente. Le notifiche locali base sono sincronizzate dal Provider senza modificare lo storico; backup resta fuori dal flusso principale.

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

Questa sezione definisce il piano tecnico per la persistenza locale. Lo Sprint Database 1 ha creato la base Drift e le tabelle principali, lo Sprint Database 2 ha aggiunto i repository, lo Sprint Database 2.5 ha allineato model e mapper e lo Sprint Database 3 ha collegato il Provider ai repository senza esporre Drift alla UI.

### Stato attuale

I dati persistiti sono coordinati da `MedicineProvider`, che conserva una cache in memoria per le schermate.

Dati mantenuti oggi:

- `_therapies`: lista di `Therapy`, ognuna con una lista annidata di `Medicine`;
- `_currentProfile`: profilo locale corrente;
- `_isLoading` e `_errorMessage`: stato UI temporaneo.

Operazioni oggi gestite dal provider:

- `addMedicine`: crea una medicina in una terapia esistente identificata da `therapyId`;
- `updateMedicine`: aggiorna una medicina dentro la terapia che la contiene;
- `deleteMedicine`: elimina una medicina senza eliminare automaticamente la terapia;
- `toggleMedicineActive`: abilita/disabilita una medicina;
- `decrementStock`: scala la quantita' disponibile;
- `updateProfile`: aggiorna preferenze e nome profilo;
- `getMedicinesTodayDue`, `getNextMedicine`, `getLowStockMedicines`: calcolano viste derivate per la UI.

Le operazioni di lettura e scrittura principali passano ora ai repository. Il Provider resta il coordinatore dello stato UI e non importa classi Drift generate.

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
- `IntakeRepository`: lettura dello storico per profilo o medicina, ricerca del record per medicina e orario previsto, creazione e aggiornamento dei record.

I repository non sono ancora collegati a `MedicineProvider`, non eseguono seed automatici e non cambiano il comportamento dell'app.

### Sprint Database 2.5 - model alignment e mapper layer

I mapper separano il dominio applicativo da Drift. La UI e il Provider continueranno a usare `Medicine`, `Therapy`, `IntakeRecord`, `UserProfile`, `AppSettings` e `MedicineSchedule`; solo mapper e repository conoscono righe, companion e query Drift.

Mapper creati:

- `UserProfileMapper` e `SettingsMapper`: convertono profilo e preferenze separate;
- `TherapyMapper`: converte status, colore e metadati della terapia;
- `MedicineMapper`: converte medicine, colore e `medicine_schedules`;
- `IntakeRecordMapper`: converte storico, snapshot e stato dell'assunzione;
- `ColorValueMapper`: centralizza la conversione tra colore hex UI e valore intero persistito.

`MedicineSchedule` mantiene una rappresentazione comoda per la UI: un orario con piu' giorni. Il mapper lo espande in una riga per combinazione giorno/orario quando salva e ricompone i gruppi quando legge. Lo stream delle medicine osserva sia `medicines` sia `medicine_schedules`.

Prossimo step previsto: aggiungere test repository, definire il seed del profilo locale e collegare gradualmente `MedicineProvider` ai repository, senza esporre Drift alla UI.

### Sprint Database 3 - Provider persistente

`MedicineProvider` usa `ProfileRepository`, `SettingsRepository`, `TherapyRepository` e `MedicineRepository`.

All'avvio `initialize` crea il profilo `local-user` con nome `Utente` solo se il database non contiene profili. Crea inoltre le impostazioni predefinite con tema `light` e notifiche abilitate se mancanti. Poi carica terapie e medicine, inclusi gli schedule normalizzati, e ricostruisce la cache usata dalla UI.

Le operazioni gia' esposte dal Provider ora persistono nel database: aggiunta, modifica, eliminazione, attivazione/disattivazione e decremento scorte delle medicine, creazione della terapia collegata al flusso di aggiunta, nome profilo e impostazioni esistenti. La prima terapia e la prima medicina vengono inserite nella stessa transazione.

Restano non persistiti nel flusso applicativo storico assunzioni, notifiche locali, backup/cloud e gestione avanzata delle terapie. Prossimo step consigliato: test repository e miglioramenti di gestione medicine tra terapie.

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
- `status` TEXT not null, valori previsti: `scheduled`, `taken`, `skipped`, `missed`;
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

Le strutture `lib/data/`, `lib/data/mappers/` e `lib/repositories/` esistono gia'. In futuro andranno completate con test e migrazioni.

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
3. Allineare i model di dominio allo schema e introdurre mapper completi. Stato: completato nello Sprint Database 2.5.
4. Aggiungere test repository e definire il seed del profilo locale `local-user`. Stato: seed completato nello Sprint Database 3; i test repository restano da aggiungere.
5. Migrare `MedicineProvider.init` per caricare dati dal repository. Stato: completato nello Sprint Database 3.
6. Spostare `addMedicine`, `updateMedicine`, `deleteMedicine`, `toggleMedicineActive`, `decrementStock`, `updateProfile` sui repository. Stato: completato nello Sprint Database 3.
7. Integrare storico, scorte e notifiche solo dopo la persistenza base.

### Rischi e punti delicati

- Migrazione dati in memoria: non esistevano dati persistenti da migrare. Il Provider crea il profilo locale iniziale e gestisce il database vuoto al primo avvio.
- Giorni della settimana e orari: mapper e Provider convertono da e verso `medicine_schedules`, mantenendo liste e schedule comodi per la UI.
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

Le terapie sono entita' autonome persistite. Possono essere create, modificate, aperte in dettaglio, archiviate e riattivate. L'eliminazione definitiva e' disponibile sia per terapie vuote sia per terapie con medicine: nel secondo caso richiede una conferma forte e cancella atomicamente medicine e schedule associati prima della terapia. Gli eventuali record di storico mantengono gli snapshot ma perdono il riferimento alla medicina eliminata. Eliminare una singola medicina non elimina mai automaticamente la terapia.

### Medicine

Ogni nuova medicina deve essere associata a una terapia esistente. Il form globale presenta un selettore terapia e, in assenza di terapie, indirizza prima alla loro creazione. Il Provider valida il relativo `therapyId`, cosi' la regola resta valida anche fuori dalla UI. Dal dettaglio medicina l'utente puo' scegliere `Modifica medicina` per aggiornare nome, dose, programmazioni, scorte, soglia, colore e note mantenendo lo stesso `medicineId`; puo' scegliere `Cambia terapia` per spostarla in una terapia attiva diversa, senza riattivare automaticamente quelle archiviate. La dose e' una stringa opzionale composta dal form tramite quantita' e unita' per assunzione; quando non definita, la UI mostra `Dose non specificata`. Questo valore non deve essere confuso con `stockQuantity`, che rappresenta la disponibilita' fisica residua. Ogni modifica rilevante deve aggiornare `updatedAt`.

Una medicina puo' avere piu' programmazioni interne. La UI le rappresenta come gruppi `giorni + orari`; il Provider le converte in `MedicineSchedule`, le normalizza e deduplica per combinazione `dayOfWeek + hour + minute`. Il database non richiede migrazioni per questo comportamento: `medicine_schedules` salva gia' righe atomiche per medicina, giorno e orario. `Medicine.times` e `Medicine.daysOfWeek` restano viste derivate/di compatibilita' basate sull'unione degli schedule reali.

Regola importante: la logica applicativa non deve ricostruire slot facendo il prodotto cartesiano tra `Medicine.times` e `Medicine.daysOfWeek`. Dashboard, assunzioni di oggi, missed planner, notifiche, azioni rapide e storico devono usare sempre gli schedule atomici reali `medicineId + dayOfWeek + hour + minute`. Questo evita combinazioni inesistenti, ad esempio `Dom 15:35` quando `15:35` appartiene solo a `Lun/Sab`.

Il dettaglio medicina non deve mescolare prossima assunzione calcolata e schedule reali. La sezione `Orari di Assunzione` deriva dagli schedule attivi, normalizza gli orari equivalenti, unisce i giorni associati e poi raggruppa le righe con stesso set di giorni, mostrando ad esempio `Lun, Mer, Ven - 08:00, 20:00`. Dashboard usa `MedicineProvider.getNextScheduledIntake()` e mostra l'orario del relativo `ScheduledIntake`, non il primo orario derivato della medicina. Dashboard, dettaglio terapia e deep link notifica passano solo l'ID/istanza iniziale: la schermata rilegge sempre la medicina corrente dal Provider per evitare dati obsoleti.

### Storico

Lo storico base usa `IntakeRecord` e `IntakeRepository`. Il Provider deriva le assunzioni previste dagli schedule attivi di oggi e crea o aggiorna un record quando l'utente segna una dose come `taken` o `skipped`; la stessa logica e' esposta da `IntakeActionService`, cosi' puo' essere usata anche dalle azioni delle notifiche senza dipendere dalla UI. La combinazione medicina e orario previsto evita duplicati. Durante `initialize`, `MissedIntakePlanner` controlla al massimo i sette giorni precedenti e salva gli slot senza record come `missed`, senza aggiornare le scorte. Uno slot e' idoneo solo dal momento piu' recente tra creazione della medicina, creazione dello schedule e data di inizio della terapia, quando presente: in questo modo non vengono ricostruite dimenticanze anteriori alla programmazione effettiva. I record mantengono snapshot di nome e dose, cosi' restano leggibili dopo l'eliminazione della medicina. Dashboard offre azioni rapide per la data corrente, le notifiche locali offrono Assunta/Saltata per lo slot notificato e HistoryScreen visualizza anche lo stato Dimenticata.

`HistoryScreen` applica filtri in memoria tramite `HistoryFilterService`, usando la cache `provider.intakeHistory` e `provider.therapies`. I filtri disponibili sono stato (`taken`, `skipped`, `missed`), periodo (`Oggi`, `Ultimi 7 giorni`, `Ultimi 30 giorni`, `Tutto`), terapia e medicina. Il filtro periodo lavora sulla data prevista `scheduledDateTime`, normalizzata al giorno, cosi' evita confronti fragili sull'orario. Il filtro medicina include anche record di medicine eliminate usando `medicineNameSnapshot`; il filtro terapia sui record eliminati resta limitato perche' `IntakeRecord` non conserva uno snapshot terapia.

`StatisticsScreen` usa `HistoryStatisticsService` con la stessa cache. La formula di aderenza base e' `taken / (taken + skipped + missed)`: i record `scheduled`, se presenti, restano nei record totali ma non entrano nelle assunzioni valutate. In assenza di dati valutabili il servizio restituisce `0%` e la UI mostra `--` o testo di fallback, cosi' non sembra una divisione errata. I periodi usano `scheduledDateTime` normalizzato al giorno; `Ultimi 7 giorni` e `Ultimi 30 giorni` includono la giornata corrente.

La sezione `Andamento aderenza` calcola punti giornalieri con la stessa formula, filtrabili per periodo (`Ultimi 7 giorni`, `Ultimi 30 giorni`, `Tutto`), terapia e medicina. I giorni senza assunzioni valutate hanno percentuale `null`: il grafico non disegna alcun punto per quel giorno e non lo tratta come 0%. Il filtro terapia non attribuisce record di medicine eliminate senza snapshot terapia; il filtro medicina puo' usare `medicineNameSnapshot` quando la medicina non esiste piu'. Il grafico e' disegnato con `CustomPainter` interno alla schermata per evitare una dipendenza grafica esterna in questo sprint; il periodo `Tutto` usa scroll orizzontale quando la serie diventa lunga e parte dal primo record coerente con i filtri selezionati.

### Scorte

Lo schema Drift e' alla versione 2: `medicines.stockQuantity` e `medicines.stockWarningThreshold` sono colonne `REAL`, migrate dai precedenti interi con `TableMigration`. `Medicine.stockConsumptionAmount` interpreta la quantita' iniziale della dose: interi, frazioni `1/2` e `1/4`, e decimali con punto o virgola. Quando un record passa a `taken`, `IntakeActionService` aggiorna `stockQuantity` insieme al record nella stessa transazione di `IntakeRepository`; un record gia' `taken` non viene sottratto una seconda volta e il passaggio a `skipped` ripristina la stessa quantita'. Dose assente o testo non interpretabile registrano lo storico ma non cambiano la disponibilita'; una quantita' superiore alla scorta blocca l'azione senza aggiornamenti parziali. `StockScreen` permette una ricarica manuale decimale persistente tramite `addStock`: il dialog raccoglie e valida soltanto la quantita', quindi viene chiuso prima dell'aggiornamento asincrono del Provider. Il controller del campo e' posseduto dal dialog e viene disposto solo con la sua route, mai subito dopo il pop. La soglia minima serve solo a determinare lo stato visivo di avviso: una ricarica valida resta consentita anche quando la quantita' finale e' ancora sotto soglia. Quando una modifica porta la scorta da sopra soglia a uguale/sotto soglia, l'app puo' inviare una notifica locale `Scorta bassa`; se la medicina era gia' sotto soglia, non invia notifiche ripetute. `MaterialApp` non deve ascoltare cambiamenti ordinari del Provider; mantenerlo stabile evita di ricreare Navigator e ScaffoldMessenger durante aggiornamenti delle schermate.

### Notifiche

`NotificationService` viene inizializzato durante `MedicineProvider.initialize` dopo il caricamento della cache. Se `notificationsEnabled` e' attivo, il Provider cancella e ripianifica i reminder delle medicine attive appartenenti a terapie attive. Gli ID sono deterministici e derivano da `medicineId`, giorno della settimana, ora e minuto; questo permette di annullare lo slot corretto senza dipendere da ID Drift nella UI. Creazione e modifica medicina cancellano prima i reminder precedenti e poi pianificano quelli nuovi; disattivazione, archiviazione o eliminazione cancellano i reminder coinvolti; riattivazione e toggle impostazioni li ripianificano. Il consenso negato, exact alarm non disponibile o un sistema non supportato non interrompono persistenza e UI. Il contratto Provider -> scheduler vive in `medicine_notification_scheduler.dart` ed e' coperto da test con fake scheduler per evitare duplicati all'avvio, verificare cancellazioni/ripianificazioni e simulare errori del layer notifiche senza plugin nativo.

`MedicineNotificationScheduler` espone anche lo stato operativo dei permessi tramite `NotificationPermissionStatus`: supporto notifiche locali, permesso notifiche Android e exact alarm quando il sistema permette di verificarlo. `MedicineProvider` mantiene questo stato in cache e `SettingsScreen` lo mostra in una sezione Notifiche con azioni per aggiornare lo stato, richiedere il permesso notifiche e richiedere exact alarm quando disponibile. Il toggle dell'app resta separato dai permessi Android: disattivarlo cancella i reminder, riattivarlo prova a ripianificarli, ma non blocca la creazione di terapie o medicine se il sistema nega i permessi. La batteria Android/Samsung resta una guida informativa perche' il controllo puntuale dipende dalle impostazioni del dispositivo.

Le notifiche includono le azioni Android/iOS `Assunta` e `Saltata`. Il payload e' JSON versionato con `medicineId`, `dayOfWeek`, `hour` e `minute`; essendo una notifica ricorrente, il payload non contiene uno `scheduledDateTime` assoluto. Quando l'utente preme un'azione, `NotificationActionHandler` ricostruisce lo slot programmato piu' recente rispetto al momento del tap e chiama `IntakeActionService`, senza usare `BuildContext` o classi Drift nella UI. Per evitare record ambigui da vecchie notifiche nel drawer, le azioni da notifica sono accettate solo se lo slot ricostruito e' oggi o ieri, non futuro, la medicina esiste ed e' attiva, la terapia collegata e' ancora attiva e lo schedule attuale contiene ancora lo stesso giorno/orario. In caso contrario l'azione viene ignorata senza modificare storico o scorte. Su Android il Manifest registra `ActionBroadcastReceiver`; le azioni senza UI possono essere elaborate da un background isolate tramite `meditrackNotificationTapBackground`, che richiama `DartPluginRegistrant.ensureInitialized()`. Se l'app e' gia' aperta o il main isolate e' ancora vivo in background, `NotificationActionEvents` registra una porta con `IsolateNameServer`: il background isolate invia un segnale al main isolate e il Provider ricarica cache, storico, assunzioni programmate e scorte prima di chiamare `notifyListeners`.

Il tap normale sul corpo della notifica segue un flusso separato dalle azioni. `NotificationService` controlla `NotificationResponseType`: `selectedNotificationAction` resta nel flusso `NotificationActionHandler`, mentre `selectedNotification` viene convertito da `NotificationNavigationEvents` in `NotificationNavigationRequest(medicineId)`. `MyApp` possiede una `GlobalKey<NavigatorState>`, ascolta queste richieste, chiama `MedicineProvider.ensureInitialized()` e apre `MedicineDetailScreen` solo se la medicina e' ancora presente nella cache persistente. Payload invalidi, medicine eliminate o terapie eliminate non generano errori visibili: l'app resta sulla Dashboard.

Gli alert di scorta bassa sono notifiche immediate, non ricorrenti. `NotificationService.showLowStockNotification` usa un ID stabile derivato da `medicineId`, titolo `Scorta bassa` e payload medicine-only per permettere il deep link al dettaglio medicina. L'alert viene richiesto da `IntakeActionService` quando un'assunzione porta la scorta sotto soglia e dal Provider per modifiche manuali della medicina; in entrambi i casi la notifica parte solo se la medicina e' attiva, la terapia e' attiva, il toggle notifiche dell'app e' attivo, la soglia e' maggiore di zero e la scorta attraversa la soglia dall'alto verso il basso. Restano futuri deep link verso storico, flussi guidati per notifiche troppo vecchie e promemoria di riacquisto avanzati.

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
- persistenza locale attiva per profilo, terapie e medicine;
- gestione autonoma delle terapie con dettaglio, archiviazione ed eliminazione persistente;
- spostamento persistente delle medicine tra terapie attive.
- storico assunzioni base persistente per stati assunta e saltata.
- notifiche locali con stato permessi visibile in Impostazioni.
- alert locali di scorta bassa con deduplica su attraversamento soglia.

Limiti attuali:

- deep link verso storico non ancora disponibile;
- promemoria avanzati di riacquisto scorte non ancora disponibili;
- alcune componenti UI sono duplicate localmente nelle schermate;
- tema scuro predisposto nel profilo ma non ancora applicato all'interfaccia.

## Note di manutenzione

- Non introdurre nuove feature direttamente negli screen se richiedono stato condiviso.
- Evitare di accoppiare il database futuro ai widget.
- Mantenere i model serializzabili e testabili.
- Aggiornare questa guida quando vengono introdotti repository, database o nuove aree funzionali.
- Prima di rilasciare una versione utilizzabile, implementare persistenza, test e gestione completa delle notifiche.
