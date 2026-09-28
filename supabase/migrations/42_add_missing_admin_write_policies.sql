-- 42_add_missing_admin_write_policies.sql
-- Trovato durante il test: anche con la policy corretta, la regolazione manuale dei token falliva comunque,
-- per un secondo motivo scoperto solo dopo aver sbloccato la policy: marketplace_items non aveva una riga
-- 'admin_token_adjust' (vincolo di chiave esterna). Aggiunta come voce amministrativa, non acquistabile
-- (disponibile=false) e senza costo proprio (il costo/importo reale è quello scritto nella singola transazione).
-- Audit RLS: ogni policy di scrittura esistente e' correttamente vincolata (solo admin o solo la propria
-- squadra) - nessun problema di sicurezza trovato. Mancavano pero' 3 policy di scrittura per l'admin, che
-- bloccavano (in modo visibile, con errore) alcune funzioni della Regia che scrivono direttamente sulla
-- tabella invece di passare da una funzione del database:
--   - challenges: "Aggiungi Nuova Prova" in Regia > Configurazione non aveva alcuna policy di scrittura.
--   - marketplace_transactions: la regolazione manuale dei token aggiorna il saldo correttamente (tramite
--     admin_adjust_team_tokens, che logga anche in activity_log), ma la riga aggiuntiva per lo storico
--     acquisti della squadra falliva in silenzio per mancanza di policy.
--   - scores: un percorso di riserva per l'eliminazione di una regolazione punti manuale (usato solo se la
--     funzione admin_delete_team_score fallisce) non aveva policy; aggiunta per coerenza/sicurezza aggiuntiva.

-- Idempotente: rimuove ed ricrea, cosi' la migrazione si puo' rieseguire senza errori
DROP POLICY IF EXISTS "Admin Write Challenges" ON public.challenges;
CREATE POLICY "Admin Write Challenges" ON public.challenges
  FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::text))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Admin Write Marketplace Transactions" ON public.marketplace_transactions;
CREATE POLICY "Admin Write Marketplace Transactions" ON public.marketplace_transactions
  FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::text))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Admin Delete Scores" ON public.scores;
CREATE POLICY "Admin Delete Scores" ON public.scores
  FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::text));

INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, disponibile)
VALUES ('admin_token_adjust', 'Regolazione Token (Regia)', 'bonus', 'Voce amministrativa per le regolazioni manuali dei token da parte della Regia.', 0, false)
ON CONFLICT (id) DO NOTHING;
