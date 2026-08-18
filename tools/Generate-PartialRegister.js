const fs = require('fs');
const path = require('path');

// Arguments or defaults
const indexPath = process.argv[2] || "work\\index\\functions_index.csv";
const objectRoot = process.argv[3] || "work\\compile\\ghidra";
const outputPath = process.argv[4] || "work\\link\\partial\\register_functions.partial.cpp";
const missingStubsPath = process.argv[5] || "work\\link\\partial\\missing_functions.partial.cpp";

if (!fs.existsSync(indexPath)) {
    console.error(`Function index not found: ${indexPath}`);
    process.exit(1);
}
if (!fs.existsSync(objectRoot)) {
    console.error(`Object root not found: ${objectRoot}`);
    process.exit(1);
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });

console.log("Reading CSV function index...");
const csvContent = fs.readFileSync(indexPath, 'utf-8');
const lines = csvContent.split(/\r?\n/);
if (lines.length < 2) {
    console.error("CSV is empty");
    process.exit(1);
}

const headers = lines[0].split(',').map(h => h.replace(/^"|"$/g, '').trim());
const cppFileIndex = headers.indexOf('CppFile');
const startIndex = headers.indexOf('Start');
const batchIndex = headers.indexOf('Batch');

if (cppFileIndex === -1 || startIndex === -1 || batchIndex === -1) {
    console.error("Could not find required columns in CSV headers: " + JSON.stringify(headers));
    process.exit(1);
}

const registered = [];
const missing = [];
const aliases = [];
const aliasKeys = new Set();

function addInternalAlias(address, symbol, ownerAddress, batch, source, kind) {
    const normalizedAddress = "0x" + address.replace(/^0x/i, '').toLowerCase();
    const normalizedOwner = "0x" + ownerAddress.replace(/^0x/i, '').toLowerCase();
    if (normalizedAddress === normalizedOwner) {
        return;
    }
    const key = `${normalizedAddress}|${symbol}`;
    if (aliasKeys.has(key)) {
        return;
    }
    aliasKeys.add(key);
    aliases.push({
        Address: normalizedAddress,
        Symbol: symbol,
        OwnerAddress: normalizedOwner,
        Batch: batch,
        Source: source,
        Kind: kind
    });
}

const regexPattern = /case\s+0x([0-9a-fA-F]+)u:\s+goto\s+label_/g;

console.log("Processing functions...");
for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    
    const cols = line.split(',').map(c => c.replace(/^"|"$/g, '').trim());
    const cppFile = cols[cppFileIndex];
    if (!cppFile) continue;

    const symbol = path.basename(cppFile, path.extname(cppFile));
    const startAddr = cols[startIndex];
    const batch = cols[batchIndex];
    const objPath = path.join(objectRoot, batch, 'obj', `${symbol}.o`);

    if (fs.existsSync(objPath)) {
        registered.push({
            Address: startAddr,
            Symbol: symbol,
            Batch: batch,
            Object: objPath
        });

        // Scan C++ file if exists
        const sourcePath = path.join(".", cppFile);
        if (fs.existsSync(sourcePath)) {
            const sourceCode = fs.readFileSync(sourcePath, 'utf-8');
            let match;
            regexPattern.lastIndex = 0;
            while ((match = regexPattern.exec(sourceCode)) !== null) {
                addInternalAlias(match[1], symbol, startAddr, batch, cppFile, "switch-case");
            }
        }
    } else {
        missing.push({
            Address: startAddr,
            Symbol: symbol,
            Batch: batch,
            Object: objPath
        });
    }
}

// A switch-case alias is only a convenience re-entry point discovered inside
// SOME owner function's body (internal jump-table / resume label). If that
// same address is ALSO the genuine start of a different, independently
// generated function (a real Ghidra function boundary, registered above in
// `registered`), the real function must win -- aliases are written AFTER all
// top-level registrations, so an unfiltered alias would silently overwrite
// the correct entry in PS2Runtime::m_functionTable with the wrong owner
// (found while closing the 0x540838 class: the code_generator.cpp jump-table
// fix that discovered 0x540838 as an internal target of sub_005407D0 also
// discovered its sibling table entry 0x540890, which happens to be the real
// start of the separately-generated FUN_00540890 -- without this filter that
// alias would hijack every external call to 0x540890). See
// docs/RESULT_MISSING_0x540838_V1.md.
function canonicalHexAddress(address) {
    // Both sides of this comparison need the SAME numeric canonicalization:
    // `registered` addresses come from the CSV index (zero-padded, e.g.
    // "0x00540890"), while alias addresses come from a regex capture over
    // "case 0x540890u:" source text (no padding). A naive string compare
    // never matches across that formatting difference -- parse to a number
    // and re-render so "0x00540890" and "0x540890" collapse to one key.
    return "0x" + (parseInt(address, 16) >>> 0).toString(16).toLowerCase();
}
const registeredAddrSet = new Set(registered.map(item => canonicalHexAddress(item.Address)));
const filteredAliases = aliases.filter(item => !registeredAddrSet.has(canonicalHexAddress(item.Address)));
const skippedAliasCount = aliases.length - filteredAliases.length;

console.log("Writing register cpp file...");
const regCppLines = [
    '#include "ps2_runtime.h"',
    '#include "register_functions.h"',
    '',
    '// Auto-generated by tools\\Generate-PartialRegister.js',
    '// Registers only functions with compiled object files under work\\compile\\ghidra.',
    ''
];

for (const item of registered) {
    regCppLines.push(`void ${item.Symbol}(uint8_t* rdram, R5900Context* ctx, PS2Runtime* runtime);`);
}
regCppLines.push('');
regCppLines.push('void registerAllFunctions(PS2Runtime& runtime)');
regCppLines.push('{');
for (const item of registered) {
    const addr = item.Address.toLowerCase();
    regCppLines.push(`    runtime.registerFunction(${addr}u, ${item.Symbol});`);
}
for (const item of filteredAliases) {
    const addr = item.Address.toLowerCase();
    regCppLines.push(`    runtime.registerFunction(${addr}u, ${item.Symbol});`);
}
regCppLines.push('}');
regCppLines.push('');

fs.writeFileSync(outputPath, regCppLines.join('\n'), 'ascii');

// Helper to write CSV manifest
function writeCSVManifest(destPath, items, keys) {
    const csvRows = [keys.join(',')];
    for (const item of items) {
        csvRows.push(keys.map(k => `"${item[k]}"`).join(','));
    }
    fs.writeFileSync(destPath, csvRows.join('\n'), 'utf-8');
}

const manifestPath = outputPath.replace(/\.cpp$/, '.manifest.csv');
writeCSVManifest(manifestPath, registered, ['Address', 'Symbol', 'Batch', 'Object']);

const aliasManifestPath = outputPath.replace(/\.cpp$/, '.aliases.csv');
writeCSVManifest(aliasManifestPath, filteredAliases, ['Address', 'Symbol', 'OwnerAddress', 'Batch', 'Source', 'Kind']);

console.log("Writing missing stubs cpp file...");
const stubLines = [
    '#include "ps2_runtime.h"',
    '',
    '#include <iostream>',
    '',
    '// Auto-generated by tools\\Generate-PartialRegister.js',
    '// Temporary link stubs for generated functions that have not been compiled yet.',
    '// These make partial executables linkable; reaching one at runtime is still a missing-code blocker.',
    ''
];

for (const item of missing) {
    const addr = item.Address.toLowerCase();
    stubLines.push(`void ${item.Symbol}(uint8_t*, R5900Context* ctx, PS2Runtime* runtime)`);
    stubLines.push('{');
    stubLines.push('    static bool logged = false;');
    stubLines.push('    if (!logged) {');
    stubLines.push(`        std::cerr << "[partial-runner:missing-function] ${item.Symbol} @ ${addr}" << std::endl;`);
    stubLines.push('        logged = true;');
    stubLines.push('    }');
    stubLines.push('    if (ctx) {');
    stubLines.push('        ctx->pc = 0;');
    stubLines.push('    }');
    stubLines.push('    if (runtime) {');
    stubLines.push('        runtime->requestStop();');
    stubLines.push('    }');
    stubLines.push('}');
    stubLines.push('');
}

fs.writeFileSync(missingStubsPath, stubLines.join('\n'), 'ascii');

const missingManifestPath = missingStubsPath.replace(/\.cpp$/, '.manifest.csv');
writeCSVManifest(missingManifestPath, missing, ['Address', 'Symbol', 'Batch', 'Object']);

console.log(`[OK] Partial register source: ${outputPath}`);
console.log(`[OK] Partial register manifest: ${manifestPath}`);
console.log(`[OK] Registered functions: ${registered.length}`);
console.log(`[OK] Internal PC aliases: ${filteredAliases.length}`);
console.log(`[OK] Aliases skipped (collide with a real function start): ${skippedAliasCount}`);
console.log(`[OK] Alias manifest: ${aliasManifestPath}`);
console.log(`[OK] Missing stub source: ${missingStubsPath}`);
console.log(`[OK] Missing stub manifest: ${missingManifestPath}`);
console.log(`[OK] Missing stub functions: ${missing.length}`);
