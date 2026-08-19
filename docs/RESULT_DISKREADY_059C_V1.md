# Resultado — servidor "disco pronto" (sid 0x8000059c), passo 17

Executa `docs/HANDOFF_FASE1_DISKREADY_059C.md`. Data: 19/08/2026. Branch `mc3` (fork local,
sem push), submódulo `PS2Recomp` a partir de `85945ba`. Docs no repo raiz.

## Resumo (3 linhas)

O sid `0x8000059c` (fno=0, send=4, recv=4) foi identificado por trace + decomp fresco de
`sub_005420C0` e implementado no dispatcher SIF (`SCECdComplete=2` no word de recv). O trace
confirma o handler novo disparando 5x (`kind=diskready-status ... value=0x2`) e o boot avança
por um instante para dentro de `sub_00549488` (0x5494e0) — comportamento nunca visto antes
desta mudança. **Mas o gate não saiu de forma estável**: 3x `Probe-Repeat` (90s,
`MC3_DETERMINISTIC=1`) deram 2 Stable PCs distintos (`0x245720` 2/3, `0x542230` 1/3) — a boot
volta a convergir para `0x245720` na maior parte do tempo, e `sceCdRead` (fno=1) não disparou
em nenhuma corrida. Resultado: progresso real e verificado, aceite não alcançado.

## (sid, fno) e resposta implementada

- **Servidor**: `0x8000059c`, fno `0x0`, `send=4B`/`recv=4B` — confirmado por trace honesto
  (90s, `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`, binário pré-mudança, commit-base
  `85945ba`):
  ```
  [boot-trace:mc3-rpc-response-fallback] sid=0x8000059c fno=0x0 payload=0x621600 size=0x4 zeroed=1
  ```
  (5x nessa janela, sempre caindo no fallback genérico de zero-fill antes desta mudança.)
- **Cliente**: `sub_005420C0` (0x5420c0-0x5422c8), bind em `0x6faed0`, retry até 17x
  (`0x542174`-`0x5421cc`). Decomp fresco lido de
  `work/generated/ghidra/sub_005420C0_0x5420c0.cpp` (confirmado compilado, `find_stale.py`=0
  antes de tocar o arquivo).
  - `0x542228`: `jal func_549488` (== `sceSifCallRpc`) com `a0`=client, `a1`=`$zero`=fno 0,
    `a2`=`$zero`=send ptr 0, `t0`=4 (sendsize), `t1`=`s1` (recvbuf), `t2`=4 (recvsize),
    `t3`=`$zero`=endFunc 0 — assinatura estrutural idêntica ao trace (fno=0, send=4, recv=4).
  - Após a call, se `v0>=0` o fluxo cai em `0x542274`→`0x542284`→`0x542288`-`0x542298`:
    `v0 = s1 | 0x2000_0000` (alias KSEG1/não-cacheado do MESMO buffer de recv), depois
    `s0 = *(v0)`, e a função retorna `v0 = s0`. **Ou seja: o valor de retorno de
    `sub_005420C0` É literalmente os 4 bytes que este servidor escreve no recv buffer** — não
    há transformação intermediária.
- **Resposta implementada** (`PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`,
  `handleCdvdRpc`, novo branch antes do branch `serverIsCdvdNcmd`): `kMc3CdvdDiskReadyStatusSid
  = 0x8000059Cu`, `kMc3CdvdDiskReadyStatusFno = 0x0u`, `kMc3CdvdDiskReadyStatusRecvSize = 0x4u`,
  `kMc3ScECdComplete = 2u` (ps2sdk `libcdvd.h`/decomp: `SCECdComplete`). Escreve `memset(dst,
  0, 4)` seguido de `dst[0] = 2` (LE, valor final = `0x00000002`) no `payloadAddr`. Sem
  env-gate, chaveado só por `(sid, fno)`, mesma infra dos handlers `init`/`diskready`/`read`
  já aceitos.

## Trace pós-mudança (90s, `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`, binário novo)

`work/logs/14_run_boot_trace.log` (linhas 8355-8414), 5x:

```
[boot-trace:CreateSema] tid=1 id=44 init=0 max=1 attr=0x8000059c option=0xffffffff param=0x19f1a0 pc=0x5469a0 ra=0x5495dc
[boot-trace:mc3-cdvd-rpc] kind=diskready-status sid=0x8000059c fno=0x0 payload=0x621600 size=0x4 value=0x2 pc=0x546d60 ra=0x5489dc
```
(repetido 5x, ids de sema 44-48, mesma contagem de tentativas do baseline pré-mudança — o
handler novo é chamado e responde `value=0x2` nas 5 vezes.)

**`sub_005420C0` sai do loop de retry desta chamada**: pela primeira vez nesta cadeia de
sessões, o `pc` observado nos `frame` logs avança para dentro de outras funções depois da 5ª
resposta — antes desta mudança o boot ficava permanentemente preso em `0x245720` a partir do
tick ~600 até o fim da janela (ver `RESULT_CDREAD_REAL_V1.md`: "nenhuma outra chamada SIF
acontece pelo resto dos 90s"). Agora:

```
tick=600  pc=0x245720   (baseline conhecido)
tick=660  pc=0x245720
tick=720  pc=0x245720
tick=780  pc=0x542230   <- dentro de sub_005420C0 (pós-loop de retry, fora de 0x245720)
tick=840  pc=0x5494e0   <- dentro de sub_00549488 (a própria func_549488/sceSifCallRpc)
[boot-trace:dispatch-budget-reached] budget=25000 pc=0x245720 ra=0x245720
```

Ou seja: o boot avança de fato para além do bloqueio antigo por um trecho da janela, mas o
orçamento de dispatch se esgota (`budget=25000`) com o PC de volta em `0x245720` — não há
evidência de que a saída seja permanente/estável dentro dos 25000 dispatches medidos.

**`sceCdRead` (fno=1, `kind=read` no trace): 0x nesta corrida.** Não disparou. Único evento
`kind=diskready` (o `sceCdNcmdDiskReady` do sid `0x80000595`, já aceito antes) aparece 1x, sem
mudança.

## Verificação bytes-vs-ISO

Não aplicável nesta sessão: `sceCdRead` não disparou ao vivo (mesma situação do passo 16). O
backend e o teste permanente (`ps2xTest`, "sceCdRead bytes match the real retail ISO when
present") continuam intactos e passando — ver seção Suíte abaixo.

## Trajetória do gate (Probe-Repeat, 3x, 90s, `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`)

`work/boot_probe/repeat_diskready_059c_det_20260819_050542.md`:

| Run | Stable PC | Counters | Timeout |
|---|---|---|---|
| 1 | `0x245720` | dma=2 gif=0 gsw=0 vif=3 gifPk1/2/3=0 gsPrims=0 gsPixels=0 | yes |
| 2 | `0x245720` | idem | yes |
| 3 | `0x542230` | idem | yes |

**2 Stable PCs distintos em 3 corridas** (`0x245720` 2/3, `0x542230` 1/3) — não-determinístico
neste passo, mesma classe de problema já documentada em `RESULT_FASE2B_DIVERGENCE_V1.md`/
`RESULT_FASE2B_ROUND2_V1.md` (corrida de threads no VBlank), fora do escopo deste handoff
para diagnosticar a fundo. **`0x245720` continua sendo o Stable PC majoritário** (2/3) — o
gate não saiu de forma confiável. `0x542230` (visto em 1/3 corridas e no trace com log
detalhado) é evidência de progresso real, não de saída estável do gate.

## Régua de render (M0-M6)

Sem mudança: `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`, `gif=0`, `gsw=0` nas 3 corridas do
probe e na corrida com trace. **M4 não atingido** (`gifPackets>0` E `gsPrims>0` — nenhum dos
dois), nada a confirmar/reportar como vitória de render.

## Build

- `tools/find_stale.py` antes de tocar código: **0 stale** (15811/15811 objetos íntegros).
- `ps2_runtime` (só `SIF.cpp` mudou): rebuild incremental limpo (`cmake --build ... --target
  ps2_runtime`), 1 arquivo recompilado.
- `tools/find_stale.py` de novo antes do relink: **0 stale** (mudança foi só na lib do
  runtime, não em código de jogo gerado — nenhum `.o` de `work/compile/ghidra` precisou
  recompilar).
- Relink: `10_link_partial_runner.bat fast`, PATH MSYS2 (`C:\msys64\ucrt64\bin`) na frente do
  `PATH`, não concorrente com nenhuma compilação. Exe: `work\link\partial\mc3_partial.exe`,
  19/08 04:59:xx (518.690.379 bytes) — mais novo que a lib recompilada.

## Suíte

`ps2xTest/ps2x_tests.exe` (rebuild via `cmake --build ... --target ps2x_tests`), de
`PS2Recomp\out\build`, PATH MSYS2 na frente (necessário para os DLLs runtime do executável de
teste, não só do compilador):

**271/272.** 1 falha isolada, pré-existente e não relacionada a este handoff: `Semaphore
poll/signal remains stable under host-thread contention` — flake de timing sob concorrência de
threads do host, já documentado como classe de problema em sessões anteriores (Fase 2b/2c).
Nenhuma falha nova, nenhuma falha no teste real-ISO (`sceCdRead bytes match the real retail
ISO when present`) nem em nenhum teste de SIF/cdvd.

## Commits

Submódulo `PS2Recomp`, branch `mc3`, **sem push**:
- Handler `handleCdvdRpc` novo para sid `0x8000059c` fno `0x0` (`SCECdComplete=2`),
  `Kernel/Stubs/SIF.cpp` (1 arquivo).

Repo raiz (`mc3recomp`, branch `mc3`), **sem push**: este documento + ponteiro do submódulo.

Nenhum objeto de código de jogo gerado (`work/generated`, `work/compile`) foi commitado —
artefatos de build locais, fora do repo por regra.

## Bloqueios / limitações documentadas

1. **O aceite completo do handoff não foi alcançado**: `sceCdRead` (fno=1) não disparou ao
   vivo em nenhuma das 4 corridas desta sessão (1 com trace + 3 do probe repeat). O gate
   `0x245720` continua sendo o Stable PC majoritário (2/3 no probe).
2. **Progresso real e verificado, porém instável**: com o handler novo, o boot demonstravelmente
   sai de `0x245720` em pelo menos uma fração das corridas (trace: avança até `0x5494e0`
   dentro da janela de 90s antes do budget esgotar; probe: Stable PC `0x542230` em 1/3
   corridas) — comportamento que nunca ocorreu antes desta mudança (baseline: preso em
   `0x245720` do tick ~600 até o fim da janela em 100% das corridas registradas). Isso é
   evidência de que a resposta implementada é aceita pelo cliente (`sub_005420C0` sai do loop
   de retry pelo menos parte do tempo), mas não é suficiente sozinha para produzir uma saída
   estável.
3. **Não-determinismo introduzido/exposto por este passo não foi investigado a fundo** — está
   fora do escopo (regra do handoff: 1 corrida = 1 prova, budget com parcimônia se avançar
   fundo). Fica registrado como próximo obstáculo: o que faz o boot, com a mesma resposta
   determinística do dispatcher, convergir para `0x245720` em 2 de 3 corridas e para
   `0x542230` na terceira, é provavelmente uma corrida de threads (mesma classe de
   `RESULT_FASE2B_*`), não o dispatcher em si (que é puramente determinístico — mesma escrita
   de 4 bytes toda vez).
4. **`_sceCd_cd_read_intr` continua fora do decomp exportado** — inalterado desde o passo 16,
   sem relevância aqui porque `sceCdRead` não chegou a disparar.

## Avaliação frente ao critério de aceite do handoff

Aceite pedia: `sub_005420C0` sai do loop (retorno 2 visto no trace) → `sceCdRead` fno=1
dispara ao vivo com bytes reais → gate sai de `0x245720`. **Alcançado parcialmente**: o
servidor foi identificado e implementado corretamente (decomp-dirigido, sem chute, `(sid,fno)`
como chave), o trace mostra o handler disparando e o boot avançando para além de `0x245720`
por um trecho da janela em pelo menos uma corrida. **Não alcançado**: nenhuma evidência de
`v0=2` sendo lido de volta por `sub_005420C0` foi capturada diretamente (o trace de PC mostra
avanço, mas não instrumenta o valor de retorno da função); `sceCdRead` não disparou; o gate
não saiu de forma estável (2/3 Stable PCs ainda em `0x245720`). Resultado honesto, conforme a
regra do `WORKFLOW.md` ("resultado negativo é entregável").
