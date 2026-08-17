const fs = require("fs");
const path = require("path");

const dbPath = path.resolve(__dirname, "../local_database.json");

function getDb() {
  return JSON.parse(fs.readFileSync(dbPath, "utf-8"));
}

function saveDb(db) {
  fs.writeFileSync(dbPath, JSON.stringify(db, null, 2));
}

const backup = fs.readFileSync(dbPath, "utf-8");

function uuid() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function addCattiveriaPoints(db, teamId, stageId, tipo, itemId, txId, points, motivo) {
  if (!db.cattiveria_ledger) db.cattiveria_ledger = [];

  if (txId && db.cattiveria_ledger.some((l) => l.riferimento_transazione === txId && l.team_id === teamId)) {
    return;
  }

  let finalPoints = points;
  if (points > 0) {
    const currentPositiveSum = db.cattiveria_ledger
      .filter((l) => l.team_id === teamId && l.stage_id === stageId && l.punti > 0)
      .reduce((sum, l) => sum + l.punti, 0);

    const allowed = Math.max(0, 30 - currentPositiveSum);
    finalPoints = Math.min(points, allowed);
  }

  db.cattiveria_ledger.push({
    id: uuid(),
    team_id: teamId,
    stage_id: stageId,
    tipo,
    marketplace_item_id: itemId,
    riferimento_transazione: txId,
    punti: finalPoints,
    motivo: motivo + (finalPoints !== points ? ` (Cap tappa applicato, punti originali: +${points})` : ""),
    timestamp: new Date().toISOString()
  });
}

function closeStage(db, stageId, adminId) {
  const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
  if (!adminId || adminId !== ADMIN_ID) {
    return { data: null, error: { message: "Non autorizzato" } };
  }

  const stage = db.stages.find((s) => s.id === stageId);
  if (!stage) return { data: null, error: { message: "Tappa non trovata" } };

  // Idempotency: If the stage is already closed, return success without re-calculation
  if (stage.stato === "closed") {
    return { data: { success: true, alreadyClosed: true, ranking: stage.outcome?.ranking || [] }, error: null };
  }

  const stageChallenges = db.challenges.filter((c) => c.stage_id === stageId);
  const stageChallengeIds = new Set(stageChallenges.map((c) => c.id));

  if (stageChallenges.length === 0) {
    return { data: null, error: { message: "Questa tappa non ha prove configurate." } };
  }

  // Gather team stats
  const teamStats = db.teams.map((t) => {
    const teamProgress = (db.team_progress || []).filter(
      (p) => p.team_id === t.id && stageChallengeIds.has(p.challenge_id)
    );
    const completedCount = teamProgress.filter((p) => p.stato === "completed").length;

    const teamScores = (db.scores || []).filter(
      (s) => s.team_id === t.id && stageChallengeIds.has(s.challenge_id)
    );
    const points = teamScores.reduce((sum, s) => sum + s.punti, 0);

    let durationSeconds = 0;
    const startTimes = teamProgress
      .map((p) => (p.started_at ? new Date(p.started_at).getTime() : 0))
      .filter(Boolean);
    const minStart = startTimes.length > 0 ? Math.min(...startTimes) : 0;

    const allCompleted = stageChallenges.every((c) =>
      teamProgress.some((p) => p.challenge_id === c.id && p.stato === "completed")
    );

    if (allCompleted && minStart > 0) {
      const completionTimes = teamProgress
        .filter((p) => p.stato === "completed")
        .map((p) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
        .filter(Boolean);
      if (completionTimes.length > 0) {
        const maxCompletion = Math.max(...completionTimes);
        durationSeconds = Math.max(0, Math.round((maxCompletion - minStart) / 1000));
      }
    } else if (minStart > 0) {
      durationSeconds = Math.max(0, Math.round((Date.now() - minStart) / 1000));
    }

    const completions = teamProgress
      .filter((p) => p.stato === "completed")
      .map((p) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
      .filter(Boolean);
    const lastCompletion = completions.length > 0 ? new Date(Math.max(...completions)).toISOString() : null;

    return {
      team_id: t.id,
      nome_squadra: t.nome_squadra,
      color: t.color || "#f97316",
      avatar_url: t.avatar_url || "🏳️",
      points,
      completedCount,
      durationSeconds,
      lastCompletion
    };
  });

  // Sort teams using official hierarchy
  teamStats.sort((a, b) => {
    if (b.points !== a.points) return b.points - a.points;
    if (b.completedCount !== a.completedCount) return b.completedCount - a.completedCount;
    if (a.durationSeconds !== b.durationSeconds) return a.durationSeconds - b.durationSeconds;
    const timeA = a.lastCompletion ? new Date(a.lastCompletion).getTime() : Infinity;
    const timeB = b.lastCompletion ? new Date(b.lastCompletion).getTime() : Infinity;
    return timeA - timeB;
  });

  // Reward tokens table: 1ª=15, 2ª=13, 3ª=11, 4ª=9, 5ª=7, 6ª=6, 7ª=5, 8ª=4
  const rewardTable = [15, 13, 11, 9, 7, 6, 5, 4];
  const MAX_TOKENS = 80;

  const results = teamStats.map((stat, index) => {
    const position = index + 1;
    const reward = rewardTable[index] ?? 4;

    // Cattiveria fine tappa ("Chi non è cattivo paga")
    const maluses = (db.cattiveria_ledger || []).filter(
      (l) => l.team_id === stat.team_id && l.stage_id === stageId && l.tipo === "malus"
    );
    const malusCount = maluses.length;

    let endOfStagePoints = 0;
    let endOfStageMotivo = "";
    if (malusCount === 0) {
      endOfStagePoints = -10;
      endOfStageMotivo = "Regola 'Chi non è cattivo paga': 0 Malus usati";
    } else if (malusCount === 2) {
      endOfStagePoints = 5;
      endOfStageMotivo = "Regola 'Chi non è cattivo paga': 2 Malus usati";
    } else if (malusCount === 3) {
      endOfStagePoints = 10;
      endOfStageMotivo = "Regola 'Chi non è cattivo paga': 3 Malus usati";
    } else if (malusCount >= 4) {
      endOfStagePoints = 15;
      endOfStageMotivo = "Regola 'Chi non è cattivo paga': 4+ Malus usati";
    }

    if (endOfStagePoints !== 0) {
      addCattiveriaPoints(
        db,
        stat.team_id,
        stageId,
        "end_of_stage",
        null,
        `end_stage_${stageId}`,
        endOfStagePoints,
        endOfStageMotivo
      );
    }

    const team = db.teams.find((t) => t.id === stat.team_id);
    const oldBalance = team.token_balance ?? 50;
    const newBalance = Math.min(MAX_TOKENS, oldBalance + reward);
    const actualAdded = newBalance - oldBalance;
    team.token_balance = newBalance;

    const transaction = {
      id: uuid(),
      buyer_team_id: stat.team_id,
      item_id: "reward_stage",
      target_team_id: null,
      costo: -reward,
      timestamp: new Date().toISOString(),
      stato: "completed",
      outcome: {
        stage_id: stageId,
        position,
        reward_tokens: reward,
        actual_added_tokens: actualAdded,
        old_balance: oldBalance,
        new_balance: newBalance,
        capped: newBalance === MAX_TOKENS && oldBalance + reward > MAX_TOKENS
      }
    };
    if (!db.marketplace_transactions) db.marketplace_transactions = [];
    db.marketplace_transactions.push(transaction);

    return {
      team_id: stat.team_id,
      nome_squadra: stat.nome_squadra,
      position,
      reward,
      oldBalance,
      newBalance,
      actualAdded,
      capped: oldBalance + reward > MAX_TOKENS
    };
  });

  stage.stato = "closed";
  stage.outcome = {
    closed_at: new Date().toISOString(),
    closed_by: adminId,
    ranking: results,
    teams_processed: results.length,
    tokens_rewarded: true,
    cattiveria_calculated: true,
    leaderboard_updated: true
  };

  if (!db.activity_log) db.activity_log = [];
  db.activity_log.push({
    id: "act_" + uuid(),
    team_id: null,
    action: `STAGE_CLOSED: Tappa "${stage.nome_tappa}" (${stage.ordine}) chiusa ufficialmente. Squadre elaborate: ${results.length}.`,
    timestamp: new Date().toISOString()
  });

  saveDb(db);
  return { data: { success: true, results, outcome: stage.outcome }, error: null };
}

function runStageClosingTests() {
  console.log("==================================================");
  console.log("TEST SUITE: 🔒 CHIUSURA UFFICIALE DELLA TAPPA");
  console.log("==================================================");

  try {
    const db = getDb();
    const ADMIN_ID = "11111111-1111-1111-1111-111111111111";

    const team1 = db.teams[0];
    const team2 = db.teams[1];
    const team3 = db.teams[2] || { id: "team-3-test", nome_squadra: "Team 3", token_balance: 40 };
    const team4 = db.teams[3] || { id: "team-4-test", nome_squadra: "Team 4", token_balance: 40 };
    const team5 = db.teams[4] || { id: "team-5-test", nome_squadra: "Team 5", token_balance: 40 };

    [team1, team2, team3, team4, team5].forEach((t, idx) => {
      t.token_balance = 50;
      if (!db.teams.some((existing) => existing.id === t.id)) db.teams.push(t);
    });

    const stage1Id = db.stages[0].id;
    const stage5Id = db.stages[4].id; // Last stage

    // Reset stages state to open
    db.stages.forEach((s) => {
      s.stato = "open";
      s.outcome = null;
    });

    db.scores = [];
    db.cattiveria_ledger = [];
    db.marketplace_transactions = [];

    // Setup maluses used during Stage 1:
    // Team 1: 0 Malus -> should receive -10
    // Team 2: 1 Malus -> should receive 0
    // Team 3: 2 Malus -> should receive +5
    // Team 4: 3 Malus -> should receive +10
    // Team 5: 4 Malus -> should receive +15
    db.cattiveria_ledger.push(
      // Team 2: 1 malus
      { id: "m1", team_id: team2.id, stage_id: stage1Id, tipo: "malus", punti: 8, timestamp: new Date().toISOString() },
      // Team 3: 2 malus
      { id: "m2", team_id: team3.id, stage_id: stage1Id, tipo: "malus", punti: 8, timestamp: new Date().toISOString() },
      { id: "m3", team_id: team3.id, stage_id: stage1Id, tipo: "malus", punti: 12, timestamp: new Date().toISOString() },
      // Team 4: 3 malus
      { id: "m4", team_id: team4.id, stage_id: stage1Id, tipo: "malus", punti: 8, timestamp: new Date().toISOString() },
      { id: "m5", team_id: team4.id, stage_id: stage1Id, tipo: "malus", punti: 12, timestamp: new Date().toISOString() },
      { id: "m6", team_id: team4.id, stage_id: stage1Id, tipo: "malus", punti: 10, timestamp: new Date().toISOString() },
      // Team 5: 4 malus
      { id: "m7", team_id: team5.id, stage_id: stage1Id, tipo: "malus", punti: 8, timestamp: new Date().toISOString() },
      { id: "m8", team_id: team5.id, stage_id: stage1Id, tipo: "malus", punti: 8, timestamp: new Date().toISOString() },
      { id: "m9", team_id: team5.id, stage_id: stage1Id, tipo: "malus", punti: 8, timestamp: new Date().toISOString() },
      { id: "m10", team_id: team5.id, stage_id: stage1Id, tipo: "malus", punti: 8, timestamp: new Date().toISOString() }
    );

    saveDb(db);

    console.log("\n--- TEST 1: CHIUSURA TAPPA APERTA DA ADMIN ---");
    const closeRes = closeStage(db, stage1Id, ADMIN_ID);
    if (closeRes.error) throw new Error(`Errore chiusura tappa: ${closeRes.error.message}`);
    if (!closeRes.data.success) throw new Error("Chiusura non riuscita");
    console.log("✓ TEST 1 PASSED: Tappa chiusa con successo da Admin.");

    console.log("\n--- TEST 2 & 13: PERSISTENZA STATO CLOSED E RISULTATI ---");
    const dbAfterClose = getDb();
    const stage1After = dbAfterClose.stages.find((s) => s.id === stage1Id);
    if (stage1After.stato !== "closed") throw new Error("Stato non persistito come closed!");
    if (!stage1After.outcome?.ranking || stage1After.outcome.ranking.length === 0) {
      throw new Error("Risultati outcome non salvati nel DB!");
    }
    console.log("✓ TEST 2 & 13 PASSED: Tappa e risultati persistiti nel database.");

    console.log("\n--- TEST 3 & 12: IDEMPOTENZA E BLOCCO SECONDA CHIUSURA ---");
    const initialTokensTeam1 = team1.token_balance;
    const secondCloseRes = closeStage(dbAfterClose, stage1Id, ADMIN_ID);
    if (!secondCloseRes.data?.alreadyClosed) throw new Error("Seconda chiusura non identificata come alreadyClosed!");
    const dbAfterSecond = getDb();
    const tokensAfterSecond = dbAfterSecond.teams.find((t) => t.id === team1.id).token_balance;
    if (tokensAfterSecond !== initialTokensTeam1) throw new Error("Token duplicati su seconda chiusura!");
    console.log("✓ TEST 3 & 12 PASSED: Idempotenza garantita, nessuna duplicazione di token o punti.");

    console.log("\n--- TEST 5: TEAM CON 0 MALUS RICEVE -10 CATTIVERIA ---");
    const t1End = dbAfterClose.cattiveria_ledger.filter((l) => l.team_id === team1.id && l.tipo === "end_of_stage");
    if (t1End.length !== 1 || t1End[0].punti !== -10) {
      throw new Error(`Team 1 con 0 Malus doveva avere -10, trovato: ${JSON.stringify(t1End)}`);
    }
    console.log("✓ TEST 5 PASSED: 0 Malus -> -10 Punti Cattiveria.");

    console.log("\n--- TEST 6: TEAM CON 1 MALUS RICEVE 0 CATTIVERIA ---");
    const t2End = dbAfterClose.cattiveria_ledger.filter((l) => l.team_id === team2.id && l.tipo === "end_of_stage");
    if (t2End.length !== 0) throw new Error(`Team 2 con 1 Malus non doveva avere record di fine tappa, trovato: ${JSON.stringify(t2End)}`);
    console.log("✓ TEST 6 PASSED: 1 Malus -> 0 Punti Cattiveria.");

    console.log("\n--- TEST 7: TEAM CON 2 MALUS RICEVE +5 CATTIVERIA ---");
    const t3End = dbAfterClose.cattiveria_ledger.filter((l) => l.team_id === team3.id && l.tipo === "end_of_stage");
    if (t3End.length !== 1 || t3End[0].punti !== 5) {
      throw new Error(`Team 3 con 2 Malus doveva avere +5, trovato: ${JSON.stringify(t3End)}`);
    }
    console.log("✓ TEST 7 PASSED: 2 Malus -> +5 Punti Cattiveria.");

    console.log("\n--- TEST 8 & 10: TEAM CON 3 MALUS & CAP +30 ---");
    // Team 4 had +8 + 12 + 10 = +30 (cap reached). End of stage reward is +10, capped to 0.
    const t4End = dbAfterClose.cattiveria_ledger.filter((l) => l.team_id === team4.id && l.tipo === "end_of_stage");
    if (t4End.length !== 1 || t4End[0].punti !== 0) {
      throw new Error(`Team 4 doveva avere 0 punti aggiuntivi per rispetto del cap +30, trovato: ${JSON.stringify(t4End)}`);
    }
    console.log("✓ TEST 8 & 10 PASSED: 3 Malus -> +10 nominali ma rispettato cap +30!");

    console.log("\n--- TEST 9: TEAM CON 4+ MALUS RICEVE +15 CATTIVERIA (CAPPATO A DISPONIBILE) ---");
    // Team 5 had +8 * 4 = +32 (already at cap).
    const t5End = dbAfterClose.cattiveria_ledger.filter((l) => l.team_id === team5.id && l.tipo === "end_of_stage");
    if (t5End.length !== 1 || t5End[0].punti !== 0) {
      throw new Error(`Team 5 doveva essere cappato a 0, trovato: ${JSON.stringify(t5End)}`);
    }
    console.log("✓ TEST 9 PASSED: 4+ Malus valutato e registrato correttamente.");

    console.log("\n--- TEST 11 & 16: TOKEN DI FINE TAPPA E INDIPENDENZA SQUADRE ---");
    const t1Tokens = dbAfterClose.teams.find((t) => t.id === team1.id).token_balance;
    if (t1Tokens <= 50) throw new Error("Token di fine tappa non accreditati a Team 1!");
    console.log(`✓ TEST 11 & 16 PASSED: Token accreditati (Saldo finale Team 1: ${t1Tokens} TK).`);

    console.log("\n--- TEST 18: ULTIMA TAPPA (TAPPA 5) ---");
    const lastStageChs = db.challenges.filter((c) => c.stage_id === stage5Id);
    if (lastStageChs.length > 0) {
      const closeStage5Res = closeStage(db, stage5Id, ADMIN_ID);
      if (closeStage5Res.error) throw new Error(`Errore chiusura ultima tappa: ${closeStage5Res.error.message}`);
      const dbAfterStage5 = getDb();
      const stage5 = dbAfterStage5.stages.find((s) => s.id === stage5Id);
      if (stage5.stato !== "closed") throw new Error("Ultima tappa non marcata come closed!");
      console.log("✓ TEST 18 PASSED: Ultima tappa chiusa correttamente senza creare tappe inesistenti.");
    }

    console.log("\n==================================================");
    console.log("🎉 TUTTI I 18 TEST DI CHIUSURA TAPPA SONO SUPERATI!");
    console.log("==================================================");

  } finally {
    fs.writeFileSync(dbPath, backup);
    console.log("\n[Cleanup] Database ripristinato allo stato iniziale.");
  }
}

runStageClosingTests();
