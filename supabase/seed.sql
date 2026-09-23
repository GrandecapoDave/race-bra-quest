-- ============================================================================
-- PECHINO EXPRESS BRA — INITIAL SEED DATA FOR SUPABASE POSTGRESQL
-- ============================================================================

-- SEED: STAGES
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('4a57212e-7e83-430c-b5fe-6cf38db7be2e', 1, 'Il Passaporto di Bra', 'Piazza Caduti per la Libertà, 14', 44.6982, 7.8507, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 2, 'Il Rebus Visivo', 'Via Mendicità Istruita, 12', 44.6976, 7.8544, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 3, 'La Banca', 'Stazione Ferroviaria di Bra', 44.6946, 7.8542, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('4b4b4c4d-5e5f-6061-7172-838485868788', 4, 'Enigmi', 'Risolvi gli enigmi e inserisci le soluzioni per avanzare.', NULL, NULL, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 5, 'Tappa Finale', 'Traguardo finale della gara! Raggiungete la destinazione.', 44.71631488741777, 7.842901351857487, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione;

-- SEED: CHALLENGES
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Creazione squadra', 'Scegliete nome, motto, avatar e colore della vostra squadra.', 'team_setup', 5, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('c4e6c385-69ba-4f17-a6d0-36b78776d527', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Quiz Bra', 'Rispondete alle domande sulla città di Bra.', 'quiz', 15, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('0147e750-f0a3-4b72-8e76-a003fe2ef143', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Foto ufficiale', 'Scattate la foto ufficiale della squadra.', 'photo', 10, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('999f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Il Rebus Visivo', 'Raggiungete il luogo rappresentato dal simbolo.', 'photo', 25, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('777f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Indovina il film dalle emoji', 'Viaggiatori, si spengono le luci, si alza il sipario: benvenuti nella sala più insolita della caccia!', 'emoji_movies', 15, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('555f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'La locandina vivente', 'La vostra squadra ha appena ricevuto la locandina di un film iconico.', 'living_poster', 15, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'La Banca', 'Quattro indizi, quattro parole, Viaggiatori. Risolveteli come veri enigmisti da settimana enigmistica: una definizione, una risposta, una sola lettera che conta davvero — la prima.', 'banca', 25, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Missione Social', 'Viaggiatori, questa volta la sfida non è contro il tempo, ma contro la vostra capacità di entrare in contatto con il mondo. Dimostrate di saper comunicare, convincere e creare un legame con persone mai incontrate prima.', 'social', 20, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Il Codice Segreto', 'Viaggiatori, per sbloccare la destinazione finale della gara dovete inserire il PIN a 10 cifre. Ma ricordate: voi avete solo mezza chiave. Dovete trovare il vostro partner economico e acquistare il frammento mancante usando i vostri Token.', 'codice', 15, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Rebus Musicale', 'Ricevete il rebus cartaceo, scoprite le 3 note e inseritele nell''ordine corretto.', 'enigma_musicale', 20, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Lucchetto Direzionale', 'Risolvete l''enigma cartaceo e ricavate la sequenza di 4 direzioni.', 'lucchetto_direzionale', 20, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Le Coordinate Finali', 'Risolvete l''enigma cartaceo per ricavare le coordinate finali.', 'enigma_coordinate', 20, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Sfida Cornhole', 'Torneo fisico di Cornhole 1vs1 gestito dalla regia.', 'cornhole', 20, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Boxe Gonfiabile', 'Torneo fisico a eliminazione diretta di Boxe Gonfiabile 1vs1.', 'boxe', 20, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Jackpot della Regia', 'Sfida Bonus opzionale. Sfida la fortuna alla slot machine scommettendo i tuoi punti.', 'jackpot', 20, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;

-- SEED: MARKETPLACE ITEMS

INSERT INTO public.marketplace_items
(id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole)
VALUES
('bonus_punti', 'BONUS PUNTI (+20 PT)', 'bonus', 'Aggiunge +20 PT alla classifica della squadra.', 40, '', 'Sparkles', true, '{}'::jsonb),
('bonus_scudo', 'BONUS SCUDO', 'bonus', 'Protegge la squadra da un malus attivo.', 35, '', 'Shield', true, '{}'::jsonb),
('ruota_fortuna', 'RUOTA DELLA FORTUNA', 'bonus', 'Gira la ruota per vincere premi o subire perdite casuali.', 25, '', 'Compass', true, '{}'::jsonb),
('passaparola', 'PASSAPAROLA', 'bonus', 'Permette di ricevere un aiuto dalla Regia.', 20, '', 'HelpCircle', true, '{}'::jsonb),
('bonus_classifica', 'BONUS CLASSIFICA', 'bonus', 'Visualizza temporaneamente la classifica generale.', 30, '', 'ListOrdered', true, '{}'::jsonb),
('partenza_anticipata', 'PARTENZA ANTICIPATA', 'bonus', '−2 minuti sul tempo di partenza della squadra.', 35, '', 'Zap', true, '{}'::jsonb),
('moltiplicatore_2x', 'MOLTIPLICATORE 2X TAPPA', 'bonus', 'Raddoppia (x2) il punteggio totale ottenuto nella tappa in cui viene attivato.', 45, '', '', true, '{}'::jsonb),
('polizza_diretta', 'POLIZZA RIMBORSO 50%', 'bonus', 'Rimborsa automaticamente il 50% dei punti persi dal prossimo malus di punti subito.', 30, '', '', true, '{}'::jsonb),
('freeze_2min', 'FREEZE 2 MINUTI', 'malus', 'Blocca la squadra avversaria per 2 minuti.', 20, '', 'Flame', true, '{}'::jsonb),
('enigma_extra', 'ENIGMA EXTRA', 'malus', 'La squadra bersaglio deve completare un enigma aggiuntivo.', 25, '', 'AlertTriangle', true, '{}'::jsonb),
('ruota_sfortunata', 'RUOTA SFORTUNATA', 'malus', 'La squadra bersaglio gira una ruota con possibili penalità casuali.', 20, '', 'Skull', true, '{}'::jsonb),
('trappola', 'TRAPPOLA', 'malus', 'Ruba fino a 30 Punti Squadra alla squadra bersaglio.', 40, '', 'Target', true, '{}'::jsonb),
('penalita_punti', 'PENALITÀ PUNTI (-20 PT)', 'malus', 'Sottrae 20 punti alla squadra avversaria.', 30, '', 'MinusCircle', true, '{}'::jsonb),
('tassa_passaggio', 'TASSA DI PASSAGGIO', 'malus', 'Scambia integralmente il punteggio con quello della squadra bersaglio.', 70, '', 'TrendingUp', true, '{}'::jsonb),
('blackout_mercato', 'BLACKOUT MERCATO 6 MINUTI', 'malus', 'Blocca l'accesso al Marketplace al bersaglio per 6 minuti.', 35, '', '', true, '{}'::jsonb),
('dimezza_punti', 'DIMEZZA PUNTI TAPPA', 'malus', 'Dimezza del 50% il punteggio complessivo di una tappa a scelta (Tappe 1–4) del bersaglio.', 40, '', '', true, '{}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
    nome = EXCLUDED.nome,
    tipo = EXCLUDED.tipo,
    descrizione = EXCLUDED.descrizione,
    costo_token = EXCLUDED.costo_token,
    effetto = EXCLUDED.effetto,
    icona = EXCLUDED.icona,
    disponibile = EXCLUDED.disponibile,
    regole = EXCLUDED.regole;

-- SEED: POSTERS

INSERT INTO public.posters (id, file_name, titolo, active) VALUES
('poster_01', 'Poster1.jpg', 'Indiana Jones', true),
('poster_02', 'Poster2.jpg', 'Back to the Future', true),
('poster_03', 'Poster3.jpg', 'Star Wars', true),
('poster_04', 'Poster4.jpg', 'Jurassic Park', true),
('poster_05', 'Poster5.jpg', 'Titanic', true),
('poster_06', 'Poster6.jpg', 'Pulp Fiction', true),
('poster_07', 'Poster7.jpg', 'The Matrix', true),
('poster_08', 'Poster8.jpg', 'Forrest Gump', true),
('poster_09', 'Poster9.jpg', 'E.T.', true),
('poster_10', 'Poster10.jpg', 'The Godfather', true)
ON CONFLICT (id) DO UPDATE SET
    file_name = EXCLUDED.file_name,
    titolo = EXCLUDED.titolo,
    active = EXCLUDED.active;

-- SEED: GAME SETTINGS

INSERT INTO public.game_settings (id, marketplace_visible, marketplace_active)
VALUES ('settings_01', false, false)
ON CONFLICT (id) DO UPDATE SET
    marketplace_visible = EXCLUDED.marketplace_visible,
    marketplace_active = EXCLUDED.marketplace_active;

-- SEED: ENIGMA SOLUTIONS

INSERT INTO public.enigma_solutions (challenge_id, solution_type, solution, punteggio) VALUES
('e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', 'notes', '["La", "Do", "Re"]'::jsonb, 20),
('e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', 'directions', '["nord-ovest", "sud", "ovest", "est"]'::jsonb, 20),
('e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', 'coordinates', '{"lat": "44.71", "lng": "7.84"}'::jsonb, 20)
ON CONFLICT (challenge_id) DO UPDATE SET
    solution = EXCLUDED.solution,
    solution_type = EXCLUDED.solution_type,
    punteggio = EXCLUDED.punteggio;

-- SEED: SETTINGS

INSERT INTO public.settings (id, value)
VALUES
('game_status', 'Gara attiva'),
('game_started_at', now()::text)
ON CONFLICT (id) DO NOTHING;

-- SEED: QUIZ QUESTIONS

INSERT INTO public.quiz_questions
(id, challenge_id, question, options, correct_answer_index, order_index, points)
VALUES
('a1111111-1111-1111-1111-111111111111',
 'c4e6c385-69ba-4f17-a6d0-36b78776d527',
 'Qual è il piatto tipico a base di carne cruda di Bra?',
 '["Salsiccia di Bra", "Prosciutto di Cuneo", "Vitello Tonnato", "Battuta di Fassona"]'::jsonb,
 0, 1, 3),

('a2222222-2222-2222-2222-222222222222',
 'c4e6c385-69ba-4f17-a6d0-36b78776d527',
 'In quale regione italiana si trova Bra?',
 '["Lombardia", "Piemonte", "Liguria", "Veneto"]'::jsonb,
 1, 2, 3),

('a3333333-3333-3333-3333-333333333333',
 'c4e6c385-69ba-4f17-a6d0-36b78776d527',
 'Quale importante movimento internazionale è nato a Bra?',
 '["Slow Food", "WWF", "Greenpeace", "Caritas"]'::jsonb,
 0, 3, 3),

('a4444444-4444-4444-4444-444444444444',
 'c4e6c385-69ba-4f17-a6d0-36b78776d527',
 'Quale celebre scrittore piemontese nacque nei pressi di Bra?',
 '["Cesare Pavese", "Beppe Fenoglio", "Giovanni Arpino", "Italo Calvino"]'::jsonb,
 2, 4, 3),

('a5555555-5555-5555-5555-555555555555',
 'c4e6c385-69ba-4f17-a6d0-36b78776d527',
 'Che tipo di formaggio DOP prende il nome da questa città?',
 '["Castelmagno", "Murazzano", "Raschera", "Bra DOP"]'::jsonb,
 3, 5, 3)

ON CONFLICT (id) DO UPDATE SET
    question = EXCLUDED.question,
    options = EXCLUDED.options,
    correct_answer_index = EXCLUDED.correct_answer_index,
    points = EXCLUDED.points;

-- SEED: GAME REPORT
INSERT INTO public.game_report (id, state, published_at, published_by, snapshot) VALUES ('current', 'PRIVATE_LIVE', NULL, NULL, NULL) ON CONFLICT (id) DO NOTHING;

