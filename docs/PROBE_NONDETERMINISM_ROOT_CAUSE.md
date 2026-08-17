# VIS-A1 — causa dominante da nao determinacao do probe

Data: 2026-08-08. Escopo: leitura de codigo e dos artefatos existentes; nenhum runner foi iniciado.

## Veredito

**Dominante — fato:** a combinacao de execucao concorrente em threads reais do host e corte externo por segundos de relogio torna a amostra final dependente do escalonador. O runner cria uma `std::thread` para o jogo e uma `std::thread` independente para cada `StartThread` guest; o driver mata todo o processo quando os 8 segundos acabam. Portanto, cada corrida pode ter executado uma quantidade e uma intercalacao diferentes antes de a amostra ser lida.

O baseline de cinco corridas confirma a consequencia: mesmo binario/modo/duracao produziu cinco PCs distintos (`0x54c29c`, `0x2469b0`, `0x545660`, `0x3`, `0x5a8908`) e `gif=0 gsw=0` em 5/5. Fonte: `work/boot_probe/repeat_baseline_20260807_20260807_013345.md`.

## Ranking de causas

| Ordem | Causa | Status | Evidencia direta | Limite honesto |
|---:|---|---|---|---|
| 1 | Threads do host | **Fato causal dominante** | `Thread.cpp:348-351` incrementa o contador e cria `std::thread`; `:357` cria contexto proprio zerado; `:410-451` despacha em loop e chama `yield`. `ps2_runtime.cpp:2167-2175` tambem cria `GameThread`; `:2202-2208` amostra enquanto ha threads ativas. | Os logs sao concorrentes/intercalados e mostram `activeThreads=3` nas runs 2/3. Nao medimos uma contribuicao percentual isolada. |
| 2 | Corte por wall-clock | **Fato causal dominante** | `14_run_boot_trace.bat:38-40` usa `WaitForExit(seconds*1000)` e, se vencer, `Stop-Process -Force`. O contador de dispatch ja existe em `ps2_runtime.cpp:64-78,1767-1798`, mas o baseline nao o ativa. | Isto prova que a duracao e tempo real; nao prova que so o corte, sem as threads, explica todos os PCs. |
| 3 | Estado nao inicializado | **Hipotese nao suportada como causa do baseline** | RDRAM, scratchpad, IOP RAM, GS VRAM e VU sao zerados em `ps2_memory.cpp:181-215`; contexto principal e zerado em `ps2_runtime.cpp:593-595`; contexto de cada worker usa `{}` em `Thread.cpp:357`. | Isso descarta estas inicializacoes como explicacao direta conhecida. Nao e uma prova global sobre todo estado de bibliotecas/host; `0x3` sozinho nao prova lixo. |
| 4 | Semente/RTC de tempo real | **Fato de presenca; hipotese de impacto** | `CD.cpp:318-334` grava o relogio do host em `sceCdReadClock`; `Helpers/Runtime.h:563-577` consulta `std::time`. | Nenhum dos cinco logs liga uma chamada RTC a uma bifurcacao ou a `0x3`; nao promover a causa. |

## O que o `Stable PC` mede

`Boot-Probe.ps1:420-457` escolhe a **ultima** linha encontrada, nesta ordem: `frame`, `dispatch-window`, `loop-exit`, `game-thread-return`; extrai o campo `pc` dessa linha. Logo, ele e uma fotografia tardia de telemetria, nao "o PC onde o jogo parou" nem uma prova de render.

Na run 4, o proprio raw log registra uma linha de frame intercalada contendo `pc=0x3` e `vif=2` (`boot_trace_pollsid59c595_20260807_013421.log`). A causa de o PC valer `0x3` **nao foi provada**. O classificador atual ja rejeita esse tipo de valor: `Boot-Probe.ps1:493-519` exige mapeamento pelo registry/nome de funcao antes de aceitar qualquer sinal; `:522-539` exige `gif>0` ou `gsw>0` para `render-started` e chama DMA/VIF sem GIF/GS de `counters-moved`.

O relatorio antigo ainda chama a run 4 de `render-started`, mas seu proprio contador e `gif=0 gsw=0`; o agregador atual tambem marca essa divergencia como falha de medicao (`Probe-Repeat.ps1:25-45,121-147`). Portanto, `0x3` e uma amostra invalida, nao uma causa atribuivel nem frame.

## Evidencia dos cinco logs (sem nova execucao)

| Run | Arquivo raw | Amostra/resultado relevante |
|---:|---|---|
| 1 | `boot_trace_pollsid59c595_20260807_013354.log` | baseline agrega `unknown-loop`, `0x54c29c`, sem GIF/GS. |
| 2 | `..._013403.log` | frame `tick=360 activeThreads=3 pc=0x2469b0`; `first-bad-pc=0x42eb48`. |
| 3 | `..._013411.log` | frame intercalado com `activeThreads=3`; baseline agrega `0x545660`; mesmo `first-bad-pc`. |
| 4 | `..._013421.log` | frame intercalado contem `pc=0x3`, `gif=0 gsw=0 vif=2`; mesmo `first-bad-pc`. |
| 5 | `..._013430.log` | `dispatch-window total=9500000 ... pc=0x5a8908`; mesmo `first-bad-pc`. |

O `first-bad-pc=0x42eb48` recorrente e uma divida separada de dispatch, nao explicacao demonstrada para a variacao: ele ocorre com multiplos PCs finais.

## Uma unica implementacao A2 proposta

**Nome:** corte deterministico por budget, sem alterar o scheduler nesta etapa.

**Arquivos sob posse A2:** `14_run_boot_trace.bat`, `tools/Boot-Probe.ps1`, `tools/Probe-Repeat.ps1`. Nao editar codigo gerado, provider, FMV ou binarios. O runtime ja oferece `MC3_DISPATCH_BUDGET` (`ps2_runtime.cpp:57-78,1767-1798`), entao A2 apenas o torna uma opcao explicita e rastreavel do probe.

**Comportamento:** adicionar `MC3_DETERMINISTIC=1` como portao opt-in. Ausente/`0` preserva exatamente o probe atual de 8 segundos. Com `1`, o wrapper exige um `MC3_DISPATCH_BUDGET` positivo, exporta ambos para o processo e escreve o budget no status/repeat report. O valor inicial deve ser escolhido abaixo do menor tempo que atinge o kill de 8 s; a corrida deve terminar pelo marcador `[boot-trace:dispatch-budget-reached]`, nunca por `timeout reached`. O budget interrompe o loop por numero de dispatches, em vez de segundos reais.

**Por que e um gate, nao uma promessa:** budget remove o corte externo como variavel, mas as threads reais continuam concorrentes. Portanto este e o menor teste reversivel: se N=10 ainda divergir, A2 falha honestamente e o proximo trabalho e um scheduler cooperativo; nao se mascara o problema aumentando segundos.

**Rollback:** remover `MC3_DETERMINISTIC=1` do ambiente; o default continua sem budget. Reverter somente os tres arquivos A2 se o wrapper precisar sair.

**Aceite N=10 (classificador honesto):**

```bat
set MC3_DETERMINISTIC=1
set MC3_DISPATCH_BUDGET=<budget-validado>
21_probe_repeat.bat 10 595 a2_budget
```

PASS somente se: (1) cada raw log tem `dispatch-budget-reached` e nenhum `timeout reached`; (2) o agregador corrigido reporta 1 `Stable PC` distinto; (3) zero `invalid-pc` e zero divergencia classificacao/GIF/GS; (4) `gif=0 gsw=0` continua registrado como **sem render**. Qualquer outra saida e FAIL/A3, nao progresso visual.

## Por que isto bloqueia GIF/GS

Sem medicao repetivel, uma mudanca de PC nao diferencia um patch util de ruído do host; por isso nao se pode atribuir uma futura primeira escrita GIF/GS a um experimento. Este gate faz a comparacao honesta antes de voltar ao provider/dispatch. **Nao existe frame visual ainda:** os cinco baselines tem `gif=0 gsw=0`, e estes sao os unicos sinais de render aceitos.

## Verificacao executada

- Leitura de `PS2_PROJECT_STATE.md`, auditoria e handoff de 2026-08-07: PASS.
- Leitura de `repeat_baseline_20260807_20260807_013345.md` e dos cinco raws listados: PASS; nenhum runner iniciado.
- Inspecao de threads, loop principal, cutoff, RDRAM/contexto e RTC: PASS (referencias acima).
- `git status --short`: indisponivel; este checkout nao e um repositorio Git reconhecido (`fatal: not a git repository`). Verificacao de escopo foi feita por lista explicita de alteracoes desta execucao.
