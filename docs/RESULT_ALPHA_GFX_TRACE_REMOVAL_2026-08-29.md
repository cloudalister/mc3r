# RESULT — Remoção dos traces gfx em endereços do alpha build — 2026-08-29

## Resultado

**Concluído.** A instrumentação `mc3-gfx-*` colocada nos owners dos endereços do
**alpha build** foi removida. A instrumentação correta, nos owners **retail**,
permaneceu intacta. O runner foi relinkado e cada string `mc3-gfx-*` agora
aparece exatamente uma vez no executável (antes: duas).

Nenhuma medição foi feita neste lote — é uma correção de instrumentação.

## Por que era um defeito

O runner executa o retail `SLUS_213.55`. Conferido em
`work/exports/retail_symbol_port.csv`, cujo cabeçalho é
`retail_addr,retail_old_name,alpha_addr,alpha_name,...`:

| Símbolo | retail | alpha |
|---|---|---|
| `gfxModel::Draw` | `0x001EB998` | `0x001E5198` |
| `gfxGetModel` | `0x001ED340` | `0x001E6B40` |
| `gfxGeometry::Draw` | `0x001ED930` | `0x001E7158` |
| `gfxGeometry::LoadMod` | `0x001EEC50` | `0x001E8478` |

Em 2026-08-28 16:02 foram instrumentados os owners dos endereços **alpha**:
`sub_001E50E0`, `sub_001E66E8`, `FUN_001e7118`, `FUN_001e8448`. No binário
retail esses endereços não são as funções de gfx — não têm sequer linha própria
como `retail_addr` no symbol port.

Consequência concreta: se um desses traces disparasse, imprimiria
`[boot-trace:mc3-gfx-model-draw]` para uma função que **não** é
`gfxModel::Draw`, gerando falsa evidência de carregamento/desenho de modelo 3D.
Como "zero traces `mc3-gfx-*`" vinha sendo usado como critério honesto de
"ainda não há carro", um falso positivo aqui corromperia justamente a métrica
que protege o projeto de anunciar vitória inexistente.

Defeito secundário: o bloco foi inserido **antes** do `switch (ctx->pc)` de
resume, então dispararia em toda reentrada de continuation, não só em chamada
real. A instrumentação retail está depois do switch, no caminho de entrada.

## O que foi feito

Script idempotente `work/scratch/remove_alpha_gfx_traces.py`. Para cada um dos
quatro arquivos alpha remove: o bloco de trace, a declaração
`static uint32_t g_mc3Gfx*TraceCount`, e o `#include <cstdio>` (apenas quando
nenhum `fprintf` sobra). O script tem guarda explícita que falha se a
instrumentação retail desaparecer.

```
LIMPO: sub_001E50E0_0x1e50e0.cpp (25262 -> 24923 bytes)
LIMPO: sub_001E66E8_0x1e66e8.cpp (70848 -> 70512 bytes)
LIMPO: FUN_001e7118_0x1e7118.cpp (17807 -> 17459 bytes)
LIMPO: FUN_001e8448_0x1e8448.cpp (14824 -> 14476 bytes)
OK preservado (retail): sub_001EB998 / sub_001ED340 / sub_001ED930 / sub_001EEC50
```

Os quatro arquivos voltaram exatamente à forma gerada original.

## Achado colateral — manifesto de build dessincronizado

Depois de editar os quatro `.cpp`, `tools/find_stale.py` reportou
**`Stale (hash/mtime): 0`**.

Causa: os quatro objetos foram compilados em 2026-08-28 16:02/16:03 **sem
atualizar `work/exports/compile_manifest.json`**. O manifesto continuava com o
SHA-256 do `.cpp` original; ao restaurar o conteúdo original, o hash voltou a
casar e a ferramenta declarou tudo fresco — enquanto os `.o` em disco ainda
continham o trace alpha.

Verificação direta que expôs a divergência:

```
sub_001E50E0_0x1e50e0   obj=2026-08-28 16:02:59  grep -ac 'mc3-gfx-' = 1
sub_001E66E8_0x1e66e8   obj=2026-08-28 16:03:00  grep -ac 'mc3-gfx-' = 1
FUN_001e7118_0x1e7118   obj=2026-08-28 16:03:00  grep -ac 'mc3-gfx-' = 1
FUN_001e8448_0x1e8448   obj=2026-08-28 16:03:00  grep -ac 'mc3-gfx-' = 1
```

Correção aplicada: remoção cirúrgica das quatro entradas do manifesto
(15811 → 15807), forçando `find_stale` a marcá-las como stale. Nenhum artefato
foi apagado. Após `parallel_compile.py`, o manifesto voltou a 15811.

```
candidates: 4 to compile: 4 hash-skipped: 0
DONE total=4 failures=0 elapsed=6s
sub_001E50E0_0x1e50e0   obj=2026-08-29 02:23:35  grep -ac 'mc3-gfx-' = 0
sub_001E66E8_0x1e66e8   obj=2026-08-29 02:23:35  grep -ac 'mc3-gfx-' = 0
FUN_001e7118_0x1e7118   obj=2026-08-29 02:23:35  grep -ac 'mc3-gfx-' = 0
FUN_001e8448_0x1e8448   obj=2026-08-29 02:23:35  grep -ac 'mc3-gfx-' = 0
```

**Risco em aberto:** se outros objetos foram compilados fora do
`parallel_compile.py`, o manifesto pode estar mentindo em mais lugares. Uma
auditoria de hash completa (recalcular SHA-256 de todos os `.cpp` contra o
manifesto e contra a data dos `.o`) ainda não foi feita.

Isso é exatamente a classe de bug que `docs/INCREMENTAL_BUILD.md` foi escrito
para evitar.

## Relink e verificação

```
10_link_partial_runner.bat fast   -> exit 0
mc3_partial.exe                   -> 2026-08-29 02:27, 521904029 bytes
libps2_runtime.a                  -> 2026-08-28 13:40 (exe mais novo, OK)
missing_functions.partial.manifest.csv -> somente cabeçalho
```

Contagem de strings no executável:

| String | Antes | Depois |
|---|---:|---:|
| `mc3-gfx-model-draw` | 2 | **1** |
| `mc3-gfx-get-model` | 2 | **1** |
| `mc3-gfx-geometry-draw` | 2 | **1** |
| `mc3-gfx-geometry-load` | 2 | **1** |
| `dmac-vif0-chain` | 1 | 1 |

Nota de processo: durante a espera do link eu verifiquei o exe cedo demais e o
vi com 0 bytes, concluindo momentaneamente que o link havia falhado. Estava
errado — `ld` ainda estava escrevendo o arquivo. O watcher checava só `ld.exe`,
que ainda não havia subido enquanto `g++`/`collect2` inicializavam. Espera
correta é por `ld.exe` **e** `collect2.exe`.

## Pendências

1. Auditoria de hash completa do `compile_manifest.json`.
2. Árvore suja grande no submódulo: 27 arquivos, +2422 linhas não commitadas
   (`ps2_vu1.cpp` +402, `ps2_vif1_interpreter.cpp` +490, `ps2_runtime.cpp` +370,
   GS, rasterizer, Pad, SIF, scheduler), mais ~10 RESULT docs untracked de
   25-26/08.
3. Probe longo no binário atual — nunca foi medido com um probe documentado.
4. Trabalho do Codex entre 14:27 e 17:40 (regiões Ghidra, relink, benchmark)
   segue sem RESULT próprio.

Sem SignalSema injetado, sem env-gate novo, sem mudança de scheduler/dispatcher/
SIF, sem PCSX2, sem janela visível e sem push.
