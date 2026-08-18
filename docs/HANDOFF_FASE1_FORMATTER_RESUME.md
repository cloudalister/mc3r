# Handoff — passo 9: o sprintf mudo (`sub_0042F558` retorna 0) e as tabelas de resume

## Contexto mínimo

Passo 8 (`docs/RESULT_BOOT_ARGS_V1.md`): `sub_0042F558_0x42f558` (motor de formatação genérico
do jogo) retorna `v0=0` com argumentos `%s%s` válidos, em 2 call sites independentes,
deterministicamente. Sem o path montado, o provider nunca abre o `ASSETS.DAT` e o boot morre
em `0x5a8908`. Suspeita principal do coordenador: **tabela de resume incompleta** — o
`switch(ctx->pc)` de função gerada não tem case para algum label onde o scheduler cooperativo
retoma, caindo em `default` e retornando com estado errado. Precedente documentado e nunca
consertado: `docs/HANDOFF_2026-08-07_B_DISPATCH_0x42EB48.md` (regeneração de 01/08 apagou os
cases `0x42EB48/0x42EB90` de `sub_0042EB08`; `first-bad-pc=0x42eb48` aparecia em 100% das
corridas da época).

## Objetivo

`sub_0042F558` formata corretamente (path `cdrom0:\assets.dat` montado no trace), pela causa
raiz — e a classe do bug (labels de resume ausentes) fica fechada para o repo inteiro, não só
para uma função.

## Método

1. **Confirmar o mecanismo** (barato): no trace com `MC3_TRACE_PROVIDER` (instrumentação do
   passo 8 já existe nos gerados), capturar o PC de entrada e o caminho de saída da chamada que
   retorna 0. Cruzar com os labels do `switch(ctx->pc)` de `sub_0042F558_0x42f558.cpp` gerado:
   o resume acontece num label que existe? O `[dispatch:first-bad-pc]` do runtime acusa algo?
2. **Diagnóstico da classe**: script (Python) que, para TODO arquivo em
   `work/generated/ghidra/`, extrai (a) os alvos de branch/labels internos do código MIPS
   original (via CSV/export do Ghidra ou parse dos comentários do gerado) e (b) os cases do
   `switch(ctx->pc)` — e lista TODA função com label alcançável sem case. Isso transforma
   "caça um bug" em "fecha a classe". Rodar e salvar `work/exports/resume_gaps.csv`.
3. **Consertar a geração, não o sintoma**: se o gap vier do exporter/recompiler
   (`ExportPS2Functions.java` / ps2xRecomp), corrigir lá e regenerar as funções afetadas
   (não patch manual que a próxima regeneração apaga — lição de 01/08). Se for pontual,
   regenerar só as afetadas com o fix. Recompilar os `.o` afetados + relink.
4. Validar: `sub_0042F558` retorna >0 no trace; path montado; seguir o gate. Se o `0x5a8908`
   cair e o provider abrir o DAT: seguir até M4 (`gifPackets>0` E `gsPrims>0` → parar,
   confirmar 3x, reportar).

## Aceite

Path `cdrom0:\assets.dat` visível no open do provider (trace) + `resume_gaps.csv` gerado com
a classe mapeada (mesmo que o fix cubra só as funções do caminho crítico nesta sessão).

## Regras

As do `STATUS.md` + economia do `WORKFLOW.md`. PATH do MSYS2 antes de compilar (libmpfr).
Mudança no recompiler/exporter = mudança tracked no fork → suíte obrigatória. Commits locais
sem push; resultado em `docs/RESULT_FORMATTER_RESUME_V1.md`.
