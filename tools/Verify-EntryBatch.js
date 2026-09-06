// Read-only ELF/source/registration verification for the 2026-09-06 batch.
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');
process.chdir(path.resolve(__dirname, '..'));
const elf = fs.readFileSync('extracted_iso/SLUS_213.55');
if (elf.readUInt32LE(0) !== 0x464c457f || elf[4] !== 1 || elf[5] !== 1)
  throw Error('Expected little-endian ELF32');
const ph = elf.readUInt32LE(28), size = elf.readUInt16LE(42), count = elf.readUInt16LE(44);
if (size < 32 || ph + size * count > elf.length) throw Error('Invalid program headers');
function word(a) {
  for (let i=0; i<count; i++) {
    const p=ph+i*size, va=elf.readUInt32LE(p+8), len=elf.readUInt32LE(p+16);
    if (elf.readUInt32LE(p)===1 && a>=va && a+4<=va+len) {
      const off=elf.readUInt32LE(p+4)+a-va;
      if (off+4>elf.length) throw Error('Invalid segment');
      return elf.readUInt32LE(off);
    }
  }
  throw Error(`Unmapped ${a.toString(16)}`);
}
const owners = [
  ['FUN_005b9500_0x5b9500', ['5b94f0','5b94f8']],
  ['FUN_005b9908_0x5b9908', ['5b9990','5b9998']],
  ['sub_00501088_0x501088', ['501268','5012c0']],
  ['sub_0042BE50_0x42be50', ['42bf00']],
];
const register = process.argv.includes('--register') ? fs.readFileSync('work/link/partial/register_functions.partial.cpp','utf8') : null;
for (const [owner, entries] of owners) {
  const raw=fs.readFileSync(`work/generated/ghidra/${owner}.cpp`), src=raw.toString('utf8');
  let checked=0;
  for (const m of src.matchAll(/\/\/ 0x([0-9a-f]+): 0x([0-9a-f]+)\s/gi)) {
    if (word(parseInt(m[1],16)) !== parseInt(m[2],16)) throw Error(`ELF mismatch ${owner}:${m[1]}`);
    checked++;
  }
  if (!checked) throw Error('No instruction annotations');
  for (const entry of entries) {
    if (!src.includes(`case 0x${entry}u: goto label_${entry};`) || !src.includes(`label_${entry}:`))
      throw Error(`Missing dispatch hook ${entry}`);
    if (entry.startsWith('5b')) {
      const a=parseInt(entry,16);
      if (word(a)!==0x03e00008 || word(a+4)!==0) throw Error(`Not jr-ra/nop: ${entry}`);
    }
    if (register && !register.includes(`runtime.registerFunction(0x${entry}u, ${owner});`))
      throw Error(`Missing actual partial registration ${entry}`);
  }
  console.log(`PASS ${owner}: ${checked} annotated words match ELF; entries=${entries}; SHA256=${crypto.createHash('sha256').update(raw).digest('hex')}`);
}
