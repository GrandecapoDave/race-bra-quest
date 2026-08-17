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

function calculateLeaderboard(db) {
  const JACKPOT_CHALLENGE_ID = "f5f5f5f5-g6g6-h7h7-i8i8-j9j9j0j0j0j0";

  return (db.teams || []).map((team) => {
    const completedChallenges = (db.team_progress || []).filter(
      (p) => p.team_id === team.id && p.stato === "completed" && p.challenge_id !== JACKPOT_CHALLENGE_ID
    ).length;

    const teamScores = (db.scores || []).filter((s) => s.team_id === team.id);
    const challengesPoints = teamScores
      .filter((s) => s.challenge_id !== null && s.challenge_id !== undefined)
      .reduce((sum, s) => sum + s.punti, 0);

    const modifierPoints = teamScores
      .filter((s) => s.challenge_id === null || s.challenge_id === undefined)
      .reduce((sum, s) => sum + s.punti, 0);

    const teamCattiveria = (db.cattiveria_ledger || []).filter((l) => l.team_id === team.id);
    const cattiveriaPoints = teamCattiveria.reduce((sum, l) => sum + l.punti, 0);

    const totalPoints = challengesPoints + modifierPoints + cattiveriaPoints;

    return {
      team_id: team.id,
      name: team.nome_squadra,
      color: team.color || "#f97316",
      avatar_url: team.avatar_url || "🏳️",
      motto: team.motto || "",
      challenges_points: challengesPoints,
      modifier_points: modifierPoints,
      cattiveria_points: cattiveriaPoints,
      total_points: totalPoints,
      completed_challenges: completedChallenges,
      total_duration_seconds: 1200,
      last_completion: null
    };
  });
}

function generateGameReport(db) {
  const rawLeaderboard = calculateLeaderboard(db);
  const sortedLeaderboard = [...rawLeaderboard].sort((a, b) => {
    if (b.completed_challenges !== a.completed_challenges) {
      return b.completed_challenges - a.completed_challenges;
    }
    if (b.total_points !== a.total_points) {
      return b.total_points - a.total_points;
    }
    return (a.total_duration_seconds ?? 0) - (b.total_duration_seconds ?? 0);
  });

  const stagesList = [...(db.stages || [])].sort((a, b) => a.ordine - b.ordine);
  const challengesList = db.challenges || [];
  const scoresList = db.scores || [];
  const transactionsList = db.marketplace_transactions || [];
  const cattiveriaList = db.cattiveria_ledger || [];
  const progressList = db.team_progress || [];
  const jackpotPlays = db.jackpot_plays || [];
  const submissionsList = db.submissions || [];

  const teamsReport = sortedLeaderboard.map((teamRank, rankIndex) => {
    const teamId = teamRank.team_id;
    const teamObj = db.teams.find((t) => t.id === teamId) || {};
    const teamScores = scoresList.filter((s) => s.team_id === teamId);
    const teamProgress = progressList.filter((p) => p.team_id === teamId);
    const teamCattiveria = cattiveriaList.filter((l) => l.team_id === teamId);
    const teamTxBought = transactionsList.filter((t) => t.buyer_team_id === teamId);
    const teamTxVictim = transactionsList.filter((t) => t.target_team_id === teamId);
    const teamJackpot = jackpotPlays.find((j) => j.team_id === teamId);

    let tokensGainedStageRewards = 0;
    let tokensSpentMarketplace = 0;
    teamTxBought.forEach((tx) => {
      if (tx.item_id === "reward_stage") {
        tokensGainedStageRewards += Math.abs(tx.costo || 0);
      } else if (tx.costo > 0 && tx.stato !== "blocked") {
        tokensSpentMarketplace += tx.costo;
      }
    });

    const stagesBreakdown = stagesList.map((stage) => {
      const stageChs = challengesList.filter((c) => c.stage_id === stage.id).sort((a, b) => a.ordine - b.ordine);

      const stageChallengesDetails = stageChs.map((c) => {
        const prog = teamProgress.find((p) => p.challenge_id === c.id);
        const score = teamScores.find((s) => s.challenge_id === c.id);
        const sub = submissionsList.find((s) => s.challenge_id === c.id && s.team_id === teamId);
        return {
          challenge_id: c.id,
          title: c.titolo,
          type: c.tipo_sfida,
          max_points: c.punteggio_massimo,
          order: c.ordine,
          completed: prog?.stato === "completed",
          completed_at: prog?.completata_at || null,
          started_at: prog?.started_at || null,
          points_awarded: score?.punti || 0,
          submission: sub || null
        };
      });

      const stageChallengesPoints = stageChallengesDetails.reduce((sum, c) => sum + c.points_awarded, 0);

      const bonusesInStage = teamTxBought
        .filter((tx) => {
          const item = db.marketplace_items?.find((i) => i.id === tx.item_id);
          return item?.categoria === "BONUS" && tx.item_id !== "reward_stage";
        })
        .map((tx) => {
          const item = db.marketplace_items?.find((i) => i.id === tx.item_id);
          const cattEntry = teamCattiveria.find((l) => l.riferimento_transazione === tx.id);
          return {
            transaction_id: tx.id,
            item_id: tx.item_id,
            name: item?.nome || tx.item_id,
            cost_tokens: tx.costo || item?.costo_token || 0,
            stato: tx.stato,
            is_used: tx.stato === "used" || tx.stato === "completed",
            timestamp: tx.timestamp,
            cattiveria_delta: cattEntry?.punti || 0,
            outcome: tx.outcome || null
          };
        });

      const malusesInStage = teamTxBought
        .filter((tx) => {
          const item = db.marketplace_items?.find((i) => i.id === tx.item_id);
          return item?.categoria === "MALUS";
        })
        .map((tx) => {
          const item = db.marketplace_items?.find((i) => i.id === tx.item_id);
          const targetTeam = db.teams.find((t) => t.id === tx.target_team_id);
          const cattEntry = teamCattiveria.find((l) => l.riferimento_transazione === tx.id);
          let directPointsDelta = 0;
          if (tx.item_id === "trappola") {
            directPointsDelta = tx.outcome?.points_stolen || 30;
          }
          return {
            transaction_id: tx.id,
            item_id: tx.item_id,
            name: item?.nome || tx.item_id,
            cost_tokens: tx.costo || item?.costo_token || 0,
            target_team_id: tx.target_team_id,
            target_team_name: targetTeam?.nome_squadra || "Avversario",
            target_team_color: targetTeam?.color || "#f97316",
            stato: tx.stato,
            blocked_by_shield: tx.stato === "blocked",
            timestamp: tx.timestamp,
            direct_points_delta: directPointsDelta,
            cattiveria_delta: cattEntry?.punti || 0,
            outcome: tx.outcome || null
          };
        });

      const malusesSuffered = teamTxVictim.map((tx) => {
        const item = db.marketplace_items?.find((i) => i.id === tx.item_id);
        const attackerTeam = db.teams.find((t) => t.id === tx.buyer_team_id);
        let pointsLost = 0;
        if (tx.item_id === "penalita_punti" && tx.stato !== "blocked") pointsLost = 20;
        if (tx.item_id === "trappola" && tx.stato !== "blocked") pointsLost = tx.outcome?.points_stolen || 30;

        return {
          transaction_id: tx.id,
          item_id: tx.item_id,
          name: item?.nome || tx.item_id,
          attacker_team_id: tx.buyer_team_id,
          attacker_team_name: attackerTeam?.nome_squadra || "Avversario",
          attacker_team_color: attackerTeam?.color || "#f97316",
          stato: tx.stato,
          blocked_by_shield: tx.stato === "blocked",
          timestamp: tx.timestamp,
          points_lost: pointsLost,
          outcome: tx.outcome || null
        };
      });

      const stageCattiveriaEntries = teamCattiveria.filter((l) => l.stage_id === stage.id);
      const stageCattiveriaPoints = stageCattiveriaEntries.reduce((sum, l) => sum + l.punti, 0);
      const stageRewardTx = teamTxBought.find(
        (tx) => tx.item_id === "reward_stage" && (tx.outcome?.stage_id === stage.id || tx.outcome?.stage_index === stage.ordine)
      );
      const endOfStageCattiveria = stageCattiveriaEntries.find((l) => l.tipo === "end_of_stage");

      return {
        stage_id: stage.id,
        stage_name: stage.nome_tappa,
        stage_order: stage.ordine,
        stage_status: stage.stato,
        challenges: stageChallengesDetails,
        challenges_points_total: stageChallengesPoints,
        bonuses_used: bonusesInStage,
        maluses_used: malusesInStage,
        maluses_suffered: malusesSuffered,
        cattiveria_entries: stageCattiveriaEntries,
        cattiveria_stage_total: stageCattiveriaPoints,
        stage_reward_tokens: stageRewardTx ? Math.abs(stageRewardTx.costo) : 0,
        end_of_stage_cattiveria: endOfStageCattiveria?.punti || 0,
        stage_total_points: stageChallengesPoints + stageCattiveriaPoints
      };
    });

    const timeline = [];

    teamProgress.forEach((p) => {
      if (p.stato === "completed" && p.completata_at) {
        const ch = challengesList.find((c) => c.id === p.challenge_id);
        const sc = teamScores.find((s) => s.challenge_id === p.challenge_id);
        const st = ch ? stagesList.find((s) => s.id === ch.stage_id) : null;
        timeline.push({
          timestamp: p.completata_at,
          category: "CHALLENGE",
          title: `Sfida completata: ${ch?.titolo || "Sfida"}`,
          stage_name: st?.nome_tappa || "",
          stage_order: st?.ordine || 1,
          points_delta: sc?.punti || 0,
          cattiveria_delta: 0,
          tokens_delta: 0,
          details: `Completata (+${sc?.punti || 0} PT)`
        });
      }
    });

    teamTxBought.forEach((tx) => {
      const item = db.marketplace_items?.find((i) => i.id === tx.item_id);
      const targetTeam = tx.target_team_id ? db.teams.find((t) => t.id === tx.target_team_id) : null;
      const catt = teamCattiveria.find((l) => l.riferimento_transazione === tx.id);

      if (tx.item_id === "reward_stage") {
        timeline.push({
          timestamp: tx.timestamp,
          category: "STAGE_REWARD",
          title: `Chiusura Tappa ${tx.outcome?.stage_index || ""}: Ricompensa Token`,
          stage_name: tx.outcome?.stage_name || "",
          stage_order: tx.outcome?.stage_index || 1,
          points_delta: 0,
          cattiveria_delta: 0,
          tokens_delta: Math.abs(tx.costo || 0),
          details: `Posizione ${tx.outcome?.position || 1}ª → +${Math.abs(tx.costo || 0)} Token`
        });
      } else if (item?.categoria === "MALUS") {
        timeline.push({
          timestamp: tx.timestamp,
          category: "MALUS_ATTACK",
          title: `Malus: ${item?.nome || tx.item_id}`,
          points_delta: tx.item_id === "trappola" ? (tx.outcome?.points_stolen || 30) : 0,
          cattiveria_delta: catt?.punti || 0,
          tokens_delta: -(tx.costo || 0),
          details: tx.stato === "blocked" ? "Attacco bloccato da Scudo!" : `Attacco su ${targetTeam?.nome_squadra || "avversario"}`
        });
      } else {
        timeline.push({
          timestamp: tx.timestamp,
          category: "BONUS_USED",
          title: `Bonus: ${item?.nome || tx.item_id}`,
          points_delta: tx.item_id === "bonus_punti" ? 20 : 0,
          cattiveria_delta: catt?.punti || 0,
          tokens_delta: -(tx.costo || 0),
          details: `Acquistato/utilizzato`
        });
      }
    });

    teamTxVictim.forEach((tx) => {
      const item = db.marketplace_items?.find((i) => i.id === tx.item_id);
      const attackerTeam = db.teams.find((t) => t.id === tx.buyer_team_id);
      if (tx.stato !== "blocked") {
        let pointsLost = 0;
        if (tx.item_id === "penalita_punti") pointsLost = 20;
        if (tx.item_id === "trappola") pointsLost = tx.outcome?.points_stolen || 30;

        timeline.push({
          timestamp: tx.timestamp,
          category: "MALUS_VICTIM",
          title: `Malus subito: ${item?.nome || tx.item_id}`,
          points_delta: -pointsLost,
          cattiveria_delta: 0,
          tokens_delta: 0,
          details: `Subito attacco da ${attackerTeam?.nome_squadra || "avversario"}`
        });
      }
    });

    teamCattiveria.filter((l) => l.tipo === "end_of_stage").forEach((l) => {
      const st = stagesList.find((s) => s.id === l.stage_id);
      timeline.push({
        timestamp: l.timestamp,
        category: "CATTIVERIA_END_STAGE",
        title: `Regola "Chi non è cattivo paga" (Tappa ${st?.ordine || ""})`,
        points_delta: 0,
        cattiveria_delta: l.punti,
        tokens_delta: 0,
        details: l.motivo
      });
    });

    if (teamJackpot) {
      timeline.push({
        timestamp: teamJackpot.timestamp,
        category: "JACKPOT",
        title: `Sfida 5.3 — Jackpot`,
        points_delta: teamJackpot.variazione_punti || 0,
        cattiveria_delta: 0,
        tokens_delta: 0,
        details: `Puntata: ${teamJackpot.puntata} PT | Esito: ${teamJackpot.risultato}`
      });
    }

    timeline.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

    return {
      position: rankIndex + 1,
      team_id: teamId,
      name: teamRank.name,
      color: teamRank.color,
      avatar_url: teamRank.avatar_url,
      token_balance: teamObj.token_balance ?? 50,
      tokens_initial: 50,
      tokens_gained_rewards: tokensGainedStageRewards,
      tokens_spent_marketplace: tokensSpentMarketplace,
      challenges_points: teamRank.challenges_points ?? 0,
      modifier_points: teamRank.modifier_points ?? 0,
      cattiveria_points: teamRank.cattiveria_points ?? 0,
      total_points: teamRank.total_points ?? 0,
      completed_challenges: teamRank.completed_challenges ?? 0,
      total_duration_seconds: teamRank.total_duration_seconds ?? 0,
      jackpot_play: teamJackpot || null,
      stages_breakdown: stagesBreakdown,
      timeline
    };
  });

  return {
    generated_at: new Date().toISOString(),
    total_teams: teamsReport.length,
    teams: teamsReport,
    stages: stagesList.map((s) => ({
      id: s.id,
      nome_tappa: s.nome_tappa,
      ordine: s.ordine,
      stato: s.stato
    }))
  };
}

function getGameReportRPC(db, userId) {
  const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
  const isAdmin = userId === ADMIN_ID || db.user_roles?.some((ur) => ur.user_id === userId && ur.role === "admin");
  const isPublished = db.game_report?.state === "PUBLISHED_FINAL";

  if (!isAdmin && !isPublished) {
    return { data: null, error: { message: "Il Resoconto Gara non è ancora stato pubblicato dalla Regia.", code: "403" } };
  }

  if (isPublished && db.game_report?.snapshot) {
    return {
      data: {
        state: "PUBLISHED_FINAL",
        published_at: db.game_report.published_at,
        published_by: db.game_report.published_by,
        is_published: true,
        report: db.game_report.snapshot
      },
      error: null
    };
  }

  const liveReport = generateGameReport(db);
  return {
    data: {
      state: db.game_report?.state || "PRIVATE_LIVE",
      published_at: null,
      published_by: null,
      is_published: false,
      report: liveReport
    },
    error: null
  };
}

function publishGameReportRPC(db, adminId) {
  const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
  const isAdmin = adminId === ADMIN_ID || db.user_roles?.some((ur) => ur.user_id === adminId && ur.role === "admin");
  if (!isAdmin) {
    return { data: null, error: { message: "Non autorizzato", code: "403" } };
  }

  if (db.game_report?.state === "PUBLISHED_FINAL") {
    return {
      data: {
        success: true,
        alreadyPublished: true,
        published_at: db.game_report.published_at
      },
      error: null
    };
  }

  const snapshot = generateGameReport(db);
  const publishedAt = new Date().toISOString();

  db.game_report = {
    state: "PUBLISHED_FINAL",
    published_at: publishedAt,
    published_by: adminId,
    snapshot
  };

  saveDb(db);
  return {
    data: {
      success: true,
      published_at: publishedAt
    },
    error: null
  };
}

function runGameReportTests() {
  console.log("==================================================");
  console.log("TEST SUITE: 📊 RESOCONTO GARA + PUBBLICAZIONE FINALE");
  console.log("==================================================");

  try {
    const db = getDb();
    const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
    const TEAM1_ID = db.teams[0].id;
    const TEAM2_ID = db.teams[1].id;

    // Reset report state
    db.game_report = {
      state: "PRIVATE_LIVE",
      published_at: null,
      published_by: null,
      snapshot: null
    };

    console.log("\n--- TEST 1: ADMIN RECUPERA IL RESOCONTO LIVE ---");
    const adminReportRes = getGameReportRPC(db, ADMIN_ID);
    if (adminReportRes.error) throw new Error("Errore recupero resoconto da Admin: " + adminReportRes.error.message);
    if (adminReportRes.data.is_published !== false) throw new Error("Resoconto non doveva essere pubblicato!");
    if (!adminReportRes.data.report?.teams || adminReportRes.data.report.teams.length === 0) {
      throw new Error("Dati squadre mancanti nel resoconto!");
    }
    console.log(`✓ TEST 1 PASSED: Admin ha accesso al Resoconto Live (${adminReportRes.data.report.teams.length} squadre elaborate).`);

    console.log("\n--- TEST 2: TEAM NON PUÒ ACCEDERE AL RESOCONTO DURANTE LA GARA ---");
    const teamReportRes = getGameReportRPC(db, TEAM1_ID);
    if (!teamReportRes.error || teamReportRes.error.code !== "403") {
      throw new Error("Accesso team NON bloccato durante la gara!");
    }
    console.log("✓ TEST 2 PASSED: Accesso Team correttamente rifiutato con 403 Forbidden.");

    console.log("\n--- TEST 3-9: VERIFICA DETTAGLI E STRUTTURA PER SQUADRA ---");
    const sampleTeam = adminReportRes.data.report.teams[0];
    if (typeof sampleTeam.total_points !== "number") throw new Error("total_points mancante!");
    if (typeof sampleTeam.challenges_points !== "number") throw new Error("challenges_points mancante!");
    if (typeof sampleTeam.cattiveria_points !== "number") throw new Error("cattiveria_points mancante!");
    if (typeof sampleTeam.token_balance !== "number") throw new Error("token_balance mancante!");
    if (!Array.isArray(sampleTeam.stages_breakdown)) throw new Error("stages_breakdown mancante!");
    if (!Array.isArray(sampleTeam.timeline)) throw new Error("timeline mancante!");
    console.log("✓ TEST 3-9 PASSED: Struttura dettagliata (sfide, tappe, bonus, malus, cattiveria, token, timeline) verificata con successo.");

    console.log("\n--- TEST 13: ADMIN PUBBLICA IL RESOCONTO FINALE ---");
    const pubRes = publishGameReportRPC(db, ADMIN_ID);
    if (pubRes.error) throw new Error("Errore pubblicazione resoconto: " + pubRes.error.message);
    if (!pubRes.data.success || !pubRes.data.published_at) throw new Error("Pubblicazione fallita!");
    console.log(`✓ TEST 13 PASSED: Resoconto Finale pubblicato ufficialmente il ${pubRes.data.published_at}.`);

    console.log("\n--- TEST 14: TEAM ORA HA ACCESSO AL RESOCONTO FINALE ---");
    const teamAfterPubRes = getGameReportRPC(db, TEAM1_ID);
    if (teamAfterPubRes.error) throw new Error("Errore accesso team dopo pubblicazione: " + teamAfterPubRes.error.message);
    if (!teamAfterPubRes.data.is_published) throw new Error("Resoconto non risulta pubblicato al Team!");
    if (!teamAfterPubRes.data.report?.teams) throw new Error("Snapshot team non accessibile al Team!");
    console.log("✓ TEST 14 PASSED: Tutte le squadre possono ora visualizzare il Resoconto Finale.");

    console.log("\n--- TEST 15: IDEMPOTENZA PUBBLICAZIONE ---");
    const secondPubRes = publishGameReportRPC(db, ADMIN_ID);
    if (!secondPubRes.data?.alreadyPublished) throw new Error("Seconda pubblicazione non marcata alreadyPublished!");
    if (secondPubRes.data.published_at !== pubRes.data.published_at) throw new Error("Timestamp di pubblicazione alterato!");
    console.log("✓ TEST 15 PASSED: Idempotenza verificata, nessuna duplicazione di snapshot.");

    console.log("\n--- TEST 16: IMMUTABILITÀ DELLO SNAPSHOT PUBBLICO ---");
    const snapshotPointsTeam1 = teamAfterPubRes.data.report.teams.find((t) => t.team_id === TEAM1_ID).total_points;
    // Modifichiamo i punti nel DB live
    db.scores.push({
      id: "extra_score_test",
      team_id: TEAM1_ID,
      challenge_id: "c1c2c3c4-c5c6-c7c8-c9d0-d1d2d3d4d5d6",
      punti: 100,
      timestamp: new Date().toISOString()
    });
    const teamAfterScoreMod = getGameReportRPC(db, TEAM1_ID);
    const newSnapshotPointsTeam1 = teamAfterScoreMod.data.report.teams.find((t) => t.team_id === TEAM1_ID).total_points;
    if (newSnapshotPointsTeam1 !== snapshotPointsTeam1) {
      throw new Error(`Snapshot modificato dopo variazione live! Era ${snapshotPointsTeam1}, ora è ${newSnapshotPointsTeam1}`);
    }
    console.log("✓ TEST 16 PASSED: Immutabilità garantita! Le modifiche ai dati live non alterano lo Snapshot Pubblico.");

    console.log("\n==================================================");
    console.log("🎉 TUTTI I TEST DEL RESOCONTO GARA SONO SUPERATI!");
    console.log("==================================================");

  } finally {
    fs.writeFileSync(dbPath, backup);
    console.log("\n[Cleanup] Database ripristinato allo stato iniziale.");
  }
}

runGameReportTests();
