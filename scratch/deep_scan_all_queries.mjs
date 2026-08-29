import * as fs from "fs";
import { execFileSync } from "child_process";

// 1. Get entire DB schema from PostgreSQL
const rawDbCols = execFileSync("psql", [
  "postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres",
  "-t", "-A", "-c", `
    SELECT json_agg(json_build_object(
      'table', c.table_name,
      'col', c.column_name,
      'type', c.data_type,
      'nullable', c.is_nullable
    ))
    FROM information_schema.columns c
    WHERE c.table_schema = 'public';
  `
], { encoding: "utf8" });

const dbCols = JSON.parse(rawDbCols);
const tableColMap = {};
for (const row of dbCols) {
  if (!tableColMap[row.table]) tableColMap[row.table] = new Set();
  tableColMap[row.table].add(row.col);
}

console.log("Loaded DB Tables & Columns:", Object.keys(tableColMap).length, "tables.");

function getFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  for (const file of list) {
    const fullPath = dir + "/" + file;
    const stat = fs.statSync(fullPath);
    if (stat && stat.isDirectory()) {
      if (!['node_modules', '.output', 'dist', '.git'].includes(file)) {
        results = results.concat(getFiles(fullPath));
      }
    } else if (file.endsWith('.ts') || file.endsWith('.tsx')) {
      results.push(fullPath);
    }
  }
  return results;
}

const files = getFiles("src");
const issues = [];

files.forEach(filePath => {
  if (filePath.includes("localDbServer.ts") || filePath.includes("types.ts")) return;
  const content = fs.readFileSync(filePath, "utf8");

  // Check for .from("tableName").insert(...) or .update(...) or .select(...) or .eq(...) or .order(...)
  const fromRegex = /\.from\(\s*["'`]([a-zA-Z0-9_]+)["'`]\s*\)([\s\S]*?)(?=\.from\(|export |const |function |return |;\s*\n|\n\s*\n\s*\n)/g;
  let match;

  while ((match = fromRegex.exec(content)) !== null) {
    const tableName = match[1];
    const chain = match[2];
    const lineNum = content.substring(0, match.index).split("\n").length;

    if (!tableColMap[tableName]) {
      issues.push({
        file: filePath,
        line: lineNum,
        severity: "CRITICAL",
        type: "TABLE_NOT_FOUND",
        table: tableName,
        detail: `Table "${tableName}" does not exist in production database.`
      });
      continue;
    }

    const validCols = tableColMap[tableName];

    // Check .insert({ ... }) or .insert([ { ... } ])
    const insertMatches = chain.matchAll(/\.insert\(\s*(\[[^\]]*\]|\{[^}]*\})/g);
    for (const im of insertMatches) {
      const payloadStr = im[1];
      // Extract keys from object
      const keyMatches = payloadStr.matchAll(/([a-zA-Z0-9_]+)\s*:/g);
      for (const km of keyMatches) {
        const key = km[1];
        if (!validCols.has(key)) {
          issues.push({
            file: filePath,
            line: lineNum,
            severity: "CRITICAL",
            type: "INVALID_INSERT_COLUMN",
            table: tableName,
            col: key,
            detail: `Column "${key}" does not exist in table "${tableName}". Valid columns: ${Array.from(validCols).join(", ")}`
          });
        }
      }
    }

    // Check .update({ ... })
    const updateMatches = chain.matchAll(/\.update\(\s*(\{[^}]*\})/g);
    for (const um of updateMatches) {
      const payloadStr = um[1];
      const keyMatches = payloadStr.matchAll(/([a-zA-Z0-9_]+)\s*:/g);
      for (const km of keyMatches) {
        const key = km[1];
        if (!validCols.has(key)) {
          issues.push({
            file: filePath,
            line: lineNum,
            severity: "CRITICAL",
            type: "INVALID_UPDATE_COLUMN",
            table: tableName,
            col: key,
            detail: `Column "${key}" does not exist in table "${tableName}". Valid columns: ${Array.from(validCols).join(", ")}`
          });
        }
      }
    }

    // Check .eq("col", ...)
    const eqMatches = chain.matchAll(/\.eq\(\s*["'`]([a-zA-Z0-9_]+)["'`]\s*,/g);
    for (const em of eqMatches) {
      const col = em[1];
      if (!validCols.has(col)) {
        issues.push({
          file: filePath,
          line: lineNum,
          severity: "CRITICAL",
          type: "INVALID_EQ_FILTER_COLUMN",
          table: tableName,
          col: col,
          detail: `Filter column "${col}" does not exist in table "${tableName}". Valid: ${Array.from(validCols).join(", ")}`
        });
      }
    }

    // Check .order("col", ...)
    const orderMatches = chain.matchAll(/\.order\(\s*["'`]([a-zA-Z0-9_]+)["'`]\s*,?/g);
    for (const om of orderMatches) {
      const col = om[1];
      if (!validCols.has(col)) {
        issues.push({
          file: filePath,
          line: lineNum,
          severity: "CRITICAL",
          type: "INVALID_ORDER_COLUMN",
          table: tableName,
          col: col,
          detail: `Order column "${col}" does not exist in table "${tableName}". Valid: ${Array.from(validCols).join(", ")}`
        });
      }
    }
  }
});

console.log("Discovered", issues.length, "codebase schema issues:");
console.log(JSON.stringify(issues, null, 2));

fs.writeFileSync("scratch/code_deep_scan_issues.json", JSON.stringify(issues, null, 2));
