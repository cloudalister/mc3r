import os, struct, sys

ROOT = r"E:\Games\Emuladores\Sony\mc3recomp"
COMPILE = os.path.join(ROOT, "work", "compile", "ghidra")

# MinGW g++ produces COFF (PE) objects, not ELF. x86-64 COFF: machine 0x8664.
# Header: machine(2) nsec(2) timestamp(4) symtab_off(4) nsyms(4) opthdr(2) chars(2) = 20 bytes
bad = []
n = 0
for dirpath, dirnames, filenames in os.walk(COMPILE):
    for f in filenames:
        if not f.endswith(".o"):
            continue
        p = os.path.join(dirpath, f)
        n += 1
        size = os.path.getsize(p)
        try:
            with open(p, "rb") as fh:
                hdr = fh.read(20)
                if len(hdr) < 20:
                    bad.append((p, size, "header too short")); continue
                machine, nsec, ts, symoff, nsyms, opt, chars = struct.unpack("<HHIIIHH", hdr)
                if machine != 0x8664:
                    bad.append((p, size, "bad machine 0x%x" % machine)); continue
                # symbol table bounds: symoff + nsyms*18 must fit; string table follows
                if symoff and symoff + nsyms * 18 + 4 > size:
                    bad.append((p, size, "symtab out of bounds symoff=%d nsyms=%d" % (symoff, nsyms))); continue
                # section headers: 40 bytes each after header+opt
                sec_end = 20 + opt + nsec * 40
                if sec_end > size:
                    bad.append((p, size, "section headers out of bounds")); continue
                # each section's data bounds
                fh.seek(20 + opt)
                sh = fh.read(nsec * 40)
                for i in range(nsec):
                    name, vsize, vaddr, rawsize, rawptr, relptr, lnptr, nrel, nln, flags = struct.unpack_from("<8sIIIIIIHHI", sh, i * 40)
                    if rawptr and rawptr + rawsize > size:
                        bad.append((p, size, "section %d data out of bounds" % i)); break
                    if relptr and relptr + nrel * 10 > size:
                        bad.append((p, size, "section %d relocs out of bounds" % i)); break
        except Exception as e:
            bad.append((p, size, "exception %s" % e))

print("checked:", n)
print("bad:", len(bad))
for p, size, why in bad:
    print("BAD", size, why, p)
