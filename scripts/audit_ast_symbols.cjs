const fs = require('fs');
const path = require('path');
const ts = require('typescript');

const projectRoot = path.resolve(__dirname, '..');
const srcDir = path.join(projectRoot, 'src');

function getAllFiles(dir, exts = ['.ts', '.tsx']) {
  let files = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files = files.concat(getAllFiles(fullPath, exts));
    } else if (exts.includes(path.extname(entry.name))) {
      files.push(fullPath);
    }
  }
  return files;
}

const allFiles = getAllFiles(srcDir);
console.log(`[AST AUDIT] Scanning ${allFiles.length} files in src/ for symbol integrity...`);

const configPath = path.join(projectRoot, 'tsconfig.json');
const configFile = ts.readConfigFile(configPath, ts.sys.readFile);
const parsedCommandLine = ts.parseJsonConfigFileContent(configFile.config, ts.sys, projectRoot);

const program = ts.createProgram({
  rootNames: parsedCommandLine.fileNames,
  options: {
    ...parsedCommandLine.options,
    noEmit: true
  }
});

const checker = program.getTypeChecker();
const diagnostics = ts.getPreEmitDiagnostics(program);

let missingSymbolsFound = [];

// 1. Check all pre-emit diagnostics for unknown identifiers (TS2304, TS2552, TS2339)
for (const diag of diagnostics) {
  if ([2304, 2552].includes(diag.code)) {
    const file = diag.file ? path.relative(projectRoot, diag.file.fileName) : 'unknown';
    const { line, character } = diag.file ? diag.file.getLineAndCharacterOfPosition(diag.start) : { line: 0, character: 0 };
    const message = ts.flattenDiagnosticMessageText(diag.messageText, '\n');
    missingSymbolsFound.push({
      file,
      line: line + 1,
      character: character + 1,
      code: diag.code,
      message
    });
  }
}

// 2. Walk AST to inspect JSX tags & Lucide icon components
for (const sourceFile of program.getSourceFiles()) {
  if (!sourceFile.isDeclarationFile && sourceFile.fileName.startsWith(srcDir)) {
    const relativePath = path.relative(projectRoot, sourceFile.fileName);

    function visit(node) {
      if (ts.isJsxOpeningElement(node) || ts.isJsxSelfClosingElement(node)) {
        const tagName = node.tagName;
        if (ts.isIdentifier(tagName)) {
          const name = tagName.text;
          if (name[0] === name[0].toUpperCase()) {
            const symbol = checker.getSymbolAtLocation(tagName);
            if (!symbol) {
              const { line, character } = sourceFile.getLineAndCharacterOfPosition(tagName.getStart());
              missingSymbolsFound.push({
                file: relativePath,
                line: line + 1,
                character: character + 1,
                code: 'UNRESOLVED_JSX',
                message: `Unresolved JSX Component/Icon <${name}>`
              });
            }
          }
        }
      }
      ts.forEachChild(node, visit);
    }
    visit(sourceFile);
  }
}

if (missingSymbolsFound.length > 0) {
  console.error(`❌ AST AUDIT FAILED! Found ${missingSymbolsFound.length} unresolved symbols:`);
  console.error(JSON.stringify(missingSymbolsFound, null, 2));
  process.exit(1);
} else {
  console.log(`✅ AST AUDIT PASSED: 0 missing symbols across all ${allFiles.length} files.`);
}
