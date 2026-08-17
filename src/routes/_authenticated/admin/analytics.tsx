import { createFileRoute } from "@tanstack/react-router";
import { useAdminContext } from "../admin";
import { Printer } from "lucide-react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  PieChart,
  Pie,
  Cell
} from "recharts";

export const Route = createFileRoute("/_authenticated/admin/analytics")({
  component: AdminAnalyticsPage,
});

function AdminAnalyticsPage() {
  const { stages, challenges, allTeams, allScores, allProgress, allSubmissions } = useAdminContext();

  const stagesList = stages.data ?? [];
  const challengesList = challenges.data ?? [];
  const teamsList = allTeams.data ?? [];
  const scoresList = allScores.data ?? [];
  const progressList = allProgress.data ?? [];
  const submissionsList = allSubmissions.data ?? [];

  // ── 1. GENERAL METRICS ────────────────────────────────────────────────────
  const totalStages = stagesList.length;
  const totalChallenges = challengesList.length;
  const activeTeams = teamsList.filter((t: any) => t.active).length;
  const totalPoints = challengesList.reduce((sum: number, c: any) => sum + (c.punteggio_massimo || 0), 0);

  // Avg points per team (from allScores)
  const teamIds = [...new Set(scoresList.map((s: any) => s.team_id))] as string[];
  const avgPointsPerTeam = teamIds.length > 0
    ? Math.round(
        teamIds.reduce((sum, tid) => {
          const pts = scoresList.filter((s: any) => s.team_id === tid).reduce((a: number, s: any) => a + (s.punti || 0), 0);
          return sum + pts;
        }, 0) / teamIds.length
      )
    : 0;

  // Pending photos to review
  const pendingPhotoCount = submissionsList.filter((s: any) =>
    (s.stato_approvazione === "pending" || s.stato_approvazione === null) &&
    (s.challenges?.tipo_sfida === "photo" || s.challenges?.tipo_sfida === "living_poster")
  ).length;

  // ── 2. STAGE BREAKDOWN ────────────────────────────────────────────────────
  const stageBreakdown = stagesList.map((st: any) => {
    const stChallenges = challengesList.filter((c: any) => c.stage_id === st.id);
    const pts = stChallenges.reduce((sum: number, c: any) => sum + (c.punteggio_massimo || 0), 0);
    const percentage = totalPoints > 0 ? ((pts / totalPoints) * 100).toFixed(2) : "0.00";
    return {
      name: st.nome_tappa || st.title || `Tappa ${st.ordine}`,
      challengesCount: stChallenges.length,
      maxPoints: pts,
      weight: parseFloat(percentage),
    };
  });

  // ── 3. CATEGORY PIE DATA ──────────────────────────────────────────────────
  const categories: Record<string, { count: number; points: number; types: string[] }> = {
    "Prove Abilità": { count: 0, points: 0, types: ["quiz", "emoji_movies", "rebus"] },
    "Prove Fortuna": { count: 0, points: 0, types: ["ruota", "casuale"] },
    "Prove Sociali": { count: 0, points: 0, types: ["photo", "living_poster", "social"] },
    "Prove Strategiche": { count: 0, points: 0, types: ["team_setup", "codice", "banca"] },
    "Prove Velocità": { count: 0, points: 0, types: ["velocita"] },
  };

  challengesList.forEach((c: any) => {
    const type = c.tipo_sfida || "";
    let categorized = false;
    Object.entries(categories).forEach(([catName, catObj]) => {
      if (catObj.types.includes(type) || (catName === "Prove Abilità" && type.includes("enigma"))) {
        catObj.count++;
        catObj.points += (c.punteggio_massimo || 0);
        categorized = true;
      }
    });
    if (!categorized) {
      if (type === "banca" || type === "codice" || type === "team_setup") {
        categories["Prove Strategiche"]!.count++;
        categories["Prove Strategiche"]!.points += (c.punteggio_massimo || 0);
      } else if (type === "social" || type === "living_poster" || type === "photo") {
        categories["Prove Sociali"]!.count++;
        categories["Prove Sociali"]!.points += (c.punteggio_massimo || 0);
      } else {
        categories["Prove Abilità"]!.count++;
        categories["Prove Abilità"]!.points += (c.punteggio_massimo || 0);
      }
    }
  });

  const categoryData = Object.entries(categories)
    .map(([name, cat]) => ({
      name,
      value: cat.points,
      count: cat.count,
      weight: totalPoints > 0 ? parseFloat(((cat.points / totalPoints) * 100).toFixed(2)) : 0,
    }))
    .filter((c) => c.value > 0);

  const COLORS = ["#0088FE", "#00C49F", "#FFBB28", "#FF8042", "#8884d8"];

  // ── NEW SECTION 2: CHALLENGE STATS ────────────────────────────────────────
  const challengeStats = challengesList.map((c: any) => {
    const stage = stagesList.find((st: any) => st.id === c.stage_id);
    const stageName = stage ? (stage.nome_tappa || stage.title || `Tappa ${stage.ordine}`) : "—";

    const completions = progressList.filter(
      (p: any) => p.challenge_id === c.id && p.stato === "completed"
    ).length;

    const pct = activeTeams > 0 ? Math.round((completions / activeTeams) * 100) : 0;

    const challengeScores = scoresList.filter((s: any) => s.challenge_id === c.id);
    const totalAssigned = challengeScores.reduce((sum: number, s: any) => sum + (s.punti || 0), 0);
    const positiveScores = challengeScores.filter((s: any) => (s.punti || 0) > 0);
    const avgAssigned =
      positiveScores.length > 0
        ? Math.round(positiveScores.reduce((sum: number, s: any) => sum + s.punti, 0) / positiveScores.length)
        : null;

    return {
      id: c.id,
      titolo: c.titolo || "—",
      stageName,
      tipo: c.tipo_sfida || "—",
      maxPoints: c.punteggio_massimo || 0,
      completions,
      pct,
      totalAssigned,
      avgAssigned,
    };
  });

  // ── NEW SECTION 3: TEAM LEADERBOARD ──────────────────────────────────────
  interface TeamRow {
    id: string;
    nome_squadra: string;
    token_balance: number;
    completedChallenges: number;
    totalPoints: number;
    pendingPoints: number;
    currentStage: string;
  }

  const teamLeaderboard: TeamRow[] = teamsList
    .filter((t: any) => t.active)
    .map((t: any) => {
      const teamProgress = progressList.filter((p: any) => p.team_id === t.id);
      const completedChallenges = teamProgress.filter((p: any) => p.stato === "completed").length;

      const teamScores = scoresList.filter((s: any) => s.team_id === t.id);
      const totalPts = teamScores.reduce((sum: number, s: any) => sum + (s.punti || 0), 0);
      const pendingPts = teamScores.filter((s: any) => (s.punti || 0) === 0).length;

      // Determine current stage: find the first stage not fully completed
      let currentStage = "—";
      const sortedStages = [...stagesList].sort((a: any, b: any) => a.ordine - b.ordine);
      for (const st of sortedStages) {
        const stageChallenges = challengesList.filter((c: any) => c.stage_id === st.id);
        if (stageChallenges.length === 0) continue;
        const allCompleted = stageChallenges.every((c: any) =>
          teamProgress.some((p: any) => p.challenge_id === c.id && p.stato === "completed")
        );
        if (!allCompleted) {
          currentStage = st.nome_tappa || st.title || `Tappa ${st.ordine}`;
          break;
        }
        currentStage = "✅ Completata";
      }

      return {
        id: t.id,
        nome_squadra: t.nome_squadra || "—",
        token_balance: t.token_balance ?? 0,
        completedChallenges,
        totalPoints: totalPts,
        pendingPoints: pendingPts,
        currentStage,
      };
    })
    .sort((a: TeamRow, b: TeamRow) => b.totalPoints - a.totalPoints);

  // ── 4. CLASSIFICATION CARDS ───────────────────────────────────────────────

  const handlePrintReport = () => {
    window.print();
  };

  const tipoBadgeColor = (tipo: string) => {
    if (tipo === "photo" || tipo === "living_poster") return "bg-purple-500/20 text-purple-300";
    if (tipo === "quiz") return "bg-blue-500/20 text-blue-300";
    if (tipo === "ruota" || tipo === "casuale") return "bg-yellow-500/20 text-yellow-300";
    if (tipo === "banca" || tipo === "codice") return "bg-red-500/20 text-red-300";
    if (tipo === "team_setup") return "bg-zinc-500/20 text-zinc-300";
    return "bg-zinc-700/30 text-zinc-400";
  };

  return (
    <div className="space-y-6 animate-pop-in print-container">
      {/* CSS Print Styles */}
      <style dangerouslySetInnerHTML={{ __html: `
        @media print {
          body {
            background: white !important;
            color: black !important;
          }
          .print\\:hidden, header, nav, aside, button, .no-print {
            display: none !important;
          }
          .print-container {
            padding: 0 !important;
            margin: 0 !important;
            background: white !important;
          }
          .surface {
            background: white !important;
            border: none !important;
            color: black !important;
            box-shadow: none !important;
            padding: 0 !important;
            margin-bottom: 2rem !important;
            page-break-inside: avoid;
          }
          h1, h2, h3, h4, th, td {
            color: black !important;
          }
          table {
            border-collapse: collapse !important;
            width: 100% !important;
          }
          th, td {
            border: 1px solid #ddd !important;
            padding: 8px !important;
          }
          .recharts-responsive-container {
            width: 100% !important;
            height: 250px !important;
            page-break-inside: avoid;
          }
        }
      `}} />

      {/* REPORT HEADER ACTIONS */}
      <div className="flex justify-between items-center no-print">
        <div>
          <h2 className="text-xl font-extrabold text-foreground uppercase tracking-wider">
            📊 Analisi Gara &amp; Statistiche Live
          </h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            Report completo del sistema dei punteggi, performance delle squadre e stato delle sfide.
          </p>
        </div>
        <button
          onClick={handlePrintReport}
          className="px-4 py-2 bg-primary/10 hover:bg-primary/20 text-primary border border-primary/20 rounded-xl font-bold text-xs flex items-center gap-1.5 cursor-pointer transition-all"
        >
          <Printer className="size-4" />
          <span>Stampa / Esporta PDF</span>
        </button>
      </div>

      {/* ─── 1. PANORAMICA GENERALE ─── */}
      <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <h3 className="text-base font-extrabold text-foreground uppercase tracking-widest border-b border-border/20 pb-2">
          1. Panoramica Generale
        </h3>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/40">
            <p className="text-[10px] uppercase font-bold text-zinc-500 tracking-wider">Tappe Totali</p>
            <p className="text-2xl font-black text-primary mt-1">{totalStages}</p>
          </div>
          <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/40">
            <p className="text-[10px] uppercase font-bold text-zinc-500 tracking-wider">Sfide Totali</p>
            <p className="text-2xl font-black text-foreground mt-1">{totalChallenges}</p>
          </div>
          <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/40">
            <p className="text-[10px] uppercase font-bold text-zinc-500 tracking-wider">Squadre Attive</p>
            <p className="text-2xl font-black text-success mt-1">{activeTeams}</p>
          </div>
          <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/40">
            <p className="text-[10px] uppercase font-bold text-zinc-500 tracking-wider">Punti in Palio</p>
            <p className="text-2xl font-black text-yellow-500 mt-1">{totalPoints} PT</p>
          </div>
        </div>

        {/* Extra stat cards */}
        <div className="grid grid-cols-2 gap-4 text-center">
          <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/40">
            <p className="text-[10px] uppercase font-bold text-zinc-500 tracking-wider">Punti Medi / Squadra</p>
            <p className="text-2xl font-black text-cyan-400 mt-1">{avgPointsPerTeam} PT</p>
            <p className="text-[10px] text-zinc-600 mt-0.5">su squadre con almeno 1 punteggio</p>
          </div>
          <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/40">
            <p className="text-[10px] uppercase font-bold text-zinc-500 tracking-wider">📸 Foto in Attesa</p>
            <p className={`text-2xl font-black mt-1 ${pendingPhotoCount > 0 ? "text-orange-400" : "text-success"}`}>
              {pendingPhotoCount}
            </p>
            <p className="text-[10px] text-zinc-600 mt-0.5">foto / locandine da approvare</p>
          </div>
        </div>

        {/* Stage breakdown table */}
        <div className="overflow-x-auto pt-2">
          <table className="w-full text-left border-collapse text-xs md:text-sm">
            <thead>
              <tr className="border-b border-border/40 text-[10px] text-muted-foreground uppercase font-black tracking-widest">
                <th className="pb-3 pr-4">Tappa</th>
                <th className="pb-3 pr-4 text-center">Numero Sfide</th>
                <th className="pb-3 pr-4 text-center">Punti Massimi Ottenibili</th>
                <th className="pb-3 text-right">Peso Percentuale</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/10">
              {stageBreakdown.map((row: any, idx: number) => (
                <tr key={idx} className="hover:bg-zinc-900/10">
                  <td className="py-3 pr-4 font-bold text-foreground">{row.name}</td>
                  <td className="py-3 pr-4 text-center font-semibold text-zinc-300">{row.challengesCount}</td>
                  <td className="py-3 pr-4 text-center font-bold text-yellow-500">{row.maxPoints} PT</td>
                  <td className="py-3 text-right font-mono text-zinc-400">{row.weight.toFixed(2)}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ─── CHARTS SECTION ─── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Bar chart: points per stage */}
        <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
          <h4 className="text-xs font-black uppercase text-zinc-400 tracking-widest">
            Distribuzione Punti per Tappa
          </h4>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={stageBreakdown} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
                <XAxis dataKey="name" stroke="#71717a" fontSize={10} tickFormatter={(v) => v.split(" ")[0]} />
                <YAxis stroke="#71717a" fontSize={10} />
                <RechartsTooltip contentStyle={{ backgroundColor: "#09090b", borderColor: "#27272a", borderRadius: "8px" }} />
                <Bar dataKey="maxPoints" name="Punti" fill="#daa520" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Pie chart: category weights */}
        <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
          <h4 className="text-xs font-black uppercase text-zinc-400 tracking-widest">
            Peso Punti per Categoria
          </h4>
          <div className="h-[250px] w-full flex flex-col md:flex-row items-center justify-between">
            <div className="h-[200px] w-full md:w-[60%]">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={categoryData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {categoryData.map((_entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <RechartsTooltip contentStyle={{ backgroundColor: "#09090b", borderColor: "#27272a", borderRadius: "8px" }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="w-full md:w-[40%] text-left space-y-1.5">
              {categoryData.map((entry, idx) => (
                <div key={idx} className="flex items-center gap-2 text-xs">
                  <span className="size-3.5 rounded shrink-0" style={{ backgroundColor: COLORS[idx % COLORS.length] }} />
                  <span className="font-bold text-zinc-300">{entry.name}</span>
                  <span className="text-zinc-500 font-mono">({entry.weight}%)</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* ─── 2. STATISTICHE PER SFIDA ─── */}
      <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <h3 className="text-base font-extrabold text-foreground uppercase tracking-widest border-b border-border/20 pb-2">
          2. Statistiche per Sfida
        </h3>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-border/40 text-[10px] text-muted-foreground uppercase font-black tracking-widest">
                <th className="pb-3 pr-3">Sfida</th>
                <th className="pb-3 pr-3">Tappa</th>
                <th className="pb-3 pr-3">Tipo</th>
                <th className="pb-3 pr-3 text-center">Punti Max</th>
                <th className="pb-3 pr-3 text-center">% Superamento</th>
                <th className="pb-3 pr-3 text-center">Punti Assegnati</th>
                <th className="pb-3 text-center">Punti Medi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/10">
              {challengeStats.map((c: { id: string; titolo: string; stageName: string; tipo: string; maxPoints: number; completions: number; pct: number; totalAssigned: number; avgAssigned: number | null }) => (
                <tr key={c.id} className="hover:bg-zinc-900/10">
                  <td className="py-2.5 pr-3 font-bold text-foreground leading-tight max-w-[160px]">
                    {c.titolo}
                  </td>
                  <td className="py-2.5 pr-3 text-zinc-400 whitespace-nowrap">{c.stageName}</td>
                  <td className="py-2.5 pr-3">
                    <span className={`inline-block px-1.5 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${tipoBadgeColor(c.tipo)}`}>
                      {c.tipo}
                    </span>
                  </td>
                  <td className="py-2.5 pr-3 text-center font-bold text-yellow-500">{c.maxPoints}</td>
                  <td className="py-2.5 pr-3 text-center">
                    <span className={`font-mono font-bold ${c.pct >= 80 ? "text-success" : c.pct >= 40 ? "text-yellow-400" : "text-zinc-400"}`}>
                      {c.completions} / {activeTeams} ({c.pct}%)
                    </span>
                  </td>
                  <td className="py-2.5 pr-3 text-center font-semibold text-zinc-300">{c.totalAssigned} PT</td>
                  <td className="py-2.5 text-center font-mono">
                    {c.avgAssigned !== null
                      ? <span className="text-cyan-400 font-bold">{c.avgAssigned} PT</span>
                      : <span className="text-zinc-600">—</span>
                    }
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ─── 3. CLASSIFICA PUNTI PER SQUADRA ─── */}
      <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <h3 className="text-base font-extrabold text-foreground uppercase tracking-widest border-b border-border/20 pb-2">
          3. Classifica Punti per Squadra
        </h3>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs md:text-sm">
            <thead>
              <tr className="border-b border-border/40 text-[10px] text-muted-foreground uppercase font-black tracking-widest">
                <th className="pb-3 pr-3">#</th>
                <th className="pb-3 pr-3">Nome Squadra</th>
                <th className="pb-3 pr-3 text-center">🪙 Token</th>
                <th className="pb-3 pr-3 text-center">Sfide ✅</th>
                <th className="pb-3 pr-3 text-center">Punti Totali</th>
                <th className="pb-3 pr-3 text-center">In Attesa</th>
                <th className="pb-3 text-left">Tappa Corrente</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/10">
              {teamLeaderboard.map((team, idx) => {
                const medal = idx === 0 ? "🥇" : idx === 1 ? "🥈" : idx === 2 ? "🥉" : `#${idx + 1}`;
                return (
                  <tr key={team.id} className={`hover:bg-zinc-900/10 ${idx === 0 ? "bg-yellow-500/5" : ""}`}>
                    <td className="py-3 pr-3 font-black text-foreground text-base">{medal}</td>
                    <td className="py-3 pr-3 font-bold text-foreground">{team.nome_squadra}</td>
                    <td className="py-3 pr-3 text-center font-mono font-bold text-yellow-400">{team.token_balance}</td>
                    <td className="py-3 pr-3 text-center font-semibold text-zinc-300">{team.completedChallenges}</td>
                    <td className="py-3 pr-3 text-center">
                      <span className="font-black text-primary text-base">{team.totalPoints} PT</span>
                    </td>
                    <td className="py-3 pr-3 text-center">
                      {team.pendingPoints > 0
                        ? <span className="font-bold text-orange-400">{team.pendingPoints} ⏳</span>
                        : <span className="text-zinc-600">—</span>
                      }
                    </td>
                    <td className="py-3 text-left text-zinc-400 font-medium">{team.currentStage}</td>
                  </tr>
                );
              })}
              {teamLeaderboard.length === 0 && (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-zinc-600 italic">
                    Nessuna squadra attiva trovata.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ─── 4. CLASSIFICAZIONE DELLE SFIDE ─── */}
      <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <h3 className="text-base font-extrabold text-foreground uppercase tracking-widest border-b border-border/20 pb-2">
          4. Classificazione delle Sfide
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {categoryData.map((c, idx: number) => (
            <div key={idx} className="bg-zinc-900/30 p-4 rounded-xl border border-zinc-800/40 text-center">
              <span className="text-[10px] font-black text-zinc-500 uppercase tracking-widest">{c.name}</span>
              <p className="text-2xl font-black text-foreground mt-1.5">{c.value} PT</p>
              <p className="text-xs text-muted-foreground mt-0.5">{c.count} prove · Peso: {c.weight}%</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
