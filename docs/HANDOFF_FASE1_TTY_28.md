# Handoff — passo 28: deixar o jogo FALAR (sceTtyWrite) e seguir o que ele contar

## Contexto mínimo

Passo 27 (`docs/RESULT_BOUNDARY_PORT_27_V1.md`) portou 585 fronteiras de função do MC.MAP:
`bad=` zerado em todas as corridas, `ASSETS.DAT` sendo lido de verdade. O boot agora avança até
**`sceTtyWrite`** — e aí morre: em `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/TTY.cpp:57` ela é
`TODO_NAMED`, que **lança `std::runtime_error`** nas primeiras chamadas por nome
(`Kernel/Stubs/Unimplemented.cpp`), depois passa a devolver -1.

Ou seja: o jogo chegou ao ponto de **narrar o próprio boot** (o motor AGE imprime muito) e o
runtime o derruba no meio da primeira frase. Implementar isso é barato e devolve a informação
mais valiosa possível: o diagnóstico do próprio jogo.

## Objetivo

1. `sceTtyWrite` (e irmãs `TODO_NAMED` do mesmo arquivo, 5 no total) implementadas de verdade:
   escrever os bytes do guest em log/stdout com prefixo (`[tty]`), respeitando fd/len, sem
   travar nem lançar.
2. Uma corrida determinística com o log do jogo capturado.
3. **Seguir o que o jogo disser** — o RESULT tem que trazer as mensagens (íntegras) e a leitura
   delas: o que ele carrega, o que ele reclama, onde para.

## Método

1. Ler `TTY.cpp` + `Unimplemented.cpp` (o comportamento do TODO_NAMED) + como outros stubs
   pegam args do guest (`Kernel/Stubs/Helpers/Support.h`).
2. Implementar: buffer do guest → string → log. Cuidado com fd (1/2), tamanho, e strings sem
   terminador. Nada de env-gate: TTY é semântica normal do kernel.
3. Build só do runtime (`.o` do jogo não muda) → `find_stale.py` = 0 → relink (PATH MSYS2,
   nunca concorrente, ≥6 min) → suíte (275).
4. 1 corrida determinística (`$env:MC3_DETERMINISTIC='1'; $env:MC3_DISPATCH_BUDGET='100000'`,
   90s) com `MC3_BOOT_TRACE=1`; extrair TODAS as linhas `[tty]` para
   `work/exports/tty_boot.txt` (por script; o trace é grande).
5. Analisar: as mensagens dizem o que falta? Se apontarem um bloqueio concreto e barato
   (arquivo não encontrado, subsistema não inicializado, valor inesperado), **conserte na mesma
   sessão** pelo caminho legítimo e repita a corrida (limite 3 iterações).
6. `21_probe_repeat` 3x no fim.

## Aceite

Mensagens do jogo capturadas em `work/exports/tty_boot.txt` (com pelo menos uma dezena de
linhas reais) + PC estabilizando além do ponto do `sceTtyWrite` + interpretação escrita no
RESULT. M4 (`gifPkTotal>0` E `gsPrims>0`) = PARAR, confirmar 3x, reportar na hora;
`gsPixels>0` = anotar commit/env/comando (primeiro framebuffer da história).

## Regras

`STATUS.md`/`WORKFLOW.md`: sem env-gate novo; sem SignalSema injetado; sem chute; scheduler
intacto; commits locais SEM push; resultado honesto em `docs/RESULT_TTY_28_V1.md`.
Se outras funções `TODO_NAMED` explodirem logo depois (o boot vai fundo agora), liste-as no
RESULT com contagem — vira o próximo handoff, não improvise implementação em massa.
