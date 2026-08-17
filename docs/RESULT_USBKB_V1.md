# Resultado — usbkb RPC dispatcher v1 (Fase 1, passo 2)

Data: 2026-08-17. Executor: Claude (Sonnet 5). Handoff: `docs/HANDOFF_FASE1_USBKB.md`.

## Resumo

Implementado `handleUsbKbRpc()` em `SIF.cpp`, chaveado por `(server sid, fno)` — nunca por
`payloadAddr` — para o servidor `0x80000211` (`sceUsbKb*`, `USBKB.IRX`). Apenas o fno
realmente exercitado no boot (`fno=1`, `sceUsbKbGetInfo`) foi confirmado ativo: **20/20
ocorrências** (2x por corrida, 10 corridas) atendidas com a resposta neutra "0 teclados"
(buffer de 0x90 bytes zerado), que é exatamente a semântica-alvo "nenhum teclado conectado" —
o próprio `sceUsbKbInit` decompilado falha de forma limpa quando a contagem lida é 0. `fno=2`
(`sceUsbKbRead`) foi implementado defensivamente (mesma política de zero neutro) mas nunca
disparou nesta janela de boot, como esperado (é guardado por `contagem > 0`, que agora é
sempre 0). A distribuição de PCs mudou (9 PCs estáveis, 1 em comum com `cdvd_dispatch_v1`), e
o boot continua sem `gif>0`/`gsw>0` — esperado e fora de escopo deste passo.

## Tabela de fnos extraída (`work/exports/alpha_decomp_sce.txt`)

| Função | Endereço | fno | send (addr/size) | recv (addr/size) | Campo lido pelo cliente após retorno |
|---|---|---:|---|---|---|
| `sceUsbKbInit` | `0x4f4f58` | — (local) | — | — | Chama `GetInfo` + `Sync(0,...)`; checa `count==0 && 0<n<0x80` antes de aceitar o teclado |
| `sceUsbKbGetInfo` | `0x4f5150` | `1` | `0x693a00`/`0x10` | `0x693a40`/`0x90` | Campo "número de teclados" (offset exato dentro do buffer de 0x90B não decompilado — copiado por um callback fora do export `sce*`, `@0x4f53e8`) |
| `sceUsbKbRead` | `0x4f51f8` | `2` | `0x693a00`/`0x10` | `0x693a40`/`0x50` | Guardado por `param_1 < DAT_00693900` (contagem de `GetInfo`); com contagem 0 nunca é chamado por um cliente correto |
| `sceUsbKbSetArrangement` | `0x4f52f8` | — (local) | — | — | Não é RPC — grava direto na struct local `DAT_00693904` |
| `sceUsbKbSync` | `0x4f5348` | — (local) | — | — | Não é RPC — `WaitSema`/`SignalSema` locais + `FUN_004f53f8()` (fora do export) |
| `sceUsbKbCnvRawCode` | `0x4f5da0` | — (local) | — | — | Não é RPC — tabela de keycodes local |

Confirmação no bind: `sceSifBindRpc(0x6939a0, 0xffffffff80000211, 0)` dentro de
`sceUsbKbInit` (decomp, endereço SDK alpha `0x6939a0`). No trace real (endereço de runtime
diferente do SDK, mesmo padrão já visto no passo 1 para cdvd):

```
[boot-trace:sif-command-compat] cmd=0x80000009 request=0x80000211 aux=0x6f8f60 ...
[boot-trace:sceSifSetDma] ... words=...,0x8000000a,...,0x6f8f60,0x1,0x10,0x6f9000,0x90,0x1,0x1,...
[boot-trace:sif-command-compat] cmd=0x8000000a request=0x1 aux=0x6f8f60 callback=0x5407c0 ...
```

`fno=1`, `send size=0x10`, `recv addr=0x6f9000`, `recv size=0x90` batem exatamente com o
`sceSifCallRpc(0x6939a0,1,1,0x693a00,0x10,0x693a40,0x90,0x4f53e8)` do decomp — confirmação
cruzada decomp + trace, sem chute.

## Diff resumido

Arquivo: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` (branch `mc3`).
`git diff --stat`: **1 file changed, 116 insertions(+), 1 deletion(-)**.

- Novos: `kMc3UsbKbSid` (`0x80000211`, confirmado no decomp e no trace), `kMc3UsbKbGetInfoFno`
  (`1`) + `kMc3UsbKbGetInfoRecvSize` (`0x90`), `kMc3UsbKbReadFno` (`2`) +
  `kMc3UsbKbReadRecvSize` (`0x50`) — todos extraídos de `sceUsbKbGetInfo`/`sceUsbKbRead`
  decompilados, não inventados.
- Nova função `handleUsbKbRpc(rdram, ctx, serverSid, fno, payloadAddr, payloadSize)`:
  - `(0x80000211, fno=1)`: zera os `0x90` bytes do `payloadAddr` real (destino dinâmico
    passado pelo chamador via DMA, nunca um endereço fixo). O offset exato do campo "contagem
    de teclados" dentro desse buffer não está no export decompilado (o callback de conclusão
    `@0x4f53e8` está fora do conjunto `sce*`), então **todo o buffer fica neutro/zero** — o que
    não é um chute de campo específico, e tem o efeito correto: qualquer offset que o cliente
    leia como contagem lê 0, que é exatamente "nenhum teclado conectado".
  - `(0x80000211, fno=2)`: mesma política (zera os `0x50` bytes do `payloadAddr` real),
    implementado defensivamente já que este fno é normalmente inalcançável com contagem 0.
  - Ambos logam `[boot-trace:mc3-usbkb-rpc]` quando `MC3_BOOT_TRACE` está ativo.
- Site de chamada: no handler de `sceSifSetDma` (cmd `0x8000000A`), chamado logo depois de
  `handleCdvdRpc`, só se este retornar `false` (sids são mutuamente exclusivos, mas evita
  trabalho redundante). Sem gate de env novo — é o caminho padrão, incondicional, igual ao
  passo 1.
- Nenhum braço da cadeia legada (`completeMc3IopResponseForExperiment`) foi removido: não
  havia nenhum braço ali para `request=0x1`/`payload=0x6f9000` — o servidor usbkb nunca teve
  tratamento especial nessa função antiga, então não há nada a substituir/remover por regra do
  handoff ("remover da cadeia legada apenas os braços que este handler substitui").
- `resetSifState()` não precisou de mudança: não há estado global novo específico do usbkb
  (o mapa `g_mc3RpcClientSid` já reseta o bind de qualquer servidor, reaproveitado do passo 1).

Nenhum `SignalSema()` foi chamado a partir de código novo. Nenhum env-gate novo foi criado.

## Build e suíte

- Build (`cmake-3.30.5-windows-x86_64\bin\cmake.exe --build PS2Recomp\out\build --target
  ps2_runtime ps2x_tests`, ninja do VS2022, g++ `C:\msys64\ucrt64\bin`): **OK**, apenas
  `SIF.cpp.obj` recompilado + `libps2_runtime.a` + `ps2x_tests.exe` relinkados.
- Suíte (`ps2xTest\ps2x_tests.exe`, executado de `PS2Recomp\out\build` com
  `C:\msys64\ucrt64\bin` no PATH): **269/269 passed** (o flake de `VBlank` conhecido não
  ocorreu nesta execução). **Nenhuma falha, nenhuma falha nova em SIF.**

## Relink

`10_link_partial_runner.bat fast` via PowerShell. Timestamp do exe:

- Antes (passo 1, `cdvd_dispatch_v1`): `work\link\partial\mc3_partial.exe` — 2026-08-17
  18:56:46 (515.726.555 bytes)
- **Depois (`usbkb_v1`): 2026-08-17 20:20:09 (515.728.537 bytes)**

## Probe: `usbkb_v1` (10 corridas, `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`, modo `595`)

Relatório: `work\boot_probe\repeat_usbkb_v1_20260817_202024.md`.

| | `cdvd_dispatch_v1` (`repeat_cdvd_dispatch_v1_20260817_185656.md`) | `usbkb_v1` (`repeat_usbkb_v1_20260817_202024.md`) |
|---|---|---|
| Stable PCs distintos | 5 | **9** |
| PCs observados | `0x1a0e84, 0x54a188, 0x3985f4, 0x54a0ac, 0x238930` | `0x54a0ac, 0x5494e0, 0x540354, 0x3985d8, 0x223480, 0x5403a4, 0x398390, 0x54bbc4, 0x234614` |
| Sobreposição com o outro conjunto | — | **1 PC em comum (`0x54a0ac`)** |
| Classificações | `semaphore` (8x), `counters-moved` (2x) | `semaphore` (5x), `counters-moved` (5x) |
| Render real (gif/gsw>0) | 0/10 | 0/10 (esperado, fora de escopo) |
| Falhas de evidência determinística | 2/10 | **0/10** |

A distribuição de PCs mudou (8 dos 9 PCs não aparecem no lado `cdvd_dispatch_v1`), consistente
com o handoff ("mudança na distribuição de PCs" como sinal esperado de efeito causal). Todas
as 10 corridas produziram evidência determinística completa desta vez (0 falhas de marker,
melhor que os 2/10 do lado anterior). `gif=0/gsw=0` em ambos, como esperado.

## `mc3-iop-response-unhandled`: antes (`cdvd_dispatch_v1`) vs depois (`usbkb_v1`)

Agregado das 10 corridas de cada lado (arquivos `boot_trace_pollsid59c595_*.log` em
`work\boot_probe`):

| request/payload/size | `cdvd_dispatch_v1` (10 runs) | `usbkb_v1` (10 runs) |
|---|---:|---:|
| `0x0 payload=0x701b40 size=0x8` (fileio, fora de escopo) | 28 | 30 |
| `0x1 payload=0x6fc780 size=0x80` (não-usbkb, server não identificado) | 26 | 30 |
| `0x9 payload=0x701b40 size=0x4` (fora de escopo) | 20 | 20 |
| `0xff payload=0x700dc0 size=0x8` (fora de escopo) | 18 | 20 |
| `0x1 payload=0x6f9000 size=0x90` (**usbkb GetInfo, este passo**) | 18 | **20** |
| `0x22 payload=0x620d80 size=0x4` (fora de escopo) | 10 | 10 |
| `0x0 payload=0x700dc0 size=0x4` (fora de escopo) | 8 | 10 |
| `0x0 payload=0x620d80 size=0x10` (cdvd init, passo 1, sem mudança neste passo) | 10 | 10 |
| **Total** | **138** | **150** |

**A linha `0x1/0x6f9000/0x90` NÃO zerou — e, pela mesma razão documentada no passo 1 para a
linha do cdvd init, isso não é uma regressão nem um resultado negativo.**
`completeMc3IopResponseForExperiment` é a função antiga/genérica que só sabe tratar um
conjunto fixo de `(request, payload)` — nunca teve um braço para `0x1/0x6f9000`, então ela
sempre logou (e continua logando) esse evento como "unhandled", independente de o novo
`handleUsbKbRpc` (chamado de um ponto diferente, no handler de `sceSifSetDma`) já ter
respondido corretamente. Isso é confirmado pela contagem de `mc3-usbkb-rpc`, que bate 1:1 com
a contagem de "unhandled" dessa linha:

```
[boot-trace:mc3-usbkb-rpc] kind=get-info sid=0x80000211 fno=0x1 payload=0x6f9000 size=0x90
```

presente **20/20 vezes** — exatamente o mesmo total da linha `0x1/0x6f9000/0x90` acima. Ou
seja, **100% das chamadas de `sceUsbKbGetInfo` observadas foram atendidas pelo dispatcher
novo**, sempre com o mesmo `sid`/`fno`/`payload`, de forma determinística. A métrica "zerar o
`mc3-iop-response-unhandled` do usbkb" **não é estruturalmente alcançável só com este passo**,
porque essa função antiga não tem (e este handoff não pede para criar) um braço específico
para suprimir esse log — o mesmo padrão já observado e documentado no passo 1 para
`0x0/0x620d80/0x10`.

## Contagem de `mc3-usbkb-rpc` (novo)

| kind | Antes (linha não existia) | Depois (10 runs) |
|---|---:|---:|
| `get-info` (fno=1) | — | **20/20** (2 por corrida × 10 corridas) |
| `read` (fno=2) | — | **0/10** (nunca disparou; esperado, guardado por contagem>0) |

## Avaliação frente ao critério de "pronto" da Fase 1

`docs/SIF_PROTOCOL.md` define pronto como `mc3-iop-response-unhandled = 0` (todos os
servidores) e `sid=5` sinalizado via `coreFileSignalSema`. **Não alcançado neste passo** — e
não esperado, já que este passo cobre só usbkb GetInfo/Read, e mesmo dentro do usbkb a métrica
bruta de "unhandled" não zera pela razão estrutural explicada acima (função antiga não
suprimida). O critério real de sucesso deste passo — "handler roda para 100% das chamadas
reais de `sceUsbKbGetInfo` no boot, com semântica 'sem teclado' correta" — **foi alcançado**
(20/20, ver seção anterior). Nem `gif` nem `gsw` avançaram, como o handoff já antecipa.

## Bloqueios / limitações documentados

1. **Layout exato do buffer de 0x90B de `GetInfo` não confirmado campo a campo.** O callback
   de conclusão da RPC (`@0x4f53e8` no decomp alpha) que copiaria esse buffer para a struct
   local de `sceUsbKbInit` está fora do export `sce*` decompilado. A resposta atual (buffer
   inteiro zerado) é a escolha neutra que garante a semântica "0 teclados" independente de
   onde exatamente esse campo mora — não chuta o offset, mas também não o confirma.
2. **`fno=2` (`sceUsbKbRead`) nunca exercitado.** Esperado: com `GetInfo` sempre reportando 0
   teclados, nenhum cliente correto chama `Read` (guardado por `índice < contagem`). O código
   está no lugar (mesma política neutro/zero) mas sem evidência de execução real.
3. **`mc3-iop-response-unhandled` para `request=0x1/payload=0x6f9000/size=0x90` não zera.**
   Estrutural, não um bug: a função antiga (`completeMc3IopResponseForExperiment`) nunca teve
   um braço para esse `(request, payload)`, então não há nada para "este handler substituir"
   ali, por regra do handoff. A evidência real de sucesso é a contagem `mc3-usbkb-rpc`
   (20/20), não essa métrica legada.
4. A causa raiz do bloqueio de boot (`sid=5` nunca sinalizado,
   `docs/ROOT_CAUSE_IOP_RESPONSE_LAYER_2026-08-13.md`) **não foi resolvida** por este passo —
   esperado, é trabalho de fases seguintes (outros servidores/fileio ainda descartam
   respostas: `request=0x1 payload=0x6fc780 size=0x80`, `0x0/0x701b40/0x8`, `0x9/0x701b40/0x4`,
   `0xff/0x700dc0/0x8`, `0x0/0x700dc0/0x4` seguem "unhandled", fora de escopo deste passo).

## Commit

Commit local no branch `mc3`, sem push (o coordenador revisa e sobe).
