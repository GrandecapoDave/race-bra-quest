# Remix of Bra Quest

Sviluppa una web application completa chiamata "Pechino Express Bra".

L'applicazione deve essere una piattaforma gamificata ispirata al programma Pechino Express, dove diverse squadre partecipano ad una gara urbana composta da tappe, checkpoint e minigiochi.

Non creare solamente un mockup grafico: sviluppa una vera applicazione con database, autenticazione, gestione stato, logiche di gara e struttura scalabile.

Tecnologia richiesta

Utilizza:

React moderno;

TypeScript;

Tailwind CSS;

Supabase come backend/database;

autenticazione utenti;

storage per immagini;

database relazionale;

API e logica server-side dove necessario.

PRINCIPIO ARCHITETTURALE

Il database deve essere la Single Source of Truth.

Ogni dato importante deve essere salvato nel database:

squadre;

membri;

prove;

progressione;

risposte;

immagini;

punteggi;

tempi;

classifiche;

attività.

Il frontend non deve mantenere dati permanenti.

Implementa:

autosalvataggio automatico;

sincronizzazione;

gestione errori;

stato offline;

retry automatici.

RUOLI

Implementa due ruoli:

Team Player

Può:

vedere dashboard squadra;

completare prove;

caricare foto;

rispondere quiz;

vedere classifica.

Admin

Può:

creare tappe;

creare prove;

modificare quiz;

controllare squadre;

vedere avanzamento gara.

CREA DATABASE

Crea uno schema relazionale con:

teams

id

name

motto

avatar_url

color

created_at

team_members

id

team_id

name

stages

id

title

description

order

status

challenges

id

stage_id

title

description

type

order

points

team_progress

id

team_id

challenge_id

status

started_at

completed_at

quiz_questions

id

challenge_id

question

options

correct_answer

team_answers

id

team_id

question_id

selected_answer

correct

timestamp

team_media

id

team_id

url

type

latitude

longitude

timestamp

score_events

id

team_id

points

reason

timestamp

race_sessions

id

team_id

start_time

end_time

duration

SVILUPPA DASHBOARD SQUADRA

Crea una dashboard moderna stile videogame.

Contenuti:

nome squadra;

avatar;

posizione classifica;

punti;

timer gara;

progresso tappe;

prova corrente;

pulsante principale azione;

storico attività;

badge;

ricompense.

SVILUPPA TAPPA 1

Nome:

"Il Passaporto di Bra"

Location:

Piazza Caduti per la Libertà.

La tappa contiene 3 prove.

Le prove devono essere bloccate e sbloccate progressivamente.

PROVA 1

Creazione squadra.

Campi:

nome;

motto;

avatar;

colore.

Dopo completamento:

sblocca prova 2.

PROVA 2

Quiz Bra.

Crea 5 domande multiple choice.

Ogni domanda deve avere:

4 risposte;

una corretta.

Dopo ogni risposta:

mostrare immediatamente:

corretto/errato;

punti ottenuti.

Domande:

Prodotto famoso:
Bra DOP

Evento:
Terra Madre / Salone del Gusto

Simbolo:
Zizzola

Regione:
Piemonte

Zona:
Langhe e Roero

PROVA 3

Foto ufficiale.

Permetti:

upload immagine;

salvataggio storage;

collegamento database;

timestamp;

GPS.

CLASSIFICA

Implementa ranking live.

La posizione dipende da:

tempo completamento;

punteggio.

Registra:

inizio tappa;

fine tappa;

durata.

Assegna bonus:

1° +20 punti

2° +15 punti

3° +10 punti

DESIGN

Lo stile deve essere:

premium;

avventuroso;

moderno;

simile ad un videogioco;

mobile first.

Utilizza:

card;

progress bar;

animazioni;

badge;

feedback immediati.

IMPORTANTE

Prima di sviluppare nuove pagine, crea:

database;

relazioni;

autenticazione;

gestione stato;

dashboard;

sistema prove.

Ogni funzionalità futura dovrà poter essere aggiunta semplicemente creando nuove prove dal database senza modificare la struttura principale.

This project was built with [Lovable](https://lovable.dev).

**Live app**: https://race-bra-quest.lovable.app

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/5cbc56ce-3434-48f7-a2fb-858ed2b92f86).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
