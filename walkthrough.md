# Walkthrough - Dashboard Admin "Regia Live" di Pechino Express Bra

Abbiamo trasformato completamente il pannello ADMIN in una vera **Console di Regia Live** per il Direttore di Gara, basata integralmente su dati memorizzati in tempo reale nel database locale (`local_database.json`).

> [!NOTE]
> **Rimpiazzo & Unificazione Dashboard**:
> L'account **ADMIN** non gareggia. Di conseguenza, l'interfaccia della squadra per l'admin è stata completamente rimpiazzata dalla **Regia Live**:
> * All'accesso, l'admin viene indirizzato direttamente a `/dashboard` dove viene renderizzato il pannello Regia Gara.
> * Il link della sidebar e la barra di navigazione mobile cambiano automaticamente il testo da "Squadra" a **"Dashboard"** per l'admin.
> * Qualsiasi tentativo di accedere manualmente a `/admin` reindirizza automaticamente alla dashboard unificata `/dashboard`.

---

## Funzionalità Implementate

### 1. Header Superiore - Stato Gara & Cronometro
* **Stato Gara Interattivo**: Un selettore dinamico permette alla regia di cambiare lo stato del gioco tra *Gara non iniziata*, *Gara attiva* e *Gara terminata*, salvando lo stato direttamente nella tabella `settings` del database.
* **Cronometro Dinamico**: Un orologio in tempo reale (aggiornato al secondo) che calcola il tempo trascorso dall'avvio della gara leggendo il timestamp `game_started_at` memorizzato nel DB.
* **Metriche Istantanee**: Visualizzazione delle squadre totali iscritte, squadre attive sul campo e numero di prove in coda da approvare.

### 2. Live Monitor delle Squadre
* Una tabella riassuntiva centrale elenca tutte le squadre con le seguenti informazioni dinamiche:
  * **Nome squadra** (con colore identificativo)
  * **Stato attuale** (🟢 Attiva, 🟡 In Attesa di approvazione, 🔴 Disattivata)
  * **Tappa Corrente** (calcolata in base alle prove completate)
  * **Ultima Azione** svolta e l'orario esatto
  * **Punteggio totale** accumulato
  * **Tempo totale** impiegato
  * **Numero di prove completate**
* Cliccando su una riga della tabella, l'interfaccia reindirizza automaticamente alla tab "Gestione Squadre" aprendo la timeline di dettaglio di quella squadra.

### 3. Coda Approvazioni & Motivazione di Rifiuto
* **Dettagli Sottomissione**: Quando una squadra invia un allegato, l'admin vede la foto caricata, la risposta, la posizione GPS del team e il **tempo impiegato** per completare la sfida (calcolato dal momento in cui è stata avviata).
* **Motivazione Rifiuto Obbligatoria**: Premendo "Rifiuta", l'admin deve inserire obbligatoriamente una motivazione all'interno di una finestra modale. Il messaggio viene salvato nel database ed inviato alla squadra, che dovrà ripetere la prova dallo stato "da rifare".

### 4. Mappa Live
* Integrata una mappa interattiva utilizzando la libreria **Leaflet** (caricata dinamicamente via CDN) con il tema scuro *CARTO Dark*.
* La mappa posiziona:
  * I checkpoint geografici definiti per la gara di Bra.
  * I pin in tempo reale di ciascuna squadra, prendendo le coordinate GPS dall'ultimo invio registrato.
* Cliccando sui marker è possibile vedere l'ultima attività svolta dalla squadra e l'orario di aggiornamento.

### 5. Classifica Live
* La Classifica Generale si aggiorna all'istante ed è ordinata in base ai seguenti criteri competitivi:
  1. Punteggio massimo
  2. Maggior numero di prove completate
  3. Minor tempo complessivo impiegato

### 7. Rimozione Riepilogo per Admin & Nuovo Summary Tappe/Sfide
* **Filtro Sidebar e Mobile Nav**: Rimosso completamente il gruppo **"Riepilogo"** (contenente Tappe, Badge, Storico) sia dal menu laterale che dalla navigazione mobile quando l'utente loggato è l'Admin, garantendo che non veda sezioni specifiche delle squadre.
* **Riepilogo Tappe e Sfide**: Sotto la tab *"Configurazione Gara"*, l'admin ha ora una sezione dedicata a tutta larghezza con un riepilogo leggibile di tutte le tappe salvate nel database ordinate, con l'elenco completo delle prove associate ad esse, il loro tipo di sfida e il punteggio massimo impostato.

### 8. Tappa 2: Rebus Visivo (🐌 Slow Food) & Blocco Tappe
* **Briefing immersivo**: Quando la squadra apre la prova della Tappa 2, se non è ancora stata avviata, viene visualizzato un testo atmosferico misterioso:
  > *"A volte, Viaggiatori, non serve decifrare: serve solo... sapere. Questa immagine non nasconde suoni né sillabe. È un simbolo, puro e semplice. Chi conosce davvero Bra, sa già dove correre."*
  ed un pulsante **"Inizia Missione"**.
* **Simbolo🐌 e Upload**: Cliccando su "Inizia Missione", la prova viene registrata come avviata nel database. L'interfaccia rimuove qualsiasi testo/indizio e mostra unicamente l'emoji **🐌** ingrandita e pulsante, insieme all'interfaccia di upload della foto (con anteprima, opzione di sostituzione e salvataggio metadati GPS/timestamp nel database).
* **Spostamento Let's Fib**: Spostata la sfida "Let's Fib" sotto la nuova **Tappa 3** senza alternarne il funzionamento.
* **Blocco Progressionale**: Le tappe successive (es. Tappa 2, Tappa 3) rimangono bloccate, non cliccabili nella lista e inaccessibili via URL finché tutte le prove della tappa precedente non sono completate.

### 9. Somma dei Tempi, Sidebar Premium & Setup Squadra Esteso
* **Somma del Tempo delle Tappe**: Il timer nella dashboard della squadra calcola ora la somma esatta dei tempi attivi spesi in ciascuna tappa (dall'inizio della prima sfida al completamento dell'ultima), evitando di penalizzare le squadre per le pause di gioco tra le tappe. Inoltre, se una tappa è attiva, il contatore si incrementa in tempo reale (ticking) ogni secondo.
* **Allineamento Classifica**: Anche la classifica generale (`leaderboard`) è stata sincronizzata per calcolare il tempo dei team con la medesima somma attiva delle tappe.
* **Design Sidebar Premium**:
  * Logo testuale valorizzato in lettere maiuscole con un gradiente dorato brillante e l'icona della bandiera racchiusa in un box sfumato con ombra.
  * Voci di menu ridisegnate con angoli arrotondati, transizioni fluide all'hover e un elegante bordo a sinistra dorato con sfondo traslucido quando la voce è attiva.
  * **Correzione Allineamento**: Ripristinati i parametri nativi del componente sidebar di shadcn-ui (rimosso `p-0 h-auto` che causava disallineamenti e testo storto) ed equilibrato l'offset del padding a sinistra del link attivo (`pl-1.5`) per compensare il bordo attivo (`border-l-2`) al pixel. Ora il layout della sidebar è 100% dritto, centrato e allineato sia in modalità aperta che collassata a icone.
* **Catalogo Esteso per la Creazione Squadra**:
  * Espansione a **12 colori** neon e d'avventura (es. rosso cremisi, verde smeraldo, viola reale, blu neon, oro).
  * Espansione a **24 avatar** unici (e.g. 🐼, 🐨, 🦖, 🏔️, 🧭, 🎒, ⚔️, 🏆, 🗺️).

### 10. Mappa Dinamica Tappe, Rimozione Pannelli di Aggiunta & Palette Pechino Express
* **Mappa Live Dinamica**: Inserite le coordinate `latitude` e `longitude` per tutte le tappe nel database (seeding e migrazione automatica dei dati esistenti). `LiveMap` disegna ora tutti i checkpoint delle tappe dinamicamente dalle informazioni del database, posizionando correttamente la Tappa 1 (Piazza Caduti per la Libertà, 14), la Tappa 2 (Via Mendicità Istruita, 12) e qualsiasi tappa/sfida aggiuntiva.
* **Rimozione Sezioni di Aggiunta**: Rimosse completamente le sezioni "Aggiungi Tappa" e "Aggiungi Prova" dalla tab *"Configurazione Gara"* dell'account admin, lasciando esclusivamente il riepilogo in sola lettura per una consultazione pulita e sicura.
* **Campionamento Palette Pechino Express**: Ridisegnata la combinazione cromatica della sidebar riproducendo i colori dello show televisivo:
  * Sfondo della barra: Deep Navy Blue (`#070d1e`) ad alta densità.
  * Stato attivo: Sunset Orange brillante (`#f97316`) con sfondo sfumato arancione traslucido (`bg-orange-500/10`) e linea di accento sinistra arancione.
  * Voci inattive: Testo in tonalità blu/azzurro morbido (`text-blue-200/60` con hover luminoso).
  * Logo in alto: Cerchio con gradiente dal rosso all'arancio fuoco e ombra arancione.
* **Live Tracking & Polling in Tempo Reale**: Impostato un intervallo di aggiornamento in background (`refetchInterval: 3000`) per le interrogazioni delle squadre, dei progressi di gara e delle risposte inviate su entrambe le interfacce:
  * L'account **Regia/Admin** interroga costantemente il database locale, consentendo alla mappa Leaflet di aggiornare istantaneamente gli indicatori GPS e i movimenti delle squadre in tempo reale sul territorio urbano.
  * L'interfaccia **Squadra** si auto-aggiorna in tempo reale sincronizzando lo stato della prova e il timer di gara appena la regia valida o rifiuta una consegna.

## Verifica e Compilazione

* Abbiamo eseguito il controllo di sintassi TypeScript con:
  ```bash
  npx tsc --noEmit
  ```
  La compilazione termina con successo con **0 errori**.
* Il server di sviluppo locale Nitro/Vite sta girando regolarmente in background su **`http://localhost:8080/`**.

---

## 11. Tappa 2 - Sfide Aggiuntive: Gioco Cinema & Locandina Vivente

Abbiamo arricchito la **Tappa 2** configurando tre sfide sequenziali, collegate in modo persistente al database locale:

### 🐌 Sfida 2.1: Il Rebus Visivo (Chiocciola Slow Food)
* **Tipo**: Invio Foto (`photo`), valore `20 punti`, ordine `1`.
* Ripristinata la schermata di briefing originale con l'emoji `🐌` e l'upload della foto.

### 🎬 Sfida 2.2: Indovina il film dalle emoji
* **Tipo**: Gioco Emoji Cinema (`emoji_movies`), valore `8 punti` (1 punto per film), ordine `2`.
* Le squadre devono indovinare gli 8 film misteriosi descritti da emoji in una tabella. A ogni risposta corretta viene sbloccata una lettera e assegnato `+1 PT` in tempo reale.
* La sfida ha una grafica a tema sala cinematografica (sfondo scuro ed accenti rossi). Al termine della decifrazione di tutte le lettere, compare la parola **VITTORIA** ed un pulsante per salvare il progresso.

### 🎭 Sfida 2.3: La Locandina Vivente
* **Tipo**: Gioco Foto Interpretativa (`living_poster`), valore fino
## 🧪 15. TEST AUTOMATIZZATI ORDINAMENTO MARKETPLACE

1.  **TypeScript**: Il comando `npx tsc --noEmit` completa con codice di uscita `0`.
2.  **Unit Tests Ordinamento (`test_marketplace_sorting.js`)**: Convalida il corretto caricamento, il raggruppamento separato delle categorie, l'ordinamento per costo decrescente, la stabilità dell'ordinamento alfabetico secondario a parità di prezzo, e l'aggiornamento dinamico dell'ordine al variare del costo degli elementi sul database. Tutti i test passano con successo (codice uscita `0`).

---

## 🛡️ 16. AUDIT COMPLETO DEL SISTEMA MARKETPLACE (BONUS & MALUS)

Abbiamo eseguito un audit profondo ed end-to-end dell'intero sistema del Marketplace, convalidando le autorizzazioni, l'oscuramento dei dati (Black Box), i limiti di addebito dei Token, la persistenza e le protezioni degli Scudi.

### Correzioni Applicate durante l'Audit

1.  **Capping del Punteggio nella Ruota Sfortunata** (Backend - [`localDbServer.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/integrations/supabase/localDbServer.ts)):
    *   *Problema*: Le penalità di punteggio derivanti dalle estrazioni `minus_20_points` e `minus_10_points_minus_5_tokens` della Ruota Sfortunata inserivano record negativi fissi a database senza considerare il punteggio corrente della squadra. Questo permetteva a una squadra di scendere sotto lo zero (es. punteggio negativo).
    *   *Soluzione*: Calcolato preventivamente il punteggio attuale e applicato un capping atomico `Math.max(0, Math.min(amount, teamCurrentPoints))` che impedisce ai punti di scendere sotto `0`, uniformandosi al comportamento di tutti gli altri Malus del gioco.
2.  **Costo Dinamico per il Success Toast di Bonus Punti** (Frontend - [`marketplace.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/marketplace.tsx)):
    *   *Problema*: Il messaggio toast visualizzava una sottrazione fissa e cablata di 40 Token (`balance - 40`), ignorando eventuali modifiche future dei prezzi a livello database.
    *   *Soluzione*: Sostituita la costante con la lettura dinamica `mergedItems.find(i => i.id === "bonus_punti")?.costo`.

### 🧪 17. TEST DI VALIDAZIONE DELL'AUDIT

1.  **TypeScript**: Il comando `npx tsc --noEmit` completa con codice di uscita `0`.
2.  **Audit Test Suite (`test_marketplace_audit.js`)**: Scritto ed eseguito un test di sistema completo che verifica:
    *   *Insufficient Token Check*: Blocco degli acquisti se il saldo è inferiore al costo.
    *   *Double Click / Double Purchase Prevention*: Richieste consecutive dello stesso articolo rifiutate.
    *   *Shield Blocking*: Scudo consumato (`used`), transazione bloccata (`blocked`), e token correttamente addebitati all'attaccante.
    *   *Points Capping*: Verifica che i punti non scendano mai sotto 0 sia per la Ruota Sfortunata che per gli altri Malus.
    *   *Black Box Privacy*: Hiding automatico di punti e token avversari per i Team non in possesso del Classifica Bonus.
    *   Tutti i test passano con successo (codice uscita `0`).
3.  **Regression Tests**: Eseguiti nuovamente tutti i test unitari preesistenti (`test_enigma_extra.js`, `test_freeze_malus.js`, `test_penalita_punti_malus.js`, `test_tassa_passaggio.js`, `test_trappola_malus.js`, `test_unlucky_wheel.js`). Tutti i test passano con successo con codice uscita `0`.
* **Assegnazione persistente senza duplicati**: Al primo accesso, il sistema assegna casualmente alla squadra una locandina da replicare scelta tra 10 disponibili. L'assegnazione viene memorizzata nel database (`team_posters`) in modo che non cambi mai anche se cambiano dispositivo o si aggiorna il server. Il sistema sceglie le locandine meno assegnate evitando duplicati tra le squadre.
* **Caricamento e completamento**: La squadra scatta e invia la propria foto ricostruita. La consegna viene registrata su database (`submissions`) e la sfida viene completata all'istante, sbloccando la Tappa successiva.
* **Pannello Regia per Valutazione**: L'admin dispone della tab dedicata **"Locandine Viventi"** che presenta un comodo layout affiancato:
  * Modificando un voto precedentemente confermato, l'admin visualizza un pop-up di avviso. Il punteggio viene aggiunto in tempo reale nello storico dei punteggi della squadra.

---

## 12. Sblocco Immediato Sfide Foto & Verifica Punteggi Regia

Per ottimizzare la fluidità di gioco sul campo, abbiamo ripensato il ciclo di vita delle sfide fotografiche standard (es. la Chiocciola `🐌` o le prove di Tappa 1):

* **Sblocco Autonomo**: Quando i partecipanti scattano e caricano la foto ufficiale per una sfida di tipo `photo`, la prova viene **completata all'istante** sul loro telefono. Vengono accreditati i punti massimi di default e viene sbloccata immediatamente la sfida successiva senza costringere le squadre ad attendere l'approvazione manuale della regia per poter proseguire.
* **Pannello di Regia "Verifica Foto"**: La tab "Approvazioni" è stata rinominata in **"Verifica Foto"**. Qui l'admin può monitorare tutte le sottomissioni fotografiche (escluse le locandine viventi, che hanno una tab dedicata) organizzate in due liste:
  * **Da Verificare**: Foto caricate di recente e non ancora verificate dalla regia.
  * **Già Verificate**: Archivio delle foto già controllate.
* **Gestione dei Punteggi (Conferma o Decurtazione)**:
  * Per ogni foto, l'admin vede l'allegato, le coordinate GPS, l'orario e il tempo speso.
  * L'admin può confermare direttamente il punteggio massimo già assegnato premendo *"Conferma Punteggio"*, oppure modificarlo (inserendo un voto inferiore, fino a `0` punti) in caso di foto errate o non conformi.
  * L'aggiornamento aggiorna all'istante il database, la classifica e i progressi generali del team. Se una foto è già stata confermata, una finestra di dialogo avverte la regia prima di sovrascrivere il punteggio.

---

## 13. Tappa 3: La Stazione Ferroviaria & Eliminazione "Let's Fib"

* **Eliminazione Completa**: Abbiamo rimosso interamente la sfida Let's Fib dal sistema (cancellato [`LetsFibChallenge.tsx`](file:///src/components/challenges/LetsFibChallenge.tsx), rimossa l'importazione e rimosso il ramo condizionale dal router [`challenge.$challengeId.tsx`](file:///src/routes/_authenticated/challenge.$challengeId.tsx)).
* **Tappa 3: La Stazione**: Riprogrammata come **"Tappa 3: La Stazione"** (Stazione Ferroviaria di Bra) con una sfida fotografica per inviare una foto artistica della stazione ferroviaria.
* **Sblocco**: Al completamento della Sfida 2.3 (Locandina Vivente), la Tappa 3 e la sua sfida si sbloccano automaticamente per i partecipanti.

---

## 14. Sistema Marketplace & Economia dei Token 🪙

Abbiamo implementato l'economia dei **Token 🪙** e il negozio di potenziamenti strategici (6 Bonus e 6 Malus) con logica database-first:

### 🔓 Sblocco Marketplace
* Il Marketplace è disponibile **solo a partire da Tappa 3**.
* **Protezione Gara**: Prima della Tappa 3, il link "🛒 Marketplace" è rimosso dalla sidebar, e l'accesso diretto alla pagina `/marketplace` restituisce una schermata di accesso negato. Eventuali chiamate API di acquisto vengono bloccate sul server.

### 🪙 Sistema dei Token
* Ciascuna squadra inizia la gara con **50 Token 🪙** (salvati nella colonna `token_balance` della tabella `TEAMS`).
* Il saldo corrente viene mostrato in tempo reale in cima al Marketplace e nella stats card della Dashboard squadra.

### 🛡️ Regole e Catalogo Prodotti
* **Vincolo di Unicità**: Ciascun articolo può essere acquistato al massimo **una sola volta per squadra** durante l'intera gara.
* **Controllo Preventivo**: In caso di token insufficienti o articolo già acquistato, il bottone si disabilita e viene mostrato il messaggio di errore:
  > `"Questo oggetto è già stato utilizzato oppure non possiedi abbastanza token."`

---

## 15. Controllo di Attivazione e Stati del Marketplace (Gestione Regia)

Abbiamo introdotto una gestione avanzata a due stati controllata centralmente tramite il database (`GAME_SETTINGS` table):

### 1. Visibilità (Auto-scoperta)
* Il Marketplace è nascosto fino al completamento della **Tappa 2 - Prova 3 (La locandina vivente)**.
* Non appena *una qualsiasi* squadra completa la Prova 3 o l'Admin assegna il voto finale alla foto della locandina vivente, il sistema imposta automaticamente `marketplace_visible = true` in database.
* La voce "Marketplace" compare nella sidebar di **tutte le squadre**.

### 2. Stato Marketplace (Aperto vs Chiuso)
L'Admin gestisce manualmente l'apertura e la chiusura degli scambi tramite la console di regia.
* **Stato Chiuso (🔒)**:
  * L'icona in sidebar mostra un lucchetto (🔒).
  * Entrando nella pagina, le squadre visualizzano esattamente il messaggio:
    > *"Il Marketplace è stato scoperto, ma il Regista non ha ancora aperto gli scambi. Rimanete pronti: l'apertura potrebbe avvenire in qualsiasi momento."*
  * Tutti i pulsanti di acquisto sono disattivati e non è possibile effettuare transazioni (bloccate anche lato API).
* **Stato Aperto (🛒)**:
  * L'icona in sidebar cambia nel carrello (🛒).
  * Entrando nella pagina, compare il messaggio:
    > *"Il Marketplace è ufficialmente aperto! Potete utilizzare i vostri Token."*
  * Gli acquisti sono abilitati e funzionali.

### 👑 Console di Controllo Regia (Admin)
La tab **Marketplace** dell'amministratore include ora una card **CONTROLLO MARKETPLACE** che mostra:
* **Stato attuale**: Indicatore dinamico `🟢 Attivo` o `🔴 Chiuso`.
* **Azioni in tempo reale**: Pulsanti `[Apri Marketplace]` e `[Chiudi Marketplace]` che cambiano all'istante lo stato tramite RPC.
* **Statistiche e Metadati**:
  * Data apertura (`activated_at`)
  * Admin che ha effettuato l'apertura (`activated_by`)
  * Numero totale acquisti effettuati nella gara
  * Token totali spesi da tutte le squadre.
* **Registro Globale**: Storico cronologico completo di tutte le transazioni di gara, salvate in modo permanente nella tabella `MARKETPLACE_TRANSACTIONS` del database locale per mantenere lo storico completo.

---

## 16. Nuove Sfide Tappa 3: La Banca & Missione Social

### 1. Ridenominazione e Pulizia Tappa 3
* **Ridenominata la Tappa 3** da "Tappa 3: La Stazione" a "La Banca".
* **Rimossa la vecchia sfida** generica della Stazione, lasciando solo le nuove sfide.

### 2. Tappa 3 - Sfida 1: La Banca
* **Componente [BancaChallenge.tsx](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/components/challenges/BancaChallenge.tsx)**:
  * Implementati 4 enigmi interattivi (Bancomat, Pin, Euro, Rata) le cui lettere estratte formano la parola finale sbloccante **BPER**.
  * Controllo sblocco lato server: la sfida non è avviabile se l'admin non ha attivato il Marketplace (`marketplace_active = true`).
  * Integrati controlli amministrativi dedicati in `admin.tsx` per forzare il completamento, resettare o modificare le risposte inserite dalle squadre.

### 3. Tappa 3 - Sfida 2: Missione Social
* **Componente [SocialChallenge.tsx](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/components/challenges/SocialChallenge.tsx)**:
  * Richiede obbligatoriamente il caricamento di 2 foto distinte scattate con 2 sconosciuti differenti.
  * **Auto-Avanzamento Immediato**: Non appena i concorrenti caricano e inviano le foto, la sfida viene impostata come completata nel database e l'interfaccia abilita all'istante il pulsante **"Prosegui la Gara"**, sbloccando la prosecuzione senza attendere l'admin.
  * Controllo sblocco lato server: legata all'attivazione del Marketplace (`marketplace_active`).
* **Valutazione Regia e Punteggio**:
  * Creata la sezione tab dedicata **📸 Missioni Social** all'interno della dashboard admin (`admin.tsx`).
  * L'admin può visualizzare in tempo reale le due foto caricate con la data di consegna e filtrare per stato (Completate, In Attesa, Rifiutate, Tutte).
  * L'admin valuta in differita per assegnare o togliere punti extra da 0 a 10 tramite lo slider di gradazione, senza bloccare l'esperienza e l'avanzamento dei concorrenti sul campo.
## Tappa 3 - Sfida 3: Il Codice Segreto
* **Concept e Flusso Gara**:
  * Il PIN finale della gara è composto da 10 cifre (`4829167305`) ed è persistito in `game_final_code`.
  * La meta finale è: `Parco Giochi Madonna dei Fiori (lato piazzale grigio)`.
  * Ad ogni squadra viene assegnata solo metà del codice (`FIRST_5` o `LAST_5`).
  * Le squadre sono collegate in un circuito ad anello chiuso ($T_i$ compra da $T_{i+1}$) persistito in `team_code_matches`.
  * Il costo in token viene generato casualmente tra 1 e 5 al momento dell'inizializzazione del circuito.
* **Transazioni e Gestione Squadre Dispari**:
  * Gli acquisti detraggo i token dal saldo del compratore ed accreditano al venditore.
  * In caso di squadre attive dispari, il circuito ad anello rimane chiuso ma il pagamento è neutro (il venditore non riceve alcun token).
* **Console Amministratore**:
  * Aggiunto il tab **Gestione Codice Segreto** alla dashboard.
  * Consente di visualizzare e aggiornare il PIN globale e la destinazione sbloccata.
  * Mostra il dettaglio di ciascun team (frammento posseduto, partner, costo, stato di sblocco).
  * Consente di forzare il completamento o modificare in-line gli abbinamenti ed i costi dei frammenti.
  * Monitora le transazioni e registra in tempo reale ogni singolo tentativo di inserimento PIN (`pin_attempts`).

## Report di Bilanciamento Punteggi & Dashboard Analitica
* **Report Offline**: Generato il documento statico dettagliato [`report_analisi_punteggi.md`](file:///Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/report_analisi_punteggi.md) contenente l'estrazione di tutti i punteggi, la categorizzazione delle prove (abilità, fortuna, sociali, strategiche, velocità) e le criticità relative al peso della Tappa 2 e dei costi del Marketplace.
* **Dashboard Online (`admin.tsx`)**: Integrato il tab **📊 Analisi Gara** nella console admin, che raggruppa in tempo reale i dati reali dal database locale e renderizza:
  * **Metriche & Tabelle**: Tappe, sfide totali, squadre attive e riepilogo del peso percentuale di ciascuna tappa sul punteggio massimo totale (138 PT).
  * **Grafici Recharts**:
    1. Distribuzione dei punti per tappa (Bar Chart).
    2. Peso percentuale per categoria di sfida (Pie Chart).
    3. Confronto a barre affiancate tra il punteggio attuale e il punteggio consigliato per ciascuna prova.
  * **Pulsante di Stampa / PDF**: Sfrutta le regole CSS `@media print` per nascondere tutti gli elementi non stampabili (sidebar, header, pulsanti) ed esportare nativamente in A4 una copia perfetta e pulita del report.

## Risoluzione Instabilità Login Admin & Correzione Regole Hook React
* **Causa del Bug**:
  1. *Hook Condizionali nel Tab Codice*: All'interno del tab `"codice"` in `admin.tsx`, c'erano diverse dichiarazioni di `useState` racchiuse all'interno di una IIFE a sua volta eseguita in modo condizionato `{activeTab === "codice" && (() => { ... })()}`. Questo causava una variazione sistematica nel numero di hook eseguiti ad ogni render a seconda del tab selezionato, innescando l'errore React.
  2. *Return Condizionali ed Instabilità Strutturale del Layout*: Nel componente `Dashboard` (`dashboard.tsx`), l'utente admin veniva reindirizzato ritornando l'intero componente `<AdminPage />` come sotto-ramo condizionale, il che induceva React a distruggere e ricreare l'albero di `AppShell` durante lo stato asincrono di caricamento del ruolo (`isAdmin.isLoading`), portando a discrepanze nel numero di hook attivi.
* **Correzioni Definitive Effettuate**:
  1. *Spostamento degli Hook*: Tutti gli `useState` del codice segreto e di amministrazione (compresi `isProcessingBank`, `isEvaluatingSocial`, `isForcingCode`, `isEditingCodeMatch` e `isUpdatingCodeSettings`) sono stati dichiarati a livello di radice nel componente `AdminPage` per garantire che vengano eseguiti sempre nello stesso identico ordine, sincronizzandone i valori tramite un `useEffect` stabile guidato dalla query `secretCodeDashboard.data`.
  2. *Unificazione e Separazione delle Rotte*: Rimossa la renderizzazione condizionale di `<AdminPage />` all'interno di `Dashboard`. Adesso l'admin viene reindirizzato in modo pulito alla rotta regia `/admin` tramite un `useEffect` programmato e un loader stabile all'interno dello stesso albero di `AppShell`.
  3. *Instradamento Diretto dell'Admin*: Aggiornata la pagina di login `auth.tsx` per instradare direttamente l'utente `justdave` alla rotta `/admin` non appena la sessione viene autenticata con successo, evitando loop o flash intermedi.
  4. *Allineamento della Sidebar*: Aggiornati i link di navigazione in `AppShell.tsx` per puntare direttamente a `/admin` se l'utente possiede il ruolo admin.

## Calibrazione Nuova Scala Punteggi Ufficiali (145 PT) & Migrazione Versionata
* **Nuovo Sistema di Scoring**:
  * Allineati tutti i massimali delle sfide del gioco secondo la nuova scala punti ufficiale:
    * Creazione squadra $\rightarrow$ **5 PT**
    * Quiz Bra $\rightarrow$ **15 PT** (domande ricalibrate a **3 PT** ciascuna)
    * Foto ufficiale $\rightarrow$ **10 PT**
    * Il Rebus Visivo $\rightarrow$ **25 PT**
    * Emoji Film $\rightarrow$ **15 PT** (1 PT per risposta corretta + 7 PT bonus di completamento)
    * Locandina vivente $\rightarrow$ **15 PT** (scala di valutazione admin estesa a 0-15 PT)
    * La Banca $\rightarrow$ **25 PT**
    * Missione Social $\rightarrow$ **20 PT** (scala di valutazione admin estesa a 0-20 PT)
    * Il Codice Segreto $\rightarrow$ **15 PT**
* **Migrazione Versionata (`database_migration_version = "1.0.0"`)**:
  * Integrata una logica di migrazione atomica a livello di server in `localDbServer.ts`.
  * All'avvio dell'applicazione (o alla prima richiesta server), il sistema controlla la versione del database nei `settings`. Se non allineato, esegue una sola volta la transizione dei massimali delle sfide, aggiorna i record storici in `scores` per le squadre esistenti e registra il completamento della migrazione.
* **Form Creazione Nuove Sfide (Tab Setup Admin)**:
  * Inserito un modulo interattivo nel tab "setup" per l'aggiunta di nuove sfide.
  * Il form pre-compila i punti in base alla difficoltà scelta (Molto Bassa: 5, Bassa: 10, Media: 15, Media-Alta: 20, Alta: 25) e consente la modifica manuale da parte dell'admin prima dell'invio.

## Calibrazione Requisiti di Progressione per lo Sblocco del Marketplace
* **Sblocco automatico a Tappa 1**: Spostata la visibilità automatica (`marketplace_visible = true`) in `localDbServer.ts` al completamento della Sfida 3 di Tappa 1 (Foto Ufficiale: `"0147e750-f0a3-4b72-8e76-a003fe2ef143"`).
* **Nuovo Controllo di Progressione**: 
  * In `AppShell.tsx`, caricata ed eseguita `progressQuery` in background per verificare se la squadra ha completato la Tappa 1. Il link al Marketplace viene visualizzato nella sidebar di navigazione solo a chi ha effettivamente superato la Foto Ufficiale.
  * Nella rotta `/marketplace` in `marketplace.tsx`, viene effettuato il controllo incrociato: se la squadra non ha completato la Tappa 1, l'accesso è negato tramite un blocco "Area Riservata" con testo allineato al superamento della Tappa 1.
* **Controllo Attivo Admin**:
  * Se l'ADMIN apre il Marketplace, esso diventa disponibile per l'acquisto solo a chi ha sbloccato la Tappa 1.
  * Se l'ADMIN chiude il Marketplace, l'accesso viene revocato istantaneamente per tutti i partecipanti (anche per coloro che hanno completato la Tappa 1), rendendo visibile la schermata di blocco "Area Riservata - Temporaneamente chiuso dalla Regia".
* **RPC di Acquisto Allineato**: Aggiornata la RPC `buy_marketplace_item` per bloccare a livello server transazioni per squadre che non hanno ancora completato le prove di Tappa 1.

---

## 🏪 14. MARKETPLACE — ORDINAMENTO BONUS E MALUS PER COSTO

### Ordinamento Dinamico & Categorie Separate
Il layout visivo del Marketplace è stato modificato per presentare gli elementi ordinati per costo in Token decrescente:
*   **Bonus e Malus separati**: Le due sezioni del negozio (`🌟 BONUS` e `⚠️ MALUS`) rimangono separate.
*   **Ordinamento decrescente per costo**: All'interno di ciascuna sezione, gli articoli vengono disposti dal costo più alto al costo più basso.
*   **Ordinamento alfabetico secondario**: In caso di parità di costo tra più articoli (ad esempio, *Bonus Scudo* e *Partenza Anticipata* entrambi a 35 Token), viene applicato un ordinamento alfabetico crescente per nome (A-Z) per garantire una visualizzazione stabile.
*   **Source of Truth**: Il costo di ciascun elemento viene letto dinamicamente dal database (`marketplace_items.costo_token`) tramite la query `marketplaceItemsQuery`. Modifiche future apportate ai prezzi da pannelli admin o modifiche al database json provocheranno l'aggiornamento dell'ordine visualizzato in tempo reale senza modifiche al codice.

---

## 🧪 15. TEST AUTOMATIZZATI ORDINAMENTO MARKETPLACE

1.  **TypeScript**: Il comando `npx tsc --noEmit` completa con codice di uscita `0`.
2.  **Unit Tests Ordinamento (`test_marketplace_sorting.js`)**: Convalida il corretto caricamento, il raggruppamento separato delle categorie, l'ordinamento per costo decrescente, la stabilità dell'ordinamento alfabetico secondario a parità di prezzo, e l'aggiornamento dinamico dell'ordine al variare del costo degli elementi sul database. Tutti i test passano con successo (codice uscita `0`).

---

## 🛡️ 16. AUDIT COMPLETO DEL SISTEMA MARKETPLACE (BONUS & MALUS)

Abbiamo eseguito un audit profondo ed end-to-end dell'intero sistema del Marketplace, convalidando le autorizzazioni, l'oscuramento dei dati (Black Box), i limiti di addebito dei Token, la persistenza e le protezioni degli Scudi.

### Correzioni Applicate durante l'Audit

1.  **Capping del Punteggio nella Ruota Sfortunata** (Backend - [`localDbServer.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/integrations/supabase/localDbServer.ts)):
    *   *Problema*: Le penalità di punteggio derivanti dalle estrazioni `minus_20_points` e `minus_10_points_minus_5_tokens` della Ruota Sfortunata inserivano record negativi fissi a database senza considerare il punteggio corrente della squadra. Questo permetteva a una squadra di scendere sotto lo zero (es. punteggio negativo).
    *   *Soluzione*: Calcolato preventivamente il punteggio attuale e applicato un capping atomico `Math.max(0, Math.min(amount, teamCurrentPoints))` che impedisce ai punti di scendere sotto `0`, uniformandosi al comportamento di tutti gli altri Malus del gioco.
2.  **Costo Dinamico per il Success Toast di Bonus Punti** (Frontend - [`marketplace.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/marketplace.tsx)):
    *   *Problema*: Il messaggio toast visualizzava una sottrazione fissa e cablata di 40 Token (`balance - 40`), ignorando eventuali modifiche future dei prezzi a livello database.
    *   *Soluzione*: Sostituita la costante con la lettura dinamica `mergedItems.find(i => i.id === "bonus_punti")?.costo`.

### 🧪 17. TEST DI VALIDAZIONE DELL'AUDIT

1.  **TypeScript**: Il comando `npx tsc --noEmit` completa con codice di uscita `0`.
2.  **Audit Test Suite (`test_marketplace_audit.js`)**: Scritto ed eseguito un test di sistema completo che verifica:
    *   *Insufficient Token Check*: Blocco degli acquisti se il saldo è inferiore al costo.
    *   *Double Click / Double Purchase Prevention*: Richieste consecutive dello stesso articolo rifiutate.
    *   *Shield Blocking*: Scudo consumato (`used`), transazione bloccata (`blocked`), e token correttamente addebitati all'attaccante.
    *   *Points Capping*: Verifica che i punti non scendano mai sotto 0 sia per la Ruota Sfortunata che per gli altri Malus.
    *   *Black Box Privacy*: Hiding automatico di punti e token avversari per i Team non in possesso del Classifica Bonus.
    *   Tutti i test passano con successo (codice uscita `0`).
3.  **Regression Tests**: Eseguiti nuovamente tutti i test unitari preesistenti (`test_enigma_extra.js`, `test_freeze_malus.js`, `test_penalita_punti_malus.js`, `test_tassa_passaggio.js`, `test_trappola_malus.js`, `test_unlucky_wheel.js`). Tutti i test passano con successo con codice uscita `0`.


