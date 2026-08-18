#!/usr/bin/env python3
"""
Mapeia a CLASSE inteira de gaps de resume no switch(ctx->pc) das funcoes
geradas em work/generated/ghidra/*.cpp.

Ver docs/RESULT_FORMATTER_RESUME_V1.md para o mecanismo confirmado por trace
nesta sessao. Duas sub-classes distintas, ambas causadoras do MESMO sintoma
(a funcao reinicia silenciosamente do zero em vez de retomar no PC certo,
porque `switch (ctx->pc)` nao tem `case` para esse PC -- sem erro visivel,
sem "[dispatch:first-bad-pc]", porque lookupFunction() acha a funcao dona
normalmente):

Mecanismo A -- preempcao cooperativa (Fase 2, MC3_DETERMINISTIC=1). O codegen
emite, para todo back-edge preemptivel:

    ctx->pc = 0x<TARGET>u;
    if (runtime->shouldPreemptGuestExecution()) {
        return;
    }
    goto label_<target>;

TARGET precisa de `case 0x<TARGET>u:` no switch(ctx->pc) do topo da MESMA
funcao. Auditoria da sessao de 18/08: 0 gaps reais desse tipo em todo o
corpus (15812 arquivos) -- a hipotese inicial do handoff
(docs/HANDOFF_FASE1_FORMATTER_RESUME.md: "tabela de resume incompleta =
bug de preempcao") foi refutada por essa varredura.

Mecanismo B -- entrada externa por endereco computado (a causa raiz real,
confirmada por trace ao vivo: sub_0042F558 faz `jalr $s5` com $s5 construido
em OUTRA funcao via `lui $reg,hi` / `addiu|ori $reg2,$reg,lo` (idioma `la`),
apontando para o MEIO do corpo de uma TERCEIRA funcao (sub_0042EB08,
enderecos 0x42EB48/0x42EB90). Como o alvo do jalr e um valor de runtime,
nenhuma analise por-funcao consegue ver esse alvo -- so o proprio codegen
(corrigido em PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp,
collectInternalBranchTargets: scan de enderecos tomados via lui+addiu/ori)
sabe popular esse case. Este script reproduz esse scan em Python sobre o
corpo JA GERADO (parseando os comentarios de disassembly que o codegen
preserva, ex. "// 0x42fa9c: 0x3c020043  lui $v0, 0x43"), cruzando
func.start/end e o conjunto real de enderecos de instrucao de TODOS os
arquivos, para auditar se o corpus atual ainda tem alguma lacuna dessa
classe (util como regressao apos qualquer regeneracao futura).

Uso:
    python tools/Find-ResumeGaps.py [generated_dir] [out_csv]
    (default: work/generated/ghidra -> work/exports/resume_gaps.csv, ambos
    relativos a raiz do repo quando rodado de la; aceita caminhos absolutos)

Saida: CSV com colunas file,function,func_start,func_end,gap_pc,kind,line_no,detail
Uma corrida sem linhas (so cabecalho) = classe fechada no corpus atual.
"""
import bisect
import csv
import os
import re
import sys

DEFAULT_GEN_DIR = os.path.join("work", "generated", "ghidra")
DEFAULT_OUT_CSV = os.path.join("work", "exports", "resume_gaps.csv")

GEN_DIR = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_GEN_DIR
OUT_CSV = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_OUT_CSV

FUNC_HEADER_RE = re.compile(r"^// Function:\s*(\S+)")
ADDR_HEADER_RE = re.compile(r"^// Address:\s*0x([0-9a-fA-F]+)\s*-\s*0x([0-9a-fA-F]+)")
SWITCH_START_RE = re.compile(r"^\s*switch\s*\(\s*ctx->pc\s*\)\s*\{")
CASE_RE = re.compile(r"case\s+0x([0-9a-fA-F]+)u?\s*:")
INSN_COMMENT_RE = re.compile(r"^\s*//\s*0x([0-9a-fA-F]+):\s*0x[0-9a-fA-F]+")
PREEMPT_RE = re.compile(r"if\s*\(\s*runtime->shouldPreemptGuestExecution\(\)\s*\)")
GOTO_LABEL_RE = re.compile(r"goto\s+label_([0-9a-fA-F]+)\s*;")

# Disassembly comments the codegen preserves, e.g.:
#   // 0x42fa9c: 0x3c020043  lui         $v0, 0x43
#   // 0x42fac4: 0x2446eb48  addiu       $a2, $v0, -0x14B8
#   // 0x1604: 0x...          ori         $a2, $v0, 0x14B8
DISASM_RE = re.compile(
    r"^\s*//\s*0x([0-9a-fA-F]+):\s*0x[0-9a-fA-F]+\s+(lui|addiu|ori)\s+"
    r"\$(\w+),\s*(?:\$(\w+),\s*)?(-?0x[0-9a-fA-F]+)"
)

REG_ALIASES = {
    "zero": 0, "at": 1, "v0": 2, "v1": 3, "a0": 4, "a1": 5, "a2": 6, "a3": 7,
    "t0": 8, "t1": 9, "t2": 10, "t3": 11, "t4": 12, "t5": 13, "t6": 14, "t7": 15,
    "s0": 16, "s1": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "t8": 24, "t9": 25, "k0": 26, "k1": 27, "gp": 28, "sp": 29, "fp": 30, "ra": 31,
}


def parse_functions(gen_dir, cpp_files):
    """First pass: collect per-file function metadata needed for both scans."""
    infos = []
    for fname in cpp_files:
        path = os.path.join(gen_dir, fname)
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
        except OSError:
            continue

        fname_val = None
        func_start = func_end = None
        for l in lines[:30]:
            fm = FUNC_HEADER_RE.match(l)
            if fm:
                fname_val = fm.group(1)
            am = ADDR_HEADER_RE.match(l)
            if am:
                func_start = int(am.group(1), 16)
                func_end = int(am.group(2), 16)
        if func_start is None:
            continue

        insn_addrs = set()
        for l in lines:
            im = INSN_COMMENT_RE.match(l)
            if im:
                insn_addrs.add(int(im.group(1), 16))

        switch_cases = set()
        in_top_switch = False
        depth = 0
        for l in lines:
            if not in_top_switch:
                if SWITCH_START_RE.match(l):
                    in_top_switch = True
                    depth = 1
                continue
            depth += l.count("{") - l.count("}")
            for cm in CASE_RE.finditer(l):
                switch_cases.add(int(cm.group(1), 16))
            if depth <= 0:
                break

        infos.append({
            "file": fname,
            "function": fname_val,
            "start": func_start,
            "end": func_end,
            "cases": switch_cases,
            "insn_addrs": insn_addrs,
            "lines": lines,
        })
    return infos


def find_owner(addr, infos_by_start_sorted, starts_cache):
    """Return the info dict of the function whose [start,end) contains addr,
    excluding addr == start (that's just the function's own entry, always
    valid without a case), AND only if addr is a real instruction address of
    that function (mirrors PS2Recompiler::discoverAdditionalEntryPoints's own
    findContainingFunction, which requires hasAddress -- this is exactly what
    keeps this scan honest: a lui/addiu pair building an unrelated 32-bit
    constant that numerically lands inside some function's address range,
    but doesn't align to any actual instruction there, is not a real gap)."""
    idx = bisect.bisect_right(starts_cache, addr) - 1
    if idx < 0:
        return None
    cand = infos_by_start_sorted[idx]
    if cand["start"] <= addr < cand["end"] and addr != cand["start"] and addr in cand["insn_addrs"]:
        return cand
    return None


def scan_mechanism_a(info):
    """Preemption-guarded resume gaps within the SAME function."""
    gaps = []
    lines = info["lines"]
    switch_cases = info["cases"]
    for li, l in enumerate(lines):
        if not PREEMPT_RE.search(l):
            continue
        target = None
        for lookahead in lines[li:li + 6]:
            gm = GOTO_LABEL_RE.search(lookahead)
            if gm:
                target = int(gm.group(1), 16)
                break
        if target is None or target == info["start"]:
            continue
        if target not in switch_cases:
            gaps.append((target, li + 1, "preemption-guarded goto has no matching case"))
    return gaps


def scan_mechanism_b(info, infos_by_start_sorted, starts_cache):
    """lui+addiu/ori constants pointing into ANOTHER function's body."""
    gaps = []
    lines = info["lines"]
    pending_hi = None  # (reg_num, hi_bits, line_no)
    for li, l in enumerate(lines):
        m = DISASM_RE.match(l)
        if not m:
            continue
        _addr_s, op, rt_name, rs_name, imm_s = m.groups()
        rt = REG_ALIASES.get(rt_name)
        if rt is None:
            continue
        # imm_s is already in disassembler sign-extended form (e.g. "-0x14B8"
        # or "0x54C8"), so a plain signed base-16 parse is exactly right.
        imm = int(imm_s, 16)

        if op == "lui":
            pending_hi = (rt, (imm & 0xFFFF) << 16, li)
            continue

        if pending_hi is None:
            continue
        hi_reg, hi_bits, hi_line = pending_hi
        if li - hi_line > 64:
            pending_hi = None
            continue

        rs = REG_ALIASES.get(rs_name) if rs_name else None
        if rs != hi_reg:
            # does this instruction clobber hi_reg before it's consumed?
            if rt == hi_reg:
                pending_hi = None
            continue

        if op == "addiu":
            constant = (hi_bits + imm) & 0xFFFFFFFF
        elif op == "ori":
            constant = hi_bits | (imm & 0xFFFF)
        else:
            pending_hi = None
            continue

        owner = find_owner(constant, infos_by_start_sorted, starts_cache)
        pending_hi = None
        if owner is None or owner is info:
            continue
        if constant not in owner["cases"]:
            gaps.append({
                "owner": owner,
                "gap_pc": constant,
                "line_no": li + 1,
                "detail": f"lui/{op} in {info['function']} (0x{info['start']:x}) builds address-taken constant into this function's body",
            })
    return gaps


def main():
    if not os.path.isdir(GEN_DIR):
        print(f"[ERROR] generated dir not found: {GEN_DIR}", file=sys.stderr)
        sys.exit(2)

    out_dir = os.path.dirname(OUT_CSV)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    cpp_files = sorted(e for e in os.listdir(GEN_DIR) if e.endswith(".cpp")
                        and e != "register_functions.cpp")
    print(f"[find_resume_gaps] parsing {len(cpp_files)} files...", file=sys.stderr)
    infos = parse_functions(GEN_DIR, cpp_files)
    infos_by_start_sorted = sorted(infos, key=lambda i: i["start"])
    starts_cache = [i["start"] for i in infos_by_start_sorted]
    print(f"[find_resume_gaps] parsed {len(infos)} functions, scanning...", file=sys.stderr)

    rows = []
    for idx, info in enumerate(infos):
        for (target, line_no, detail) in scan_mechanism_a(info):
            rows.append([info["file"], info["function"], f"0x{info['start']:x}",
                         f"0x{info['end']:x}", f"0x{target:x}", "A-preemption",
                         line_no, detail])
        for gap in scan_mechanism_b(info, infos_by_start_sorted, starts_cache):
            owner = gap["owner"]
            rows.append([owner["file"], owner["function"], f"0x{owner['start']:x}",
                         f"0x{owner['end']:x}", f"0x{gap['gap_pc']:x}",
                         "B-address-taken-external-entry", gap["line_no"], gap["detail"]])
        if (idx + 1) % 3000 == 0:
            print(f"...{idx + 1}/{len(infos)} functions scanned, {len(rows)} gap rows so far",
                  file=sys.stderr)

    with open(OUT_CSV, "w", newline="", encoding="utf-8") as out_f:
        writer = csv.writer(out_f)
        writer.writerow(["file", "function", "func_start", "func_end", "gap_pc", "kind", "line_no", "detail"])
        writer.writerows(rows)

    a_count = sum(1 for r in rows if r[5] == "A-preemption")
    b_count = sum(1 for r in rows if r[5] == "B-address-taken-external-entry")
    print(f"[find_resume_gaps] functions scanned={len(infos)} "
          f"mechanism-A gaps={a_count} mechanism-B gaps={b_count} total={len(rows)}")
    print(f"[find_resume_gaps] wrote {OUT_CSV}")


if __name__ == "__main__":
    main()
