# Handoff — passo 15 (Fase 2c): VBlank DENTRO do tick — matar a segunda thread

## Estratégia (decisão do coordenador após 3 rounds)

Rounds 1-2 da Fase 2b provaram 3 mecanismos de corrida entre a thread host do VBlank e o
scheduler determinístico; consertar as disputas uma a uma não convergiu (sempre sobra uma).
**Redesenho: no modo determinístico, a thread de VBlank não participa.** O próprio scheduler
(dono do baton) avança o VBlank inline, dentro do seu turno: a cada N handoffs de baton (N
fixo, derivado do que hoje é a cadência) ou no idle, o scheduler chama a sequência do tick
(latch INTC_STAT, toggle CSR.FIELD, wake dos waiters de vsync) **sob o mesmo lock/turno**.
Sem segunda thread no caminho, a classe de corrida deixa de existir. Modo normal (env off)
continua com a thread como está.

## Passo 0 — OBRIGATÓRIO antes de qualquer medição: reconstruir o mundo

O estado atual tem **exe possivelmente stale**: o código-fonte foi revertido (round 2) mas o
exe é do build com os fixes (18/08 ~23h). As duas últimas medições (5/5 timeout, PC
`0x1a0138`, marker ausente) são lixo por isso e/ou por env vars mal setadas.

1. Rebuild da lib (`ps2_runtime`) a partir do fonte atual (revertido) + relink completo
   (`10_link_partial_runner.bat fast`, timeout ≥6 min). Conferir: exe MAIS NOVO que a lib.
2. Env vars SEMPRE via PowerShell nativo: `$env:MC3_DETERMINISTIC='1';
   $env:MC3_DISPATCH_BUDGET='25000'` na MESMA sessão que chama o .bat (a armadilha
   `set X=1` do PowerShell já invalidou medições 2x — RESULT do passo 5 e do round 2).
3. Baseline: `21_probe_repeat.bat 5 probe fase2c_baseline`. Esperado: corridas válidas
   (marker=yes) na família `0x245718/0x245720`. Se o baseline não sair limpo, PARE e reporte
   — nada de implementar em cima de medição quebrada.

## Implementação

1. Ler `docs/RESULT_FASE2B_DIVERGENCE_V1.md` e `docs/FASE2_SCHEDULER_DESIGN.md` (mecanismos
   e desenho atual) + `DeterministicScheduler.cpp`/`Interrupt.cpp` (onde vive o tick hoje).
2. Modo determinístico: suspender/neutralizar a thread de VBlank (ela não dispara tick);
   o scheduler avança o VBlank inline por contagem de handoffs (constante, sem relógio).
   Escolher N pela cadência atual (documentar a conta). Waiters de vsync acordam pelo
   caminho normal de ready-queue do próprio scheduler, no mesmo turno.
3. Reaplicar o contrato de semáforos (`RESULT_SEMA_CONTRACT_V1.md`) — ele é pré-requisito
   para alcançar a profundidade onde a divergência aparecia — e remover a flag
   `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID`.
4. Rebuild/relink; suíte completa (271; testes de VBlank que assumem a thread podem precisar
   de ajuste no modo determinístico — comentar cada ajuste).

## Aceite

`21_probe_repeat.bat 10 probe fase2c_v1` (janela 30s): **1 Stable PC único, 10/10 com
evidência válida**. Medir também tempo-até-marcador vs baseline (não pode passar de 2x).
Com aceite: commitar pacote completo, seguir o gate (`0x245718` deve cair; M4 = parar,
confirmar 3x, reportar imediatamente).

## Regras

As do `STATUS.md`/`WORKFLOW.md` (economia: logs por script, Haiku pra bateladas, janela
mínima). PATH MSYS2; CPU limpa; sem tempo de host no caminho determinístico (a contagem de
handoffs substitui o relógio); commits locais SEM push; resultado honesto em
`docs/RESULT_FASE2C_V1.md` mesmo parcial. Limite: se após 3 iterações o 1-PC não sair,
parar e reportar com os traces — decisão volta ao coordenador.
