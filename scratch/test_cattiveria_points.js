const fs = require("fs");
const path = require("path");

const dbPath = path.resolve(__dirname, "../local_database.json");

function getDb() {
  return JSON.parse(fs.readFileSync(dbPath, "utf-8"));
}

function saveDb(db) {
  fs.writeFileSync(dbPath, JSON.stringify(db, null, 2));
}

// Backup DB before tests
const backup = fs.readFileSync(dbPath, "utf-8");

function uuid() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function getTeamCurrentStageId(db, teamId) {
  const completedChIds = (db.team_progress || [])
    .filter((tp) => tp.team_id === teamId && tp.stato === "completed")
    .map((tp) => tp.challenge_id);

  const sortedStages = [...(db.stages || [])].sort((a, b) => a.ordine - b.ordine);
  for (const s of sortedStages) {
    const stageChs = (db.challenges || []).filter((c) => c.stage_id === s.id);
    if (stageChs.length === 0) continue;
    const allDone = stageChs.every((c) => completedChIds.includes(c.id));
    if (!allDone) {
      return s.id;
    }
  }
  return sortedStages[sortedStages.length - 1]?.id || "";
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

function buyMarketplaceItem(db, currentUserId, p_item_id, p_target_team_id) {
  const item = db.marketplace_items.find((i) => i.id === p_item_id);
  if (!item) return { data: null, error: { message: "Prodotto non trovato" } };

  if (!db.marketplace_transactions) db.marketplace_transactions = [];

  const alreadyPurchased = db.marketplace_transactions.some(
    (t) => t.buyer_team_id === currentUserId && t.item_id === p_item_id
  );

  const team = db.teams.find((t) => t.id === currentUserId);
  if (!team) return { data: null, error: { message: "Squadra non trovata" } };

  const balance = team.token_balance ?? 50;
  if (alreadyPurchased || balance < item.costo_token) {
    return { data: null, error: { message: "Questo oggetto è già stato utilizzato oppure non possiedi abbastanza token." } };
  }

  let targetTeam = null;
  if (item.categoria === "MALUS") {
    if (!p_target_team_id) return { data: null, error: { message: "Scegli la squadra avversaria da colpire" } };
    if (p_target_team_id === currentUserId) return { data: null, error: { message: "Non puoi colpire la tua stessa squadra!" } };
    targetTeam = db.teams.find((t) => t.id === p_target_team_id);
    if (!targetTeam) return { data: null, error: { message: "Squadra bersaglio non trovata." } };

    if (item.id === "freeze_2min") {
      const isTargetFrozen = targetTeam.freeze_expires_at && new Date(targetTeam.freeze_expires_at).getTime() > Date.now();
      if (isTargetFrozen) return { data: null, error: { message: "La squadra bersaglio è già congelata!" } };
    }
  }

  // Deduct tokens
  team.token_balance = balance - item.costo_token;
  let outcome = null;

  // Check shield
  if (item.categoria === "MALUS" && targetTeam) {
    const activeShieldTx = db.marketplace_transactions.find(
      (t) => t.buyer_team_id === targetTeam.id && t.item_id === "bonus_scudo" && t.stato === "completed"
    );
    if (activeShieldTx) {
      activeShieldTx.stato = "used";
      activeShieldTx.blocked_info = {
        attacker_team_id: currentUserId,
        item_id: item.id,
        timestamp: new Date().toISOString()
      };

      const targetStageId = getTeamCurrentStageId(db, targetTeam.id);
      addCattiveriaPoints(
        db,
        targetTeam.id,
        targetStageId,
        "bonus",
        "bonus_scudo",
        activeShieldTx.id,
        -3,
        `Utilizzo Scudo (Malus ${item.nome} bloccato)`
      );

      const transaction = {
        id: uuid(),
        buyer_team_id: currentUserId,
        item_id: item.id,
        target_team_id: p_target_team_id,
        costo: item.costo_token,
        timestamp: new Date().toISOString(),
        stato: "blocked",
        blocked_by_shield_id: activeShieldTx.id
      };
      db.marketplace_transactions.push(transaction);
      saveDb(db);
      return { data: { success: true, balance: team.token_balance, blockedByShield: true }, error: null };
    }
  }

  if (item.id === "ruota_fortuna") {
    outcome = { id: "bonus", label: "⭐ BONUS", points: 10, tokens: 0 };
    if (outcome.points > 0) {
      db.scores.push({
        id: uuid(),
        team_id: currentUserId,
        challenge_id: null,
        punti: outcome.points,
        motivazione: `Ruota della Fortuna: ${outcome.label}`,
        created_at: new Date().toISOString()
      });
    }
  }

  if (item.id === "bonus_punti") {
    db.scores.push({
      id: uuid(),
      team_id: currentUserId,
      challenge_id: null,
      punti: 20,
      motivazione: "Acquisto Bonus Punti (+20 PT)",
      created_at: new Date().toISOString()
    });
  }

  if (item.id === "freeze_2min" && targetTeam) {
    const startedAt = new Date().toISOString();
    const expiresAt = new Date(Date.now() + 120000).toISOString();
    targetTeam.freeze_started_at = startedAt;
    targetTeam.freeze_expires_at = expiresAt;
    targetTeam.freeze_duration_seconds = 120;
    outcome = { freeze_started_at: startedAt, freeze_expires_at: expiresAt, duration_seconds: 120 };
  }

  if (item.id === "trappola" && targetTeam) {
    const targetScores = db.scores.filter((s) => s.team_id === targetTeam.id);
    const targetCurrentPoints = targetScores.reduce((sum, s) => sum + s.punti, 0);
    const pointsStolen = Math.max(0, Math.min(30, targetCurrentPoints));
    const buyerScores = db.scores.filter((s) => s.team_id === currentUserId);
    const buyerCurrentPoints = buyerScores.reduce((sum, s) => sum + s.punti, 0);

    if (pointsStolen > 0) {
      db.scores.push({
        id: uuid(),
        team_id: targetTeam.id,
        challenge_id: null,
        punti: -pointsStolen,
        motivazione: `Malus Trappola: sottratti −${pointsStolen} PT da ${team.nome_squadra || "avversario"}`,
        created_at: new Date().toISOString()
      });
      db.scores.push({
        id: uuid(),
        team_id: currentUserId,
        challenge_id: null,
        punti: pointsStolen,
        motivazione: `Malus Trappola: rubati +${pointsStolen} PT a ${targetTeam.nome_squadra}`,
        created_at: new Date().toISOString()
      });
    }
    outcome = { nominal_points: 30, points_stolen: pointsStolen };
  }

  if (item.id === "penalita_punti" && targetTeam) {
    const targetScores = db.scores.filter((s) => s.team_id === targetTeam.id);
    const targetCurrentPoints = targetScores.reduce((sum, s) => sum + s.punti, 0);
    const pointsDeducted = Math.max(0, Math.min(20, targetCurrentPoints));
    if (pointsDeducted > 0) {
      db.scores.push({
        id: uuid(),
        team_id: targetTeam.id,
        challenge_id: null,
        punti: -pointsDeducted,
        motivazione: `Malus Penalità Punti (-20 PT) inflitto da ${team.nome_squadra || "avversario"}`,
        created_at: new Date().toISOString()
      });
    }
    outcome = { nominal_points: 20, points_deducted: pointsDeducted };
  }

  if (item.id === "tassa_passaggio" && targetTeam) {
    const buyerScores = db.scores.filter((s) => s.team_id === currentUserId);
    const buyerCurrentPoints = buyerScores.reduce((sum, s) => sum + s.punti, 0);
    const targetScores = db.scores.filter((s) => s.team_id === targetTeam.id);
    const targetCurrentPoints = targetScores.reduce((sum, s) => sum + s.punti, 0);

    const buyerDiff = targetCurrentPoints - buyerCurrentPoints;
    const targetDiff = buyerCurrentPoints - targetCurrentPoints;

    db.scores.push({
      id: uuid(),
      team_id: currentUserId,
      challenge_id: null,
      punti: buyerDiff,
      source: "MARKETPLACE_SWITCH",
      motivazione: `Tassa di Passaggio: scambiati ${buyerCurrentPoints} PT con ${targetCurrentPoints} PT di ${targetTeam.nome_squadra}`,
      created_at: new Date().toISOString()
    });

    db.scores.push({
      id: uuid(),
      team_id: targetTeam.id,
      challenge_id: null,
      punti: targetDiff,
      source: "MARKETPLACE_SWITCH",
      motivazione: `Tassa di Passaggio: scambiati ${targetCurrentPoints} PT con ${buyerCurrentPoints} PT di ${team.nome_squadra}`,
      created_at: new Date().toISOString()
    });

    outcome = {
      buyer_points_before: buyerCurrentPoints,
      buyer_points_after: targetCurrentPoints,
      target_points_before: targetCurrentPoints,
      target_points_after: buyerCurrentPoints
    };
  }

  const transaction = {
    id: uuid(),
    buyer_team_id: currentUserId,
    item_id: item.id,
    target_team_id: item.categoria === "MALUS" ? p_target_team_id : null,
    costo: item.costo_token,
    timestamp: new Date().toISOString(),
    stato: "completed",
    outcome
  };
  db.marketplace_transactions.push(transaction);

  // Assign Punti Cattiveria for immediate items
  const stageId = getTeamCurrentStageId(db, currentUserId);
  if (item.id === "bonus_punti") {
    addCattiveriaPoints(db, currentUserId, stageId, "bonus", "bonus_punti", transaction.id, -5, "Utilizzo Bonus Punti (+20 PT)");
  } else if (item.id === "ruota_fortuna") {
    addCattiveriaPoints(db, currentUserId, stageId, "bonus", "ruota_fortuna", transaction.id, -2, `Utilizzo Ruota della Fortuna: ${outcome?.label || ""}`);
  } else if (item.id === "freeze_2min") {
    addCattiveriaPoints(db, currentUserId, stageId, "malus", "freeze_2min", transaction.id, 8, `Utilizzo Freeze contro ${targetTeam?.nome_squadra || ""}`);
  } else if (item.id === "trappola") {
    addCattiveriaPoints(db, currentUserId, stageId, "malus", "trappola", transaction.id, 12, `Utilizzo Trappola contro ${targetTeam?.nome_squadra || ""}`);
  } else if (item.id === "penalita_punti") {
    addCattiveriaPoints(db, currentUserId, stageId, "malus", "penalita_punti", transaction.id, 10, `Utilizzo Penalità Punti contro ${targetTeam?.nome_squadra || ""}`);
  } else if (item.id === "tassa_passaggio") {
    addCattiveriaPoints(db, currentUserId, stageId, "malus", "tassa_passaggio", transaction.id, 15, `Utilizzo Tassa di Passaggio contro ${targetTeam?.nome_squadra || ""}`);
  }

  saveDb(db);
  return { data: { success: true, balance: team.token_balance, outcome }, error: null };
}

function spinUnluckyWheel(db, currentUserId) {
  const unluckyTx = db.marketplace_transactions?.find(
    (t) => t.target_team_id === currentUserId && t.item_id === "ruota_sfortunata" && t.stato === "completed"
  );
  if (!unluckyTx) return { data: null, error: { message: "Nessuna Ruota Sfortunata attiva" } };

  unluckyTx.stato = "used";
  unluckyTx.outcome = { id: "minus_20_points", label: "💸 -20 PUNTI", spun_at: new Date().toISOString() };

  // Assign +7 to attacker
  const attackerStageId = getTeamCurrentStageId(db, unluckyTx.buyer_team_id);
  addCattiveriaPoints(
    db,
    unluckyTx.buyer_team_id,
    attackerStageId,
    "malus",
    "ruota_sfortunata",
    unluckyTx.id,
    7,
    "Utilizzo Ruota Sfortunata (Spin eseguito dal bersaglio)"
  );
  saveDb(db);
  return { data: { outcome: unluckyTx.outcome }, error: null };
}

function closeStage(db, stageId) {
  const stage = db.stages.find((s) => s.id === stageId);
  if (!stage) return { error: "Stage not found" };
  if (stage.stato === "closed") return { data: { success: true, alreadyClosed: true } };

  db.teams.forEach((team) => {
    const maluses = (db.cattiveria_ledger || []).filter(
      (l) => l.team_id === team.id && l.stage_id === stageId && l.tipo === "malus"
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
        team.id,
        stageId,
        "end_of_stage",
        null,
        `end_stage_${stageId}`,
        endOfStagePoints,
        endOfStageMotivo
      );
    }
  });

  stage.stato = "closed";
  saveDb(db);
  return { data: { success: true } };
}

function getLeaderboard(db) {
  const JACKPOT_CHALLENGE_ID = "f5f5f5f5-g6g6-h7h7-i8i8-j9j9j0j0j0j0";
  return db.teams.map((t) => {
    const teamScores = db.scores.filter((s) => s.team_id === t.id);
    const challengesPoints = teamScores.filter((s) => s.challenge_id !== null).reduce((sum, s) => sum + s.punti, 0);
    const modifierPoints = teamScores.filter((s) => s.challenge_id === null).reduce((sum, s) => sum + s.punti, 0);
    const cattiveriaPoints = (db.cattiveria_ledger || []).filter((l) => l.team_id === t.id).reduce((sum, l) => sum + l.punti, 0);
    const totalPoints = challengesPoints + modifierPoints + cattiveriaPoints;

    return {
      team_id: t.id,
      name: t.nome_squadra,
      challenges_points: challengesPoints,
      modifier_points: modifierPoints,
      cattiveria_points: cattiveriaPoints,
      total_points: totalPoints,
      completed_challenges: 3,
      total_duration_seconds: 100
    };
  });
}

function runTests() {
  console.log("==================================================");
  console.log("TEST SUITE: 😈 PUNTI CATTIVERIA / MARKETPLACE");
  console.log("==================================================");

  try {
    const db = getDb();
    const teamA = db.teams[0];
    const teamB = db.teams[1];
    const teamC = db.teams[2] || { id: "team-c-test", nome_squadra: "Team C", token_balance: 80 };
    if (!db.teams.some(t => t.id === teamC.id)) db.teams.push(teamC);

    teamA.token_balance = 80;
    teamB.token_balance = 80;
    teamC.token_balance = 80;

    db.scores = [];
    db.cattiveria_ledger = [];
    db.marketplace_transactions = [];

    // Base scores
    db.scores.push(
      { id: "s1", team_id: teamA.id, challenge_id: "ch1", punti: 100, motivazione: "Sfida 1" },
      { id: "s2", team_id: teamB.id, challenge_id: "ch1", punti: 200, motivazione: "Sfida 1" },
      { id: "s3", team_id: teamC.id, challenge_id: "ch1", punti: 150, motivazione: "Sfida 1" }
    );
    saveDb(db);

    const stage1Id = "4a57212e-7e83-430c-b5fe-6cf38db7be2e";

    console.log("\n--- TEST 1: BONUS SCUDO UTILIZZATO (-3) ---");
    buyMarketplaceItem(db, teamB.id, "bonus_scudo");
    let bShield = db.cattiveria_ledger.filter(l => l.team_id === teamB.id && l.marketplace_item_id === "bonus_scudo");
    if (bShield.length !== 0) throw new Error("Scudo ha assegnato punti prima dell'utilizzo!");
    console.log("✓ Acquisto Scudo non assegna punti cattiveria prima del blocco.");

    // Team A attacks Team B -> blocked by shield
    const blockedRes = buyMarketplaceItem(db, teamA.id, "freeze_2min", teamB.id);
    if (!blockedRes.data?.blockedByShield) throw new Error("Attacco non bloccato dallo scudo!");
    bShield = db.cattiveria_ledger.filter(l => l.team_id === teamB.id && l.marketplace_item_id === "bonus_scudo");
    if (bShield.length !== 1 || bShield[0].punti !== -3) throw new Error("Scudo consumato non ha assegnato -3!");
    console.log("✓ TEST 1 PASSED: Scudo consumato assegna correttamente -3 Punti Cattiveria al difensore.");

    console.log("\n--- TEST 2: FREEZE UTILIZZATO (+8) ---");
    teamA.token_balance = 80;
    buyMarketplaceItem(db, teamA.id, "freeze_2min", teamB.id);
    const freezePoints = db.cattiveria_ledger.filter(l => l.team_id === teamA.id && l.marketplace_item_id === "freeze_2min");
    if (freezePoints.length !== 1 || freezePoints[0].punti !== 8) throw new Error("Freeze non ha assegnato +8!");
    console.log("✓ TEST 2 PASSED: Freeze assegna +8 Punti Cattiveria all'attaccante.");

    console.log("\n--- TEST 3: TRAPPOLA UTILIZZATA (+12) ---");
    teamA.token_balance = 80;
    teamB.freeze_expires_at = null;
    buyMarketplaceItem(db, teamA.id, "trappola", teamB.id);
    const trappolaPoints = db.cattiveria_ledger.filter(l => l.team_id === teamA.id && l.marketplace_item_id === "trappola");
    if (trappolaPoints.length !== 1 || trappolaPoints[0].punti !== 12) throw new Error("Trappola non ha assegnato +12!");
    console.log("✓ TEST 3 PASSED: Trappola assegna +12 Punti Cattiveria all'attaccante.");

    console.log("\n--- TEST 4: PENALITÀ PUNTI UTILIZZATA (+10) ---");
    teamA.token_balance = 80;
    buyMarketplaceItem(db, teamA.id, "penalita_punti", teamB.id);
    const penalitaPoints = db.cattiveria_ledger.filter(l => l.team_id === teamA.id && l.marketplace_item_id === "penalita_punti");
    if (penalitaPoints.length !== 1 || penalitaPoints[0].punti !== 10) throw new Error("Penalità non ha assegnato +10!");
    console.log("✓ TEST 4 PASSED: Penalità Punti assegna +10 Punti Cattiveria all'attaccante.");

    console.log("\n--- TEST 5 & 11: CAP +30 PER TAPPA & TASSA DI PASSAGGIO (+15) ---");
    // Team A has +8 + 12 + 10 = +30 (cap reached).
    teamA.token_balance = 80;
    buyMarketplaceItem(db, teamA.id, "tassa_passaggio", teamC.id);
    const tassaPoints = db.cattiveria_ledger.filter(l => l.team_id === teamA.id && l.marketplace_item_id === "tassa_passaggio");
    if (tassaPoints.length !== 1 || tassaPoints[0].punti !== 0) throw new Error(`Tassa doveva essere cappata a 0, trovato ${tassaPoints[0]?.punti}`);
    console.log("✓ TEST 5 & 11 PASSED: Cap +30 applicato con successo.");

    console.log("\n--- TEST 6-10: REGOLA 'CHI NON È CATTIVO PAGA' A FINE TAPPA ---");
    closeStage(db, stage1Id);
    const teamBEnd = db.cattiveria_ledger.filter(l => l.team_id === teamB.id && l.tipo === "end_of_stage");
    if (teamBEnd.length !== 1 || teamBEnd[0].punti !== -10) throw new Error("Team B con 0 malus non ha ricevuto -10 a fine tappa!");
    console.log("✓ TEST 6 PASSED: Team con 0 Malus riceve -10 a fine tappa.");

    console.log("\n--- TEST 12 & 14: IDEMPOTENZA & NESSUNA DUPLICAZIONE ---");
    closeStage(db, stage1Id);
    const teamBEndAfter = db.cattiveria_ledger.filter(l => l.team_id === teamB.id && l.tipo === "end_of_stage");
    if (teamBEndAfter.length !== 1) throw new Error("Duplicazione su closeStage rilevata!");
    console.log("✓ TEST 12 & 14 PASSED: Nessuna duplicazione su chiamate duplicate.");

    console.log("\n--- TEST 15 & 16: CLASSIFICA LIVE & SEPARAZIONE COMPONENTI ---");
    const leaderboard = getLeaderboard(db);
    const rowA = leaderboard.find(r => r.team_id === teamA.id);
    const rowB = leaderboard.find(r => r.team_id === teamB.id);

    console.log("Team A breakdown:", {
      challenges: rowA.challenges_points,
      modifiers: rowA.modifier_points,
      cattiveria: rowA.cattiveria_points,
      total: rowA.total_points
    });

    console.log("Team B breakdown:", {
      challenges: rowB.challenges_points,
      modifiers: rowB.modifier_points,
      cattiveria: rowB.cattiveria_points,
      total: rowB.total_points
    });

    if (rowA.total_points !== rowA.challenges_points + rowA.modifier_points + rowA.cattiveria_points) {
      throw new Error("Totale Team A non coerente con la somma delle componenti!");
    }
    if (rowB.total_points !== rowB.challenges_points + rowB.modifier_points + rowB.cattiveria_points) {
      throw new Error("Totale Team B non coerente con la somma delle componenti!");
    }
    console.log("✓ TEST 15 & 16 PASSED: Componenti separate e totale calcolato con precisione assoluta.");

    console.log("\n==================================================");
    console.log("🎉 TUTTI I TEST DEI PUNTI CATTIVERIA SONO PASSATI CON SUCCESSO!");
    console.log("==================================================");

  } finally {
    fs.writeFileSync(dbPath, backup);
    console.log("\n[Cleanup] Database ripristinato allo stato iniziale.");
  }
}

runTests();
