# Guida tecnica - Meditrack

Questo documento descrive l'architettura attuale di Meditrack e le linee guida per mantenerlo ed evolverlo. E' pensato per sviluppatori che prenderanno in carico il progetto in futuro.

## Architettura del progetto

Meditrack e' un'app Flutter basata su una struttura semplice:

- UI costruita con widget Flutter e Material 3.
- Stato applicativo gestito con Provider e `ChangeNotifier`.
- Dati temporanei mantenuti in memoria.
- Model di dominio gia' predisposti per serializzazione JSON.
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
├── models/
├── providers/
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

Nota: il profilo contiene una preferenza `isDarkMode`, ma `themeMode` e' attualmente impostato a `ThemeMode.light`. Il supporto completo al tema scuro e' quindi pianificato, non ancora operativo.

### `lib/models/`

Contiene le entita' di dominio. I model rappresentano i dati principali dell'app e devono rimanere il piu' possibile indipendenti dalla UI.

File attuali:

- `medicine.dart`
- `therapy.dart`
- `intake_record.dart`
- `user_profile.dart`

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
- gestire preferenza tema scuro a livello dati;
- mostrare voci predisposte per backup e report PDF.

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
- mantenere i model indipendenti dalla UI;
- evitare logica di business complessa dentro gli screen;
- aggiungere metodi al provider solo se coordinano stato applicativo;
- creare widget riutilizzabili quando una UI viene ripetuta;
- preparare test per logiche di calcolo o trasformazione dati;
- aggiornare README e guida tecnica quando cambia l'architettura.

Flusso consigliato:

1. Definire il comportamento atteso.
2. Verificare quali model servono.
3. Aggiungere o aggiornare il provider.
4. Costruire la UI con widget piccoli e leggibili.
5. Collegare eventuali servizi esterni.
6. Verificare su emulatore e dispositivo.
7. Aggiornare la documentazione.

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
- tema scuro salvato nel profilo ma non applicato.

## Note di manutenzione

- Non introdurre nuove feature direttamente negli screen se richiedono stato condiviso.
- Evitare di accoppiare il database futuro ai widget.
- Mantenere i model serializzabili e testabili.
- Aggiornare questa guida quando vengono introdotti repository, database o nuove aree funzionali.
- Prima di rilasciare una versione utilizzabile, implementare persistenza, test e gestione completa delle notifiche.
