# Handoff — passo 14: Fase 2b, round 2 — separar lentidão de não-determinismo

## Contexto mínimo

Round 1 (`docs/RESULT_FASE2B_DIVERGENCE_V1.md`): 3 mecanismos de corrida no caminho do VBlank
identificados; fixes 1+2 (arbitragem request/response do driver + sentinel de exclusividade)
provados por diff, mas revertidos porque o re-aceite deu 2/10 "falhas de evidência". **Análise
do coordenador: as 2 falhas foram TIMEOUT, não PCs divergentes — e o RESULT registra que o
boot ficou mais lento (não travado; 6/6 terminam em 90s).** O critério atual carimba corrida
lenta como evidência inválida, misturando dois problemas distintos.

## Objetivo

1. Reaplicar fixes 1+2 (estão descritos no RESULT; o diff revertido está na história local do
   submódulo se precisar — `git log -g`/stash, senão reimplementar do RESULT).
2. **Medir determinismo e desempenho separadamente:**
   - Determinismo: 10 corridas com janela folgada (60s) e/ou budget reduzido para o marcador
     bater antes do timeout. Métrica: **PCs distintos entre corridas com marcador válido**.
     Aceite: 1 PC único em todas as corridas válidas, com ≥8/10 válidas.
   - Desempenho: medir ticks/segundo (ou tempo até o marcador) antes/depois dos fixes.
     Se os fixes custam >2x, otimizar o mecanismo (ex.: handshake sem wake extra — o RESULT
     sugere investigar a lentidão antes do fix 3) até voltar à mesma ordem de grandeza.
3. Fix 3 (`WaitForNextVSyncTick`/condition_variable separado) SÓ depois de 1-2 estarem
   estáveis e rápidos — e só se os PCs válidos ainda divergirem.
4. Com 1 PC único + desempenho ok: commitar pacote completo (fixes + contrato de semáforos do
   `RESULT_SEMA_CONTRACT_V1.md` + remoção da flag `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID`),
   suíte completa, seguir o gate (`0x245718` deve cair). M4 = parar, confirmar 3x, reportar.

## Ajuste de ferramenta permitido

Se o classificador do probe não permitir distinguir "timeout mas PC válido", ajustar
`tools/Probe-Repeat.ps1`/`Boot-Probe.ps1` para reportar o PC mesmo em timeout (marcado como
tal) — mudança de MEDIÇÃO, documentada, sem tocar semântica do runtime.

## Regras

As do `STATUS.md`/`WORKFLOW.md` (economia: scripts para logs de 4MB, Haiku para bateladas
mecânicas, janela de leitura mínima). PATH MSYS2; `.o` afetados; relink ≥6 min; CPU limpa;
commits locais sem push; resultado em `docs/RESULT_FASE2B_ROUND2_V1.md`, honesto, mesmo
parcial. Se após ~4 iterações o 1-PC-único não sair: parar e reportar com os dados de
desempenho — decisão de arquitetura volta ao coordenador.
