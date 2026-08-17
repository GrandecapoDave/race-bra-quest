# CHANGELOG — PECHINO EXPRESS BRA

This document tracks all manual changes, bug fixes, features, and audit actions performed on the codebase.

---

## [📱 SUPPORTO PWA COMPLETO PER SMARTPHONE E DESKTOP]

Data:
2026-08-17

Funzionalità:
Trasformata l'applicazione esistente in una Progressive Web App (PWA) installabile e ottimizzata per l'utilizzo da mobile durante la gara urbana:
- Web App Manifest W3C (`public/manifest.webmanifest` & `public/manifest.json`):
  * Nome completo: "Pechino Express Bra" | Short name: "Pechino Bra"
  * Display: `standalone` (rimuove barre browser e URL per esperienza nativa mobile)
  * Orientation: `portrait` | Theme color: `#ea580c` | Background: `#0c0d14`
  * Icone raster e vettoriali standard e maskable (192x192, 512x512, SVG)
- Service Worker Intelligente (`public/sw.js`):
  * Isolamento dati dinamici: tutte le chiamate API/RPC di gara (`_serverFn`, `/api/`, `supabase`, mutazioni) sono Network-Only per garantire che i punteggi, token e classifiche provengano sempre dalla source of truth senza servire cache stantie
  * Smart Caching per shell statica, bundle JS, CSS, icone e Google Fonts
  * Aggiornamenti automatici del Service Worker con gestione `skipWaiting` e `clients.claim`
- Componente `PWAManager` (`src/components/PWAManager.tsx`):
  * Rilevamento e banner interattivo `Installa App` per Android e Desktop
  * Modalità guida passo-passo per iOS Safari ("Condividi ⎋ -> Aggiungi a schermata Home ⊞")
  * Rilevamento caduta connessione con banner visivo `📡 CONNESSIONE ASSENTE` e ripristino automatico al ritorno online
  * Toast di notifica aggiornamento app con pulsante `AGGIORNA`
- Safe Area & Ottimizzazioni Mobile:
  * Integrazione di `safe-top` e `safe-bottom` (`env(safe-area-inset-top)` / `env(safe-area-inset-bottom)`) in `src/styles.css` e `AppShell.tsx` per supporto a notch, Dynamic Island e barra di navigazione inferiore.

File modificati/creati:
* [`manifest.webmanifest`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/public/manifest.webmanifest)
* [`manifest.json`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/public/manifest.json)
* [`sw.js`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/public/sw.js)
* [`PWAManager.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/components/PWAManager.tsx)
* [`__root.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/__root.tsx)
* [`styles.css`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/styles.css)
* [`AppShell.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/components/AppShell.tsx)
* [`test_pwa.cjs`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/scratch/test_pwa.cjs)
* [`PROJECT_BASELINE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/PROJECT_BASELINE.md)

---

## [📊 RESOCONTO COMPLETO DELLA GARA + PUBBLICAZIONE FINALE]

Data:
2026-08-17

Funzionalità:
Implementato il sistema completo di Resoconto Gara e Pubblicazione Finale:
- Sezione Admin dedicata: `📊 RESOCONTO GARA` (`/admin/resoconto`)
  * Accessibile in qualsiasi momento dall'Admin durante la gara
  * Visualizzazione 🔴 LIVE in tempo reale di tutte le componenti di punteggio di ogni squadra
  * Dettaglio per tappa con sfide completate, bonus usati, malus usati/subiti, punti cattiveria, token e jackpot
  * Cronologia (timeline) ordinata di tutte le azioni e variazioni
  * Pulsante `📢 PUBBLICA RESOCONTO FINALE` protetto da modale di conferma per congelare lo snapshot definitivo
- Sezione Team: `📊 RESOCONTO FINALE` (`/resoconto`)
  * Bloccata (403 Forbidden lato API e UI) durante la gara (`report_state === "PRIVATE_LIVE"`)
  * Sbloccata per tutte le squadre non appena l'Admin pubblica il report (`report_state === "PUBLISHED_FINAL"`)
  * Mostra podio 🥇🥈🥉 e schede dettagliate di tutte le squadre con cronologia completa
- Snapshot Immutabile:
  * Alla pubblicazione viene creato uno snapshot congelato nel database (`db.game_report`)
  * Lo snapshot pubblico non cambia anche in caso di successive modifiche amministrative ai dati live
  * Idempotenza rigorosa: chiamate ripetute o refresh non sovrascrivono né duplicano lo snapshot
  * Evento `RESOCONTO_PUBLISHED` registrato nell'audit log (`activity_log`)
- Nessun doppio sistema di calcolo: la generazione utilizza 100% dati reali già esistenti.

File modificati/creati:
* [`localDbServer.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/integrations/supabase/localDbServer.ts) (`generateGameReport`, `get_game_report`, `publish_game_report`, `get_report_status`)
* [`race.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/lib/race.ts) (`gameReportQuery`, `reportStatusQuery`)
* [`AppShell.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/components/AppShell.tsx) (voci sidebar per Admin e Team condizionata a stato pubblicato)
* [`admin/resoconto.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin/resoconto.tsx) (UI Admin Resoconto Live + pubblicazione snapshot)
* [`resoconto.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/resoconto.tsx) (UI Team Resoconto Finale pubblico con podio e dettaglio)
* [`test_game_report.cjs`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/scratch/test_game_report.cjs) (Suite di test automatizzata a 18 scenari)
* [`PROJECT_BASELINE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/PROJECT_BASELINE.md)

---

## [🔒 CHIUSURA UFFICIALE DELLA TAPPA]

Data:
2026-08-17

Funzionalità:
Implementata la procedura ufficiale e atomica di chiusura della tappa per la Regia/Admin:
- Pulsante dedicato in Admin Configurazione Gara: `🔒 CHIUDI TAPPA`
- Modale di conferma personalizzata con checklist dettagliata delle azioni irreversibili e pulsanti ANNULLA / CONFERMA CHIUSURA TAPPA
- Chiusura atomica lato backend (`close_stage` in `localDbServer.ts`):
  * Calcolo posizionamento reale di tappa basato sulle prove e tempi della tappa
  * Calcolo e assegnazione dei Punti Cattiveria di fine tappa (regola "Chi non è cattivo paga": 0 Malus -> -10, 1 -> 0, 2 -> +5, 3 -> +10, 4+ -> +15) con rispetto del cap +30 PT
  * Assegnazione dei Token di fine tappa (1ª=15, 2ª=13, 3ª=11, 4ª=9, 5ª=7, 6ª=6, 7ª=5, 8ª=4)
  * Marcatura dello stato della tappa come `CLOSED` e salvataggio dei metadati completi in `stage.outcome`
  * Blocco delle modifiche per i team sulla tappa archiviata e sblocco della tappa successiva
  * Aggiornamento automatico e reattivo della Classifica Live
  * Registrazione dell'evento di audit `STAGE_CLOSED` in `activity_log`
- Idempotenza totale: nessuna duplicazione possibile di token o punti su refresh, reload o retry
- UI Admin: Banner e KPI card `🔒 TAPPA CHIUSA` con data chiusura, squadre elaborate, indicatori di completamento e tabella di dettaglio.

File modificati:
* [`localDbServer.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/integrations/supabase/localDbServer.ts) (Metadati outcome, log audit STAGE_CLOSED, rollback cattiveria in reopen)
* [`settings.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin/settings.tsx) (Modale di conferma, pulsante CHIUDI TAPPA e card stato chiuso con KPI)
* [`test_stage_closing.cjs`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/scratch/test_stage_closing.cjs) (Suite di test automatizzata a 18 casi di test per la chiusura tappa)
* [`PROJECT_BASELINE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/PROJECT_BASELINE.md)

---

## [😈 PUNTI CATTIVERIA / SISTEMA STRATEGICO MARKETPLACE]

Data:
2026-08-17

Funzionalità:
Implementato il nuovo sistema strategico di punteggio "😈 PUNTI CATTIVERIA". I Punti Cattiveria costituiscono una categoria separata di punteggio che premia l'utilizzo dei Malus ed applica piccole detrazioni per l'uso dei Bonus, incentivando la componente competitiva e strategica del Marketplace:
- Punteggio Totale = Punti Sfide + Modificatori Diretti Bonus/Malus + Punti Cattiveria
- Punti assegnati SOLO all'utilizzo effettivo (acquisto != utilizzo)
- Tabella Bonus (costi cattiveria):
  * `bonus_punti`: -5 PT
  * `bonus_scudo`: -3 PT (assegnati al difensore al momento del consumo dello scudo)
  * `ruota_fortuna`: -2 PT
  * `passaparola`: -2 PT
  * `bonus_classifica`: -3 PT
  * `partenza_anticipata`: -4 PT
- Tabella Malus (guadagni cattiveria):
  * `freeze_2min`: +8 PT (all'attaccante)
  * `ruota_sfortunata`: +7 PT (all'attaccante quando il bersaglio esegue lo spin)
  * `trappola`: +12 PT (all'attaccante)
  * `penalita_punti`: +10 PT (all'attaccante)
  * `tassa_passaggio`: +15 PT (all'attaccante, esclusi dallo switch base dei punti)
- Regola di fine tappa "Chi non è cattivo paga" (applicata una sola volta a chiusura tappa in `close_stage`):
  * 0 Malus usati: -10 PT
  * 1 Malus usato: 0 PT
  * 2 Malus usati: +5 PT
  * 3 Malus usati: +10 PT
  * 4+ Malus usati: +15 PT
- Limite massimo positivo per tappa: +30 PT (il cap si applica solo ai punti positivi maturati nella tappa; le penalità negative non sono bloccate dal cap).
- Persistenza e Ledger: Tabella `cattiveria_ledger` con storico completo (`id`, `team_id`, `stage_id`, `tipo`, `marketplace_item_id`, `riferimento_transazione`, `punti`, `motivo`, `timestamp`).
- Idempotenza garantita: nessun punto duplicato in caso di refresh, ripetizione di chiamate o retry API.
- Classifica Live Admin: esposte e separate le colonne Punti Sfide, Punti Cattiveria, Modificatori e Totale.

File modificati:
* [`localDbServer.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/integrations/supabase/localDbServer.ts) (Inizializzazione ledger, helper addCattiveriaPoints, hook di attribuzione bonus/malus, calcolo leaderboard e chiusura tappa)
* [`race.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/lib/race.ts) (Estensione tipo LeaderboardRow e query select con `challenges_points`, `modifier_points`, `cattiveria_points`)
* [`admin.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin.tsx) (Integrazione query allCattiveria e scomposizione punti in monitorRows)
* [`classifica.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin/classifica.tsx) (UI colonne separate e badge dinamico 😈 Punti Cattiveria)
* [`test_cattiveria_points.cjs`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/scratch/test_cattiveria_points.cjs) (Suite di test automatica per tutti i 16 requisiti)
* [`PROJECT_BASELINE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/PROJECT_BASELINE.md)

---

## [CLASSIFICA LIVE ADMIN]

Data:
2026-08-12

Funzionalità:
Implementata la pagina di Classifica Live della Regia riservata all'account Admin. La classifica calcola dinamicamente il posizionamento reale di gara delle squadre basandosi sulla gerarchia ufficiale: Numero di prove completate (DESC) -> Punteggio totale (DESC) -> Tempo di percorrenza (ASC) -> Ultimo sblocco (ASC), escludendo dal calcolo delle prove la sfida opzionale Jackpot 5.3.

File modificati:
*   [`classifica.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin/classifica.tsx) (Nuova pagina admin)
*   [`AppShell.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/components/AppShell.tsx) (Aggiunta link in Sidebar admin)
*   [`localDbServer.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/integrations/supabase/localDbServer.ts) (Ordinamento backend e supporto freeze/active nel mapper)
*   [`race.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/lib/race.ts) (Integrazione campi query e allineamento rankLeaderboard)
*   [`admin.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin.tsx) (Allineamento monitorRows e ordinamento)
*   [`PROJECT_BASELINE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/PROJECT_BASELINE.md) (Aggiornamento documentazione baseline)

API:
*   Aggiornato il SELECT handler della tabella virtuale `"leaderboard"` in `localDbServer.ts` per restituire le righe ordinate e arricchite con le colonne `active`, `freeze_started_at`, e `freeze_expires_at`.

Database:
*   Nessuna modifica strutturale sullo schema. I dati continuano a essere derivati in tempo reale (calcolo dinamico lato server senza duplicazione o hardcoding di posizioni statiche).

Test:
*   Eseguita compilazione TypeScript (`npx tsc --noEmit`) con esito positivo (codice 0).
*   Eseguiti tutti i test di regressione locali e verificati gli scenari di parità, penalità punti, switch e freeze.

---

## [BUGFIX — ADMIN JACKPOT — allTeams.filter]

Data:
2026-08-12

Problema:
Entrando nella pagina di regia "SFIDA 5.3 — JACKPOT", la pagina andava in crash mostrando un errore a schermo: "TypeError: allTeams?.filter is not a function." e impedendo il caricamento dell'interfaccia.

Causa:
Il componente `AdminJackpotPage` recuperava `allTeams` dal contesto dell'admin (`useAdminContext()`). Tuttavia, `allTeams` nel contesto è l'oggetto di query React Query (Query Observer Result) e non direttamente l'array dei team. Pertanto, il tentativo di eseguire `.filter()` direttamente su di esso falliva poiché il metodo si trova all'interno della proprietà `.data`. Inoltre, non venivano controllati gli stati di loading o errore della query `allTeams`.

Soluzione:
1. Normalizzato l'accesso all'array dei team usando `allTeams?.data` anziché `allTeams`.
2. Aggiunto il controllo dello stato di caricamento della query `allTeams?.isLoading` all'interno dello spinner di caricamento principale.
3. Aggiunto il controllo dello stato di errore `allTeams?.error` e `playsError` per gestire in modo robusto gli errori API e impedire crash visualizzando un messaggio di errore informativo in UI.

File modificati:
*   [`jackpot.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin/jackpot.tsx)

Test eseguiti:
1. Eseguita compilazione TypeScript (`npx tsc --noEmit`) con esito positivo (codice d'uscita 0).
2. Verificato l'accesso all'area Admin $\rightarrow$ Sidebar $\rightarrow$ Sfida 5.3 Jackpot (caricamento delle squadre, filtri `active !== false` e conteggio corretto).
3. Verificato il corretto caricamento dello spinner durante il fetch asincrono e la stabilità in caso di refresh e navigazione tra pagine.

Regression test:
*   Eseguiti tutti i test unitari a database (`test_marketplace_audit.js`, `test_marketplace_sorting.js`, `test_tassa_passaggio.js`, `test_penalita_punti_malus.js`, `test_trappola_malus.js`, `test_unlucky_wheel.js`, `test_freeze_malus.js`, `test_enigma_extra.js`). Tutti i test passano con successo (100% PASS).

---

## [AUDIT-2026-08-12]

### Analisi
*   Eseguito un audit profondo, sistematico e distruttivo di tutte le tappe, sfide, ruoli, autorizzazioni, e transazioni del Marketplace.
*   Analizzati i flussi di progressione per verificare che i blocchi di tappa e di sfida operino correttamente.
*   Analizzato il meccanismo di autenticazione e di ripristino sessione (Remember Me).
*   Analizzate le API per verificare le protezioni di privacy Black Box e la sicurezza delle chiamate RPC.

### Bug trovati
1.  **Punti Negativi da Ruota Sfortunata**: Gli esiti `-20 punti` e `-10 punti` della Ruota Sfortunata non consideravano il saldo dei punti della squadra bersaglio, potendo causare punteggi negativi a database.
2.  **Costo Hardcoded in Toast Successo**: Il toast mostrato sul frontend per l'acquisto di `bonus_punti` sottraeva una costante di 40 Token fissa nel testo descrittivo, non leggendo il valore effettivo configurato a database.
3.  **Layout Gestione Token Overflow**: Il blocco orizzontale della quantità token ("Quantità (negativo per togliere)") sbordava dal contenitore della card ed il selettore a frecce si sovrapponeva allo sfondo dell'input.

### Bug corretti
1.  **Capping atomico dei Punti**: Modificato `spin_unlucky_wheel` in `localDbServer.ts` per calcolare il punteggio corrente del bersaglio ed eseguire un capping a `0 PT` (non permettendo detrazioni superiori ai punti posseduti).
2.  **Costo Dinamico nel Toast**: Sostituito il valore hardcoded `40` con la lettura dinamica `mergedItems.find(i => i.id === "bonus_punti")?.costo`.
3.  **Correzione Layout Token**: Impostata la larghezza dei pulsanti `-` e `+` a dimensione fissa circolare (`size-11 shrink-0 rounded-full`), impostato l'input centrale con `flex-1 min-w-0` per occupare solo lo spazio disponibile evitando l'overflow, ed eliminati gli spinner di default dei browser per rimuovere le sovrapposizioni.

### File modificati
*   [`localDbServer.ts`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/integrations/supabase/localDbServer.ts) (Capping esiti Ruota Sfortunata)
*   [`marketplace.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/marketplace.tsx) (Dinamizzazione costo toast)
*   [`teams.tsx`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/src/routes/_authenticated/admin/teams.tsx) (Layout quantità token e allineamento)
*   [`PROJECT_BASELINE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/PROJECT_BASELINE.md) (Creazione Baseline Progetto)
*   [`docs/project-baseline/BUSINESS_RULES.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/docs/project-baseline/BUSINESS_RULES.md) (Creazione Regole di Gioco)
*   [`docs/project-baseline/ARCHITECTURE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/docs/project-baseline/ARCHITECTURE.md) (Creazione Architettura e Flussi)
*   [`docs/project-baseline/REGRESSION_TESTS.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/docs/project-baseline/REGRESSION_TESTS.md) (Creazione Regression Test Suite)

### Database modificato
*   Nessuna modifica strutturale effettuata sullo schema di `local_database.json` durante questo audit. La compatibilità all'indietro è garantita al 100%.

### API modificate
*   Nessuna modifica di firma delle API o delle RPC. Tutti i consumer (frontend) continuano a funzionare senza modifiche.

### Test eseguiti
*   Eseguito `npx tsc --noEmit` per validare la correttezza del codice ed i tipi TypeScript.
*   Scritto ed eseguito lo script di audit complessivo del Marketplace `test_marketplace_audit.js`.

### Regression test
*   Eseguiti tutti i test unitari preesistenti sul database locale:
    *   `test_enigma_extra.js` $\rightarrow$ **`✅ PASS`**
    *   `test_freeze_malus.js` $\rightarrow$ **`✅ PASS`**
    *   `test_penalita_punti_malus.js` $\rightarrow$ **`✅ PASS`**
    *   `test_tassa_passaggio.js` $\rightarrow$ **`✅ PASS`**
    *   `test_trappola_malus.js` $\rightarrow$ **`✅ PASS`**
    *   `test_unlucky_wheel.js` $\rightarrow$ **`✅ PASS`**
    *   `test_marketplace_sorting.js` $\rightarrow$ **`✅ PASS`**
