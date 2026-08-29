import * as fs from "fs";
import { execFileSync } from "child_process";

// 1. Get entire DB schema from PostgreSQL
const rawDbCols = execFileSync("psql", [
  "postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres",
  "-t", "-A", "-c", `
    SELECT json_agg(json_build_object(
      'table', c.table_name,
      'col', c.column_name
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
const selectIssues = [];

files.forEach(filePath => {
  if (filePath.includes("localDbServer.ts") || filePath.includes("types.ts")) return;
  const content = fs.readFileSync(filePath, "utf8");

  // Regex to match .from("table").select("cols") or .select(`cols`)
  const selectRegex = /\.from\(\s*["'`]([a-zA-Z0-9_]+)["'`]\s*\)[\s\S]*?\.select\(\s*[`"']([^`"']+)`?["']\s*\)/g;
  let match;

  while ((match = selectRegex.exec(content)) !== null) {
    const tableName = match[1];
    const selectStr = match[2];
    const lineNum = content.substring(0, match.index).split("\n").length;

    if (!tableColMap[tableName]) continue;
    const validCols = tableColMap[tableName];

    // Clean and split selected fields
    const fields = selectStr
      .replace(/\s+/g, " ")
      .split(",")
      .map(f => f.trim())
      .filter(Boolean);

    for (const field of fields) {
      if (field === "*" || field.includes("(") || field.includes(")") || field.includes("->")) continue;
      
      // If alias like "target_col:real_col" or "alias:real_col"
      let realCol = field;
      if (field.includes(":")) {
        realCol = field.split(":")[1].trim();
      }

      if (!validCols.has(realCol)) {
        selectIssues.push({
          file: filePath,
          line: lineNum,
          table: tableName,
          column: realCol,
          detail: `Selected column "${realCol}" does not exist in table "${tableName}". Valid: ${Array.from(validCols).join(", ")}`
        });
      }
    }
  }
});

console.log("Found", selectIssues.length, "SELECT column issues:");
console.log(JSON.stringify(selectIssues, null, 2));

fs.writeFileSync("scratch/select_column_issues.json", JSON.stringify(selectIssues, null, 2));
