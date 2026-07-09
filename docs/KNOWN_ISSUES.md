# Problemi noti - Meditrack

Questo file raccoglie bug, discrepanze e rischi tecnici noti. Ogni problema resta tracciato fino a quando viene corretto, accettato come limite temporaneo o spostato nella roadmap.

## Export CSV locale senza share sheet

### Categoria

Limite funzionale.

### Stato

Risolto

### Cosa e' stato trovato

Lo Sprint Export CSV salva lo storico filtrato in un file locale nella directory documenti dell'app. Non apre ancora un foglio di condivisione e non esporta PDF, backup database o cloud.

### Data risoluzione

2026-07-08

### Come e' stato risolto

L'export CSV ora scrive un file temporaneo e apre lo share sheet di sistema tramite `share_plus`, cosi' l'utente puo' salvare o inviare il CSV con app come Files, Drive, Gmail o WhatsApp.

### File modificati

- `pubspec.yaml`;
- `pubspec.lock`;
- `lib/screens/history_screen.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

### Note

Se il dispositivo non ha destinazioni disponibili o lo share sheet fallisce, l'app non crasha e mostra un messaggio di fallback. PDF, cloud e backup database restano fuori da questo sprint.

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

Risolto

### Data risoluzione

2026-06-22

### Area

Terapie, Medicine, Provider, Database futuro

### Cosa e' stato trovato

Le terapie venivano create o usate principalmente durante l'aggiunta di una medicina. Non esisteva un flusso autonomo per crearle, modificarle, archiviarle o aprirne il dettaglio.

### Motivazione

Lo Sprint Terapie ha introdotto una lista autonoma, form di creazione e modifica, dettaglio con medicine associate e pulsante di aggiunta medicina nel contesto della terapia. Le operazioni usano il Provider e restano persistite in Drift.

### Possibili soluzioni

### Come e' stato risolto

- introdotte `AddTherapyScreen` e `TherapyDetailScreen`;
- aggiunti metodi Provider per creare, modificare, archiviare/eliminare e interrogare terapie;
- aggiunta associazione medicina a una terapia selezionata;
- mantenuto il modello `TERAPIE -> MEDICINE` senza esporre Drift alla UI;
- le terapie con medicine possono essere archiviate o eliminate insieme alle medicine associate, previa conferma esplicita;
- eliminare l'ultima medicina non elimina automaticamente la terapia;
- il vecchio flusso riusa o riattiva la terapia esistente con lo stesso nome.

### Note

Lo spostamento di medicine tra terapie e' disponibile dal 2026-06-24. Filtri e ordinamenti avanzati restano miglioramenti futuri non bloccanti.

## Eliminazione medicina non immediata dal dettaglio terapia

### Categoria

Bug da correggere ora.

### Stato

Risolto

### Data risoluzione

2026-06-24

### Come e' stato risolto

Il dettaglio terapia ora mostra un menu elimina per ogni medicina; il dettaglio della singola medicina espone la stessa azione. Entrambe richiedono conferma e chiamano `MedicineProvider.deleteMedicine`, che aggiorna database e cache UI.

### File modificati

- `lib/screens/therapy_detail_screen.dart`;
- `lib/screens/medicine_detail_screen.dart`;
- `docs/KNOWN_ISSUES.md`.

## Terapia archiviata senza riattivazione dalla UI

### Categoria

Bug da correggere ora.

### Stato

Risolto

### Data risoluzione

2026-06-22

### Come e' stato risolto

Il menu azioni nel dettaglio di una terapia archiviata ora mostra `Riattiva`. L'azione usa `MedicineProvider.reactivateTherapy`, aggiorna lo stato persistito e ricarica la cache senza duplicare la terapia.

### File modificati

- `lib/providers/medicine_provider.dart`;
- `lib/screens/therapy_detail_screen.dart`;
- `docs/KNOWN_ISSUES.md`.

## UI/UX Terapie e Medicine da rifinire

### Categoria

Incoerenza da chiarire/correggere ora.

### Stato

Rimandato

### Cosa e' stato trovato

La gestione autonoma delle terapie e i flussi medicina sono funzionali, ma la gerarchia visiva e alcune azioni richiedono un passaggio UI/UX dedicato per essere ancora piu' immediate su schermi piccoli e pieghevoli.

### Motivazione

Un redesign completo non rientra nello sprint QA. In questa fase sono state corrette solo leggibilita', azioni mancanti e responsivita' dei form esistenti.

### Possibili soluzioni

- revisione dei flussi e della gerarchia visiva Terapie/Medicine;
- test manuali su schermi piccoli e Samsung Z Flip;
- consolidamento delle card e delle azioni contestuali.

## Storico assunzioni base

### Categoria

Funzionalita' incompleta.

### Stato

Parzialmente risolto

### Data aggiornamento

2026-06-24

### Cosa e' stato trovato

Lo storico base e' ora operativo: Dashboard permette di segnare ogni assunzione prevista per oggi come assunta o saltata, il Provider salva o aggiorna un `IntakeRecord` in Drift e la schermata Storico mostra i record persistiti con snapshot di nome e dose. All'avvio, gli slot degli ultimi sette giorni senza record vengono salvati come `missed` / Dimenticata, senza modificare le scorte.

### Motivazione

Restano fuori dal perimetro le statistiche, i filtri per periodo o terapia, i record previsti creati in anticipo, le assunzioni in ritardo e il collegamento automatico con notifiche.

### Possibili soluzioni

- aggiungere filtri e ricerca dello storico;
- collegare la conferma assunzione alle notifiche;
- introdurre statistiche e report basati sui record persistiti;
- valutare la generazione anticipata dei record `scheduled` per le viste future.

### Limite di recupero

Per evitare di generare molti record dopo un lungo periodo di inattivita', il rollover controlla al massimo i sette giorni precedenti. Gli slot piu' vecchi non vengono ricostruiti automaticamente.

## Filtro e statistiche terapia su storico di medicine eliminate

### Categoria

Limite architetturale.

### Stato

Rimandato

### Cosa e' stato trovato

Lo storico conserva snapshot di nome e dose della medicina, ma non conserva uno snapshot della terapia. Quando una medicina viene eliminata, il repository scollega `medicineId` dai record storici per mantenere lo storico leggibile senza lasciare riferimenti a record cancellati.

### Motivazione

Il filtro medicina, le statistiche per medicina e il grafico di andamento filtrato per medicina possono ancora funzionare sui record eliminati usando `medicineNameSnapshot`. Il filtro terapia, le statistiche per terapia e il grafico filtrato per terapia, invece, non possono associare in modo affidabile quei record a una terapia eliminata o non piu' presente senza un campo snapshot dedicato o una strategia di soft delete.

### Possibili soluzioni

- aggiungere in futuro uno snapshot `therapyNameSnapshot` / `therapyIdSnapshot` agli `intake_records`;
- valutare soft delete per terapie e medicine invece di cancellazione fisica;
- introdurre una migrazione Drift solo quando il comportamento storico desiderato sara' definito.

## Assunzioni dimenticate anteriori alla creazione della medicina

### Categoria

Bug.

### Stato

Risolto

### Data risoluzione

2026-06-24

### Causa

Il planner controllava gli schedule dei sette giorni precedenti senza verificare se medicina o schedule esistessero gia' alla data e ora dello slot. Una programmazione creata oggi poteva quindi produrre una falsa assunzione Dimenticata per un giorno passato.

### Come e' stato risolto

`MissedIntakePlanner` considera uno slot solo quando e' uguale o successivo al momento piu' recente tra `medicine.createdAt`, `schedule.createdAt` e `therapy.startDate`, quando disponibile. Restano invariati il limite di sette giorni, l'esclusione della giornata corrente e il controllo anti-duplicato.

### File modificati

- `lib/services/missed_intake_planner.dart`;
- `test/missed_intake_planner_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

### Note

I test coprono medicina o schedule creati dopo lo slot, slot valido precedente, record gia' presenti e riavvio successivo.

## Schermata rossa durante la ricarica delle scorte

### Categoria

Bug UI/state.

### Stato

Risolto

### Data risoluzione

2026-06-24

### Causa

Il `TextEditingController` del dialog veniva disposto subito dopo `Navigator.pop`, mentre il `TextField` poteva essere ancora montato durante l'animazione di chiusura della route. Questo errore di lifecycle generava ricostruzioni incoerenti e l'assert Flutter `_dependents.isEmpty`. Inoltre `MyApp` ascoltava `MedicineProvider` senza usare alcun dato, ricostruendo inutilmente l'intero `MaterialApp` a ogni aggiornamento.

### Come e' stato risolto

Il dialog ora valida e restituisce soltanto la quantita'. Il suo `TextEditingController` e' posseduto da uno `StatefulWidget` dedicato e viene disposto solo nel suo `dispose`, dopo la rimozione effettiva della route. Il dialog si chiude prima della scrittura asincrona; Provider e `ScaffoldMessengerState` vengono acquisiti dal contesto della schermata prima dell'attesa, cosi' l'aggiornamento e il messaggio finale non usano il contesto del dialog chiuso. `MyApp` non ascolta piu' il Provider, quindi `MaterialApp`, Navigator e ScaffoldMessenger restano stabili durante gli aggiornamenti. Le card scorte hanno una chiave basata sull'ID medicina. La soglia minima resta solo un avviso visivo e non blocca mai una ricarica valida.

### File modificati

- `lib/screens/stock_screen.dart`;
- `lib/app.dart`;
- `test/stock_screen_test.dart`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

### Note

La ricarica resta persistente e accetta quantita' intere o decimali positive, anche quando il totale resta sotto soglia.

## Decremento automatico delle scorte dopo un'assunzione

### Categoria

Funzionalita' completata.

### Stato

Risolto

### Data aggiornamento

2026-06-24

### Cosa e' stato risolto

Lo schema Drift e' stato migrato alla versione 2: `stockQuantity` e `stockWarningThreshold` usano ora valori reali e i dati interi esistenti vengono convertiti preservandone il valore. Quando un record passa a `taken`, l'app interpreta `1`, `1/2`, `1/4` e valori decimali come `2.5`, sottrae la quantita' una sola volta e impedisce scorte negative. Il passaggio da `taken` a `skipped` ripristina esattamente la stessa quantita'. L'aggiornamento di record e medicina e' eseguito nella stessa transazione Drift. La schermata Scorte consente anche una ricarica manuale persistente.

### Limiti aperti

La dose resta testo libero: il decremento interpreta soltanto la quantita' iniziale in forma intera, frazionaria o decimale. Dose assente o testo non interpretabile non aggiornano automaticamente la scorta, ma l'assunzione viene registrata. Le ricariche manuali non generano ancora un record storico dedicato.

### Possibili soluzioni

- separare quantita', unita' e consumo scorte in campi strutturati;
- aggiungere un registro di ricariche e correzioni manuali;
- collegare le scorte a promemoria di riacquisto in uno sprint notifiche dedicato.

## Notifiche locali avanzate e limiti piattaforma

### Categoria

Funzionalita' parzialmente implementata.

### Stato

Parzialmente risolto

### Data aggiornamento

2026-07-02

### Cosa e' stato risolto

`NotificationService` viene inizializzato all'avvio e, se il toggle profilo e' attivo, ripianifica i promemoria delle medicine attive. Creazione, modifica, attivazione e riattivazione pianificano reminder ricorrenti per ogni combinazione giorno-orario; disattivazione, archiviazione ed eliminazione li cancellano. Gli ID sono deterministici e il ripristino all'avvio pulisce le notifiche locali dell'app prima della pianificazione, evitando duplicati. AndroidManifest dichiara i permessi richiesti per notifiche, exact alarm, azioni e ripristino al boot. Lo sprint QA del 2026-06-26 ha aggiunto test Provider con scheduler finto per coprire startup, modifica medicina, cancellazione, disattivazione/riattivazione, archiviazione/eliminazione terapia, toggle notifiche e failure best-effort per permessi o exact alarm negati. Lo Sprint Notifiche Locali 2 ha aggiunto azioni rapide Assunta/Saltata con payload stabile e handler senza `BuildContext`: l'azione aggiorna `IntakeRecord` e scorte tramite repository, evita duplicati sequenziali e non crea aggiornamenti parziali se la scorta e' insufficiente. Il bug "UI non aggiornata live dopo azione notifica" e' stato risolto usando `IsolateNameServer` per notificare il Provider vivo anche quando l'azione arriva da background isolate. Il limite delle notifiche vecchie nel drawer e' stato mitigato: l'azione viene accettata solo per slot di oggi o ieri, compatibili con schedule corrente, medicina attiva e terapia attiva; altrimenti viene ignorata senza modificare storico o scorte. Lo sprint UX permessi del 2026-06-26 ha aggiunto in Impostazioni una sezione Notifiche con toggle app, stato del permesso notifiche Android, stato exact alarm quando verificabile, richiesta permesso e guida breve su ottimizzazione batteria. Lo Sprint Deep Link Notifiche del 2026-06-29 ha separato il tap normale sul corpo della notifica dalle azioni rapide: il tap emette una richiesta di navigazione verso il dettaglio medicina, mentre `Assunta` e `Saltata` continuano a passare da `NotificationActionHandler`. Lo sprint del 2026-07-02 ha aggiunto gli alert locali di scorta bassa quando una medicina attraversa la soglia minima dall'alto verso il basso, senza ripetere notifiche mentre resta sotto soglia.

### Limiti aperti

- nessun deep link verso storico; il tap sul corpo notifica apre il dettaglio medicina quando il record esiste ancora;
- i sistemi Android possono ritardare notifiche per battery optimization o negare exact alarm;
- i permessi negati non bloccano l'app e ora sono visibili in Impostazioni, ma possono comunque richiedere intervento dell'utente nelle impostazioni del sistema;
- un tap su una vecchia notifica troppo lontana dallo slot previsto viene ignorato invece di aprire un flusso di correzione guidata;
- il timezone e' impostato su `Europe/Rome`, adatto al contesto attuale ma non ancora configurabile per profilo.

### Possibili soluzioni

- aggiungere deep link verso storico o flussi di correzione guidata;
- valutare deep link verso le impostazioni Android specifiche se verra' introdotta una dipendenza dedicata;
- usare un timezone configurabile o rilevato dal dispositivo;
- introdurre promemoria avanzati e configurabili per il riacquisto delle scorte.

## Backup e report PDF completi sono voci non operative

### Categoria

Limite funzionale.

### Stato

Parzialmente risolto

### Data aggiornamento

2026-07-09

### Cosa e' stato risolto

Le voci Backup e Report medico PDF nelle impostazioni mostrano un messaggio chiaro invece di comportarsi come controlli operativi. Dal 2026-07-09 il dettaglio terapia permette anche di esportare e condividere un PDF base di riepilogo della singola terapia.

### File modificati

- `lib/screens/settings_screen.dart`;
- `lib/screens/therapy_detail_screen.dart`;
- `lib/services/therapy_pdf_export_service.dart`;
- `test/therapy_pdf_export_service_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`.

### Note

Backup, cloud, report multi-terapia e cartella clinica completa restano nella roadmap. Il PDF attuale e' un riepilogo personale di una singola terapia, non un documento medico completo.

## Limiti export PDF riepilogo terapia

### Categoria

Limite funzionale / reportistica.

### Stato

Rimandato

### Cosa e' stato trovato

Il PDF generato dal dettaglio terapia include informazioni terapia, medicine associate, schedule, scorte, soglia minima, aderenza ultimi 30 giorni e disclaimer. Non include ancora grafici, firma, profilo completo, allegati, export multi-terapia o selezione manuale dell'intervallo temporale.

### Motivazione

Lo sprint introduce un primo riepilogo utile senza modificare schema database, storico, statistiche o notifiche. I record storici senza medicina corrente o senza snapshot terapia non vengono attribuiti alla terapia per evitare collegamenti non verificabili. Lo sprint QA del 2026-07-09 ha sostituito i font standard Helvetica con font Roboto locali per coprire accenti italiani e simboli comuni come frazioni, gradi e micro. Le emoji vengono rimosse dal testo PDF per evitare glyph mancanti.

### Possibili soluzioni

- aggiungere in futuro snapshot terapia agli `intake_records`;
- introdurre filtri di periodo per il PDF;
- estendere il report a piu' terapie o a un riepilogo profilo;
- valutare grafici e sezioni avanzate in uno sprint dedicato.

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

## Medicine create senza una terapia esistente

### Categoria

Incoerenza funzionale / modello dati.

### Stato

Risolto

### Data risoluzione

2026-06-22

### Come e' stato risolto

Il flusso globale di aggiunta medicina richiede ora la selezione di una terapia esistente. Se non esistono terapie, l'app non apre il form e propone di crearne una. Il Provider richiede inoltre un `therapyId` valido e non crea piu' terapie in modo implicito dal nome digitato nel form.

### File modificati

- `lib/screens/medicines_screen.dart`;
- `lib/screens/add_medicine_screen.dart`;
- `lib/providers/medicine_provider.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `README.md`.

### Note

Le medicine create dai flussi attuali hanno sempre una terapia associata. Gli eventuali record legacy senza `therapyId` non vengono modificati automaticamente in questo sprint.

## Eliminazione definitiva di una terapia con medicine associate

### Categoria

Bug di comportamento / rischio di perdita dati.

### Stato

Risolto

### Data risoluzione

2026-06-22

### Come e' stato risolto

Il menu della terapia distingue archiviazione ed eliminazione definitiva. L'archiviazione mantiene medicine e collegamenti; l'eliminazione definitiva e' sempre disponibile. Quando la terapia contiene medicine, l'app chiede una conferma esplicita e il repository elimina in transazione le medicine, i relativi schedule e poi la terapia, senza lasciare medicine orfane.

### File modificati

- `lib/screens/therapy_detail_screen.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/repositories/therapy_repository.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`.

### Note

La cancellazione mantiene eventuali `intake_records` storici, ma rimuove il relativo `medicineId`, coerentemente con la strategia gia' usata per l'eliminazione di una singola medicina.

## Spostamento medicine tra terapie

### Categoria

Funzionalita' incompleta.

### Stato

Risolto

### Data risoluzione

2026-06-24

### Come e' stato risolto

Nel dettaglio medicina e' disponibile l'azione `Cambia terapia`. La UI mostra solo terapie attive diverse da quella corrente; il Provider valida la destinazione, aggiorna `therapyId` tramite repository, ricarica la cache e notifica subito tutte le schermate interessate.

### File modificati

- `lib/screens/medicine_detail_screen.dart`;
- `lib/providers/medicine_provider.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `README.md`.

### Note

Le terapie archiviate non sono destinazioni disponibili e non vengono riattivate automaticamente durante lo spostamento.

## Orari duplicati nel dettaglio medicina

### Categoria

Bug UI/dati derivati.

### Stato

Risolto

### Data risoluzione

2026-07-03

### Causa

La sezione `Orari di Assunzione` mostrava lo stesso `TimeOfDay` due volte nella stessa riga: una volta nel chip evidenziato e una volta come testo normale. Inoltre il dettaglio usava in alcune sezioni l'istanza iniziale della medicina invece della versione aggiornata dal Provider, rendendo piu' facile visualizzare dati non allineati dopo navigazioni da Dashboard o notifica.

### Come e' stato risolto

`MedicineDetailScreen` ora legge la medicina corrente dal Provider, costruisce la lista orari dagli schedule attivi, raggruppa gli schedule equivalenti per ora/minuto, unisce i giorni associati e ordina gli orari in modo crescente. La riga mostra un solo chip orario e i giorni collegati, senza aggiungere una seconda etichetta con lo stesso orario.

### File modificati

- `lib/screens/medicine_detail_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`.

### Note

La correzione vale per aperture da Dashboard, dettaglio terapia e deep link notifica, perche' tutte arrivano allo stesso `MedicineDetailScreen`.

## Modifica medicina dal dettaglio non disponibile

### Categoria

Funzionalita' incompleta.

### Stato

Risolto

### Data risoluzione

2026-07-03

### Cosa e' stato trovato

Il dettaglio medicina permetteva di eliminare o cambiare terapia, ma non di modificare nome, dose, orari, giorni, scorte, soglia e note.

### Come e' stato risolto

Il dettaglio medicina espone ora un'azione `Modifica medicina`. Il form `AddMedicineScreen` supporta anche la modalita' edit: precompila i campi esistenti e salva tramite `MedicineProvider.updateMedicine`, mantenendo invariato `medicineId`, aggiornando `updatedAt` tramite Provider e ripianificando le notifiche della medicina.

### File modificati

- `lib/screens/medicine_detail_screen.dart`;
- `lib/screens/add_medicine_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `README.md`.

### Note

Il cambio terapia resta nel flusso separato `Cambia terapia`, gia' persistente e validato sulle terapie attive.

## Selezione giorni globale per tutti gli orari della medicina

### Categoria

Limite funzionale / UX.

### Stato

Risolto

### Data risoluzione

2026-07-05

### Cosa e' stato trovato

Il form medicina permetteva di scegliere una sola lista globale di giorni e una lista globale di orari. Questo rappresentava bene casi come `Lun, Mer, Ven alle 08:00 e 20:00`, ma non casi come `Lun alle 08:00` e `Mer alle 14:00` per la stessa medicina.

### Come e' stato risolto

`AddMedicineScreen` usa ora una sezione `Programmazione assunzioni`, composta da una o piu' card. Ogni card contiene i propri giorni e i propri orari. Al salvataggio il form converte le card in schedule reali, il Provider deduplica le combinazioni giorno/orario e il repository continua a salvare righe atomiche nella tabella `medicine_schedules`, senza modificare lo schema Drift.

### File modificati

- `lib/screens/add_medicine_screen.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/medicine_detail_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `test/missed_intake_planner_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`;
- `README.md`.

### Note

La medicina resta una sola. Dashboard, storico, missed planner e notifiche lavorano sugli slot generati dalle programmazioni interne.

## Prodotto cartesiano giorni/orari negli schedule avanzati

### Categoria

Bug.

### Stato

Risolto

### Data risoluzione

2026-07-05

### Cosa e' stato trovato

Dopo l'introduzione degli schedule avanzati, alcuni calcoli potevano ancora usare le viste derivate `Medicine.times` e `Medicine.daysOfWeek`. Con programmazioni come `Lun/Sab -> 15:30, 15:35` e `Mar/Dom -> 14:30, 16:35`, l'unione globale di giorni e orari poteva generare uno slot inesistente come `Dom 15:35`.

### Come e' stato risolto

Dashboard e Provider usano ora `ScheduledIntake` derivati da `medicine.schedules`, filtrando gli schedule attivi per la data richiesta. Gli helper `Medicine.shouldTakeToday()` e `Medicine.getNextIntake()` leggono gli schedule reali invece dei campi derivati. Notifiche, missed planner e azioni rapide sono coperti da test che verificano solo combinazioni atomiche reali `medicineId + dayOfWeek + hour + minute`.

### File modificati

- `lib/models/medicine.dart`;
- `lib/providers/medicine_provider.dart`;
- `lib/screens/dashboard_screen.dart`;
- `test/medicine_provider_notification_test.dart`;
- `test/missed_intake_planner_test.dart`;
- `test/notification_action_handler_test.dart`;
- `docs/KNOWN_ISSUES.md`;
- `docs/TECHNICAL_GUIDE.md`;
- `docs/CHANGELOG_PROGRESS.md`.

### Note

`Medicine.times` e `Medicine.daysOfWeek` restano disponibili come viste di compatibilita', ma non devono essere usati per ricostruire slot operativi.

## Record legacy di medicine senza terapia

### Categoria

Problema tecnico da verificare.

### Stato

Rimandato

### Motivazione

Lo schema Drift consente ancora `therapyId` nullo per compatibilita' con dati precedenti. Il Provider non mostra tali record nella cache organizzata per terapie e questo sprint non introduce una migrazione automatica, per evitare di associare dati sanitari a una terapia arbitraria.

### Possibili soluzioni

- preparare una migrazione guidata che assegni una terapia scelta dall'utente;
- valutare un controllo di integrita' e rendere `therapyId` obbligatorio in una futura versione dello schema;
- aggiungere test di migrazione prima di modificare dati esistenti.

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
