# Handoff — passo 30: o cartão de memória (loop em `mcMemCard`)

## Contexto mínimo

Corrida longa do passo 29: **é LOOP, não progresso.** Depois da fase inicial, as janelas de
dispatch reportam `uniqueSample=1` no PC `0x1b1610` e todos os contadores de render seguem
zero. O símbolo port localiza o PC dentro de `FUN_001b15d8` (`0x1b15d8-0x1b16bc`), na região
`mcMemCard::DateToSecondsSimplified` (`0x1b1580`), vizinha de
`mcMemCard::HasCareerSavedataChanged` (`0x1b16c0`) e `GetCurrentSavegameVersion` (`0x1b19d0`).

Leitura: o jogo está **checando o cartão de memória atrás do save da carreira** no boot, e a
resposta nunca chega — mesma classe já resolvida para cdvd/usbkb/lgdev.

Insumos prontos: `sceMcInit` (`0x4f6fc8` alpha), `sceMcGetInfo`, `sceMcSync`, `sceMcOpen`,
`sceMcGetDir` etc. nomeados em `work/exports/alpha_decomp_sce.txt`; binds de memory card
`0x80000100`/`0x80000101` já vistos no decomp; módulos `MCMAN.IRX`/`MCSERV.IRX` no disco;
dispatcher SIF por `(sid, fno)` já montado (`SIF.cpp`).

## Objetivo

O subsistema de cartão responde com semântica real e o loop termina. Semântica-alvo (nesta
ordem de preferência, escolher pela evidência do decomp):

1. **"Nenhum cartão inserido"** — resposta limpa e completa; o jogo deve tratar isso e seguir
   (é o caminho normal de console sem cartão).
2. Se o jogo exigir cartão para prosseguir: **cartão presente, formatado e vazio** (sem save
   de carreira), o que também é caminho legítimo (jogador novo).

Nada de forçar flag/valor na marra: preencher a estrutura de resposta que o cliente lê,
conforme o decomp.

## Método

1. Trace dirigido: qual chamada `sceMc*` o loop faz (fno, sid, tamanhos), e o que
   `sceMcSync`/`GetInfo` devolve hoje. A instrumentação do runtime já existe para SIF.
2. Decomp: `sceMcInit`/`sceMcGetInfo`/`sceMcSync` no `alpha_decomp_sce.txt` (extrair por
   `awk`, não ler o arquivo inteiro) — layout de request/response, e o que o cliente testa.
   **Endereço alpha nunca vale no retail sem portar** (lição do passo 21).
3. Implementar no dispatcher por `(sid, fno)`. Sem env-gate.
4. 1 corrida determinística = 1 prova. O loop saiu? Onde estabiliza agora? Iterar (limite 4).
5. `21_probe_repeat` 3x no fim.

## Aceite

PC sai da região `0x1b15xx-0x1b16xx` com evidência de resposta legítima do cartão no trace.
M4 (`gifPkTotal>0` E `gsPrims>0`) = PARAR, confirmar 3x, reportar na hora; `gsPixels>0` =
anotar commit/env/comando (primeiro framebuffer da história).

## Nota de qualidade (coordenador)

No `tools/analyze_longrun.py`, as conclusões ("encerrou por timeout", "evidência de loop…")
estão **hardcoded como texto**. Derive-as dos dados: se o script for reexecutado noutro log,
ele vai mentir. Corrigir junto (é barato) — evidência gerada, não narrada.

## Regras

`STATUS.md`/`WORKFLOW.md`: sem env-gate novo; sem SignalSema injetado; sem chute; scheduler
intacto; `find_stale.py`=0 pré-relink; relink nunca concorrente (PATH MSYS2, ≥6 min); suíte;
commits locais SEM push; resultado honesto em `docs/RESULT_MEMCARD_30_V1.md`.
