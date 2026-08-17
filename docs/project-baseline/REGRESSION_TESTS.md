# REGRESSION TEST SUITE — PECHINO EXPRESS BRA

This document defines the permanent automated regression test suite for **Pechino Express Bra**. These tests must be executed and verified before pushing any new code to ensure existing features are protected.

---

## 🛠️ Come Eseguire i Regression Test

### 1. Verifica della Compilazione TypeScript
Assicurati che non vi siano errori di tipo in tutta l'applicazione:
```bash
npx tsc --noEmit
```

### 2. Esecuzione dei Test Unitari e di Sistema
Esegui ciascuno dei file di test memorizzati nella directory temporanea/test del progetto (`/Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/`):

*   **Test Audit Marketplace (Core Invariants & Shield)**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_marketplace_audit.js
    ```
*   **Test Ordinamento Marketplace**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_marketplace_sorting.js
    ```
*   **Test Tassa di Passaggio (Black Box & Leaderboard Switch)**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_tassa_passaggio.js
    ```
*   **Test Malus Penalità Punti (-20 PT)**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_penalita_punti_malus.js
    ```
*   **Test Malus Trappola**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_trappola_malus.js
    ```
*   **Test Malus Ruota Sfortunata**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_unlucky_wheel.js
    ```
*   **Test Malus Freeze**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_freeze_malus.js
    ```
*   **Test Malus Enigma Extra**:
    ```bash
    node /Users/davidepregliasco/.gemini/antigravity/brain/1a3a6b6c-40e7-4d92-b8c4-1f54890189e5/scratch/test_enigma_extra.js
    ```

Tutti i test sopra elencati devono completare con codice di uscita `0` (nessun errore generato).

---

## 📋 Matrice di Copertura dei Test

| Codice Test | Descrizione | Invariante Verificato |
| :--- | :--- | :--- |
| **AUTH-001** | Autenticazione Squadra | Assicura che le credenziali in chiaro corrispondano a `password_plain` e rimandi alla `/dashboard`. |
| **AUTH-002** | Autenticazione Admin | Convalida lo username `justdave` e la password hash in `local_database.json`. |
| **AUTH-003** | Logout | Pulisce completamente `sessionStorage`, `localStorage` ed invalida i listener. |
| **AUTH-004** | Remember Me | Salva la sessione in `localStorage` e la ripristina all'avvio solo se la spunta è attiva. |
| **PRIV-001** | Team Isolation | Verifica che le query di un team filtrino esclusivamente i propri progressi e risposte. |
| **PRIV-002** | Leaderboard Black Box | Verifica l'oscuramento dinamico di punti e token degli avversari a livello API. |
| **GAME-001** | Progressione Sfide | Blocca l'avvio delle sfide fuori ordine. |
| **GAME-002** | Progressione Tappe | Impedisce l'accesso a una tappa se quella precedente non è completata al 100%. |
| **MARKET-001**| Saldo Token | Rifiuta l'acquisto se il saldo dei token della squadra è inferiore al prezzo dell'oggetto. |
| **MARKET-002**| Doppio Acquisto | Simula clic consecutivi rapidi e blocca le transazioni duplicate a livello server. |
| **MARKET-003**| Scudo Protettivo | Verifica che un attacco malus sia neutralizzato se il bersaglio ha uno scudo attivo. |
| **MALUS-001**| Capping Punti | Garantisce che nessun malus (Penalità, Trappola, Ruota Sfortunata) riduca i punti sotto zero. |
| **MALUS-002**| Freeze Time | Blocca le chiamate API di sblocco sfide sul server se il bersaglio è congelato. |
| **MALUS-003**| Enigma Extra Block | Rifiuta lo sblocco di sfide finché il bersaglio non inserisce la risposta corretta (**LANTERNA**). |
| **MALUS-004**| Tassa di Passaggio | Convalida lo switch permanente dei punti ed il ricalcolo istantaneo delle classifiche. |
