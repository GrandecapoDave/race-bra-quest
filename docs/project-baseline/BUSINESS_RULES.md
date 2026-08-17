# BUSINESS RULES — PECHINO EXPRESS BRA

This document specifies the exact business rules, gameplay mechanics, points values, token rewards, and security constraints governing **Pechino Express Bra**.

---

## 👥 Ruoli e Autorizzazioni
1.  **Admin (Regia - `justdave`)**:
    *   Può abilitare/disabilitare il Marketplace.
    *   Può approvare o rifiutare le consegne di foto (`submissions`).
    *   Può inserire e modificare punteggi extra (Slider Sfida Social).
    *   Può selezionare i vincitori dei match del torneo (Cornhole, Boxe) e configurare il BYE speciale.
    *   Può visualizzare la classifica reale ed aggiornata in qualsiasi momento.
    *   Può creare, sospendere, o eliminare squadre.
2.  **Team (Squadre partecipanti)**:
    *   Possono iscriversi compilando nome, motto, colore, ed avatar (Sfida 1.1).
    *   Possono rispondere a quiz, inserire codici di sblocco, e caricare foto.
    *   Possono acquistare Bonus e Malus dal Marketplace spendendo Token.
    *   Non possono vedere i punteggi degli avversari a meno che non attivino il `bonus_classifica`.
    *   Non possono modificare i propri punti o lo stato delle sfide al di fuori dei flussi regolari di gioco.

---

## 📈 Punteggi e Tappe
Il punteggio totale di una squadra si calcola sommando tutti i record in `scores` a database.
Le sfide sono sbloccate in ordine di `ordine_index` per ciascuna tappa. Le tappe si sbloccano in ordine sequenziale: una tappa N si sblocca solo se tutte le sfide della tappa N-1 sono state completate.

### Sfide e Punti per Tappa:
*   **Tappa 1: Il Passaporto di Bra**
    *   Sfida 1.1 (Configurazione Squadra): 5 PT (Auto-completamento)
    *   Sfida 1.2 (Quiz di Bra): Fino a 15 PT (3 PT per ogni risposta esatta su 5 domande)
    *   Sfida 1.3 (Foto Ufficiale): 10 PT (Previa approvazione manuale dell'Admin)
*   **Tappa 2: Il Rebus Visivo**
    *   Sfida 2.1 (Il Rebus Visivo): 25 PT (Previa approvazione manuale dell'Admin)
    *   Sfida 2.2 (Indovina il film dalle emoji): 15 PT (1 PT per risposta corretta + 7 PT bonus di completamento)
    *   Sfida 2.3 (La locandina vivente): Fino a 15 PT (Scala di valutazione admin estesa a 0-15 PT)
*   **Tappa 3: La Banca**
    *   Sfida 3.1 (La Banca): 25 PT (Risoluzione di 4 enigmi, parola chiave: **BPER**)
    *   Sfida 3.2 (Missione Social): Fino a 20 PT (Caricamento obbligatorio di 2 foto distinte. Sblocco e completamento immediato lato concorrente. Valutazione e punteggio in differita da 0 a 20 PT gestito dall'Admin)
    *   Sfida 3.3 (Il Codice Segreto): 15 PT (Sblocco frammenti di codice ad anello con token. Parola chiave: **4829167305**)
*   **Tappa 4: Enigmi**
    *   Sfida 4.1 (Rebus Musicale): 5 PT (Risposta esatta: **BRA**)
    *   Sfida 4.2 (Lucchetto Direzionale): 5 PT (Risposta esatta: **SU-GIU-DESTRA-SINISTRA**)
    *   Sfida 4.3 (Le Coordinate Finali): 5 PT (Risposta esatta: **44.7163, 7.8429**)
*   **Tappa 5: Tappa Finale**
    *   Sfida 5.1 (Torneo Cornhole): Vincitore: 20 PT. Partecipanti: 10 PT. (Completato per tutte le squadre al termine della finale)
    *   Sfida 5.2 (Boxe Gonfiabile): Vincitore: 20 PT. Partecipanti: 10 PT. (Completato per tutte le squadre al termine della finale)
    *   Sfida 5.3 (Jackpot della Regia - Slot Machine): Facoltativa. Giocabile 1 sola volta. Scommessa compresa tra 5 e 20 PT (non superiore ai propri punti totali). 3 simboli uguali = raddoppio (+puntata), altrimenti perdita (-puntata).

---

## 🪙 Sistema Token
*   **Saldo Iniziale**: Ciascuna squadra parte con **50 Token** di base (o valore configurato al setup).
*   **Guadagno**: I token si accumulano completando le prove o tramite incentivi gestiti dalla Regia.
*   **Utilizzo**: Spesi nel Marketplace per acquistare Bonus o Malus, oppure nella Sfida 3.3 per acquistare frammenti di codice.
*   **Scambio Finale**: Nel circuito ad anello della Sfida 3.3, i token spesi per acquistare i frammenti vengono accreditati direttamente al venditore (se le squadre attive sono pari).

---

## 🏪 Marketplace: Regole Generali
*   **Sblocco**: Il Marketplace è invisibile e inaccessibile fino a quando la squadra non ha completato la Tappa 1 (completamento di Foto Ufficiale).
*   **Stato Regia**: Se l'Admin disabilita il Marketplace, l'accesso è interdetto a tutti visualizzando la schermata "Temporaneamente chiuso dalla Regia".
*   **Ordinamento**: Gli elementi sono ordinati per costo decrescente. A parità di costo, si applica l'ordinamento alfabetico crescente per nome.
*   **Monouso**: Ciascun articolo può essere acquistato ed utilizzato una sola volta per ogni acquisto.

### 🌟 BONUS:
1.  **Bonus Punti (+20 PT)**: Aggiunge istantaneamente 20 punti alla squadra acquirente.
2.  **Bonus Scudo**: Protegge la squadra acquirente dal primo Malus lanciato dagli avversari. All'attacco, lo scudo si consuma (stato: `used`) ed annulla l'effetto del Malus (stato della transazione malus: `blocked`).
3.  **Ruota della Fortuna**: Spin interattivo con premi positivi estratti casualmente.
4.  **Passaparola**: Permette di inviare una richiesta all'Admin per ricevere un indizio extra SÌ/NO su un enigma bloccato.
5.  **Bonus Classifica**: Consente alla squadra di visualizzare la classifica per una sessione. Lo stato passa da `completed` a `viewing` all'apertura, e viene impostato a `used` all'uscita dalla schermata.
6.  **Partenza Anticipata**: Fornisce un bonus fisico di -2 minuti alla partenza. Segnalato alla Regia per l'applicazione manuale.

### ⚠️ MALUS:
1.  **Freeze 2 Minuti**: Blocca l'interfaccia e le API del bersaglio per 120 secondi. La squadra bersaglio non può avviare o completare sfide durante il freeze.
2.  **Enigma Extra**: Impedisce alla squadra bersaglio di proseguire la gara fino a quando non inserisce la risposta corretta (**LANTERNA**). Durante l'enigma extra, le API di sblocco sfide sono bloccate sul server.
3.  **Ruota Sfortunata**: Forza la squadra bersaglio a compiere uno spin contenente penalità. La sottomissione delle sfide è bloccata finché non viene completato lo spin.
    *   *Esiti*: `-20 Punti`, `-10 Token`, `Freeze 2 Min`, `Heavy Backpack (+3 min)`, `+2 minuti di penalità`, `-10 Punti e -5 Token`.
    *   *Deductions Capping*: La penalità in punti è limitata per impedire che il punteggio scenda sotto zero.
4.  **Trappola**: Detrae 30 punti al bersaglio e li distrugge (non vengono accreditati all'acquirente). Capping automatico a zero punti per il bersaglio.
5.  **Penalità Punti (-20 PT)**: Rimuove istantaneamente 20 punti al bersaglio. Capping automatico a zero punti per il bersaglio.
6.  **Tassa di Passaggio (Black Box Switch)**:
    *   Scambia integralmente il punteggio della squadra acquirente con quello della squadra bersaglio.
    *   *Black Box Mode*: L'acquirente sceglie il bersaglio senza poter vedere il suo punteggio reale.
    *   I punti scambiati diventano i nuovi punteggi reali e ufficiali delle due squadre e aggiornano la classifica in tempo reale.

---

## 🏁 Tornei di Tappa 5
1.  **Partecipanti**: Vengono estratti dal database tra le squadre attive.
2.  **Bye Speciale**: L'admin può assegnare un BYE speciale (passaggio turno automatico) per gestire i numeri dispari o come vantaggio. Per Cornhole, il BYE va di default alla prima squadra che ha risolto l'Enigma 4.3.
3.  **Avanzamento**: La Regia seleziona manualmente il vincitore di ciascun match, che viene promosso al round successivo fino alla finale.
