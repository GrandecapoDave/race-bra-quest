import { execSync } from "child_process";
import * as fs from "fs";

const rpcs = JSON.parse(fs.readFileSync("scratch/real_rpc_list.json", "utf8"));
const schema = JSON.parse(fs.readFileSync("scratch/db_full_audit.json", "utf8"));

const tableMap = {};
for (const col of schema.tables || []) {
  if (!tableMap[col.table_name]) tableMap[col.table_name] = new Set();
  tableMap[col.table_name].add(col.column_name);
}

function runSql(sql) {
  const cmd = `psql 'postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres' -t -A -c "${sql.replace(/"/g, '\\"')}"`;
  return execSync(cmd, { encoding: "utf8" }).trim();
}

console.log("Analyzing all", rpcs.length, "functions...");

const functionSources = JSON.parse(runSql(`
  SELECT json_agg(json_build_object(
    'name', p.proname,
    'src', p.prosrc,
    'args', pg_get_function_arguments(p.oid),
    'return', pg_get_function_result(p.oid),
    'secdef', p.prosecdef,
    'config', p.proconfig
  ))
  FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public';
`));

fs.writeFileSync("scratch/all_function_sources.json", JSON.stringify(functionSources, null, 2));

const issues = [];

functionSources.forEach(fn => {
  // Check security definer and search_path
  if (fn.secdef) {
    const configStr = (fn.config || []).join(", ");
    if (!configStr.includes("search_path")) {
      issues.push({
        fn: fn.name,
        type: "SECURITY",
        severity: "HIGH",
        detail: "SECURITY DEFINER function missing explicit search_path configuration (vulnerable to search_path injection)"
      });
    }
  }

  // Check table references in src
  const src = fn.src;

  // Check for safeupdate errors: UPDATE table_name SET ... without WHERE
  const updatesWithoutWhere = src.match(/UPDATE\s+public\.([a-z_]+)\s+SET\s+[^;]+?;/gi);
  if (updatesWithoutWhere) {
    updatesWithoutWhere.forEach(u => {
      if (!u.toUpperCase().includes("WHERE")) {
        issues.push({
          fn: fn.name,
          type: "SAFEUPDATE_RISK",
          severity: "CRITICAL",
          detail: `UPDATE without WHERE clause detected: "${u.trim()}"`
        });
      }
    });
  }
});

console.log("Found", issues.length, "function issues.");
console.log(JSON.stringify(issues, null, 2));

fs.writeFileSync("scratch/rpc_issues.json", JSON.stringify(issues, null, 2));
