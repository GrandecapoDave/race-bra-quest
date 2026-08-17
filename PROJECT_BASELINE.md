# PECHINO EXPRESS BRA — PROJECT BASELINE

This document represents the official master baseline for the **Pechino Express Bra** application. It serves as the primary technical source of truth for architecture, components, security, and game systems. All future modifications must adhere to the rules and guidelines laid out in this baseline.

## Versione baseline
*   **Logical Version**: `1.0.0`
*   **Last Audit Date**: 2026-08-12
*   **System Status**: 🟢 **OPERATIONAL** (All core components, API boundaries, security gates, and E2E suites passing)

## Architettura
The system is built as a single-page full-stack React application powered by **TanStack React Start**, **React Query**, and **TailwindCSS**.
*   **Frontend**: Client-side single-page routing built using TanStack Router. State synchronization is managed via React Query.
*   **Backend Services**: Mocked Supabase SDK client communicating via RPC/mutations with TanStack React Start Server Functions (`createServerFn`).
*   **Database (Source of Truth)**: A local JSON database file (`local_database.json`) stored in the project root.
*   *Detailed reference*: See [`ARCHITECTURE.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/docs/project-baseline/ARCHITECTURE.md) for data flows, entity relationships, and client-server synchronization patterns.

## Authentication & Authorization
*   **Auth Provider**: Supabase Auth (Mocked via local login/logout RPC handlers).
*   **Session Management**: Sessions are read from `sessionStorage` for active tab persistence and verified via `supabase.auth.getUser()`.
*   **Remember Me ("Ricorda accesso")**: If enabled, credentials/session payload is copied to `localStorage` under `mock_supabase_session`.
*   **Roles & Guards**: 
    *   **Admin (`justdave`)**: Unrestricted access to regia views, tournament progression, and configuration dashboards.
    *   **Team (Standard Team Accounts)**: Isolated access restricted to team setup, stage progress, and marketplace views.
    *   *Detailed reference*: See [`BUSINESS_RULES.md`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/docs/project-baseline/BUSINESS_RULES.md) for exact role access lists.

## Tappe & Sfide
*   **Stages (Tappe)**: 5 distinct stages ordered sequentially:
    1.  *Il Passaporto di Bra* (Creazione squadra, Quiz Bra, Foto ufficiale)
    2.  *Il Rebus Visivo* (Il Rebus Visivo, Indovina il film dalle emoji, La locandina vivente)
    3.  *La Banca* (La Banca, Missione Social, Il Codice Segreto)
    4.  *Enigmi* (Rebus Musicale, Lucchetto Direzionale, Le Coordinate Finali)
    5.  *Tappa Finale* (Sfida Cornhole, Boxe Gonfiabile, Jackpot della Regia)
*   **Progression & Unlocking**: Challenges must be completed sequentially within each stage. Stages unlock dynamically only when all challenges of the preceding stage are completed.

## Marketplace (Bonus & Malus)
The marketplace allows teams to buy items using their Token balance.
*   **🌟 BONUS**:
    *   `bonus_punti` (+20 PT) - Cost: 40 Tokens
    *   `bonus_scudo` (Malus Shield Block) - Cost: 35 Tokens
    *   `ruota_fortuna` (Luck Draw) - Cost: 25 Tokens
    *   `passaparola` (Organiser Extra Hint) - Cost: 20 Tokens
    *   `bonus_classifica` (Temporary Leaderboard Visibility) - Cost: 30 Tokens
    *   `partenza_anticipata` (-2 Minutes Advantage) - Cost: 35 Tokens
*   **⚠️ MALUS**:
    *   `freeze_2min` (Freeze Target Team for 2 Minutes) - Cost: 20 Tokens
    *   `enigma_extra` (Assign Enigma to Target Team) - Cost: 25 Tokens
    *   `ruota_sfortunata` (Force Target Spin Unlucky Wheel) - Cost: 20 Tokens
    *   `trappola` (Steal 30 PT from Target Team) - Cost: 40 Tokens
    *   `penalita_punti` (-20 PT to Target Team) - Cost: 30 Tokens
    *   `tassa_passaggio` (Switch current scores with Target Team) - Cost: 70 Tokens

## 😈 Punti Cattiveria (Sistema Strategico Marketplace)
*   **Formula Punteggio Totale**:
    `PUNTEGGIO TOTALE = PUNTI SFIDE + MODIFICATORI DIRETTI (BONUS/MALUS) + PUNTI CATTIVERIA`
*   **Regola Fondamentale**: L'acquisto non assegna punti cattiveria; i punti vengono attribuiti solo all'utilizzo effettivo dell'oggetto.
*   **Bonus (Penalità Cattiveria per gioco conservativo)**:
    *   `bonus_punti`: -5 PT
    *   `bonus_scudo`: -3 PT (assegnati al difensore al momento del blocco/consumo effettivo)
    *   `ruota_fortuna`: -2 PT
    *   `passaparola`: -2 PT (assegnati all'invio della richiesta alla regia)
    *   `bonus_classifica`: -3 PT (assegnati all'apertura della sessione di visualizzazione)
    *   `partenza_anticipata`: -4 PT (assegnati quando la regia marca il bonus come usato)
*   **Malus (Premio Cattiveria per gioco aggressivo)**:
    *   `freeze_2min`: +8 PT (all'attaccante all'applicazione)
    *   `ruota_sfortunata`: +7 PT (all'attaccante quando il bersaglio esegue lo spin)
    *   `trappola`: +12 PT (all'attaccante all'applicazione)
    *   `penalita_punti`: +10 PT (all'attaccante all'applicazione)
    *   `tassa_passaggio`: +15 PT (all'attaccante all'esecuzione; i punti cattiveria rimangono dell'attaccante e sono esclusi dallo switch dei punti base)
*   **Cap per Tappa**: Massimo +30 Punti Cattiveria positivi maturabili per singola tappa. Il cap non limita le penalità negative.
*   **Regola di Fine Tappa ("Chi non è cattivo paga")**:
    *   0 Malus usati nella tappa $\rightarrow$ -10 PT
    *   1 Malus usato nella tappa $\rightarrow$ 0 PT
    *   2 Malus usati nella tappa $\rightarrow$ +5 PT
    *   3 Malus usati nella tappa $\rightarrow$ +10 PT
    *   4+ Malus usati nella tappa $\rightarrow$ +15 PT
    *   Applicata automaticamente e una sola volta alla chiusura della tappa (`close_stage`).
*   **Ledger e Idempotenza**: Tutte le transazioni di Punti Cattiveria sono registrate nella tabella `cattiveria_ledger` con `team_id`, `stage_id`, `tipo`, `marketplace_item_id`, `riferimento_transazione`, `punti`, `motivo`, `timestamp`. Duplicazioni e refresh non generano punti multipli.

## 🔒 Chiusura Ufficiale della Tappa
*   **Autorizzazione**: Riservata esclusivamente all'account Admin/Regia.
*   **Trigger**: Pulsante `🔒 CHIUDI TAPPA` in `Admin -> Configurazione Gara` (`settings.tsx`) protetto da modale di conferma.
*   **Operazioni Atomiche Backend (`close_stage`)**:
    1.  *Verifica Idempotenza*: Se la tappa è già `closed`, restituisce i risultati salvati senza ricalcoli né duplicazioni di token o punti.
    2.  *Posizionamento Tappa*: Determina la classifica reale della tappa per tutte le squadre in base a punti sfide, prove completate e tempi.
    3.  *Punti Cattiveria Fine Tappa*: Applica la regola "Chi non è cattivo paga" (0 Malus $\rightarrow$ -10, 1 $\rightarrow$ 0, 2 $\rightarrow$ +5, 3 $\rightarrow$ +10, 4+ $\rightarrow$ +15) con rispetto del cap positivo +30 PT.
    4.  *Token di Fine Tappa*: Accredita i Token previsti dal regolamento (1ª=15, 2ª=13, 3ª=11, 4ª=9, 5ª=7, 6ª=6, 7ª=5, 8ª=4) salvando la transazione.
    5.  *Blocco Tappa*: Marca `stage.stato = "closed"`, bloccando le modifiche retroattive per i Team e sbloccando la tappa successiva (se non è l'ultima).
    6.  *Audit Logging*: Registra l'evento `STAGE_CLOSED` in `activity_log`.
    7.  *Aggiornamento Classifica*: La Classifica Live si aggiorna immediatamente con i nuovi totali.

## 📊 Resoconto Gara e Pubblicazione Finale
*   **Scopo**: Ricostruire con precisione e trasparenza l'intero percorso di punteggio di ogni squadra (sfide, bonus, malus, switch, punti cattiveria, movimenti token, jackpot e cronologia eventi).
*   **Stati del Resoconto**:
    *   `PRIVATE_LIVE`: Durante la gara, accessibile esclusivamente all'Admin (`/admin/resoconto`). I dati si aggiornano reattivamente in tempo reale. L'accesso per i Team è rigorosamente bloccato sia da interfaccia sia da API backend (403 Forbidden).
    *   `PUBLISHED_FINAL`: Alla pubblicazione tramite pulsante `📢 PUBBLICA RESOCONTO FINALE`, il backend congela uno Snapshot immutabile in `db.game_report` e registra l'audit `RESOCONTO_PUBLISHED`. Da questo momento il link `📊 Resoconto Finale` (`/resoconto`) diventa permanentemente disponibile a tutte le squadre nella sidebar.
*   **Immutabilità dello Snapshot**: Eventuali modifiche amministrative o ricalcoli successivi alla pubblicazione non alterano il Resoconto Finale Pubblico, che rimane fedele allo stato congelato al momento del rilascio.
*   **Nessun Sistema Parallelo**: I calcoli derivano al 100% dai ledger e tabelle esistenti (`scores`, `team_progress`, `marketplace_transactions`, `cattiveria_ledger`, `jackpot_plays`, `stages`, `challenges`).

## 📱 Architettura PWA (Progressive Web App)
*   **Layer PWA Unificato**: Una sola applicazione, stesso frontend, stesso backend, stesso database. La PWA aggiunge unicamente la capacità di installazione nativa a schermo intero (`standalone`) e di caching intelligente delle risorse statiche.
*   **Source of Truth e Caching**:
    *   *Risorse Statiche* (JS, CSS, Font, Icone, Immagini fisse): Gestite tramite Service Worker (`sw.js`) con strategia Stale-While-Revalidate.
    *   *Dati Dinamici di Gara* (API, RPC, Punteggi, Classifica, Token, Sfide, Foto): Gestiti rigorosamente come **Network-Only**. Nessun dato di gioco critico viene cachato in modo persistente o modificato offline.
*   **Gestione Connettività**: Se la connessione cade durante la gara, l'applicazione mostra immediatamente il banner visivo `📡 CONNESSIONE ASSENTE` e si risincronizza automaticamente al ripristino della rete senza mostrare dati falsati.
*   **Mobile & Safe Area**: Supporto completo a notch, Dynamic Island e gesture bar (`safe-top`, `safe-bottom`, `viewport-fit=cover`).

## Classifica Live Admin
*   **Access**: Permanently available for the Admin under `/admin/classifica`. Embedded in the Admin Sidebar menu.
*   **Privacy & Guard**: Completely hidden and protected from standard Team routes. Teams can only see their leaderboard view via a static snapshot purchased using the `bonus_classifica` token item.
*   **Ranking Hierarchy**:
    1.  *Numero di prove completate* (DESC, excluding optional Jackpot challenge `f5f5f5f5-g6g6-h7h7-i8i8-j9j9j0j0j0j0`)
    2.  *Punteggio totale* (DESC)
    3.  *Tempo di percorrenza* (ASC)
    4.  *Tie-breaker*: Last challenge completion timestamp (ASC)
*   **Source of Truth**: Derived dynamically on request by calculating aggregate metrics from tables `teams`, `scores`, `team_progress`, and `time_penalties`. No static position columns are stored in database.
*   **Update Mechanism**: Real-time polling fetches updates every 3 seconds to keep the admin monitor synchronized with changes in team status.

## Security & Integrity Rules
1.  **Team Isolation**: No team can read or write points, tokens, or status parameters of another team (IDOR prevention).
2.  **Black Box Enforcement**: Leaderboard score totals and token balances of opposing teams are stripped out of API responses unless the requesting team is an Admin or has an active `bonus_classifica`.
3.  **Deduction Capping**: No point penalty or Malus can cause a team's score to fall below `0`. Deductions are dynamically capped.
4.  **Double Purchase / Double Click Protection**: All marketplace and gameplay actions are checked synchronously for idempotency to prevent duplicated requests.

---

## ⚠️ REGOLA FONDAMENTALE PER I LAVORI FUTURI

> [!IMPORTANT]
> **Prima di modificare qualsiasi funzionalità esistente, leggere `PROJECT_BASELINE.md`, `BUSINESS_RULES.md`, `ARCHITECTURE.md` e il `CHANGELOG` relativo alla funzionalità interessata.**
>
> Un lavoro futuro **NON deve**:
> *   Modificare una funzionalità senza verificarne le dipendenze.
> *   Cambiare una business rule implicitamente.
> *   Eliminare una protezione di sicurezza.
> *   Cambiare una API senza verificarne i consumer.
> *   Cambiare lo schema del database local_database.json senza aggiornare frontend/backend.
> *   Modificare un componente condiviso senza regression test.

---

## 🔄 REGOLA ANTI-CONFLITTO (10 STEP OBBLIGATORI)

Prima di ogni futura modifica:
1.  **Identificare** la funzionalità interessata.
2.  **Identificare** i file coinvolti.
3.  **Identificare** le API coinvolte.
4.  **Identificare** le tabelle coinvolte.
5.  **Identificare** le altre funzionalità dipendenti.
6.  **Leggere** la baseline.
7.  **Verificare** i test esistenti nella regression suite.
8.  **Modificare** con cautela.
9.  **Eseguire** i regression test.
10. **Aggiornare** la baseline e il changelog se il comportamento cambia intenzionalmente.
