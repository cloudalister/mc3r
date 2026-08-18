# Resultado — passo 12: contrato de retorno dos syscalls de semáforo (auditado, corrigido, e revertido por regressão de determinismo)

Data: 2026-08-18. Executor: Claude (Sonnet 5). Handoff: `docs/HANDOFF_FASE1_SEMA_CONTRACT.md`.

## Resumo (2 linhas)

A auditoria confirmou o contrato correto (sucesso retorna o **sid**, não `KE_OK`) para toda a
família de semáforos, a correção permanente derrubou o gate `0x245718` (prova por trace único),
mas o re-aceite obrigatório da Fase 2 (`21_probe_repeat.bat 10 probe`) **falhou** — 2 Stable PCs
distintos em 10/10, reproduzido em duas bateladas limpas — então, seguindo a regra do handoff
("Regressão disso = reverter e reportar"), **revertida integralmente**. Zero mudança de código
permanece no repo; este RESULT é o único artefato novo.

## 1. Auditoria do contrato (call sites do jogo + consistência de família)

Insumos: `work/generated/ghidra/*.cpp` (recompilado, ~230 referências às 9 primitivas),
`work/exports/alpha_decomp_sce.txt` (wrappers `ipcPollSema`/`ipcWaitSema`/`ipcSignalSema`/
`ipcDeleteSema`, SDK genérico, não do binário retail), `PS2Recomp/ps2xRuntime/src/lib/Kernel/
Syscalls/Sync.cpp`, `PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Helpers/
DeterministicScheduler.cpp`.

| Syscall | Contrato antes | Contrato correto (auditado) | Evidência |
|---|---|---|---|
| `PollSema`/`iPollSema` | `KE_OK`(0) no sucesso, atrás de `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID` | **sid** no sucesso | **Confirmado por call site do jogo**: `sub_005420C0_0x5420c0.cpp:0x54210C`→`0x542114` (`PollSema` seguido de `bne $v1,$v0` comparando contra o sid lido de `0x61FBB0`) — já documentado em `docs/RESULT_CDCACHE_DISKREADY_V1.md`. `iPollSema` delega para `PollSema` sem call site próprio no jogo. |
| `WaitSema` | `0` (=KE_OK) no sucesso | **sid** no sucesso | Varredura de agente dedicado em **34 call sites** de fallback (`WaitSema_0x5469e0`) em todo `work/generated/ghidra/*.cpp`: em **nenhum** o retorno (`$v0`/reg2) é lido antes de ser sobrescrito por outra instrução — o jogo nunca consome esse valor nos pontos varridos. Contrato aplicado por **consistência de família** com `PollSema` (mesmo mecanismo kernel, mesma classe de primitiva), não confirmado contra um consumidor. |
| `SignalSema`/`iSignalSema` | `0`/`KE_SEMA_OVF` | **sid** no sucesso, `KE_SEMA_OVF` no overflow (inalterado) | Varredura de **57+20=77** call sites (`SignalSema_0x5469c0`+`iSignalSema_0x5469d0`): mesmo padrão — retorno nunca lido antes de sobrescrita (branch incondicional / reload de memória logo após a chamada). Aplicado por consistência de família, não confirmado. |
| `DeleteSema`/`iDeleteSema` | `KE_OK` | **sid** no sucesso | Varredura de **38** call sites (`DeleteSema_0x5469b0`): mesmo padrão, retorno ignorado (ex. `FUN_00541560_0x541560.cpp` chama `SignalSema`+`DeleteSema` 4x em sequência de cleanup sem checar nenhum retorno). Aplicado por consistência de família. |
| `ReferSemaStatus`/`iReferSemaStatus` | `KE_OK` | **sid** no sucesso | **Nenhum call site no jogo** — busca pelo endereço de stub esperado (`0x546a10`/`0x546a20`, sequência de `+0x10` a partir de `PollSema=0x5469f0`) só encontrou falsos positivos (bytes de instrução `bnel`, não chamadas). O jogo não invoca essas duas primitivas na janela de boot traçada. Aplicado por consistência de família, sem qualquer confirmação por consumidor. |
| `CreateSema` | id novo no sucesso | **sem mudança** — já correto | Confirmado por `ipcCreateSemaEx`/testes existentes (`t.IsTrue(sid > 0, ...)`); consistente com o resto da família. |

Erros (`KE_UNKNOWN_SEMID=-408`, `KE_SEMA_ZERO=-419`, `KE_SEMA_OVF=-420`, `KE_WAIT_DELETE`,
`KE_RELEASE_WAIT`, `KE_ERROR`) permanecem negativos e inalterados em toda a família — a auditoria
não encontrou nenhuma divergência nos caminhos de erro.

**Honestidade sobre a força da evidência**: apenas `PollSema` tem confirmação direta contra um
call site do binário retail. Para `WaitSema`/`SignalSema`/`DeleteSema`/`ReferSemaStatus`, a
varredura (feita por agente dedicado, cobrindo a totalidade dos call sites de fallback, não uma
amostra) mostrou que **o jogo simplesmente não lê o retorno dessas quatro primitivas** em nenhum
ponto alcançado pelo boot traçado — então a mudança para elas foi aplicada por consistência de
família com o contrato comprovado do EE kernel real (mesmo subsistema, mesmo padrão "retorna o
id do objeto, não 0", quirk documentado na comunidade PS2 homebrew), não por confirmação
byte-a-byte. Isso respeita a regra "sem chute" no sentido de que a mudança não é uma invenção
sem lastro, mas é importante registrar que não é do mesmo grau de certeza que `PollSema`.

## 2. Varredura por dependências internas do contrato antigo

- `PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Helpers/DeterministicScheduler.cpp` (dono da
  mecânica de troca de contexto da Fase 2, **não tocado**): `DetSchedMarkReadyWaitingOnSema`
  opera inteiramente sobre o **sid** (parâmetro explícito) e o estado interno de
  `ThreadInfo::waitType/waitId` — nunca lê o valor de retorno do syscall (`ctx->r2`). Confirmado
  por leitura completa do arquivo.
- `SignalSemaByIdForRuntimeCompat` (`Sync.cpp`, usado por `SIF.cpp` para completar RPCs de
  movie/USB a partir de threads host) retorna `bool`, nunca escreve em `ctx->r2` — não depende
  do contrato de retorno do syscall guest.
- `grep` por `PollSema|WaitSema|SignalSema|DeleteSema|ReferSemaStatus` em todo
  `ps2xRuntime/src` fora de `Sync.cpp`: único uso é o dispatch por número de syscall
  (`Dispatcher.cpp`, que só encaminha para as funções de `Sync.cpp`, não interpreta o retorno) e
  comentários. Nenhuma dependência interna do contrato antigo encontrada em `game_overrides.cpp`
  nem `ps2_runtime.cpp`.

## 3. Correção aplicada, testada e — **depois revertida**

Editado (e depois revertido via `git checkout --`, ver seção 5): `Sync.cpp` (remoção de
`isMc3PollSemaReturnSidExperimentEnabled()`/flag; `PollSema` permanente sem gate;
`WaitSema`/`SignalSema`/`DeleteSema`/`ReferSemaStatus` passando a retornar o sid no sucesso,
preservando os códigos de erro; refatorado o gate interno
`if (ret == KE_OK && isMc3DeterministicModeEnabled())` de `SignalSema` para um bool `signaled`
explícito, sem alterar quando/como `DetSchedMarkReadyWaitingOnSema` é chamado — só o valor
numérico de retorno mudou, a mecânica do scheduler ficou intocada, conforme a regra do
handoff). Testes atualizados no mesmo commit hipotético: `ps2xTest/src/
ps2_runtime_kernel_tests.cpp`, `ps2_runtime_expansion_tests.cpp`, `ps2_sif_rpc_tests.cpp`
(asserts que esperavam `KE_OK` viraram `sid`, com comentário citando este doc).

Build (`cmake --build PS2Recomp/out/build --config Debug`, MSYS2 `g++`/Ninja/CMake 3.30.5 no
PATH): limpo. Suíte completa (`ps2x_tests.exe`): **271 testes, 270 passaram, 1 falhou** — o
mesmo flake documentado (`VU0 macro mappings cover all S1/S2 enums`, falha de working directory
em `instructions.h`, não relacionado a sema), idêntico ao baseline. Todos os testes de semáforo
(`semaphore EE layout covers poll, signal overflow, and status`, `semaphore legacy layout decode
remains supported`, `Semaphore poll/signal remains stable under host-thread contention`, `snddrv
state RPC returns stable buffers and signals sema`) passaram com as novas expectativas.

## 4. Trajetória do gate — prova por trace único (com a correção aplicada)

`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000 MC3_BOOT_TRACE=1`, `14_run_boot_trace.bat 30`
(exe relinkado com o fix, `work/link/partial/mc3_partial.exe` mais novo que
`libps2_runtime.a`), log em `work/logs/14_run_boot_trace.log`:

- Ocorrências de `pc=0x245718` no log: **0** (baseline antigo: 1571 ticks travado ali). O padrão
  `PollSema ret=-419` constante (contador vazando) desaparece; em seu lugar aparece o
  produtor/consumidor saudável já previsto no diagnóstico do passo 11:
  ```
  [boot-trace:PollSema] tid=1 sid=15 count=1->0 ret=15 pc=0x5469f0 ra=0x54178c
  [boot-trace:SignalSema] tid=1 sid=15 count=0->1 ret=15 pc=0x5469c0 ra=0x5417f8
  [boot-trace:PollSema] tid=1 sid=17 count=1->0 ret=17 pc=0x5469f0 ra=0x542114
  [boot-trace:SignalSema] tid=1 sid=17 count=0->1 ret=17 pc=0x5469c0 ra=0x542244
  ```
- O boot avança bem além do gate antigo: `tid=3` (thread do jogo) chega a terminar
  (`[boot-trace:thread-exit] id=3 exited=0`, `[boot-trace:loop-exit] ... gameThreadFinished=1`)
  dentro da janela de 30s/budget=25000, algo que nunca acontecia no baseline.
- `dispatch-budget-reached` final: `pc=0x548e70 ra=0x548e58` (bem além de `0x245718`).
- Régua de render: `gifPk1/2/3=0`, `gsPrims=0`, `gsPixels=0` — sem mudança de marco (M4/M5 não
  alcançados; nada a reportar em `gsPixels>0`).

**Esta parte da prova é sólida e reprodutível** — o problema não é a correção do gate em si, é o
que a Fase 2 faz depois de alcançá-lo (seção 5).

## 5. Re-aceite da Fase 2 — **FALHOU**, correção revertida

Critério exigido (idêntico ao que aceitou a Fase 2 originalmente): `21_probe_repeat.bat 10 probe
<label>` → 1 único Stable PC em 10/10 com evidência determinística válida
(`MC3_DETERMINISTIC=1`, `MC3_DISPATCH_BUDGET=25000`, marker=yes, timeout=no em todas as 10).

- **Batelada 1** (`sema_contract_v1`, sem `MC3_DETERMINISTIC` setada por engano do executor):
  10/10 `deterministic=no` — evidência inválida, descartada,
  `work/boot_probe/repeat_sema_contract_v1_20260818_042043.md`.
- **Batelada 2** (`sema_contract_v1`, com env correta, mas com um processo `grep` órfão de uma
  busca anterior ainda rodando em background consumindo CPU): 3 Stable PCs distintos
  (`0x245720`×6 válidos, `0x548e70`×2 válidos, `0x5494e0`×1 com evidência **inválida**
  marker=no/timeout=yes — contaminação de CPU real, não determinismo do runtime),
  `work/boot_probe/repeat_sema_contract_v1_20260818_042227.md`. Processo órfão identificado
  (`tasklist`) e morto antes da próxima batelada.
- **Batelada 3** (`sema_contract_v1_clean`, CPU limpa confirmada, mesma env): **10/10 com
  evidência válida** (`marker=yes`, `timeout=no` em todas), mas **2 Stable PCs distintos**:
  `0x548e70` em 6 corridas (1,4,5,7,8,9), `0x245720` em 4 corridas (2,3,6,10). Zero corridas
  inconsistentes (classificação bate com contadores), zero falhas de evidência determinística —
  ou seja, isto não é ruído de medição, é uma divergência real e reproduzível na trajetória sob
  `MC3_DETERMINISTIC=1`. `work/boot_probe/repeat_sema_contract_v1_clean_20260818_042447.md`.

**Isto é uma regressão do critério de aceite da Fase 2** (que exigia 1/10, e foi validado assim
em `b9b40d2`). Nenhuma linha de `DeterministicScheduler.cpp` foi tocada nesta sessão — a hipótese
mais provável (não confirmada, fora do escopo deste handoff investigar a fundo) é que essa
não-determinismo **já existia** na Fase 2, mas nunca foi observável porque o boot sempre travava
para sempre em `0x245718`, muito antes de qualquer trajetória que dependesse dela; ao corrigir o
contrato de retorno e destravar o gate, a execução passou a alcançar, pela primeira vez, um
trecho onde essa divergência se manifesta. Isso não muda a ação exigida pelo handoff: "Regressão
disso = reverter e reportar."

## 6. Reversão

`git checkout -- ps2xRuntime/src/lib/Kernel/Syscalls/Sync.cpp ps2xTest/src/
ps2_runtime_expansion_tests.cpp ps2xTest/src/ps2_runtime_kernel_tests.cpp ps2xTest/src/
ps2_sif_rpc_tests.cpp` no submódulo `PS2Recomp` (branch `mc3`) — os 4 arquivos voltaram
byte-a-byte ao estado anterior a esta sessão (`git status` limpo, nada staged, nada a commitar
no submódulo). Rebuild + relink (`10_link_partial_runner.bat fast`) confirmaram a reversão:

- Suíte: 271 testes, 270 passaram, 1 falhou (mesmo flake de sempre) — idêntico ao estado antes
  desta sessão.
- Trace único pós-reversão (`14_run_boot_trace.bat 30`, mesma env): `pc=0x245718` de volta como
  PC estável (`tick=1740`, preso), confirmando bit-a-bit o comportamento anterior à sessão.

`MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID` **continua existindo** no runtime (não foi removida,
porque a remoção fazia parte da mudança revertida). Não foi tocado nenhum outro arquivo do
projeto (nenhum doc de fato, nenhum script `.bat`/`.ps1`) — as referências históricas à flag em
`docs/RESULT_CDCACHE_DISKREADY_V1.md`, `docs/MASTER_PLAN_TITLE_SCREEN.md`, `BRAIN.md`,
`tools/Boot-Probe.ps1` (dentro de presets de experimento já aposentados por `STATUS.md`)
permanecem válidas sem alteração.

## 7. Régua de render (M0-M6)

Sem mudança de marco em nenhum momento desta sessão: `gifPk1/2/3=0`, `gsPrims=0`, `gsPixels=0`
tanto com o fix aplicado (seção 4) quanto após a reversão (seção 6). M4 não se aplica; nada a
reportar sobre `gsPixels>0`.

## 8. Suíte

271 testes, 270 passaram, 1 falhou (flake pré-existente e documentado, `VU0 macro mappings cover
all S1/S2 enums` — dependência de working directory para achar `instructions.h`, não relacionado
a semáforos). Idêntico antes e depois desta sessão (a versão com o fix aplicado também passou
nesse mesmo número antes de ser revertida).

## 9. Commits

Nenhum commit de código — a mudança foi revertida antes de qualquer commit acontecer no
submódulo `PS2Recomp`. Este RESULT doc é o único artefato novo, no repo principal (`mc3recomp`,
branch `mc3`), pronto para commit local pelo executor.

## 10. Aceite do handoff

**Não alcançado** — por regressão comprovada no re-aceite obrigatório da Fase 2, seguindo à risca
a regra do próprio handoff ("Regressão disso = reverter e reportar"). O achado é honesto e tem
valor: (a) o contrato de retorno auditado e correto para toda a família de semáforos agora está
documentado e confirmado (`PollSema` por call site, os demais por consistência de família); (b)
a correção efetivamente derruba o gate `0x245718` quando aplicada isoladamente (trace único,
seção 4); (c) mas expõe uma não-determinismo pré-existente na Fase 2 (scheduler determinístico,
camada congelada) que nunca tinha sido observável antes porque o boot nunca alcançava esse
trecho. Por regra do `WORKFLOW.md` ("Suspeita de bug em camada congelada: reportar no RESULT,
nunca remendar dentro de outro handoff"), esse achado não foi investigado a fundo nem corrigido
aqui — é entregue como está, para o dono do scheduler decidir o próximo passo.

## Recomendação para o próximo handoff

1. **Não é possível destravar `0x245718` sem antes (ou junto de) resolver a não-determinismo da
   Fase 2 revelada aqui.** Um handoff novo, escopado para o dono do scheduler (não para
   sema/kernel), deveria: reproduzir a divergência (`21_probe_repeat.bat 10 probe <label>` com
   `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000` sobre um binário com o contrato de sid
   aplicado — os patches estão descritos byte-a-byte na seção 3 deste doc e no diff revertido,
   fácil de reaplicar), instrumentar por que a mesma sequência de dispatch determinística chega a
   dois PCs finais diferentes (hipóteses a checar, não confirmadas: threads reais de host fora do
   baton — ex. `SignalSemaByIdForRuntimeCompat` chamado de `SIF.cpp` por workers de
   movie/USB/RPC — podem marcar um semáforo "pronto" em pontos diferentes do tempo real entre
   corridas mesmo que a arbitragem do baton em si seja determinística; ou uma race na própria
   captura do "Stable PC" de qual thread está em `ctx->pc` no instante exato do
   dispatch-budget-reached, quando `activeThreads>1`).
2. Só depois disso reaplicar o contrato de retorno de sid (seção 3 tem o diff completo,
   reversível em minutos) e refazer o re-aceite de 10/10.
