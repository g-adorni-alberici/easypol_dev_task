# dev_task_adorni

Dev Task Easypol - Gabor Adorni

# Scenario
Uno spin-off del team sviluppo di EasyPol si ferma spesso dopo il lavoro per un aperitivo. In quell’occasione i membri del team amano sperimentare nuovi cocktail e drink. Il locale dove vanno ha però un menù limitato, il che non lascia spazio molto spazio alla loro fantasia. Decidono quindi di sviluppare un’app che gli permetta di consultare una lista estesa di cocktail nella quale cercare nuovi drink filtrando ad esempio per nome o per ingrediente. Inoltre ogni Venerdí c'è l’usanza di condividere cocktail tra colleghi, per questo l’app potrebbe aiutarli a scambiarsi con facilità i cocktail preferiti tramite QRCode.

# Task
In qualità di Flutter Developer, hai totalmente in mano il progetto dell’app. I tuoi compagni sanno che riuscirai a sviluppare un’ottima applicazione che si integri con i sistemi di Backend di EasyPol.

La funzionalità più gettonata è quella che permette di scambiarsi i cocktail tramite QR Code. Ogni utente può generare un QR Code dalla propria app per un drink che vuole condividere, e gli altri possono inquadrare quel QRCode per visualizzarlo nell’app.

Essendo uno spin-off del team tecnico, gli altri team non vengono coinvolti. Per questo dovrai occuparti anche di progettare le interfacce e l’esperienza utente complessiva dell’app. Non hai nessun asset di design a disposizione.

Infine non volete assolutamente che gli altri team vengano a sapere del vostro progetto, perciò dovrai far si che sia possibile impostare un pin di sicurezza e accesso biometrico per accedere all’app.

## Funzionalità
- Lista cocktail
    - Ricerca per nome
    - Ricerca per ingrediente
    - Filtra per alcolico e non-alcolico
    - Filtra per categoria
- Dettaglio cocktail
- Poter segnare/rimuovere un cocktail come preferito
- Lista cocktail preferiti
- Condivisione cocktail tramite QRCode
- BONUS: Unit e Integration Testing

Dettagli delle API da cui prendere i dati:

Integra queste API all’interno dell’applicazione per ottenere i dati richiesti. Utilizza tutti gli endpoint che preferisci (chiaramente solo quelli free).

## Requisiti di progetto:
- Cross-Platform: iOS e Android
- Responsive (smartphone, tablet)
- PIN e Accesso Biometrico

## Vincoli Tecnici:
- Pattern State Management: Provider

# Valutazione e consegna

## Modalità di valutazione:
Valuteremo i seguenti aspetti:
- Corretto funzionamento delle funzionalità richieste
- Qualità del codice in termini di ordine, efficienza e sicurezza
- UI/UX dell’applicazione
- Scelte progettuali
- Velocità di consegna
- Prestazioni dell'app

## Modalità di consegna (passaggi obbligatori):
- Condivisione di un repository Git
- Rilascio su Apple TestFlight e/o Test interno Google Play Store
- Presentazione dell’assignment tramite Google Meet

# Soluzione Gabor Adorni

## Premesse:

Ho analizzato le API a disposizione su https://www.thecocktaildb.com/api.php:
- Le API di ricerca hanno un limite di 25
- La lista di ingredienti ha un limite di 100
- La ricerca dei cocktails per ingrediente può essere effettuata solo con la stringa intera (es. 'sug' -> risultati: 0, 'Sugar' risultati: >= 1)

## Soluzione
- Dati i limiti sopracitati ho optato per una gestione della ricerca e dei filtri completamente client-side.
- Al primo accesso verrà chiesto di impostare un codice PIN a 6 cifre (Per la simulazione lo salvo con il pacchetto shared_preferences)
- Il PIN impostato dovrà essere immesso ad ogni sessione successiva per accedere all'app.
- Se il dispositivo lo prevede è possibile accedere anche con l'impronta digitale.
- I dati verranno caricati una sola volta non appena si è autorizzati all'accesso dell'app.
- Dato il limite di 25 che non riusciva a rappresentare una situazione reale ho implementato il seguente work-around:
    - Utilizzo l'API per caricare i cocktails dato come parametro la lettera iniziale.
    - Grazie alla funzione Future.wait richiamo la GET per ogni lettera dell'alfabeto, in questo modo verranno gestite in asincrono e contemporaneamente.
    - Riconosco che in una situazione reale non è la soluzione ottimale, ma in questo modo posso lavorare su più di 500 elementi.
- L'app è composta principalmente da 2 schermate: 1 per la lista dei cocktails e l'altra per il dettaglio. Su tablet entrambe saranno sulla stessa schermata.
- La schermata principale a sua volta sarà divisa su 2 tab: 1 per lista completa dei cocktails e l'altra per i preferiti.
- Sulla toolbar saranno presenti 2 funzioni:
    - Ricerca per nome cocktail o per nome ingrediente
    - Filtro con selezione tra alcolico / non alcolico e le categorie caricate con la relativa API.
- Dalla schermata principale sarà possibile accedere alla fotocamera per la scansione dei codici QR.
- Verranno riconosciuti solo i QR che contengono un codice apposito e l'id del cocktail. In caso di codice corretto verrà riportata la relativa schermata di dettaglio.
- Nella schermata di dettaglio saranno visualizzabili dati come la ricetta, il bicchiere, ecc. Inoltre verrà mostrata la lista degli ingredienti con la relativa quantità.
- Nel dettaglio sarà possibile generare un codice QR che potrà essere condiviso con gli strumenti disponibili sul dispositivo.


