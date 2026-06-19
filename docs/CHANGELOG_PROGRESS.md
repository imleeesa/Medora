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
