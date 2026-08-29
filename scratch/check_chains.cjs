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

console.log('=== CHECKING ALL .from() CHAINS ===');

files.forEach(filePath => {
  const content = fs.readFileSync(filePath, 'utf8');
  const fromPattern = /\.from\(\s*["']([^"']+)["']\s*\)([\s\S]*?)(?:;|\n\s*\n|\.then|\.catch|const |let |return )/g;
  let match;
  while ((match = fromPattern.exec(content)) !== null) {
    const table = match[1];
    const chain = match[2];

    // Check .eq("col", ...)
    const eqMatches = chain.matchAll(/\.eq\(\s*["']([^"']+)["']/g);
    for (const eqM of eqMatches) {
      const col = eqM[1];
      if (schemaMap[table] && !schemaMap[table][col]) {
        console.log(`[EQ MISMATCH] ${filePath} -> table "${table}" has no column "${col}" (in .eq("${col}", ...))`);
      }
    }

    // Check .order("col", ...)
    const orderMatches = chain.matchAll(/\.order\(\s*["']([^"']+)["']/g);
    for (const ordM of orderMatches) {
      const col = ordM[1];
      if (schemaMap[table] && !schemaMap[table][col]) {
        console.log(`[ORDER MISMATCH] ${filePath} -> table "${table}" has no column "${col}" (in .order("${col}", ...))`);
      }
    }

    // Check .in("col", ...)
    const inMatches = chain.matchAll(/\.in\(\s*["']([^"']+)["']/g);
    for (const inM of inMatches) {
      const col = inM[1];
      if (schemaMap[table] && !schemaMap[table][col]) {
        console.log(`[IN MISMATCH] ${filePath} -> table "${table}" has no column "${col}" (in .in("${col}", ...))`);
      }
    }
  }
});
