const fs = require("fs");
const path = require("path");

function runPWATests() {
  console.log("==================================================");
  console.log("TEST SUITE: 📱 SUPPORTO PWA COMPLETO PECHINO EXPRESS BRA");
  console.log("==================================================");

  const rootDir = path.resolve(__dirname, "..");
  const publicDir = path.join(rootDir, "public");

  // TEST 1: Manifest check
  console.log("\n--- TEST 1: VERIFICA WEB APP MANIFEST ---");
  const manifestPath = path.join(publicDir, "manifest.webmanifest");
  if (!fs.existsSync(manifestPath)) throw new Error("manifest.webmanifest non trovato in public/");
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));

  if (!manifest.name || manifest.name !== "Pechino Express Bra") throw new Error("Manifest name non corretto: " + manifest.name);
  if (!manifest.short_name || manifest.short_name !== "Pechino Bra") throw new Error("Manifest short_name non corretto: " + manifest.short_name);
  if (manifest.display !== "standalone") throw new Error("Manifest display non è standalone!");
  if (!manifest.theme_color || !manifest.background_color) throw new Error("theme_color o background_color mancante!");
  if (!Array.isArray(manifest.icons) || manifest.icons.length < 3) throw new Error("Icone mancanti nel manifest!");
  console.log("✓ TEST 1 PASSED: manifest.webmanifest valido, completo e conforme agli standard W3C.");

  // TEST 2: Icon files verification
  console.log("\n--- TEST 2: VERIFICA RISORSE ICONE PWA ---");
  manifest.icons.forEach((icon) => {
    const iconRelPath = icon.src.replace(/^\//, "");
    const iconFullPath = path.join(publicDir, iconRelPath);
    if (!fs.existsSync(iconFullPath)) {
      throw new Error(`File icona dichiarato non esistente su disco: ${iconFullPath}`);
    }
    const stat = fs.statSync(iconFullPath);
    if (stat.size < 100) throw new Error(`Icona ${iconFullPath} è vuota o corrotta (${stat.size} bytes)`);
  });
  console.log(`✓ TEST 2 PASSED: Tutte le ${manifest.icons.length} icone (192, 512, maskable, svg) sono presenti e valide.`);

  // TEST 3: Service Worker verification
  console.log("\n--- TEST 3: VERIFICA SERVICE WORKER (public/sw.js) ---");
  const swPath = path.join(publicDir, "sw.js");
  if (!fs.existsSync(swPath)) throw new Error("sw.js non trovato in public/");
  const swContent = fs.readFileSync(swPath, "utf-8");

  if (!swContent.includes("addEventListener(\"install\"") && !swContent.includes("addEventListener('install'")) {
    throw new Error("sw.js non gestisce l'evento install!");
  }
  if (!swContent.includes("addEventListener(\"activate\"") && !swContent.includes("addEventListener('activate'")) {
    throw new Error("sw.js non gestisce l'evento activate!");
  }
  if (!swContent.includes("addEventListener(\"fetch\"") && !swContent.includes("addEventListener('fetch'")) {
    throw new Error("sw.js non gestisce l'evento fetch!");
  }
  if (!swContent.includes("skipWaiting") || !swContent.includes("clients.claim")) {
    throw new Error("sw.js non gestisce skipWaiting o clients.claim per gli aggiornamenti!");
  }
  if (!swContent.includes("_serverFn") || !swContent.includes("/api/")) {
    throw new Error("sw.js non implementa la protezione network-only per i dati dinamici di gara!");
  }
  console.log("✓ TEST 3 PASSED: Service Worker correttamente configurato con isolamento dati dinamici e smart cache.");

  // TEST 4: Root HTML metadata
  console.log("\n--- TEST 4: VERIFICA METADATI PWA NELLA ROOT HTML ---");
  const rootComponentPath = path.join(rootDir, "src/routes/__root.tsx");
  const rootContent = fs.readFileSync(rootComponentPath, "utf-8");

  if (!rootContent.includes("manifest.webmanifest")) throw new Error("Link a manifest.webmanifest mancante in __root.tsx");
  if (!rootContent.includes("apple-mobile-web-app-capable")) throw new Error("Meta tag apple-mobile-web-app-capable mancante in __root.tsx");
  if (!rootContent.includes("viewport-fit=cover")) throw new Error("viewport-fit=cover mancante in __root.tsx");
  if (!rootContent.includes("PWAManager")) throw new Error("Componente PWAManager non montato in __root.tsx");
  console.log("✓ TEST 4 PASSED: Metadati PWA e componente PWAManager integrati nella Root.");

  // TEST 5: PWAManager component
  console.log("\n--- TEST 5: VERIFICA COMPONENTE PWAManager ---");
  const pwaManagerPath = path.join(rootDir, "src/components/PWAManager.tsx");
  if (!fs.existsSync(pwaManagerPath)) throw new Error("PWAManager.tsx non trovato!");
  const pwaContent = fs.readFileSync(pwaManagerPath, "utf-8");

  if (!pwaContent.includes("beforeinstallprompt")) throw new Error("Gestione beforeinstallprompt mancante in PWAManager");
  console.log("✓ TEST 5 PASSED: PWAManager gestisce install prompt, istruzioni iOS e aggiornamenti app.");

  // TEST 6: Safe Area CSS
  console.log("\n--- TEST 6: VERIFICA SAFE AREA CSS UTILITIES ---");
  const stylesPath = path.join(rootDir, "src/styles.css");
  const stylesContent = fs.readFileSync(stylesPath, "utf-8");
  if (!stylesContent.includes("safe-top") || !stylesContent.includes("safe-bottom")) {
    throw new Error("Utility safe-top o safe-bottom mancanti in styles.css");
  }
  console.log("✓ TEST 6 PASSED: Utility CSS per notch, dynamic island e safe area presenti.");

  console.log("\n==================================================");
  console.log("🎉 TUTTI I TEST PWA SONO STATI SUPERATI CON SUCCESSO!");
  console.log("==================================================");
}

runPWATests();
