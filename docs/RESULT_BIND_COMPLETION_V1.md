# Resultado — passo 19b: completion do bind SIF, gate 0x245720 rompido

Executa a continuação do handoff (`docs/RESULT_LOOP_245720_V2.md`), verificando a
hipótese do coordenador (padrão SDK: bind assíncrono grava campo no client struct que
o retry-loop testa) antes de codar. Data: 19/08/2026. Repo raiz `mc3recomp` (branch
`main`) + submódulo `PS2Recomp` (branch `mc3`).

## Resumo (3 linhas)

A hipótese do coordenador estava parcialmente certa de espírito mas errada em
mecanismo: o campo que trava o retry-loop de `sub_005420C0` não é um "bind-done" no
client struct — é o bit0 ("busy") do slot que o **pool de 256 pacotes RPC**
(`func_548E40`, decomp) marca ocupado a cada `sceSifSendCmd`/bind e que **nunca era
liberado** pelo runtime, porque a liberação real acontece no handler de interrupção
`sceSifCmdIntrHdlr` — que é um `TODO_NAMED` (nunca implementado) — e o runtime
completa bind/call de forma síncrona sem passar por esse caminho. Cada bind (sucesso
ou falha) drenava 1 slot do pool; uma vez esgotado, todo bind subsequente falhava com
-1 para sempre, batendo exatamente com o padrão observado ("sucesso ocasional,
depois busy-spin permanente"). Implementei a liberação do slot (limpar bit0 em
`xfer.src+0x10`) dentro do handler de completion de `sceSifSetDma`
(`PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`), unconditional para qualquer
bind (`0x80000009`)/call (`0x8000000A`) — **gate 0x245720 rompido, `sceCdRead`
disparou ao vivo pela primeira vez**, confirmado 3x.

## Campo/offset do bind-done (evidência do decomp)

Não existe um único "bind-done flag" no client struct como a hipótese original
supunha. A cadeia real, toda a partir de decomp honesto (`work/generated/ghidra/`):

- `sceSifBindRpc` alpha (`work/exports/alpha_decomp_sce.txt` linha ~4820) e a versão
  retail recompilada (`sub_005492B8_0x5492b8.cpp`) fazem, em modo síncrono
  (`mode&1==0`, o caso usado por `sub_005420C0`):
  1. `func_548E40` (`work/generated/ghidra/FUN_00548e40_0x548e40.cpp`,
     0x548e40-0x548ee8): varre um pool fixo de **256 slots de 0x40 bytes** no global
     `0x69ab40`. Cada slot tem seu "busy flag" no **bit0 do word em
     `slot+0x10`** (`0x548e70-0x548e88`: `v0 = READ32(slot+0x10) & 1`; se ocupado,
     avança; se livre, faz `*(slot+0x10) = (index<<16)|5` — seta bit0). Se os 256
     slots estiverem todos ocupados, retorna `0` (`0x548ec8-0x548ed0`).
  2. Se `func_548E40` retornar `0` (nenhum slot livre), `sceSifBindRpc` retorna `-1`
     direto (`0x5492f4: beqz $s0 → v0=-1`) — **isto** é o que faz `func_5492B8`
     retornar `<0` em `sub_005420C0` e entrar no busy-spin de
     `0x5421ac-0x5421cc`.
  3. Se houver slot livre, `CreateSema` + `sceSifSendCmd(0x80000009, slot, 0x40, 0,0,0)`
     + `WaitSema` no semáforo recém-criado — o slot fica marcado ocupado
     **antes** de saber se o bind vai ter sucesso.
- No lado do runtime, `sceSifSendCmd` (guest, `sub_00548A00_0x548a00.cpp`) desce até
  `sceSifSetDma` (nativo, `SIF.cpp`), onde o DMA do pacote de comando é processado.
  O runtime já reconhecia `commandId==0x80000009` (bind) e `0x8000000A` (call) e
  fazia a completion síncrona (escreve `complete=1` em `auxAddr+0x24`, sinaliza
  `semaId` lido de `auxAddr+8`) — mas **nunca limpava o bit0 do slot**
  (`xfer.src+0x10`, o mesmo campo que `func_548E40` testa). `xfer.src` é literalmente
  o próprio slot (é o `pkt` passado como 2º arg de `sceSifSendCmd`, que vira o `src`
  do DMA).

## O que o runtime escrevia antes vs agora

- **Antes**: em `SIF.cpp`, dentro de `sceSifSetDma`, para `commandId==0x80000009` ou
  `0x8000000A` com `auxAddr!=0`: escrevia `complete=1` em `auxAddr+0x24`, sinalizava
  `semaId` (`auxAddr+8`). Nunca tocava `slot+0x10` (bit0 permanecia setado para
  sempre).
- **Agora** (`SIF.cpp`, bloco logo antes de `SignalSemaByIdForRuntimeCompat`): lê o
  word em `xfer.src+0x10`, limpa o bit0 (`&= ~1u`), regrava. Aplica-se
  incondicionalmente a todo bind/call completion, não só ao sid `0x8000059c` — é a
  liberação genérica do slot, espelhando o que `sceSifCmdIntrHdlr` faria em hardware
  real.

## Retry-loop saiu?

**Sim.** `docs/BOOT_PROBE_STATUS.md` (gerado por `21_probe_repeat.bat`, autoatualizado)
antes deste fix: `Stable PC 0x245720`, `Function sub_00245680_0x245680` (o próprio
laço travado). Depois do fix, mesma corrida (probe modo `595`, 3x): `Stable PC
0x5a8908`, `Function sub_005A8898_0x5a8898` — **PC diferente, função completamente
diferente**, mais adiante no boot. Confirmado reprodutível 3x (`21_probe_repeat.bat 3
595 bindfix`): `Stable PCs distintos: 1` (as 3 corridas convergem no mesmo novo PC,
não é ruído).

## Portões A/B/C ao vivo (`FUN_005422C8`)

Antes: 0 hits nos 3 (a função nunca era alcançada, per `RESULT_LOOP_245720_V2.md`).
Agora, na mesma corrida de 90s (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=100000`,
`work/logs/14_run_boot_trace.log`):

```
[MC3_BOOT_TRACE] gateA@0x54231c v0(func_5418D0 ret)=0 (0x0)
[MC3_BOOT_TRACE] gateB@0x54232c v0(func_541760(4) ret)=1 (0x1)
[MC3_BOOT_TRACE] gateC@0x542448 v0(sceCdRead sceSifCallRpc ret)=0 (0x0)
```

Os 3 portões passam: A não é `6` (não aborta), B retorna `1` (sucesso), C retorna
`>=0` (`bgezl` tomado) — `FUN_005422C8` chega ao fim normal e o laço externo em
`0x245720` finalmente sai.

## sceCdRead — disparou, bytes ainda não confiáveis

```
[boot-trace:mc3-cdvd-rpc] kind=read sid=0x80000595 fno=0x1 lsn=0x3c16aaaa
    sectors=0x3c1700ff buf=0x36f7ffff readOk=0 intr_data=0x5d9040 pc=0x546d60 ra=0x5489dc
```

`sceCdRead` (fno=1) disparou ao vivo pela primeira vez nesta sessão — o handler
já-implementado (`SIF.cpp:1110-1177`) rodou. Porém `lsn`/`sectors`/`buf` **não são
valores plausíveis de LBA/contagem/ponteiro** (parecem lixo/desalinhados) e
`readOk=0`. Isto é um problema **diferente e posterior** ao gate deste handoff (a
leitura do payload de envio da RPC, não a completion do bind) — não investigado
aqui, é o próximo gate na cadeia. Também apareceram, na mesma corrida, `kind=init`
(2x, sid `0x80000592`) e `kind=diskready` (1x, sid `0x80000595` fno `0xe`) — a
sequência completa de inicialização cdvd agora roda de ponta a ponta pela primeira
vez.

## Trajetória do gate

`0x245720` (laço de bind-retry, `sub_00245680`) → **rompido** → PC estabiliza em
`0x5a8908` dentro de `sub_005A8898_0x5a8898` (não investigado nesta sessão — é o
próximo gate).

## Régua de render (M0-M6)

Sem M4. `gsPixels=1` apareceu uma vez isolada no trace de 90s (não confirmada 3x,
provavelmente ruído/transiente) — anotado conforme a régua, não é um resultado
estável. As 3 corridas do `Probe-Repeat` (8s cada, modo `595`) mostram
`gsPrims=0 gsPixels=0 gifPk1=0` de forma consistente. `M4` não alcançado.

## Suíte

`ps2x_tests.exe` (272 testes) rodado após rebuild completo (ninja, target
`ps2x_tests`, que também recompilou `libps2_runtime.a` pegando a mudança em
`SIF.cpp`): **271 passed, 1 failed**. A falha (`VU0 macro mappings cover all
S1/S2 enums`) é em decodificação de VU0, suite `R5900Decoder`/VU — nenhuma relação
com SIF/RPC/bind; código tocado nesta sessão não encosta em VU0. Não investigada
(fora do escopo, provável pré-existente).

## Build

- `SIF.cpp` recompilado via `ninja ps2x_tests` (CMake/Ninja em
  `PS2Recomp/out/build`, MSYS2 `ucrt64` no PATH), que reconstruiu
  `libps2_runtime.a` e o exe de testes na mesma invocação — build limpo, sem
  warnings novos reportados.
- `mc3_partial.exe`: `libps2_runtime.a` atualizada manualmente (compilação direta +
  `ar r`) antes do ninja também confirmar o mesmo `.o`; `python tools/find_stale.py`
  → `Missing: 0, Stale (mtime): 0` (nenhum `.o` gerado do ELF ficou desatualizado,
  já que a mudança é só na lib do runtime, não em código gerado); relink via
  `10_link_partial_runner.bat fast`. Confirmado exe mais novo que a lib (timestamp).

## Corridas

- `14_run_boot_trace.bat 90` (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=100000`):
  log completo em `work/logs/14_run_boot_trace.log` (+ `.stdout`/`.stderr`).
- `21_probe_repeat.bat 3 595 bindfix`: 3 corridas, `Stable PCs distintos: 1`,
  relatório em `work/boot_probe/repeat_bindfix_20260819_055306.md`.

## Commits

- Submódulo `PS2Recomp` (branch `mc3`): `ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`
  (+29 linhas, liberação do slot do pool RPC) — pronto para commit local, sem push.
- Repo raiz (`mc3recomp`, branch `main`): ponteiro do submódulo atualizado,
  `docs/BOOT_PROBE_STATUS.md` (autoatualizado pelo probe) e este RESULT doc —
  prontos para commit local, sem push.

## Próximo passo recomendado

1. `sub_005A8898_0x5a8898` (novo Stable PC `0x5a8908`) é o próximo gate — anatomia
   ainda não feita, mesmo método (ler decomp, achar a condição, instrumentar 1
   ponto, tracear 1 corrida).
2. `sceCdRead` disparou mas com `lsn`/`sectors`/`buf` implausíveis — auditar de onde
   o handler lê o payload de envio (`kMc3CdvdNcmdSendDataAddr`) contra o que o
   decomp diz que o cliente realmente escreve antes da chamada; pode ser offset
   errado ou payload ainda não populado nesse ponto da sequência.
3. Falha isolada em `VU0 macro mappings cover all S1/S2 enums`: confirmar se é
   pré-existente (rodar suíte na revisão anterior do SIF.cpp) antes de assumir que
   é ruído — não feito nesta sessão por estar fora do escopo do handoff.
