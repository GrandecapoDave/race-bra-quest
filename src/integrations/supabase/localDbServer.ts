import { createServerFn } from "@tanstack/react-start";
import fs from "fs";
import path from "path";
import defaultDbJson from "../../../local_database.json";

const dbPath = path.resolve(process.cwd(), "local_database.json");
const uploadsDir = path.resolve(process.cwd(), "public", "uploads");

let memoryDb: any = null;

// Initialize Database structure
function getDb() {
  if (memoryDb) {
    return memoryDb;
  }

  let db: any = null;
  const tmpPath = "/tmp/local_database.json";
  if (fs.existsSync(tmpPath)) {
    try {
      const data = JSON.parse(fs.readFileSync(tmpPath, "utf8"));
      if (data && (data.teams?.length > 0 || data.admin?.length > 0)) {
        db = data;
      }
    } catch (e) {
      // Ignore read errors
    }
  }

  if (!db && fs.existsSync(dbPath)) {
    try {
      const data = JSON.parse(fs.readFileSync(dbPath, "utf8"));
      if (data && (data.teams?.length > 0 || data.admin?.length > 0)) {
        db = data;
      }
    } catch (e) {
      // Ignore read errors
    }
  }

  if (!db) {
    db = JSON.parse(JSON.stringify(defaultDbJson));
  }

  let updated = false;

  if (!db.posters) {
    db.posters = [
      { id: "poster_01", file_name: "Poster1.jpg", titolo: "Indiana Jones", active: true },
      { id: "poster_02", file_name: "Poster2.jpg", titolo: "Back to the Future", active: true },
      { id: "poster_03", file_name: "Poster3.jpg", titolo: "Star Wars", active: true },
      { id: "poster_04", file_name: "Poster4.jpg", titolo: "Jurassic Park", active: true },
      { id: "poster_05", file_name: "Poster5.jpg", titolo: "Titanic", active: true },
      { id: "poster_06", file_name: "Poster6.jpg", titolo: "Pulp Fiction", active: true },
      { id: "poster_07", file_name: "Poster7.jpg", titolo: "The Matrix", active: true },
      { id: "poster_08", file_name: "Poster8.jpg", titolo: "Forrest Gump", active: true },
      { id: "poster_09", file_name: "Poster9.jpg", titolo: "E.T.", active: true },
      { id: "poster_10", file_name: "Poster10.jpg", titolo: "The Godfather", active: true },
    ];
    updated = true;
  }
  if (!db.team_posters) {
    db.team_posters = [];
    updated = true;
  }

  if (!db.marketplace_items || db.marketplace_items.length === 0) {
    db.marketplace_items = [
      // BONUS
      {
        id: "bonus_punti",
        nome: "BONUS PUNTI",
        categoria: "BONUS",
        descrizione:
          "Un grande vantaggio per scalare la classifica. Usa questo bonus nel momento decisivo.",
        costo_token: 40,
        active: true,
      },
      {
        id: "bonus_scudo",
        nome: "BONUS SCUDO",
        categoria: "BONUS",
        descrizione:
          "Uno scudo invisibile protegge il vostro viaggio dagli attacchi degli avversari.",
        costo_token: 35,
        active: true,
      },
      {
        id: "ruota_fortuna",
        nome: "RUOTA DELLA FORTUNA",
        categoria: "BONUS",
        descrizione: "La fortuna decide il vostro destino. Siete pronti a rischiare?",
        costo_token: 25,
        active: true,
      },
      {
        id: "passaparola",
        nome: "PASSAPAROLA",
        categoria: "BONUS",
        descrizione:
          "Permette di chiamare l'organizzatore una volta per ricevere un indizio extra SÌ/NO su qualsiasi enigma bloccato.",
        costo_token: 20,
        active: true,
      },
      {
        id: "bonus_classifica",
        nome: "BONUS CLASSIFICA",
        categoria: "BONUS",
        descrizione: "Visualizza temporaneamente la classifica generale.",
        costo_token: 30,
        active: true,
      },
      {
        id: "partenza_anticipata",
        nome: "PARTENZA ANTICIPATA",
        categoria: "BONUS",
        descrizione: "-2 minuti sulla partenza. Comunica alla Regia per utilizzarlo.",
        costo_token: 35,
        active: true,
      },
      // MALUS
      {
        id: "freeze_2min",
        nome: "FREEZE 2 MINUTI",
        categoria: "MALUS",
        descrizione: "Il tempo si ferma per i vostri rivali.",
        costo_token: 20,
        active: true,
      },
      {
        id: "enigma_extra",
        nome: "ENIGMA EXTRA",
        categoria: "MALUS",
        descrizione:
          "La squadra bersaglio deve completare un enigma aggiuntivo prima di continuare.",
        costo_token: 25,
        active: true,
      },
      {
        id: "ruota_sfortunata",
        nome: "RUOTA SFORTUNATA",
        categoria: "MALUS",
        descrizione: "La squadra bersaglio deve girare una ruota con possibili penalità casuali.",
        costo_token: 20,
        active: true,
      },
      {
        id: "trappola",
        nome: "TRAPPOLA",
        categoria: "MALUS",
        descrizione: "Ruba fino a 30 Punti Squadra a una squadra avversaria.",
        costo_token: 40,
        active: true,
      },
      {
        id: "penalita_punti",
        nome: "PENALITÀ PUNTI (-20 PT)",
        categoria: "MALUS",
        descrizione: "−20 PT",
        costo_token: 30,
        active: true,
      },
      {
        id: "tassa_passaggio",
        nome: "TASSA DI PASSAGGIO",
        categoria: "MALUS",
        descrizione:
          "Scambia integralmente i Punti Squadra correnti con quelli di una squadra avversaria.",
        costo_token: 70,
        active: true,
      },
    ];
    updated = true;
  }

  if (db.teams) {
    db.teams.forEach((t: any) => {
      if (t.token_balance === undefined || t.token_balance === null) {
        t.token_balance = 50;
        updated = true;
      }
    });
  }

  if (!db.game_settings || db.game_settings.length === 0) {
    db.game_settings = [
      {
        id: "settings_01",
        marketplace_visible: false,
        marketplace_active: false,
        activated_at: null,
        activated_by: null,
        cornhole_special_bye_team_id: null,
        boxe_special_bye_team_id: null,
      },
    ];
    updated = true;
  } else {
    const settings = db.game_settings[0];
    let settingsUpdated = false;
    if (settings.cornhole_special_bye_team_id === undefined) {
      settings.cornhole_special_bye_team_id = null;
      settingsUpdated = true;
    }
    if (settings.boxe_special_bye_team_id === undefined) {
      settings.boxe_special_bye_team_id = null;
      settingsUpdated = true;
    }
    if (settingsUpdated) updated = true;
  }

  // Migration logic for existing databases
  const stage1 = db.stages.find((s: any) => s.id === "4a57212e-7e83-430c-b5fe-6cf38db7be2e");
  if (
    stage1 &&
    (stage1.descrizione !== "Piazza Caduti per la Libertà, 14" ||
      stage1.latitude !== 44.6982 ||
      stage1.longitude !== 7.8507)
  ) {
    stage1.descrizione = "Piazza Caduti per la Libertà, 14";
    stage1.latitude = 44.6982;
    stage1.longitude = 7.8507;
    updated = true;
  }

  const stage2 = db.stages.find((s: any) => s.id === "dfa9e6db-4e1b-41be-94be-21cf2980fa2a");
  if (
    stage2 &&
    (stage2.nome_tappa !== "Il Rebus Visivo" ||
      stage2.descrizione !== "Via Mendicità Istruita, 12" ||
      stage2.latitude !== 44.6976 ||
      stage2.longitude !== 7.8544)
  ) {
    stage2.nome_tappa = "Il Rebus Visivo";
    stage2.descrizione = "Via Mendicità Istruita, 12";
    stage2.ordine = 2;
    stage2.latitude = 44.6976;
    stage2.longitude = 7.8544;
    updated = true;
  }

  const stage3Exists = db.stages.some((s: any) => s.id === "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c");
  if (!stage3Exists) {
    db.stages.push({
      id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
      nome_tappa: "La Banca",
      descrizione: "Stazione Ferroviaria di Bra",
      ordine: 3,
      latitude: 44.6946,
      longitude: 7.8542,
    });
    updated = true;
  } else {
    const stage3 = db.stages.find((s: any) => s.id === "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c");
    if (
      stage3 &&
      (stage3.nome_tappa !== "La Banca" ||
        stage3.descrizione !== "Stazione Ferroviaria di Bra" ||
        stage3.latitude !== 44.6946 ||
        stage3.longitude !== 7.8542)
    ) {
      stage3.nome_tappa = "La Banca";
      stage3.descrizione = "Stazione Ferroviaria di Bra";
      stage3.latitude = 44.6946;
      stage3.longitude = 7.8542;
      updated = true;
    }
  }

  const rebusVisivo = db.challenges.find(
    (c: any) => c.id === "999f4e1f-7443-42e7-9d7a-115f2122888f",
  );
  if (!rebusVisivo) {
    db.challenges.push({
      id: "999f4e1f-7443-42e7-9d7a-115f2122888f",
      stage_id: "dfa9e6db-4e1b-41be-94be-21cf2980fa2a",
      titolo: "Il Rebus Visivo",
      descrizione: "Raggiungete il luogo rappresentato dal simbolo.",
      tipo_sfida: "photo",
      punteggio_massimo: 25,
      ordine: 1,
    });
    updated = true;
  } else if (
    rebusVisivo.tipo_sfida !== "photo" ||
    rebusVisivo.punteggio_massimo !== 25 ||
    rebusVisivo.titolo !== "Il Rebus Visivo"
  ) {
    rebusVisivo.titolo = "Il Rebus Visivo";
    rebusVisivo.descrizione = "Raggiungete il luogo rappresentato dal simbolo.";
    rebusVisivo.tipo_sfida = "photo";
    rebusVisivo.punteggio_massimo = 25;
    rebusVisivo.ordine = 1;
    updated = true;
  }

  const emojiMoviesCh = db.challenges.find(
    (c: any) => c.id === "777f4e1f-7443-42e7-9d7a-115f2122888f",
  );
  if (!emojiMoviesCh) {
    db.challenges.push({
      id: "777f4e1f-7443-42e7-9d7a-115f2122888f",
      stage_id: "dfa9e6db-4e1b-41be-94be-21cf2980fa2a",
      titolo: "Indovina il film dalle emoji",
      descrizione:
        "Viaggiatori, si spengono le luci, si alza il sipario: benvenuti nella sala più insolita della caccia!",
      tipo_sfida: "emoji_movies",
      punteggio_massimo: 15,
      ordine: 2,
    });
    updated = true;
  } else if (
    emojiMoviesCh.ordine !== 2 ||
    emojiMoviesCh.tipo_sfida !== "emoji_movies" ||
    emojiMoviesCh.punteggio_massimo !== 15
  ) {
    emojiMoviesCh.ordine = 2;
    emojiMoviesCh.tipo_sfida = "emoji_movies";
    emojiMoviesCh.punteggio_massimo = 15;
    updated = true;
  }

  const livingPosterCh = db.challenges.find(
    (c: any) => c.id === "555f4e1f-7443-42e7-9d7a-115f2122888f",
  );
  if (!livingPosterCh) {
    db.challenges.push({
      id: "555f4e1f-7443-42e7-9d7a-115f2122888f",
      stage_id: "dfa9e6db-4e1b-41be-94be-21cf2980fa2a",
      titolo: "La locandina vivente",
      descrizione: "La vostra squadra ha appena ricevuto la locandina di un film iconico.",
      tipo_sfida: "living_poster",
      punteggio_massimo: 15,
      ordine: 3,
    });
    updated = true;
  } else if (
    livingPosterCh.ordine !== 3 ||
    livingPosterCh.tipo_sfida !== "living_poster" ||
    livingPosterCh.punteggio_massimo !== 15
  ) {
    livingPosterCh.ordine = 3;
    livingPosterCh.tipo_sfida = "living_poster";
    livingPosterCh.punteggio_massimo = 15;
    updated = true;
  }

  // Initialize challenge_answers table if not exists
  if (!db.challenge_answers) {
    db.challenge_answers = [];
    updated = true;
  }

  // Seed challenge_answers for 'La Banca'
  const bankAnswersCount = db.challenge_answers.filter(
    (a: any) => a.challenge_id === "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
  ).length;
  if (bankAnswersCount === 0) {
    db.challenge_answers.push(
      {
        id: "ans_1",
        challenge_id: "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
        question_number: 1,
        question_text: "Lo usi per prelevare contanti senza fare la fila allo sportello",
        correct_answer: "BANCOMAT",
        extracted_letter: "B",
      },
      {
        id: "ans_2",
        challenge_id: "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
        question_number: 2,
        question_text: "Il codice segreto a 4 cifre che non devi mai dire a nessuno",
        correct_answer: "PIN",
        extracted_letter: "P",
      },
      {
        id: "ans_3",
        challenge_id: "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
        question_number: 3,
        question_text: "La moneta che hai in tasca in tutta Europa",
        correct_answer: "EURO",
        extracted_letter: "E",
      },
      {
        id: "ans_4",
        challenge_id: "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
        question_number: 4,
        question_text: "La scadenza mensile del mutuo, incubo di ogni famiglia",
        correct_answer: "RATA",
        extracted_letter: "R",
      },
    );
    updated = true;
  }

  // Initialize team_challenge_progress table if not exists
  if (!db.team_challenge_progress) {
    db.team_challenge_progress = [];
    updated = true;
  }

  // Add/Verify 'La Banca' challenge
  const bankCh = db.challenges.find((c: any) => c.id === "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6");
  if (!bankCh) {
    db.challenges.push({
      id: "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
      stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
      titolo: "La Banca",
      descrizione:
        "Quattro indizi, quattro parole, Viaggiatori. Risolveteli come veri enigmisti da settimana enigmistica: una definizione, una risposta, una sola letter che conta davvero — la prima.",
      tipo_sfida: "banca",
      punteggio_massimo: 25,
      ordine: 1,
      unlock_condition: "marketplace_active",
    });
    updated = true;
  } else if (
    bankCh.ordine !== 1 ||
    bankCh.tipo_sfida !== "banca" ||
    bankCh.unlock_condition !== "marketplace_active" ||
    bankCh.punteggio_massimo !== 25
  ) {
    bankCh.ordine = 1;
    bankCh.tipo_sfida = "banca";
    bankCh.unlock_condition = "marketplace_active";
    bankCh.punteggio_massimo = 25;
    updated = true;
  }

  // Add/Verify 'Missione Social' challenge
  const socialCh = db.challenges.find((c: any) => c.id === "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7");
  if (!socialCh) {
    db.challenges.push({
      id: "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7",
      stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
      titolo: "Missione Social",
      descrizione:
        "Viaggiatori, questa volta la sfida non è contro il tempo, ma contro la vostra capacità di entrare in contatto con il mondo. Dimostrate di saper comunicare, convincere e creare un legame con persone mai incontrate prima.",
      tipo_sfida: "social",
      punteggio_massimo: 20,
      ordine: 2,
      unlock_condition: "marketplace_active",
    });
    updated = true;
  } else if (
    socialCh.ordine !== 2 ||
    socialCh.tipo_sfida !== "social" ||
    socialCh.unlock_condition !== "marketplace_active" ||
    socialCh.punteggio_massimo !== 20
  ) {
    socialCh.ordine = 2;
    socialCh.tipo_sfida = "social";
    socialCh.unlock_condition = "marketplace_active";
    socialCh.punteggio_massimo = 20;
    updated = true;
  }

  // Initialize team_social_submissions table if not exists
  if (!db.team_social_submissions) {
    db.team_social_submissions = [];
    updated = true;
  }

  // Add/Verify 'Il Codice Segreto' challenge
  const codeCh = db.challenges.find((c: any) => c.id === "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8");
  if (!codeCh) {
    db.challenges.push({
      id: "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8",
      stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
      titolo: "Il Codice Segreto",
      descrizione:
        "Viaggiatori, per sbloccare la destinazione finale della gara dovete inserire il PIN a 10 cifre. Ma ricordate: voi avete solo mezza chiave. Dovete trovare il vostro partner economico e acquistare il frammento mancante usando i vostri Token.",
      tipo_sfida: "codice",
      punteggio_massimo: 15,
      ordine: 3,
      unlock_condition: "marketplace_active",
    });
    updated = true;
  } else if (
    codeCh.ordine !== 3 ||
    codeCh.tipo_sfida !== "codice" ||
    codeCh.unlock_condition !== "marketplace_active" ||
    codeCh.punteggio_massimo !== 15
  ) {
    codeCh.ordine = 3;
    codeCh.tipo_sfida = "codice";
    codeCh.unlock_condition = "marketplace_active";
    codeCh.punteggio_massimo = 15;
    updated = true;
  }

  // Initialize new secret code challenge tables if not exist
  if (!db.game_final_code || db.game_final_code.length === 0) {
    db.game_final_code = [
      {
        id: uuid(),
        full_code: "4829167305",
        next_stage_destination: "Parco Giochi Madonna dei Fiori (lato piazzale grigio)",
        created_at: new Date().toISOString(),
      },
    ];
    updated = true;
  }
  if (!db.team_code_parts) {
    db.team_code_parts = [];
    updated = true;
  }
  if (!db.team_code_matches) {
    db.team_code_matches = [];
    updated = true;
  }
  if (!db.code_purchase_transactions) {
    db.code_purchase_transactions = [];
    updated = true;
  }
  if (!db.pin_attempts) {
    db.pin_attempts = [];
    updated = true;
  }

  // Remove 'La Stazione' challenge (888f4e1f-7443-42e7-9d7a-115f2122888f) if it exists
  const hasStazione = db.challenges.some(
    (c: any) => c.id === "888f4e1f-7443-42e7-9d7a-115f2122888f",
  );
  if (hasStazione) {
    db.challenges = db.challenges.filter(
      (c: any) => c.id !== "888f4e1f-7443-42e7-9d7a-115f2122888f",
    );
    updated = true;
  }

  if (!db.activity_log) {
    db.activity_log = [];
    updated = true;
  }
  if (!db.settings) {
    db.settings = [
      { id: "game_status", value: "Gara attiva" },
      { id: "game_started_at", value: new Date().toISOString() },
    ];
    updated = true;
  }
  // Migration: ensure every existing team has active=true if the field was never set
  let teamsMigrated = false;
  if (db.teams) {
    db.teams.forEach((t: any) => {
      if (t.active === undefined || t.active === null) {
        t.active = true;
        teamsMigrated = true;
      }
    });
    if (teamsMigrated) updated = true;
  }
  // ────────────────────────────────────────────
  // TAPPA 4 — ENIGMI (migration 2.0.0)
  // ────────────────────────────────────────────
  const STAGE4_ID = "4b4b4c4d-5e5f-6061-7172-838485868788";
  const ENIGMA1_ID = "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7";
  const ENIGMA2_ID = "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8";
  const ENIGMA3_ID = "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9";

  const stage4Exists = db.stages.some((s: any) => s.id === STAGE4_ID);
  if (!stage4Exists) {
    db.stages.push({
      id: STAGE4_ID,
      nome_tappa: "Enigmi",
      descrizione: "Risolvi gli enigmi e inserisci le soluzioni per avanzare.",
      ordine: 4,
      latitude: null,
      longitude: null,
    });
    updated = true;
  } else {
    const s4 = db.stages.find((s: any) => s.id === STAGE4_ID);
    if (s4 && s4.ordine !== 4) {
      s4.ordine = 4;
      updated = true;
    }
  }

  const enigma1Exists = db.challenges.some((c: any) => c.id === ENIGMA1_ID);
  if (!enigma1Exists) {
    db.challenges.push({
      id: ENIGMA1_ID,
      stage_id: STAGE4_ID,
      titolo: "Rebus Musicale",
      descrizione:
        "Ricevete il rebus cartaceo, scoprite le 3 note e inseritele nell'ordine corretto.",
      tipo_sfida: "enigma_musicale",
      punteggio_massimo: 5,
      ordine: 1,
      wrong_answer_penalty: -8,
    });
    updated = true;
  } else {
    const e1 = db.challenges.find((c: any) => c.id === ENIGMA1_ID);
    if (e1 && e1.wrong_answer_penalty === undefined) {
      e1.wrong_answer_penalty = -8;
      updated = true;
    }
  }

  const enigma2Exists = db.challenges.some((c: any) => c.id === ENIGMA2_ID);
  if (!enigma2Exists) {
    db.challenges.push({
      id: ENIGMA2_ID,
      stage_id: STAGE4_ID,
      titolo: "Lucchetto Direzionale",
      descrizione: "Risolvete l'enigma cartaceo e ricavate la sequenza di 4 direzioni.",
      tipo_sfida: "lucchetto_direzionale",
      punteggio_massimo: 5,
      ordine: 2,
      wrong_answer_penalty: -8,
    });
    updated = true;
  } else {
    const e2 = db.challenges.find((c: any) => c.id === ENIGMA2_ID);
    if (e2) {
      let e2Updated = false;
      if (e2.tipo_sfida !== "lucchetto_direzionale" || e2.titolo !== "Lucchetto Direzionale") {
        e2.tipo_sfida = "lucchetto_direzionale";
        e2.titolo = "Lucchetto Direzionale";
        e2.descrizione = "Risolvete l'enigma cartaceo e ricavate la sequenza di 4 direzioni.";
        e2Updated = true;
      }
      if (e2.wrong_answer_penalty !== -8) {
        e2.wrong_answer_penalty = -8;
        e2Updated = true;
      }
      if (e2Updated) updated = true;
    }
  }

  const STAGE5_ID = "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c";
  const CORNHOLE_CHALLENGE_ID = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";
  const TRAGUARDO_CHALLENGE_ID = "e5e5e5e5-f6f6-f7f7-f8f8-f9f9f0f0f0f0";

  const stage5Exists = db.stages.some((s: any) => s.id === STAGE5_ID);
  if (!stage5Exists) {
    db.stages.push({
      id: STAGE5_ID,
      nome_tappa: "Tappa Finale",
      descrizione: "Traguardo finale della gara! Raggiungete la destinazione.",
      ordine: 5,
      latitude: 44.71631488741777,
      longitude: 7.842901351857487,
    });
    updated = true;
  }

  const BOXE_CHALLENGE_ID = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";

  const cornholeExists = db.challenges.some((c: any) => c.id === CORNHOLE_CHALLENGE_ID);
  if (!cornholeExists) {
    db.challenges.push({
      id: CORNHOLE_CHALLENGE_ID,
      stage_id: STAGE5_ID,
      titolo: "Sfida Cornhole",
      descrizione: "Torneo fisico di Cornhole 1vs1 gestito dalla regia.",
      tipo_sfida: "cornhole",
      punteggio_massimo: 20,
      ordine: 1,
    });
    updated = true;
  }

  const boxeExists = db.challenges.some((c: any) => c.id === BOXE_CHALLENGE_ID);
  if (!boxeExists) {
    db.challenges.push({
      id: BOXE_CHALLENGE_ID,
      stage_id: STAGE5_ID,
      titolo: "Boxe Gonfiabile",
      descrizione: "Torneo fisico a eliminazione diretta di Boxe Gonfiabile 1vs1.",
      tipo_sfida: "boxe",
      punteggio_massimo: 20,
      ordine: 2,
    });
    updated = true;
  }

  const JACKPOT_CHALLENGE_ID = "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0";

  const jackpotExists = db.challenges.some((c: any) => c.id === JACKPOT_CHALLENGE_ID);
  if (!jackpotExists) {
    db.challenges.push({
      id: JACKPOT_CHALLENGE_ID,
      stage_id: STAGE5_ID,
      titolo: "Jackpot della Regia",
      descrizione:
        "Sfida Bonus opzionale. Sfida la fortuna alla slot machine scommettendo i tuoi punti.",
      tipo_sfida: "jackpot",
      punteggio_massimo: 20,
      ordine: 3,
    });
    updated = true;
  }

  // Rimozione Sfida 4 (Traguardo Finale) per Stage 5
  if (db.challenges.some((c: any) => c.id === TRAGUARDO_CHALLENGE_ID)) {
    db.challenges = db.challenges.filter((c: any) => c.id !== TRAGUARDO_CHALLENGE_ID);
    db.team_progress =
      db.team_progress?.filter((tp: any) => tp.challenge_id !== TRAGUARDO_CHALLENGE_ID) ?? [];
    updated = true;
  }

  if (!db.jackpot_plays) {
    db.jackpot_plays = [];
    updated = true;
  }

  if (!db.cornhole_matches) {
    db.cornhole_matches = [];
    updated = true;
  }

  if (!db.boxe_matches) {
    db.boxe_matches = [];
    updated = true;
  }

  const enigma3Exists = db.challenges.some((c: any) => c.id === ENIGMA3_ID);
  if (!enigma3Exists) {
    db.challenges.push({
      id: ENIGMA3_ID,
      stage_id: STAGE4_ID,
      titolo: "Le Coordinate Finali",
      descrizione: "Risolvete l'enigma cartaceo per ricavare le coordinate finali.",
      tipo_sfida: "enigma_coordinate",
      punteggio_massimo: 5,
      ordine: 3,
      wrong_answer_penalty: -8,
    });
    updated = true;
  } else {
    const e3 = db.challenges.find((c: any) => c.id === ENIGMA3_ID);
    if (e3) {
      let e3Updated = false;
      if (e3.tipo_sfida !== "enigma_coordinate" || e3.titolo !== "Le Coordinate Finali") {
        e3.tipo_sfida = "enigma_coordinate";
        e3.titolo = "Le Coordinate Finali";
        e3.descrizione = "Risolvete l'enigma cartaceo per ricavare le coordinate finali.";
        e3Updated = true;
      }
      if (e3.wrong_answer_penalty !== -8) {
        e3.wrong_answer_penalty = -8;
        e3Updated = true;
      }
      if (e3Updated) updated = true;
    }
  }

  // enigma_attempts — tracks every validation attempt
  if (!db.enigma_attempts) {
    db.enigma_attempts = [];
    updated = true;
  }

  // enigma_solutions — server-only, never sent to client
  if (!db.enigma_solutions) {
    db.enigma_solutions = [
      {
        id: "sol_enigma1",
        challenge_id: ENIGMA1_ID,
        solution_type: "notes", // notes = array comparison
        solution: ["La", "Do", "Re"],
        punteggio: 5,
      },
      {
        id: "sol_enigma2",
        challenge_id: ENIGMA2_ID,
        solution_type: "directions", // directions = direction array comparison
        solution: ["nord-ovest", "sud", "ovest", "est"],
        punteggio: 5,
      },
      {
        id: "sol_enigma3",
        challenge_id: ENIGMA3_ID,
        solution_type: "coordinates", // coordinates = coordinate verification
        solution: { lat: "44.71", lng: "7.84" },
        punteggio: 5,
      },
    ];
    updated = true;
  } else {
    const s2 = db.enigma_solutions.find((s: any) => s.challenge_id === ENIGMA2_ID);
    if (s2 && s2.solution_type !== "directions") {
      s2.solution_type = "directions";
      s2.solution = ["nord-ovest", "sud", "ovest", "est"];
      updated = true;
    }
    const s3 = db.enigma_solutions.find((s: any) => s.challenge_id === ENIGMA3_ID);
    if (s3 && s3.solution_type !== "coordinates") {
      s3.solution_type = "coordinates";
      s3.solution = { lat: "44.71", lng: "7.84" };
      updated = true;
    }
  }

  // database_migration_version check
  if (!db.settings.some((s: any) => s.id === "database_migration_version" && s.value === "1.0.0")) {
    const targetChallenges = [
      { id: "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", maxPoints: 5 },
      { id: "c4e6c385-69ba-4f17-a6d0-36b78776d527", maxPoints: 15 },
      { id: "0147e750-f0a3-4b72-8e76-a003fe2ef143", maxPoints: 10 },
      { id: "999f4e1f-7443-42e7-9d7a-115f2122888f", maxPoints: 25 },
      { id: "777f4e1f-7443-42e7-9d7a-115f2122888f", maxPoints: 15 },
      { id: "555f4e1f-7443-42e7-9d7a-115f2122888f", maxPoints: 15 },
      { id: "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", maxPoints: 25 },
      { id: "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", maxPoints: 20 },
      { id: "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", maxPoints: 15 },
    ];

    targetChallenges.forEach((tc) => {
      const ch = db.challenges.find((c: any) => c.id === tc.id);
      if (ch) ch.punteggio_massimo = tc.maxPoints;
    });

    db.quiz_questions.forEach((q: any) => {
      if (q.challenge_id === "c4e6c385-69ba-4f17-a6d0-36b78776d527") {
        q.points = 3;
      }
    });

    const SCORING_MAP: Record<string, number> = {
      "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47": 5, // Creazione squadra
      "c4e6c385-69ba-4f17-a6d0-36b78776d527": 15, // Quiz Bra
      "0147e750-f0a3-4b72-8e76-a003fe2ef143": 10, // Foto ufficiale
      "999f4e1f-7443-42e7-9d7a-115f2122888f": 25, // Il Rebus Visivo
      "555f4e1f-7443-42e7-9d7a-115f2122888f": 15, // La locandina vivente
      "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6": 25, // La Banca
      "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7": 20, // Missione Social
      "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8": 15, // Il Codice Segreto
    };

    db.scores.forEach((s: any) => {
      if (s.challenge_id === "777f4e1f-7443-42e7-9d7a-115f2122888f") {
        if (s.motivazione && s.motivazione.includes("Completamento prova")) {
          s.punti = 7;
        }
      } else if (SCORING_MAP[s.challenge_id] !== undefined) {
        s.punti = SCORING_MAP[s.challenge_id];
      }
    });

    const versionSetting = db.settings.find((s: any) => s.id === "database_migration_version");
    if (versionSetting) {
      versionSetting.value = "1.0.0";
    } else {
      db.settings.push({ id: "database_migration_version", value: "1.0.0" });
    }
    updated = true;
    console.log("[Migration] Database version 1.0.0 applied successfully.");
  }

  if (db.stages) {
    db.stages.forEach((s: any) => {
      if (!s.stato) {
        s.stato = "open";
        updated = true;
      }
    });
  }

  if (!db.cattiveria_ledger) {
    db.cattiveria_ledger = [];
    updated = true;
  }

  if (!db.game_report) {
    db.game_report = {
      state: "PRIVATE_LIVE",
      published_at: null,
      published_by: null,
      snapshot: null,
    };
    updated = true;
  }

  if (updated) {
    saveDb(db);
  }
  memoryDb = db;
  return db;
}

function calculateLeaderboard(db: any) {
  const JACKPOT_CHALLENGE_ID = "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0";
  const rows = db.teams.map((t: any) => {
    const teamScores = db.scores.filter((s: any) => s.team_id === t.id);
    const challengesPoints = teamScores
      .filter((s: any) => s.challenge_id !== null)
      .reduce((sum: number, s: any) => sum + s.punti, 0);
    const modifierPoints = teamScores
      .filter((s: any) => s.challenge_id === null)
      .reduce((sum: number, s: any) => sum + s.punti, 0);
    const cattiveriaPoints = (db.cattiveria_ledger || [])
      .filter((l: any) => l.team_id === t.id)
      .reduce((sum: number, l: any) => sum + l.punti, 0);
    const totalPoints = challengesPoints + modifierPoints + cattiveriaPoints;

    const progress = db.team_progress.filter(
      (p: any) =>
        p.team_id === t.id && p.stato === "completed" && p.challenge_id !== JACKPOT_CHALLENGE_ID,
    );
    const completedChallenges = progress.length;

    let totalDurationSeconds = 0;
    const teamProg = db.team_progress.filter((p: any) => p.team_id === t.id);

    db.stages.forEach((s: any) => {
      const stageChs = db.challenges.filter((c: any) => c.stage_id === s.id);
      if (stageChs.length === 0) return;

      const stageProgs = teamProg.filter((p: any) =>
        stageChs.some((c: any) => c.id === p.challenge_id),
      );
      if (stageProgs.length === 0) return;

      const startTimes = stageProgs
        .map((p: any) => (p.started_at ? new Date(p.started_at).getTime() : 0))
        .filter(Boolean);
      if (startTimes.length === 0) return;
      const minStart = Math.min(...startTimes);

      const completedChs = stageProgs.filter((p: any) => p.stato === "completed");
      const allCompleted = stageChs.every((c: any) =>
        completedChs.some((p: any) => p.challenge_id === c.id),
      );

      if (allCompleted) {
        const completionTimes = completedChs
          .map((p: any) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
          .filter(Boolean);
        if (completionTimes.length > 0) {
          const maxCompletion = Math.max(...completionTimes);
          totalDurationSeconds += Math.max(0, Math.round((maxCompletion - minStart) / 1000));
        }
      } else {
        totalDurationSeconds += Math.max(0, Math.round((Date.now() - minStart) / 1000));
      }
    });

    const teamPenalties = (db.time_penalties || []).filter((p: any) => p.team_id === t.id);
    const penaltySeconds = teamPenalties.reduce(
      (sum: number, p: any) => sum + (p.duration || 0),
      0,
    );
    totalDurationSeconds += penaltySeconds;

    const completions = progress
      .map((p: any) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
      .filter(Boolean);
    const lastCompletion =
      completions.length > 0 ? new Date(Math.max(...completions)).toISOString() : null;

    return {
      team_id: t.id,
      name: t.nome_squadra,
      color: t.color || "#f97316",
      avatar_url: t.avatar_url || "🏳️",
      motto: t.motto || "",
      challenges_points: challengesPoints,
      modifier_points: modifierPoints,
      cattiveria_points: cattiveriaPoints,
      total_points: totalPoints,
      completed_challenges: completedChallenges,
      total_duration_seconds: totalDurationSeconds,
      last_completion: lastCompletion,
    };
  });

  return rows.sort((a: any, b: any) => {
    // 1. Completed challenges DESC
    if (b.completed_challenges !== a.completed_challenges) {
      return b.completed_challenges - a.completed_challenges;
    }
    // 2. Total points DESC
    if (b.total_points !== a.total_points) {
      return b.total_points - a.total_points;
    }
    // 3. Total duration seconds ASC
    if (a.total_duration_seconds !== b.total_duration_seconds) {
      return a.total_duration_seconds - b.total_duration_seconds;
    }
    // Tie-breaker
    const timeA = a.last_completion ? new Date(a.last_completion).getTime() : Infinity;
    const timeB = b.last_completion ? new Date(b.last_completion).getTime() : Infinity;
    return timeA - timeB;
  });
}

function saveDb(db: any) {
  memoryDb = db;
  try {
    fs.writeFileSync(dbPath, JSON.stringify(db, null, 2));
  } catch (e) {
    try {
      fs.writeFileSync("/tmp/local_database.json", JSON.stringify(db, null, 2));
    } catch (err) {
      // Ignore write errors to tmp
    }
  }
}

// Helper to log activities
function logActivity(db: any, teamId: string | null, action: string, points?: number) {
  if (!db.activity_log) db.activity_log = [];
  db.activity_log.push({
    id: "act_" + uuid(),
    team_id: teamId,
    action,
    points: points || null,
    timestamp: new Date().toISOString(),
  });
}

// Helper to get current stage ID for a team based on incomplete challenges
function getTeamCurrentStageId(db: any, teamId: string): string {
  const completedChIds = (db.team_progress || [])
    .filter((tp: any) => tp.team_id === teamId && tp.stato === "completed")
    .map((tp: any) => tp.challenge_id);

  const sortedStages = [...(db.stages || [])].sort((a: any, b: any) => a.ordine - b.ordine);
  for (const s of sortedStages) {
    const stageChs = (db.challenges || []).filter((c: any) => c.stage_id === s.id);
    if (stageChs.length === 0) continue;
    const allDone = stageChs.every((c: any) => completedChIds.includes(c.id));
    if (!allDone) {
      return s.id;
    }
  }
  return sortedStages[sortedStages.length - 1]?.id || "";
}

// Helper to log and cap Punti Cattiveria
function addCattiveriaPoints(
  db: any,
  teamId: string,
  stageId: string,
  tipo: "bonus" | "malus" | "end_of_stage",
  itemId: string | null,
  txId: string | null,
  points: number,
  motivo: string,
) {
  if (!db.cattiveria_ledger) db.cattiveria_ledger = [];

  // Idempotency: verify if this transaction already generated Punti Cattiveria for this team
  if (
    txId &&
    db.cattiveria_ledger.some(
      (l: any) => l.riferimento_transazione === txId && l.team_id === teamId,
    )
  ) {
    return;
  }

  let finalPoints = points;
  if (points > 0) {
    // Sum of positive points gained by this team in this stage
    const currentPositiveSum = db.cattiveria_ledger
      .filter((l: any) => l.team_id === teamId && l.stage_id === stageId && l.punti > 0)
      .reduce((sum: number, l: any) => sum + l.punti, 0);

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
    motivo:
      motivo +
      (finalPoints !== points ? ` (Cap tappa applicato, punti originali: +${points})` : ""),
    timestamp: new Date().toISOString(),
  });
}

// Generate random UUID
function uuid() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// Generate comprehensive game report from real game data
function generateGameReport(db: any) {
  const rawLeaderboard = calculateLeaderboard(db);
  const sortedLeaderboard = [...rawLeaderboard].sort((a: any, b: any) => {
    if (b.completed_challenges !== a.completed_challenges) {
      return b.completed_challenges - a.completed_challenges;
    }
    if (b.total_points !== a.total_points) {
      return b.total_points - a.total_points;
    }
    if (a.total_duration_seconds !== b.total_duration_seconds) {
      return (a.total_duration_seconds ?? 0) - (b.total_duration_seconds ?? 0);
    }
    const timeA = a.last_completion ? new Date(a.last_completion).getTime() : Infinity;
    const timeB = b.last_completion ? new Date(b.last_completion).getTime() : Infinity;
    return timeA - timeB;
  });

  const stagesList = [...(db.stages || [])].sort((a: any, b: any) => a.ordine - b.ordine);
  const challengesList = db.challenges || [];
  const scoresList = db.scores || [];
  const transactionsList = db.marketplace_transactions || [];
  const cattiveriaList = db.cattiveria_ledger || [];
  const progressList = db.team_progress || [];
  const jackpotPlays = db.jackpot_plays || [];
  const submissionsList = db.submissions || [];

  const teamsReport = sortedLeaderboard.map((teamRank: any, rankIndex: number) => {
    const teamId = teamRank.team_id;
    const teamObj = db.teams.find((t: any) => t.id === teamId) || {};
    const teamScores = scoresList.filter((s: any) => s.team_id === teamId);
    const teamProgress = progressList.filter((p: any) => p.team_id === teamId);
    const teamCattiveria = cattiveriaList.filter((l: any) => l.team_id === teamId);
    const teamTxBought = transactionsList.filter((t: any) => t.buyer_team_id === teamId);
    const teamTxVictim = transactionsList.filter((t: any) => t.target_team_id === teamId);
    const teamJackpot = jackpotPlays.find((j: any) => j.team_id === teamId);

    // Initial tokens: base is 50. Calculate token movements
    let tokensGainedStageRewards = 0;
    let tokensSpentMarketplace = 0;
    teamTxBought.forEach((tx: any) => {
      if (tx.item_id === "reward_stage") {
        tokensGainedStageRewards += Math.abs(tx.costo || 0);
      } else if (tx.costo > 0 && tx.stato !== "blocked") {
        tokensSpentMarketplace += tx.costo;
      }
    });

    // Breakdown per Stage
    const stagesBreakdown = stagesList.map((stage: any) => {
      const stageChs = challengesList
        .filter((c: any) => c.stage_id === stage.id)
        .sort((a: any, b: any) => a.ordine - b.ordine);

      // Challenges in this stage
      const stageChallengesDetails = stageChs.map((c: any) => {
        const prog = teamProgress.find((p: any) => p.challenge_id === c.id);
        const score = teamScores.find((s: any) => s.challenge_id === c.id);
        const sub = submissionsList.find(
          (s: any) => s.challenge_id === c.id && s.team_id === teamId,
        );
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
          submission: sub
            ? {
                file_upload: sub.file_upload || null,
                risposta: sub.risposta || null,
                stato_approvazione: sub.stato_approvazione || "approved",
                voto: sub.voto || null,
              }
            : null,
        };
      });

      const stageChallengesPoints = stageChallengesDetails.reduce(
        (sum: number, c: any) => sum + c.points_awarded,
        0,
      );

      // Bonuses used
      const bonusesInStage = teamTxBought
        .filter((tx: any) => {
          const item = db.marketplace_items?.find((i: any) => i.id === tx.item_id);
          return item?.categoria === "BONUS" && tx.item_id !== "reward_stage";
        })
        .map((tx: any) => {
          const item = db.marketplace_items?.find((i: any) => i.id === tx.item_id);
          const cattEntry = teamCattiveria.find((l: any) => l.riferimento_transazione === tx.id);
          return {
            transaction_id: tx.id,
            item_id: tx.item_id,
            name: item?.nome || tx.item_id,
            cost_tokens: tx.costo || item?.costo_token || 0,
            stato: tx.stato,
            is_used: tx.stato === "used" || tx.stato === "completed",
            timestamp: tx.timestamp,
            cattiveria_delta: cattEntry?.punti || 0,
            outcome: tx.outcome || null,
          };
        });

      // Maluses used by team (attacker)
      const malusesInStage = teamTxBought
        .filter((tx: any) => {
          const item = db.marketplace_items?.find((i: any) => i.id === tx.item_id);
          return item?.categoria === "MALUS";
        })
        .map((tx: any) => {
          const item = db.marketplace_items?.find((i: any) => i.id === tx.item_id);
          const targetTeam = db.teams.find((t: any) => t.id === tx.target_team_id);
          const cattEntry = teamCattiveria.find((l: any) => l.riferimento_transazione === tx.id);

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
            outcome: tx.outcome || null,
          };
        });

      // Maluses suffered by team (victim)
      const malusesSuffered = teamTxVictim.map((tx: any) => {
        const item = db.marketplace_items?.find((i: any) => i.id === tx.item_id);
        const attackerTeam = db.teams.find((t: any) => t.id === tx.buyer_team_id);
        let pointsLost = 0;
        if (tx.item_id === "penalita_punti" && tx.stato !== "blocked") {
          pointsLost = 20;
        } else if (tx.item_id === "trappola" && tx.stato !== "blocked") {
          pointsLost = tx.outcome?.points_stolen || 30;
        }

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
          outcome: tx.outcome || null,
        };
      });

      // Cattiveria ledger entries for this stage
      const stageCattiveriaEntries = teamCattiveria.filter((l: any) => l.stage_id === stage.id);
      const stageCattiveriaPoints = stageCattiveriaEntries.reduce(
        (sum: number, l: any) => sum + l.punti,
        0,
      );

      // Stage closing reward for this stage
      const stageRewardTx = teamTxBought.find(
        (tx: any) =>
          tx.item_id === "reward_stage" &&
          (tx.outcome?.stage_id === stage.id || tx.outcome?.stage_index === stage.ordine),
      );
      const endOfStageCattiveria = stageCattiveriaEntries.find(
        (l: any) => l.tipo === "end_of_stage",
      );

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
        stage_total_points: stageChallengesPoints + stageCattiveriaPoints,
      };
    });

    // Timeline for this team
    const timeline: any[] = [];

    // Add challenge completions
    teamProgress.forEach((p: any) => {
      if (p.stato === "completed" && p.completata_at) {
        const ch = challengesList.find((c: any) => c.id === p.challenge_id);
        const sc = teamScores.find((s: any) => s.challenge_id === p.challenge_id);
        const st = ch ? stagesList.find((s: any) => s.id === ch.stage_id) : null;
        timeline.push({
          timestamp: p.completata_at,
          category: "CHALLENGE",
          title: `Sfida completata: ${ch?.titolo || "Sfida"}`,
          stage_name: st?.nome_tappa || "",
          stage_order: st?.ordine || 1,
          points_delta: sc?.punti || 0,
          cattiveria_delta: 0,
          tokens_delta: 0,
          details: `Completata con successo (+${sc?.punti || 0} PT)`,
        });
      }
    });

    // Add marketplace transactions (bought)
    teamTxBought.forEach((tx: any) => {
      const item = db.marketplace_items?.find((i: any) => i.id === tx.item_id);
      const targetTeam = tx.target_team_id
        ? db.teams.find((t: any) => t.id === tx.target_team_id)
        : null;
      const catt = teamCattiveria.find((l: any) => l.riferimento_transazione === tx.id);

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
          details: `Posizione ${tx.outcome?.position || 1}ª → +${Math.abs(tx.costo || 0)} Token accreditati`,
        });
      } else if (item?.categoria === "MALUS") {
        timeline.push({
          timestamp: tx.timestamp,
          category: "MALUS_ATTACK",
          title: `Malus utilizzato: ${item?.nome || tx.item_id}`,
          stage_name: "",
          stage_order: 1,
          points_delta: tx.item_id === "trappola" ? tx.outcome?.points_stolen || 30 : 0,
          cattiveria_delta: catt?.punti || 0,
          tokens_delta: -(tx.costo || 0),
          details:
            tx.stato === "blocked"
              ? `Attacco contro ${targetTeam?.nome_squadra || "avversario"} bloccato dallo Scudo difensivo!`
              : `Attacco contro ${targetTeam?.nome_squadra || "avversario"} applicato con successo.`,
        });
      } else {
        timeline.push({
          timestamp: tx.timestamp,
          category: "BONUS_USED",
          title: `Bonus: ${item?.nome || tx.item_id}`,
          stage_name: "",
          stage_order: 1,
          points_delta: tx.item_id === "bonus_punti" ? 20 : 0,
          cattiveria_delta: catt?.punti || 0,
          tokens_delta: -(tx.costo || 0),
          details: `Acquistato/utilizzato (${-(tx.costo || 0)} Token${catt?.punti ? `, ${catt.punti} Cattiveria` : ""})`,
        });
      }
    });

    // Add marketplace transactions (victim)
    teamTxVictim.forEach((tx: any) => {
      const item = db.marketplace_items?.find((i: any) => i.id === tx.item_id);
      const attackerTeam = db.teams.find((t: any) => t.id === tx.buyer_team_id);
      if (tx.stato !== "blocked") {
        let pointsLost = 0;
        if (tx.item_id === "penalita_punti") pointsLost = 20;
        if (tx.item_id === "trappola") pointsLost = tx.outcome?.points_stolen || 30;

        timeline.push({
          timestamp: tx.timestamp,
          category: "MALUS_VICTIM",
          title: `Malus subito: ${item?.nome || tx.item_id}`,
          stage_name: "",
          stage_order: 1,
          points_delta: -pointsLost,
          cattiveria_delta: 0,
          tokens_delta: 0,
          details: `Subito attacco da ${attackerTeam?.nome_squadra || "avversario"}${pointsLost > 0 ? ` (−${pointsLost} PT)` : ""}`,
        });
      }
    });

    // Add Cattiveria end-of-stage rewards
    teamCattiveria
      .filter((l: any) => l.tipo === "end_of_stage")
      .forEach((l: any) => {
        const st = stagesList.find((s: any) => s.id === l.stage_id);
        timeline.push({
          timestamp: l.timestamp,
          category: "CATTIVERIA_END_STAGE",
          title: `Regola "Chi non è cattivo paga" (Tappa ${st?.ordine || ""})`,
          stage_name: st?.nome_tappa || "",
          stage_order: st?.ordine || 1,
          points_delta: 0,
          cattiveria_delta: l.punti,
          tokens_delta: 0,
          details: l.motivo,
        });
      });

    // Add Jackpot if played
    if (teamJackpot) {
      timeline.push({
        timestamp: teamJackpot.timestamp,
        category: "JACKPOT",
        title: `Sfida 5.3 — Jackpot della Regia`,
        stage_name: "Tappa Finale",
        stage_order: 5,
        points_delta: teamJackpot.variazione_punti || 0,
        cattiveria_delta: 0,
        tokens_delta: 0,
        details: `Puntata: ${teamJackpot.puntata} PT | Esito: ${teamJackpot.risultato?.toUpperCase()} (${teamJackpot.variazione_punti > 0 ? `+${teamJackpot.variazione_punti}` : teamJackpot.variazione_punti} PT)`,
      });
    }

    // Sort timeline ascending by timestamp
    timeline.sort(
      (a: any, b: any) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
    );

    return {
      position: rankIndex + 1,
      team_id: teamId,
      name: teamRank.name,
      color: teamRank.color,
      avatar_url: teamRank.avatar_url,
      motto: teamRank.motto,
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
      last_completion: teamRank.last_completion || null,
      jackpot_play: teamJackpot || null,
      stages_breakdown: stagesBreakdown,
      timeline,
    };
  });

  return {
    generated_at: new Date().toISOString(),
    total_teams: teamsReport.length,
    teams: teamsReport,
    stages: stagesList.map((s: any) => ({
      id: s.id,
      nome_tappa: s.nome_tappa,
      ordine: s.ordine,
      stato: s.stato,
    })),
  };
}

export const runLocalDbAction = createServerFn({ method: "POST" })
  .validator((data: any) => data)
  .handler(async ({ data: payload }: any) => {
    const db = getDb();
    const action = payload.action;
    const currentUserId = payload.userId || "";

    try {
      // Game Freeze & Enigma Extra Guard / Middleware
      if (currentUserId && (action === "rpc" || action === "mutation" || action === "upload")) {
        const team = db.teams?.find((t: any) => t.id === currentUserId);

        // 1. Freeze check
        if (team && team.freeze_expires_at) {
          const expiresMs = new Date(team.freeze_expires_at).getTime();
          const nowMs = Date.now();
          if (expiresMs > nowMs) {
            let isBlocked = false;
            if (action === "mutation" || action === "upload") {
              isBlocked = true;
            } else if (action === "rpc") {
              const { fnName } = payload;
              const actionRPCs = [
                "start_challenge",
                "complete_challenge",
                "submit_quiz_answer",
                "submit_bank_answer",
                "submit_social_challenge",
                "submit_secret_code_pin",
                "buy_secret_code_part",
                "submit_enigma_answer",
                "submit_cornhole_match_result",
                "submit_boxe_match_result",
                "buy_marketplace_item",
                "consume_marketplace_transaction",
                "open_classifica_bonus",
                "mark_partenza_used",
              ];
              if (actionRPCs.includes(fnName)) {
                isBlocked = true;
              }
            }

            if (isBlocked) {
              return {
                data: null,
                error: {
                  error: "ACCOUNT_FROZEN",
                  message: "La tua squadra è attualmente congelata.",
                  freeze_expires_at: team.freeze_expires_at,
                  status: 403,
                },
              };
            }
          }
        }

        // 2. Enigma Extra check
        const activeEnigmaTx = db.marketplace_transactions?.find(
          (t: any) =>
            t.target_team_id === currentUserId &&
            t.item_id === "enigma_extra" &&
            t.stato === "completed",
        );
        if (activeEnigmaTx) {
          let isBlocked = false;
          if (action === "mutation" || action === "upload") {
            isBlocked = true;
          } else if (action === "rpc") {
            const { fnName } = payload;
            const actionRPCs = [
              "start_challenge",
              "complete_challenge",
              "submit_quiz_answer",
              "submit_bank_answer",
              "submit_social_challenge",
              "submit_secret_code_pin",
              "buy_secret_code_part",
              "submit_enigma_answer",
              "submit_cornhole_match_result",
              "submit_boxe_match_result",
              "buy_marketplace_item",
              "consume_marketplace_transaction",
              "open_classifica_bonus",
              "mark_partenza_used",
            ];
            // Allow calling submit_enigma_extra_answer!
            if (actionRPCs.includes(fnName) && fnName !== "submit_enigma_extra_answer") {
              isBlocked = true;
            }
          }

          if (isBlocked) {
            return {
              data: null,
              error: {
                error: "ENIGMA_EXTRA_ACTIVE",
                message: "La tua squadra deve risolvere l'enigma extra per poter continuare.",
                status: 403,
              },
            };
          }
        }

        // 3. Ruota Sfortunata check
        const activeUnluckyWheelTx = db.marketplace_transactions?.find(
          (t: any) =>
            t.target_team_id === currentUserId &&
            t.item_id === "ruota_sfortunata" &&
            t.stato === "completed",
        );
        if (activeUnluckyWheelTx) {
          let isBlocked = false;
          if (action === "mutation" || action === "upload") {
            isBlocked = true;
          } else if (action === "rpc") {
            const { fnName } = payload;
            const actionRPCs = [
              "start_challenge",
              "complete_challenge",
              "submit_quiz_answer",
              "submit_bank_answer",
              "submit_social_challenge",
              "submit_secret_code_pin",
              "buy_secret_code_part",
              "submit_enigma_answer",
              "submit_cornhole_match_result",
              "submit_boxe_match_result",
              "buy_marketplace_item",
              "consume_marketplace_transaction",
              "open_classifica_bonus",
              "mark_partenza_used",
            ];
            // Allow calling spin_unlucky_wheel!
            if (actionRPCs.includes(fnName) && fnName !== "spin_unlucky_wheel") {
              isBlocked = true;
            }
          }

          if (isBlocked) {
            return {
              data: null,
              error: {
                error: "RUOTA_SFORTUNATA_ACTIVE",
                message: "La tua squadra deve girare la ruota sfortunata per poter continuare.",
                status: 403,
              },
            };
          }
        }
      }

      // 1. LOGIN
      if (action === "login") {
        const { email, password } = payload;
        const username = email?.split("@")[0]?.toLowerCase().trim();
        const trimmedPassword = typeof password === "string" ? password.trim() : "";

        if (username === "justdave") {
          const adminObj = (db.admin || []).find((a: any) => a.username === "justdave");
          const isValid =
            (adminObj &&
              (adminObj.password_hash === password ||
                adminObj.password_hash === trimmedPassword)) ||
            password === "Zioporco01" ||
            trimmedPassword === "Zioporco01";
          if (isValid) {
            const session = {
              user: {
                id: "11111111-1111-1111-1111-111111111111",
                email: "justdave@admin.pechino.local",
                raw_user_meta_data: { display_name: "Admin Regia" },
              },
            };
            return { session, error: null };
          }
        } else {
          const team = (db.teams || []).find(
            (t: any) => t.username?.toLowerCase().trim() === username,
          );
          if (
            team &&
            (team.password_plain === password || team.password_plain === trimmedPassword)
          ) {
            // Block only when active is explicitly false (never block undefined/null — those default to active)
            if (team.active === false) {
              return { error: "Account disattivato dall'amministratore", session: null };
            }
            const session = {
              user: {
                id: team.id,
                email: `${username}@team.pechino.local`,
                raw_user_meta_data: { display_name: team.nome_squadra },
              },
            };
            return { session, error: null };
          }
        }
        return { error: "Credenziali non valide. Controlla username e password.", session: null };
      }

      // 2. FILE UPLOADS
      if (action === "upload") {
        const { bucket, path: filePath, fileData } = payload;
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const fullPath = path.join(uploadsDir, filePath);
        const parentDir = path.dirname(fullPath);
        if (!fs.existsSync(parentDir)) {
          fs.mkdirSync(parentDir, { recursive: true });
        }

        // Write base64 data to disk
        const base64Data = fileData.replace(/^data:image\/\w+;base64,/, "");
        fs.writeFileSync(fullPath, base64Data, "base64");
        return { success: true, error: null };
      }

      // 3. DATABASE QUERIES (SELECT)
      if (action === "query") {
        const { table, select, filters, limit, single } = payload.query;
        let order = payload.query.order;
        let rows = db[table] || [];

        // Special views & Joins
        if (table === "quiz_questions_public") {
          rows = db.quiz_questions.map((q: any) => {
            const { correct_option, ...rest } = q;
            return rest;
          });
        } else if (table === "submissions") {
          rows = rows.map((r: any) => {
            const team = db.teams.find((t: any) => t.id === r.team_id);
            const challenge = db.challenges.find((c: any) => c.id === r.challenge_id);
            const stage = challenge
              ? db.stages.find((s: any) => s.id === challenge.stage_id)
              : null;
            return {
              ...r,
              teams: team ? { nome_squadra: team.nome_squadra } : null,
              challenges: challenge
                ? {
                    titolo: challenge.titolo,
                    punteggio_massimo: challenge.punteggio_massimo,
                    stage_id: challenge.stage_id,
                    stages: stage ? { nome_tappa: stage.nome_tappa } : null,
                  }
                : null,
            };
          });
        } else if (table === "leaderboard") {
          const JACKPOT_CHALLENGE_ID = "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0";
          rows = db.teams.map((t: any) => {
            const teamScores = db.scores.filter((s: any) => s.team_id === t.id);

            // Calculate components
            const challengesPoints = teamScores
              .filter((s: any) => s.challenge_id !== null)
              .reduce((sum: number, s: any) => sum + s.punti, 0);
            const modifierPoints = teamScores
              .filter((s: any) => s.challenge_id === null)
              .reduce((sum: number, s: any) => sum + s.punti, 0);
            const cattiveriaPoints = (db.cattiveria_ledger || [])
              .filter((l: any) => l.team_id === t.id)
              .reduce((sum: number, l: any) => sum + l.punti, 0);
            const totalPoints = challengesPoints + modifierPoints + cattiveriaPoints;

            const progress = db.team_progress.filter(
              (p: any) =>
                p.team_id === t.id &&
                p.stato === "completed" &&
                p.challenge_id !== JACKPOT_CHALLENGE_ID,
            );
            const completedChallenges = progress.length;

            let totalDurationSeconds = 0;
            const teamProg = db.team_progress.filter((p: any) => p.team_id === t.id);

            db.stages.forEach((s: any) => {
              const stageChs = db.challenges.filter((c: any) => c.stage_id === s.id);
              if (stageChs.length === 0) return;

              const stageProgs = teamProg.filter((p: any) =>
                stageChs.some((c: any) => c.id === p.challenge_id),
              );
              if (stageProgs.length === 0) return;

              const startTimes = stageProgs
                .map((p: any) => (p.started_at ? new Date(p.started_at).getTime() : 0))
                .filter(Boolean);
              if (startTimes.length === 0) return;
              const minStart = Math.min(...startTimes);

              const completedChs = stageProgs.filter((p: any) => p.stato === "completed");
              const allCompleted = stageChs.every((c: any) =>
                completedChs.some((p: any) => p.challenge_id === c.id),
              );

              if (allCompleted) {
                const completionTimes = completedChs
                  .map((p: any) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
                  .filter(Boolean);
                if (completionTimes.length > 0) {
                  const maxCompletion = Math.max(...completionTimes);
                  totalDurationSeconds += Math.max(
                    0,
                    Math.round((maxCompletion - minStart) / 1000),
                  );
                }
              } else {
                totalDurationSeconds += Math.max(0, Math.round((Date.now() - minStart) / 1000));
              }
            });

            const teamPenalties = (db.time_penalties || []).filter((p: any) => p.team_id === t.id);
            const penaltySeconds = teamPenalties.reduce(
              (sum: number, p: any) => sum + (p.duration || 0),
              0,
            );
            totalDurationSeconds += penaltySeconds;

            const completions = progress
              .map((p: any) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
              .filter(Boolean);
            const lastCompletion =
              completions.length > 0 ? new Date(Math.max(...completions)).toISOString() : null;

            return {
              team_id: t.id,
              name: t.nome_squadra,
              color: t.color || "#f97316",
              avatar_url: t.avatar_url || "🏳️",
              motto: t.motto || "",
              challenges_points: challengesPoints,
              modifier_points: modifierPoints,
              cattiveria_points: cattiveriaPoints,
              total_points: totalPoints,
              completed_challenges: completedChallenges,
              total_duration_seconds: totalDurationSeconds,
              last_completion: lastCompletion,
              active: t.active,
              freeze_started_at: t.freeze_started_at,
              freeze_expires_at: t.freeze_expires_at,
            };
          });

          // Sort rows according to the official hierarchy
          rows.sort((a: any, b: any) => {
            // 1. completed_challenges DESC
            if (b.completed_challenges !== a.completed_challenges) {
              return b.completed_challenges - a.completed_challenges;
            }
            // 2. total_points DESC
            if (b.total_points !== a.total_points) {
              return b.total_points - a.total_points;
            }
            // 3. total_duration_seconds ASC
            if (a.total_duration_seconds !== b.total_duration_seconds) {
              return a.total_duration_seconds - b.total_duration_seconds;
            }
            // Tie-breaker
            const timeA = a.last_completion ? new Date(a.last_completion).getTime() : Infinity;
            const timeB = b.last_completion ? new Date(b.last_completion).getTime() : Infinity;
            return timeA - timeB;
          });

          order = null; // Prevent subsequent query orders from overriding this
        }

        // Apply filters
        if (filters && filters.length > 0) {
          filters.forEach((f: any) => {
            rows = rows.filter((r: any) => r[f.field] === f.value);
          });
        }

        // Apply order
        if (order && order.length > 0) {
          order.forEach((o: any) => {
            rows = [...rows].sort((a: any, b: any) => {
              if (a[o.column] < b[o.column]) return o.ascending ? -1 : 1;
              if (a[o.column] > b[o.column]) return o.ascending ? 1 : -1;
              return 0;
            });
          });
        }

        // Apply limit
        if (limit != null) {
          rows = rows.slice(0, limit);
        }

        // Apply select alias mapping (e.g. name:nome_squadra)
        if (select && select !== "*" && select.includes(":")) {
          const aliasFields = select
            .split(",")
            .map((f: string) => f.trim())
            .filter((f: string) => f.includes(":"));
          rows = rows.map((r: any) => {
            const mapped = { ...r };
            aliasFields.forEach((f: string) => {
              const [alias, original] = f.split(":");
              if (alias && original) {
                mapped[alias.trim()] = r[original.trim()];
              }
            });
            return mapped;
          });
        }

        // Apply privacy stripping for Black Box mode
        if (table === "leaderboard") {
          const isAdmin =
            currentUserId === "justdave" ||
            db.admin?.some((a: any) => a.id === currentUserId || a.username === currentUserId);
          const hasBonus =
            currentUserId &&
            db.marketplace_transactions?.some(
              (t: any) =>
                t.buyer_team_id === currentUserId &&
                t.item_id === "bonus_classifica" &&
                (t.stato === "completed" || t.stato === "viewing"),
            );

          rows = rows.map((r: any) => {
            const isSelf = r.team_id === currentUserId;
            if (isSelf || isAdmin || hasBonus) {
              return r;
            } else {
              const {
                total_points,
                completed_challenges,
                total_duration_seconds,
                last_completion,
                ...rest
              } = r;
              return rest;
            }
          });
        }

        if (table === "teams") {
          const isAdmin =
            currentUserId === "justdave" ||
            db.admin?.some((a: any) => a.id === currentUserId || a.username === currentUserId);
          rows = rows.map((r: any) => {
            const isSelf = r.id === currentUserId;
            if (isSelf || isAdmin) {
              return r;
            } else {
              const { token_balance, ...rest } = r;
              return rest;
            }
          });
        }

        if (table === "scores") {
          const isAdmin =
            currentUserId === "justdave" ||
            db.admin?.some((a: any) => a.id === currentUserId || a.username === currentUserId);
          if (!isAdmin && currentUserId) {
            rows = rows.filter((r: any) => r.team_id === currentUserId);
          }
        }

        // Apply single mapping
        const result = single ? rows[0] || null : rows;
        return { data: result, error: null };
      }

      // 4. DATABASE MUTATIONS (INSERT, UPDATE, DELETE)
      if (action === "mutation") {
        const { table, method, data, filters } = payload;
        let tableData = db[table] || [];

        if (method === "insert") {
          const insertData = Array.isArray(data) ? data : [data];
          const newRows = insertData.map((d: any) => {
            const newRow = { id: uuid(), created_at: new Date().toISOString(), ...d };

            // Trigger equivalents: if team is inserted, auto assign default user_role and mock auth profile
            if (table === "teams") {
              // Always default active to true so new accounts can log in immediately
              if (newRow.active === undefined || newRow.active === null) {
                newRow.active = true;
              }
              if (newRow.token_balance === undefined || newRow.token_balance === null) {
                newRow.token_balance = 50;
              }
              db.user_roles.push({ user_id: newRow.id, role: "player" });
              logActivity(
                db,
                newRow.id,
                `Squadra "${newRow.nome_squadra}" creata ed iscritta alla competizione.`,
              );
            }

            if (table === "submissions") {
              const team = db.teams.find((t: any) => t.id === newRow.team_id);
              const challenge = db.challenges.find((c: any) => c.id === newRow.challenge_id);
              if (team && challenge) {
                logActivity(
                  db,
                  newRow.team_id,
                  `Squadra "${team.nome_squadra}" ha inviato la prova "${challenge.titolo}" (in attesa di approvazione).`,
                );
              }
            }

            tableData.push(newRow);
            return newRow;
          });
          db[table] = tableData;
          saveDb(db);
          return { data: Array.isArray(data) ? newRows : newRows[0], error: null };
        }

        if (method === "update") {
          let updatedCount = 0;
          tableData = tableData.map((r: any) => {
            // Check if matches filters
            const matches = filters.every((f: any) => r[f.field] === f.value);
            if (matches) {
              updatedCount++;
              if (table === "teams") {
                if (data.active !== undefined && data.active !== r.active) {
                  logActivity(
                    db,
                    r.id,
                    `La regia ha ${data.active ? "ATTIVATO" : "DISATTIVATO"} l'account della squadra "${r.nome_squadra}".`,
                  );
                } else {
                  logActivity(
                    db,
                    r.id,
                    `La regia ha modificato le informazioni per la squadra "${data.nome_squadra || r.nome_squadra}".`,
                  );
                }
              }
              return { ...r, ...data, updated_at: new Date().toISOString() };
            }
            return r;
          });
          db[table] = tableData;
          saveDb(db);
          return { data: tableData, error: null };
        }

        if (method === "delete") {
          const originalLength = tableData.length;
          tableData = tableData.filter((r: any) => {
            const matches = filters.every((f: any) => r[f.field] === f.value);
            if (matches && table === "teams") {
              // Delete trigger equivalent: cleanup roles
              db.user_roles = db.user_roles.filter((ur: any) => ur.user_id !== r.id);
            }
            return !matches;
          });
          db[table] = tableData;
          saveDb(db);
          return { data: null, error: null };
        }
      }

      // 5. DATABASE RPCS (stored procedures)
      if (action === "rpc") {
        const { fnName, args } = payload;

        if (fnName === "current_team_id") {
          return { data: currentUserId || null, error: null };
        }

        if (fnName === "has_role") {
          const { _user_id, _role } = args;
          const roleRecord = db.user_roles.find(
            (ur: any) => ur.user_id === _user_id && ur.role === _role,
          );
          return { data: Boolean(roleRecord), error: null };
        }

        if (fnName === "start_challenge") {
          const { p_challenge } = args;
          const challenge = db.challenges.find((c: any) => c.id === p_challenge);
          if (challenge) {
            const exists = db.team_progress.some(
              (tp: any) => tp.team_id === currentUserId && tp.challenge_id === p_challenge,
            );
            if (!exists) {
              db.team_progress.push({
                id: uuid(),
                team_id: currentUserId,
                stage_id: challenge.stage_id,
                challenge_id: p_challenge,
                stato: "started",
                started_at: new Date().toISOString(),
              });
              const team = db.teams.find((t: any) => t.id === currentUserId);
              if (team) {
                logActivity(
                  db,
                  currentUserId,
                  `Squadra "${team.nome_squadra}" ha iniziato la prova "${challenge.titolo}".`,
                );
              }
              saveDb(db);
            }
          }
          return { data: null, error: null };
        }

        if (fnName === "complete_challenge") {
          const { p_challenge } = args;
          const progRecord = db.team_progress.find(
            (tp: any) => tp.team_id === currentUserId && tp.challenge_id === p_challenge,
          );
          const already = progRecord?.stato === "completed";

          // UPSERT: if no progress record exists, create one (handles team_setup and other edge cases)
          if (!progRecord) {
            const challenge = db.challenges.find((c: any) => c.id === p_challenge);
            db.team_progress.push({
              id: uuid(),
              team_id: currentUserId,
              stage_id: challenge?.stage_id || null,
              challenge_id: p_challenge,
              stato: "completed",
              started_at: new Date().toISOString(),
              completata_at: new Date().toISOString(),
            });
          } else {
            db.team_progress = db.team_progress.map((tp: any) => {
              if (tp.team_id === currentUserId && tp.challenge_id === p_challenge) {
                return { ...tp, stato: "completed", completata_at: new Date().toISOString() };
              }
              return tp;
            });
          }

          const team = db.teams.find((t: any) => t.id === currentUserId);
          const challenge = db.challenges.find((c: any) => c.id === p_challenge);

          // Sfide fotografiche: 0 punti iniziali, punteggio assegnato manualmente dall'admin
          const isPhotoChallenge =
            challenge &&
            (challenge.tipo_sfida === "photo" ||
              challenge.tipo_sfida === "living_poster" ||
              challenge.tipo_sfida === "social");

          let points = 0;
          if (!isPhotoChallenge) {
            points = challenge?.punteggio_massimo ?? 0;
            if (challenge && challenge.tipo_sfida === "emoji_movies") {
              points = 7; // Bonus completamento Emoji Film
            }
          }
          const bonus = 0;
          let stage_completed = false;

          let multiplier_2x_bonus = 0;
          let dimezza_penalty = 0;
          let polizza_refund = 0;

          if (!already) {
            let base_points = points;

            // 1. Sfida punti base
            db.scores.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: p_challenge,
              punti: base_points,
              motivazione: isPhotoChallenge
                ? `Foto consegnata — in attesa di valutazione: ${challenge?.titolo || "Sfida"}`
                : `Completamento prova: ${challenge?.titolo || "Sfida"}`,
              created_at: new Date().toISOString(),
            });

            if (base_points > 0) {
              // 2. MODIFICATORE 2X
              const tx2x = db.marketplace_transactions?.find(
                (t: any) => (t.team_id === currentUserId || t.buyer_team_id === currentUserId) &&
                            (t.marketplace_item_id === "moltiplicatore_2x" || t.item_id === "moltiplicatore_2x") &&
                            t.stato === "completed"
              );
              if (tx2x) {
                multiplier_2x_bonus = base_points;
                db.scores.push({
                  id: uuid(),
                  team_id: currentUserId,
                  challenge_id: p_challenge,
                  punti: multiplier_2x_bonus,
                  motivazione: `Moltiplicatore 2X Tappa (Raddoppio +${multiplier_2x_bonus} PT)`,
                  created_at: new Date().toISOString(),
                });
                tx2x.stato = "used";
                tx2x.data_utilizzo = new Date().toISOString();
                tx2x.dettagli = {
                  applied_to_challenge_id: p_challenge,
                  challenge_title: challenge?.titolo || "Prova",
                  base_points: base_points,
                  multiplier: 2,
                  doubled_points: multiplier_2x_bonus,
                  final_points: base_points + multiplier_2x_bonus,
                };
              }

              // 3. DIMEZZA PUNTI: Rimossa la gestione per singola sfida, spostata al completamento della tappa
            }

            points = base_points + multiplier_2x_bonus - dimezza_penalty + polizza_refund;

            if (challenge) {
              const allStageChs = db.challenges.filter(
                (c: any) => c.stage_id === challenge.stage_id,
              );
              const completedStageChs = db.team_progress.filter(
                (tp: any) =>
                  tp.team_id === currentUserId &&
                  tp.stage_id === challenge.stage_id &&
                  tp.stato === "completed",
              );
              const newlyCompleted = [...completedStageChs];
              if (!newlyCompleted.some((tp: any) => tp.challenge_id === p_challenge)) {
                newlyCompleted.push({ challenge_id: p_challenge });
              }
              if (allStageChs.length > 0 && newlyCompleted.length >= allStageChs.length) {
                stage_completed = true;

                // Handle Dimezza Punti Tappa on stage completion
                const txStageDimezza = db.marketplace_transactions?.find(
                  (t: any) =>
                    t.target_team_id === currentUserId &&
                    (t.marketplace_item_id === "dimezza_punti" || t.item_id === "dimezza_punti") &&
                    (t.stage_id === challenge.stage_id || t.dettagli?.target_stage_id === challenge.stage_id) &&
                    t.stato === "completed",
                );

                if (txStageDimezza) {
                  const stageScores = db.scores.filter(
                    (s: any) => s.team_id === currentUserId && s.stage_id === challenge.stage_id && s.tipo_modificatore !== "penalty_dimezza_tappa",
                  );
                  const fullStageScore = stageScores.reduce((sum: number, s: any) => sum + (s.punti || 0), 0);
                  if (fullStageScore > 0) {
                    dimezza_penalty = Math.floor(fullStageScore / 2);
                    db.scores.push({
                      id: uuid(),
                      team_id: currentUserId,
                      stage_id: challenge.stage_id,
                      punti: -dimezza_penalty,
                      tipo_modificatore: "penalty_dimezza_tappa",
                      motivo: `Malus Dimezza Punti Tappa: penalità −${dimezza_penalty} PT (50% del punteggio complessivo della tappa)`,
                      created_at: new Date().toISOString(),
                    });

                    // Polizza Diretta refund 50%
                    const txPolizza = db.marketplace_transactions?.find(
                      (t: any) => t.team_id === currentUserId && (t.marketplace_item_id === "polizza_diretta" || t.item_id === "polizza_diretta") && t.stato === "completed",
                    );
                    if (txPolizza && dimezza_penalty > 0) {
                      polizza_refund = Math.ceil(dimezza_penalty / 2);
                      db.scores.push({
                        id: uuid(),
                        team_id: currentUserId,
                        stage_id: challenge.stage_id,
                        punti: polizza_refund,
                        tipo_modificatore: "bonus_polizza",
                        motivo: `Polizza Diretta: Rimborso 50% penalità Dimezza Tappa (+${polizza_refund} PT)`,
                        created_at: new Date().toISOString(),
                      });
                      txPolizza.stato = "used";
                      txPolizza.data_utilizzo = new Date().toISOString();
                      txPolizza.dettagli = { refunded_points: polizza_refund, source_malus: "dimezza_punti", target_stage_id: challenge.stage_id };
                    }
                  }

                  txStageDimezza.stato = "used";
                  txStageDimezza.data_utilizzo = new Date().toISOString();
                  txStageDimezza.dettagli = {
                    ...(txStageDimezza.dettagli || {}),
                    stage_score_before: fullStageScore,
                    penalty_applied: dimezza_penalty,
                    stage_score_after: fullStageScore - dimezza_penalty,
                    applied_at_stage_completion: true,
                  };
                }
              }
            }

            if (team && challenge) {
              logActivity(
                db,
                currentUserId,
                isPhotoChallenge
                  ? `Squadra "${team.nome_squadra}" ha consegnato la prova "${challenge.titolo}" — in attesa di valutazione dalla Regia.`
                  : `Squadra "${team.nome_squadra}" ha completato la prova "${challenge.titolo}".`,
                points,
              );
            }
            if (p_challenge === "0147e750-f0a3-4b72-8e76-a003fe2ef143") {
              const settings = db.game_settings?.[0];
              if (settings && !settings.marketplace_visible) {
                settings.marketplace_visible = true;
                logActivity(
                  db,
                  "system",
                  "Il Marketplace è stato SCOPERTO! La voce è ora visibile a tutti i partecipanti.",
                );
              }
            }
          }

          saveDb(db);
          return {
            data: {
              already,
              points,
              base_points: points - multiplier_2x_bonus + dimezza_penalty,
              multiplier_2x_bonus,
              dimezza_penalty,
              polizza_refund,
              bonus,
              stage_completed,
            },
            error: null,
          };
        }

        if (fnName === "approve_submission") {
          const { p_submission_id, p_points } = args;
          const sub = db.submissions.find((s: any) => s.id === p_submission_id);
          if (sub) {
            const challenge = db.challenges.find((c: any) => c.id === sub.challenge_id);
            // Update submission status
            db.submissions = db.submissions.map((s: any) =>
              s.id === p_submission_id ? { ...s, stato_approvazione: "approved" } : s,
            );

            // Complete team progress — upsert if not exists
            const existingProgress = db.team_progress.find(
              (tp: any) => tp.team_id === sub.team_id && tp.challenge_id === sub.challenge_id,
            );
            if (existingProgress) {
              db.team_progress = db.team_progress.map((tp: any) => {
                if (tp.team_id === sub.team_id && tp.challenge_id === sub.challenge_id) {
                  return { ...tp, stato: "completed", completata_at: new Date().toISOString() };
                }
                return tp;
              });
            } else {
              db.team_progress.push({
                id: uuid(),
                team_id: sub.team_id,
                stage_id: challenge?.stage_id || null,
                challenge_id: sub.challenge_id,
                stato: "completed",
                started_at: sub.timestamp || new Date().toISOString(),
                completata_at: new Date().toISOString(),
              });
            }

            // Insert score
            db.scores.push({
              id: uuid(),
              team_id: sub.team_id,
              challenge_id: sub.challenge_id,
              punti: p_points,
              motivazione: `Approvazione prova: ${challenge?.titolo || "Sfida"}`,
              created_at: new Date().toISOString(),
            });

            const team = db.teams.find((t: any) => t.id === sub.team_id);
            if (team && challenge) {
              logActivity(
                db,
                sub.team_id,
                `La regia ha APPROVATO la prova "${challenge.titolo}" della squadra "${team.nome_squadra}".`,
                p_points,
              );
            }

            saveDb(db);
          }
          return { data: null, error: null };
        }

        if (fnName === "reject_submission") {
          const { p_submission_id, p_motivo } = args;
          const sub = db.submissions.find((s: any) => s.id === p_submission_id);
          if (sub) {
            // Update submission status
            const rejectionMsg = p_motivo ? `Rifiutata: ${p_motivo}` : "Rifiutata";
            db.submissions = db.submissions.map((s: any) =>
              s.id === p_submission_id
                ? { ...s, stato_approvazione: "rejected", risposta: rejectionMsg }
                : s,
            );

            // Reset progress to started so team can submit again
            db.team_progress = db.team_progress.map((tp: any) => {
              if (tp.team_id === sub.team_id && tp.challenge_id === sub.challenge_id) {
                return { ...tp, stato: "started", completata_at: null };
              }
              return tp;
            });

            const team = db.teams.find((t: any) => t.id === sub.team_id);
            const challenge = db.challenges.find((c: any) => c.id === sub.challenge_id);
            if (team && challenge) {
              logActivity(
                db,
                sub.team_id,
                `La regia ha RIFIUTATO la prova "${challenge.titolo}" della squadra "${team.nome_squadra}".${p_motivo ? ` Motivazione: ${p_motivo}` : ""}`,
              );
            }

            saveDb(db);
          }
          return { data: null, error: null };
        }

        if (fnName === "get_or_assign_poster") {
          const { p_team_id } = args;
          const assigned = db.team_posters.find((tp: any) => tp.team_id === p_team_id);
          if (assigned) {
            const poster = db.posters.find((p: any) => p.id === assigned.poster_id);
            return { data: { assigned, poster }, error: null };
          }

          const activePosters = db.posters.filter((p: any) => p.active);
          if (activePosters.length === 0) {
            return { data: null, error: { message: "No active posters found in database." } };
          }

          const assignmentCounts: Record<string, number> = {};
          activePosters.forEach((p: any) => {
            assignmentCounts[p.id] = 0;
          });

          db.team_posters.forEach((tp: any) => {
            const currentCount = assignmentCounts[tp.poster_id];
            if (currentCount !== undefined) {
              assignmentCounts[tp.poster_id] = currentCount + 1;
            }
          });

          const minCount = Math.min(...Object.values(assignmentCounts));
          const candidates = activePosters.filter((p: any) => assignmentCounts[p.id] === minCount);
          const chosenPoster = candidates[Math.floor(Math.random() * candidates.length)];

          const newAssignment = {
            id: uuid(),
            team_id: p_team_id,
            poster_id: chosenPoster.id,
            assigned_at: new Date().toISOString(),
          };

          db.team_posters.push(newAssignment);
          saveDb(db);

          return { data: { assigned: newAssignment, poster: chosenPoster }, error: null };
        }

        if (fnName === "evaluate_poster") {
          const { p_submission_id, p_voto, p_admin_id } = args;
          const sub = db.submissions.find((s: any) => s.id === p_submission_id);
          if (!sub) return { data: null, error: { message: "Submission not found" } };

          sub.voto = p_voto;
          sub.approved_at = new Date().toISOString();
          sub.approved_by = p_admin_id;
          sub.stato_approvazione = "approved";

          // Update score (upsert)
          const scoreEntry = db.scores.find(
            (s: any) => s.team_id === sub.team_id && s.challenge_id === sub.challenge_id,
          );
          if (scoreEntry) {
            scoreEntry.punti = p_voto;
            scoreEntry.motivazione = `Valutazione Locandina Vivente (Voto: ${p_voto}/10)`;
            scoreEntry.created_at = new Date().toISOString();
          } else {
            db.scores.push({
              id: uuid(),
              team_id: sub.team_id,
              challenge_id: sub.challenge_id,
              punti: p_voto,
              motivazione: `Valutazione Locandina Vivente (Voto: ${p_voto}/10)`,
              created_at: new Date().toISOString(),
            });
          }

          // Mark challenge as completed in team_progress (upsert)
          const challenge = db.challenges.find((c: any) => c.id === sub.challenge_id);
          const existingProg = db.team_progress.find(
            (tp: any) => tp.team_id === sub.team_id && tp.challenge_id === sub.challenge_id,
          );
          if (existingProg) {
            existingProg.stato = "completed";
            existingProg.completata_at = new Date().toISOString();
          } else {
            db.team_progress.push({
              id: uuid(),
              team_id: sub.team_id,
              stage_id: challenge?.stage_id || null,
              challenge_id: sub.challenge_id,
              stato: "completed",
              started_at: sub.timestamp || new Date().toISOString(),
              completata_at: new Date().toISOString(),
            });
          }

          const team = db.teams.find((t: any) => t.id === sub.team_id);
          if (team && challenge) {
            logActivity(
              db,
              p_admin_id,
              `Regia ha assegnato ${p_voto} punti alla squadra "${team.nome_squadra}" per la sfida "${challenge.titolo}".`,
              p_voto,
            );
          }

          if (sub.challenge_id === "555f4e1f-7443-42e7-9d7a-115f2122888f") {
            const settings = db.game_settings?.[0];
            if (settings && !settings.marketplace_visible) {
              settings.marketplace_visible = true;
              logActivity(
                db,
                "system",
                "Il Marketplace è stato SCOPERTO! La voce è ora visibile a tutti i partecipanti.",
              );
            }
          }

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "confirm_photo_score") {
          const { p_submission_id, p_points, p_admin_id } = args;
          const sub = db.submissions.find((s: any) => s.id === p_submission_id);
          if (!sub) return { data: null, error: { message: "Submission not found" } };

          sub.stato_approvazione = "confirmed";
          sub.voto = p_points;
          sub.approved_at = new Date().toISOString();
          sub.approved_by = p_admin_id;

          const scoreEntry = db.scores.find(
            (s: any) => s.team_id === sub.team_id && s.challenge_id === sub.challenge_id,
          );

          const oldPoints = scoreEntry?.punti ?? 0;
          if (scoreEntry) {
            scoreEntry.punti = p_points;
            scoreEntry.motivazione = `Valutazione foto dalla Regia: ${p_points} PT — ${db.challenges.find((c: any) => c.id === sub.challenge_id)?.titolo || "Sfida"}`;
            scoreEntry.created_at = new Date().toISOString();
          } else {
            db.scores.push({
              id: uuid(),
              team_id: sub.team_id,
              challenge_id: sub.challenge_id,
              punti: p_points,
              motivazione: `Valutazione foto dalla Regia: ${p_points} PT — ${db.challenges.find((c: any) => c.id === sub.challenge_id)?.titolo || "Sfida"}`,
              created_at: new Date().toISOString(),
            });
          }

          const team = db.teams.find((t: any) => t.id === sub.team_id);
          const challenge = db.challenges.find((c: any) => c.id === sub.challenge_id);
          if (team && challenge) {
            if (oldPoints !== p_points) {
              logActivity(
                db,
                p_admin_id,
                `La regia ha modificato il punteggio per la prova "${challenge.titolo}" della squadra "${team.nome_squadra}" da ${oldPoints} a ${p_points} punti.`,
                p_points - oldPoints,
              );
            } else {
              logActivity(
                db,
                p_admin_id,
                `La regia ha confermato il punteggio di ${p_points} punti per la prova "${challenge.titolo}" della squadra "${team.nome_squadra}".`,
              );
            }
          }

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "buy_marketplace_item") {
          const { p_item_id, p_target_team_id } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };

          // Verify marketplace is active
          const settings = db.game_settings?.[0];
          if (!settings || !settings.marketplace_active || !settings.marketplace_visible) {
            return {
              data: null,
              error: { message: "Il Marketplace è chiuso. Non puoi effettuare acquisti." },
            };
          }

          // Ensure Tappa 1 is completed for the current team
          const stage1Challenges = db.challenges.filter(
            (c: any) => c.stage_id === "4a57212e-7e83-430c-b5fe-6cf38db7be2e",
          );
          const completedIds = db.team_progress
            .filter((p: any) => p.team_id === currentUserId && p.stato === "completed")
            .map((p: any) => p.challenge_id);

          const isTappa1Completed = stage1Challenges.every((c: any) => completedIds.includes(c.id));
          if (!isTappa1Completed) {
            return {
              data: null,
              error: {
                message: "Il Marketplace si sbloccherà solo dopo aver completato la Tappa 1!",
              },
            };
          }

          const item = db.marketplace_items.find((i: any) => i.id === p_item_id);
          if (!item) return { data: null, error: { message: "Prodotto non trovato" } };

          if (!db.marketplace_transactions) {
            db.marketplace_transactions = [];
          }

          const alreadyPurchased = db.marketplace_transactions.some(
            (t: any) => t.buyer_team_id === currentUserId && t.item_id === p_item_id,
          );

          const team = db.teams.find((t: any) => t.id === currentUserId);
          if (!team) return { data: null, error: { message: "Squadra non trovata" } };

          const balance = team.token_balance ?? 50;

          if (alreadyPurchased || balance < item.costo_token) {
            return {
              data: null,
              error: {
                message:
                  "Questo oggetto è già stato utilizzato oppure non possiedi abbastanza token.",
              },
            };
          }

          // Target validation for Malus
          let targetTeam = null;
          if (item.categoria === "MALUS") {
            if (!p_target_team_id) {
              return { data: null, error: { message: "Scegli la squadra avversaria da colpire" } };
            }
            if (p_target_team_id === currentUserId) {
              return { data: null, error: { message: "Non puoi colpire la tua stessa squadra!" } };
            }
            targetTeam = db.teams.find((t: any) => t.id === p_target_team_id);
            if (!targetTeam) {
              return { data: null, error: { message: "Squadra bersaglio non trovata." } };
            }

            // Check if already frozen
            if (item.id === "freeze_2min") {
              const isTargetFrozen =
                targetTeam.freeze_expires_at &&
                new Date(targetTeam.freeze_expires_at).getTime() > Date.now();
              if (isTargetFrozen) {
                return { data: null, error: { message: "La squadra bersaglio è già congelata!" } };
              }
            }

            // Check if target already has an active enigma extra
            if (item.id === "enigma_extra") {
              const hasActiveEnigma = db.marketplace_transactions?.some(
                (t: any) =>
                  t.target_team_id === p_target_team_id &&
                  t.item_id === "enigma_extra" &&
                  t.stato === "completed",
              );
              if (hasActiveEnigma) {
                return {
                  data: null,
                  error: { message: "La squadra bersaglio ha già un Enigma Extra attivo!" },
                };
              }
            }

            // Check if target already has an active ruota sfortunata
            if (item.id === "ruota_sfortunata") {
              const hasActiveRuota = db.marketplace_transactions?.some(
                (t: any) =>
                  t.target_team_id === p_target_team_id &&
                  t.item_id === "ruota_sfortunata" &&
                  t.stato === "completed",
              );
              if (hasActiveRuota) {
                return {
                  data: null,
                  error: { message: "La squadra bersaglio ha già una Ruota Sfortunata da girare!" },
                };
              }
            }
          }

          // Deduct tokens
          team.token_balance = balance - item.costo_token;
          let outcome = null;

          // Check if the target team has an active shield
          if (item.categoria === "MALUS" && targetTeam) {
            const activeShieldTx = db.marketplace_transactions.find(
              (t: any) =>
                t.buyer_team_id === targetTeam.id &&
                t.item_id === "bonus_scudo" &&
                t.stato === "completed",
            );
            if (activeShieldTx) {
              // Consume the shield
              activeShieldTx.stato = "used";
              activeShieldTx.blocked_info = {
                attacker_team_id: currentUserId,
                item_id: item.id,
                timestamp: new Date().toISOString(),
              };

              // Assign -3 Punti Cattiveria to the target team (shield owner)
              const targetStageId = getTeamCurrentStageId(db, targetTeam.id);
              addCattiveriaPoints(
                db,
                targetTeam.id,
                targetStageId,
                "bonus",
                "bonus_scudo",
                activeShieldTx.id,
                -3,
                `Utilizzo Scudo (Malus ${item.nome} bloccato)`,
              );

              // Insert blocked Malus transaction
              const transaction = {
                id: uuid(),
                buyer_team_id: currentUserId,
                item_id: item.id,
                target_team_id: p_target_team_id,
                costo: item.costo_token,
                timestamp: new Date().toISOString(),
                stato: "blocked",
                blocked_by_shield_id: activeShieldTx.id,
              };
              db.marketplace_transactions.push(transaction);

              // Log activity
              logActivity(
                db,
                currentUserId,
                `Il Malus "${item.nome}" lanciato da "${team.nome_squadra}" contro "${targetTeam.nome_squadra}" è stato BLOCCATO dallo Scudo.`,
              );

              saveDb(db);
              return {
                data: { success: true, balance: team.token_balance, blockedByShield: true },
                error: null,
              };
            }
          }

          if (item.id === "ruota_fortuna") {
            const rand = Math.random() * 100;
            if (rand < 3) {
              outcome = {
                id: "jackpot",
                label: "🏆 JACKPOT",
                points: 20,
                tokens: 0,
                daveHelp: false,
              };
            } else if (rand < 6) {
              outcome = {
                id: "dave_help",
                label: "🧠 AIUTO EXTRA DI DAVE",
                points: 0,
                tokens: 0,
                daveHelp: true,
              };
            } else if (rand < 13) {
              outcome = {
                id: "mega_bonus",
                label: "💎 MEGA BONUS",
                points: 15,
                tokens: 0,
                daveHelp: false,
              };
            } else if (rand < 25) {
              outcome = { id: "bonus", label: "⭐ BONUS", points: 10, tokens: 0, daveHelp: false };
            } else if (rand < 45) {
              outcome = {
                id: "piccolo_bonus",
                label: "🎁 PICCOLO BONUS",
                points: 5,
                tokens: 0,
                daveHelp: false,
              };
            } else if (rand < 55) {
              outcome = {
                id: "gettoni_bonus",
                label: "🪙 GETTONI BONUS",
                points: 0,
                tokens: 10,
                daveHelp: false,
              };
            } else if (rand < 65) {
              outcome = {
                id: "doppio_premio",
                label: "🎯 DOPPIO PREMIO",
                points: 5,
                tokens: 5,
                daveHelp: false,
              };
            } else if (rand < 80) {
              outcome = {
                id: "fortuna",
                label: "🍀 FORTUNA",
                points: 0,
                tokens: 5,
                daveHelp: false,
              };
            } else {
              outcome = {
                id: "sorpresa",
                label: "🎉 SORPRESA",
                points: 3,
                tokens: 0,
                daveHelp: false,
              };
            }

            // Apply points immediately
            if (outcome.points > 0) {
              db.scores.push({
                id: uuid(),
                team_id: currentUserId,
                challenge_id: null,
                punti: outcome.points,
                motivazione: `Ruota della Fortuna: ${outcome.label}`,
                created_at: new Date().toISOString(),
              });
            }

            // Apply tokens immediately
            if (outcome.tokens > 0) {
              team.token_balance = (team.token_balance ?? 0) + outcome.tokens;
            }
          }

          if (item.id === "bonus_punti") {
            db.scores.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: null,
              punti: 20,
              motivazione: "Acquisto Bonus Punti (+20 PT)",
              created_at: new Date().toISOString(),
            });
          }

          if (item.id === "freeze_2min" && targetTeam) {
            const startedAt = new Date().toISOString();
            const expiresAt = new Date(Date.now() + 120000).toISOString();

            targetTeam.freeze_started_at = startedAt;
            targetTeam.freeze_expires_at = expiresAt;
            targetTeam.freeze_duration_seconds = 120;

            outcome = {
              freeze_started_at: startedAt,
              freeze_expires_at: expiresAt,
              duration_seconds: 120,
            };

            logActivity(
              db,
              p_target_team_id,
              `La squadra "${targetTeam.nome_squadra}" è stata congelata da "${team.nome_squadra}" per 120 secondi!`,
            );
          }

          if (item.id === "enigma_extra" && targetTeam) {
            outcome = {
              enigma_name: "Il Codice del Viaggiatore",
              assigned_at: new Date().toISOString(),
              solution: "LANTERNA",
              solved_at: null,
            };
            logActivity(
              db,
              p_target_team_id,
              `La squadra "${targetTeam.nome_squadra}" ha ricevuto un Enigma Extra da "${team.nome_squadra}"!`,
            );
          }

          if (item.id === "trappola" && targetTeam) {
            const targetScores = db.scores.filter((s: any) => s.team_id === targetTeam.id);
            const targetCurrentPoints = targetScores.reduce(
              (sum: number, s: any) => sum + s.punti,
              0,
            );
            const pointsStolen = Math.max(0, Math.min(30, targetCurrentPoints));

            const buyerScores = db.scores.filter((s: any) => s.team_id === currentUserId);
            const buyerCurrentPoints = buyerScores.reduce(
              (sum: number, s: any) => sum + s.punti,
              0,
            );

            if (pointsStolen > 0) {
              db.scores.push({
                id: uuid(),
                team_id: targetTeam.id,
                challenge_id: null,
                punti: -pointsStolen,
                motivazione: `Malus Trappola: sottratti −${pointsStolen} PT da ${team.nome_squadra || "avversario"}`,
                created_at: new Date().toISOString(),
              });

              db.scores.push({
                id: uuid(),
                team_id: currentUserId,
                challenge_id: null,
                punti: pointsStolen,
                motivazione: `Malus Trappola: rubati +${pointsStolen} PT a ${targetTeam.nome_squadra}`,
                created_at: new Date().toISOString(),
              });
            }

            outcome = {
              nominal_points: 30,
              points_stolen: pointsStolen,
              target_points_before: targetCurrentPoints,
              target_points_after: Math.max(0, targetCurrentPoints - pointsStolen),
              buyer_points_before: buyerCurrentPoints,
              buyer_points_after: buyerCurrentPoints + pointsStolen,
            };

            logActivity(
              db,
              currentUserId,
              `La squadra "${team.nome_squadra}" ha attivato la TRAPPOLA contro "${targetTeam.nome_squadra}" rubando ${pointsStolen} PT.`,
            );
          }

          if (item.id === "penalita_punti" && targetTeam) {
            const targetScores = db.scores.filter((s: any) => s.team_id === targetTeam.id);
            const targetCurrentPoints = targetScores.reduce(
              (sum: number, s: any) => sum + s.punti,
              0,
            );
            const pointsDeducted = Math.max(0, Math.min(20, targetCurrentPoints));

            if (pointsDeducted > 0) {
              db.scores.push({
                id: uuid(),
                team_id: targetTeam.id,
                challenge_id: null,
                punti: -pointsDeducted,
                motivazione: `Malus Penalità Punti (-20 PT) inflitto da ${team.nome_squadra || "avversario"}`,
                created_at: new Date().toISOString(),
              });
            }

            outcome = {
              nominal_points: 20,
              points_deducted: pointsDeducted,
              target_points_before: targetCurrentPoints,
              target_points_after: Math.max(0, targetCurrentPoints - pointsDeducted),
            };

            logActivity(
              db,
              currentUserId,
              `La squadra "${team.nome_squadra}" ha inflitto una PENALITÀ PUNTI contro "${targetTeam.nome_squadra}" sottraendo ${pointsDeducted} PT.`,
            );
          } else if (item.id === "tassa_passaggio" && targetTeam) {
            const buyerScores = db.scores.filter((s: any) => s.team_id === currentUserId);
            const buyerCurrentPoints = buyerScores.reduce(
              (sum: number, s: any) => sum + s.punti,
              0,
            );

            const targetScores = db.scores.filter((s: any) => s.team_id === targetTeam.id);
            const targetCurrentPoints = targetScores.reduce(
              (sum: number, s: any) => sum + s.punti,
              0,
            );

            const buyerDiff = targetCurrentPoints - buyerCurrentPoints;
            const targetDiff = buyerCurrentPoints - targetCurrentPoints;

            db.scores.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: null,
              punti: buyerDiff,
              source: "MARKETPLACE_SWITCH",
              motivazione: `Tassa di Passaggio: scambiati ${buyerCurrentPoints} PT con ${targetCurrentPoints} PT di ${targetTeam.nome_squadra}`,
              created_at: new Date().toISOString(),
            });

            db.scores.push({
              id: uuid(),
              team_id: targetTeam.id,
              challenge_id: null,
              punti: targetDiff,
              source: "MARKETPLACE_SWITCH",
              motivazione: `Tassa di Passaggio: scambiati ${targetCurrentPoints} PT con ${buyerCurrentPoints} PT di ${team.nome_squadra}`,
              created_at: new Date().toISOString(),
            });

            outcome = {
              buyer_points_before: buyerCurrentPoints,
              buyer_points_after: targetCurrentPoints,
              target_points_before: targetCurrentPoints,
              target_points_after: buyerCurrentPoints,
            };

            logActivity(
              db,
              currentUserId,
              `La squadra "${team.nome_squadra}" ha utilizzato la TASSA DI PASSAGGIO scambiando i punteggi con "${targetTeam.nome_squadra}" (${buyerCurrentPoints} PT ↔ ${targetCurrentPoints} PT).`,
            );
          } else if (item.id === "dimezza_punti" && targetTeam) {
            const p_target_stage_id = args.p_target_stage_id;
            const targetStage = db.stages?.find((s: any) => s.id === p_target_stage_id);
            const stageChallenges = db.challenges.filter((c: any) => c.stage_id === p_target_stage_id);
            const compChallenges = db.team_progress.filter(
              (p: any) => p.team_id === targetTeam.id && p.stage_id === p_target_stage_id && p.stato === "completed",
            );
            const isCompleted = stageChallenges.length > 0 && compChallenges.length >= stageChallenges.length;

            if (isCompleted) {
              const stageScores = db.scores.filter(
                (s: any) => s.team_id === targetTeam.id && s.stage_id === p_target_stage_id && s.tipo_modificatore !== "penalty_dimezza_tappa",
              );
              const fullStageScore = stageScores.reduce((sum: number, s: any) => sum + (s.punti || 0), 0);
              let penalty = 0;
              if (fullStageScore > 0) {
                penalty = Math.floor(fullStageScore / 2);
                db.scores.push({
                  id: uuid(),
                  team_id: targetTeam.id,
                  stage_id: p_target_stage_id,
                  punti: -penalty,
                  tipo_modificatore: "penalty_dimezza_tappa",
                  motivo: `Malus Dimezza Punti Tappa ${targetStage?.numero_tappa || ""}: penalità −${penalty} PT (punteggio tappa dimezzato)`,
                  created_at: new Date().toISOString(),
                });

                // Polizza check
                const polizzaTx = db.marketplace_transactions?.find(
                  (t: any) => t.team_id === targetTeam.id && (t.marketplace_item_id === "polizza_diretta" || t.item_id === "polizza_diretta") && t.stato === "completed",
                );
                if (polizzaTx && penalty > 0) {
                  const refund = Math.ceil(penalty / 2);
                  db.scores.push({
                    id: uuid(),
                    team_id: targetTeam.id,
                    stage_id: p_target_stage_id,
                    punti: refund,
                    tipo_modificatore: "bonus_polizza",
                    motivo: `Polizza Diretta: Rimborso 50% penalità Dimezza Tappa (+${refund} PT)`,
                    created_at: new Date().toISOString(),
                  });
                  polizzaTx.stato = "used";
                  polizzaTx.data_utilizzo = new Date().toISOString();
                }
              }

              outcome = {
                target_stage_id: p_target_stage_id,
                stage_number: targetStage?.numero_tappa,
                stage_title: targetStage?.titolo,
                stage_status_at_purchase: "completed",
                stage_score_before: fullStageScore,
                penalty_applied: penalty,
                stage_score_after: fullStageScore - penalty,
                applied_mode: "immediate_completed",
                attacker_name: team.nome_squadra,
                target_team_name: targetTeam.nome_squadra,
              };
            } else {
              outcome = {
                target_stage_id: p_target_stage_id,
                stage_number: targetStage?.numero_tappa,
                stage_title: targetStage?.titolo,
                stage_status_at_purchase: compChallenges.length > 0 ? "in_progress" : "not_started",
                applied_mode: "pending_future",
                attacker_name: team.nome_squadra,
                target_team_name: targetTeam.nome_squadra,
              };
            }

            logActivity(
              db,
              currentUserId,
              `La squadra "${team.nome_squadra}" ha applicato il Malus DIMEZZA PUNTI alla Tappa ${targetStage?.numero_tappa || ""} di "${targetTeam.nome_squadra}".`,
            );
          }

          // Insert transaction
          let txOutcome: any = outcome;
          if (item.id === "bonus_classifica") {
            txOutcome = {
              snapshot: calculateLeaderboard(db),
              snapshot_timestamp: new Date().toISOString(),
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
            outcome: txOutcome,
          };
          db.marketplace_transactions.push(transaction);

          // Assign Punti Cattiveria for items used immediately
          const stageId = getTeamCurrentStageId(db, currentUserId);
          if (item.id === "bonus_punti") {
            addCattiveriaPoints(
              db,
              currentUserId,
              stageId,
              "bonus",
              "bonus_punti",
              transaction.id,
              -5,
              "Utilizzo Bonus Punti (+20 PT)",
            );
          } else if (item.id === "ruota_fortuna") {
            addCattiveriaPoints(
              db,
              currentUserId,
              stageId,
              "bonus",
              "ruota_fortuna",
              transaction.id,
              -2,
              `Utilizzo Ruota della Fortuna: ${outcome?.label || ""}`,
            );
          } else if (item.id === "freeze_2min") {
            addCattiveriaPoints(
              db,
              currentUserId,
              stageId,
              "malus",
              "freeze_2min",
              transaction.id,
              8,
              `Utilizzo Freeze contro ${targetTeam?.nome_squadra || ""}`,
            );
          } else if (item.id === "trappola") {
            addCattiveriaPoints(
              db,
              currentUserId,
              stageId,
              "malus",
              "trappola",
              transaction.id,
              12,
              `Utilizzo Trappola contro ${targetTeam?.nome_squadra || ""}`,
            );
          } else if (item.id === "penalita_punti") {
            addCattiveriaPoints(
              db,
              currentUserId,
              stageId,
              "malus",
              "penalita_punti",
              transaction.id,
              10,
              `Utilizzo Penalità Punti contro ${targetTeam?.nome_squadra || ""}`,
            );
          } else if (item.id === "tassa_passaggio") {
            addCattiveriaPoints(
              db,
              currentUserId,
              stageId,
              "malus",
              "tassa_passaggio",
              transaction.id,
              15,
              `Utilizzo Tassa di Passaggio contro ${targetTeam?.nome_squadra || ""}`,
            );
          }

          // Log activity
          logActivity(
            db,
            currentUserId,
            `La squadra "${team.nome_squadra}" ha acquistato "${item.nome}" per ${item.costo_token} token.${
              targetTeam ? ` Bersaglio: "${targetTeam.nome_squadra}".` : ""
            }${
              outcome ? ` Risultato Ruota: "${outcome.label}".` : ""
            } Saldo residuo: ${team.token_balance} token.`,
          );

          saveDb(db);
          return { data: { success: true, balance: team.token_balance, outcome }, error: null };
        }

        if (fnName === "submit_passaparola_request") {
          const { p_transaction_id, p_request_text } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };
          const tr = db.marketplace_transactions.find((t: any) => t.id === p_transaction_id);
          if (!tr) return { data: null, error: { message: "Transazione non trovata" } };
          if (tr.buyer_team_id !== currentUserId)
            return { data: null, error: { message: "Non autorizzato" } };
          if (tr.item_id !== "passaparola" || tr.stato !== "completed") {
            return { data: null, error: { message: "Richiesta non valida o già inoltrata" } };
          }
          tr.stato = "pending";
          tr.request_text = p_request_text;
          tr.timestamp_request = new Date().toISOString();

          // Deduct -2 Punti Cattiveria
          const stageId = getTeamCurrentStageId(db, currentUserId);
          addCattiveriaPoints(
            db,
            currentUserId,
            stageId,
            "bonus",
            "passaparola",
            tr.id,
            -2,
            "Utilizzo Passaparola (Richiesta inviata)",
          );

          const team = db.teams.find((t: any) => t.id === currentUserId);
          logActivity(
            db,
            currentUserId,
            `La squadra "${team?.nome_squadra || "Sconosciuta"}" ha inoltrato una richiesta Passaparola: "${p_request_text}"`,
          );
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "respond_passaparola_request") {
          const { p_transaction_id, p_response, p_nota_interna, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const tr = db.marketplace_transactions.find((t: any) => t.id === p_transaction_id);
          if (!tr) return { data: null, error: { message: "Transazione non trovata" } };
          if (tr.stato !== "pending")
            return { data: null, error: { message: "La richiesta non è in attesa di risposta" } };

          tr.stato = "used";
          tr.response_text = p_response;
          tr.response_timestamp = new Date().toISOString();
          tr.nota_interna = p_nota_interna || null;

          const team = db.teams.find((t: any) => t.id === tr.buyer_team_id);
          logActivity(
            db,
            tr.buyer_team_id,
            `La Regia ha risposto alla richiesta Passaparola di "${team?.nome_squadra || "Sconosciuta"}": "${p_response}"`,
          );
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "toggle_marketplace") {
          const { p_active, p_admin_id } = args;
          // Accept any call from the known admin ID or from an authenticated session
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          if (!db.game_settings || db.game_settings.length === 0) {
            db.game_settings = [
              {
                id: "settings_01",
                marketplace_visible: false,
                marketplace_active: false,
                activated_at: null,
                activated_by: null,
              },
            ];
          }

          const settings = db.game_settings[0];
          settings.marketplace_active = p_active;

          if (p_active) {
            settings.activated_at = new Date().toISOString();
            settings.activated_by = p_admin_id;
          }

          const adminLabel = db.admin.find((a: any) => a.id === p_admin_id)?.username || "admin";
          logActivity(
            db,
            p_admin_id,
            `Il regista "${adminLabel}" ha ${p_active ? "APERTO" : "CHIUSO"} il Marketplace!`,
          );

          saveDb(db);
          return { data: { success: true, settings }, error: null };
        }

        if (fnName === "open_classifica_bonus") {
          const { p_transaction_id } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };

          const transaction = db.marketplace_transactions?.find(
            (t: any) =>
              t.id === p_transaction_id &&
              t.buyer_team_id === currentUserId &&
              t.item_id === "bonus_classifica",
          );

          if (!transaction) return { data: null, error: { message: "Transazione non trovata" } };

          // If already viewing or used, deny a second session
          if (transaction.stato === "viewing" || transaction.stato === "used") {
            return { data: null, error: { message: "Bonus già in uso o consumato" } };
          }

          // Transition completed → viewing
          if (transaction.stato === "completed") {
            transaction.stato = "viewing";
            transaction.viewed_at = new Date().toISOString();

            // Deduct -3 Punti Cattiveria
            const stageId = getTeamCurrentStageId(db, currentUserId);
            addCattiveriaPoints(
              db,
              currentUserId,
              stageId,
              "bonus",
              "bonus_classifica",
              transaction.id,
              -3,
              "Utilizzo Bonus Classifica",
            );

            saveDb(db);
            return { data: { success: true }, error: null };
          }

          return { data: null, error: { message: "Stato bonus non valido" } };
        }

        if (fnName === "consume_marketplace_transaction") {
          const { p_transaction_id } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };

          const isAdmin = db.user_roles?.some((ur: any) => ur.user_id === currentUserId && ur.role === "admin") || currentUserId === "11111111-1111-1111-1111-111111111111";

          const transaction = db.marketplace_transactions?.find(
            (t: any) => t.id === p_transaction_id && (t.buyer_team_id === currentUserId || t.target_team_id === currentUserId || isAdmin),
          );

          if (transaction) {
            // Allow consuming from completed, viewing, or pending states
            if (transaction.stato === "completed" || transaction.stato === "viewing" || transaction.stato === "pending") {
              transaction.stato = "used";
              transaction.data_utilizzo = new Date().toISOString();
              transaction.closed_at = new Date().toISOString();

              if ((transaction.item_id === "freeze_2min" || transaction.marketplace_item_id === "freeze_2min") && transaction.target_team_id) {
                const targetTeam = db.teams?.find((t: any) => t.id === transaction.target_team_id);
                if (targetTeam) {
                  targetTeam.freeze_expires_at = null;
                  targetTeam.freeze_started_at = null;
                  targetTeam.freeze_duration_seconds = 0;
                }
              }

              saveDb(db);
              return { data: { success: true }, error: null };
            }
            // Already used — idempotent success
            if (transaction.stato === "used") {
              return { data: { success: true }, error: null };
            }
          }
          return { data: null, error: { message: "Transazione non trovata" } };
        }

        if (fnName === "mark_partenza_used") {
          const { p_transaction_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser)
            return { data: null, error: { message: "Non autorizzato" } };

          const tx = db.marketplace_transactions?.find(
            (t: any) => t.id === p_transaction_id && t.item_id === "partenza_anticipata",
          );
          if (!tx) return { data: null, error: { message: "Transazione non trovata" } };
          if (tx.stato === "used") return { data: { success: true }, error: null };

          tx.stato = "used";
          tx.used_at = new Date().toISOString();

          // Deduct -4 Punti Cattiveria
          const stageId = getTeamCurrentStageId(db, tx.buyer_team_id);
          addCattiveriaPoints(
            db,
            tx.buyer_team_id,
            stageId,
            "bonus",
            "partenza_anticipata",
            tx.id,
            -4,
            "Utilizzo Partenza Anticipata (Confermata dalla Regia)",
          );

          saveDb(db);

          const team = db.teams.find((t: any) => t.id === tx.buyer_team_id);
          logActivity(
            db,
            tx.buyer_team_id,
            `La Regia ha registrato l'utilizzo del Bonus Partenza Anticipata da parte di "${team?.nome_squadra || "Sconosciuta"}"`,
          );
          return { data: { success: true }, error: null };
        }

        if (fnName === "close_stage") {
          const { p_stage_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const stage = db.stages.find((s: any) => s.id === p_stage_id);
          if (!stage) return { data: null, error: { message: "Tappa non trovata" } };

          // Idempotency: If the stage is already closed, return success
          if (stage.stato === "closed") {
            return {
              data: { success: true, alreadyClosed: true, ranking: stage.outcome?.ranking || [] },
              error: null,
            };
          }

          const stageChallenges = db.challenges.filter((c: any) => c.stage_id === p_stage_id);
          const stageChallengeIds = new Set(stageChallenges.map((c: any) => c.id));

          if (stageChallenges.length === 0) {
            return { data: null, error: { message: "Questa tappa non ha prove configurate." } };
          }

          // Gather team stats for this stage
          const teamStats = db.teams.map((t: any) => {
            const teamProgress = db.team_progress.filter(
              (p: any) => p.team_id === t.id && stageChallengeIds.has(p.challenge_id),
            );
            const completedCount = teamProgress.filter((p: any) => p.stato === "completed").length;

            const teamScores = db.scores.filter(
              (s: any) => s.team_id === t.id && stageChallengeIds.has(s.challenge_id),
            );
            const points = teamScores.reduce((sum: number, s: any) => sum + s.punti, 0);

            let durationSeconds = 0;
            const startTimes = teamProgress
              .map((p: any) => (p.started_at ? new Date(p.started_at).getTime() : 0))
              .filter(Boolean);
            const minStart = startTimes.length > 0 ? Math.min(...startTimes) : 0;

            const allCompleted = stageChallenges.every((c: any) =>
              teamProgress.some((p: any) => p.challenge_id === c.id && p.stato === "completed"),
            );

            if (allCompleted && minStart > 0) {
              const completionTimes = teamProgress
                .filter((p: any) => p.stato === "completed")
                .map((p: any) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
                .filter(Boolean);
              if (completionTimes.length > 0) {
                const maxCompletion = Math.max(...completionTimes);
                durationSeconds = Math.max(0, Math.round((maxCompletion - minStart) / 1000));
              }
            } else if (minStart > 0) {
              durationSeconds = Math.max(0, Math.round((Date.now() - minStart) / 1000));
            }

            const completions = teamProgress
              .filter((p: any) => p.stato === "completed")
              .map((p: any) => (p.completata_at ? new Date(p.completata_at).getTime() : 0))
              .filter(Boolean);
            const lastCompletion =
              completions.length > 0 ? new Date(Math.max(...completions)).toISOString() : null;

            return {
              team_id: t.id,
              nome_squadra: t.nome_squadra,
              color: t.color || "#f97316",
              avatar_url: t.avatar_url || "🏳️",
              points,
              completedCount,
              durationSeconds,
              lastCompletion,
            };
          });

          // Sort teams using official leaderboard rules (scoped to this stage)
          teamStats.sort((a: any, b: any) => {
            if (b.points !== a.points) {
              return b.points - a.points;
            }
            if (b.completedCount !== a.completedCount) {
              return b.completedCount - a.completedCount;
            }
            if (a.durationSeconds !== b.durationSeconds) {
              return a.durationSeconds - b.durationSeconds;
            }
            const timeA = a.lastCompletion ? new Date(a.lastCompletion).getTime() : Infinity;
            const timeB = b.lastCompletion ? new Date(b.lastCompletion).getTime() : Infinity;
            return timeA - timeB;
          });

          // Reward tokens: 1ª=15, 2ª=13, 3ª=11, 4ª=9, 5ª=7, 6ª=6, 7ª=5, 8ª=4
          const rewardTable = [15, 13, 11, 9, 7, 6, 5, 4];
          const MAX_TOKENS = 80;

          const results = teamStats.map((stat: any, index: number) => {
            const position = index + 1;
            const reward = rewardTable[index] ?? 4;

            // Chi non è cattivo paga logic
            const maluses = (db.cattiveria_ledger || []).filter(
              (l: any) =>
                l.team_id === stat.team_id && l.stage_id === p_stage_id && l.tipo === "malus",
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
                p_stage_id,
                "end_of_stage",
                null,
                `end_stage_${p_stage_id}`,
                endOfStagePoints,
                endOfStageMotivo,
              );
            }

            const team = db.teams.find((t: any) => t.id === stat.team_id);
            const oldBalance = team.token_balance ?? 50;
            const newBalance = Math.min(MAX_TOKENS, oldBalance + reward);
            const actualAdded = newBalance - oldBalance;

            // Update balance
            team.token_balance = newBalance;

            // Record transaction in ledger
            const transaction = {
              id: uuid(),
              buyer_team_id: stat.team_id,
              item_id: "reward_stage",
              target_team_id: null,
              costo: -reward, // negative cost indicates token addition
              timestamp: new Date().toISOString(),
              stato: "completed",
              outcome: {
                stage_id: p_stage_id,
                stage_name: stage.nome_tappa || stage.title || `Tappa ${stage.ordine}`,
                stage_index: stage.ordine,
                position: position,
                reward_tokens: reward,
                actual_added_tokens: actualAdded,
                old_balance: oldBalance,
                new_balance: newBalance,
                capped: newBalance === MAX_TOKENS && oldBalance + reward > MAX_TOKENS,
              },
            };

            if (!db.marketplace_transactions) {
              db.marketplace_transactions = [];
            }
            db.marketplace_transactions.push(transaction);

            logActivity(
              db,
              stat.team_id,
              `Squadra "${stat.nome_squadra}" ha concluso la Tappa ${stage.ordine} in ${position}ª posizione ricevendo +${reward} Token.`,
            );

            return {
              team_id: stat.team_id,
              nome_squadra: stat.nome_squadra,
              avatar_url: stat.avatar_url,
              color: stat.color,
              position,
              reward,
              oldBalance,
              newBalance,
              actualAdded,
              capped: oldBalance + reward > MAX_TOKENS,
            };
          });

          // Mark stage as closed
          stage.stato = "closed";
          stage.outcome = {
            closed_at: new Date().toISOString(),
            closed_by: p_admin_id,
            ranking: results,
            teams_processed: results.length,
            tokens_rewarded: true,
            cattiveria_calculated: true,
            leaderboard_updated: true,
          };

          logActivity(
            db,
            null,
            `STAGE_CLOSED: Tappa "${stage.nome_tappa}" (ordine ${stage.ordine}) chiusa ufficialmente dall'Admin. Squadre elaborate: ${results.length}. Token e Punti Cattiveria assegnati.`,
          );

          saveDb(db);
          return { data: { success: true, results, outcome: stage.outcome }, error: null };
        }

        if (fnName === "reopen_stage") {
          const { p_stage_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const stage = db.stages.find((s: any) => s.id === p_stage_id);
          if (!stage) return { data: null, error: { message: "Tappa non trovata" } };

          if (stage.stato !== "closed") {
            return { data: { success: true }, error: null }; // already open
          }

          // Revert balances
          if (db.marketplace_transactions) {
            const stageTransactions = db.marketplace_transactions.filter(
              (t: any) => t.item_id === "reward_stage" && t.outcome?.stage_id === p_stage_id,
            );

            stageTransactions.forEach((tx: any) => {
              const team = db.teams.find((t: any) => t.id === tx.buyer_team_id);
              if (team) {
                const added = tx.outcome?.actual_added_tokens || 0;
                team.token_balance = Math.max(0, (team.token_balance ?? 50) - added);
              }
            });

            // Delete those transactions
            db.marketplace_transactions = db.marketplace_transactions.filter(
              (t: any) => !(t.item_id === "reward_stage" && t.outcome?.stage_id === p_stage_id),
            );
          }

          // Revert end of stage cattiveria points
          if (db.cattiveria_ledger) {
            db.cattiveria_ledger = db.cattiveria_ledger.filter(
              (l: any) => !(l.tipo === "end_of_stage" && l.stage_id === p_stage_id),
            );
          }

          // Change status
          stage.stato = "open";
          stage.outcome = null;

          logActivity(
            db,
            "system",
            `STAGE_REOPENED: La Regia ha riaperto la Tappa "${stage.nome_tappa}" (${stage.ordine}). Token e Punti Cattiveria di fine tappa sono stati revocati.`,
          );
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "admin_adjust_team_tokens") {
          const { p_team_id, p_amount, p_reason, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }
          if (typeof p_amount !== "number" || isNaN(p_amount)) {
            return { data: null, error: { message: "Quantità token non valida" } };
          }

          const team = db.teams.find((t: any) => t.id === p_team_id);
          if (!team) return { data: null, error: { message: "Squadra non trovata" } };

          const currentBalance = team.token_balance ?? 50;
          const newBalance = Math.max(0, currentBalance + p_amount);
          team.token_balance = newBalance;

          const adminLabel = db.admin?.find((a: any) => a.id === p_admin_id)?.username || "admin";
          const direction = p_amount >= 0 ? "aggiunto" : "rimosso";
          const absAmount = Math.abs(p_amount);
          logActivity(
            db,
            p_admin_id,
            `Regia (${adminLabel}) ha ${direction} ${absAmount} token alla squadra "${team.nome_squadra}". ${p_reason ? `Motivazione: ${p_reason}.` : ""} Saldo attuale: ${newBalance} token.`,
          );

          saveDb(db);
          return { data: { success: true, new_balance: newBalance }, error: null };
        }

        if (fnName === "admin_adjust_team_score") {
          const { p_team_id, p_punti, p_motivo, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }
          if (typeof p_punti !== "number" || isNaN(p_punti)) {
            return { data: null, error: { message: "Punteggio non valido" } };
          }

          const team = db.teams.find((t: any) => t.id === p_team_id);
          if (!team) return { data: null, error: { message: "Squadra non trovata" } };

          const scoreRecord = {
            id: crypto.randomUUID(),
            team_id: p_team_id,
            punti: p_punti,
            motivo: p_motivo || "Regolazione manuale Regia",
            tipo_modificatore: "admin_adjustment",
            created_at: new Date().toISOString(),
          };

          db.scores = db.scores || [];
          db.scores.push(scoreRecord);

          const adminLabel = db.admin?.find((a: any) => a.id === p_admin_id)?.username || "admin";
          const direction = p_punti >= 0 ? "assegnato" : "sottratto";
          const absPoints = Math.abs(p_punti);
          logActivity(
            db,
            p_admin_id,
            `Regia (${adminLabel}) ha ${direction} ${absPoints} punti alla squadra "${team.nome_squadra}". Motivazione: ${p_motivo || "Nessuna"}.`,
          );

          saveDb(db);
          return { data: { success: true, score_id: scoreRecord.id }, error: null };
        }

        if (fnName === "admin_delete_team_score") {
          const { p_score_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          db.scores = (db.scores || []).filter((s: any) => s.id !== p_score_id);
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "submit_quiz_answer") {
          const { p_question, p_selected } = args;
          const q = db.quiz_questions.find((qq: any) => qq.id === p_question);
          if (!q) return { error: "Question not found" };

          const correct = p_selected === q.correct_option;
          const points = correct ? q.points : 0;

          // Record individual answer
          db.team_answers = db.team_answers.filter(
            (ta: any) => !(ta.team_id === currentUserId && ta.question_id === p_question),
          );
          db.team_answers.push({
            id: uuid(),
            team_id: currentUserId,
            question_id: p_question,
            selected_answer: p_selected,
            correct,
            created_at: new Date().toISOString(),
          });

          // If correct, record score
          if (correct) {
            db.scores.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: q.challenge_id,
              punti: points,
              motivazione: "Risposta corretta al quiz",
              created_at: new Date().toISOString(),
            });
          }

          // Record unified submission
          const hasSub = db.submissions.some(
            (s: any) => s.team_id === currentUserId && s.challenge_id === q.challenge_id,
          );
          if (!hasSub) {
            db.submissions.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: q.challenge_id,
              risposta: "Risposto a domanda quiz",
              stato_approvazione: "approved",
              timestamp: new Date().toISOString(),
            });
          }

          const team = db.teams.find((t: any) => t.id === currentUserId);
          const challenge = db.challenges.find((c: any) => c.id === q.challenge_id);
          if (team && challenge) {
            logActivity(
              db,
              currentUserId,
              `Squadra "${team.nome_squadra}" ha risposto alla domanda quiz: "${q.question.slice(0, 30)}..." (${correct ? "Corretto" : "Errato"})`,
              points,
            );
          }

          saveDb(db);
          return { data: { correct, points }, error: null };
        }

        if (fnName === "get_bank_state") {
          const { p_team_id } = args;
          const targetTeamId = p_team_id || currentUserId;
          if (!targetTeamId) return { data: null, error: { message: "Squadra non specificata" } };

          const progress =
            db.team_challenge_progress?.find(
              (p: any) =>
                p.team_id === targetTeamId &&
                p.challenge_id === "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
            ) || null;

          if (!db.team_challenge_answers) db.team_challenge_answers = [];
          const answers = db.team_challenge_answers.filter(
            (a: any) =>
              a.team_id === targetTeamId &&
              a.challenge_id === "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6" &&
              a.correct,
          );

          const allQuestions = db.challenge_answers.filter(
            (q: any) => q.challenge_id === "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6",
          );

          return {
            data: {
              progress,
              answers: answers.map((a: any) => ({
                question_number: a.question_number,
                answer: a.answer,
                extracted_letter: a.extracted_letter,
              })),
              all_questions: allQuestions.map((q: any) => ({
                question_number: q.question_number,
                question_text: q.question_text,
                length: q.correct_answer.length,
              })),
            },
            error: null,
          };
        }

        if (fnName === "submit_bank_answer") {
          const { p_question_number, p_answer } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };

          const settings = db.game_settings?.[0];
          if (!settings || !settings.marketplace_active) {
            return {
              data: null,
              error: {
                message: "La sfida è bloccata. Il Regista deve prima attivare il Marketplace.",
              },
            };
          }

          const challengeId = "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6";
          const q = db.challenge_answers.find(
            (ca: any) =>
              ca.challenge_id === challengeId && ca.question_number === p_question_number,
          );
          if (!q) return { data: null, error: { message: "Domanda non trovata" } };

          if (!db.team_challenge_progress) db.team_challenge_progress = [];
          let progress = db.team_challenge_progress.find(
            (p: any) => p.team_id === currentUserId && p.challenge_id === challengeId,
          );

          if (!progress) {
            progress = {
              id: uuid(),
              team_id: currentUserId,
              challenge_id: challengeId,
              status: "IN_PROGRESS",
              attempts: 0,
              created_at: new Date().toISOString(),
              completed_at: null,
              time_completed: null,
            };
            db.team_challenge_progress.push(progress);
          }

          if (progress.status === "COMPLETED") {
            return { data: { already_completed: true }, error: null };
          }

          progress.attempts = (progress.attempts || 0) + 1;

          const givenClean = (p_answer || "").trim().toUpperCase();
          const isCorrect = givenClean === q.correct_answer.toUpperCase();

          if (!db.team_challenge_answers) db.team_challenge_answers = [];

          // Guard against duplicate correct answers
          const alreadyCorrect = db.team_challenge_answers.some(
            (a: any) =>
              a.team_id === currentUserId &&
              a.challenge_id === challengeId &&
              a.question_number === p_question_number &&
              a.correct,
          );

          if (isCorrect && !alreadyCorrect) {
            db.team_challenge_answers.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: challengeId,
              question_number: p_question_number,
              answer: givenClean,
              correct: true,
              extracted_letter: q.extracted_letter,
              created_at: new Date().toISOString(),
            });

            // Assign score (5 points per correct riddle)
            db.scores.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: challengeId,
              punti: 5,
              motivazione: `Risposta esatta enigma ${p_question_number} - La Banca`,
              created_at: new Date().toISOString(),
            });
          } else if (!isCorrect) {
            // Deduct 5 points on wrong answer
            db.scores.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: challengeId,
              punti: -5,
              tipo_modificatore: "penalty",
              motivazione: `Errore enigma ${p_question_number} - La Banca (-5 PT)`,
              created_at: new Date().toISOString(),
            });
          }

            // Check if all 4 are completed
            const correctAnswers = db.team_challenge_answers.filter(
              (a: any) =>
                a.team_id === currentUserId && a.challenge_id === challengeId && a.correct,
            );

            if (correctAnswers.length === 4) {
              progress.status = "COMPLETED";
              progress.completed_at = new Date().toISOString();

              const startMs = new Date(progress.created_at).getTime();
              const endMs = new Date(progress.completed_at).getTime();
              progress.time_completed = Math.round((endMs - startMs) / 1000); // duration in seconds

              // Write to team_progress for path flow sblocco
              const generalProg = db.team_progress.find(
                (p: any) => p.team_id === currentUserId && p.challenge_id === challengeId,
              );
              if (generalProg) {
                generalProg.stato = "completed";
                generalProg.completata_at = progress.completed_at;
              } else {
                db.team_progress.push({
                  id: uuid(),
                  team_id: currentUserId,
                  stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
                  challenge_id: challengeId,
                  stato: "completed",
                  started_at: progress.created_at,
                  completata_at: progress.completed_at,
                });
              }

              // Save unified submission
              db.submissions.push({
                id: uuid(),
                team_id: currentUserId,
                challenge_id: challengeId,
                risposta: "BPER",
                stato_approvazione: "auto_approved",
                timestamp: progress.completed_at,
              });

              const team = db.teams.find((t: any) => t.id === currentUserId);
              logActivity(
                db,
                currentUserId,
                `La squadra "${team?.nome_squadra || "Sconosciuta"}" ha risolto la sfida finale "La Banca" sbloccando la parola BPER!`,
                20,
              );
            }

            if (isCorrect) {
              saveDb(db);
              return {
                data: {
                  correct: true,
                  letter: q.extracted_letter,
                  challenge_completed: progress.status === "COMPLETED",
                },
                error: null,
              };
            }

            saveDb(db);
            return { data: { correct: false }, error: null };
          }

        if (fnName === "admin_force_complete_bank") {
          const { p_team_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const challengeId = "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6";
          if (!db.team_challenge_progress) db.team_challenge_progress = [];
          let progress = db.team_challenge_progress.find(
            (p: any) => p.team_id === p_team_id && p.challenge_id === challengeId,
          );

          if (!progress) {
            progress = {
              id: uuid(),
              team_id: p_team_id,
              challenge_id: challengeId,
              status: "COMPLETED",
              attempts: 1,
              created_at: new Date().toISOString(),
              completed_at: new Date().toISOString(),
              time_completed: 10,
            };
            db.team_challenge_progress.push(progress);
          } else {
            progress.status = "COMPLETED";
            progress.completed_at = new Date().toISOString();
            progress.time_completed = 10;
          }

          // Force insert correct answers if missing
          if (!db.team_challenge_answers) db.team_challenge_answers = [];
          const allQuestions = db.challenge_answers.filter(
            (q: any) => q.challenge_id === challengeId,
          );
          allQuestions.forEach((q: any) => {
            const alreadyCorrect = db.team_challenge_answers.some(
              (a: any) =>
                a.team_id === p_team_id &&
                a.challenge_id === challengeId &&
                a.question_number === q.question_number &&
                a.correct,
            );
            if (!alreadyCorrect) {
              db.team_challenge_answers.push({
                id: uuid(),
                team_id: p_team_id,
                challenge_id: challengeId,
                question_number: q.question_number,
                answer: q.correct_answer,
                correct: true,
                extracted_letter: q.extracted_letter,
                created_at: new Date().toISOString(),
              });

              // Score +5
              db.scores.push({
                id: uuid(),
                team_id: p_team_id,
                challenge_id: challengeId,
                punti: 5,
                motivazione: `Risposta esatta enigma ${q.question_number} - La Banca (Forzata da Admin)`,
                created_at: new Date().toISOString(),
              });
            }
          });

          // Write to general team_progress
          const generalProg = db.team_progress.find(
            (p: any) => p.team_id === p_team_id && p.challenge_id === challengeId,
          );
          if (generalProg) {
            generalProg.stato = "completed";
            generalProg.completata_at = progress.completed_at;
          } else {
            db.team_progress.push({
              id: uuid(),
              team_id: p_team_id,
              stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
              challenge_id: challengeId,
              stato: "completed",
              started_at: progress.created_at,
              completata_at: progress.completed_at,
            });
          }

          // Submission BPER
          const hasSub = db.submissions.some(
            (s: any) => s.team_id === p_team_id && s.challenge_id === challengeId,
          );
          if (!hasSub) {
            db.submissions.push({
              id: uuid(),
              team_id: p_team_id,
              challenge_id: challengeId,
              risposta: "BPER",
              stato_approvazione: "auto_approved",
              timestamp: progress.completed_at,
            });
          }

          const team = db.teams.find((t: any) => t.id === p_team_id);
          logActivity(
            db,
            p_admin_id,
            `Regia ha forzato il completamento della sfida "La Banca" per la squadra "${team?.nome_squadra || "Sconosciuta"}"`,
          );

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "admin_reset_bank") {
          const { p_team_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const challengeId = "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6";

          // Delete from team_challenge_progress
          if (db.team_challenge_progress) {
            db.team_challenge_progress = db.team_challenge_progress.filter(
              (p: any) => !(p.team_id === p_team_id && p.challenge_id === challengeId),
            );
          }

          // Delete from team_challenge_answers
          if (db.team_challenge_answers) {
            db.team_challenge_answers = db.team_challenge_answers.filter(
              (a: any) => !(a.team_id === p_team_id && a.challenge_id === challengeId),
            );
          }

          // Delete from team_progress
          if (db.team_progress) {
            db.team_progress = db.team_progress.filter(
              (p: any) => !(p.team_id === p_team_id && p.challenge_id === challengeId),
            );
          }

          // Delete from submissions
          if (db.submissions) {
            db.submissions = db.submissions.filter(
              (s: any) => !(s.team_id === p_team_id && s.challenge_id === challengeId),
            );
          }

          // Delete scores for this challenge
          if (db.scores) {
            db.scores = db.scores.filter(
              (s: any) => !(s.team_id === p_team_id && s.challenge_id === challengeId),
            );
          }

          const team = db.teams.find((t: any) => t.id === p_team_id);
          logActivity(
            db,
            p_admin_id,
            `Regia ha resettato completamente la sfida "La Banca" per la squadra "${team?.nome_squadra || "Sconosciuta"}"`,
          );

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "admin_edit_bank_answer") {
          const { p_team_id, p_question_number, p_answer, p_correct, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const challengeId = "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6";
          if (!db.team_challenge_answers) db.team_challenge_answers = [];

          // Remove old answer for this question
          db.team_challenge_answers = db.team_challenge_answers.filter(
            (a: any) =>
              !(
                a.team_id === p_team_id &&
                a.challenge_id === challengeId &&
                a.question_number === p_question_number
              ),
          );

          const q = db.challenge_answers.find(
            (ca: any) =>
              ca.challenge_id === challengeId && ca.question_number === p_question_number,
          );

          if (p_correct) {
            db.team_challenge_answers.push({
              id: uuid(),
              team_id: p_team_id,
              challenge_id: challengeId,
              question_number: p_question_number,
              answer: (p_answer || q?.correct_answer || "").trim().toUpperCase(),
              correct: true,
              extracted_letter: q?.extracted_letter || "",
              created_at: new Date().toISOString(),
            });

            // Adjust scores: remove old scores for this riddle first, then add +5
            if (db.scores) {
              db.scores = db.scores.filter(
                (s: any) =>
                  !(
                    s.team_id === p_team_id &&
                    s.challenge_id === challengeId &&
                    s.motivazione.includes(`enigma ${p_question_number}`)
                  ),
              );
            }
            db.scores.push({
              id: uuid(),
              team_id: p_team_id,
              challenge_id: challengeId,
              punti: 5,
              motivazione: `Risposta esatta enigma ${p_question_number} - La Banca (Corretta da Regia)`,
              created_at: new Date().toISOString(),
            });
          } else {
            // Remove points if marked wrong
            if (db.scores) {
              db.scores = db.scores.filter(
                (s: any) =>
                  !(
                    s.team_id === p_team_id &&
                    s.challenge_id === challengeId &&
                    s.motivazione.includes(`enigma ${p_question_number}`)
                  ),
              );
            }
          }

          // Check if completion status changed
          const correctAnswers = db.team_challenge_answers.filter(
            (a: any) => a.team_id === p_team_id && a.challenge_id === challengeId && a.correct,
          );

          if (!db.team_challenge_progress) db.team_challenge_progress = [];
          let progress = db.team_challenge_progress.find(
            (p: any) => p.team_id === p_team_id && p.challenge_id === challengeId,
          );

          if (correctAnswers.length === 4) {
            if (!progress) {
              progress = {
                id: uuid(),
                team_id: p_team_id,
                challenge_id: challengeId,
                status: "COMPLETED",
                attempts: 1,
                created_at: new Date().toISOString(),
                completed_at: new Date().toISOString(),
                time_completed: 10,
              };
              db.team_challenge_progress.push(progress);
            } else {
              progress.status = "COMPLETED";
              progress.completed_at = new Date().toISOString();
              progress.time_completed = 10;
            }

            // Write to team_progress
            const generalProg = db.team_progress.find(
              (p: any) => p.team_id === p_team_id && p.challenge_id === challengeId,
            );
            if (generalProg) {
              generalProg.stato = "completed";
              generalProg.completata_at = progress.completed_at;
            } else {
              db.team_progress.push({
                id: uuid(),
                team_id: p_team_id,
                stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
                challenge_id: challengeId,
                stato: "completed",
                started_at: progress.created_at,
                completata_at: progress.completed_at,
              });
            }

            // Submission BPER
            const hasSub = db.submissions.some(
              (s: any) => s.team_id === p_team_id && s.challenge_id === challengeId,
            );
            if (!hasSub) {
              db.submissions.push({
                id: uuid(),
                team_id: p_team_id,
                challenge_id: challengeId,
                risposta: "BPER",
                stato_approvazione: "auto_approved",
                timestamp: progress.completed_at,
              });
            }
          } else {
            // Downgrade status if not all correct
            if (progress) {
              progress.status = "IN_PROGRESS";
              progress.completed_at = null;
              progress.time_completed = null;
            }
            // Remove from general team_progress completions
            if (db.team_progress) {
              db.team_progress = db.team_progress.filter(
                (p: any) => !(p.team_id === p_team_id && p.challenge_id === challengeId),
              );
            }
            // Remove submission
            if (db.submissions) {
              db.submissions = db.submissions.filter(
                (s: any) => !(s.team_id === p_team_id && s.challenge_id === challengeId),
              );
            }
          }

          const team = db.teams.find((t: any) => t.id === p_team_id);
          logActivity(
            db,
            p_admin_id,
            `Regia ha modificato la risposta dell'enigma ${p_question_number} per la squadra "${team?.nome_squadra || "Sconosciuta"}"`,
          );

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "get_social_submission") {
          const { p_team_id } = args;
          const targetTeamId = p_team_id || currentUserId;
          if (!targetTeamId) return { data: null, error: { message: "Squadra non specificata" } };

          if (!db.team_social_submissions) db.team_social_submissions = [];
          const submission =
            db.team_social_submissions.find(
              (s: any) =>
                s.team_id === targetTeamId &&
                s.challenge_id === "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7",
            ) || null;

          return { data: submission, error: null };
        }

        if (fnName === "submit_social_challenge") {
          const { p_image_1_path, p_image_2_path } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };

          const settings = db.game_settings?.[0];
          if (!settings || !settings.marketplace_active) {
            return {
              data: null,
              error: {
                message: "La sfida è bloccata. Il Regista deve prima attivare il Marketplace.",
              },
            };
          }

          if (!p_image_1_path || !p_image_2_path) {
            return {
              data: null,
              error: { message: "Devi caricare entrambe le immagini per completare la missione." },
            };
          }

          const challengeId = "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7";
          if (!db.team_social_submissions) db.team_social_submissions = [];

          let sub = db.team_social_submissions.find(
            (s: any) => s.team_id === currentUserId && s.challenge_id === challengeId,
          );

          if (sub) {
            sub.image_1_url = p_image_1_path;
            sub.image_2_url = p_image_2_path;
            sub.uploaded_at = new Date().toISOString();
            sub.status = "submitted";
          } else {
            sub = {
              id: uuid(),
              team_id: currentUserId,
              challenge_id: challengeId,
              image_1_url: p_image_1_path,
              image_2_url: p_image_2_path,
              uploaded_at: new Date().toISOString(),
              status: "submitted",
              admin_score: null,
            };
            db.team_social_submissions.push(sub);
          }

          // Update team_challenge_progress to 'COMPLETED'
          if (!db.team_challenge_progress) db.team_challenge_progress = [];
          let progress = db.team_challenge_progress.find(
            (p: any) => p.team_id === currentUserId && p.challenge_id === challengeId,
          );
          if (!progress) {
            progress = {
              id: uuid(),
              team_id: currentUserId,
              challenge_id: challengeId,
              status: "COMPLETED",
              attempts: 1,
              created_at: new Date().toISOString(),
              completed_at: new Date().toISOString(),
            };
            db.team_challenge_progress.push(progress);
          } else {
            progress.status = "COMPLETED";
            progress.completed_at = new Date().toISOString();
          }

          // Update general team_progress to 'completed'
          const generalProg = db.team_progress.find(
            (p: any) => p.team_id === currentUserId && p.challenge_id === challengeId,
          );
          if (generalProg) {
            generalProg.stato = "completed";
            generalProg.completata_at = new Date().toISOString();
          } else {
            db.team_progress.push({
              id: uuid(),
              team_id: currentUserId,
              stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
              challenge_id: challengeId,
              stato: "completed",
              started_at: new Date().toISOString(),
              completata_at: new Date().toISOString(),
            });
          }

          // Insert submission to submissions table for real-time overview/timeline
          db.submissions = db.submissions.filter(
            (s: any) => !(s.team_id === currentUserId && s.challenge_id === challengeId),
          );
          db.submissions.push({
            id: uuid(),
            team_id: currentUserId,
            challenge_id: challengeId,
            risposta: "social_submitted",
            file_upload: p_image_1_path,
            file_upload_2: p_image_2_path,
            stato_approvazione: "auto_approved",
            timestamp: new Date().toISOString(),
          });

          const team = db.teams.find((t: any) => t.id === currentUserId);
          logActivity(
            db,
            currentUserId,
            `La squadra "${team?.nome_squadra || "Sconosciuta"}" ha inviato la "Missione Social" (in attesa di valutazione)`,
          );

          saveDb(db);
          return { data: sub, error: null };
        }

        if (fnName === "evaluate_social_challenge") {
          const { p_submission_id, p_voto, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          if (!db.team_social_submissions) db.team_social_submissions = [];
          const sub = db.team_social_submissions.find((s: any) => s.id === p_submission_id);
          if (!sub) return { data: null, error: { message: "Sottomissione non trovata" } };

          const challengeId = "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7";
          const score = p_voto !== undefined ? p_voto : 0;

          // Update submission record
          sub.status = "approved";
          sub.admin_score = score;

          // Aggiorna (o crea) il record score — sostituisce il placeholder a 0
          db.scores = db.scores.filter(
            (s: any) => !(s.team_id === sub.team_id && s.challenge_id === challengeId),
          );
          db.scores.push({
            id: uuid(),
            team_id: sub.team_id,
            challenge_id: challengeId,
            punti: score,
            motivazione: `Valutazione Missione Social dalla Regia: ${score}/20 punti`,
            created_at: new Date().toISOString(),
          });

          // Aggiorna la submission principale
          const mainSub = db.submissions.find(
            (s: any) => s.team_id === sub.team_id && s.challenge_id === challengeId,
          );
          if (mainSub) {
            mainSub.stato_approvazione = "approved";
            mainSub.voto = score;
          }

          const team = db.teams.find((t: any) => t.id === sub.team_id);
          logActivity(
            db,
            p_admin_id,
            `Regia ha valutato la "Missione Social" per la squadra "${team?.nome_squadra || "Sconosciuta"}": ${score}/20 PT.`,
          );

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "initialize_secret_code_challenge") {
          const activeTeams = db.teams.filter((t: any) => t.active);
          if (activeTeams.length < 2) {
            return {
              data: { success: false, message: "Servono almeno 2 squadre per iniziare la sfida" },
              error: null,
            };
          }

          const finalCodeRecord = db.game_final_code?.[0];
          if (!finalCodeRecord) {
            return {
              data: { success: false, message: "Codice finale non inizializzato" },
              error: null,
            };
          }
          const fullCode = finalCodeRecord.full_code;
          const first5 = fullCode.slice(0, 5);
          const last5 = fullCode.slice(5);

          if (!db.team_code_parts) db.team_code_parts = [];
          if (!db.team_code_matches) db.team_code_matches = [];

          // Step 1: ensure EVERY team has a part assigned
          activeTeams.forEach((team: any, index: number) => {
            const part = db.team_code_parts.find((p: any) => p.team_id === team.id);
            if (!part) {
              const partType = index % 2 === 0 ? "FIRST_5" : "LAST_5";
              const codeVal = partType === "FIRST_5" ? first5 : last5;
              db.team_code_parts.push({
                id: uuid(),
                team_id: team.id,
                code_part: codeVal,
                part_type: partType,
                assigned_at: new Date().toISOString(),
              });
            }
          });

          // Step 2: build purely random derangement cycle
          db.team_code_matches = [];
          const shuffled = [...activeTeams];
          for (let i = shuffled.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const temp = shuffled[i];
            shuffled[i] = shuffled[j];
            shuffled[j] = temp;
          }

          for (let i = 0; i < shuffled.length; i++) {
            const buyer = shuffled[i];
            const seller = shuffled[(i + 1) % shuffled.length];

            const teamPart = db.team_code_parts.find((p: any) => p.team_id === buyer.id);
            const requiredPart = teamPart?.part_type === "FIRST_5" ? "LAST_5" : "FIRST_5";
            const cost = Math.floor(Math.random() * 3) + 2;

            db.team_code_matches.push({
              buyer_team_id: buyer.id,
              seller_team_id: seller.id,
              required_part: requiredPart,
              token_cost: cost,
              created_at: new Date().toISOString(),
            });
          }

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "get_secret_code_state") {
          const { p_team_id } = args;
          const targetTeamId = p_team_id || currentUserId;
          if (!targetTeamId) return { data: null, error: { message: "Squadra non specificata" } };

          const activeTeams = db.teams.filter((t: any) => t.active);
          const finalCodeRecord = db.game_final_code?.[0];
          const fullCode = finalCodeRecord?.full_code || "4829167305";
          const first5 = fullCode.slice(0, 5);
          const last5 = fullCode.slice(5);

          if (!db.team_code_parts) db.team_code_parts = [];
          if (!db.team_code_matches) db.team_code_matches = [];

          let part = db.team_code_parts.find((p: any) => p.team_id === targetTeamId);
          if (!part) {
            const index = activeTeams.findIndex((t: any) => t.id === targetTeamId);
            const partType = index !== -1 && index % 2 === 1 ? "LAST_5" : "FIRST_5";
            const codeVal = partType === "FIRST_5" ? first5 : last5;
            part = {
              id: uuid(),
              team_id: targetTeamId,
              code_part: codeVal,
              part_type: partType,
              assigned_at: new Date().toISOString(),
            };
            db.team_code_parts.push(part);
            saveDb(db);
          }

          let match = db.team_code_matches.find((m: any) => m.buyer_team_id === targetTeamId);
          if (!match && activeTeams.length >= 2) {
            const myIndex = activeTeams.findIndex((t: any) => t.id === targetTeamId);
            const sellerIndex = myIndex !== -1 ? (myIndex + 1) % activeTeams.length : 0;
            const seller = activeTeams[sellerIndex];
            const requiredPart = part.part_type === "FIRST_5" ? "LAST_5" : "FIRST_5";
            const cost = Math.floor(Math.random() * 3) + 3;
            match = {
              buyer_team_id: targetTeamId,
              seller_team_id: seller.id,
              required_part: requiredPart,
              token_cost: cost,
              created_at: new Date().toISOString(),
            };
            db.team_code_matches.push(match);
            saveDb(db);
          }

          const sellerTeam = match
            ? db.teams.find((t: any) => t.id === match.seller_team_id)
            : null;
          const hasPurchased =
            db.code_purchase_transactions?.some((t: any) => t.buyer_team_id === targetTeamId) ||
            false;

          let purchasedDigits = null;
          if (hasPurchased) {
            const tx = db.code_purchase_transactions.find(
              (t: any) => t.buyer_team_id === targetTeamId,
            );
            purchasedDigits =
              tx?.digits_received || (part.part_type === "FIRST_5" ? last5 : first5);
          }

          const challengeId = "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8";
          const progress = db.team_progress?.find(
            (p: any) => p.team_id === targetTeamId && p.challenge_id === challengeId,
          );
          const completed = progress?.stato === "completed";

          return {
            data: {
              part,
              match: match
                ? { ...match, seller_name: sellerTeam?.nome_squadra || "Sconosciuta" }
                : null,
              has_purchased: hasPurchased,
              purchased_digits: purchasedDigits,
              completed,
              destination:
                finalCodeRecord?.next_stage_destination ||
                "Parco Giochi Madonna dei Fiori (lato piazzale grigio)",
            },
            error: null,
          };
        }

        if (fnName === "buy_secret_code_part") {
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };

          const challengeId = "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8";
          const settings = db.game_settings?.[0];
          if (!settings || !settings.marketplace_active) {
            return {
              data: null,
              error: {
                message: "La sfida è bloccata. Il Regista deve prima attivare il Marketplace.",
              },
            };
          }

          const match = db.team_code_matches?.find((m: any) => m.buyer_team_id === currentUserId);
          if (!match)
            return { data: null, error: { message: "Nessun partner di acquisto associato" } };

          const hasPurchased = db.code_purchase_transactions?.some(
            (t: any) => t.buyer_team_id === currentUserId,
          );
          if (hasPurchased)
            return { data: null, error: { message: "Hai già acquistato il frammento" } };

          const buyerTeam = db.teams.find((t: any) => t.id === currentUserId);
          if (!buyerTeam)
            return { data: null, error: { message: "Squadra compratrice non trovata" } };

          if ((buyerTeam.token_balance || 0) < match.token_cost) {
            return { data: null, error: { message: "Non possiedi abbastanza token" } };
          }

          const sellerTeam = db.teams.find((t: any) => t.id === match.seller_team_id);
          const activeTeamsCount = db.teams.filter((t: any) => t.active).length;
          const isOdd = activeTeamsCount % 2 !== 0;

          // Update balances
          buyerTeam.token_balance = (buyerTeam.token_balance || 0) - match.token_cost;
          if (!isOdd && sellerTeam) {
            sellerTeam.token_balance = (sellerTeam.token_balance || 0) + match.token_cost;
          }

          const finalCodeRecord = db.game_final_code?.[0];
          const fullCode = finalCodeRecord?.full_code || "4829167305";
          const digits =
            match.required_part === "FIRST_5" ? fullCode.slice(0, 5) : fullCode.slice(5);

          if (!db.code_purchase_transactions) db.code_purchase_transactions = [];
          db.code_purchase_transactions.push({
            id: uuid(),
            buyer_team_id: currentUserId,
            seller_team_id: match.seller_team_id,
            token_cost: match.token_cost,
            digits_received: digits,
            timestamp: new Date().toISOString(),
          });

          if (!db.submissions) db.submissions = [];
          db.submissions.push({
            id: uuid(),
            team_id: currentUserId,
            challenge_id: challengeId,
            risposta: `Acquistato frammento da ${sellerTeam?.nome_squadra || "Sconosciuta"} per ${match.token_cost} token`,
            stato_approvazione: "auto_approved",
            timestamp: new Date().toISOString(),
          });

          logActivity(
            db,
            currentUserId,
            `Squadra "${buyerTeam.nome_squadra}" ha acquistato il frammento dalla squadra "${sellerTeam?.nome_squadra || "Sconosciuta"}" per ${match.token_cost} Token. ${isOdd ? "(Pagamento Neutro)" : ""}`,
          );

          saveDb(db);
          return { data: { success: true, digits }, error: null };
        }

        if (fnName === "submit_secret_code_pin") {
          const { p_inserted_code } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autorizzato" } };

          const finalCodeRecord = db.game_final_code?.[0];
          const fullCode = finalCodeRecord?.full_code || "4829167305";
          const challengeId = "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8";

          const isCorrect = p_inserted_code?.trim() === fullCode;

          if (!db.pin_attempts) db.pin_attempts = [];
          db.pin_attempts.push({
            id: uuid(),
            team_id: currentUserId,
            inserted_code: p_inserted_code,
            timestamp: new Date().toISOString(),
            success: isCorrect,
          });

          const team = db.teams.find((t: any) => t.id === currentUserId);

          if (isCorrect) {
            if (!db.team_challenge_progress) db.team_challenge_progress = [];
            let progress = db.team_challenge_progress.find(
              (p: any) => p.team_id === currentUserId && p.challenge_id === challengeId,
            );
            if (!progress) {
              progress = {
                id: uuid(),
                team_id: currentUserId,
                challenge_id: challengeId,
                status: "COMPLETED",
                attempts: db.pin_attempts.filter((a: any) => a.team_id === currentUserId).length,
                created_at: new Date().toISOString(),
                completed_at: new Date().toISOString(),
              };
              db.team_challenge_progress.push(progress);
            } else {
              progress.status = "COMPLETED";
              progress.completed_at = new Date().toISOString();
            }

            const generalProg = db.team_progress.find(
              (p: any) => p.team_id === currentUserId && p.challenge_id === challengeId,
            );
            if (generalProg) {
              generalProg.stato = "completed";
              generalProg.completata_at = new Date().toISOString();
            } else {
              db.team_progress.push({
                id: uuid(),
                team_id: currentUserId,
                stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
                challenge_id: challengeId,
                stato: "completed",
                started_at: new Date().toISOString(),
                completata_at: new Date().toISOString(),
              });
            }

            logActivity(
              db,
              currentUserId,
              `La squadra "${team?.nome_squadra || "Sconosciuta"}" ha DECIFRATO IL CODICE SEGRETO ed ha completato la Tappa 3!`,
            );

            saveDb(db);
            return {
              data: {
                success: true,
                destination:
                  finalCodeRecord?.next_stage_destination ||
                  "Parco Giochi Madonna dei Fiori (lato piazzale grigio)",
              },
              error: null,
            };
          } else {
            logActivity(
              db,
              currentUserId,
              `La squadra "${team?.nome_squadra || "Sconosciuta"}" ha inserito un codice PIN errato: ${p_inserted_code}`,
            );
            saveDb(db);
            return {
              data: {
                success: false,
                message: "Codice errato. Controllate attentamente le cifre ricevute.",
              },
              error: null,
            };
          }
        }

        if (fnName === "admin_get_secret_code_dashboard") {
          const finalCodeRecord = db.game_final_code?.[0];
          const fullCode = finalCodeRecord?.full_code || "4829167305";
          const destination =
            finalCodeRecord?.next_stage_destination ||
            "Parco Giochi Madonna dei Fiori (lato piazzale grigio)";

          const parts = db.team_code_parts || [];
          const matches = db.team_code_matches || [];
          const transactions = db.code_purchase_transactions || [];
          const attempts = db.pin_attempts || [];

          const challengeId = "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8";
          const progress =
            db.team_progress?.filter(
              (p: any) => p.challenge_id === challengeId && p.stato === "completed",
            ) || [];

          const completedTeams = progress
            .map((p: any) => {
              const t = db.teams.find((team: any) => team.id === p.team_id);
              return {
                team_id: p.team_id,
                nome_squadra: t?.nome_squadra || "Sconosciuta",
                completed_at: p.completata_at,
              };
            })
            .sort(
              (a: any, b: any) =>
                new Date(a.completed_at).getTime() - new Date(b.completed_at).getTime(),
            );

          return {
            data: {
              full_code: fullCode,
              destination,
              parts,
              matches,
              transactions,
              attempts,
              completed_teams: completedTeams,
            },
            error: null,
          };
        }

        if (fnName === "admin_edit_secret_code_match") {
          const {
            p_buyer_team_id,
            p_seller_team_id,
            p_assigned_part_type,
            p_token_cost,
            p_admin_id,
          } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const finalCodeRecord = db.game_final_code?.[0];
          const fullCode = finalCodeRecord?.full_code || "4829167305";

          // Update part
          if (p_assigned_part_type) {
            const part = db.team_code_parts.find((p: any) => p.team_id === p_buyer_team_id);
            const codeVal =
              p_assigned_part_type === "FIRST_5" ? fullCode.slice(0, 5) : fullCode.slice(5);
            if (part) {
              part.part_type = p_assigned_part_type;
              part.code_part = codeVal;
            } else {
              db.team_code_parts.push({
                id: uuid(),
                team_id: p_buyer_team_id,
                code_part: codeVal,
                part_type: p_assigned_part_type,
                assigned_at: new Date().toISOString(),
              });
            }
          }

          // Update match
          const match = db.team_code_matches.find((m: any) => m.buyer_team_id === p_buyer_team_id);
          const buyerPart = db.team_code_parts.find((p: any) => p.team_id === p_buyer_team_id);
          const requiredPart = buyerPart?.part_type === "FIRST_5" ? "LAST_5" : "FIRST_5";

          if (match) {
            if (p_seller_team_id) match.seller_team_id = p_seller_team_id;
            match.required_part = requiredPart;
            if (p_token_cost !== undefined) match.token_cost = p_token_cost;
          } else {
            db.team_code_matches.push({
              buyer_team_id: p_buyer_team_id,
              seller_team_id: p_seller_team_id,
              required_part: requiredPart,
              token_cost: p_token_cost !== undefined ? p_token_cost : 3,
              created_at: new Date().toISOString(),
            });
          }

          const buyerT = db.teams.find((t: any) => t.id === p_buyer_team_id);
          logActivity(
            db,
            p_admin_id,
            `Regia ha modificato manualmente la configurazione del Codice Segreto per la squadra "${buyerT?.nome_squadra || "Sconosciuta"}"`,
          );

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "admin_force_complete_secret_code") {
          const { p_team_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          const challengeId = "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8";

          if (!db.team_challenge_progress) db.team_challenge_progress = [];
          const progress = db.team_challenge_progress.find(
            (p: any) => p.team_id === p_team_id && p.challenge_id === challengeId,
          );
          if (!progress) {
            db.team_challenge_progress.push({
              id: uuid(),
              team_id: p_team_id,
              challenge_id: challengeId,
              status: "COMPLETED",
              attempts: 1,
              created_at: new Date().toISOString(),
              completed_at: new Date().toISOString(),
            });
          } else {
            progress.status = "COMPLETED";
            progress.completed_at = new Date().toISOString();
          }

          const generalProg = db.team_progress.find(
            (p: any) => p.team_id === p_team_id && p.challenge_id === challengeId,
          );
          if (generalProg) {
            generalProg.stato = "completed";
            generalProg.completata_at = new Date().toISOString();
          } else {
            db.team_progress.push({
              id: uuid(),
              team_id: p_team_id,
              stage_id: "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c",
              challenge_id: challengeId,
              stato: "completed",
              started_at: new Date().toISOString(),
              completata_at: new Date().toISOString(),
            });
          }

          const team = db.teams.find((t: any) => t.id === p_team_id);
          logActivity(
            db,
            p_admin_id,
            `Regia ha FORZATO il completamento del Codice Segreto per la squadra "${team?.nome_squadra || "Sconosciuta"}"`,
          );

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "admin_edit_secret_code_settings") {
          const { p_full_code, p_destination, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!p_admin_id || !isAdminUser) {
            return { data: null, error: { message: "Non autorizzato" } };
          }

          if (!db.game_final_code) db.game_final_code = [];
          if (db.game_final_code.length === 0) {
            db.game_final_code.push({
              id: uuid(),
              full_code: p_full_code || "4829167305",
              next_stage_destination:
                p_destination || "Parco Giochi Madonna dei Fiori (lato piazzale grigio)",
              created_at: new Date().toISOString(),
            });
          } else {
            db.game_final_code[0].full_code = p_full_code || "4829167305";
            db.game_final_code[0].next_stage_destination =
              p_destination || "Parco Giochi Madonna dei Fiori (lato piazzale grigio)";
          }

          const first5 = (p_full_code || "4829167305").slice(0, 5);
          const last5 = (p_full_code || "4829167305").slice(5);
          db.team_code_parts?.forEach((part: any) => {
            part.code_part = part.part_type === "FIRST_5" ? first5 : last5;
          });

          logActivity(
            db,
            p_admin_id,
            `Regia ha modificato manualmente le impostazioni del PIN finale: ${p_full_code}`,
          );

          saveDb(db);
          return { data: { success: true }, error: null };
        }

        // ─── TAPPA 4 — ENIGMI RPCs ───────────────────────────────────────

        if (fnName === "submit_enigma_answer") {
          const { p_challenge_id, p_answer } = args;

          if (!currentUserId) return { data: null, error: { message: "Non autenticato" } };

          const solution = (db.enigma_solutions || []).find(
            (s: any) => s.challenge_id === p_challenge_id,
          );
          if (!solution)
            return { data: null, error: { message: "Soluzione non trovata per questo enigma" } };

          // Check if already completed
          const alreadyCompleted = (db.team_progress || []).some(
            (tp: any) =>
              tp.team_id === currentUserId &&
              tp.challenge_id === p_challenge_id &&
              tp.stato === "completed",
          );
          if (alreadyCompleted) {
            return {
              data: {
                is_correct: true,
                already_completed: true,
                attempt_number: 0,
                points: solution.punteggio,
              },
              error: null,
            };
          }

          // ── Idempotency / Double submit prevention ───────────────────────
          const now = Date.now();
          const lastAttempt = db.enigma_attempts
            .filter((a: any) => a.team_id === currentUserId && a.challenge_id === p_challenge_id)
            .sort(
              (a: any, b: any) =>
                new Date(b.submitted_at).getTime() - new Date(a.submitted_at).getTime(),
            )[0];

          if (lastAttempt) {
            const msSinceLast = now - new Date(lastAttempt.submitted_at).getTime();
            if (msSinceLast < 1500) {
              // Same answer check to be certain it is a duplicate
              const isSameAnswer = JSON.stringify(lastAttempt.answer) === JSON.stringify(p_answer);
              if (isSameAnswer) {
                return {
                  data: {
                    is_correct: lastAttempt.is_correct,
                    attempt_number: lastAttempt.attempt_number,
                    points: lastAttempt.is_correct ? solution.punteggio : 0,
                    already_completed: false,
                    is_duplicate: true,
                  },
                  error: null,
                };
              }
            }
          }

          // Count existing attempts
          if (!db.enigma_attempts) db.enigma_attempts = [];
          const existingAttempts = db.enigma_attempts.filter(
            (a: any) => a.team_id === currentUserId && a.challenge_id === p_challenge_id,
          );
          const attemptNumber = existingAttempts.length + 1;

          // ── Server-side answer verification ──────────────────────────────
          let isCorrect = false;
          if (solution.solution_type === "notes") {
            const correctNotes: string[] = solution.solution;
            const submittedNotes: string[] = Array.isArray(p_answer) ? p_answer : [];
            isCorrect =
              correctNotes.length === submittedNotes.length &&
              correctNotes.every(
                (n: string, i: number) => n.toLowerCase() === submittedNotes[i]?.toLowerCase(),
              );
          } else if (solution.solution_type === "directions") {
            const correctDirections: string[] = solution.solution;
            const submittedDirections: string[] = Array.isArray(p_answer) ? p_answer : [];
            isCorrect =
              correctDirections.length === submittedDirections.length &&
              correctDirections.every(
                (d: string, i: number) => d.toLowerCase() === submittedDirections[i]?.toLowerCase(),
              );
          } else if (solution.solution_type === "coordinates") {
            const correctCoords = solution.solution; // e.g. { lat: "44.71", lng: "7.84" }
            const submitted = p_answer || {};
            const norm = (val: any) =>
              String(val || "")
                .trim()
                .replace(",", ".");
            isCorrect =
              norm(correctCoords.lat) === norm(submitted.lat) &&
              norm(correctCoords.lng) === norm(submitted.lng);
          } else {
            const correctText = String(solution.solution).trim().toUpperCase().replace(/\s+/g, "");
            const submittedText = String(p_answer).trim().toUpperCase().replace(/\s+/g, "");
            isCorrect = correctText === submittedText;
          }

          // Record attempt
          db.enigma_attempts.push({
            id: uuid(),
            team_id: currentUserId,
            challenge_id: p_challenge_id,
            attempt_number: attemptNumber,
            answer: p_answer,
            is_correct: isCorrect,
            submitted_at: new Date().toISOString(),
          });

          const team = db.teams.find((t: any) => t.id === currentUserId);
          const challenge = db.challenges.find((c: any) => c.id === p_challenge_id);

          // Ensure progress record exists (started_at tracking)
          const progRecord = (db.team_progress || []).find(
            (tp: any) => tp.team_id === currentUserId && tp.challenge_id === p_challenge_id,
          );

          if (isCorrect) {
            if (!progRecord) {
              db.team_progress.push({
                id: uuid(),
                team_id: currentUserId,
                stage_id: challenge?.stage_id || null,
                challenge_id: p_challenge_id,
                stato: "completed",
                started_at: new Date().toISOString(),
                completata_at: new Date().toISOString(),
              });
            } else {
              db.team_progress = db.team_progress.map((tp: any) =>
                tp.team_id === currentUserId && tp.challenge_id === p_challenge_id
                  ? { ...tp, stato: "completed", completata_at: new Date().toISOString() }
                  : tp,
              );
            }

            // Assign points
            db.scores.push({
              id: uuid(),
              team_id: currentUserId,
              challenge_id: p_challenge_id,
              punti: solution.punteggio,
              motivazione: `Enigma risolto: ${challenge?.titolo || "Enigma"}`,
              created_at: new Date().toISOString(),
            });

            logActivity(
              db,
              currentUserId,
              `Squadra "${team?.nome_squadra || "?"}" ha risolto l'enigma "${challenge?.titolo || p_challenge_id}" al tentativo ${attemptNumber}.`,
              solution.punteggio,
            );
          } else {
            // Create progress record in "started" state if not yet tracking
            if (!progRecord) {
              db.team_progress.push({
                id: uuid(),
                team_id: currentUserId,
                stage_id: challenge?.stage_id || null,
                challenge_id: p_challenge_id,
                stato: "started",
                started_at: new Date().toISOString(),
                completata_at: null,
              });
            }

            // Apply wrong answer penalty if configured (e.g. -8 points for Stage 4)
            const penalty = challenge?.wrong_answer_penalty ?? 0;
            if (penalty !== 0) {
              db.scores.push({
                id: uuid(),
                team_id: currentUserId,
                challenge_id: p_challenge_id,
                punti: penalty,
                motivazione: `Risposta errata — ${challenge?.titolo || "Enigma"}`,
                created_at: new Date().toISOString(),
              });

              logActivity(
                db,
                currentUserId,
                `Squadra "${team?.nome_squadra || "?"}" ha ricevuto una penalità di ${penalty} PT per risposta errata su "${challenge?.titolo || p_challenge_id}".`,
                penalty,
              );
            }
          }

          saveDb(db);
          return {
            data: {
              is_correct: isCorrect,
              attempt_number: attemptNumber,
              points: isCorrect ? solution.punteggio : (challenge?.wrong_answer_penalty ?? 0),
              already_completed: false,
            },
            error: null,
          };
        }

        if (fnName === "submit_enigma_extra_answer") {
          const { p_answer } = args;
          if (!currentUserId) return { data: null, error: { message: "Non autenticato" } };

          const enigmaTx = db.marketplace_transactions?.find(
            (t: any) =>
              t.target_team_id === currentUserId &&
              t.item_id === "enigma_extra" &&
              t.stato === "completed",
          );

          if (!enigmaTx) {
            return {
              data: null,
              error: { message: "Nessun Enigma Extra attivo trovato per la tua squadra." },
            };
          }

          const correctText = "LANTERNA";
          const submittedText = String(p_answer || "")
            .trim()
            .toUpperCase()
            .replace(/\s+/g, "");
          const isCorrect = correctText === submittedText;

          if (isCorrect) {
            enigmaTx.stato = "used";
            if (!enigmaTx.outcome) {
              enigmaTx.outcome = {};
            }
            enigmaTx.outcome.solved_at = new Date().toISOString();
            enigmaTx.outcome.submitted_answer = p_answer;

            const team = db.teams.find((t: any) => t.id === currentUserId);
            logActivity(
              db,
              currentUserId,
              `La squadra "${team?.nome_squadra || "?"}" ha risolto l'Enigma Extra!`,
            );
            saveDb(db);
          }

          return {
            data: {
              is_correct: isCorrect,
            },
            error: null,
          };
        }

        if (fnName === "spin_unlucky_wheel") {
          if (!currentUserId) return { data: null, error: { message: "Non autenticato" } };

          // Find the active transaction
          const unluckyTx = db.marketplace_transactions?.find(
            (t: any) => t.target_team_id === currentUserId && t.item_id === "ruota_sfortunata",
          );

          if (!unluckyTx) {
            return {
              data: null,
              error: { message: "Nessuna Ruota Sfortunata attiva trovata per la tua squadra." },
            };
          }

          // If already spun, return the existing outcome immediately (Idempotency)
          if (unluckyTx.stato === "used") {
            return {
              data: {
                outcome: unluckyTx.outcome,
              },
              error: null,
            };
          }

          if (unluckyTx.stato !== "completed") {
            return { data: null, error: { message: "Transazione nello stato non valido." } };
          }

          // Random spin logic based on configured weights
          const outcomes = [
            { id: "freeze_2min", label: "❄️ FREEZE 2 MINUTI", weight: 20 },
            { id: "minus_20_points", label: "💸 -20 PUNTI", weight: 20 },
            { id: "minus_10_tokens", label: "🪙 -10 TOKEN", weight: 20 },
            { id: "plus_2_min", label: "⏱️ +2 MINUTI", weight: 15 },
            { id: "heavy_backpack", label: "🎒 ZAINO PESANTE (+3m)", weight: 15 },
            { id: "minus_10_points_minus_5_tokens", label: "💸 -10 PT & 🪙 -5 TK", weight: 10 },
          ];

          const totalWeight = outcomes.reduce((sum, o) => sum + o.weight, 0); // 100
          let rand = Math.random() * totalWeight;
          let selectedOutcome: any = outcomes[0];

          for (const o of outcomes) {
            if (rand < o.weight) {
              selectedOutcome = o;
              break;
            }
            rand -= o.weight;
          }

          const outcome = {
            id: selectedOutcome.id,
            label: selectedOutcome.label,
            spun_at: new Date().toISOString(),
          };

          // Apply selected outcome effects
          const team = db.teams.find((t: any) => t.id === currentUserId);
          if (!team) return { data: null, error: { message: "Squadra non trovata." } };

          if (selectedOutcome.id === "freeze_2min") {
            const startedAt = new Date().toISOString();
            const expiresAt = new Date(Date.now() + 120000).toISOString();
            team.freeze_started_at = startedAt;
            team.freeze_expires_at = expiresAt;
            team.freeze_duration_seconds = 120;

            (outcome as any).freeze_started_at = startedAt;
            (outcome as any).freeze_expires_at = expiresAt;
          } else if (selectedOutcome.id === "minus_20_points") {
            if (!db.scores) db.scores = [];
            const teamScores = db.scores.filter((s: any) => s.team_id === currentUserId);
            const teamCurrentPoints = teamScores.reduce((sum: number, s: any) => sum + s.punti, 0);
            const pointsToDeduct = Math.max(0, Math.min(20, teamCurrentPoints));
            if (pointsToDeduct > 0) {
              db.scores.push({
                id: uuid(),
                team_id: currentUserId,
                challenge_id: null,
                punti: -pointsToDeduct,
                motivazione: `Malus Ruota Sfortunata: −${pointsToDeduct} Punti`,
                created_at: new Date().toISOString(),
              });
            }
          } else if (selectedOutcome.id === "minus_10_tokens") {
            const currentTokens = team.token_balance ?? 50;
            team.token_balance = Math.max(0, currentTokens - 10);
            (outcome as any).old_tokens = currentTokens;
            (outcome as any).new_tokens = team.token_balance;
          } else if (selectedOutcome.id === "plus_2_min") {
            if (!db.time_penalties) db.time_penalties = [];
            db.time_penalties.push({
              id: uuid(),
              team_id: currentUserId,
              type: "TIME_PENALTY",
              duration: 120,
              source: "RUOTA_SFORTUNATA",
              created_at: new Date().toISOString(),
            });
          } else if (selectedOutcome.id === "heavy_backpack") {
            if (!db.time_penalties) db.time_penalties = [];
            db.time_penalties.push({
              id: uuid(),
              team_id: currentUserId,
              type: "TIME_PENALTY",
              duration: 180,
              source: "RUOTA_SFORTUNATA",
              created_at: new Date().toISOString(),
            });
          } else if (selectedOutcome.id === "minus_10_points_minus_5_tokens") {
            if (!db.scores) db.scores = [];
            const teamScores = db.scores.filter((s: any) => s.team_id === currentUserId);
            const teamCurrentPoints = teamScores.reduce((sum: number, s: any) => sum + s.punti, 0);
            const pointsToDeduct = Math.max(0, Math.min(10, teamCurrentPoints));
            if (pointsToDeduct > 0) {
              db.scores.push({
                id: uuid(),
                team_id: currentUserId,
                challenge_id: null,
                punti: -pointsToDeduct,
                motivazione: `Malus Ruota Sfortunata: −${pointsToDeduct} Punti`,
                created_at: new Date().toISOString(),
              });
            }
            const currentTokens = team.token_balance ?? 50;
            team.token_balance = Math.max(0, currentTokens - 5);
            (outcome as any).old_tokens = currentTokens;
            (outcome as any).new_tokens = team.token_balance;
          }

          // Mark transaction as used and save outcome
          unluckyTx.stato = "used";
          unluckyTx.outcome = outcome;

          // Assign +7 Punti Cattiveria to the attacker
          const attackerStageId = getTeamCurrentStageId(db, unluckyTx.buyer_team_id);
          addCattiveriaPoints(
            db,
            unluckyTx.buyer_team_id,
            attackerStageId,
            "malus",
            "ruota_sfortunata",
            unluckyTx.id,
            7,
            "Utilizzo Ruota Sfortunata (Spin eseguito dal bersaglio)",
          );

          logActivity(
            db,
            currentUserId,
            `La squadra "${team.nome_squadra}" ha girato la Ruota Sfortunata ottenendo: ${selectedOutcome.label}`,
          );
          saveDb(db);

          return {
            data: {
              outcome,
            },
            error: null,
          };
        }

        if (fnName === "get_enigma_state") {
          const { p_challenge_id, p_team_id } = args;
          const teamId = p_team_id || currentUserId;
          const attempts = (db.enigma_attempts || []).filter(
            (a: any) => a.team_id === teamId && a.challenge_id === p_challenge_id,
          );
          const progress = (db.team_progress || []).find(
            (tp: any) => tp.team_id === teamId && tp.challenge_id === p_challenge_id,
          );
          return {
            data: {
              attempts,
              is_completed: progress?.stato === "completed",
              started_at: progress?.started_at || null,
              completed_at: progress?.completata_at || null,
              attempt_count: attempts.length,
            },
            error: null,
          };
        }

        if (fnName === "admin_get_enigma_dashboard") {
          const { p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          const STAGE4_ID_CONST = "4b4b4c4d-5e5f-6061-7172-838485868788";
          const stage4Challenges = db.challenges
            .filter((c: any) => c.stage_id === STAGE4_ID_CONST)
            .sort((a: any, b: any) => a.ordine - b.ordine);

          const rows = db.teams.map((t: any) => {
            const enigmaProgress = stage4Challenges.map((c: any) => {
              const prog = (db.team_progress || []).find(
                (tp: any) => tp.team_id === t.id && tp.challenge_id === c.id,
              );
              const attempts = (db.enigma_attempts || []).filter(
                (a: any) => a.team_id === t.id && a.challenge_id === c.id,
              );
              return {
                challenge_id: c.id,
                titolo: c.titolo,
                ordine: c.ordine,
                stato: prog?.stato || "not_started",
                started_at: prog?.started_at || null,
                completed_at: prog?.completata_at || null,
                attempt_count: attempts.length,
                attempts,
              };
            });

            const completedCount = enigmaProgress.filter(
              (p: any) => p.stato === "completed",
            ).length;

            return {
              team_id: t.id,
              nome_squadra: t.nome_squadra,
              active: t.active,
              started: enigmaProgress.some((p: any) => p.stato !== "not_started"),
              completed_all: completedCount === stage4Challenges.length,
              enigmi_completati: completedCount,
              enigmi_totali: stage4Challenges.length,
              enigma_progress: enigmaProgress,
            };
          });

          return {
            data: {
              rows,
              enigma_solutions: (db.enigma_solutions || []).map((s: any) => ({
                challenge_id: s.challenge_id,
                solution_type: s.solution_type,
                // Only expose safe descriptors, NOT the actual answers
                hint:
                  s.solution_type === "text"
                    ? `${String(s.solution).slice(0, 3)}...`
                    : s.solution_type === "directions"
                      ? "[lucchetto]"
                      : s.solution_type === "coordinates"
                        ? "Lat: 44.71, Lng: 7.84"
                        : "[note]",
              })),
            },
            error: null,
          };
        }

        if (fnName === "admin_update_enigma_solution") {
          const { p_challenge_id, p_solution, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          if (!db.enigma_solutions)
            return { data: null, error: { message: "Tabella soluzioni non trovata" } };
          const sol = db.enigma_solutions.find((s: any) => s.challenge_id === p_challenge_id);
          if (!sol)
            return { data: null, error: { message: "Soluzione non trovata per questo enigma" } };

          sol.solution = String(p_solution).trim().toUpperCase();
          logActivity(
            db,
            p_admin_id,
            `Regia ha aggiornato la soluzione per l'enigma: challenge_id=${p_challenge_id}`,
          );
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "reset_cornhole_tournament") {
          const CORNHOLE_CHALLENGE_ID_CONST = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";
          if (db.cornhole_matches) {
            db.cornhole_matches = db.cornhole_matches.filter(
              (m: any) => m.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
            );
          }
          if (db.scores) {
            db.scores = db.scores.filter(
              (s: any) => s.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
            );
          }
          if (db.team_progress) {
            db.team_progress = db.team_progress.filter(
              (tp: any) => tp.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
            );
          }
          if (db.game_settings?.[0]) {
            db.game_settings[0].cornhole_special_bye_team_id = null;
          }
          logActivity(db, args.p_admin_id || "admin", "Torneo Cornhole resettato");
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "generate_cornhole_tournament") {
          const STAGE5_ID_CONST = "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c";
          const CORNHOLE_CHALLENGE_ID_CONST = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";

          if (!db.cornhole_matches) {
            db.cornhole_matches = [];
          }

          // Reset existing
          db.cornhole_matches = db.cornhole_matches.filter(
            (m: any) => m.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
          );
          if (db.scores) {
            db.scores = db.scores.filter(
              (s: any) => s.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
            );
          }
          if (db.team_progress) {
            db.team_progress = db.team_progress.filter(
              (tp: any) => tp.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
            );
          }

          const activeTeams = db.teams.filter((t: any) => t.active !== false);
          if (activeTeams.length < 2) {
            return {
              data: null,
              error: { message: "Sono necessarie almeno 2 squadre attive per generare il torneo." },
            };
          }

          const specialByeTeamId =
            args.p_special_bye_team_id ||
            db.game_settings?.[0]?.cornhole_special_bye_team_id ||
            null;
          if (db.game_settings?.[0]) {
            db.game_settings[0].cornhole_special_bye_team_id = specialByeTeamId;
          }

          const N = activeTeams.length;
          const K_main = Math.pow(2, Math.floor(Math.log2(N)));
          const P = N - K_main;
          const matchesToInsert: any[] = [];

          let pool = [...activeTeams];
          for (let i = pool.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const temp = pool[i];
            pool[i] = pool[j];
            pool[j] = temp;
          }

          if (P === 0) {
            const totalRounds = Math.log2(K_main);
            for (let r = 0; r < totalRounds; r++) {
              const matchesInRound = K_main / Math.pow(2, r + 1);
              for (let m = 0; m < matchesInRound; m++) {
                matchesToInsert.push({
                  id:
                    "match_cornhole_" + r + "_" + m + "_" + Math.random().toString(36).substr(2, 9),
                  stage_id: STAGE5_ID_CONST,
                  challenge_id: CORNHOLE_CHALLENGE_ID_CONST,
                  round: r,
                  match_index: m,
                  team1_id: null,
                  team2_id: null,
                  winner_id: null,
                  status: "pending",
                  completed_at: null,
                  is_special_bye: false,
                });
              }
            }

            let tIdx = 0;
            for (let m = 0; m < K_main / 2; m++) {
              const match = matchesToInsert.find((x: any) => x.round === 0 && x.match_index === m);
              if (!match) continue;
              match.team1_id = pool[tIdx++].id;
              match.team2_id = pool[tIdx++].id;
              match.status = "ready";
            }
          } else {
            const totalRounds = 1 + Math.log2(K_main);

            if (specialByeTeamId && pool.some((t: any) => t.id === specialByeTeamId)) {
              pool = pool.filter((t: any) => t.id !== specialByeTeamId);
            }

            const prelimTeams = pool.slice(0, 2 * P);
            const directTeams = [];
            if (specialByeTeamId && activeTeams.some((t: any) => t.id === specialByeTeamId)) {
              const spTeam = activeTeams.find((t: any) => t.id === specialByeTeamId);
              if (spTeam) directTeams.push(spTeam);
            }
            directTeams.push(...pool.slice(2 * P));

            // Round 0: P matches
            for (let m = 0; m < P; m++) {
              matchesToInsert.push({
                id: "match_cornhole_0_" + m + "_" + Math.random().toString(36).substr(2, 9),
                stage_id: STAGE5_ID_CONST,
                challenge_id: CORNHOLE_CHALLENGE_ID_CONST,
                round: 0,
                match_index: m,
                team1_id: prelimTeams[2 * m].id,
                team2_id: prelimTeams[2 * m + 1].id,
                winner_id: null,
                status: "ready",
                completed_at: null,
                is_special_bye: false,
              });
            }

            // Subsequent rounds
            for (let r = 1; r < totalRounds; r++) {
              const matchesInRound = K_main / Math.pow(2, r);
              for (let m = 0; m < matchesInRound; m++) {
                matchesToInsert.push({
                  id:
                    "match_cornhole_" + r + "_" + m + "_" + Math.random().toString(36).substr(2, 9),
                  stage_id: STAGE5_ID_CONST,
                  challenge_id: CORNHOLE_CHALLENGE_ID_CONST,
                  round: r,
                  match_index: m,
                  team1_id: null,
                  team2_id: null,
                  winner_id: null,
                  status: "pending",
                  completed_at: null,
                  is_special_bye: false,
                });
              }
            }

            // Seed Round 1
            let dtIdx = 0;
            for (let m = 0; m < P; m++) {
              const match = matchesToInsert.find((x: any) => x.round === 1 && x.match_index === m);
              if (match && directTeams[dtIdx]) {
                match.team1_id = directTeams[dtIdx++].id;
                match.team2_id = null;
                match.status = "pending";
                match.is_special_bye = match.team1_id === specialByeTeamId;
              }
            }
            for (let m = P; m < K_main / 2; m++) {
              const match = matchesToInsert.find((x: any) => x.round === 1 && x.match_index === m);
              if (match && directTeams[dtIdx] && directTeams[dtIdx + 1]) {
                match.team1_id = directTeams[dtIdx++].id;
                match.team2_id = directTeams[dtIdx++].id;
                match.status = "ready";
              }
            }
          }

          db.cornhole_matches.push(...matchesToInsert);
          logActivity(
            db,
            args.p_admin_id || "admin",
            "Regia ha generato il tabellone del Torneo Cornhole",
          );
          saveDb(db);
          return { data: matchesToInsert, error: null };
        }

        if (fnName === "get_cornhole_tournament") {
          const CORNHOLE_CHALLENGE_ID_CONST = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";
          if (!db.cornhole_matches) {
            db.cornhole_matches = [];
          }
          const matches = db.cornhole_matches.filter(
            (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
          );
          return { data: matches, error: null };
        }

        if (fnName === "submit_cornhole_match_result") {
          const { p_match_id, p_winner_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          const CORNHOLE_CHALLENGE_ID_CONST = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";
          const STAGE5_ID_CONST = "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c";

          const match = db.cornhole_matches.find((m: any) => m.id === p_match_id);
          if (!match) return { data: null, error: { message: "Match non trovato." } };

          if (match.status === "completed" && match.winner_id === p_winner_id) {
            return {
              data: db.cornhole_matches.filter(
                (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
              ),
              error: null,
            };
          }

          match.winner_id = p_winner_id;
          match.status = "completed";
          match.completed_at = new Date().toISOString();

          const challengeMatches = db.cornhole_matches.filter(
            (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
          );
          const maxRound = Math.max(...challengeMatches.map((m: any) => m.round));
          const r0Matches = challengeMatches.filter((m: any) => m.round === 0);
          const r1Matches = challengeMatches.filter((m: any) => m.round === 1);

          if (match.round < maxRound) {
            if (match.round === 0 && r0Matches.length < r1Matches.length) {
              const nextMatch = db.cornhole_matches.find(
                (m: any) =>
                  m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST &&
                  m.round === 1 &&
                  m.match_index === match.match_index,
              );
              if (nextMatch) {
                nextMatch.team2_id = p_winner_id;
                if (nextMatch.team1_id && nextMatch.team2_id) nextMatch.status = "ready";
              }
            } else {
              const nextRound = match.round + 1;
              const nextMatchIdx = Math.floor(match.match_index / 2);
              const nextMatch = db.cornhole_matches.find(
                (m: any) =>
                  m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST &&
                  m.round === nextRound &&
                  m.match_index === nextMatchIdx,
              );

              if (nextMatch) {
                if (match.match_index % 2 === 0) {
                  nextMatch.team1_id = p_winner_id;
                } else {
                  nextMatch.team2_id = p_winner_id;
                }
                if (nextMatch.team1_id && nextMatch.team2_id) {
                  nextMatch.status = "ready";
                }
              }
            }
          } else {
            // This was the final! Allocate points and complete challenge.
            const pointsAlreadyAssigned = db.scores.some(
              (s: any) => s.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
            );
            if (!pointsAlreadyAssigned) {
              // 20 points to the winner
              db.scores.push({
                id: "score_" + Math.random().toString(36).substr(2, 9),
                team_id: p_winner_id,
                challenge_id: CORNHOLE_CHALLENGE_ID_CONST,
                punti: 20,
                motivazione: "Vincitore Torneo Cornhole (Tappa 5)",
                created_at: new Date().toISOString(),
              });

              // 10 points to all other active teams
              const otherTeams = db.teams.filter(
                (t: any) => t.active !== false && t.id !== p_winner_id,
              );
              otherTeams.forEach((t: any) => {
                db.scores.push({
                  id: "score_" + Math.random().toString(36).substr(2, 9),
                  team_id: t.id,
                  challenge_id: CORNHOLE_CHALLENGE_ID_CONST,
                  punti: 10,
                  motivazione: "Partecipazione Torneo Cornhole (Tappa 5)",
                  created_at: new Date().toISOString(),
                });
              });

              // Complete challenge in team_progress for all active teams
              const activeTeams = db.teams.filter((t: any) => t.active !== false);
              activeTeams.forEach((t: any) => {
                const prog = db.team_progress.find(
                  (tp: any) =>
                    tp.team_id === t.id && tp.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
                );
                if (!prog) {
                  db.team_progress.push({
                    id: "progress_" + Math.random().toString(36).substr(2, 9),
                    team_id: t.id,
                    stage_id: STAGE5_ID_CONST,
                    challenge_id: CORNHOLE_CHALLENGE_ID_CONST,
                    stato: "completed",
                    started_at: new Date().toISOString(),
                    completata_at: new Date().toISOString(),
                  });
                } else {
                  prog.stato = "completed";
                  prog.completata_at = new Date().toISOString();
                }
              });
            }
          }

          logActivity(
            db,
            p_admin_id,
            `Match Cornhole ${p_match_id} completato con vincitore ${p_winner_id}`,
          );
          saveDb(db);
          return {
            data: db.cornhole_matches.filter(
              (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
            ),
            error: null,
          };
        }

        if (fnName === "rollback_cornhole_match_result") {
          const { p_match_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          const CORNHOLE_CHALLENGE_ID_CONST = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";

          const match = db.cornhole_matches.find((m: any) => m.id === p_match_id);
          if (!match) return { data: null, error: { message: "Match non trovato." } };

          if (match.status !== "completed") {
            return {
              data: db.cornhole_matches.filter(
                (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
              ),
              error: null,
            };
          }

          // Check if subsequent round match is already completed
          const challengeMatches = db.cornhole_matches.filter(
            (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
          );
          const maxRound = Math.max(...challengeMatches.map((m: any) => m.round));

          if (match.round < maxRound) {
            const nextRound = match.round + 1;
            const nextMatchIdx = Math.floor(match.match_index / 2);
            const nextMatch = db.cornhole_matches.find(
              (m: any) =>
                m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST &&
                m.round === nextRound &&
                m.match_index === nextMatchIdx,
            );

            if (nextMatch) {
              if (nextMatch.status === "completed") {
                return {
                  data: null,
                  error: {
                    message:
                      "Impossibile annullare: il turno successivo è già stato disputato. Annulla prima quel match.",
                  },
                };
              }
              // Reset the team slot in the next round
              if (match.match_index % 2 === 0) {
                nextMatch.team1_id = null;
              } else {
                nextMatch.team2_id = null;
              }
              nextMatch.status = "pending";
            }
          } else {
            // Rollback of the final: clear scores and team progress completion
            db.scores = db.scores.filter(
              (s: any) => s.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
            );
            const activeTeams = db.teams.filter((t: any) => t.active !== false);
            activeTeams.forEach((t: any) => {
              const prog = db.team_progress.find(
                (tp: any) => tp.team_id === t.id && tp.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
              );
              if (prog) {
                prog.stato = "started";
                prog.completata_at = null;
              }
            });
          }

          match.winner_id = null;
          match.status = "ready";
          match.completed_at = null;

          logActivity(db, p_admin_id, `Rollback match Cornhole ${p_match_id}`);
          saveDb(db);
          return {
            data: db.cornhole_matches.filter(
              (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
            ),
            error: null,
          };
        }

        if (fnName === "get_cornhole_settings") {
          const CORNHOLE_CHALLENGE_ID_CONST = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";
          const ENIGMA3_ID = "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9";

          const settings = db.game_settings?.[0];
          const specialByeTeamId = settings?.cornhole_special_bye_team_id || null;

          // Determine if the tournament has started (any non-bye match completed)
          const tournamentMatches =
            db.cornhole_matches?.filter(
              (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
            ) || [];
          const hasStarted = tournamentMatches.some(
            (m: any) => m.status === "completed" && m.team2_id !== null,
          );

          // Find the team that solved Challenge 4.3 first
          const completions = (db.team_progress || [])
            .filter(
              (tp: any) =>
                tp.challenge_id === ENIGMA3_ID && tp.stato === "completed" && tp.completata_at,
            )
            .sort(
              (a: any, b: any) =>
                new Date(a.completata_at).getTime() - new Date(b.completata_at).getTime(),
            );
          const firstPlaceTeamId = completions[0]?.team_id || null;

          return {
            data: {
              special_bye_team_id: specialByeTeamId,
              started: hasStarted,
              first_place_stage4_3: firstPlaceTeamId,
            },
            error: null,
          };
        }

        if (fnName === "set_cornhole_special_bye") {
          const { p_team_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          const CORNHOLE_CHALLENGE_ID_CONST = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";

          // Verify if tournament has already started
          const tournamentMatches =
            db.cornhole_matches?.filter(
              (m: any) => m.challenge_id === CORNHOLE_CHALLENGE_ID_CONST,
            ) || [];
          const hasStarted = tournamentMatches.some(
            (m: any) => m.status === "completed" && m.team2_id !== null,
          );
          if (hasStarted) {
            return {
              data: null,
              error: { message: "Impossibile modificare il vantaggio: il torneo è già iniziato." },
            };
          }

          if (!db.game_settings || db.game_settings.length === 0) {
            db.game_settings = [
              {
                id: "settings_01",
                marketplace_visible: false,
                marketplace_active: false,
                activated_at: null,
                activated_by: null,
                cornhole_special_bye_team_id: null,
              },
            ];
          }

          db.game_settings[0].cornhole_special_bye_team_id = p_team_id;

          // Clear previous tournament layout so it will regenerate with the new bye structure
          db.cornhole_matches = db.cornhole_matches.filter(
            (m: any) => m.challenge_id !== CORNHOLE_CHALLENGE_ID_CONST,
          );

          logActivity(
            db,
            p_admin_id,
            `Regia ha configurato il BYE speciale per la squadra: ${p_team_id || "nessuna"}`,
          );
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "reset_boxe_tournament") {
          const BOXE_CHALLENGE_ID_CONST = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";
          if (db.boxe_matches) {
            db.boxe_matches = db.boxe_matches.filter(
              (m: any) => m.challenge_id !== BOXE_CHALLENGE_ID_CONST,
            );
          }
          if (db.scores) {
            db.scores = db.scores.filter((s: any) => s.challenge_id !== BOXE_CHALLENGE_ID_CONST);
          }
          if (db.team_progress) {
            db.team_progress = db.team_progress.filter(
              (tp: any) => tp.challenge_id !== BOXE_CHALLENGE_ID_CONST,
            );
          }
          if (db.game_settings?.[0]) {
            db.game_settings[0].boxe_special_bye_team_id = null;
          }
          logActivity(db, args.p_admin_id || "admin", "Torneo Boxe resettato");
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "get_boxe_tournament") {
          const BOXE_CHALLENGE_ID_CONST = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";
          if (!db.boxe_matches) {
            db.boxe_matches = [];
          }
          const existingMatches = db.boxe_matches.filter(
            (m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST,
          );
          return { data: existingMatches, error: null };
        }

        if (fnName === "generate_boxe_tournament") {
          const STAGE5_ID_CONST = "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c";
          const BOXE_CHALLENGE_ID_CONST = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";

          if (!db.boxe_matches) {
            db.boxe_matches = [];
          }

          // Reset existing
          db.boxe_matches = db.boxe_matches.filter(
            (m: any) => m.challenge_id !== BOXE_CHALLENGE_ID_CONST,
          );
          if (db.scores) {
            db.scores = db.scores.filter((s: any) => s.challenge_id !== BOXE_CHALLENGE_ID_CONST);
          }
          if (db.team_progress) {
            db.team_progress = db.team_progress.filter(
              (tp: any) => tp.challenge_id !== BOXE_CHALLENGE_ID_CONST,
            );
          }

          const activeTeams = db.teams.filter((t: any) => t.active !== false);
          if (activeTeams.length < 2) {
            return {
              data: null,
              error: { message: "Sono necessarie almeno 2 squadre attive per generare il torneo." },
            };
          }

          const specialByeTeamId =
            args.p_special_bye_team_id || db.game_settings?.[0]?.boxe_special_bye_team_id || null;
          if (db.game_settings?.[0]) {
            db.game_settings[0].boxe_special_bye_team_id = specialByeTeamId;
          }

          const N = activeTeams.length;
          const K_main = Math.pow(2, Math.floor(Math.log2(N)));
          const P = N - K_main;
          const matchesToInsert: any[] = [];

          let pool = [...activeTeams];
          for (let i = pool.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const temp = pool[i];
            pool[i] = pool[j];
            pool[j] = temp;
          }

          if (P === 0) {
            const totalRounds = Math.log2(K_main);
            for (let r = 0; r < totalRounds; r++) {
              const matchesInRound = K_main / Math.pow(2, r + 1);
              for (let m = 0; m < matchesInRound; m++) {
                matchesToInsert.push({
                  id: "match_boxe_" + r + "_" + m + "_" + Math.random().toString(36).substr(2, 9),
                  stage_id: STAGE5_ID_CONST,
                  challenge_id: BOXE_CHALLENGE_ID_CONST,
                  round: r,
                  match_index: m,
                  team1_id: null,
                  team2_id: null,
                  winner_id: null,
                  status: "pending",
                  completed_at: null,
                  is_special_bye: false,
                });
              }
            }

            let tIdx = 0;
            for (let m = 0; m < K_main / 2; m++) {
              const match = matchesToInsert.find((x: any) => x.round === 0 && x.match_index === m);
              if (!match) continue;
              match.team1_id = pool[tIdx++].id;
              match.team2_id = pool[tIdx++].id;
              match.status = "ready";
            }
          } else {
            const totalRounds = 1 + Math.log2(K_main);

            if (specialByeTeamId && pool.some((t: any) => t.id === specialByeTeamId)) {
              pool = pool.filter((t: any) => t.id !== specialByeTeamId);
            }

            const prelimTeams = pool.slice(0, 2 * P);
            const directTeams = [];
            if (specialByeTeamId && activeTeams.some((t: any) => t.id === specialByeTeamId)) {
              const spTeam = activeTeams.find((t: any) => t.id === specialByeTeamId);
              if (spTeam) directTeams.push(spTeam);
            }
            directTeams.push(...pool.slice(2 * P));

            // Round 0: P matches
            for (let m = 0; m < P; m++) {
              matchesToInsert.push({
                id: "match_boxe_0_" + m + "_" + Math.random().toString(36).substr(2, 9),
                stage_id: STAGE5_ID_CONST,
                challenge_id: BOXE_CHALLENGE_ID_CONST,
                round: 0,
                match_index: m,
                team1_id: prelimTeams[2 * m].id,
                team2_id: prelimTeams[2 * m + 1].id,
                winner_id: null,
                status: "ready",
                completed_at: null,
                is_special_bye: false,
              });
            }

            // Subsequent rounds
            for (let r = 1; r < totalRounds; r++) {
              const matchesInRound = K_main / Math.pow(2, r);
              for (let m = 0; m < matchesInRound; m++) {
                matchesToInsert.push({
                  id: "match_boxe_" + r + "_" + m + "_" + Math.random().toString(36).substr(2, 9),
                  stage_id: STAGE5_ID_CONST,
                  challenge_id: BOXE_CHALLENGE_ID_CONST,
                  round: r,
                  match_index: m,
                  team1_id: null,
                  team2_id: null,
                  winner_id: null,
                  status: "pending",
                  completed_at: null,
                  is_special_bye: false,
                });
              }
            }

            // Seed Round 1
            let dtIdx = 0;
            for (let m = 0; m < P; m++) {
              const match = matchesToInsert.find((x: any) => x.round === 1 && x.match_index === m);
              if (match && directTeams[dtIdx]) {
                match.team1_id = directTeams[dtIdx++].id;
                match.team2_id = null;
                match.status = "pending";
                match.is_special_bye = match.team1_id === specialByeTeamId;
              }
            }
            for (let m = P; m < K_main / 2; m++) {
              const match = matchesToInsert.find((x: any) => x.round === 1 && x.match_index === m);
              if (match && directTeams[dtIdx] && directTeams[dtIdx + 1]) {
                match.team1_id = directTeams[dtIdx++].id;
                match.team2_id = directTeams[dtIdx++].id;
                match.status = "ready";
              }
            }
          }

          db.boxe_matches.push(...matchesToInsert);
          logActivity(
            db,
            args.p_admin_id || "admin",
            "Regia ha generato il tabellone del Torneo Boxe",
          );
          saveDb(db);
          return { data: matchesToInsert, error: null };
        }

        if (fnName === "submit_boxe_match_result") {
          const { p_match_id, p_winner_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          const STAGE5_ID_CONST = "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c";
          const BOXE_CHALLENGE_ID_CONST = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";

          const match = db.boxe_matches.find((m: any) => m.id === p_match_id);
          if (!match) return { data: null, error: { message: "Match non trovato." } };

          if (match.status === "completed" && match.winner_id === p_winner_id) {
            return {
              data: db.boxe_matches.filter((m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST),
              error: null,
            };
          }

          match.winner_id = p_winner_id;
          match.status = "completed";
          match.completed_at = new Date().toISOString();

          const challengeMatches = db.boxe_matches.filter(
            (m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST,
          );
          const maxRound = Math.max(...challengeMatches.map((m: any) => m.round));
          const r0Matches = challengeMatches.filter((m: any) => m.round === 0);
          const r1Matches = challengeMatches.filter((m: any) => m.round === 1);

          if (match.round < maxRound) {
            if (match.round === 0 && r0Matches.length < r1Matches.length) {
              const nextMatch = db.boxe_matches.find(
                (m: any) =>
                  m.challenge_id === BOXE_CHALLENGE_ID_CONST &&
                  m.round === 1 &&
                  m.match_index === match.match_index,
              );
              if (nextMatch) {
                nextMatch.team2_id = p_winner_id;
                if (nextMatch.team1_id && nextMatch.team2_id) nextMatch.status = "ready";
              }
            } else {
              const nextRound = match.round + 1;
              const nextMatchIdx = Math.floor(match.match_index / 2);
              const nextMatch = db.boxe_matches.find(
                (m: any) =>
                  m.challenge_id === BOXE_CHALLENGE_ID_CONST &&
                  m.round === nextRound &&
                  m.match_index === nextMatchIdx,
              );

              if (nextMatch) {
                if (match.match_index % 2 === 0) {
                  nextMatch.team1_id = p_winner_id;
                } else {
                  nextMatch.team2_id = p_winner_id;
                }
                if (nextMatch.team1_id && nextMatch.team2_id) {
                  nextMatch.status = "ready";
                }
              }
            }
          } else {
            // This was the final! Allocate points and complete challenge.
            const pointsAlreadyAssigned = db.scores.some(
              (s: any) => s.challenge_id === BOXE_CHALLENGE_ID_CONST,
            );
            if (!pointsAlreadyAssigned) {
              // 20 points to the winner
              db.scores.push({
                id: "score_boxe_" + Math.random().toString(36).substr(2, 9),
                team_id: p_winner_id,
                challenge_id: BOXE_CHALLENGE_ID_CONST,
                punti: 20,
                motivazione: "Vincitore Torneo Boxe Gonfiabile (Tappa 5)",
                created_at: new Date().toISOString(),
              });

              // 10 points to all other active teams
              const otherTeams = db.teams.filter(
                (t: any) => t.active !== false && t.id !== p_winner_id,
              );
              otherTeams.forEach((t: any) => {
                db.scores.push({
                  id: "score_boxe_" + Math.random().toString(36).substr(2, 9),
                  team_id: t.id,
                  challenge_id: BOXE_CHALLENGE_ID_CONST,
                  punti: 10,
                  motivazione: "Partecipazione Torneo Boxe Gonfiabile (Tappa 5)",
                  created_at: new Date().toISOString(),
                });
              });

              // Complete challenge in team_progress for all active teams
              const activeTeams = db.teams.filter((t: any) => t.active !== false);
              activeTeams.forEach((t: any) => {
                const prog = db.team_progress.find(
                  (tp: any) => tp.team_id === t.id && tp.challenge_id === BOXE_CHALLENGE_ID_CONST,
                );
                if (!prog) {
                  db.team_progress.push({
                    id: "progress_boxe_" + Math.random().toString(36).substr(2, 9),
                    team_id: t.id,
                    stage_id: STAGE5_ID_CONST,
                    challenge_id: BOXE_CHALLENGE_ID_CONST,
                    stato: "completed",
                    started_at: new Date().toISOString(),
                    completata_at: new Date().toISOString(),
                  });
                } else {
                  prog.stato = "completed";
                  prog.completata_at = new Date().toISOString();
                }
              });
            }
          }

          logActivity(
            db,
            p_admin_id,
            `Match Boxe Gonfiabile ${p_match_id} completato con vincitore ${p_winner_id}`,
          );
          saveDb(db);
          return {
            data: db.boxe_matches.filter((m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST),
            error: null,
          };
        }

        if (fnName === "rollback_boxe_match_result") {
          const { p_match_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          const BOXE_CHALLENGE_ID_CONST = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";

          const match = db.boxe_matches.find((m: any) => m.id === p_match_id);
          if (!match) return { data: null, error: { message: "Match non trovato." } };

          if (match.status !== "completed") {
            return {
              data: db.boxe_matches.filter((m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST),
              error: null,
            };
          }

          // Check if subsequent round match is already completed
          const challengeMatches = db.boxe_matches.filter(
            (m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST,
          );
          const maxRound = Math.max(...challengeMatches.map((m: any) => m.round));

          if (match.round < maxRound) {
            const nextRound = match.round + 1;
            const nextMatchIdx = Math.floor(match.match_index / 2);
            const nextMatch = db.boxe_matches.find(
              (m: any) =>
                m.challenge_id === BOXE_CHALLENGE_ID_CONST &&
                m.round === nextRound &&
                m.match_index === nextMatchIdx,
            );

            if (nextMatch) {
              if (nextMatch.status === "completed") {
                return {
                  data: null,
                  error: {
                    message:
                      "Impossibile annullare: il turno successivo è già stato disputato. Annulla prima quel match.",
                  },
                };
              }
              // Reset the team slot in the next round
              if (match.match_index % 2 === 0) {
                nextMatch.team1_id = null;
              } else {
                nextMatch.team2_id = null;
              }
              nextMatch.status = "pending";
            }
          } else {
            // Rollback of the final: clear scores and team progress completion
            db.scores = db.scores.filter((s: any) => s.challenge_id !== BOXE_CHALLENGE_ID_CONST);
            const activeTeams = db.teams.filter((t: any) => t.active !== false);
            activeTeams.forEach((t: any) => {
              const prog = db.team_progress.find(
                (tp: any) => tp.team_id === t.id && tp.challenge_id === BOXE_CHALLENGE_ID_CONST,
              );
              if (prog) {
                prog.stato = "started";
                prog.completata_at = null;
              }
            });
          }

          match.winner_id = null;
          match.status = "ready";
          match.completed_at = null;

          logActivity(db, p_admin_id, `Rollback match Boxe Gonfiabile ${p_match_id}`);
          saveDb(db);
          return {
            data: db.boxe_matches.filter((m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST),
            error: null,
          };
        }

        if (fnName === "get_boxe_settings") {
          const BOXE_CHALLENGE_ID_CONST = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";
          const ENIGMA3_ID = "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9";

          const settings = db.game_settings?.[0];
          const specialByeTeamId = settings?.boxe_special_bye_team_id || null;

          // Determine if the tournament has started
          const tournamentMatches =
            db.boxe_matches?.filter((m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST) || [];
          const hasStarted = tournamentMatches.some(
            (m: any) => m.status === "completed" && m.team2_id !== null,
          );

          // Find the team that solved Challenge 4.3 first
          const completions = (db.team_progress || [])
            .filter(
              (tp: any) =>
                tp.challenge_id === ENIGMA3_ID && tp.stato === "completed" && tp.completata_at,
            )
            .sort(
              (a: any, b: any) =>
                new Date(a.completata_at).getTime() - new Date(b.completata_at).getTime(),
            );
          const firstPlaceTeamId = completions[0]?.team_id || null;

          return {
            data: {
              special_bye_team_id: specialByeTeamId,
              started: hasStarted,
              first_place_stage4_3: firstPlaceTeamId,
            },
            error: null,
          };
        }

        if (fnName === "set_boxe_special_bye") {
          const { p_team_id, p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser) return { data: null, error: { message: "Non autorizzato" } };

          const BOXE_CHALLENGE_ID_CONST = "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0";

          // Verify if tournament has already started
          const tournamentMatches =
            db.boxe_matches?.filter((m: any) => m.challenge_id === BOXE_CHALLENGE_ID_CONST) || [];
          const hasStarted = tournamentMatches.some(
            (m: any) => m.status === "completed" && m.team2_id !== null,
          );
          if (hasStarted) {
            return {
              data: null,
              error: { message: "Impossibile modificare il vantaggio: il torneo è già iniziato." },
            };
          }

          if (!db.game_settings || db.game_settings.length === 0) {
            db.game_settings = [
              {
                id: "settings_01",
                marketplace_visible: false,
                marketplace_active: false,
                activated_at: null,
                activated_by: null,
                cornhole_special_bye_team_id: null,
                boxe_special_bye_team_id: null,
              },
            ];
          }

          db.game_settings[0].boxe_special_bye_team_id = p_team_id;

          // Clear previous tournament layout so it will regenerate with the new random structure
          db.boxe_matches = db.boxe_matches.filter(
            (m: any) => m.challenge_id !== BOXE_CHALLENGE_ID_CONST,
          );

          logActivity(
            db,
            p_admin_id,
            `Regia ha configurato il BYE speciale Boxe per la squadra: ${p_team_id || "nessuna"}`,
          );
          saveDb(db);
          return { data: { success: true }, error: null };
        }

        if (fnName === "play_jackpot") {
          const { p_team_id, p_puntata } = args;
          const JACKPOT_CHALLENGE_ID = "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0";

          if (!db.jackpot_plays) {
            db.jackpot_plays = [];
          }

          // Check if team has already played
          const alreadyPlayed = db.jackpot_plays.some(
            (p: any) => p.team_id === p_team_id && p.challenge_id === JACKPOT_CHALLENGE_ID,
          );
          if (alreadyPlayed) {
            return { data: null, error: { message: "Giocata già effettuata", code: "409" } };
          }

          const team = db.teams.find((t: any) => t.id === p_team_id);
          if (!team || team.active === false) {
            return { data: null, error: { message: "Squadra non trovata o inattiva" } };
          }

          // Calculate current score
          const currentScore =
            db.scores
              ?.filter((s: any) => s.team_id === p_team_id)
              .reduce((sum: number, s: any) => sum + s.punti, 0) || 0;

          const puntataNum = Number(p_puntata);
          if (isNaN(puntataNum) || puntataNum < 5 || puntataNum > 20) {
            return {
              data: null,
              error: { message: "La puntata deve essere compresa tra 5 e 20 punti." },
            };
          }

          if (puntataNum > currentScore) {
            return {
              data: null,
              error: { message: "Non puoi scommettere più punti di quelli che possiedi." },
            };
          }

          // Generate 3 symbols randomly and equiprobably from ['🍒', '🍋', '🔔', '💎']
          const pool = ["🍒", "🍋", "🔔", "💎"];
          const sym1 = pool[Math.floor(Math.random() * 4)];
          const sym2 = pool[Math.floor(Math.random() * 4)];
          const sym3 = pool[Math.floor(Math.random() * 4)];
          const simboliStr = `${sym1},${sym2},${sym3}`;

          const isWin = sym1 === sym2 && sym2 === sym3;
          const risultato = isWin ? "vinta" : "persa";
          const variazione = isWin ? puntataNum : -puntataNum;
          const nuovoPunteggio = currentScore + variazione;

          const timestamp = new Date().toISOString();

          // Save play
          const newPlay = {
            team_id: p_team_id,
            challenge_id: JACKPOT_CHALLENGE_ID,
            puntata: puntataNum,
            simboli: simboliStr,
            risultato: risultato,
            variazione: variazione,
            punteggio_precedente: currentScore,
            punteggio_attuale: nuovoPunteggio,
            timestamp: timestamp,
          };
          db.jackpot_plays.push(newPlay);

          // Save points score event
          if (!db.scores) {
            db.scores = [];
          }
          db.scores.push({
            id: "score_jackpot_" + Math.random().toString(36).substr(2, 9),
            team_id: p_team_id,
            challenge_id: JACKPOT_CHALLENGE_ID,
            punti: variazione,
            motivazione: `Jackpot della Regia: ${risultato.toUpperCase()} (${sym1} ${sym2} ${sym3})`,
            created_at: timestamp,
          });

          // Mark challenge as completed in team_progress
          if (!db.team_progress) {
            db.team_progress = [];
          }
          const progressIndex = db.team_progress.findIndex(
            (tp: any) => tp.team_id === p_team_id && tp.challenge_id === JACKPOT_CHALLENGE_ID,
          );
          if (progressIndex >= 0) {
            db.team_progress[progressIndex].stato = "completed";
            db.team_progress[progressIndex].completata_at = timestamp;
          } else {
            db.team_progress.push({
              id: "tp_jackpot_" + Math.random().toString(36).substr(2, 9),
              team_id: p_team_id,
              challenge_id: JACKPOT_CHALLENGE_ID,
              stato: "completed",
              completata_at: timestamp,
              started_at: timestamp,
            });
          }

          logActivity(
            db,
            p_team_id,
            `Ha giocato al Jackpot scommettendo ${puntataNum} PT: ${risultato.toUpperCase()} (${sym1}${sym2}${sym3})`,
          );
          saveDb(db);

          return { data: newPlay, error: null };
        }

        if (fnName === "get_jackpot_state") {
          const { p_team_id } = args;
          const JACKPOT_CHALLENGE_ID = "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0";

          if (!db.jackpot_plays) {
            db.jackpot_plays = [];
          }

          const play =
            db.jackpot_plays.find(
              (p: any) => p.team_id === p_team_id && p.challenge_id === JACKPOT_CHALLENGE_ID,
            ) || null;
          const currentScore =
            db.scores
              ?.filter((s: any) => s.team_id === p_team_id)
              .reduce((sum: number, s: any) => sum + s.punti, 0) || 0;

          return {
            data: {
              played: play !== null,
              play: play,
              current_score: currentScore,
            },
            error: null,
          };
        }

        if (fnName === "get_jackpot_plays") {
          const { p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdminUser =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdminUser)
            return { data: null, error: { message: "Non autorizzato", code: "403" } };

          const JACKPOT_CHALLENGE_ID = "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0";
          if (!db.jackpot_plays) {
            db.jackpot_plays = [];
          }

          const plays = db.jackpot_plays.filter(
            (p: any) => p.challenge_id === JACKPOT_CHALLENGE_ID,
          );
          return { data: plays, error: null };
        }

        if (fnName === "get_report_status") {
          const isPublished = db.game_report?.state === "PUBLISHED_FINAL";
          return {
            data: {
              state: db.game_report?.state || "PRIVATE_LIVE",
              is_published: isPublished,
              published_at: db.game_report?.published_at || null,
            },
            error: null,
          };
        }

        if (fnName === "get_game_report") {
          const { p_user_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdmin =
            p_user_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_user_id && ur.role === "admin");
          const isPublished = db.game_report?.state === "PUBLISHED_FINAL";

          // If not admin and not published -> Forbidden
          if (!isAdmin && !isPublished) {
            return {
              data: null,
              error: {
                message: "Il Resoconto Gara non è ancora stato pubblicato dalla Regia.",
                code: "403",
              },
            };
          }

          // If published, return the frozen snapshot
          if (isPublished && db.game_report?.snapshot) {
            return {
              data: {
                state: "PUBLISHED_FINAL",
                published_at: db.game_report.published_at,
                published_by: db.game_report.published_by,
                is_published: true,
                report: db.game_report.snapshot,
              },
              error: null,
            };
          }

          // Otherwise (Admin in LIVE mode), generate live report
          const liveReport = generateGameReport(db);
          return {
            data: {
              state: db.game_report?.state || "PRIVATE_LIVE",
              published_at: null,
              published_by: null,
              is_published: false,
              report: liveReport,
            },
            error: null,
          };
        }

        if (fnName === "publish_game_report") {
          const { p_admin_id } = args;
          const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
          const isAdmin =
            p_admin_id === ADMIN_ID ||
            db.user_roles?.some((ur: any) => ur.user_id === p_admin_id && ur.role === "admin");
          if (!isAdmin) {
            return { data: null, error: { message: "Non autorizzato", code: "403" } };
          }

          // Idempotency: If already published, return existing without re-saving
          if (db.game_report?.state === "PUBLISHED_FINAL") {
            return {
              data: {
                success: true,
                alreadyPublished: true,
                published_at: db.game_report.published_at,
              },
              error: null,
            };
          }

          // Generate the frozen snapshot
          const snapshot = generateGameReport(db);
          const publishedAt = new Date().toISOString();

          db.game_report = {
            state: "PUBLISHED_FINAL",
            published_at: publishedAt,
            published_by: p_admin_id,
            snapshot,
          };

          logActivity(
            db,
            null,
            `RESOCONTO_PUBLISHED: La Regia ha pubblicato ufficialmente il Resoconto Finale della Gara.`,
          );

          saveDb(db);
          return {
            data: {
              success: true,
              published_at: publishedAt,
            },
            error: null,
          };
        }
      }

      return { error: "Unknown action" };
    } catch (err: any) {
      return { error: err.message };
    }
  });
