# Resultado — passo 15 (Fase 2c): VBlank inline no scheduler, sem segunda thread

Executa `docs/HANDOFF_FASE2C_VBLANK_IN_TICK.md`. Data: 19/08/2026. Branch `mc3` (fork local, sem
push), submódulo `PS2Recomp` commit `289e4dd`. Docs no repo raiz.

## Resumo (2 linhas)

Redesenho aceito: VBlank não roda mais em thread de host separada em modo determinístico — o
próprio scheduler avança o tick inline, no turno de handoff do baton. Aceite obrigatório passou
limpo (**1 Stable PC único em 10/10**, `0x245720`, evidência determinística válida em todas), o
gate `0x245718` caiu, e o custo caiu também (mais rápido que o baseline, não mais lento).

## Passo 0 — baseline (válido, mas exigiu ajuste de janela)

Rebuild (`ps2_runtime`) + relink (`10_link_partial_runner.bat fast`) a partir do fonte revertido
(`8c5ddb6`, working tree limpo confirmado). Exe relinkado mais novo que a lib em todo ponto desta
sessão (checado a cada rebuild).

**`21_probe_repeat.bat 5 probe fase2c_baseline` (janela padrão 8s) saiu sujo**: 5/5
`timeout=yes marker=no`, PCs dispersos (`0x238924`, `0x1dd870`, `0x432aa0`, `0x432848`,
`0x54bcb0`) — nenhum na família esperada. Diagnóstico antes de descartar a medição (regra
"reconferir binário/env antes de desconfiar do código"):

1. Achado um processo `find` órfão desta própria sessão consumindo ~450s de CPU acumulada
   (resquício de uma busca de ferramenta em background que não foi encerrada) — morto
   (`taskkill /F`). CPU média do host após isso: **4%** (`Win32_Processor.LoadPercentage`), ou
   seja, não era mais contenção real de CPU no instante da medição.
2. Repetido com 5s ainda sujo (2/5 já batendo `0x245718`, mas todas marker=no/timeout=yes) e com
   30s (4/5 em `0x245718`, ainda marker=no/timeout=yes) — sinal de "lento", não "quebrado"
   (mesma distinção que `RESULT_FASE2B_DIVERGENCE_V1.md` recomenda fazer antes de suspeitar de
   bug: comparar janelas curtas vs longas).
3. Com **90s**, `21_probe_repeat.bat 5 probe fase2c_baseline_90s` saiu **limpo**: 5/5
   `marker=yes timeout=no`, **1 Stable PC único (`0x245718`)** — exatamente a família histórica
   esperada pelo handoff.

**Conclusão do Passo 0**: baseline válido, mas a máquina precisou de 90s (não os 8s do modo
`probe` padrão) para produzir evidência determinística limpa nesta sessão — provavelmente carga
residual de outros processos do host (Spotify/Overwolf/Brave/Photoshop rodando em paralelo,
confirmados via `Get-Process`, fora do controle deste executor) mais o próprio custo do binário de
518MB. Não é o "binário stale" do passo 13 (exe confirmado mais novo que a lib, env confirmado
propagando corretamente — `deterministic=yes budget=25000` aparece em toda linha). Todas as
medições subsequentes desta sessão usam **90s** para manter comparação justa (mesma janela,
mesma máquina, mesma carga aproximada).

## Redesenho implementado

Arquivos tocados (dono do scheduler): `DeterministicScheduler.cpp` (reescrito),
`Interrupt.cpp`, `ps2_runtime.cpp`/`ps2_runtime.h` (fiação mínima de
`enterGuestExecution`/`releaseGuestExecution`/etc.), `ps2_syscalls.h` (assinaturas), `Sync.cpp`
(contrato de sema), + 3 arquivos de teste (contrato de sema).

### Mecânica

- **Sem segunda thread**: `ensureInterruptWorkerRunning` em modo determinístico não cria mais
  `std::thread` nenhuma — só chama `DetSchedRegisterVBlankTick(rdram, runtime,
  &runOneVBlankTick)`, que guarda o ponteiro de função + contexto sob o mutex do scheduler.
- **Tick inline**: `pickNextLocked()` (chamado por todo `DetSchedEnter`/`DetSchedLeave`/etc.)
  decide se um tick está "devido" — fila de prontos vazia (idle) **ou** `N=50` handoffs reais
  desde o último tick — e, se o call site permite (`allowInlineVBlankTick=true`), executa o
  corpo do tick (`runOneVBlankTick`: latch INTC_STAT, toggle CSR.FIELD, despacha
  `sceGsSyncVCallback` + handlers INTC de vblank-start/end, acorda waiters de vsync) **na própria
  thread chamadora**, com `det_sched::g_mutex` liberado durante a execução (nunca held através de
  código guest) e um sentinel (`g_currentTid = kInlineVBlankCurrentTidSentinel`) garantindo
  exclusividade — nenhuma outra thread real pode ganhar o token enquanto o tick roda.
- **N=50**: contagem de handoffs fixa, sem relógio. Derivada do baseline do Passo 0 (90s limpo):
  `dispatch-budget=25000` batido com `vblank-tick` no contador ~512 no mesmo ponto → 25000/512 ≈
  48.8 → arredondado para 50 (documentado em comentário no código-fonte,
  `DeterministicScheduler.cpp`).
- **`allowInlineVBlankTick`**: novo parâmetro (default `false`) em `DetSchedEnter`/`DetSchedLeave`
  e, transitivamente, em `GuestExecutionReleaseScope`/`releaseGuestExecution`/
  `reacquireGuestExecution`. Só `true` em dois lugares: (a) `enterGuestExecution`/
  `leaveGuestExecution` (usados por `GuestExecutionScope`, sempre no topo do dispatch loop —
  auditado como livre de qualquer lock externo — `Thread.cpp:495`, `ps2_runtime.cpp:1902`,
  `Runtime.h:375`, `IPU.cpp:40`); (b) `WaitForNextVSyncTick` (`Interrupt.cpp`), reestruturado para
  **não** segurar `g_vsync_flag_mutex` continuamente através do release/reacquire — do contrário
  o tick inline (que toma esse mesmo mutex em `signalVSyncFlag`) se autotrancaria. Todo outro
  call site de `GuestExecutionReleaseScope` (WaitSema, WaitEventFlag, SleepThread, SuspendThread,
  espera de TerminateThread) mantém o default `false` — risco residual documentado abaixo.

### Bug achado e corrigido no bring-up (livelock)

Primeira versão de `pickNextLocked` rodava o tick e fazia `continue` num loop `for(;;)`,
tentando repetidamente até a fila de prontos deixar de estar vazia. Com **1 thread só**
registrada (o caso do arranque, antes de qualquer `StartThread`), isso é um livelock: a única
thread capaz de repor a fila de prontos é a própria thread presa dentro dessa chamada — ela nunca
consegue chamar `Enter()` de novo porque `pickNextLocked` nunca retorna. Sintoma observado: boot
travado no PC de entrada (`0x1a0008`), `activeThreads=1` a sessão inteira, watchdog
`idle-vblank-advances-without-progress` disparando após 20000 ticks inline em ~30s sem nenhum
progresso real. Corrigido: no máximo **1 tick por chamada** quando idle, devolvendo controle ao
chamador (que, no próximo `Enter()` do seu próprio loop de dispatch, refaz a arbitragem) — mesma
cadência de ping-pong do design de 2 threads antigo, sem a segunda thread. Reproduzido e corrigido
tanto com o scheduler isolado (contrato de sema antigo) quanto com o pacote completo.

## Aceite

`21_probe_repeat.bat 10 probe fase2c_v1`, executado como
`Probe-Repeat.ps1 -Runs 10 -Mode probe -Seconds 90` (ver nota do Passo 0 sobre a janela):

**1 Stable PC único em 10/10** (`0x245720`), todas com evidência determinística válida
(`marker=yes`, `timeout=no`). Zero falhas de evidência, zero classificações inconsistentes.
Relatório: `work/boot_probe/repeat_fase2c_v1_20260819_023553.md`.

### Custo (tempo-até-marcador vs baseline)

Medido diretamente (`Start-Process`+`Stopwatch`, mesmo binário/env, fora da cadeia de scripts
para eliminar overhead de driver):

| | PC final | Tempo até `dispatch-budget-reached` |
|---|---|---|
| Baseline (pré-Fase2c, `8c5ddb6`) | `0x245718` | **26.7s** |
| Fase 2c (`289e4dd`) | `0x245720` (mais profundo) | **3.9s** |

Fase 2c ficou **mais rápida**, não mais lenta — bem dentro do limite de 2x do handoff. A remoção
da segunda thread (e da disputa de mutex do SO entre ela e a thread guest) parece ter reduzido
overhead, não aumentado.

## Suíte

`ps2x_tests.exe`, `PS2Recomp\out\build`, env ausente (modo padrão, nenhum teste seta
`MC3_DETERMINISTIC`): 5 rodadas nesta sessão (contando as do bring-up) — **4× 271/271, 1×
270/271**. A rodada com falha foi um teste diferente do flake historicamente citado
(`sceGsSyncV waits on VBlank and reports interlaced field parity`, não
`VU0 macro mappings...`), mas da mesma categoria: timing real de `steady_clock`/worker de VBlank
em modo **não-determinístico** (nenhum teste liga `MC3_DETERMINISTIC`), já documentado em
`RESULT_FASE2_SCHED_V1.md`/`RESULT_GSYNCV_METRICS_V1.md`/`RESULT_FASE2B_DIVERGENCE_V1.md` como
flake pré-existente não relacionado ao scheduler determinístico. Análise de por que variam os
nomes: qualquer teste que dependa do worker de VBlank de parede (`interruptWorkerMain`,
inalterado nesta sessão) pode flakar sob carga do host; qual teste especificamente perde a corrida
depende da ordem/timing daquela rodada. Consistente com o piso `≥266/269` da regra.

Nenhum teste do suite exercita o caminho determinístico (`MC3_DETERMINISTIC=1`) diretamente — item
4 do handoff ("ajustes em testes de VBlank do modo determinístico comentados um a um") não se
aplicou: não existem testes desse tipo na suíte hoje.

## Trajetória do gate

`0x245718` **caiu** (era o Stable PC único do baseline). Novo Stable PC único: `0x245720`, poucos
bytes adiante, ainda na mesma família de `sub_00245680` (`psxCdCache`/`RawRead`) documentada em
`RESULT_FASE2B_DIVERGENCE_V1.md`. Não houve avanço de marco além disso nesta sessão — o próximo
gate real está mais adiante no boot, fora do escopo deste handoff (dono do scheduler, não do
protocolo CD/SIF).

## Régua de render (M0-M6)

Inalterada em todas as 10 corridas do aceite: `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`,
`gif=0`, `gsw=0`. **M4 não foi atingido** (exige `gifPackets(total)>0` E `gsPrims>0`) — nenhuma
confirmação 3x necessária, nada a reportar como vitória de render nesta sessão.

## Commits

Submódulo `PS2Recomp`, branch `mc3`, **sem push**:
- `289e4dd` — "sched: VBlank inline no scheduler (sem 2a thread) + contrato de sema reaplicado"
  (9 arquivos: `DeterministicScheduler.cpp`, `Interrupt.cpp`, `Sync.cpp`, `ps2_runtime.cpp`,
  `ps2_runtime.h`, `ps2_syscalls.h`, + 3 arquivos de teste do contrato de sema).

Repo raiz (`mc3recomp`, branch `mc3`), **sem push**: este documento + ponteiro do submódulo +
`docs/BOOT_PROBE_STATUS.md` (artefato automático da última corrida de probe), commitados juntos
pelo executor.

## Aceite do handoff

**Alcançado.** `21_probe_repeat.bat 10 probe fase2c_v1`: 1 Stable PC único, 10/10 com evidência
válida, custo menor que o baseline (não maior). Gate `0x245718` caiu. M4 não atingido (nada a
confirmar). Redesenho implementado sem env-gate novo, sem `SignalSema` injetado, sem tempo de
host no caminho determinístico (contagem de handoffs substitui o relógio em toda a lógica de
tick).

## Riscos residuais e recomendação para o próximo passo

1. **Tick inline só roda de call sites verificados livres de lock** (topo do dispatch loop +
   `WaitForNextVSyncTick`). Todo outro syscall bloqueante (`WaitSema`, `WaitEventFlag`,
   `SleepThread`, `SuspendThread`, espera de `TerminateThread`) mantém `allowInlineVBlankTick=
   false` por padrão — se a única thread viva algum dia ficar parada exatamente num desses (sem
   nenhuma thread num call site seguro para bombear o tick), o VBlank para de avançar. Não
   observado nesta sessão (watchdog diagnóstico `vblank-tick-due-but-no-lock-free-call-site-
   reached`, threshold 2000, nunca disparou nas medições), mas é um risco estrutural documentado,
   não eliminado — não fazia parte do escopo deste handoff resolver para toda a família de waits,
   só para VBlank/vsync especificamente.
2. **Próximo gate real** (além de `0x245720`) não foi investigado — é trabalho do dono do
   protocolo CD/SIF, não do scheduler.
3. O `N=50` é uma constante derivada empiricamente de uma única medição de baseline; se a cadência
   real de handoffs mudar substancialmente em profundidades futuras do boot, pode valer a pena
   recalibrar (documentado no comentário do código-fonte para facilitar isso).
