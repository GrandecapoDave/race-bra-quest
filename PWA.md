# 📱 GUIDA PWA (PROGRESSIVE WEB APP) — PECHINO EXPRESS BRA

L'applicazione **Pechino Express Bra** è una Progressive Web App (PWA) installabile su tutti gli smartphone iOS e Android, progettata per offrire un'esperienza fluida a schermo intero durante la gara urbana.

---

## 1. Caratteristiche PWA Implementate

- **Modalità Standalone**: Quando installata, l'app si avvia a schermo intero rimuovendo barre di navigazione, barre URL e controlli del browser.
- **Icona Ufficiale Personalizzata**: Icone vettoriali e rasterizzate ad alta definizione (192x192, 512x512 standard e maskable) con il tema bussola e avventura di Pechino Bra.
- **Safe Area Insets**: Supporto completo per notch, Dynamic Island su iPhone e gesture navigation su Android (`env(safe-area-inset-top)` / `env(safe-area-inset-bottom)`).
- **Isolamento Dati Dinamici (Network-Only)**: Il Service Worker non memorizza in cache i punteggi, token o classifiche, garantendo che i dati di gara provengano sempre e solo in tempo reale dal backend Supabase.
- **Smart Cache Risorse Statiche (Stale-While-Revalidate)**: Bundle JS, CSS, icone e Google Fonts sono memorizzati nella cache locale per un avvio immediato anche in condizioni di rete cellulare debole.
- **Aggiornamenti Automatici**: Il Service Worker rileva in background nuove release dell'app e mostra un messaggio di aggiornamento per passare all'ultima versione senza perdere la sessione di gioco.

---

## 2. Istruzioni di Installazione per le Squadre

### 🤖 Installazione su Android (Chrome, Edge, Samsung Internet)
1. Apri il browser Chrome e visita l'URL dell'applicazione (es. `https://pechino-bra.vercel.app`).
2. Sullo schermo comparirà in basso il banner: **"Installa Pechino Bra — Usa l'app a schermo intero durante la gara"** con il pulsante **"Installa"**.
3. Tocca **"Installa"** e conferma l'aggiunta.
4. L'icona dell'app apparirà tra le applicazioni dello smartphone.

*In alternativa (se il banner non compare):*
- Tocca i tre puntini `⋮` in alto a destra su Chrome.
- Seleziona **"Installa app"** o **"Aggiungi a schermata Home"**.

### 🍏 Installazione su iPhone / iPad (Safari)
1. Apri **Safari** e visita l'URL dell'applicazione.
2. Tocca l'icona **Condividi** (il quadrato con la freccia verso l'alto `⎋`) posizionata al centro della barra inferiore di Safari.
3. Scorri l'elenco delle azioni verso il basso e tocca **"Aggiungi alla schermata Home"** (`⊞`).
4. Tocca **"Aggiungi"** in alto a destra.
5. L'icona ufficiale di Pechino Express Bra comparirà sulla schermata principale dell'iPhone.

---

## 3. Gestione Connettività e Upload Fotografici

- **Fotocamera Mobile**: Nelle sfide fotografiche (Foto Ufficiale, Locandina Vivente, Social Challenge), il pulsante di scatto apre direttamente la fotocamera nativa o la galleria con acquisizione automatica delle coordinate GPS.
- **Comportamento di Rete**: Se la connessione mobile è instabile durante la navigazione, l'app notifica lo stato tramite toast senza corrompere i dati locali. Al ripristino del segnale, tutti i conteggi e le classifiche si sincronizzano automaticamente.
