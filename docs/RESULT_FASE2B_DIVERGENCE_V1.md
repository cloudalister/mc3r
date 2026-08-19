# Resultado — passo 13: a divergência na profundidade nova (Fase 2b)

Executa `docs/HANDOFF_FASE2B_DIVERGENCE.md`. Data: 18-19/08/2026. Branch `mc3` (fork local, sem
push), submódulo `PS2Recomp`. Docs no repo raiz.

## Resumo (honesto: achado real, fix tentado, fix revertido)

Achei e confirmei — por diff evento-a-evento de dois boot traces limpos do mesmo binário
determinístico — **dois mecanismos reais de não-determinismo** na fiação VBlank do scheduler da
Fase 2, exatamente na camada que este handoff autorizou tocar. Corrigi os dois. A correção
combinada, porém, **não passou no re-aceite**: em vez de 1 Stable PC em 10/10, o comportamento
ficou pior (corridas que nem chegam a `dispatch-budget-reached`, ~15-20% de falha de evidência
determinística, incluindo hangs verdadeiros de dezenas de segundos). Não consegui isolar a causa
raiz desse terceiro problema dentro do orçamento da sessão. Seguindo `WORKFLOW.md` ("Suspeita de
bug em camada congelada: reportar no RESULT, nunca remendar dentro de outro handoff") e a regra
do próprio handoff, **revertida integralmente** a correção do scheduler e o contrato de
semáforos (pré-requisito para alcançar a região). Único artefato permanente: uma correção de
integridade de log (mutex compartilhado para os writers `[boot-trace:*]`), que não toca estado
de jogo nem determinismo — foi o que tornou o diff limpo possível e continua útil para a próxima
tentativa.

## 1. Reaplicação do contrato de semáforos (pré-requisito)

Reaplicado localmente o diff descrito em `docs/RESULT_SEMA_CONTRACT_V1.md` seção 3 (sucesso
retorna o `sid`, não `KE_OK`, para `PollSema`/`WaitSema`/`SignalSema`/`DeleteSema`/
`ReferSemaStatus`; `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID` removida). Build limpo, suíte 271/271
com o fix aplicado. Confirmado (de novo) que isso destrava o gate `0x245718` e alcança a região
profunda nova (`0x548e70`/`0x245720`), reproduzindo os 2 Stable PCs já documentados.

## 2. Primeiro mecanismo encontrado: corrida real no token do VBlank

### Método

Adicionei trace de eventos do scheduler (`[boot-trace:det-sched-register/ready/handoff]`,
gated por `MC3_BOOT_TRACE`, sempre serializado sob o mesmo mutex do scheduler — portanto tão
determinístico quanto a própria decisão de arbitragem). Rodei `14_run_boot_trace.bat 30` várias
vezes até capturar uma corrida terminando em cada PC final, e comparei os dois traces
evento-a-evento com um script Python (nunca lendo os ~8MB de log inteiros para o contexto — só a
janela em torno da primeira linha divergente).

**Achado colateral que quase inviabilizou o diff**: `[boot-trace:frame]` (amostrado pela thread
de desenho do host, fora do baton determinístico) rasga linhas de outros writers no meio da
escrita (`std::cerr` não é atômico entre chamadas `<<` encadeadas). Corrigido com um mutex
compartilhado (`ps2xRuntime/include/runtime/ps2_boot_trace_sync.h`) tomado por todo writer
`[boot-trace:*]` do projeto (`Interrupt.cpp`, `ps2_memory.cpp`, `ps2_runtime.cpp`, `Sync.cpp`,
`Thread.cpp`, `GS.cpp`, `SIF.cpp`) — **este é o único artefato de código que sobreviveu ao
revert final** (commit `8c5ddb6` no submódulo). Não muda timing nem estado de jogo.

Descoberta adicional durante a instrumentação: o trace por-evento não pode escrever direto (sem
buffer) — `std::cerr` é unit-buffered (flush a cada operator<<), e a fiação
idle→VBlank→handoff acontece com frequência alta o bastante para, sem batching, impedir o
processo de terminar dentro da janela de 30s mesmo sem nenhum bug lógico (medido: primeira
tentativa travou em `pc=0x1a0138`, só por causa do I/O). Corrigido acumulando linhas em memória
e fazendo flush em lotes de 256KB (ou no `atexit`) — só afeta quando o texto chega ao arquivo,
nunca quando algo guest-visível acontece.

### O evento divergente

Duas corridas idênticas byte-a-byte por **~2700 handoffs consecutivos do scheduler**
(`seq=1`…`seq=2708`, alternando `tid=1`/idle-VBlank a cada handoff). Na posição `seq=2708→2709`:

- Corrida A (final `0x548e70`): `seq=2709` vai para `tid=1` normalmente (alternância mantida).
- Corrida B (final `0x245720`): `seq=2709` vai para o pseudo-thread idle **de novo** (dois
  handoffs de idle seguidos, sem `tid=1` no meio) — daí em diante toda a sequência de handoffs
  fica desalinhada por exatamente 1 posição entre as duas corridas, para sempre.

### Mecanismo

`DeterministicScheduler` (design original da Fase 2) registrava o driver de VBlank como um
**pseudo-participante competindo pelo token** (`DetSchedRegisterIdlePseudoThread`, prioridade
`INT_MAX`), num loop separado: `DetSchedEnter(-1000)` → roda 1 tick → `DetSchedLeave(-1000)` →
repete. O guest thread real faz o mesmo padrão (`leave()` no back-edge de preempção, `enter()`
na próxima iteração do dispatch loop) — mas em **outra thread de host inteiramente separada**.
Cada `leave()`/`enter()` é uma aquisição de mutex própria; entre um `leave()` e o `enter()`
seguinte da MESMA thread existe uma janela real, por menor que seja. Se as duas threads
independentes (guest e driver de VBlank) ficam nessa janela ao mesmo tempo, **quem quer que o
SO agende primeiro para religar** vence a arbitragem — decidido por tempo real de escalonamento
do host, não por `(prioridade, ordem de criação)`. Isso é exatamente a classe de bug que a Fase
2 foi desenhada para eliminar (`docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md`), reaparecendo numa
camada mais interna porque o boot nunca tinha alcançado essa região antes (gate `0x245718`
travava tudo primeiro).

### Fix tentado

Eliminei o pseudo-participante como concorrente. `pickNextLocked()` (chamado só sob o mutex do
scheduler, portanto serializado com toda outra decisão) agora reconhece idle verdadeiro
(`g_ready` vazio, `g_currentTid==0`) e **pede** um tick via uma flag +
`condition_variable` dedicada — RPC-style: o driver só espera o pedido, roda o corpo do tick,
devolve o controle. Nenhuma thread decide sozinha "devo rodar de novo" — essa decisão acontece
uma única vez, sob o mesmo lock que arbitra todo handoff real. Novas funções
`DetSchedWaitForVBlankTickRequest`/`DetSchedCompleteVBlankTick` substituindo
`DetSchedRegisterIdlePseudoThread`.

## 3. Segundo mecanismo (bug no próprio fix, achado ao testar): exclusividade perdida

Testando o fix acima isoladamente, o re-aceite piorou (4 Stable PCs em vez de 2). Causa: o
design novo não fazia `g_currentTid` refletir "tick em andamento" — ficava em `0` durante o
corpo do tick. Como `runOneVBlankTick()` despacha handlers INTC reais (código guest de verdade,
via `dispatchIntcHandlersForCause`), qualquer thread que ficasse pronta **durante** o corpo do
tick (ex.: por um `SignalSema` chamado de dentro de um handler) podia vencer `pickNextLocked()`
e começar a rodar **concorrentemente** com o próprio código guest do handler — uma segunda fonte
de não-determinismo, autoinfligida pelo fix. Corrigido com um sentinel
(`kVBlankInProgressTid`) que `pickNextLocked()` escreve em `g_currentTid` ao pedir o tick e que
`DetSchedCompleteVBlankTick()` limpa ao terminar — nenhuma outra thread pode ser escolhida
enquanto o tick roda.

Com os dois fixes juntos: probe de confirmação rápida (`Probe-Repeat.ps1 -Seconds 20`, 5
corridas) voltou a 2 Stable PCs limpos (mesma divergência de antes, nenhuma pior) — sinal de que
a corrida original estava mesmo resolvida.

## 4. Terceiro mecanismo, parcialmente encontrado, **NÃO corrigido com segurança**

### Evidência

Diff limpo (sem rasgo, com o mutex de trace) de duas corridas pós-fix-duplo: idênticas por
~600 ticks de VBlank, depois divergem exatamente onde `sub_00545648` (helper de `sceGsSyncV`)
lê `gs_csr_lo` — uma corrida vê `0x0`, a outra `0x2000` (bit 13 = CSR.FIELD) no mesmo ponto
lógico do trace. Rastreei até `WaitForNextVSyncTick` (`Interrupt.cpp`): ele bloqueia num
`condition_variable` (`g_vsync_cv`) **separado do mutex do scheduler**; quando um tick sinaliza
esse cv, a thread guest acordada tem que, no seu próprio tempo real de SO, desenrolar e chamar
`DetSchedEnter(tid)` de volta — mesma classe de corrida do mecanismo 1, só que num ponto de
notificação diferente.

### Fix tentado e por que foi revertido

Apliquei o mesmo padrão de `DetSchedMarkReadyWaitingOnSema`/`Event`: nova tag
`TSW_VSYNC` em `ThreadInfo::waitType`, nova `DetSchedMarkReadyWaitingOnVSync()` chamada
sincronamente de dentro de `signalVSyncFlag()` (mesma thread/lock que decidiu o tick). Isolado
(sema+scheduler race+exclusividade+este fix juntos): **re-aceite piorou muito** — várias
corridas nunca chegam a `dispatch-budget-reached` mesmo com timeout de 20-30s (`marker=no`,
`timeout=yes`, ou classificadas como PC totalmente diferente tipo `semaphore pc=0x4aea04`).

Revertendo só esse terceiro fix (mantendo os dois primeiros): **o problema persistiu
idêntico** — ou seja, o bug não está no fix do `TSW_VSYNC` em si, está em algo que os fixes 1+2
(mecanismo VBlank/exclusividade) já introduziram e que só fica visível estatisticamente (não é
100% reproduzível, aparece em ~30-40% das corridas). Tentei isolar com um watchdog de
diagnóstico (`kIdleStallTickLimit` baixado para 50, flush do trace de scheduler baixado para
1KB para não perder o log em corridas mortas à força) — **descobri que os casos "travados" que eu
tinha capturado com timeout curto (10-25s) na verdade terminam se dado mais tempo (confirmado:
6/6 terminaram com 90s)** — ou seja, parte do que parecia "hang" era só lentidão real,
provavelmente amplificada pela própria instrumentação de diagnóstico (flush a cada 1KB é caro).
Mas **mesmo depois de restaurar os valores de diagnóstico aos originais** (sem overhead extra) e
rodar o probe limpo (`Probe-Repeat.ps1 -Seconds 30`, sem `MC3_BOOT_TRACE`), **2 de 10 corridas
ainda falharam a evidência determinística** — uma com `timeout=yes marker=no` genuíno, outra
parando num PC totalmente fora do padrão conhecido (`0x4aea04`, classificação `semaphore`). Isso
não é mais "só lento" — é uma regressão real, ainda não isolada.

**Não consegui, dentro do orçamento desta sessão, provar por que os 2 primeiros fixes (que
isoladamente parecem corretos por inspeção de código e por um probe de 5 corridas em 20s)
produzem esse comportamento pior sob amostragem maior.** Hipóteses não confirmadas para a
próxima sessão:
1. Alguma interação entre o sentinel de exclusividade (`kVBlankInProgressTid`) e o caminho de
   `DetSchedUnregisterThread`/término de thread quando isso acontece bem no meio de um tick.
2. Uma segunda corrida, mais rara, envolvendo `dispatchGsSyncVCallback` (despachado de dentro do
   corpo do tick) que pode invocar código guest cujo comportamento realimenta o próprio ritmo
   de ticks.
3. Recursão: se algum callback despachado durante `runOneVBlankTick` acabar chamando
   `WaitForNextVSyncTick` a partir da própria thread do driver (`g_currentThreadId==-1000`),
   isso pode autotravar o produtor do próximo tick — não confirmado, `lookupThreadInfo(-1000)`
   deveria retornar nulo e pular o novo código, mas o `g_vsync_cv.wait` em si não é condicional
   a isso.

## 5. Decisão: reverter tudo, exceto a correção de log

Seguindo a regra do handoff ("Regressão disso = reverter e reportar") e `WORKFLOW.md`
("Suspeita de bug em camada congelada: reportar no RESULT, nunca remendar dentro de outro
handoff"): `git checkout --` no submódulo restaurou **byte-a-byte** ao estado anterior à sessão:
`ps2xRuntime/include/ps2_syscalls.h`,
`ps2xRuntime/src/lib/Kernel/Syscalls/Helpers/DeterministicScheduler.cpp`,
`ps2xRuntime/src/lib/Kernel/Syscalls/Helpers/State.h`,
`ps2xRuntime/src/lib/Kernel/Syscalls/Interrupt.cpp`,
`ps2xRuntime/src/lib/Kernel/Syscalls/Sync.cpp`, e os 3 arquivos de teste do contrato de sema.
Confirmado por rebuild + suíte (271, mesmo flake documentado) + probe de sanidade (volta ao gate
histórico `0x245718`, comportamento pré-sessão).

**Único commit permanente** (submódulo `PS2Recomp`, branch `mc3`, sem push, `8c5ddb6`): a
correção de integridade de log (`ps2xRuntime/include/runtime/ps2_boot_trace_sync.h` novo +
guards de mutex em `GS.cpp`/`SIF.cpp`/`Thread.cpp`/`ps2_memory.cpp`/`ps2_runtime.cpp`). Não
altera nenhum estado de jogo, timing ou decisão de scheduler — só serializa a escrita de texto
de diagnóstico. Mantida porque (a) é comprovadamente segura (testada isolada e em combinação, sem
efeito em determinismo), e (b) é exatamente o que tornou o diff evento-a-evento deste handoff
possível — sem ela, a próxima tentativa perde tempo re-descobrindo o mesmo problema de log
rasgado.

`MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID` **continua existindo** (não foi removida — fazia parte da
correção revertida, mesma situação do passo 12).

## 6. Trajetória do gate

**Sem mudança de marco.** Gate continua `0x245718` (o mesmo de antes desta sessão) — o contrato
de sema que destrava esse gate foi revertido junto com tudo o mais. Não há progresso líquido no
caminho até o frame nesta sessão; o valor entregue é o diagnóstico dos dois mecanismos de
corrida confirmados no scheduler (documentados e prontos para reaplicar) e um terceiro mecanismo
mapeado mas não resolvido.

## 7. Régua de render (M0-M6)

Inalterada: `gifPk1/2/3=0`, `gsPrims=0`, `gsPixels=0`. M4 não se aplica — nenhuma corrida desta
sessão chegou perto de `gifPackets>0`/`gsPrims>0`; nada a reportar como vitória grande.

## 8. Suíte

`ps2x_tests.exe`, `PS2Recomp\out\build`: **271 testes**. No estado final (revertido + fix de log
apenas): 5 rodadas, 4× 271/271, 1× 270/271 — o mesmo flake histórico de VBlank já documentado em
`RESULT_FASE2_SCHED_V1.md`/`RESULT_GSYNCV_METRICS_V1.md` (timing real de `steady_clock` no modo
não-determinístico dos testes unitários, não relacionado a este handoff). Consistente com o piso
`≥266/269` da regra.

## 9. Commits

Submódulo `PS2Recomp`, branch `mc3`, sem push:
- `8c5ddb6` — "trace: serialize all [boot-trace:*] writes to stderr behind one shared mutex"
  (único commit de código desta sessão; tudo o mais foi revertido antes de qualquer commit).

Repo raiz (`mc3recomp`, branch `mc3`), sem push: este documento, pronto para commit local pelo
executor. Referência do submódulo atualizada para `8c5ddb6`.

## 10. Aceite do handoff

**Não alcançado.** O aceite exigia 1 Stable PC em 10/10 com o contrato de sema aplicado
permanentemente — não foi possível chegar lá com segurança dentro do orçamento desta sessão.
Dois mecanismos de corrida real foram confirmados por evidência de diff e corrigidos; um
terceiro mecanismo foi confirmado como real (não é só lentidão) mas não isolado nem corrigido.
Reverter era a opção mais honesta disponível: aplicar os fixes 1+2 sozinhos (sem entender o
terceiro problema) trocaria "2 Stable PCs válidos, 10/10 com evidência determinística" por "10-20%
de falhas de evidência determinística, incluindo casos que nunca terminam dentro de qualquer
timeout razoável" — uma regressão pior que a que motivou este handoff.

## Recomendação para o próximo handoff

1. **Os dois primeiros fixes (corrida do token de VBlank + exclusividade) provavelmente estão
   corretos** — a lógica foi verificada por inspeção repetida e por diffs limpos, e um probe
   pequeno (5×20s) não mostrou regressão. O problema aparece só sob amostragem maior (10 corridas
   ou mais, ou timeouts mais curtos). Vale reaplicar (diff completo nas seções 2-3 deste doc,
   fácil de reconstruir) e investigar especificamente **por que às vezes o boot fica muito mais
   lento** (não travado — os testes de 90s mostraram 6/6 terminando) antes de tentar o terceiro
   fix (`TSW_VSYNC`).
2. **Instrumentar sem custo de I/O desde o início**: qualquer trace novo de alta frequência deve
   nascer com batching (como o `g_detSchedTraceBuffer` desta sessão), nunca `std::cerr` direto
   por evento — o primeiro dia desta sessão foi perdido descobrindo isso.
3. **Diferenciar "lento" de "travado" cedo**: usar sempre pelo menos duas janelas de timeout
   (ex. 20s e 90s) ao investigar uma regressão de probe, para não confundir devagar-mas-termina
   com deadlock real — essa confusão consumiu boa parte do orçamento desta sessão.
4. O mutex de log (`ps2_boot_trace_sync.h`, já commitado) deve ser reusado, não recriado.
