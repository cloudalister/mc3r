# Handoff — passo 29: grampear o `scePrintf` + corrida longa com linha do tempo

## Contexto mínimo

Passo 28 (`docs/RESULT_TTY_28_V1.md`): TTY implementada, o jogo **falou** —
`liblgdev version 1.11.036` + `EZ Wheel Wrapper v3.02` — e a mensagem revelou que o
`lgdev.irx` reportava versão errada; corrigido, o jogo saiu do halt. PC agora em
`datParser::AddRecord` (`0x55f7c0`), registrando tipos de dado: é inicialização real.

Duas lacunas a fechar neste passo:

1. **Só 2 linhas de fala.** O motor AGE imprime pela **`scePrintf`** (vista no decomp:
   `sceCdRead` chama `scePrintf(0x622d80)`), não pela TTY direta. Grampear `scePrintf`
   (e `printf`/`vprintf` do runtime, se existirem como stub) deve multiplicar o diagnóstico.
2. **Não sabemos se `AddRecord` é progresso ou loop.** Precisa de linha do tempo, não de foto.

## Parte 1 — fazer o jogo falar de verdade

- Localizar `scePrintf` no retail (`work/exports/retail_symbol_port.csv`) e como o runtime a
  trata hoje (stub? TODO_NAMED? não registrada?). Implementar: ler a string de formato do
  guest, os argumentos conforme a ABI MIPS (a0=fmt, a1-a3 + pilha), formatar com cuidado
  (limitar tamanho, tolerar ponteiro inválido sem crashar) e logar com prefixo `[printf]`.
  Suportar pelo menos `%s %d %x %u %c %f`.
- Sem env-gate (é semântica normal). Não travar nem lançar em nenhum caso.

## Parte 2 — corrida longa com LINHA DO TEMPO (diagnóstico, sem mais código)

`$env:MC3_DETERMINISTIC='1'; $env:MC3_DISPATCH_BUDGET='5000000'; $env:MC3_BOOT_TRACE='1'`,
janela de 15 min. Processar o log **por script** (é enorme — nunca ler inteiro) e produzir
`work/exports/longrun_timeline.md` com:

1. **Tempo → função**: a cada N frames, traduzir o PC para o nome mais próximo abaixo via
   `retail_symbol_port.csv`. A pergunta que isso responde: o boot **caminha por funções
   diferentes** (progresso) ou **circula entre poucas** (loop)?
2. **Top-20 funções por tempo/amostras** — onde ele gasta a vida.
3. Todas as linhas `[tty]`/`[printf]` na ordem, com o timestamp/tick.
4. LBAs lidos do CD ao longo do tempo (streaming continua?).
5. `gifPk1/2/3`, `gsPrims`, `gsPixels` ao longo do tempo.
6. Onde termina e por quê (orçamento? loop? exceção? `TODO_NAMED` novo — se sim, LISTE com
   contagem, vira o próximo handoff).

## Aceite

`longrun_timeline.md` respondendo "progresso ou loop?" com evidência + o diagnóstico do jogo
(`[printf]`) capturado. Se for **loop**: identificar a condição que ele espera (decomp
nomeado) e propor o próximo passo. Se for **progresso**: dizer até onde chegou e qual a
próxima fronteira.

M4 (`gifPkTotal>0` E `gsPrims>0`) = PARAR, confirmar 3x, reportar na hora. `gsPixels>0` =
anotar commit/env/comando (primeiro framebuffer da história).

## Regras

`STATUS.md`/`WORKFLOW.md`: sem env-gate novo; sem SignalSema injetado; sem chute; scheduler
intacto; `find_stale.py`=0 antes do relink; relink nunca concorrente (PATH MSYS2, ≥6 min);
suíte (277/278, flake do `sceGsSyncV` conhecido); commits locais SEM push; resultado honesto em
`docs/RESULT_LONGRUN_29_V1.md`.
