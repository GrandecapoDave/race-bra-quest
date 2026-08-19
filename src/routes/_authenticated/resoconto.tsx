import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useSession } from "@/hooks/useAuth";
import { gameReportQuery, reportStatusQuery, formatDuration } from "@/lib/race";
import {
  FileText,
  Trophy,
  Coins,
  Lock,
  Loader2,
  Calendar,
  Layers,
  History,
  ChevronDown,
  ChevronUp,
  Award,
  Sparkles,
  Shield,
  CheckCircle2,
  Zap,
  Skull,
  Flame,
  ArrowRight,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/resoconto")({
  component: TeamResocontoPage,
});

function TeamResocontoPage() {
  const { user } = useSession();
  const [selectedTeamId, setSelectedTeamId] = useState<string | "ALL">("ALL");
  const [openStages, setOpenStages] = useState<Record<string, boolean>>({});

  const reportStatus = useQuery(reportStatusQuery);
  const reportQuery = useQuery(gameReportQuery(user?.id));

  const isPublished = reportStatus.data?.is_published || reportQuery.data?.is_published || false;
  const publishedAt = reportStatus.data?.published_at || reportQuery.data?.published_at;
  const reportData = reportQuery.data?.report;

  function toggleStage(teamId: string, stageId: string) {
    const key = `${teamId}_${stageId}`;
    setOpenStages((prev) => ({ ...prev, [key]: !prev[key] }));
  }

  if (reportQuery.isLoading || reportStatus.isLoading) {
    return (
      <div className="surface p-12 text-center rounded-2xl border border-border/40 space-y-4">
        <Loader2 className="size-8 animate-spin mx-auto text-primary" />
        <p className="text-sm font-black uppercase tracking-wider text-muted-foreground">
          Caricamento Resoconto Finale in corso...
        </p>
      </div>
    );
  }

  // Not published state: Strict lock screen
  if (!isPublished || !reportData || !reportData.teams) {
    return (
      <div className="surface p-10 text-center rounded-2xl border border-border/40 bg-zinc-950/60 max-w-md mx-auto space-y-4 my-8 shadow-2xl">
        <div className="size-16 rounded-2xl bg-zinc-900 border border-zinc-800 flex items-center justify-center mx-auto text-muted-foreground">
          <Lock className="size-8 text-amber-500" />
        </div>
        <div className="space-y-2">
          <h2 className="text-lg font-display font-black uppercase tracking-wide text-foreground">
            Resoconto Non Ancora Disponibile
          </h2>
          <p className="text-xs text-muted-foreground leading-relaxed">
            🏁 Il resoconto finale verrà pubblicato dalla Regia al termine della gara.
          </p>
        </div>
      </div>
    );
  }

  const teams = reportData.teams || [];
  const filteredTeams = selectedTeamId === "ALL" ? teams : teams.filter((t: any) => t.team_id === selectedTeamId);

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      {/* ===================================================================== */}
      {/* HEADER SECTION */}
      {/* ===================================================================== */}
      <div className="surface p-6 rounded-2xl border border-emerald-500/30 bg-emerald-950/10 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="text-2xl font-display font-black tracking-wide uppercase text-foreground flex items-center gap-2">
              <Trophy className="size-6 text-gold" />
              Resoconto Finale della Gara
            </h1>
            <span className="flex items-center gap-1.5 text-[11px] font-black uppercase tracking-wider bg-emerald-500/20 border border-emerald-500/40 text-emerald-400 px-3 py-1 rounded-full">
              <CheckCircle2 className="size-3.5" />
              🟢 CLASSIFICA UFFICIALE E DEFINITIVA
            </span>
          </div>
          <p className="text-xs text-muted-foreground font-semibold mt-1">
            Pubblicato dalla Regia il {publishedAt ? new Date(publishedAt).toLocaleString("it-IT") : ""} · Trasparenza completa di tutti i punteggi, tempi e bonus.
          </p>
        </div>
      </div>

      {/* ===================================================================== */}
      {/* PODIUM SUMMARY */}
      {/* ===================================================================== */}
      {teams.length >= 3 && (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {/* 2° POSTO */}
          <div className="surface p-4 rounded-2xl border border-zinc-700 bg-zinc-950/40 text-center space-y-2 order-2 sm:order-1">
            <span className="text-3xl">🥈</span>
            <p className="text-xs font-black uppercase text-zinc-400">2° Posto</p>
            <h3 className="font-extrabold text-base text-foreground uppercase truncate">
              {teams[1].nome_squadra || teams[1].name || teams[1].team_name}
            </h3>
            <p className="text-xl font-display font-black text-primary">
              {teams[1].final_score ?? teams[1].total_points} PT
            </p>
          </div>

          {/* 1° POSTO */}
          <div className="surface p-5 rounded-2xl border-2 border-gold/60 bg-gold/5 text-center space-y-2 order-1 sm:order-2 shadow-xl shadow-gold/5">
            <span className="text-4xl">🥇</span>
            <p className="text-xs font-black uppercase text-gold">Vincitori Assoluti</p>
            <h3 className="font-extrabold text-lg text-foreground uppercase truncate">
              {teams[0].nome_squadra || teams[0].name || teams[0].team_name}
            </h3>
            <p className="text-2xl font-display font-black text-gold">
              {teams[0].final_score ?? teams[0].total_points} PT
            </p>
          </div>

          {/* 3° POSTO */}
          <div className="surface p-4 rounded-2xl border border-amber-900/60 bg-zinc-950/40 text-center space-y-2 order-3">
            <span className="text-3xl">🥉</span>
            <p className="text-xs font-black uppercase text-amber-600">3° Posto</p>
            <h3 className="font-extrabold text-base text-foreground uppercase truncate">
              {teams[2].nome_squadra || teams[2].name || teams[2].team_name}
            </h3>
            <p className="text-xl font-display font-black text-primary">
              {teams[2].final_score ?? teams[2].total_points} PT
            </p>
          </div>
        </div>
      )}

      {/* ===================================================================== */}
      {/* CLASSIFICA TABELLARE */}
      {/* ===================================================================== */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-display font-black uppercase tracking-wider text-foreground flex items-center gap-2">
            <Trophy className="size-5 text-gold" /> Classifica Finale Completa
          </h2>
          <span className="text-xs text-muted-foreground font-mono">
            {teams.length} Squadre
          </span>
        </div>

        <div className="surface rounded-2xl border border-border/50 bg-zinc-950/40 overflow-hidden shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-border/40 bg-zinc-900/60 font-black text-muted-foreground uppercase text-[10px] tracking-wider">
                  <th className="py-3.5 px-4 text-center w-16">Pos</th>
                  <th className="py-3.5 px-4">Squadra</th>
                  <th className="py-3.5 px-3 text-center">Prove</th>
                  <th className="py-3.5 px-3 text-right">Punti Base</th>
                  <th className="py-3.5 px-3 text-center">Tempo Totale</th>
                  <th className="py-3.5 px-3 text-right">Bonus Tempo</th>
                  <th className="py-3.5 px-3 text-center">Token Rimasti</th>
                  <th className="py-3.5 px-3 text-right">Bonus Token</th>
                  <th className="py-3.5 px-4 text-right">PUNTI FINALI</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/20">
                {teams.map((t: any) => {
                  const pos = t.final_rank ?? t.rank ?? t.position ?? 1;
                  const basePts = t.base_score ?? t.total_score_before_final_bonuses ?? t.challenges_points + (t.modifier_points ?? 0) + (t.cattiveria_points ?? 0);
                  const timeBonus = t.time_bonus ?? t.bonus_tempo ?? 0;
                  const tokenBonus = t.token_efficiency_bonus ?? t.bonus_token ?? Math.floor((t.token_balance ?? 50) / 5);
                  const finalScore = t.final_score ?? t.total_points ?? (basePts + timeBonus + tokenBonus);
                  const teamName = t.nome_squadra || t.name || t.team_name || "Squadra";

                  const isTop1 = pos === 1;
                  const isTop2 = pos === 2;
                  const isTop3 = pos === 3;

                  return (
                    <tr
                      key={t.team_id}
                      className={`hover:bg-zinc-900/40 transition-colors ${
                        isTop1
                          ? "bg-gold/5 font-semibold"
                          : isTop2
                          ? "bg-zinc-800/10"
                          : isTop3
                          ? "bg-amber-950/10"
                          : ""
                      }`}
                    >
                      {/* POS */}
                      <td className="py-3.5 px-4 text-center">
                        <span
                          className={`inline-flex items-center justify-center size-7 rounded-xl font-black text-xs ${
                            isTop1
                              ? "bg-gold text-black shadow-md shadow-gold/20"
                              : isTop2
                              ? "bg-zinc-400 text-black"
                              : isTop3
                              ? "bg-amber-700 text-white"
                              : "bg-zinc-800 text-zinc-300 font-mono"
                          }`}
                        >
                          {pos}
                        </span>
                      </td>

                      {/* TEAM */}
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-3">
                          <span
                            className="size-8 rounded-xl text-sm flex items-center justify-center shadow-inner border shrink-0"
                            style={{
                              backgroundColor: (t.color ?? "#f97316") + "22",
                              borderColor: (t.color ?? "#f97316") + "55",
                            }}
                          >
                            {t.avatar_url ?? "🏳️"}
                          </span>
                          <div>
                            <p className="font-extrabold text-sm text-foreground uppercase tracking-wide">
                              {teamName}
                            </p>
                            {t.motto && (
                              <p className="text-[10px] text-muted-foreground truncate max-w-[200px]">
                                "{t.motto}"
                              </p>
                            )}
                          </div>
                        </div>
                      </td>

                      {/* PROVE */}
                      <td className="py-3.5 px-3 text-center font-mono font-bold text-zinc-300">
                        {t.completed_challenges ?? 0} / 15
                      </td>

                      {/* PUNTI BASE */}
                      <td className="py-3.5 px-3 text-right font-mono font-bold text-zinc-200">
                        {basePts} PT
                      </td>

                      {/* TEMPO */}
                      <td className="py-3.5 px-3 text-center font-mono text-[11px] text-zinc-400">
                        <div>{formatDuration(t.total_time_seconds ?? t.total_duration_seconds ?? 0)}</div>
                        <span className="text-[9px] text-muted-foreground uppercase font-bold">
                          #{t.time_rank ?? pos} tempo
                        </span>
                      </td>

                      {/* BONUS TEMPO */}
                      <td className="py-3.5 px-3 text-right font-mono font-bold text-amber-400">
                        +{timeBonus} PT
                      </td>

                      {/* TOKEN */}
                      <td className="py-3.5 px-3 text-center font-mono font-bold text-amber-300">
                        {t.token_balance ?? 50} 🪙
                      </td>

                      {/* BONUS TOKEN */}
                      <td className="py-3.5 px-3 text-right font-mono font-bold text-emerald-400">
                        +{tokenBonus} PT
                      </td>

                      {/* FINAL SCORE */}
                      <td className="py-3.5 px-4 text-right">
                        <span className="text-base font-display font-black text-primary px-2.5 py-1 rounded-lg bg-primary/10 border border-primary/20">
                          {finalScore} PT
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* ===================================================================== */}
      {/* DETTAGLIO SQUADRE ACCORDION */}
      {/* ===================================================================== */}
      <div className="space-y-6 pt-4 border-t border-border/40">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-display font-black uppercase tracking-wider text-foreground flex items-center gap-2">
              <Layers className="size-5 text-primary" /> Dettaglio per Squadra
            </h2>
            <p className="text-xs text-muted-foreground">
              Consulta le prove superate per ogni tappa, bonus e malus di ciascuna squadra.
            </p>
          </div>

          {/* TEAM SELECTOR TABS */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-thin">
            <button
              onClick={() => setSelectedTeamId("ALL")}
              className={`px-3.5 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all whitespace-nowrap cursor-pointer ${
                selectedTeamId === "ALL"
                  ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                  : "surface border border-border/40 text-muted-foreground hover:text-foreground"
              }`}
            >
              Tutte ({teams.length})
            </button>
            {teams.map((t: any) => {
              const tName = t.nome_squadra || t.name || t.team_name || "Squadra";
              return (
                <button
                  key={t.team_id}
                  onClick={() => setSelectedTeamId(t.team_id)}
                  className={`px-3.5 py-2 rounded-xl text-xs font-extrabold uppercase tracking-wider transition-all flex items-center gap-1.5 whitespace-nowrap cursor-pointer ${
                    selectedTeamId === t.team_id
                      ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                      : "surface border border-border/40 text-muted-foreground hover:text-foreground"
                  }`}
                >
                  <span
                    className="size-4 rounded text-[10px] flex items-center justify-center"
                    style={{ backgroundColor: (t.color ?? "#f97316") + "33" }}
                  >
                    {t.avatar_url ?? "🏳️"}
                  </span>
                  {tName}
                </button>
              );
            })}
          </div>
        </div>

        {/* TEAMS CARDS */}
        <div className="space-y-8">
          {filteredTeams.map((team: any) => {
            const teamPos = team.final_rank ?? team.position ?? team.rank ?? 1;
            const teamName = team.nome_squadra || team.name || team.team_name || "Squadra";
            const initialTokens = team.tokens_initial ?? 50;
            const gainedTokens = team.tokens_gained_rewards ?? team.tokens_gained_stage_rewards ?? 0;
            const spentTokens = team.tokens_spent_marketplace ?? 0;
            const balanceTokens = team.token_balance ?? 50;
            const basePts = team.base_score ?? team.challenges_points + (team.modifier_points ?? 0) + (team.cattiveria_points ?? 0);
            const timeBonus = team.time_bonus ?? 0;
            const tokenBonus = team.token_efficiency_bonus ?? Math.floor(balanceTokens / 5);
            const finalScore = team.final_score ?? team.total_points ?? (basePts + timeBonus + tokenBonus);

            return (
              <div
                key={team.team_id}
                className="surface rounded-2xl border border-border/50 bg-zinc-950/40 p-6 space-y-6 shadow-xl"
              >
                {/* TEAM MAIN HEADER */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-border/30 pb-5">
                  <div className="flex items-center gap-4">
                    <div
                      className="size-14 rounded-2xl flex items-center justify-center text-3xl shadow-inner border"
                      style={{
                        backgroundColor: (team.color ?? "#f97316") + "22",
                        borderColor: (team.color ?? "#f97316") + "55",
                      }}
                    >
                      {team.avatar_url ?? "🏳️"}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-black uppercase tracking-widest text-primary px-2.5 py-0.5 rounded-full bg-primary/10 border border-primary/20">
                          {teamPos === 1 ? "🥇 1° Posto" : teamPos === 2 ? "🥈 2° Posto" : teamPos === 3 ? "🥉 3° Posto" : `#${teamPos} in Classifica`}
                        </span>
                        <h3 className="text-2xl font-display font-black text-foreground uppercase tracking-wide">
                          {teamName}
                        </h3>
                      </div>
                      <p className="text-xs text-muted-foreground font-semibold mt-1">
                        {team.motto ? `"${team.motto}" · ` : ""}
                        Prove: {team.completed_challenges ?? 0}/15 · Tempo: {formatDuration(team.total_time_seconds ?? team.total_duration_seconds ?? 0)} (#{team.time_rank ?? teamPos} tempo)
                      </p>
                    </div>
                  </div>

                  {/* SCORE BLOCKS */}
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                    <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                      <span className="text-[10px] uppercase font-bold text-muted-foreground">Punti Finali</span>
                      <p className="text-xl font-display font-black text-primary">{finalScore} PT</p>
                    </div>
                    <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                      <span className="text-[10px] uppercase font-bold text-muted-foreground">Punti Base</span>
                      <p className="text-lg font-mono font-black text-zinc-200">{basePts} PT</p>
                    </div>
                    <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                      <span className="text-[10px] uppercase font-bold text-muted-foreground">Bonus Tempo</span>
                      <p className="text-lg font-mono font-black text-amber-400">+{timeBonus} PT</p>
                    </div>
                    <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                      <span className="text-[10px] uppercase font-bold text-muted-foreground">Bonus Token</span>
                      <p className="text-lg font-mono font-black text-emerald-400">+{tokenBonus} PT</p>
                    </div>
                  </div>
                </div>

                {/* MOVIMENTO TOKEN */}
                <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/80 space-y-2">
                  <h4 className="text-xs font-black uppercase tracking-wider text-zinc-400 flex items-center gap-1.5">
                    <Coins className="size-4 text-amber-400" /> Movimento Token
                  </h4>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                    <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                      <p className="text-[9px] text-muted-foreground uppercase font-bold">Iniziali</p>
                      <p className="font-mono font-bold text-zinc-300">+{initialTokens} TK</p>
                    </div>
                    <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                      <p className="text-[9px] text-muted-foreground uppercase font-bold">Guadagnati Fine Tappa</p>
                      <p className="font-mono font-bold text-emerald-400">+{gainedTokens} TK</p>
                    </div>
                    <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                      <p className="text-[9px] text-muted-foreground uppercase font-bold">Spesi nel Marketplace</p>
                      <p className="font-mono font-bold text-rose-400">−{spentTokens} TK</p>
                    </div>
                    <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                      <p className="text-[9px] text-muted-foreground uppercase font-bold">Saldo Finale</p>
                      <p className="font-mono font-black text-amber-400">{balanceTokens} TK</p>
                    </div>
                  </div>
                </div>

                {/* DETTAGLIO TAPPE ACCORDION */}
                <div className="space-y-3">
                  <h4 className="text-xs font-display font-black uppercase tracking-wider text-muted-foreground flex items-center gap-2">
                    <Layers className="size-4 text-primary" /> Dettaglio per Tappa
                  </h4>

                  <div className="space-y-3">
                    {(team.stages_breakdown ?? team.stages ?? []).map((sb: any) => {
                      const stageKey = `${team.team_id}_${sb.stage_id}`;
                      const isOpen = openStages[stageKey] ?? true;

                      return (
                        <div
                          key={sb.stage_id}
                          className="bg-zinc-900/40 rounded-xl border border-zinc-800 overflow-hidden transition-all"
                        >
                          <button
                            type="button"
                            onClick={() => toggleStage(team.team_id, sb.stage_id)}
                            className="w-full p-4 flex items-center justify-between text-left hover:bg-zinc-900/80 transition-colors cursor-pointer"
                          >
                            <div className="flex items-center gap-3">
                              <span className="size-6 rounded-lg bg-zinc-800 text-xs font-black flex items-center justify-center text-primary">
                                {sb.stage_order}
                              </span>
                              <div>
                                <h4 className="font-bold text-sm text-foreground">
                                  {sb.stage_name || `Tappa ${sb.stage_order}`}
                                </h4>
                                <p className="text-[10px] text-muted-foreground">
                                  Punti Tappa: {sb.stage_total_points} PT
                                </p>
                              </div>
                            </div>

                            <div className="flex items-center gap-4">
                              <span className="text-xs font-mono font-black text-primary">
                                {sb.stage_total_points} PT
                              </span>
                              {isOpen ? <ChevronUp className="size-4 text-muted-foreground" /> : <ChevronDown className="size-4 text-muted-foreground" />}
                            </div>
                          </button>

                          {isOpen && (
                            <div className="p-4 pt-0 border-t border-zinc-800/60 space-y-4">
                              {/* SFIDE NELLA TAPPA */}
                              <div className="space-y-2 pt-3">
                                <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground">
                                  Prove di Tappa
                                </span>
                                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                                  {(sb.challenges ?? []).map((c: any) => (
                                    <div
                                      key={c.challenge_id}
                                      className={`p-3 rounded-lg border text-xs space-y-1 ${
                                        c.completed
                                          ? "bg-emerald-950/20 border-emerald-500/30 text-emerald-300"
                                          : "bg-zinc-950/40 border-zinc-800 text-muted-foreground"
                                      }`}
                                    >
                                      <div className="flex items-center justify-between">
                                        <span className="font-bold">{c.title}</span>
                                        {c.completed ? (
                                          <CheckCircle2 className="size-3.5 text-emerald-400" />
                                        ) : (
                                          <span className="text-[10px] text-zinc-500">Non completata</span>
                                        )}
                                      </div>
                                      <div className="flex items-center justify-between text-[10px] text-zinc-400 font-mono">
                                        <span>Max: {c.max_points} PT</span>
                                        <span className="font-bold text-foreground">
                                          Ottenuti: {c.points_awarded} PT
                                        </span>
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              </div>

                              {/* BONUS USATI */}
                              {(sb.bonuses_used ?? []).length > 0 && (
                                <div className="space-y-2">
                                  <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                    <Shield className="size-3 text-emerald-400" /> Bonus Acquistati in Tappa
                                  </span>
                                  <div className="space-y-1.5">
                                    {(sb.bonuses_used ?? []).map((b: any) => (
                                      <div
                                        key={b.transaction_id}
                                        className="p-2.5 bg-emerald-950/10 border border-emerald-500/20 rounded-lg text-xs flex items-center justify-between"
                                      >
                                        <span className="font-semibold text-emerald-300">{b.name}</span>
                                        <span className="font-mono text-[11px] text-amber-400">-{b.cost_tokens} TK</span>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* MALUS USATI (ATTACCO) */}
                              {(sb.maluses_used ?? []).length > 0 && (
                                <div className="space-y-2">
                                  <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                    <Zap className="size-3 text-purple-400" /> Malus Sferrati contro Avversari
                                  </span>
                                  <div className="space-y-1.5">
                                    {(sb.maluses_used ?? []).map((m: any) => (
                                      <div
                                        key={m.transaction_id}
                                        className="p-2.5 bg-purple-950/10 border border-purple-500/20 rounded-lg text-xs flex items-center justify-between flex-wrap gap-2"
                                      >
                                        <div className="flex items-center gap-2">
                                          <span className="font-semibold text-purple-300">{m.name}</span>
                                          <ArrowRight className="size-3 text-muted-foreground" />
                                          <span className="font-bold text-foreground">{m.target_team_name}</span>
                                        </div>
                                        <div className="flex items-center gap-3 font-mono text-[11px]">
                                          <span className="text-amber-400">-{m.cost_tokens} TK</span>
                                          <span className="text-purple-400">+{m.cattiveria_delta} 😈</span>
                                        </div>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* MALUS SUBITI (VITTIMA) */}
                              {(sb.maluses_suffered ?? []).length > 0 && (
                                <div className="space-y-2">
                                  <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                    <Skull className="size-3 text-rose-400" /> Malus Subiti da Altre Squadre
                                  </span>
                                  <div className="space-y-1.5">
                                    {(sb.maluses_suffered ?? []).map((ms: any) => (
                                      <div
                                        key={ms.transaction_id}
                                        className="p-2.5 bg-rose-950/10 border border-rose-500/20 rounded-lg text-xs flex items-center justify-between"
                                      >
                                        <span className="font-semibold text-rose-300">{ms.name}</span>
                                        <span className="text-muted-foreground text-[11px]">
                                          Da: <strong className="text-foreground">{ms.attacker_team_name}</strong>
                                        </span>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}

                              {/* REGISTRO CATTIVERIA */}
                              {(sb.cattiveria_entries ?? []).length > 0 && (
                                <div className="space-y-2">
                                  <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                    <Flame className="size-3 text-purple-400" /> Variazioni Punti Cattiveria
                                  </span>
                                  <div className="space-y-1">
                                    {(sb.cattiveria_entries ?? []).map((ce: any) => (
                                      <div
                                        key={ce.id}
                                        className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800 text-[11px] flex items-center justify-between"
                                      >
                                        <span className="text-zinc-300">{ce.motivo}</span>
                                        <span
                                          className={`font-mono font-bold ${
                                            ce.punti >= 0 ? "text-purple-400" : "text-rose-400"
                                          }`}
                                        >
                                          {ce.punti > 0 ? `+${ce.punti}` : ce.punti} 😈
                                        </span>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
