# Handoff Gemini - MC3 primeiro frame visivel

Data: 2026-08-09 BRT.

## Papel

Voce e o investigador barato e somente leitura. Sol/Nexo coordena, decide e valida.
Nao implemente, nao edite runtime, nao regenere codigo, nao compile, nao relinke e
nao abra o runner ou PCSX2. Sua funcao e gastar contexto lendo codigo e logs para
entregar evidencias verificaveis e uma recomendacao pequena.

Todo comando de terminal deve passar por `rtk`; para comandos sem filtro proprio,
use `rtk proxy <comando>`.

## Objetivo humano

Cloud quer ver algo real do MC3 na tela. Documentos, Stable PC diferente, DMA ou VIF
sozinho nao contam. Sucesso visual exige `gif > 0` ou `gsw > 0` e depois aceite visual
do Cloud.

## Estado confirmado

Leia nesta ordem:

1. `PS2_PROJECT_STATE.md`
2. `docs/STATUS_2026-08-07_AUDIT.md`
3. `docs/HANDOFF_2026-08-07_A_DETERMINISM.md`
4. `docs/PROBE_MEASUREMENT_FIX_2026-08-08.md`
5. `docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md`
6. `docs/PROBE_DETERMINISTIC_BUDGET_2026-08-08.md`
7. `docs/HANDOFF_2026-08-07_B_DISPATCH_0x42EB48.md`
8. `docs/HANDOFF_2026-08-07_C_PROVIDER.md`

Fatos atuais:

- Nunca houve frame real: `gif=0`, `gsw=0`.
- O classificador antigo mentia; o atual exige GIF/GSW.
- Threads guest usam `std::thread` do host e o probe antigo corta por wall-clock.
- O gate A2 por `MC3_DISPATCH_BUDGET` foi parcialmente implementado nos scripts,
  mas ainda nao foi aceito nem rodado N=10.
- O teste sintetico atual falha em
  `tools/tests/Test-ProbeMeasurement.ps1:199`: `Compare-Object` recebe
  `ReferenceObject` nulo quando nao existe `mc3_partial.exe` rodando.
- `first-bad-pc=0x42EB48` e recorrente. E uma divida real, mas ainda nao esta provado
  que seja a causa direta de GIF/GS zerados.
- Git nao e confiavel neste checkout: `.git` existe, mas `git status` diz que nao e
  repositorio.

## Missao 1 - auditoria curta do A2 parcial

Somente leitura:

1. Inspecione:
   - `14_run_boot_trace.bat`
   - `tools/Boot-Probe.ps1`
   - `tools/Probe-Repeat.ps1`
   - `tools/tests/Test-ProbeMeasurement.ps1`
2. Confirme se o default sem `MC3_DETERMINISTIC=1` continua igual.
3. Confirme se budget ausente, zero ou invalido e rejeitado antes de abrir processo.
4. Confirme se uma corrida deterministica so e aceita com
   `dispatch-budget-reached` e sem `timeout reached`.
5. Explique a correcao minima para o bug de lista vazia do teste. Nao aplique.
6. Procure outros falsos positivos ou efeitos colaterais. Cada achado precisa de
   `arquivo:linha`, causa e teste que o prova.

## Missao 2 - garimpo do primeiro GIF/GS

Somente leitura e sem busca ampla cega em todo `work/generated/ghidra`:

1. Localize onde os contadores `gifCopyCount` e `gsWriteCount` sao incrementados.
2. Mapeie as APIs/runtime stubs que levam a esses incrementos.
3. A partir dessas entradas, trace para tras os callers guest conhecidos e os
   arquivos gerados correspondentes. Restrinja buscas a enderecos/funcoes descobertos.
4. Compare com:
   - os cinco raws do baseline de 07/08;
   - `work/logs/14_run_boot_trace.log` atual;
   - documentos PCSX2 live/provider existentes em `docs/`;
   - o gap `0x42EB48`.
5. Responda objetivamente:
   - `0x42EB48` esta no caminho necessario para o primeiro GIF/GS, ou apenas aparece
     antes por coincidencia/dispatch incompleto?
   - Qual e o ultimo produtor grafico comprovadamente alcancado pelo runner?
   - Qual e o primeiro produtor grafico esperado que nunca aparece?
   - O bloqueio imediato e dispatch, provider/assets, inicializacao GS, SIF/IOP ou
     ainda indeterminado?
6. Escolha exatamente um proximo experimento pequeno, reversivel e falsificavel.

## Proibicoes

- Nao editar nenhum arquivo do projeto.
- Nao criar patch, objeto, executavel ou commit.
- Nao rodar `15_auto_boot_probe`, `21_probe_repeat`, runner ou PCSX2.
- Nao forcar `SignalSema`, retorno, handle, provider pointer ou callback.
- Nao chamar DMA/VIF de render.
- Nao apresentar correlacao como causa.
- Nao recomendar reescrita ampla ou varios experimentos em paralelo.

## Formato obrigatorio da resposta

Entregue no chat; nao escreva arquivo.

```text
GEMINI MC3 HANDOFF RESULT

A2 VERDICT: sound | fix-first | rethink
A2 FINDINGS:
- FACT | arquivo:linha | evidencia | impacto
A2 MINIMAL TEST FIX:
- arquivo:linha | mudanca sugerida | teste esperado

GRAPHICS PATH:
1. FACT | origem -> destino | arquivo:linha | evidencia
2. FACT | origem -> destino | arquivo:linha | evidencia

0x42EB48 VERDICT: required-path | separate-debt | unknown
REASON: evidencia direta

LAST PROVEN GRAPHICS PRODUCER: <funcao/endereco ou none>
FIRST EXPECTED MISSING PRODUCER: <funcao/endereco ou unknown>
IMMEDIATE BLOCKER: dispatch | provider-assets | gs-init | sif-iop | unknown

ONE NEXT EXPERIMENT:
- objective:
- allowedPaths:
- exact change boundary:
- gate-off behavior:
- verification commands:
- positive acceptance:
- negative/rejection result:
- rollback:

UNCERTAINTIES:
- HYPOTHESIS | o que falta provar
```

Se nao houver evidencia suficiente, use `unknown`. Inventar uma resposta e pior que
deixar a lacuna explicita.
