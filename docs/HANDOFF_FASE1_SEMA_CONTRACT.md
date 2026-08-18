# Handoff — passo 12: contrato de retorno dos syscalls de semáforo (camada congelada, DESCONGELADA para este escopo)

## Autorização

`Sync.cpp` é camada congelada da Fase 2. O coordenador autoriza mudança **somente** no
contrato de valor de retorno dos syscalls de semáforo, com re-aceite completo da Fase 2 como
condição de entrega. Nada de mexer na mecânica de troca de contexto/baton.

## Contexto mínimo

Passo 11 (`docs/RESULT_CDCACHE_DISKREADY_V1.md`): o gate `0x245718` é causado por `PollSema`
retornando `KE_OK` (0) no sucesso, quando o kernel real do EE retorna o **id do semáforo**.
O jogo compara o retorno contra o sid → sucesso vira falha eterna. Prova empírica: flag
pré-existente `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID=1` derruba o gate imediatamente.

## Objetivo

Contrato de retorno correto do kernel EE em TODA a família de semáforos, permanente, sem flag:

1. Auditar contra o contrato real (referência: decomp do próprio jogo — como o retorno é
   consumido nos call sites nomeados — e a documentação de kernel EE; em caso de conflito, o
   comportamento que o binário retail espera vence): `PollSema`, `WaitSema`, `SignalSema`,
   `iSignalSema`, `iPollSema`, `CreateSema`, `DeleteSema`, `ReferSemaStatus`,
   `iReferSemaStatus`. Contrato esperado (confirmar um a um): sucesso retorna **sid** para
   Poll/Wait/Signal/Delete/Refer; `CreateSema` retorna o sid novo; erros retornam negativos
   (`KE_SEMA_ZERO=-419` etc.).
2. Corrigir os que divergirem; **remover** a flag `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID`
   (o comportamento correto vira o único).
3. Varrer o runtime por chamadas internas que dependem do retorno antigo (`grep PollSema|
   WaitSema` fora de Sync.cpp) e ajustar.

## Validação (bateria completa — obrigatória por tocar camada da Fase 2)

1. Suíte completa (271, 1 flake documentado) — atualizar testes que assumiam retorno 0 com
   comentário citando o contrato.
2. Relink + **re-aceite da Fase 2**: `21_probe_repeat.bat 10 probe sema_contract_v1` →
   exigido: 1 único Stable PC em 10/10 com evidência válida (o mesmo critério que aceitou a
   fase). Regressão disso = reverter e reportar.
3. Seguir o gate: com o contrato correto, `0x245718` deve cair; continuar o rastreio
   (provável próxima parada: a cadeia real do psxCdCache/leituras de DAT). M4 = parar,
   confirmar 3x, reportar.

## Aceite

Gate `0x245718` cai pela correção permanente + 10/10 determinístico mantido + suíte verde.

## Regras

As do `STATUS.md`/`WORKFLOW.md`. PATH MSYS2; recompilar `.o` afetados; relink ≥6 min;
commits locais sem push; resultado em `docs/RESULT_SEMA_CONTRACT_V1.md`.
