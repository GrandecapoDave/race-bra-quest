const fs = require("fs");
const path = require("path");

function escapeSql(str) {
  if (str === null || str === undefined) return "NULL";
  return `'${String(str).replace(/'/g, "''")}'`;
}

function generateSeedSQL() {
  const dbPath = path.resolve(__dirname, "../local_database.json");
  const db = JSON.parse(fs.readFileSync(dbPath, "utf-8"));
  const seedPath = path.resolve(__dirname, "../supabase/seed.sql");

  let sql = "-- ============================================================================\n";
  sql += "-- PECHINO EXPRESS BRA — INITIAL SEED DATA FOR SUPABASE POSTGRESQL\n";
  sql += "-- ============================================================================\n\n";

  // 1. Teams
  if (db.teams && db.teams.length > 0) {
    sql += "-- SEED: TEAMS\n";
    for (const t of db.teams) {
      const nome = t.nome_squadra || t.name || "Squadra";
      sql += `INSERT INTO public.teams (id, nome_squadra, colore, token_balance, active) VALUES ('${t.id}', ${escapeSql(nome)}, ${escapeSql(t.colore || t.color || "#ea580c")}, ${t.token_balance || 50}, ${t.active !== false}) ON CONFLICT (id) DO UPDATE SET token_balance = EXCLUDED.token_balance;\n`;
    }
    sql += "\n";
  }

  // 2. Stages
  if (db.stages && db.stages.length > 0) {
    sql += "-- SEED: STAGES\n";
    for (let i = 0; i < db.stages.length; i++) {
      const s = db.stages[i];
      const numero = s.numero_tappa || s.ordine || (i + 1);
      const titolo = s.titolo || s.nome_tappa || `Tappa ${numero}`;
      const outcome = s.outcome ? `${escapeSql(JSON.stringify(s.outcome))}::jsonb` : "NULL";
      const lat = s.latitude !== undefined && s.latitude !== null ? s.latitude : "NULL";
      const lng = s.longitude !== undefined && s.longitude !== null ? s.longitude : "NULL";

      sql += `INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('${s.id}', ${numero}, ${escapeSql(titolo)}, ${escapeSql(s.descrizione || "")}, ${lat}, ${lng}, '${s.stato || "open"}', ${outcome}) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione;\n`;
    }
    sql += "\n";
  }

  // 3. Challenges
  if (db.challenges && db.challenges.length > 0) {
    sql += "-- SEED: CHALLENGES\n";
    for (let i = 0; i < db.challenges.length; i++) {
      const c = db.challenges[i];
      const ordine = c.ordine_sfida || c.ordine || (i + 1);
      const config = c.configurazione ? `${escapeSql(JSON.stringify(c.configurazione))}::jsonb` : "'{}'::jsonb";
      sql += `INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('${c.id}', '${c.stage_id}', ${escapeSql(c.titolo)}, ${escapeSql(c.descrizione || "")}, ${escapeSql(c.tipo_sfida)}, ${c.punteggio_massimo || 100}, ${ordine}, ${config}) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;\n`;
    }
    sql += "\n";
  }

  // 4. Marketplace Items
  if (db.marketplace_items && db.marketplace_items.length > 0) {
    sql += "-- SEED: MARKETPLACE ITEMS\n";
    for (const m of db.marketplace_items) {
      const regole = m.regole ? `${escapeSql(JSON.stringify(m.regole))}::jsonb` : "'{}'::jsonb";
      sql += `INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('${m.id}', ${escapeSql(m.nome)}, ${escapeSql(m.tipo)}, ${escapeSql(m.descrizione || "")}, ${m.costo_token}, ${escapeSql(m.effetto || "")}, ${escapeSql(m.icona || "")}, ${m.disponibile !== false}, ${regole}) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;\n`;
    }
    sql += "\n";
  }

  // 5. Game Report initial state
  sql += "-- SEED: GAME REPORT\n";
  sql += `INSERT INTO public.game_report (id, state, published_at, published_by, snapshot) VALUES ('current', 'PRIVATE_LIVE', NULL, NULL, NULL) ON CONFLICT (id) DO NOTHING;\n\n`;

  fs.writeFileSync(seedPath, sql);
  console.log("✓ Generated supabase/seed.sql successfully with complete stages, challenges, and teams data!");
}

generateSeedSQL();
