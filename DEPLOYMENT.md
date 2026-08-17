# 🚀 GUIDA AL DEPLOYMENT ONLINE — PECHINO EXPRESS BRA

Questa guida descrive i passaggi per pubblicare online l'applicazione **Pechino Express Bra** in modo **100% gratuito** e affidabile per circa 10 squadre contemporanee durante la gara.

---

## 1. Architettura di Hosting

```
┌─────────────────────────────────────────────────────────────┐
│                       SMARTPHONE PWA                        │
│                (Installata da Browser Safari/Chrome)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ (HTTPS)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        VERCEL HOBBY                         │
│            Frontend React 19 + TanStack Start App           │
│                   Config: vercel.json                       │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│        SUPABASE FREE        │ │      SUPABASE STORAGE       │
│    Database PostgreSQL 15   │ │     Bucket: team-media      │
│  Tabelle, RPC & Indici RLS  │ │  Foto Prove con coordinate  │
└─────────────────────────────┘ └─────────────────────────────┘
```

---

## 2. Configurazione Supabase (Database & Storage)

### Step 2.1 — Creazione Progetto Gratuito
1. Accedi a [Supabase](https://supabase.com) e crea una nuova organizzazione/progetto gratuito.
2. Scegli una regione vicina (es. `eu-central-1` Francoforte o `eu-west-1` Dublino).
3. Salva la password del database generata.

### Step 2.2 — Esecuzione Schema SQL e Seed
1. Nel dashboard di Supabase, apri **SQL Editor**.
2. Copia e incolla il contenuto del file [`supabase/migrations/01_pechino_bra_schema.sql`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/supabase/migrations/01_pechino_bra_schema.sql) ed esegui il run. Questo creerà tutte le tabelle, chiavi esterne, indici di performance e Row Level Security (RLS).
3. Copia e incolla il contenuto del file [`supabase/seed.sql`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/supabase/seed.sql) ed esegui il run. Questo popolerà le tappe, le sfide, gli item del Marketplace e le squadre.

### Step 2.3 — Configurazione Storage per le Fotografie
1. Vai su **Storage** nel menu di sinistra.
2. Verifica che il bucket `team-media` sia presente e impostato come **Public** (creato automaticamente dallo script SQL).
3. Le foto caricate dalle squadre durante le prove saranno salvate in questo bucket con path `{team_id}/{challenge_id}-{timestamp}.jpg`.

---

## 3. Deployment Frontend su Vercel

### Step 3.1 — Importazione del Repository GitHub
1. Accedi a [Vercel](https://vercel.com) e clicca su **"Add New Project"**.
2. Seleziona il repository GitHub collegato a questo progetto (`race-bra-quest-main`).

### Step 3.2 — Impostazioni di Build
Vercel utilizzerà automaticamente le impostazioni definite in [`vercel.json`](file:///Users/davidepregliasco/Desktop/TUTTO/Altro/JUSTDAVE/race-bra-quest-main/vercel.json):
- **Framework Preset**: `Vite`
- **Build Command**: `npm run build`
- **Output Directory**: `.output/public`

### Step 3.3 — Variabili d'Ambiente (Environment Variables)
Nel pannello **Environment Variables** di Vercel, inserisci:

| Variabile | Valore | Descrizione |
| :--- | :--- | :--- |
| `VITE_SUPABASE_URL` | `https://<tuo-progetto>.supabase.co` | URL del tuo progetto Supabase |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_...` o `anon_key` | Anon Key pubblica di Supabase |

### Step 3.4 — Deploy
1. Clicca su **Deploy**.
2. In circa 60 secondi il sito sarà online con certificato **HTTPS** automatico (es. `https://pechino-bra.vercel.app`).

---

## 4. Verifica Limiti Piani Gratuiti (10 Squadre di Gara)

| Servizio | Risorsa / Limite Free | Consumo Stimato Gara | Margine Disponibile |
| :--- | :--- | :--- | :--- |
| **Vercel Hobby** | Bandwidth: 100 GB / mese | ~250 MB | **> 99% Libero** |
| **Vercel Hobby** | Build: 6.000 min / mese | ~5 min per deploy | **> 99% Libero** |
| **Supabase Free** | Database: 500 MB | ~15 MB | **> 95% Libero** |
| **Supabase Storage** | Storage: 1 GB gratuito | ~50 MB (foto ottimizzate) | **> 95% Libero** |
| **Supabase Bandwidth** | Egress: 2 GB / mese | ~300 MB | **> 85% Libero** |

---

## 5. Procedura di Backup e Ripristino

### Backup Database
Dal dashboard Supabase:
- **Database** $\rightarrow$ **Backups** $\rightarrow$ Scarica backup giornaliero automatico.
- Oppure esporta i dati da terminale:
  ```bash
  npx supabase db dump -f backup_gara.sql
  ```

### Reset Rapido per Nuova Partita
Per resettare la partita allo stato iniziale mantenendo tappe e configurazioni:
```sql
DELETE FROM public.submissions;
DELETE FROM public.scores;
DELETE FROM public.team_progress;
DELETE FROM public.marketplace_transactions;
DELETE FROM public.cattiveria_ledger;
DELETE FROM public.jackpot_plays;
DELETE FROM public.activity_log;
UPDATE public.teams SET token_balance = 50;
UPDATE public.stages SET stato = 'locked', outcome = NULL;
UPDATE public.stages SET stato = 'open' WHERE numero_tappa = 1;
UPDATE public.game_report SET state = 'PRIVATE_LIVE', published_at = NULL, published_by = NULL, snapshot = NULL;
```
