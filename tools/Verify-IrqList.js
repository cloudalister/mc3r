const fs=require('fs'),path=require('path'),crypto=require('crypto');
process.chdir(path.resolve(__dirname,'..'));
const elf=fs.readFileSync('extracted_iso/SLUS_213.55');
if(elf.readUInt32LE(0)!==0x464c457f || elf[4]!==1 || elf[5]!==1)throw Error('Expected LE ELF32');
const ph=elf.readUInt32LE(28),sz=elf.readUInt16LE(42),n=elf.readUInt16LE(44);
function word(a) {
  for(let i=0;i<n;i++) {
    const p=ph+i*sz,va=elf.readUInt32LE(p+8),len=elf.readUInt32LE(p+16);
    if(elf.readUInt32LE(p)===1 && a>=va && a+4<=va+len)return elf.readUInt32LE(elf.readUInt32LE(p+4)+a-va);
  }
  throw Error('Unmapped address');
}
const src=fs.readFileSync('work/generated/ghidra/FUN_0054cb58_0x54cb58.cpp','utf8');
const seen=new Set();
for(const m of src.matchAll(/\/\/ 0x([0-9a-f]+): 0x([0-9a-f]+)\s/gi)) {
  const a=parseInt(m[1],16);
  if(word(a)!==parseInt(m[2],16))throw Error('ELF mismatch '+m[1]);
  seen.add(a);
}
for(let a=0x54cb58;a<0x54cce8;a+=4)if(!seen.has(a))throw Error('Missing annotation '+a.toString(16));
console.log('PASS '+seen.size+' instruction annotations match ELF; this is opcode provenance, not a full semantic oracle.');
console.log('Owner SHA256='+crypto.createHash('sha256').update(src).digest('hex'));
