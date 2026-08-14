// Helper: print batch N code length and first line for verification
const fs = require('fs');
const path = require('path');
const base = path.join(__dirname, '..', 'docs/realm-of-spirits/studio/_city_hex3');
const i = Number(process.argv[2] || 0);
const file = path.join(base, `code_only_${i}.luau`);
const code = fs.readFileSync(file, 'utf8');
console.log(JSON.stringify({ batch: i, codeLen: code.length, endsWithReturn: code.trim().endsWith('return #acc.Value') }));
