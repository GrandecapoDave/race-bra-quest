import * as fs from "fs";

console.log("=== VERCEL & BUILD CONFIG ===");
const vercelJson = fs.existsSync("vercel.json") ? fs.readFileSync("vercel.json", "utf8") : "NO vercel.json";
console.log("vercel.json:", vercelJson);

const pkgJson = JSON.parse(fs.readFileSync("package.json", "utf8"));
console.log("Dependencies:", Object.keys(pkgJson.dependencies || {}));

console.log("\n=== CHECKING CLIENT ENV VARS & FALLBACKS ===");
const clientTs = fs.readFileSync("src/integrations/supabase/client.ts", "utf8");
console.log("client.ts content:", clientTs);

console.log("\n=== CHECKING PWA & MANIFEST ===");
const indexHtml = fs.existsSync("index.html") ? fs.readFileSync("index.html", "utf8") : "NO index.html";
console.log("index.html has manifest link:", indexHtml.includes("manifest"));
console.log("index.html has service worker:", indexHtml.includes("serviceWorker") || indexHtml.includes("registerSW"));

console.log("\n=== CHECKING TODO / FIXME / SENSITIVE KEYWORDS ===");
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
    } else if (file.endsWith('.ts') || file.endsWith('.tsx') || file.endsWith('.json')) {
      results.push(fullPath);
    }
  }
  return results;
}

const files = getFiles("src");
const suspList = [];

files.forEach(f => {
  if (f.includes("localDbServer.ts")) return;
  const content = fs.readFileSync(f, "utf8");
  const lines = content.split("\n");
  lines.forEach((l, i) => {
    if (l.includes("TODO") || l.includes("FIXME") || l.includes("teams.name") || l.includes("teams.color")) {
      suspList.push(`${f}:${i+1} -> ${l.trim()}`);
    }
  });
});

console.log("Suspicious comments / matches:", suspList.length);
suspList.forEach(s => console.log("  ", s));
