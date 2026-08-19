# Resultado — passo 18 (Fase 2d): respostas RPC dentro do turno + recalibração de budget

Executa `docs/HANDOFF_FASE2D_RPC_IN_TICK.md`. Data: 19/08/2026. Branch `mc3` (fork local, sem
push). Submódulo `PS2Recomp` sem mudanças (`63e2435`, mesmo do passo 17).

## Resumo (3 linhas)

Diagnóstico com `MC3_DISPATCH_BUDGET=100000` mostra que a entrega da resposta RPC do sid
`0x8000059c` **já acontece dentro do turno determinístico** (síncrona, inline, na própria
thread que chama `sceSifCallRpc`, sob a arbitração do `DetSched`) — a hipótese do handoff
("entrega fora do turno, mesma doença do VBlank") **não se confirmou**. A oscilação
`0x245720`/`0x542230` do passo 17 era artefato de amostragem (mesmo laço de
`PollSema`/`SignalSema` sid=15/17, dois PCs do mesmo call stack), não dois estados de jogo
diferentes. Recalibrar o budget para 100000 **resolveu a não-determinismo observado**: 10/10
corridas caem no mesmo Stable PC. Mas esse PC é o gate antigo `0x245720`, não território novo —
`sceCdRead` continua sem disparar. Nenhuma mudança de código foi feita (nada para corrigir
dentro do escopo autorizado). Aceite do handoff **não alcançado**, resultado honesto.

## 1. Diagnóstico (budget 100000, 1 corrida)

`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=100000`, `14_run_boot_trace.bat 90`,
`work/logs/14_run_boot_trace.log` (10169 linhas).

- O handler `handleCdvdRpc` (sid `0x8000059c`, fno `0`) dispara **5x**, idêntico ao passo 17:
  ```
  [boot-trace:mc3-cdvd-rpc] kind=diskready-status sid=0x8000059c fno=0x0 payload=0x621600 size=0x4 value=0x2 pc=0x546d60 ra=0x5489dc
  ```
  Mais budget não produz mais respostas — o cliente já para de pedir depois da 5ª.
- O boot avança transitoriamente para dentro de `sub_005420C0` (`0x542230`) e
  `sub_00549488`/`func_549488` (`0x5494e0`), igual ao passo 17 — **mas depois volta e se
  estabiliza em `0x245720`** (`tick=600→245720`, `tick=660→542230`, `tick=720→542230`,
  `tick=780→245720`, ..., `dispatch-budget-reached budget=100000 pc=0x245720`). Com budget
  maior o resultado final é o gate antigo, não o novo.
- **`sceCdRead` (fno=1) não disparou** nesta corrida — mesma ausência do passo 17, budget maior
  não muda isso.
- A partir de `tick=600`, `activeThreads=3` (não 1) — duas threads de guest adicionais existem
  nesse ponto do boot além da thread principal (tid=1). Uma delas (tid=3) está bloqueada em
  `WaitSema sid=5` em `ra=0x398b28`, fora da região SIF/cdvd (`docs/BOOT_PROBE_STATUS.md`,
  seção "Last WaitSema Block") — não relacionada ao gate `0x245720`.

## 2. Mecanismo de entrega da resposta RPC — mapeado, já correto

Fonte: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`, `sceSifSetDma`/`isceSifSetDma`
(linhas 1764-2100) + `handleCdvdRpc` (linha 992).

- `sceSifSetDma` é uma stub de **syscall EE comum** — chamada diretamente pela thread guest que
  executa `sceSifCallRpc` (não por uma thread host separada, não por um worker de IOP). Todo o
  processamento do "lado IOP" da chamada (decodificar o pacote de comando, chamar
  `handleCdvdRpc`, escrever os 4 bytes de resposta no `payloadAddr` via `memcpy`, e finalmente
  `ps2_syscalls::SignalSemaByIdForRuntimeCompat(semaId)` para acordar o cliente) acontece
  **dentro da mesma chamada de syscall, na mesma thread**, antes de `sceSifSetDma` retornar ao
  guest.
- Trace confirma isso diretamente: toda a sequência
  `CreateSema → sceSifSetDma → mc3-cdvd-rpc → sif-command-compat → WaitSema:wake` (linhas
  8355-8362 do log da sessão anterior, `docs/RESULT_DISKREADY_059C_V1.md`) roda em `tid=1`, sem
  nenhuma outra linha de trace de outra origem intercalada nessa janela específica.
- Como `sceSifSetDma` é uma syscall guest normal, ela já executa **sob a arbitração do
  `DeterministicScheduler`** (a thread só está executando porque o `DetSched` lhe deu o baton) —
  não existe uma segunda thread host competindo por esse trabalho, ao contrário do que a Fase
  2b/2c encontrou para o VBlank (`docs/RESULT_FASE2B_DIVERGENCE_V1.md`). **A entrega já está
  subordinada ao turno.**
- Conclusão: **não há bug de "entrega fora do turno" para corrigir neste sid/fno.** A suspeita
  do handoff (mesmo padrão do VBlank) não se sustenta para este mecanismo específico.

## 3. Causa real da oscilação `0x245720`/`0x542230` do passo 17

`docs/RESULT_CDCACHE_DISKREADY_V1.md` (passo 11) já tinha documentado que `0x245720` é dentro
de `sub_00245680`, cujo corpo chama `func_5420C0` (`0x5420c0-0x5422c8`) num laço apertado de
`PollSema`/`SignalSema` (sid 15/17) — produtor/consumidor rápido, não um laço travado. `0x542230`
é um endereço **dentro dessa mesma cadeia de chamada** (a função chamada pelo laço externo), não
um estado de jogo diferente. O log de status mais recente confirma:
`Last Stable Frame: pc=0x245720` com o mesmo padrão `SignalSema`/`PollSema` sid=15/17 em ritmo
alto logo antes.

Ou seja: **`0x245720` e `0x542230` são dois PCs do mesmo laço de espera** (caller/callee),
amostrados em instantes diferentes pela thread de log de frame (que roda no loop de apresentação
do host, a cada 60 ticks — `ps2_runtime.cpp:2304-2311` — não sincronizada ao `DetSched`). Com
`MC3_DISPATCH_BUDGET=25000` (passo 17), o ponto exato onde o orçamento se esgota caía ora dentro,
ora fora dessa janela de amostragem, produzindo a aparência de "2 Stable PCs distintos" sem que o
estado de jogo realmente divergisse. Com budget maior (100000), o laço tem tempo de se
estabilizar antes do fim do orçamento e a amostra final é consistentemente `0x245720`.

**Isto não é a doença do VBlank (2 threads competindo por baton).** É um artefato de medição
(sample point vs. orçamento pequeno demais), resolvido só recalibrando o budget — sem mudança de
scheduler.

## 4. Mudança de código

**Nenhuma.** `git status` do submódulo `PS2Recomp` limpo antes e depois desta sessão (mesmo
commit `63e2435` do passo 17). O diagnóstico (seções 1-3) mostra que o mecanismo suspeito
(entrega RPC fora do turno) já está correto; não há um alvo dentro do escopo autorizado deste
handoff ("scheduler: mudanças permitidas SÓ na subordinação da entrega RPC ao tick") para
corrigir. Forçar uma mudança sem uma causa raiz identificada violaria a regra "sem chute" do
`WORKFLOW.md`.

## 5. Budget recalibrado

`MC3_DISPATCH_BUDGET`: **25000 → 100000** (`STATUS.md` atualizado). Motivo: com 25000 o ponto de
corte caía dentro da janela de oscilação de amostragem (seção 3); com 100000 o laço se estabiliza
antes do orçamento acabar, produzindo Stable PC idêntico em 10/10 corridas (seção 6). Custo:
corridas de trace ficam mais longas em termos de linhas de log (~10k linhas vs ~2-3k), mas ainda
cabem dentro da janela padrão de 90s.

## 6. Aceite (`tools/Probe-Repeat.ps1 -Runs 10 -Mode probe -Seconds 90`, budget 100000)

```
Stable PCs distintos: 1 (0x245720)
Classificações distintas: 1 (counters-moved)
Corridas com render real: 0/10
Falhas de evidência determinística: 0
```

10/10 corridas caem exatamente no mesmo Stable PC: `0x245720` (`sub_00245680_0x245680.cpp`),
mesmos counters (`dma=2 gif=0 gsw=0 vif=3 gifPk1/2/3=0 gsPrims=0 gsPixels=0`) em todas.
**Determinismo pleno alcançado** (1 único Stable PC, 10/10, sem timeout, com marcador de budget)
— mas em **`0x245720`, não em território ≥`0x542230`** como o aceite do handoff exigia. O
critério binário do handoff (**"1 Stable PC único em território ≥0x542230"**) **não foi
atingido**: o Stable PC único obtido é o gate antigo, uma regressão frente à excursão transitória
vista no passo 17, não um avanço estável.

Relatório completo: `work/boot_probe/repeat_fase2d_rpc_tick_v1_20260819_*.md`.

## Régua de render (M0-M6)

Sem mudança: `gifPk1/2/3=0`, `gsPrims=0`, `gsPixels=0`, `gif=0`, `gsw=0` nas 10 corridas do
aceite e no trace de diagnóstico. M4 não atingido.

## Suíte

**Não rodada.** Nenhum arquivo tracked mudou (nem no repo raiz fora de docs/STATUS, nem no
submódulo `PS2Recomp`) — regra do `WORKFLOW.md`/`STATUS.md` de só rodar a suíte completa quando
código tracked muda.

## Commits

- Submódulo `PS2Recomp`: **nenhum** (nada mudou; ainda em `63e2435`).
- Repo raiz (`mc3recomp`, branch `mc3`), sem push: este documento
  (`docs/RESULT_FASE2D_RPC_TICK_V1.md`) + `STATUS.md` (budget padrão `25000→100000`).

## Bloqueios / limitações documentadas

1. **A hipótese central do handoff não se confirmou**: a entrega da resposta RPC do sid
   `0x8000059c` já roda inline, síncrona, na thread guest chamadora, sob arbitração do
   `DetSched` — não há uma segunda thread host competindo pelo turno (diferente do VBlank em
   Fase 2b). Não há mudança de scheduler a fazer dentro do escopo autorizado.
2. **A "instabilidade" do passo 17 (2 Stable PCs em 3 corridas) foi diagnosticada como artefato
   de amostragem** (budget pequeno demais capturando o PC em pontos diferentes do mesmo laço de
   espera `PollSema`/`SignalSema` sid=15/17), não uma corrida de threads real neste mecanismo.
   Recalibrar o budget para 100000 resolveu isso (10/10 determinístico).
3. **`sceCdRead` (fno=1) continua sem disparar** em nenhuma corrida (diagnóstico + 10 corridas do
   aceite). O boot toca território novo (`0x542230`/`0x5494e0`) transitoriamente mas sempre
   volta a se estabilizar no laço `sub_00245680`/`0x245720` — o próximo requisito real para sair
   desse laço (provavelmente uma resposta/estado que `sceCdRead` ou o próprio laço de
   `PollSema` sid=15/17 aguarda) não foi identificado nesta sessão; está fora do escopo deste
   handoff (RPC-in-tick) e precisa de um handoff novo, escopado a esse laço específico
   (`sub_00245680`/`sub_005420C0`), não ao dispatcher SIF.
4. **`activeThreads=3` a partir de tick~600** — duas threads de guest além da principal existem
   nesse ponto; uma delas (tid=3) fica bloqueada em `WaitSema sid=5` fora da região cdvd/SIF
   (`ra=0x398b28`). Não investigado a fundo (fora do escopo), registrado para o próximo handoff.

## Avaliação frente ao critério de aceite do handoff

Aceite pedia: diagnóstico com budget 100000 (feito, seção 1); mapear e, se necessário,
subordinar a entrega RPC ao tick (feito — já estava subordinada, nenhuma mudança necessária,
seção 2); recalibrar o budget (feito — 100000, seção 5); `Probe-Repeat 10x90s` com **1 Stable PC
único em território ≥0x542230** (seção 6: **1 Stable PC único, 10/10, mas em `0x245720`, não em
território ≥0x542230**). **Não alcançado.** Resultado honesto, conforme `WORKFLOW.md`
("resultado negativo é entregável"): o diagnóstico eliminou a hipótese principal (RPC fora do
turno) e produziu uma medição totalmente determinística pela primeira vez nesta cadeia de passos
— mas não no estado que o aceite exigia.
