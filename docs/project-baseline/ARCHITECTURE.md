# SYSTEM ARCHITECTURE — PECHINO EXPRESS BRA

This document describes the code architecture, data flow, client-server bridging, and persistence design of **Pechino Express Bra**.

---

## 🗺️ Panoramica del Flusso Dati

The application is structured as a full-stack Javascript/Typescript app running on **TanStack React Start**.

```mermaid
graph TD
    subgraph Frontend (SPA Client)
        Routes[TanStack Router /routes]
        Components[React Components /components]
        Hooks[useAuth & React Query Hooks]
        MockClient[MockSupabaseClient client.ts]
    end

    subgraph Backend (TanStack React Start Server)
        ServerFn[runLocalDbAction Server Function]
        DBServer[localDbServer.ts Handlers]
        DiskDB[(local_database.json)]
        Uploads[public/uploads/]
    end

    Components --> Routes
    Routes --> Hooks
    Hooks --> MockClient
    MockClient -- "HTTP POST (Serialized Action)" --> ServerFn
    ServerFn --> DBServer
    DBServer -- "Synchronous JSON I/O" --> DiskDB
    DBServer -- "File System Write" --> Uploads
```

---

## 📂 Struttura Cartelle e Componenti Chiave

*   **`src/routes/`**: Contains the routing paths of the application.
    *   `auth.tsx`: Login view, Remember Me setup, and username validation.
    *   `_authenticated/route.tsx`: Guard that blocks unauthenticated visitors and queries active user session.
    *   `_authenticated/dashboard.tsx`: Active challenge, points total, remaining tokens, active malus badges.
    *   `_authenticated/marketplace.tsx`: Renders grids for Bonus and Malus. Performs token checks and target team selection.
    *   `_authenticated/classifica.tsx`: Leaderboard view. Restricts score visibility unless classification bonus is active.
    *   `_authenticated/admin.tsx`: Master administrative dashboard.
*   **`src/components/`**: Core reusable components.
    *   `AppShell.tsx`: The primary wrapper. Handles the navigation sidebar and enforces full-screen malus overlays (Freeze, Enigma Extra, Unlucky Wheel).
    *   `challenges/`: Custom gameplay interfaces for all 15 challenges (Quiz, Banca, Social, Enigmi, Tornei, Jackpot).
*   **`src/integrations/supabase/`**: Core bridging layer.
    *   `client.ts`: Mock client that replaces standard Supabase client methods (`from`, `select`, `insert`, `rpc`, `storage`) with calls routed to the local database server.
    *   `localDbServer.ts`: TanStack Server Function (`runLocalDbAction`) that processes database queries, updates, transactions, and custom RPC methods.

---

## 🔒 Session & State Persistence

1.  **Tab Session Storage**: On login, the session is saved as a serialized string inside `sessionStorage.setItem("mock_supabase_session", ...)`.
2.  **Persistent Storage**: If "Ricorda accesso" (Remember Me) is enabled, the session is also mirrored to `localStorage.setItem("mock_supabase_session", ...)` and a flag `mock_supabase_persistent` is set to `"1"`.
3.  **Restoration**: When the page is reloaded, the Supabase client checks sessionStorage. If empty, and the persistent flag is `"1"`, it copies the session from localStorage back into sessionStorage to restore the session.
4.  **Logout**: When logging out, all tokens, sessions, and flags are wiped from both sessionStorage and localStorage.

---

## 🛢️ Database Schema & File Storage

The local database is stored in a single JSON file `local_database.json` in the root folder.

### Principali Entità Database:
*   **`admin`**: `{ id, username, password_hash }`
*   **`teams`**: `{ id, nome_squadra, username, password_plain, token_balance, active, freeze_started_at, freeze_expires_at }`
*   **`stages`**: `{ id, nome_tappa, ordine, stato, outcome }`
*   **`challenges`**: `{ id, stage_id, titolo, tipo_sfida, punteggio_massimo, ordine }`
*   **`team_progress`**: `{ id, team_id, challenge_id, stato, completata_at }`
*   **`submissions`**: `{ id, team_id, challenge_id, file_upload, risposta, stato_approvazione }`
*   **`scores`**: `{ id, team_id, challenge_id, punti, motivazione }`
*   **`marketplace_transactions`**: `{ id, buyer_team_id, item_id, target_team_id, costo, stato, outcome }`

### Concurrency and Atomicity:
Because JS execution in Node is single-threaded and all file system operations in `localDbServer.ts` are synchronous (`readFileSync` and `writeFileSync`), database transactions are atomic by default. There is no risk of race conditions on tokens or points updates during concurrent team transactions.

### File Uploads:
When a team uploads an image (e.g. Photo Challenge or Social Mission), the frontend reads the file as a Base64 string and calls `supabase.storage.from("uploads").upload(path, file)`. The mock client intercepts this and sends the Base64 payload to the backend server function, which decodes it and writes it directly to the `/public/uploads/` directory on disk.
