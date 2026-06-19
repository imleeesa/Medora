# Problemi noti - Meditrack

Questo file raccoglie bug, discrepanze e rischi tecnici noti. Ogni problema dovrebbe restare tracciato fino a quando viene corretto, accettato come limite temporaneo o spostato nella roadmap.

## Formato delle voci

Ogni voce deve includere:

- problema;
- area;
- possibili cause;
- possibili soluzioni;
- stato.

## Naming non uniforme tra Medora e Meditrack

Area: identita' progetto.

Problema:

La cartella del progetto usa il nome Medora, mentre package Flutter, titolo app e documentazione usano Meditrack.

Possibili cause:

- rinomina parziale del progetto;
- vecchia identita' mantenuta in alcuni file;
- scelta del nome definitivo non ancora consolidata.

Possibili soluzioni:

- decidere il nome definitivo;
- aggiornare documentazione, package name, app label e riferimenti UI in modo coerente;
- valutare se cambiare anche application id Android quando il branding sara' stabile.

Stato: aperto.

## Tema scuro salvato ma non applicato

Area: UI e preferenze.

Problema:

Il profilo contiene `isDarkMode`, ma l'app forza `ThemeMode.light`.

Possibili cause:

- preferenza predisposta per sviluppo futuro;
- tema scuro non ancora rifinito graficamente.

Possibili soluzioni:

- collegare `themeMode` alla preferenza del profilo;
- verificare contrasto, card, navbar e schermate principali in dark mode;
- oppure nascondere temporaneamente il toggle finche' non e' realmente operativo.

Stato: aperto.

## Terapie non gestibili come entita' autonome

Area: dominio e UX.

Problema:

Le terapie vengono create indirettamente quando si aggiunge una medicina. Non esiste ancora un flusso dedicato per creare, modificare, archiviare o cancellare una terapia.

Possibili cause:

- fase prototipale concentrata sul flusso medicina;
- provider gia' predisposto ma non ancora esteso alla gestione completa delle terapie.

Possibili soluzioni:

- introdurre azioni dedicate per le terapie;
- mantenere il modello `TERAPIE -> MEDICINE`;
- aggiungere dettaglio terapia prima di introdurre database.

Stato: aperto.

## Storico assunzioni non operativo

Area: storico.

Problema:

Il model `IntakeRecord` esiste, ma la schermata Storico mostra solo uno stato vuoto e non registra assunzioni.

Possibili cause:

- mancano azioni di conferma, salto o ritardo assunzione;
- manca una lista di record nello stato applicativo;
- scorte e storico non sono ancora collegati.

Possibili soluzioni:

- aggiungere gestione in memoria degli `IntakeRecord`;
- creare azioni rapide dalla dashboard o dal dettaglio medicina;
- collegare la conferma assunzione al decremento scorte.

Stato: aperto.

## Notifiche locali non integrate nel flusso principale

Area: notifiche.

Problema:

`NotificationService` e' presente, ma non viene inizializzato all'avvio e non viene usato quando una medicina viene creata, modificata, disattivata o cancellata.

Possibili cause:

- servizio predisposto ma non collegato al provider;
- manca una strategia stabile per gli ID notifica delle medicine.

Possibili soluzioni:

- inizializzare il servizio in fase di avvio;
- pianificare notifiche alla creazione/modifica medicina;
- cancellare notifiche quando una medicina viene disattivata o rimossa;
- verificare permessi Android e iOS.

Stato: aperto.

## Backup e report PDF sono voci non operative

Area: impostazioni.

Problema:

Le voci Backup e Report medico PDF sono visibili nelle impostazioni, ma non eseguono azioni.

Possibili cause:

- funzionalita' pianificate ma non ancora implementate;
- placeholder utili alla roadmap.

Possibili soluzioni:

- mostrare un messaggio "funzione in arrivo";
- lasciare le voci disabilitate finche' non sono pronte;
- implementare report e backup solo nelle fasi previste.

Stato: aperto.

## Vecchio log di build con errore NDK

Area: build Android.

Problema:

`build_output.txt` contiene un errore relativo a NDK mancante o incompleto in un percorso precedente del progetto.

Possibili cause:

- installazione NDK corrotta o incompleta;
- log generato in una vecchia cartella;
- ambiente Android non allineato.

Possibili soluzioni:

- verificare `flutter doctor`;
- reinstallare o selezionare una versione NDK valida;
- rigenerare il log dopo un nuovo tentativo di build.

Stato: da verificare.

## Application ID Android ancora generico

Area: configurazione release.

Problema:

Il progetto Android usa ancora `com.example.meditrack`.

Possibili cause:

- configurazione Flutter iniziale non ancora personalizzata;
- branding definitivo non ancora deciso.

Possibili soluzioni:

- scegliere nome definitivo dell'app;
- impostare namespace e application id coerenti;
- aggiornare eventuali configurazioni store quando il progetto sara' pronto.

Stato: aperto.
