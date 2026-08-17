# Fase 2 — Design do scheduler cooperativo determinístico (MC3_DETERMINISTIC=1)

Data: 2026-08-17. Etapa 1 do `docs/HANDOFF_FASE2_SCHEDULER.md`, produzido antes de qualquer
código conforme exigido. Leitura completa de `Thread.cpp`, `Sync.cpp`, `Helpers/State.h`,
`ps2_runtime.cpp` (+ `Interrupt.cpp`, `GS.cpp` para VBlank, e `code_generator.cpp` para o ponto
de preempção nas back-edges do código gerado).

## 1. Inventário do que existe hoje (modo padrão)

### 1.1 Concorrência

- Cada thread guest iniciada por `StartThread` (`Thread.cpp:349-557`) vira uma **`std::thread`
  real do host**, registrada em `g_hostThreads` (`Helpers/State.h:207`). O corpo roda um loop
  `while (...) { step(rdram, ctx, runtime); }` que despacha uma função recompilada por vez
  (`Thread.cpp:410-488`).
- A thread principal do jogo é outra `std::thread` (`gameThread`, `ps2_runtime.cpp:2170-2197`),
  separada da thread de host que desenha a janela (`run()`, mesmo arquivo, loop em
  `2201-2271` — este último **não** participa da exclusão mútua de execução guest; ele só lê
  `m_memory`/`m_debugPc` e desenha, então não precisa mudar).
- **Já existe um "GIL"**: `PS2Runtime::m_guestExecutionMutex`, tomado por
  `GuestExecutionScope` em volta de cada `step()` (`ps2_runtime.cpp:1889-1892`, chamado tanto no
  `dispatchLoop` da thread principal quanto em `Thread.cpp:484-487` para threads guest). Só uma
  thread host executa código recompilado por vez — mas **quem pega o mutex a seguir é decidido
  pelo scheduler do SO** (`std::mutex::lock()` não é FIFO nem determinístico sob contenção). Essa
  é a causa raiz documentada em `docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md`.
- **Ponto de preempção cooperativa já existe no codegen**: toda back-edge (branch para trás, ou
  seja, fim de loop) emite `if (runtime->shouldPreemptGuestExecution()) { return; }` antes do
  `goto` (`code_generator.cpp:247-253`). `shouldPreemptGuestExecution()` (`ps2_runtime.cpp:1972-
  1984`) é um contador `thread_local` que devolve `true` a cada 64 (se há esperando) ou 100
  back-edges. Quando devolve `true`, a função recompilada faz `return`, o `step()` termina, o
  loop despachante (`Thread.cpp:410` ou `dispatchLoop`) libera o GIL implicitamente ao sair do
  escopo do `GuestExecutionScope` e volta a tentar pegar o mutex na próxima iteração — de novo,
  a ordem de quem ganha é do SO.
- **Pontos de bloqueio real** (todos soltam o GIL via `GuestExecutionReleaseScope` antes de
  bloquear num `condition_variable::wait`, e o readquirem ao acordar):
  - `WaitSema` (`Sync.cpp:391`) — bloqueia em `sema->cv` até `count>0`.
  - `SleepThread` (`Thread.cpp:843`) — bloqueia em `info->cv` até `wakeupCount>0`.
  - `SuspendThread` (auto-suspensão) (`Thread.cpp:697`) — bloqueia em `info->cv` até
    `suspendCount==0`.
  - `WaitEventFlag` (`Sync.cpp:741`) — bloqueia em `info->cv` até bits satisfeitos.
  - `TerminateThread` (esperando thread alvo terminar) (`Thread.cpp:659`) — bloqueia em
    `info->cv` do alvo.
  - `WaitForNextVSyncTick` / `sceGsSyncV` (`Interrupt.cpp:400`) — bloqueia em `g_vsync_cv` até o
    contador de tick avançar.
  - `PollSema`/`PollEventFlag`/`RotateThreadReadyQueue` **não bloqueiam**: `PollSema`/
    `PollEventFlag` retornam na hora; `RotateThreadReadyQueue` só chama
    `std::this_thread::yield()` (`Thread.cpp:1071`) — não solta o GIL formalmente porque não
    passa por `GuestExecutionReleaseScope`, mas em modo padrão isso ainda depende do
    escalonador do SO para decidir quem roda a seguir.
- **VBlank/timers**: um único worker de host (`interruptWorkerMain`, `Interrupt.cpp:304-346`) é
  criado sob demanda (`ensureInterruptWorkerRunning`) e dorme em intervalos de **relógio de
  parede** (`kVblankPeriod = 16667us`, `Interrupt.cpp:12,309-341`). A cada tick ele: incrementa
  `g_vsync_tick_counter`, escreve o flag/tick guest, despacha o callback de `sceGsSyncVCallback`
  e os handlers INTC de vblank-start/vblank-end. Esse worker roda **fora** do GIL guest (não usa
  `GuestExecutionScope`) e injeta trabalho assíncrono de verdade guiado pelo relógio do host —
  segunda fonte grande de não-determinismo, independente da primeira.
- Alarmes (`SetAlarm`, `Sync.cpp:928-974`) usam outro worker (`ensureAlarmWorkerRunning`, não
  lido em detalhe aqui pois nenhum handler SIF depende dele no caminho de boot atual) também
  guiado por `std::chrono::steady_clock`.

### 1.2 Onde `std::thread` nasce

1. `ps2_runtime.cpp:2170` — thread do jogo (`gameThread`).
2. `Thread.cpp:351` — cada `StartThread` guest.
3. `Interrupt.cpp:365` — worker de IRQ/VBlank (`std::thread(...).detach()`).
4. Worker de alarmes (`ensureAlarmWorkerRunning`, referenciado em `Sync.cpp:971` — não é o alvo
   desta fase; nenhum alarm participa da métrica de Stable PC até aqui, mas fica registrado como
   risco residual, ver §4).

## 2. Direção escolhida: baton determinístico sobre a infraestrutura existente, não fibers

A convocação original cita "fibers do Windows ou corrotinas" como opções. Depois de ler o
código, a escolha é **nenhuma das duas**: manter cada thread guest como uma `std::thread` real
(zero mudança na forma como pilha/stack/TLS/exceções já funcionam — `ThreadExitException`,
`runExitHandlersForThread`, `waitWhileSuspended` etc. continuam exatamente iguais), e substituir
apenas **a política de arbitragem do GIL** (`enterGuestExecution`/`leaveGuestExecution`/
`releaseGuestExecution`/`reacquireGuestExecution`) por um **baton determinístico**: em vez de
`std::mutex::lock()` (justo/aleatório por decisão do SO), o "token" de execução guest só é
concedido explicitamente pelo scheduler a UMA thread específica, escolhida por
`(prioridade desc, ordem de criação asc)` dentre as prontas.

Por que não fibers: converter todas as ~10 famílias de wait (sema, event flag, sleep, suspend,
terminate-wait, vsync, RPC completion via callback, DMAC handler dispatch, exit handlers, alarm)
para fibers explícitas exigiria reescrever cada uma dessas trocas de contexto E garantir que
nenhuma delas prende uma stack de host (mutexes de `std::lock_guard`, exceções C++ atravessando
`SwitchToFiber`, etc.) — risco de deadlock/corrupção muito mais alto para o mesmo resultado
observável (uma única ordem determinística de execução). O baton preserva 100% da lógica de
cada syscall (mesmos `condition_variable`, mesmos campos de `ThreadInfo`), e muda só "quem post
executa a seguir quando o token fica livre" — que é exatamente e apenas a causa raiz
identificada no §1.1.

### 2.1 Componente novo: `DeterministicScheduler`

Novo arquivo `ps2xRuntime/src/lib/Kernel/Syscalls/Helpers/DeterministicScheduler.h/.cpp`,
ativo somente quando `MC3_DETERMINISTIC=1` (checado uma vez, cacheado em `static const bool`,
mesma convenção de `isMc3BootTraceEnabled()`).

Estado:

```
struct DetThreadEntry {
    int tid;
    int priority;          // currentPriority no momento em que entrou na ready queue
    uint64_t createSeq;    // ordem de criação (contador global monotônico)
    std::condition_variable cv; // sinalizada só quando é a vez desta thread
    bool isCurrent = false;
    bool isReady = false;
};

std::mutex g_detMutex;
std::map<int, DetThreadEntry> g_detThreads;      // por tid
int g_detCurrentTid = 0;                          // 0 = nenhuma (idle)
std::set<std::pair<int,uint64_t>, DescByPriorityThenCreateOrder> g_detReadyOrder; // chave (−priority, createSeq) -> tid
uint64_t g_detCreateSeqCounter = 0;
uint64_t g_detDispatchCount = 0;                  // contagem de handoffs -> avança VBlank
```

Operações (todas sob `g_detMutex`, todas puramente locais — nenhuma tocam o `condition_variable`
de `ThreadInfo`, que continua igual):

- `registerThread(tid, priority)` — chamado em `CreateThread`/`StartThread` (ver §2.3);
  atribui `createSeq` e insere em `g_detThreads`.
- `unregisterThread(tid)` — chamado quando a thread termina (`ExitThread`/dormant).
- `enter(tid)` — equivalente determinístico de `enterGuestExecution()`: marca `tid` como pronta,
  insere em `g_detReadyOrder`; se `g_detCurrentTid == 0`, `pickNext()` imediatamente; senão
  bloqueia em `g_detThreads[tid].cv` até `isCurrent==true`.
- `leave(tid)` — equivalente de `leaveGuestExecution()`: limpa `isCurrent`, remove `tid` de
  pronto (a thread real vai bloquear em seguida no seu próprio `condition_variable` de recurso —
  ela só volta a `g_detReadyOrder` quando o recurso a libera, via `wake(tid)`), chama
  `pickNext()`.
- `wake(tid)` — chamado pelos pontos que hoje fazem `cv.notify_*` sobre um recurso (SignalSema,
  WakeupThread, SetEventFlag, ReleaseWaitThread, VBlank tick, DMAC handler dispatch): insere
  `tid` de volta em `g_detReadyOrder` (não concede o token na hora — só o torna elegível). A
  thread continua bloqueada no seu **próprio** `condition_variable::wait` (sema/evento/sleep)
  até a condição real ficar satisfeita (ela mesma decide isso, sem mudança); só depois ela chama
  `enter(tid)` de novo antes de tocar código guest, exatamente como hoje o
  `GuestExecutionReleaseScope`/reacquire já faz.
- `pickNext()` — se `g_detReadyOrder` não vazio: `tid* = min(g_detReadyOrder)` (prioridade mais
  alta, depois criação mais antiga); marca `g_detThreads[tid*].isCurrent = true`,
  `g_detCurrentTid = tid*`; `notify_one()` só no `cv` de `tid*`. Se vazio: `g_detCurrentTid = 0`
  (idle — todas as threads guest bloqueadas) e **avança VBlank determinístico** (§2.4) antes de
  tentar de novo.

### 2.2 `enterGuestExecution`/`leaveGuestExecution`/`releaseGuestExecution`/
`reacquireGuestExecution` (`ps2_runtime.cpp:1914-1970`)

Ganham um branch no topo:

```cpp
void PS2Runtime::enterGuestExecution()
{
    if (isDeterministicModeEnabled())
    {
        DeterministicScheduler::instance().enter(g_currentThreadId);
        ++g_guestExecutionDepths[this]; // contagem de profundidade continua igual
        return;
    }
    // ... caminho atual, inalterado
}
```

Mesma forma para as outras três. `shouldPreemptGuestExecution()` também ganha um branch: em modo
determinístico, o contador de back-edges continua existindo (mesmo threshold), mas ao devolver
`true` ele **não** apenas deixa o `step()` retornar — ele explicitamente chama
`DeterministicScheduler::instance().leave(tid)` seguido de `enter(tid)` seria um no-op (a mesma
thread pegaria o token de volta se ainda for a de maior prioridade pronta), então o efeito
correto é: `leave()` só, e deixar o dispatch loop chamar `enter()` de novo na próxima iteração —
isso já é o que `Thread.cpp:410-487` faz naturalmente (o `GuestExecutionScope` do próximo
`step()` chama `enter()`). Ou seja, **nenhuma mudança adicional é necessária em
`shouldPreemptGuestExecution` além de garantir que o `return` realmente devolve o controle ao
loop que reentra via `GuestExecutionScope`** — o que já é o caso hoje. Confirmar isso é o
primeiro teste da Etapa 2 (uma thread sozinha não deve travar).

### 2.3 Registro de threads no scheduler

- `CreateThread` (`Thread.cpp:97`) não precisa mudar (não determina execução ainda).
- `StartThread` (`Thread.cpp:264`): logo depois de `g_activeThreads.fetch_add`, se modo
  determinístico, chamar `DeterministicScheduler::instance().registerThread(tid,
  info->currentPriority)`. A thread guest de host (`std::thread worker(...)`) continua sendo
  criada do mesmo jeito — ela só vai ficar bloqueada em `enter(tid)` (dentro do primeiro
  `GuestExecutionScope`) até ser sua vez, o que já resolve o ordenamento de criação: como
  `StartThread` roda dentro de uma seção guest (quem chama `StartThread` já segura o token), a
  nova thread só entra em `g_detReadyOrder` quando `registerThread` roda, e o chamador de
  `StartThread` continua rodando até seu próprio próximo yield — não há corrida de startup.
  A thread principal do jogo (`gameThread`, tid=1) é registrada uma vez em `run()`, antes do
  `dispatchLoop`, com prioridade "mais alta" convencional (ela é a única pronta no início, então
  a prioridade exata não importa até a primeira `StartThread`).
- Término de thread (`ExitThread`/`ExitDeleteThread`/retorno natural em `Thread.cpp:499-556`):
  chamar `unregisterThread(tid)` **depois** de `leave()` acontecer implicitamente (o último
  `step()` da thread já passou por `GuestExecutionScope::~GuestExecutionScope` → `leave()` →
  `pickNext()`), então o unregister é só limpeza de estado, não afeta arbitragem.

### 2.4 VBlank/tempo em modo determinístico

Handoff exige: "tempo" avança por contagem de eventos/dispatch, não relógio de parede.
Implementação escolhida: **VBlank avança quando o scheduler fica idle** (`g_detReadyOrder` vazio
— todas as threads guest bloqueadas esperando algo) **e** quando o número de handoffs de token
desde o último VBlank atinge um teto configurável (`MC3_DET_VBLANK_DISPATCH_INTERVAL`, default
grande o bastante para não disparar durante bursts normais de boot — valor exato a calibrar na
Etapa 3 observando quantos handoffs ocorrem por "frame" real no baseline).

Motivo de usar idle-driven como gatilho primário: é o caso que hoje mais depende de relógio de
parede — quando nada mais pode rodar, o modo atual só progride porque o worker de VBlank acorda
sozinho a cada 16.667ms reais. Em modo determinístico, se o scheduler está idle e existe alguém
esperando em `WaitForNextVSyncTick`/`sceGsSyncVCallback`, avançar o tick imediatamente (sem
dormir) é a escolha determinística natural — mesma sequência de eventos toda vez, sem depender
de quanto tempo real passou. O teto por contagem de dispatch é um cinto de segurança para o
caso (não esperado no boot atual, mas possível) de alguma thread ficar rodando por muitos
handoffs de token sem que ninguém espere VBlank — evita que o jogo nunca veja um tick.

`interruptWorkerMain` (`Interrupt.cpp:304`) ganha um branch: se modo determinístico,
**não inicia** o worker baseado em `steady_clock` — em vez disso, o próprio
`DeterministicScheduler::pickNext()` chama uma função `advanceDeterministicVBlankTick(rdram,
runtime)` (movida de `interruptWorkerMain` para uma função reutilizável) quando idle. Isso
mantém DMAC/INTC/`sceGsSyncVCallback` com o mesmo corpo de código, só muda quem os aciona e
quando.

Alarmes (`SetAlarm`): fora de escopo desta fase (nenhum handler SIF do caminho de boot depende
deles, conforme achado do Bloco A / Fase 1). Ficam com o worker de relógio de parede atual
mesmo em modo determinístico — risco residual documentado no §4, não bloqueia o aceite porque
não aparece na métrica de Stable PC até agora.

### 2.5 `RotateThreadReadyQueue` (`Thread.cpp:1047-1074`)

Hoje só chama `std::this_thread::yield()`. Em modo determinístico isso deve virar um yield real
de token: `leave(tid)` seguido de `enter(tid)` — como o baton sempre escolhe por prioridade e
depois ordem de criação, se houver outra thread pronta de prioridade igual ou maior ela ganha a
vez (mimetiza "roda a fila de prontos do mesmo nível", que é a semântica real do syscall EE,
sem precisar implementar rotação por nível de prioridade separada — a fila do `std::set` já
ordena por prioridade primeiro).

### 2.6 O que NÃO muda no modo padrão

- Sem `MC3_DETERMINISTIC=1` (ou valor `0`/ausente), `isDeterministicModeEnabled()` retorna
  `false` em todo call site, e cada função entra no branch `else` que é **exatamente o código
  atual, sem reformatação** (para manter o diff mínimo e auditável). `DeterministicScheduler`
  nunca é instanciado/tocado. `interruptWorkerMain` continua idêntico. Nenhum SIF handler muda.
  Nenhum `SignalSema` é injetado.

## 3. Lista exata dos pontos de yield (troca de contexto) em modo determinístico

| Syscall/local | Arquivo:linha (padrão) | Ação em modo determinístico |
|---|---|---|
| Back-edge de loop (preempção) | `code_generator.cpp:249` (gerado), consumido via `shouldPreemptGuestExecution` | `leave(tid)`; próxima `GuestExecutionScope` do dispatch loop chama `enter(tid)` |
| `WaitSema` bloqueando | `Sync.cpp:391` | `leave(tid)` antes do `cv.wait`; ao acordar, `enter(tid)` (via `GuestExecutionReleaseScope`/reacquire) |
| `SignalSema`/`SignalSemaByIdForRuntimeCompat` | `Sync.cpp:254,311` | depois de `cv.notify_one()`, chamar `wake(targetTid)` — precisa achar qual tid esperava (novo: registrar `waitId`→tid no `ThreadInfo`, já existe `waitId`/`waitType` por thread; scheduler pode varrer `g_detThreads` procurando quem tem `waitType==TSW_SEMA && waitId==sid`, reaproveitando estado já existente em `ThreadInfo`, sem novo mapa) |
| `SleepThread` bloqueando | `Thread.cpp:843` | `leave`/`enter` iguais a WaitSema |
| `WakeupThread` | `Thread.cpp:885` | `wake(tid)` alvo |
| `SuspendThread` (auto) | `Thread.cpp:697` | `leave`/`enter` |
| `ResumeThread` | `Thread.cpp:711` | `wake(tid)` alvo |
| `WaitEventFlag` bloqueando | `Sync.cpp:741` | `leave`/`enter` |
| `SetEventFlag` | `Sync.cpp:590` | `wake()` de todas as threads com `waitType==TSW_EVENT && waitId==eid` cujo predicado agora é satisfeito (mesma varredura) |
| `TerminateThread` esperando alvo | `Thread.cpp:659` | `leave`/`enter`; alvo termina → `unregisterThread` já libera via `pickNext` natural (thread saindo não precisa de `wake` explícito, quem espera vai reavaliar no próprio predicate do `cv.wait`) |
| `ReleaseWaitThread` | `Thread.cpp:1081` | `wake(tid)` alvo |
| `RotateThreadReadyQueue` | `Thread.cpp:1047` | `leave(tid)`+`enter(tid)` (ver §2.5) |
| Fim de thread (retorno natural/`ExitThread`) | `Thread.cpp:499-556`, `579-622` | `unregisterThread(tid)` após o último `leave()` implícito |
| `WaitForNextVSyncTick` bloqueando | `Interrupt.cpp:400` | `leave`/`enter`; despertar vem de `advanceDeterministicVBlankTick` chamando `g_vsync_cv.notify_all()` como hoje — quem estava esperando reentra em `g_detReadyOrder` na hora de dar `enter()` de novo (não precisa de `wake` símile porque o predicado do próprio `cv.wait` já libera o `wait`; o `enter()` seguinte é que arbitra a vez) |
| Idle do scheduler (`g_detReadyOrder` vazio) | novo, `DeterministicScheduler::pickNext` | chama `advanceDeterministicVBlankTick` |

## 4. Riscos e detecção

- **Risco 1 — starvation por prioridade fixa**: se duas threads de mesma prioridade alta ficam
  sempre prontas ao mesmo tempo, `createSeq` desempata sempre a favor da mais antiga; se ela
  nunca chama um syscall de bloqueio/yield (só back-edges), o teto de
  `shouldPreemptGuestExecution` (64/100 back-edges) ainda força `leave()` periodicamente, então
  não deveria travar — mas **loops sem back-edge** (ex.: só chamadas de função, sem `goto` para
  trás) não emitem o hook. Mitigação de detecção: watchdog por **contagem de handoffs de
  token**, não por tempo — se `g_detDispatchCount` não muda por N tentativas de `pickNext` (ex.:
  1000) com `g_detReadyOrder` não-vazio e nenhuma thread nova registrada, é deadlock/starvation:
  logar `(tid atual, todas as threads em g_detThreads com seu waitType/waitId)` e **parar** via
  exceção fatal (não contornar com sleep de host), exatamente como as regras exigem.
- **Risco 2 — algum completion hoje depende de preempção real do SO** (ex.: um handler de DMAC
  ou callback SIF que espera um efeito colateral de outra thread "correr um pouco" antes de
  checar de novo, sem passar por `WaitSema`/etc.) — se existir, o modo determinístico vai
  travar porque ninguém mais roda. Plano de detecção: o mesmo watchdog do Risco 1; se acionar,
  documentar o par (thread, recurso esperado) e o trace, e parar — achado, não bug a esconder.
- **Risco 3 — VBlank idle-driven pode disparar tick "cedo demais"** comparado ao timing real
  (ex.: se o jogo depende implicitamente de várias iterações de polling antes do primeiro
  vblank). Mitigação: `MC3_DET_VBLANK_DISPATCH_INTERVAL` como piso mínimo de handoffs antes de
  permitir o primeiro tick, calibrado observando o baseline atual.
- **Risco 4 — alarmes e DMAC assíncronos fora do escopo** (§2.4) continuam via relógio de
  parede; se aparecerem no caminho de boot como fonte de variação residual, é o "de onde vem a
  variação residual" que o aceite parcial da Etapa 3 pede para documentar.
- **Risco 5 — recursão de profundidade do GIL** (`g_guestExecutionDepths`) já existe hoje para
  suportar chamadas aninhadas de `GuestExecutionScope` (ex.: RPC invocado de dentro de guest
  code). O baton precisa preservar essa contagem por thread sem re-arbitrar em cada nível
  aninhado — só o primeiro `enter()`/último `leave()` de uma thread tocam o scheduler; níveis
  internos só incrementam/decrementam `g_guestExecutionDepths[this]` como hoje.

## 5. Critério de "não mudou nada no modo padrão"

- Todo novo código está atrás de `if (isDeterministicModeEnabled())`, cacheado de
  `std::getenv("MC3_DETERMINISTIC")` uma vez por processo (mesmo padrão dos outros gates do
  projeto).
- Nenhuma assinatura de função pública muda; `DeterministicScheduler` é um novo arquivo,
  compilado sempre, mas só instanciado/usado atrás do gate.
- Suíte `ps2x_tests` deve continuar ≥266/269 com o env ausente (nenhum teste seta
  `MC3_DETERMINISTIC`).

## 6. Plano de implementação (Etapa 2) e validação (Etapa 3)

1. `DeterministicScheduler.h/.cpp` (novo) com a API do §2.1, watchdog do §4 incluso.
2. Branches em `enterGuestExecution`/`leaveGuestExecution`/`releaseGuestExecution`/
   `reacquireGuestExecution`/`shouldPreemptGuestExecution` (`ps2_runtime.cpp`).
3. `registerThread`/`unregisterThread` em `StartThread`/fim-de-thread (`Thread.cpp`), e registro
   da thread principal em `run()`.
4. `wake()` nos pontos da tabela do §3 (`Sync.cpp`, `Thread.cpp`).
5. `RotateThreadReadyQueue` determinístico (`Thread.cpp`).
6. VBlank idle-driven: extrair corpo de tick de `interruptWorkerMain` para função reutilizável;
   gate em `ensureInterruptWorkerRunning` para não subir o worker de relógio; chamar a partir de
   `DeterministicScheduler::pickNext` quando idle (`Interrupt.cpp`).
7. Build + suíte com env ausente (≥266/269) antes de qualquer teste com o env ligado.
8. Relink (`10_link_partial_runner.bat fast`).
9. `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000 21_probe_repeat.bat 10 595 sched_v1`.
10. `21_probe_repeat.bat 10 595 sched_off_regression` com o env ausente, comparar com
    `usbkb_v1`.
11. Resultado honesto em `docs/RESULT_FASE2_SCHED_V1.md`, incluindo qualquer parada por
    watchdog (Risco 1/2) com o par thread/recurso registrado.
