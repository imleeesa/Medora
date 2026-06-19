# Meditrack

Meditrack e' un'app Flutter per la gestione personale di medicine, terapie, orari di assunzione e scorte. Il progetto e' pensato come base evolutiva per un'applicazione mobile professionale dedicata al monitoraggio terapeutico quotidiano.

## Descrizione generale

L'app permette all'utente di creare una terapia, associare una o piu' medicine, definire dosaggio, orari, giorni della settimana, note e quantita' disponibili. La dashboard mostra una sintesi dello stato della giornata, la prossima medicina prevista, le terapie attive e gli eventuali avvisi di scorta bassa.

Al momento i dati sono gestiti temporaneamente in memoria tramite Provider. I model sono gia' predisposti per la serializzazione JSON, cosi' da facilitare l'introduzione futura di un database locale e di funzionalita' di backup.

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
- Navigazione inferiore tra Home, Terapie, Storico e Profilo.
- Creazione di una medicina associata a una terapia.
- Inserimento di nome medicina, dosaggio, note, colore, orari, giorni della settimana, quantita' iniziale e soglia minima.
- Raggruppamento delle medicine per terapia.
- Ricerca per nome terapia o nome medicina.
- Dettaglio della medicina con dosaggio, stato, orari, giorni, scorte e note.
- Attivazione o disattivazione di una medicina.
- Eliminazione di una medicina dalla sessione corrente.
- Calcolo della prossima medicina da assumere nella giornata.
- Rilevamento delle medicine con scorta bassa.
- Schermata Scorte con indicatore visivo della disponibilita'.
- Schermata Storico predisposta per le assunzioni future.
- Profilo utente locale con nome, preferenze tema e notifiche.
- Schermata Impostazioni predisposta per backup e report PDF.
- Servizio notifiche locali presente nel codice e pronto per integrazione nel flusso applicativo.

## Funzionalita' pianificate

- Miglioramento generale della UI e consolidamento del design system.
- Sistema Terapie completo con creazione, modifica, archiviazione e stato attivo/inattivo.
- Associazione piu' strutturata Medicine -> Terapie.
- Dashboard avanzata con statistiche, aderenza terapeutica e azioni rapide.
- Storico delle assunzioni con conferma, salto, ritardo e note.
- Gestione avanzata delle scorte con carico/scarico, soglie e promemoria di riacquisto.
- Notifiche locali integrate con le medicine salvate.
- Database locale persistente.
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
- flutter_lints per le regole di qualita' del codice

## Architettura generale

Il progetto segue una struttura semplice e leggibile, adatta alla fase attuale dell'app:

- `main.dart` inizializza Flutter e registra il provider globale.
- `app.dart` configura tema, MaterialApp e schermata iniziale.
- `models/` contiene le entita' di dominio.
- `providers/` contiene lo stato applicativo temporaneo e le operazioni sui dati.
- `screens/` contiene le pagine principali dell'interfaccia.
- `widgets/` contiene componenti riutilizzabili.
- `services/` contiene servizi applicativi esterni alla UI, come le notifiche.

Il flusso dati principale passa da `MedicineProvider`, che mantiene in memoria terapie, medicine e profilo corrente. Le schermate leggono e aggiornano questo stato tramite `Consumer` o accesso diretto al provider.

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

Meditrack e' in una fase prototipale avanzata. La UI principale e i flussi base sono presenti, ma la persistenza dei dati non e' ancora implementata: le medicine, le terapie e le preferenze vengono perse al riavvio dell'app.

Il codice contiene gia' model serializzabili e un servizio notifiche locali, elementi utili per la prossima evoluzione architetturale. Le schermate Storico, Backup e Report PDF sono predisposte ma non ancora operative.

## Roadmap futura

### Fase 1 - Consolidamento UI

- Uniformare stile, spaziature, card, bottoni e stati vuoti.
- Estrarre componenti comuni dove utile.
- Migliorare accessibilita', leggibilita' e responsive layout.
- Rivedere testi e microcopy in italiano.

### Fase 2 - Sistema Terapie

- Creare una schermata dedicata alla gestione delle terapie.
- Consentire modifica, eliminazione e archiviazione delle terapie.
- Gestire stato attivo/inattivo della terapia.
- Preparare ordinamento e filtri.

### Fase 3 - Associazione Medicine -> Terapie

- Separare in modo piu' netto la gestione delle medicine dalla gestione delle terapie.
- Consentire lo spostamento di una medicina tra terapie.
- Supportare piu' medicine nella stessa terapia con regole chiare.
- Preparare relazioni compatibili con database.

### Fase 4 - Dashboard avanzata

- Mostrare assunzioni previste, completate e mancanti.
- Aggiungere indicatori di aderenza terapeutica.
- Inserire azioni rapide per confermare un'assunzione.
- Evidenziare urgenze, scorte basse e prossimi promemoria.

### Fase 5 - Storico

- Registrare ogni assunzione programmata.
- Gestire stati: assunta, saltata, dimenticata o in ritardo.
- Aggiungere filtri per periodo, terapia e medicina.
- Preparare statistiche e dati per report.

### Fase 6 - Scorte

- Aggiornare automaticamente le scorte dopo ogni assunzione confermata.
- Aggiungere carico manuale delle quantita'.
- Creare avvisi di scorta bassa.
- Preparare promemoria per riacquisto.

### Fase 7 - Notifiche

- Integrare `NotificationService` con creazione, modifica e cancellazione delle medicine.
- Pianificare promemoria ricorrenti per giorni e orari selezionati.
- Gestire permessi Android e iOS in modo guidato.
- Aggiungere azioni da notifica, se supportate.

### Fase 8 - Database

- Introdurre persistenza locale.
- Creare repository dedicati per medicine, terapie, profili e storico.
- Migrare lo stato temporaneo dal provider al database.
- Gestire migrazioni e versionamento schema.

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
