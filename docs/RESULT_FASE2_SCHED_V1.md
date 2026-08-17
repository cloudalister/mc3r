# Resultado — Fase 2: scheduler cooperativo determinístico (sched_v1)

Data: 2026-08-17. Executa `docs/HANDOFF_FASE2_SCHEDULER.md` do início ao fim (Bloco A + Bloco B).
Branch: `mc3` (fork local, sem push), tanto no repo raiz quanto no submódulo `PS2Recomp`.

## Resumo executivo

**Aceite da Fase 2 atingido**: `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`, modo de probe
`595`, 10/10 corridas produziram o **mesmo** Stable PC (`0x5a8908`), mesma classificação
(`counters-moved`), todas com evidência determinística válida (`Dispatch budget marker=yes`,
`Timeout reached=no`). Nenhum watchdog de deadlock disparou. Modo padrão (env ausente): suíte
`ps2x_tests` 268/269 (mesma falha pré-existente de sempre, não relacionada), e a mesma métrica de
`mc3-iop-response-unhandled` do Bloco A foi validada num trace real desta sessão.

Uma observação honesta que não deve ser escondida: a corrida de regressão (`sched_off_regression`,
env ausente) também produziu 1 único Stable PC nas 10 corridas, diferente da distribuição de 9 PCs
distintos documentada em `docs/RESULT_USBKB_V1.md` para `usbkb_v1`. Análise na seção 5.

## Bloco A — higiene do log `mc3-iop-response-unhandled`

Commit no submódulo `PS2Recomp` (branch `mc3`): `f2fc530` — *"sif: suppress legacy
unhandled-response log for events served by new dispatchers"*.

- Arquivo: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` — 1 arquivo, 17 inserções, 5
  remoções.
- Mudança: `completeMc3IopResponseForExperiment()` ganhou um parâmetro
  `handledByNewDispatcher`; o call site (dispatch de `sceSifSetDma` cmd `0x8000000A`) agora captura
  `newDispatcherHandled = handleCdvdRpc(...) || handleUsbKbRpc(...)` e o repassa. O log
  `mc3-iop-response-unhandled` só dispara quando `!wrote && !handledByNewDispatcher`.
- Commit espelho no repo raiz (bump do ponteiro de submódulo): `639eaf9`.

**Validação empírica** (não só leitura de código): trace de `sched_off_regression` desta sessão
(`work\logs\14_run_boot_trace.log`) mostra, na mesma janela, `mc3-cdvd-rpc kind=init fno=0x0` e
`mc3-usbkb-rpc kind=get-info fno=0x1` **sem** nenhuma linha `mc3-iop-response-unhandled` para esses
mesmos eventos — as linhas `unhandled` restantes são todas `request=` diferentes (`0xff`, `0x22`,
`0x0`@payload distinto, `0x9`, `0x1`), ou seja, eventos genuinamente sem handler (novo ou velho).
Aceite do Bloco A confirmado.

## Bloco B — scheduler cooperativo determinístico

### Design escolhido (resumo; documento completo em `docs/FASE2_SCHEDULER_DESIGN.md`)

Não fibers, não corrotinas: as threads guest continuam `std::thread` reais (zero mudança em
pilha/TLS/exceções). O que muda é **quem tem permissão de executar código recompilado agora** —
hoje um `std::mutex` do SO (`m_guestExecutionMutex`), cuja ordem de concessão sob contenção é
decidida pelo escalonador do Windows (causa raiz documentada em
`docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md`). Em `MC3_DETERMINISTIC=1`, essa decisão passa a ser um
**baton explícito** (`DeterministicScheduler`, arquivo novo
`Kernel/Syscalls/Helpers/DeterministicScheduler.cpp`), arbitrado só por
`(prioridade EE asc, ordem de criação da thread)` — nunca por relógio ou por como o SO acordou uma
`condition_variable`.

Pontos de troca de contexto (§3 do design): back-edges de loop (via `shouldPreemptGuestExecution`,
já existente no codegen), `WaitSema`/`SleepThread`/`SuspendThread`/`WaitEventFlag`/
`TerminateThread`-wait/`WaitForNextVSyncTick` (todos já passavam por
`GuestExecutionReleaseScope`, que agora delega ao baton), `SignalSema`/`WakeupThread`/
`SetEventFlag`/`ResumeThread`/`ReleaseWaitThread` (marcam a thread-alvo pronta só quando o
predicado real foi de fato satisfeito, não apenas quando um contador mudou — ver seção "riscos
tratados" abaixo), e `RotateThreadReadyQueue` (agora libera e readquire o token
deterministicamente em vez de `std::this_thread::yield()`).

VBlank em modo determinístico não usa mais relógio de parede: um pseudo-participante de prioridade
mínima (`kDetVBlankPseudoTid`) só é escolhido pelo scheduler quando a fila de prontos esvazia —
ou seja, quando toda thread guest está genuinamente bloqueada — avançando o tick por esse evento,
não por `steady_clock`.

### Riscos tratados durante a implementação

O design previu (seção 4) que marcar uma thread "pronta" sem que o predicado real esteja
satisfeito poderia conceder o token a uma thread que na verdade ainda está bloqueada em outro
recurso, travando todo o resto. Isso apareceu de fato ao implementar `WakeupThread`/
`ResumeThread`: a primeira versão marcava a thread-alvo pronta sempre que o syscall era chamado,
mas `WakeupThread` só libera de verdade quando a thread estava em `THS_WAIT`/`TSW_SLEEP` (senão só
incrementa um contador para um `SleepThread` futuro) e `ResumeThread` só libera de verdade quando
`suspendCount` chega a 0 **e** `waitType==TSW_NONE` (senão a thread continua bloqueada em outro
`WaitSema`/`WaitEventFlag`, que é quem vai marcá-la pronta de verdade). Corrigido antes de
qualquer teste de probe — ver `actuallyWoke`/`actuallyResumed` em `Thread.cpp`. `ReleaseWaitThread`
não precisou desse cuidado: `forceRelease` garante que a thread sai do `cv.wait` do recurso
independentemente do predicado, então marcar pronta sempre é correto ali.

Risco documentado e não eliminado: `SetEventFlag` marca prontas **todas** as threads esperando no
`eid`, não só as cujo `AND`/`OR` específico já foi satisfeito (o `ThreadInfo` não guarda o modo/
máscara por esperador). Isso não pode corromper estado (a thread só sai do `cv.wait` real quando o
predicado dela mesma for verdadeiro), mas em tese pode atrasar outras threads atrás dela na fila
até esse predicado resolver. Não observado nas 10 corridas desta sessão (nenhum watchdog disparou).

### Validação

Build: `ninja ps2_runtime` e `ninja ps2x_tests` (cmake portátil + ninja do VS2022 + g++ do
`msys64/ucrt64`, conforme ambiente do handoff).

| Etapa | Resultado |
|---|---|
| Suite `ps2x_tests` (env ausente) | **268/269** — falha única pré-existente `VU0 macro mappings cover all S1/S2 enums`, não tocada por este trabalho (a segunda falha histórica, `sceGsSyncV waits on VBlank...`, é flaky por natureza e passou nesta corrida) |
| Relink | `10_link_partial_runner.bat fast` — `work\link\partial\mc3_partial.exe`, timestamp **2026-08-17 20:51:11** |
| `sched_v1` (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`, modo `595`, 10 corridas) | **1 Stable PC distinto** (`0x5a8908`), classificação `counters-moved` em 10/10, `Dispatch budget marker=yes` e `Timeout reached=no` em 10/10 — **aceite atingido**. Relatório: `work\boot_probe\repeat_sched_v1_20260817_205419.md` |
| `sched_off_regression` (env ausente, modo `595`, 10 corridas) | **1 Stable PC distinto** (`0x5a8908`), `Deterministic=no`, `Timeout reached=yes` em 10/10 (comportamento do modo padrão: mata o processo aos 8s, como sempre) — ver ressalva na seção 5. Relatório: `work\boot_probe\repeat_sched_off_regression_20260817_205504.md` |

Nenhuma linha `mc3-det-sched-stall` (watchdog de deadlock) apareceu em nenhum log desta sessão.

## Distribuição de PCs — sched_v1 vs sched_off_regression vs usbkb_v1

| Conjunto | Modo | Corridas | Stable PCs distintos | PCs observados | Evidência válida |
|---|---|---:|---:|---|---|
| `usbkb_v1` (`docs/RESULT_USBKB_V1.md`, 17/08, sessão anterior) | padrão (env ausente) | 10 | **9** | `0x54a0ac, 0x5494e0, 0x540354, 0x3985d8, 0x223480, 0x5403a4, 0x398390, 0x54bbc4, 0x234614` | falhas de evidência determinística: 0/10 (não aplicável — não era modo determinístico) |
| `sched_off_regression` (esta sessão) | padrão (env ausente) | 10 | **1** | `0x5a8908` | 10/10 com `timeout reached=yes` (comportamento padrão de corte por relógio) |
| `sched_v1` (esta sessão) | determinístico | 10 | **1** | `0x5a8908` | 10/10 com `marker=yes`, `timeout=no` |

## 5. Ressalva honesta sobre a comparação de regressão

O pedido do handoff era comparar `sched_off_regression` com `usbkb_v1` esperando "distribuição
semelhante = modo padrão intacto". O resultado observado não é uma distribuição semelhante em
número de PCs (1 aqui vs 9 em `usbkb_v1`) — mas também **não é evidência de regressão funcional**,
pelos seguintes motivos, registrados sem maquiagem:

1. **Revisão de código**: toda linha nova desta fase está atrás de
   `isMc3DeterministicModeEnabled()` (cacheado de `MC3_DETERMINISTIC`). Com a variável ausente,
   cada função tocada (`enterGuestExecution`, `leaveGuestExecution`, `releaseGuestExecution`,
   `reacquireGuestExecution`, `shouldPreemptGuestExecution`, `ensureInterruptWorkerRunning`,
   `StartThread`, `WakeupThread`, `ResumeThread`, `ReleaseWaitThread`,
   `RotateThreadReadyQueue`, `SignalSema`, `SignalSemaByIdForRuntimeCompat`, `SetEventFlag`) cai
   exatamente no branch que existia antes desta fase, byte a byte. Não há caminho de código novo
   alcançável com o env ausente.
2. **A diferença observada é explicável sem invocar o código novo**: `0x5a8908` já aparecia como
   PC de baseline em `docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md` (run 5 do baseline original,
   `dispatch-window total=9500000 ... pc=0x5a8908`) e tem anatomia própria documentada
   (`docs/LOOP_0x5A8908_ANATOMY.md`) — é um loop conhecido, não um endereço novo introduzido por
   este trabalho. As 10 corridas de `sched_off_regression` rodaram os 8s completos até o corte por
   relógio (`timeout reached=yes` em todas, igual ao comportamento padrão de sempre); é plausível
   que, dado tempo suficiente, a execução convirja para esse loop estável independentemente da
   ordem inicial de intercalação de threads — o que a métrica de `Stable PC` (amostra tardia, não
   "onde o jogo parou") mediria como "1 PC" mesmo com nondeterminismo real acontecendo mais cedo na
   execução.
3. **O que de fato precisa ficar igual — ficou**: suíte 268/269, e o comportamento de
   `mc3-iop-response-unhandled` do Bloco A, ambos verificados nesta mesma sessão em modo padrão.

Não estou tratando "1 PC" no lado padrão como prova de que o modo padrão também ficou
determinístico por acidente — não teria como, já que nenhum código novo roda nesse caminho. Registro
isto como uma limitação da comparação (o parâmetro de probe usado, modo `595`/8s, não reproduziu a
distribuição de 9 PCs de `usbkb_v1` neste ambiente/sessão) e não como conclusão sobre o modo
padrão. Se o time quiser uma comparação mais direta, o próximo passo é rodar
`sched_off_regression` com os mesmos parâmetros exatos (mesma seed de probe, mesma máquina, mesmo
momento) que geraram `usbkb_v1`, ou reduzir a janela de tempo para capturar PCs mais cedo, antes da
convergência para o loop `0x5a8908`.

## Regras seguidas

- Nenhum `SignalSema` foi injetado; nenhum handler SIF do Bloco A/Fase 1 foi tocado nesta fase.
- Commits locais na branch `mc3` do fork, em ambos os repositórios (raiz e submódulo
  `PS2Recomp`), sem push.
- Nenhum deadlock ocorreu; o watchdog por contagem de dispatch (não por tempo) está implementado
  e não disparou em nenhuma das 20 corridas desta sessão (10 `sched_v1` + 10
  `sched_off_regression`), nem na corrida avulsa de sanidade anterior.

## Commits

| Bloco | Repositório | Commit | Resumo |
|---|---|---|---|
| A | `PS2Recomp` (submódulo) | `f2fc530` | log legado não duplica `unhandled` para eventos já atendidos pelos novos dispatchers |
| A | raiz | `639eaf9` | bump do ponteiro de submódulo + nota do handoff |
| B | `PS2Recomp` (submódulo) | `b9b40d2` | scheduler cooperativo determinístico completo (6 arquivos, 582 inserções, 9 remoções) |
| B | raiz | (este commit) | docs de design/resultado + bump do ponteiro de submódulo |

## Documentos

- Design obrigatório (produzido antes do código): `docs/FASE2_SCHEDULER_DESIGN.md`
- Este resultado: `docs/RESULT_FASE2_SCHED_V1.md`
- Handoff original: `docs/HANDOFF_FASE2_SCHEDULER.md`
- Relatórios de probe: `work\boot_probe\repeat_sched_v1_20260817_205419.md`,
  `work\boot_probe\repeat_sched_off_regression_20260817_205504.md`
