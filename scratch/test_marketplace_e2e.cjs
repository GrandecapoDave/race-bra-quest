const { execSync } = require("child_process");

const PSQL_CONN = "postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres";

function runSql(sql) {
  const cmd = `psql '${PSQL_CONN}' -t -A -c "${sql.replace(/"/g, '\\"')}"`;
  return execSync(cmd, { encoding: "utf8" }).trim();
}

async function runTests() {
  console.log("==================================================");
  console.log("STARTING REAL END-TO-END AUTOMATED TEST SUITE");
  console.log("==================================================");

  // Setup test teams
  const userA = "aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa";
  const userB = "bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb";
  const teamA = "1111aaaa-1111-1111-1111-1111aaaaaaaa";
  const teamB = "2222bbbb-2222-2222-2222-2222bbbbbbbb";

  // Clean any old test data
  runSql(`
    DELETE FROM public.scores WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.cattiveria_ledger WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.marketplace_transactions WHERE team_id IN ('${teamA}', '${teamB}') OR target_team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.team_progress WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.user_roles WHERE user_id IN ('${userA}', '${userB}');
    DELETE FROM public.teams WHERE id IN ('${teamA}', '${teamB}');
  `);

  // Insert test teams
  runSql(`
    INSERT INTO public.teams (id, nome_squadra, colore, token_balance, active, owner_id)
    VALUES 
      ('${teamA}', 'TEST SQUADRA ALFA', '#ff0000', 300, true, '${userA}'),
      ('${teamB}', 'TEST SQUADRA BETA', '#0000ff', 300, true, '${userB}');
    INSERT INTO public.user_roles (user_id, team_id, role)
    VALUES 
      ('${userA}', '${teamA}', 'team'),
      ('${userB}', '${teamB}', 'team');
  `);

  const challengeId = runSql(`SELECT id FROM public.challenges WHERE tipo_sfida = 'codice' LIMIT 1;`);
  runSql(`UPDATE public.challenges SET punteggio_massimo = 20 WHERE id = '${challengeId}';`);

  console.log(`Using challengeId: ${challengeId}`);

  // ----------------------------------------------------
  // TEST 1: Team A buys Moltiplicatore 2X & completes challenge (20 PT)
  // ----------------------------------------------------
  console.log("\n--- TEST 1: Moltiplicatore 2X ---");
  const buy2xRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.buy_marketplace_item('moltiplicatore_2x');
  `));
  console.log("Buy 2X result:", buy2xRes);
  if (!buy2xRes.success) throw new Error("TEST 1 FAILED: Buy 2X failed");

  const completeRes1 = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.complete_challenge('${challengeId}');
  `));
  console.log("Complete challenge result:", completeRes1);
  if (completeRes1.points !== 40) throw new Error(`TEST 1 FAILED: Expected 40 points, got ${completeRes1.points}`);
  if (completeRes1.multiplier_2x_bonus !== 20) throw new Error("TEST 1 FAILED: Expected +20 multiplier bonus");

  const tx2xStatus = runSql(`SELECT stato FROM public.marketplace_transactions WHERE team_id = '${teamA}' AND marketplace_item_id = 'moltiplicatore_2x';`);
  console.log("2X transaction status:", tx2xStatus);
  if (tx2xStatus !== "used") throw new Error("TEST 1 FAILED: 2X status should be used");

  // Attempt 2nd purchase (Monouso)
  const second2xRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.buy_marketplace_item('moltiplicatore_2x');
  `));
  console.log("Second buy 2X (monouso check):", second2xRes);
  if (second2xRes.success) throw new Error("TEST 1 FAILED: Monouso failed, second purchase allowed!");
  console.log("✅ TEST 1 PASSED!");

  // ----------------------------------------------------
  // TEST 2: Team A uses Dimezza Punti on Team B -> Team B completes 20 PT challenge
  // ----------------------------------------------------
  console.log("\n--- TEST 2: Dimezza Punti & Cattiveria ---");
  const buyDimezzaRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.buy_marketplace_item('dimezza_punti', '${teamB}');
  `));
  console.log("Buy Dimezza result:", buyDimezzaRes);
  if (!buyDimezzaRes.success) throw new Error("TEST 2 FAILED: Buy Dimezza failed");

  const cattiveriaA = parseInt(runSql(`SELECT COALESCE(SUM(punti), 0) FROM public.cattiveria_ledger WHERE team_id = '${teamA}' AND marketplace_item_id = 'dimezza_punti';`), 10);
  console.log("Cattiveria for Team A:", cattiveriaA);
  if (cattiveriaA !== 10) throw new Error(`TEST 2 FAILED: Expected +10 Cattiveria, got ${cattiveriaA}`);

  const completeResB = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.complete_challenge('${challengeId}');
  `));
  console.log("Team B complete challenge result:", completeResB);
  if (completeResB.points !== 10) throw new Error(`TEST 2 FAILED: Expected 10 points (halved), got ${completeResB.points}`);
  if (completeResB.dimezza_penalty !== 10) throw new Error("TEST 2 FAILED: Expected 10 penalty");

  const dimezzaTxStatus = runSql(`SELECT stato FROM public.marketplace_transactions WHERE target_team_id = '${teamB}' AND marketplace_item_id = 'dimezza_punti';`);
  console.log("Dimezza transaction status:", dimezzaTxStatus);
  if (dimezzaTxStatus !== "used") throw new Error("TEST 2 FAILED: Dimezza status should be used");
  console.log("✅ TEST 2 PASSED!");

  // ----------------------------------------------------
  // TEST 3: Universal Shield vs Dimezza Punti
  // ----------------------------------------------------
  console.log("\n--- TEST 3: Universal Shield against Malus ---");
  runSql(`
    DELETE FROM public.team_progress WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.marketplace_transactions WHERE team_id IN ('${teamA}', '${teamB}') OR target_team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.cattiveria_ledger WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.scores WHERE team_id IN ('${teamA}', '${teamB}');
  `);

  // Team B buys shield
  const buyShieldRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.buy_marketplace_item('bonus_scudo');
  `));
  console.log("Team B buys shield:", buyShieldRes);
  if (!buyShieldRes.success) throw new Error("TEST 3 FAILED: Team B shield purchase failed");

  // Team A launches Dimezza Punti against Team B
  const attackShieldRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.buy_marketplace_item('dimezza_punti', '${teamB}');
  `));
  console.log("Team A attacks shielded Team B:", attackShieldRes);
  if (!attackShieldRes.shielded) throw new Error("TEST 3 FAILED: Expected shielded=true");

  const shieldStatus = runSql(`SELECT stato FROM public.marketplace_transactions WHERE team_id = '${teamB}' AND marketplace_item_id = 'bonus_scudo';`);
  const attackStatus = runSql(`SELECT stato FROM public.marketplace_transactions WHERE team_id = '${teamA}' AND marketplace_item_id = 'dimezza_punti';`);
  console.log("Shield status:", shieldStatus, "Attack status:", attackStatus);
  if (shieldStatus !== "used" || attackStatus !== "expired") throw new Error("TEST 3 FAILED: Expected shield=used, attack=expired");

  const cattCountA = parseInt(runSql(`SELECT COUNT(*) FROM public.cattiveria_ledger WHERE team_id = '${teamA}';`), 10);
  if (cattCountA !== 0) throw new Error("TEST 3 FAILED: Attacker received Cattiveria despite shield parry!");

  const completeResBFull = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.complete_challenge('${challengeId}');
  `));
  console.log("Team B complete challenge after shield parry:", completeResBFull);
  if (completeResBFull.points !== 20) throw new Error(`TEST 3 FAILED: Expected 20 points, got ${completeResBFull.points}`);
  console.log("✅ TEST 3 PASSED!");

  // ----------------------------------------------------
  // TEST 4: Blackout Mercato
  // ----------------------------------------------------
  console.log("\n--- TEST 4: Blackout Mercato ---");
  runSql(`
    DELETE FROM public.marketplace_transactions WHERE team_id IN ('${teamA}', '${teamB}') OR target_team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.cattiveria_ledger WHERE team_id IN ('${teamA}', '${teamB}');
  `);

  const buyBlackoutRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.buy_marketplace_item('blackout_mercato', '${teamB}');
  `));
  console.log("Team A buys blackout against Team B:", buyBlackoutRes);
  if (!buyBlackoutRes.success) throw new Error("TEST 4 FAILED: Blackout purchase failed");

  const cattBlackout = parseInt(runSql(`SELECT COALESCE(SUM(punti), 0) FROM public.cattiveria_ledger WHERE team_id = '${teamA}' AND marketplace_item_id = 'blackout_mercato';`), 10);
  if (cattBlackout !== 10) throw new Error(`TEST 4 FAILED: Expected +10 Cattiveria, got ${cattBlackout}`);

  // Team B tries to buy an item while under blackout
  const blockedBuyRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.buy_marketplace_item('bonus_punti');
  `));
  console.log("Team B purchase attempt under blackout:", blockedBuyRes);
  if (blockedBuyRes.success) throw new Error("TEST 4 FAILED: Purchase should have been blocked by Blackout!");
  console.log("✅ TEST 4 PASSED!");

  // ----------------------------------------------------
  // TEST 5: Shield blocks Blackout Mercato
  // ----------------------------------------------------
  console.log("\n--- TEST 5: Shield vs Blackout Mercato ---");
  runSql(`
    DELETE FROM public.marketplace_transactions WHERE team_id IN ('${teamA}', '${teamB}') OR target_team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.cattiveria_ledger WHERE team_id IN ('${teamA}', '${teamB}');
  `);

  // Team B buys Shield
  runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.buy_marketplace_item('bonus_scudo');
  `);

  // Team A launches Blackout Mercato
  const shieldBlackoutRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.buy_marketplace_item('blackout_mercato', '${teamB}');
  `));
  console.log("Shield vs Blackout result:", shieldBlackoutRes);
  if (!shieldBlackoutRes.shielded) throw new Error("TEST 5 FAILED: Expected shielded=true");

  // Team B can still purchase
  const allowedBuyRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.buy_marketplace_item('bonus_punti');
  `));
  console.log("Team B buy bonus_punti after parried blackout:", allowedBuyRes);
  if (!allowedBuyRes.success) throw new Error("TEST 5 FAILED: Team B should be allowed to purchase");
  console.log("✅ TEST 5 PASSED!");

  // ----------------------------------------------------
  // TEST 6: Monouso across all items
  // ----------------------------------------------------
  console.log("\n--- TEST 6: Monouso Strict Enforcement ---");
  const doubleBonusPuntiRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.buy_marketplace_item('bonus_punti');
  `));
  console.log("Double buy bonus_punti:", doubleBonusPuntiRes);
  if (doubleBonusPuntiRes.success) throw new Error("TEST 6 FAILED: Double purchase of bonus_punti allowed!");
  console.log("✅ TEST 6 PASSED!");

  // ----------------------------------------------------
  // TEST 7: Polizza 50% Refund on Malus
  // ----------------------------------------------------
  console.log("\n--- TEST 7: Polizza 50% Refund ---");
  runSql(`
    DELETE FROM public.marketplace_transactions WHERE team_id IN ('${teamA}', '${teamB}') OR target_team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.scores WHERE team_id IN ('${teamA}', '${teamB}');
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo) VALUES ('${teamB}', 50, 'initial', 'Test baseline');
  `);

  // Team B buys Polizza Diretta
  const buyPolizzaRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userB}';
    SELECT public.buy_marketplace_item('polizza_diretta');
  `));
  console.log("Buy Polizza result:", buyPolizzaRes);
  if (!buyPolizzaRes.success) throw new Error("TEST 7 FAILED: Buy Polizza failed");

  // Team A launches Penalita Punti (-20 PT)
  const penalitaRes = JSON.parse(runSql(`
    SET request.jwt.claim.sub = '${userA}';
    SELECT public.buy_marketplace_item('penalita_punti', '${teamB}');
  `));
  console.log("Penalita result with active Polizza:", penalitaRes);

  const finalScoreB = parseInt(runSql(`SELECT SUM(punti) FROM public.scores WHERE team_id = '${teamB}';`), 10);
  console.log("Team B score after -20 PT and +10 PT polizza refund:", finalScoreB);
  if (finalScoreB !== 40) throw new Error(`TEST 7 FAILED: Expected 40 net points, got ${finalScoreB}`);

  const polizzaStatus = runSql(`SELECT stato FROM public.marketplace_transactions WHERE team_id = '${teamB}' AND marketplace_item_id = 'polizza_diretta';`);
  console.log("Polizza transaction status:", polizzaStatus);
  if (polizzaStatus !== "used") throw new Error("TEST 7 FAILED: Polizza should be marked used");
  console.log("✅ TEST 7 PASSED!");

  // Final Cleanup
  runSql(`
    DELETE FROM public.user_roles WHERE user_id IN ('${userA}', '${userB}');
    DELETE FROM public.scores WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.cattiveria_ledger WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.marketplace_transactions WHERE team_id IN ('${teamA}', '${teamB}') OR target_team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.team_progress WHERE team_id IN ('${teamA}', '${teamB}');
    DELETE FROM public.teams WHERE id IN ('${teamA}', '${teamB}');
  `);

  console.log("\n==================================================");
  console.log("🎉 ALL 7 TEST SCENARIOS PASSED 100% SUCCESSFULLY!");
  console.log("==================================================");
}

runTests().catch(err => {
  console.error("❌ TEST FAILED:", err);
  process.exit(1);
});
