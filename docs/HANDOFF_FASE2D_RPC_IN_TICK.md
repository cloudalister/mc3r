# Handoff — passo 18 (Fase 2d): respostas RPC dentro do turno + budget que alcance o território novo

## Contexto mínimo

Passo 17 (`docs/RESULT_DISKREADY_059C_V1.md`): o disco-pronto funciona — o boot atravessa
`0x245720` e alcança `0x542230`/`0x5494e0` (território inédito) — mas (a) o budget de 25000
esgota no meio do caminho novo e (b) 3 corridas deram 2 PCs finais distintos. Suspeita
principal (mesmo padrão vencido na Fase 2c com o VBlank): a **entrega das respostas RPC/SIF
ao guest acontece fora do turno determinístico do scheduler** — a ordem de acordar o
cliente varia entre corridas.

## Objetivo

1. **Diagnóstico primeiro**: 1 corrida com `MC3_DISPATCH_BUDGET=100000` (anotado como
   diagnóstico) — até onde o boot honesto vai de verdade? Onde estabiliza? `sceCdRead`
   fno=1 dispara com budget maior?
2. **Determinismo da entrega RPC**: mapear COMO a resposta implementada chega ao guest hoje
   (quem escreve o recv buffer e quem sinaliza/acorda o cliente, em qual thread). Se
   qualquer parte roda fora do turno do scheduler (thread host, callback imediato no meio
   do processamento de DMA de outra thread), subordinar ao tick — mesmo princípio da Fase
   2c: efeitos visíveis ao guest só em pontos determinísticos (ex.: fila de respostas
   drenada pelo scheduler no início do turno).
3. Recalibrar o budget padrão da medição se o boot agora precisa de mais (documentar o novo
   valor e atualizar `STATUS.md`/probe tooling na entrega).
4. Aceite: `tools/Probe-Repeat.ps1 -Runs 10 -Mode probe -Seconds 90` (budget novo) →
   **1 Stable PC único, 10/10 válidas**, em território ≥ `0x542230` (não regressão para
   `0x245720`). M4 = parar, confirmar 3x, reportar imediatamente.

## Regras

As do `STATUS.md`/`WORKFLOW.md` + build novo (`find_stale.py`=0 antes de relink;
`parallel_compile.py` se muitos `.o`; relink nunca concorrente). Scheduler: mudanças
permitidas SÓ na subordinação da entrega RPC ao tick (não mexer no baton/VBlank aceitos).
Sem env-gate novo; sem SignalSema injetado (a entrega legítima da resposta é o produtor);
sem tempo de host. Suíte completa se mudar tracked. Commits locais SEM push; resultado em
`docs/RESULT_FASE2D_RPC_TICK_V1.md`, honesto. Limite 3 iterações sem o aceite = parar e
reportar com traces.
