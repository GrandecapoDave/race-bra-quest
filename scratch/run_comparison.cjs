const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const dbAudit = JSON.parse(fs.readFileSync('scratch/db_full_audit.json', 'utf8'));

// Build schema map: table -> Set of column names & detailed col info
const schemaMap = {};
for (const col of dbAudit.tables || []) {
  if (!schemaMap[col.table_name]) {
    schemaMap[col.table_name] = {};
  }
  schemaMap[col.table_name][col.column_name] = col;
}

// Build RLS map
const rlsMap = {};
for (const t of dbAudit.rls_status || []) {
  rlsMap[t.table_name] = t.rowsecurity;
}

// Build Policies map
const policiesMap = {};
for (const p of dbAudit.policies || []) {
  if (!policiesMap[p.table_name]) policiesMap[p.table_name] = [];
  policiesMap[p.table_name].push(p);
}

// Build RPC map
const rpcMap = {};
for (const r of dbAudit.rpcs || []) {
  rpcMap[r.name] = r;
}

// Recursive file scanner
function getFiles(dir, exts = ['.ts', '.tsx']) {
  let results = [];
  const list = fs.readdirSync(dir);
  for (const file of list) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat && stat.isDirectory()) {
      if (file !== 'node_modules' && file !== '.output' && file !== 'dist' && file !== '.git') {
        results = results.concat(getFiles(fullPath, exts));
      }
    } else {
      if (exts.some(ext => file.endsWith(ext))) {
        results.push(fullPath);
      }
    }
  }
  return results;
}

const allSrcFiles = getFiles('src');

// 1. Audit Frontend .from(...) Queries
const queryAudit = [];
const rpcAudit = [];
const storageAudit = [];

for (const filePath of allSrcFiles) {
  // Ignore localDbServer mock implementation for query extraction
  if (filePath.includes('localDbServer.ts')) continue;

  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  lines.forEach((line, idx) => {
    const lineNum = idx + 1;

    // Detect .from("table_name")
    const fromMatches = line.matchAll(/\.from\(\s*["']([^"']+)["']\s*\)/g);
    for (const match of fromMatches) {
      const tableName = match[1];
      queryAudit.push({
        file: filePath,
        line: lineNum,
        table: tableName,
        lineContent: line.trim()
      });
    }

    // Detect .rpc("rpc_name", { ... })
    const rpcMatches = line.matchAll(/\.rpc\(\s*["']([^"']+)["'](?:\s*,\s*(\{[\s\S]*?\}))?/g);
    for (const match of rpcMatches) {
      const rpcName = match[1];
      rpcAudit.push({
        file: filePath,
        line: lineNum,
        rpc: rpcName,
        lineContent: line.trim()
      });
    }

    // Detect .storage.from("bucket")
    const storageMatches = line.matchAll(/\.storage\.from\(\s*["']([^"']+)["']\s*\)/g);
    for (const match of storageMatches) {
      const bucketName = match[1];
      storageAudit.push({
        file: filePath,
        line: lineNum,
        bucket: bucketName,
        lineContent: line.trim()
      });
    }
  });
}

// Analyze from(...) tables and columns
const tableFindings = [];
const uniqueTables = [...new Set(queryAudit.map(q => q.table))];

for (const tableName of uniqueTables) {
  const exists = !!schemaMap[tableName];
  tableFindings.push({
    table: tableName,
    existsInProduction: exists,
    occurrences: queryAudit.filter(q => q.table === tableName).map(q => `${q.file}:${q.line}`)
  });
}

// Analyze RPCs
const rpcFindings = [];
const uniqueRpcs = [...new Set(rpcAudit.map(r => r.rpc))];

for (const rpcName of uniqueRpcs) {
  const prodRpc = rpcMap[rpcName];
  rpcFindings.push({
    rpc: rpcName,
    existsInProduction: !!prodRpc,
    productionArgs: prodRpc ? prodRpc.args : null,
    productionReturn: prodRpc ? prodRpc.return_type : null,
    isSecurityDefiner: prodRpc ? prodRpc.is_security_definer : null,
    occurrences: rpcAudit.filter(r => r.rpc === rpcName).map(r => `${r.file}:${r.line}`)
  });
}

const auditResult = {
  dbSummary: {
    totalTables: Object.keys(schemaMap).length,
    tables: Object.keys(schemaMap),
    totalRpcs: Object.keys(rpcMap).length,
    rpcs: Object.keys(rpcMap)
  },
  tableFindings,
  rpcFindings,
  storageAudit
};

fs.writeFileSync('scratch/code_db_comparison.json', JSON.stringify(auditResult, null, 2));
console.log('Comparison complete! Checked', tableFindings.length, 'tables and', rpcFindings.length, 'RPCs.');
