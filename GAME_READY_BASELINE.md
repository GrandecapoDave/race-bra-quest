# GAME READY BASELINE
## Pechino Express — Race Bra Quest

---

## CHECKPOINT INFORMATION

| Campo | Valore |
|---|---|
| **Data Checkpoint** | 2026-08-29 |
| **Ora (locale)** | 22:31 CEST (UTC+2) |
| **Branch** | `main` |
| **Commit SHA** | `87b03718f4ed5836a7aa39b7072dca6b7b5bd38a` |
| **Commit Message** | `fix: photo submission lock is now driven by DB query (not local state) - survives refresh, logout, navigation` |
| **Tag** | `game-ready-baseline-2026-08-29` |
| **Tag SHA (deref)** | `87b03718f4ed5836a7aa39b7072dca6b7b5bd38a` |
| **Working Tree** | CLEAN |
| **Remote** | `https://github.com/GrandecapoDave/race-bra-quest.git` |

---

## RIPRISTINO

Per tornare esattamente a questa versione:

```bash
git checkout game-ready-baseline-2026-08-29
```

oppure via SHA diretto:

```bash
git checkout 87b03718f4ed5836a7aa39b7072dca6b7b5bd38a
```

---

## STACK TECNOLOGICO

| Layer | Tecnologia | Versione |
|---|---|---|
| Framework UI | React | ^19.2.0 |
| Router | TanStack Router | ^1.170.18 |
| Data fetching | TanStack Query | ^5.101.1 |
| Backend / Auth / DB | Supabase | ^2.112.0 |
| Styling | Tailwind CSS | ^4.2.1 |
| Build / SSR | Vite + Nitro (TanStack Start) | — |
| Deployment target | Cloudflare Workers (cloudflare-module) | — |
| UI Components | Radix UI / Shadcn | varie |
| Toast | Sonner | — |
| Icone | Lucide React | — |
| Mappe | Leaflet 1.9.4 (CDN) | — |

---

## DATABASE

- **Provider**: Supabase (PostgreSQL hosted)
- **Auth**: Supabase Auth (email/password)
- **Storage**: bucket `team-media`
- **Realtime**: attivo
- **RLS**: abilitato
- **RPC**: funzioni PostgreSQL custom per scoring, marketplace, valutazioni

---

## FUNZIONALITA' IMPLEMENTATE

### Sistema di Gioco
- Registrazione squadre e componenti
- Progressione tappe sequenziale con blocco sfide
- Stato gara (non iniziata / attiva / terminata) gestibile da Admin

### Sfide
- Photo (upload con DB-lock post-invio)
- Living Poster (locandina vivente)
- Social Challenge
- Quiz
- La Banca
- Emoji Movies
- Codice Segreto
- Enigma Musicale / Testo / Coordinate
- Lucchetto Direzionale
- Cornhole
- Boxe
- Jackpot
- Rebus Visivo

### Admin (Regia)
- Console regia live
- Valutazione foto (punteggio modificabile)
- Valutazione locandine (punteggio IMMUTABILE post-conferma)
- Valutazione missioni social
- Classifica live, analisi dati, statistiche
- Gestione Marketplace, Cattiveria, Bonus/Malus, Tassa, Jackpot
- Log attivita', mappa GPS

### Economia
- Token, Marketplace, Scudo, Polizza, Freeze, Blackout, Dimezza Punti, Tassa di Passaggio, Bonus Classifica

---

## TEST ESEGUITI

| Test | Tipo | Esito |
|---|---|---|
| TypeScript typecheck | Automatico | PASS |
| Production build | Automatico | PASS |
| Script verifiche funzionalita' | Automatico | PASS |
| Verifica manuale generale | Manuale | PASS (dichiarato dall'utente) |
| Blocco upload foto su refresh | Da verificare in produzione | PENDING |
| Test multi-squadra simultaneo | Non testato | PENDING |
| Test mobile (camera) | Non testato | PENDING |

---

## ELEMENTI NON ANCORA VERIFICATI IN PRODUZIONE

1. Blocco upload foto dopo refresh su dispositivo reale
2. Immutabilita' locandine dopo refresh su dispositivo reale
3. Comportamento mobile (camera capture)
4. Performance con N squadre simultanee
5. Comportamento Realtime sotto carico

---

## NOTE

> Questo documento e' stato creato automaticamente al momento del checkpoint.
> Qualsiasi modifica futura deve partire dal tag `game-ready-baseline-2026-08-29`.
> Per regressioni: `git checkout game-ready-baseline-2026-08-29`

*Generato: 2026-08-29 22:31 CEST*
