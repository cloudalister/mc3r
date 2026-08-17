#!/usr/bin/env python3
# Casa funcoes do alpha 102404 (nomeadas via MC.MAP) com o retail SLUS_213.55.
# Etapa 1: hash exato de bytes mascarados (imediatos lui/load/store e alvos de jal zerados).
# Etapa 2: propagacao por callgraph (o k-esimo jal de um par casado vota no par de alvos).
# Saida: work/exports/retail_symbol_port.csv + resumo no stdout.

import csv
import hashlib
import re
import struct
import sys
from collections import defaultdict

ROOT = sys.argv[1] if len(sys.argv) > 1 else r"E:\Games\Emuladores\Sony\mc3recomp"
ALPHA_ELF = ROOT + r"\MIDNIGHT CLUB 3 DUB PS2 ALPHA BUILD 102404\SLUS_123.45"
ALPHA_MAP = ROOT + r"\MIDNIGHT CLUB 3 DUB PS2 ALPHA BUILD 102404\MC.MAP"
RETAIL_ELF = ROOT + r"\extracted_iso\SLUS_213.55"
RETAIL_CSV = ROOT + r"\work\exports\SLUS_213.55.ghidra.csv"
OUT_CSV = ROOT + r"\work\exports\retail_symbol_port.csv"

KEY_RETAIL = [0x398B18, 0x398A60, 0x3984C0, 0x398610, 0x3986D8, 0x398730, 0x398788,
              0x4F9A68, 0x4FAED8, 0x4FA7A8, 0x4FB0D8, 0x4F9760,
              0x5422C8, 0x5420C0, 0x541968, 0x5424A8, 0x549680, 0x54A080,
              0x245568, 0x2B4438, 0x42EB08, 0x447928, 0x5A8898, 0x4BD488]


class Elf:
    def __init__(self, path):
        self.data = open(path, "rb").read()
        assert self.data[:4] == b"\x7fELF", path
        phoff, = struct.unpack_from("<I", self.data, 0x1C)
        phentsize, phnum = struct.unpack_from("<HH", self.data, 0x2A)
        self.segs = []
        for i in range(phnum):
            p_type, p_offset, p_vaddr, _, p_filesz = struct.unpack_from(
                "<IIIII", self.data, phoff + i * phentsize)
            if p_type == 1 and p_filesz > 0:
                self.segs.append((p_vaddr, p_filesz, p_offset))

    def read(self, vaddr, size):
        for va, sz, off in self.segs:
            if va <= vaddr and vaddr + size <= va + sz:
                o = off + (vaddr - va)
                return self.data[o:o + size]
        return None


# opcodes cujo imm16 costuma carregar metade de endereco absoluto
IMM_MASK_OPS = {0x0F}                     # lui
IMM_MASK_OPS |= set(range(0x20, 0x40))    # loads/stores (lb..sd, lq/sq, lwc1 etc)
IMM_MASK_OPS |= {0x08, 0x09, 0x0C, 0x0D}  # addi/addiu/andi/ori (lo16 comuns)


def mask_words(raw):
    out = bytearray()
    n = len(raw) & ~3
    for i in range(0, n, 4):
        w, = struct.unpack_from("<I", raw, i)
        op = w >> 26
        if op in (2, 3):            # j / jal: mantem opcode, zera alvo
            w &= 0xFC000000
        elif op in IMM_MASK_OPS:    # zera imm16, mantem opcode+regs
            w &= 0xFFFF0000
        out += struct.pack("<I", w)
    return bytes(out)


def jal_targets(raw, vaddr):
    tg = []
    n = len(raw) & ~3
    for i in range(0, n, 4):
        w, = struct.unpack_from("<I", raw, i)
        if w >> 26 == 3:
            tg.append(((vaddr + i) & 0xF0000000) | ((w & 0x03FFFFFF) << 2))
    return tg


def strip_params(name):
    depth = 0
    for i, c in enumerate(name):
        if c == "(":
            if depth == 0:
                return name[:i]
            depth += 1
    return name


def load_alpha():
    """MC.MAP -> {addr: (size, nome)} apenas simbolos de .text."""
    sec_re = re.compile(r"^([0-9a-f]{8}) ([0-9a-f]{8})\s+\d+ (\.\S+)\s*$")
    sym_re = re.compile(r"^([0-9a-f]{8}) ([0-9a-f]{8})\s+0 \s+(\S.*?)\s*$")
    text_ranges = []
    cur = None
    lines = open(ALPHA_MAP, "r", errors="replace").read().splitlines()
    for ln in lines:
        m = sec_re.match(ln)
        if m and not ln.startswith("        "):
            cur = m.group(3)
            if cur.startswith(".text"):
                text_ranges.append((int(m.group(1), 16), int(m.group(2), 16)))
    funcs = {}
    for ln in lines:
        m = sym_re.match(ln)
        if not m:
            continue
        addr, size = int(m.group(1), 16), int(m.group(2), 16)
        name = m.group(3)
        if size == 0 or addr == 0:
            continue
        if not any(base <= addr < base + sz for base, sz in text_ranges):
            continue
        if addr not in funcs:
            funcs[addr] = (size, name)
    return funcs


def load_retail():
    funcs = {}
    with open(RETAIL_CSV, newline="") as f:
        for row in csv.DictReader(f):
            addr = int(row["Start"], 16)
            funcs[addr] = (int(row["Size"]), row["Name"])
    return funcs


def main():
    alpha_elf, retail_elf = Elf(ALPHA_ELF), Elf(RETAIL_ELF)
    alpha, retail = load_alpha(), load_retail()
    print(f"alpha .text funcs: {len(alpha)}  retail funcs: {len(retail)}")

    def index(funcs, elf):
        by_hash = defaultdict(list)
        for addr, (size, _name) in funcs.items():
            if size < 8 or size > 0x200000:
                continue
            raw = elf.read(addr, size)
            if raw is None:
                continue
            h = (size, hashlib.md5(mask_words(raw)).digest())
            by_hash[h].append(addr)
        return by_hash

    ah, rh = index(alpha, alpha_elf), index(retail, retail_elf)

    match = {}      # retail_addr -> (alpha_addr, metodo)
    rev = {}        # alpha_addr -> retail_addr
    for h, a_addrs in ah.items():
        r_addrs = rh.get(h)
        if r_addrs and len(a_addrs) == 1 and len(r_addrs) == 1:
            match[r_addrs[0]] = (a_addrs[0], "hash")
            rev[a_addrs[0]] = r_addrs[0]
    print(f"etapa 1 (hash exato unico): {len(match)}")

    # etapa 2: votos de callgraph a partir dos pares casados
    for it in range(12):
        votes = defaultdict(lambda: defaultdict(int))
        for r_addr, (a_addr, _m) in match.items():
            a_size, r_size = alpha[a_addr][0], retail[r_addr][0]
            a_raw, r_raw = alpha_elf.read(a_addr, a_size), retail_elf.read(r_addr, r_size)
            if a_raw is None or r_raw is None:
                continue
            at, rt = jal_targets(a_raw, a_addr), jal_targets(r_raw, r_addr)
            if len(at) != len(rt):
                continue
            for a_t, r_t in zip(at, rt):
                if a_t in alpha and r_t in retail and r_t not in match and a_t not in rev:
                    votes[r_t][a_t] += 1
        added = 0
        for r_t, cands in votes.items():
            if r_t in match:
                continue
            best = sorted(cands.items(), key=lambda kv: -kv[1])
            if len(best) > 1 and best[1][1] == best[0][1]:
                continue  # empate
            a_t, n = best[0]
            if a_t in rev:
                continue
            a_size, r_size = alpha[a_t][0], retail[r_t][0]
            if n < 2 and abs(a_size - r_size) > max(16, 0.25 * max(a_size, r_size)):
                continue
            match[r_t] = (a_t, f"callgraph:it{it}:votes{n}")
            rev[a_t] = r_t
            added += 1
        print(f"etapa 2 it{it}: +{added} (total {len(match)})")
        if added == 0:
            break

    with open(OUT_CSV, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["retail_addr", "retail_old_name", "alpha_addr", "alpha_name",
                    "alpha_label", "method", "alpha_size", "retail_size"])
        for r_addr in sorted(match):
            a_addr, method = match[r_addr]
            a_size, a_name = alpha[a_addr]
            r_size, r_name = retail[r_addr]
            w.writerow([f"0x{r_addr:08X}", r_name, f"0x{a_addr:08X}", a_name,
                        strip_params(a_name), method, a_size, r_size])
    print(f"gravado: {OUT_CSV}  ({len(match)} pares, "
          f"{100.0 * len(match) / len(retail):.1f}% do retail)")

    print("\n== enderecos-chave do boot ==")
    for k in KEY_RETAIL:
        if k in match:
            a_addr, method = match[k]
            print(f"0x{k:08X} -> {alpha[a_addr][1]}   [{method}, alpha 0x{a_addr:08X}]")
        else:
            print(f"0x{k:08X} -> (sem match)")


if __name__ == "__main__":
    main()
