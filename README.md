# Meditrack

Meditrack e' un'app Flutter per la gestione personale di medicine, terapie, orari di assunzione e scorte. Il progetto e' pensato come base evolutiva per un'applicazione mobile professionale dedicata al monitoraggio terapeutico quotidiano.

## Descrizione generale

L'app permette all'utente di creare una terapia, associare una o piu' medicine, definire dosaggio, orari, giorni della settimana, note e quantita' disponibili. La dashboard mostra una sintesi dello stato della giornata, la prossima medicina prevista, le terapie attive e gli eventuali avvisi di scorta bassa.

I dati principali sono salvati localmente con Drift e SQLite. Provider mantiene una cache per la UI, mentre repository e mapper isolano l'app dai dettagli di persistenza.

## Obiettivo dell'app

L'obiettivo di Meditrack e' aiutare l'utente a seguire con maggiore ordine le proprie terapie, riducendo il rischio di dimenticanze e rendendo piu' semplice controllare medicine, dosaggi, orari e disponibilita' delle scorte.

## Problema che risolve

Molte persone gestiscono terapie multiple usando appunti, memoria personale o promemoria non strutturati. Questo puo' portare a:

- dimenticare un'assunzione;
- confondere dosaggi o orari;
- accorgersi troppo tardi che una medicina sta finendo;
- non avere uno storico chiaro da condividere con medico o caregiver;
- gestire con difficolta' terapie diverse o profili diversi.

Meditrack nasce per centralizzare queste informazioni in un'esperienza semplice, leggibile e progressivamente estendibile.

## Funzionalita' attualmente implementate

- Dashboard principale con riepilogo della giornata.
- Medicine e assunzioni mostrate in Dashboard cliccabili verso il dettaglio medicina.
- Navigazione inferiore tra Home, Terapie, Storico e Profilo.
- Creazione di una medicina associata a una terapia.
- Creazione, modifica, dettaglio, archiviazione ed eliminazione di terapie anche senza medicine.
- Aggiunta di una medicina direttamente dal dettaglio terapia.
- Inserimento di nome medicina, dosaggio, note, colore, programmazioni di assunzione, quantita' iniziale e soglia minima.
- Supporto a piu' programmazioni per una singola medicina, con giorni e orari propri.
- Raggruppamento delle medicine per terapia.
- Ricerca per nome terapia o nome medicina.
- Dettaglio della medicina con dosaggio, stato, programmazioni, scorte e note.
- Modifica di una medicina esistente dal dettaglio, mantenendo lo stesso identificativo e ripianificando i promemoria.
- Spostamento persistente di una medicina verso un'altra terapia attiva.
- Attivazione o disattivazione di una medicina.
- Eliminazione persistente di una medicina senza rimuovere automaticamente la terapia.
- Archiviazione delle terapie e cancellazione definitiva, con conferma, di una terapia e delle medicine associate.
- Calcolo della prossima medicina da assumere nella giornata.
- Rilevamento delle medicine con scorta bassa.
- Schermata Scorte con indicatore visivo della disponibilita'.
- Quantita' di scorta e consumo per dose supportano interi, frazioni e decimali.
- Ricarica manuale persistente delle scorte dalla schermata Scorte.
- Dashboard con azioni rapide per segnare le assunzioni di oggi come assunte o saltate.
- Schermata Storico persistente con stati assunta, saltata e dimenticata, filtri per stato, periodo, terapia e medicina, snapshot della medicina, dose e data/ora.
- Schermata Statistiche accessibile dallo Storico, con aderenza generale, andamento temporale filtrabile, riepiloghi per periodo, stato, medicina e terapia.
- Decremento automatico della scorta per assunzioni con quantita' intera, frazionaria o decimale definita.
- Profilo utente locale con nome, preferenze tema e notifiche.
- Persistenza locale di profilo, impostazioni, terapie, medicine, scorte e schedule.
- Schermata Impostazioni predisposta per backup e report PDF.
- Promemoria locali ricorrenti per medicine attive, basati su giorni e orari programmati.
- Azioni rapide dalle notifiche locali per segnare una dose come assunta o saltata, con aggiornamento di storico e scorte.
- Apertura del dettaglio medicina quando l'utente tocca il corpo di una notifica.
- Notifiche locali di scorta bassa quando una medicina attraversa la soglia minima.
- Sezione Impostazioni per mostrare stato permesso notifiche Android, exact alarm e guida su ottimizzazione batteria.

## Funzionalita' pianificate

- Miglioramento generale della UI e consolidamento del design system.
- Evoluzione del sistema Terapie con filtri, ordinamento e stati archiviati piu' chiari.
- Associazione piu' strutturata Medicine -> Terapie con controlli di integrita' piu' avanzati.
- Dashboard avanzata con statistiche, aderenza terapeutica e azioni rapide.
- Evoluzione dello storico con ritardi, note, correzioni, grafici avanzati e confronti piu' approfonditi.
- Gestione avanzata delle scorte con registro carico/scarico e promemoria di riacquisto configurabili.
- Notifiche locali avanzate con deep link verso storico e controlli piattaforma piu' completi.
- Migrazioni schema e test automatici del database locale.
- Profili multipli per utente, familiari o caregiver.
- Report PDF esportabile per medico o uso personale.
- Backup Cloud e sincronizzazione tra dispositivi.

## Tecnologie utilizzate

- Flutter
- Dart
- Material 3
- Provider per lo state management
- flutter_local_notifications per notifiche locali
- timezone per la pianificazione delle notifiche
- intl per supporto a date e formattazioni
- uuid per generazione degli identificativi
- drift e SQLite per persistenza locale
- flutter_lints per le regole di qualita' del codice

## Architettura generale

Il progetto segue una struttura semplice e leggibile, adatta alla fase attuale dell'app:

- `main.dart` inizializza Flutter e registra il provider globale.
- `app.dart` configura tema, MaterialApp e schermata iniziale.
- `models/` contiene le entita' di dominio.
- `providers/` contiene la cache UI e coordina repository e operazioni sui dati.
- `screens/` contiene le pagine principali dell'interfaccia.
- `widgets/` contiene componenti riutilizzabili.
- `services/` contiene servizi applicativi esterni alla UI, come le notifiche.

Il flusso dati principale passa da `MedicineProvider`, che mantiene una cache di terapie, medicine e profilo corrente per la UI. I repository leggono e scrivono i dati persistenti nel database Drift; le schermate restano collegate solo al Provider tramite `Consumer` o accesso diretto.

## Struttura delle cartelle

```text
meditrack/
├── android/                 # Configurazione progetto Android
├── ios/                     # Configurazione progetto iOS
├── linux/                   # Configurazione desktop Linux
├── macos/                   # Configurazione desktop macOS
├── web/                     # Configurazione Flutter Web
├── windows/                 # Configurazione desktop Windows
├── docs/                    # Documentazione tecnica del progetto
├── lib/
│   ├── app.dart             # Configurazione MaterialApp e tema
│   ├── main.dart            # Entry point dell'app
│   ├── models/              # Model di dominio
│   ├── providers/           # State management
│   ├── screens/             # Schermate dell'app
│   ├── services/            # Servizi applicativi
│   └── widgets/             # Widget riutilizzabili
├── test/                    # Test Flutter
├── analysis_options.yaml    # Regole static analysis
├── pubspec.yaml             # Dipendenze e configurazione Flutter
└── README.md                # Documentazione principale
```

## Installazione

Prerequisiti consigliati:

- Flutter SDK compatibile con Dart `^3.8.0`;
- Android Studio o Visual Studio Code;
- Android SDK configurato per sviluppo mobile;
- Xcode su macOS per esecuzione iOS;
- un emulatore Android, simulatore iOS o dispositivo fisico.

Passaggi:

```bash
flutter pub get
```

Per verificare la configurazione dell'ambiente:

```bash
flutter doctor
```

## Avvio del progetto

Per avviare l'app sul dispositivo o emulatore disponibile:

```bash
flutter run
```

Per elencare i dispositivi disponibili:

```bash
flutter devices
```

Per avviare su un target specifico:

```bash
flutter run -d <device-id>
```

## Esecuzione su emulatore

1. Aprire Android Studio.
2. Avviare un emulatore da Device Manager.
3. Verificare che Flutter lo riconosca:

```bash
flutter devices
```

4. Avviare l'app:

```bash
flutter run
```

In alternativa, con piu' dispositivi disponibili:

```bash
flutter run -d <emulator-id>
```

## Esecuzione su dispositivo fisico

### Android

1. Abilitare le Opzioni sviluppatore sul dispositivo.
2. Abilitare il Debug USB.
3. Collegare il dispositivo al computer.
4. Accettare la richiesta di autorizzazione al debug.
5. Verificare il dispositivo:

```bash
flutter devices
```

6. Avviare l'app:

```bash
flutter run -d <device-id>
```

### iOS

1. Usare un computer macOS con Xcode installato.
2. Collegare iPhone o iPad.
3. Configurare firma e team di sviluppo in Xcode.
4. Verificare il dispositivo:

```bash
flutter devices
```

5. Avviare l'app:

```bash
flutter run -d <device-id>
```

## Stato attuale del progetto

Meditrack e' in una fase prototipale avanzata. I flussi base per terapie e medicine sono persistenti: le terapie, le medicine, le scorte, gli schedule e le impostazioni principali restano disponibili al riavvio dell'app. Ogni nuova medicina viene associata a una terapia esistente; puo' avere piu' programmazioni interne con giorni e orari propri; puo' essere modificata dal dettaglio senza perdere storico o identificativo; la dose e' opzionale e viene distinta dalla quantita' in scorta.

Lo storico base e' operativo e persistente, con filtri in memoria per stato, periodo, terapia e medicina. Le statistiche base mostrano aderenza, riepiloghi per periodo e breakdown per medicina e terapia. Le notifiche locali vengono pianificate per le medicine attive quando il sistema concede i permessi, includono azioni rapide Assunta/Saltata, aprono il dettaglio medicina dal tap sul corpo della notifica, avvisano quando la scorta attraversa la soglia minima e mostrano in Impostazioni lo stato dei permessi Android; Backup e Report PDF restano predisposti ma non ancora operativi.

## Roadmap futura

### Fase 1 - Consolidamento UI

- Uniformare stile, spaziature, card, bottoni e stati vuoti.
- Estrarre componenti comuni dove utile.
- Migliorare accessibilita', leggibilita' e responsive layout.
- Rivedere testi e microcopy in italiano.

### Fase 2 - Evoluzione Terapie

- Aggiungere riattivazione esplicita, filtri e ordinamento.
- Rifinire gli stati archiviati e le azioni di gestione.

### Fase 3 - Associazione Medicine -> Terapie

- Separare in modo piu' netto la gestione delle medicine dalla gestione delle terapie.
- Supportare piu' medicine nella stessa terapia con regole chiare.
- Preparare relazioni compatibili con database.

### Fase 4 - Dashboard avanzata

- Mostrare assunzioni previste, completate e mancanti.
- Aggiungere indicatori di aderenza terapeutica.
- Inserire azioni rapide per confermare un'assunzione.
- Evidenziare urgenze, scorte basse e prossimi promemoria.

### Fase 5 - Storico

- Registrare ogni assunzione programmata.
- Gestire stati avanzati come ritardata, note e correzioni dello storico.
- Preparare grafici, statistiche avanzate e dati per report.

### Fase 6 - Scorte

- Aggiornare automaticamente le scorte dopo ogni assunzione confermata.
- Aggiungere carico manuale delle quantita'.
- Preparare promemoria avanzati per riacquisto.

### Fase 7 - Notifiche

- Consolidare i test dei promemoria locali su dispositivi reali e le eccezioni di battery optimization Android.
- Aggiungere deep link verso storico e controlli piu' avanzati per battery optimization Android, se supportati.

### Fase 8 - Database

- Aggiungere test repository su database temporaneo.
- Gestire migrazioni e versionamento schema.
- Estendere la persistenza a storico e nuove funzionalita'.

### Fase 9 - Profili

- Supportare piu' profili locali.
- Associare terapie, medicine e storico al profilo corretto.
- Preparare casi d'uso per familiari e caregiver.
- Estendere preferenze personali e impostazioni.

### Fase 10 - Report PDF

- Generare report con terapie, medicine, dosaggi e storico.
- Consentire esportazione e condivisione.
- Preparare un formato chiaro per medici e visite.
- Valutare filtri per intervallo temporale.

### Fase 11 - Backup Cloud

- Definire strategia di backup e ripristino.
- Introdurre sincronizzazione sicura tra dispositivi.
- Gestire conflitti e versioni dei dati.
- Valutare autenticazione e protezione dei dati sensibili.

## Documentazione aggiuntiva

- [Guida tecnica](docs/TECHNICAL_GUIDE.md)
- [Changelog progresso](docs/CHANGELOG_PROGRESS.md)
- [Problemi noti](docs/KNOWN_ISSUES.md)

## Flusso di lavoro del progetto

Ogni modifica importante deve essere documentata. Il progetto mantiene quattro documenti principali:

- `README.md`: obiettivo dell'app, funzionalita', tecnologie, avvio, stato e roadmap.
- `docs/TECHNICAL_GUIDE.md`: architettura, cartelle, model, screen, provider, widget e linee guida tecniche.
- `docs/CHANGELOG_PROGRESS.md`: registro delle modifiche importanti con data, tipo, descrizione, file modificati, motivazione e stato.
- `docs/KNOWN_ISSUES.md`: registro di bug, discrepanze, possibili cause, possibili soluzioni e stato.

Regole operative:

- analizzare il codice esistente prima di modificare;
- non riscrivere file interi se non serve;
- non introdurre database, cloud o login senza richiesta esplicita;
- mantenere lo stile verde/bianco medical-tech;
- aggiornare il changelog per modifiche importanti;
- aggiornare la guida tecnica se cambiano architettura o funzionalita';
- aggiornare i problemi noti quando emergono bug o discrepanze;
- aggiornare il README quando cambia lo stato generale del progetto;
- chiedere conferma prima di grandi refactor.
