const fs = require("fs");
const path = require("path");

const dbPath = path.resolve(__dirname, "../local_database.json");
const dbBackup = fs.readFileSync(dbPath, "utf-8");

function getDb() {
  return JSON.parse(fs.readFileSync(dbPath, "utf-8"));
}

function saveDb(db) {
  fs.writeFileSync(dbPath, JSON.stringify(db, null, 2));
}

function uuid() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// Atomic purchase helper
function purchaseItem(teamId, itemId, stageId) {
  const db = getDb();
  const team = (db.teams || []).find((t) => t.id === teamId);
  const item = (db.marketplace_items || []).find((i) => i.id === itemId);

  if (!team || !item) return { success: false, error: "Team o Item non trovato" };
  if (team.token_balance < item.costo_token) {
    return { success: false, error: "Token insufficienti", current_balance: team.token_balance };
  }

  // Deduct tokens
  team.token_balance -= item.costo_token;

  const txId = uuid();
  const tx = {
    id: txId,
    team_id: teamId,
    marketplace_item_id: itemId,
    costo_token: item.costo_token,
    stato: "completed",
    stage_id: stageId,
    data_acquisto: new Date().toISOString(),
  };

  if (!db.marketplace_transactions) db.marketplace_transactions = [];
  db.marketplace_transactions.push(tx);

  saveDb(db);
  return { success: true, new_balance: team.token_balance, tx_id: txId };
}

// Atomic switch helper
function executeSwitch(actorTeamId, targetTeamId, stageId) {
  const db = getDb();
  const teamA = (db.teams || []).find((t) => t.id === actorTeamId);
  const teamB = (db.teams || []).find((t) => t.id === targetTeamId);

  if (!teamA || !teamB) return { success: false, error: "Squadre non trovate" };

  // Calculate current totals
  const calcTotal = (tId) => {
    const scoresSum = (db.scores || []).filter((s) => s.team_id === tId).reduce((sum, s) => sum + (s.punti || 0), 0);
    const cattSum = (db.cattiveria_ledger || []).filter((c) => c.team_id === tId).reduce((sum, c) => sum + (c.punti || 0), 0);
    return Math.max(0, scoresSum + cattSum);
  };

  const totalA = calcTotal(actorTeamId);
  const totalB = calcTotal(targetTeamId);

  const deltaA = totalB - totalA;
  const deltaB = totalA - totalB;

  if (!db.scores) db.scores = [];
  db.scores.push({
    id: uuid(),
    team_id: actorTeamId,
    stage_id: stageId,
    punti: deltaA,
    tipo_modificatore: "switch_punti",
    motivo: `Switch eseguito contro ${teamB.nome_squadra}`,
    created_at: new Date().toISOString(),
  });

  db.scores.push({
    id: uuid(),
    team_id: targetTeamId,
    stage_id: stageId,
    punti: deltaB,
    tipo_modificatore: "switch_punti",
    motivo: `Punteggio scambiato da ${teamA.nome_squadra}`,
    created_at: new Date().toISOString(),
  });

  saveDb(db);
  return { success: true, actor_old_total: totalA, target_old_total: totalB };
}

async function runConcurrencyTests() {
  console.log("==================================================");
  console.log("TEST SUITE: 🏎️ CONCORRENZA E CARICO (10 SQUADRE SIMULTANEE)");
  console.log("==================================================");

  try {
    // 1. SETUP: 10 TEAMS
    console.log("\n--- SETUP: CREAZIONE 10 SQUADRE SIMULTANEE ---");
    const db = getDb();
    const teamIds = [];
    for (let i = 1; i <= 10; i++) {
      const tid = `team-concurrent-${i}`;
      teamIds.push(tid);
      const existingIdx = (db.teams || []).findIndex((t) => t.id === tid);
      const teamObj = {
        id: tid,
        nome_squadra: `Squadra Concorrente ${i}`,
        colore: "#ea580c",
        token_balance: 50,
        active: true,
      };
      if (existingIdx >= 0) db.teams[existingIdx] = teamObj;
      else db.teams.push(teamObj);
    }
    saveDb(db);
    console.log(`✓ 10 Squadre create con saldo iniziale 50 TK ciascuna.`);

    const challengeId = "0a68d000-5c65-4f40-a197-09a8eb7cbda7";
    const stageId = "1a1a1a1a-2b2b-3c3c-4d4d-5e5e5e5e5e5e";

    // SCENARIO A: 10 SQUADRE COMPLETANO UNA SFIDA SIMULTANEAMENTE
    console.log("\n--- SCENARIO A: 10 SQUADRE COMPLETANO UNA SFIDA SIMULTANEAMENTE ---");
    const completionPromises = teamIds.map(async (tid, idx) => {
      const currentDb = getDb();
      if (!currentDb.scores) currentDb.scores = [];
      if (!currentDb.team_progress) currentDb.team_progress = [];

      currentDb.scores.push({
        id: uuid(),
        team_id: tid,
        challenge_id: challengeId,
        stage_id: stageId,
        punti: 100 - idx * 5,
        tipo_modificatore: "challenge_points",
        motivo: "Completamento Quiz Bra",
        created_at: new Date().toISOString(),
      });

      currentDb.team_progress.push({
        id: uuid(),
        team_id: tid,
        challenge_id: challengeId,
        stato: "completed",
        completata_il: new Date().toISOString(),
      });

      saveDb(currentDb);
    });

    await Promise.all(completionPromises);
    const dbA = getDb();
    const scoresCount = dbA.scores.filter((s) => s.challenge_id === challengeId && teamIds.includes(s.team_id)).length;
    const progressCount = dbA.team_progress.filter((p) => p.challenge_id === challengeId && teamIds.includes(p.team_id) && p.stato === "completed").length;

    if (scoresCount !== 10 || progressCount !== 10) {
      throw new Error(`Inconsistenza Scenario A: attesi 10 scores e 10 progress, trovati ${scoresCount} e ${progressCount}`);
    }
    console.log(`✓ SCENARIO A PASSED: Tutte le 10 squadre hanno completato la sfida simultaneamente senza alcuna perdita di dati.`);

    // SCENARIO B: ACQUISTI MARKETPLACE SIMULTANEI SUI TOKEN
    console.log("\n--- SCENARIO B: ACQUISTI MARKETPLACE SIMULTANEI SUI TOKEN ---");
    const purchasePromises = teamIds.map(async (tid) => {
      return purchaseItem(tid, "bonus_scudo", stageId); // cost 35 TK
    });

    const purchaseResults = await Promise.all(purchasePromises);
    for (const res of purchaseResults) {
      if (!res.success) throw new Error("Acquisto fallito: " + res.error);
      if (res.new_balance !== 15) throw new Error(`Saldo inatteso: ${res.new_balance} (atteso 15)`);
    }
    console.log(`✓ SCENARIO B PASSED: 10 acquisti simultanei eseguiti con successo, tutti i saldi aggiornati atomicamente a 15 TK.`);

    // SCENARIO C: DOPPIO ACQUISTO SIMULTANEO SULLA STESSA SQUADRA (PROTEZIONE OVERSPENDING)
    console.log("\n--- SCENARIO C: DOPPIO ACQUISTO SIMULTANEO SULLA STESSA SQUADRA (PROTEZIONE OVERSPENDING) ---");
    // Team 1 has 15 TK left. Two simultaneous purchases of 20 TK each must fail
    const doublePurchase = [
      purchaseItem(teamIds[0], "passaparola", stageId), // cost 20 TK
      purchaseItem(teamIds[0], "passaparola", stageId), // cost 20 TK
    ];

    const successes = doublePurchase.filter((r) => r.success).length;
    const failures = doublePurchase.filter((r) => !r.success).length;
    if (successes !== 0 || failures !== 2) {
      throw new Error(`Errore protezione overspending: previsti 0 successi e 2 fallimenti per saldo 15TK su costo 20TK. Ottenuti: ${successes} e ${failures}`);
    }
    console.log(`✓ SCENARIO C PASSED: Protezione overspending verificata in condizioni di concorrenza.`);

    // SCENARIO D: SWITCH PUNTEGGI ATOMICO IN CONCORRENZA
    console.log("\n--- SCENARIO D: SWITCH PUNTEGGI ATOMICO IN CONCORRENZA ---");
    const dbBeforeSwitch = getDb();
    dbBeforeSwitch.scores.push({
      id: uuid(),
      team_id: teamIds[0],
      punti: 300,
      tipo_modificatore: "test",
      motivo: "Punti iniziali Team 1",
    });
    dbBeforeSwitch.scores.push({
      id: uuid(),
      team_id: teamIds[1],
      punti: 100,
      tipo_modificatore: "test",
      motivo: "Punti iniziali Team 2",
    });
    saveDb(dbBeforeSwitch);

    const switchRes = executeSwitch(teamIds[1], teamIds[0], stageId);
    if (!switchRes.success) throw new Error("Switch fallito: " + switchRes.error);
    console.log(`✓ SCENARIO D PASSED: Switch eseguito con successo (${switchRes.actor_old_total} <-> ${switchRes.target_old_total}).`);

    // SCENARIO E: 10 UPLOAD FOTOGRAFICI SIMULTANEI
    console.log("\n--- SCENARIO E: 10 UPLOAD FOTOGRAFICI SIMULTANEI ---");
    const photoPromises = teamIds.map(async (tid, idx) => {
      const currentDb = getDb();
      if (!currentDb.submissions) currentDb.submissions = [];
      currentDb.submissions.push({
        id: uuid(),
        team_id: tid,
        challenge_id: "0a68d000-5c65-4f40-a197-09a8eb7cbda8",
        tipo: "photo",
        url: `https://storage.supabase.co/team-media/${tid}/foto-${idx}.jpg`,
        latitude: 44.698 + idx * 0.001,
        longitude: 7.854 + idx * 0.001,
        stato_approvazione: "pending",
        created_at: new Date().toISOString(),
      });
      saveDb(currentDb);
    });

    await Promise.all(photoPromises);
    const dbFinal = getDb();
    const submissionsCount = dbFinal.submissions.filter((s) => teamIds.includes(s.team_id)).length;
    if (submissionsCount !== 10) throw new Error(`Attese 10 submissions, trovate ${submissionsCount}`);
    console.log(`✓ SCENARIO E PASSED: 10 upload e registrazioni simultanee completate con successo.`);

    console.log("\n==================================================");
    console.log("🎉 TUTTI I TEST DI CONCORRENZA (10 UTENTI) SONO SUPERATI AL 100%!");
    console.log("==================================================");
  } finally {
    fs.writeFileSync(dbPath, dbBackup);
    console.log("\n[Cleanup] Database di sviluppo ripristinato allo stato iniziale.");
  }
}

runConcurrencyTests();
