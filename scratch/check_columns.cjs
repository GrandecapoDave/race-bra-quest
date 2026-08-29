const fs = require('fs');
const path = require('path');

const dbAudit = JSON.parse(fs.readFileSync('scratch/db_full_audit.json', 'utf8'));
const schemaMap = {};
for (const col of dbAudit.tables || []) {
  if (!schemaMap[col.table_name]) schemaMap[col.table_name] = {};
  schemaMap[col.table_name][col.column_name] = col;
}

function getFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  for (const file of list) {
    const fullPath = path.join(dir, file);
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

const files = getFiles('src').filter(f => !f.includes('localDbServer.ts'));
const columnIssues = [];

files.forEach(filePath => {
  const content = fs.readFileSync(filePath, 'utf8');

  // Match supabase.from("table").select("cols") or .insert({...}) or .update({...})
  // Simple regex for chained from().select()
  const fromSelectRegex = /\.from\(\s*["']([^"']+)["']\s*\)\s*\.select\(\s*[`"']([^`"']+)`?["']\s*\)/g;
  let match;
  while ((match = fromSelectRegex.exec(content)) !== null) {
    const table = match[1];
    const selectRaw = match[2];
    const cols = selectRaw.split(',').map(c => c.trim()).filter(Boolean);

    if (!schemaMap[table]) {
      columnIssues.push({
        file: filePath,
        table,
        error: `Table "${table}" does not exist in production DB`,
        query: match[0]
      });
      continue;
    }

    cols.forEach(col => {
      // Handle alias: alias:column_name
      let actualCol = col;
      if (col.includes(':')) {
        actualCol = col.split(':')[1].trim();
      }
      // Handle joins like "teams ( nome_squadra )"
      if (actualCol.includes('(') || actualCol.includes('*') || actualCol.includes(')')) return;

      if (!schemaMap[table][actualCol]) {
        columnIssues.push({
          file: filePath,
          table,
          column: actualCol,
          error: `Column "${actualCol}" does not exist in table "${table}" in production DB`,
          rawSelect: col
        });
      }
    });
  }
});

console.log('Column issues found:', columnIssues.length);
console.log(JSON.stringify(columnIssues, null, 2));

fs.writeFileSync('scratch/column_issues.json', JSON.stringify(columnIssues, null, 2));
