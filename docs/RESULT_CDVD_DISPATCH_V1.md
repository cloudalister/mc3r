# Resultado — cdvd RPC dispatcher v1 (Fase 1, passo 1)

Data: 2026-08-17/18. Executor: Claude (Sonnet 5). Handoff: `docs/HANDOFF_FASE1_CDVD_MIN.md`.

## Resumo

Implementado `handleCdvdRpc()` em `SIF.cpp`, chaveado por `(server sid, fno)` — nunca por
`payloadAddr` — para o servidor cdvd (`0x80000592`). fno 0 (init) está **implementado e
confirmado ativo em 10/10 corridas do probe**, com um valor de resposta diferente (e mais
correto, por análise do decomp) do que o experimento antigo escrevia. fno 1 (read) está
**implementado mas nunca exercitado** nesta janela de boot — o cliente N-cmd do cdvd nunca
chega a chamar `sceCdRead` antes do budget de dispatch (25000) esgotar. A distribuição de PCs
mudou (nenhuma sobreposição com o baseline de 17/08), mas o boot continua sem `gif>0`/`gsw>0`
— resultado esperado e explicitamente não cobrado por este passo.

## Diff resumido

Arquivo: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` (branch `mc3`).
`git diff --stat`: **1 file changed, 192 insertions(+), 12 deletions(-)**.

- Novos: `kMc3CdvdInitSid` (`0x80000592`, confirmado no decomp: `sceSifBindRpc(0x6958e8,
  0x80000592, 0)` dentro de `sceCdInit`), `kMc3CdvdNcmdSid` (`0x80000596`, do próprio
  `docs/SIF_PROTOCOL.md`, não inventado — o bind do cliente N-cmd `0x5d9110` não está no
  export `sce*`), `kMc3CdvdNcmdSendDataAddr`/`kMc3CdvdRdIntrDataAddr`/`kMc3CdvdCbSemAddr`
  (`_sceCd_ncmdsdata`/`_sceCd_rd_intr_data`/`_sceCd_c_cb_sem`, endereços tirados do
  `MC.MAP` do build alpha, não do trace).
- Novo mapa `g_mc3RpcClientSid` (clientPtr → sid), populado no momento do `sceSifBindRpc`
  (cmd `0x80000009`, lendo o mesmo offset `+0x20` que os pacotes de call usam para o fno —
  confirmado em `sceSifBindRpc`/`sceSifCallRpc` decompilados, `@0x4fda48`/`@0x4fdc18`).
  Isso é o que permite chavear por servidor real em vez de endereço de payload fixo.
- Nova função `handleCdvdRpc(rdram, ctx, serverSid, fno, payloadAddr, payloadSize)`:
  - `(0x80000592, fno=0)`: escreve os 16 bytes de resposta de `sceCdInit` no `payloadAddr`
    real (o recv buffer que o chamador passou, dinâmico — não mais um endereço fixo). Byte
    `+0xC = 0xFF` (decomp: seleciona o ramo "sem dado extra" de `sceCdInit`, não é chute do
    campo verdadeiro). Bytes restantes = 0 + TODO documentado no código.
  - `(0x80000596, fno=1)`: escreve os 0x90 bytes de `_sceCd_rd_intr_data` (endereço fixo do
    SDK, não do chamador) como neutro/zero + TODO (layout de `_sceCd_cd_read_intr` não está
    no export decompilado), limpa `_sceCd_c_cb_sem` (a flag que `sceCdSync` faz polling —
    **não** é `SignalSema()`), e tenta a leitura real via `readCdSectors` (mesmo backend de
    `ps2_stubs::sceCdRead` em `CD.cpp`) usando lsn/sectors/buf lidos de `_sceCd_ncmdsdata`.
  - Chamada a partir do handler de `sceSifSetDma` (cmd `0x8000000A`), sem gate de env novo —
    é o caminho padrão, incondicional.
- Removido o braço antigo `requestId == 0x0 && payloadAddr == 0x00620D80 &&
  isMc3SifPayload592ExperimentEnabled()` (kind `"request-592-payload"`) de
  `completeMc3IopResponseForExperiment` — era exatamente o padrão de endereço fixo que
  `docs/ROOT_CAUSE_IOP_RESPONSE_LAYER_2026-08-13.md` aponta como não escalável, e escrevia
  `0xFE` no byte `+0xC` (seleciona o ramo *verbose*, não o ramo neutro). O resto da cadeia
  antiga (`0x1@0x7019c0`, `0xFF@0x701b40`, `0x0@0x621600`, `0xE@0x61fc00`, `0x4@0x620d80`)
  **não foi tocado**, por escopo.
- `resetSifState()` agora também limpa `g_mc3RpcClientSid`.

Nenhum `SignalSema()` foi chamado a partir de código novo. Nenhum env-gate novo foi criado.

## Build e suíte

- Build (`cmake-3.30.5-windows-x86_64\bin\cmake.exe --build PS2Recomp\out\build --target
  ps2_runtime ps2x_tests`, ninja do VS2022, g++ `C:\msys64\ucrt64\bin`): **OK**, apenas
  `SIF.cpp.obj` recompilado + `libps2_runtime.a` + `ps2x_tests.exe` relinkados.
- Suíte (`ps2xTest\ps2x_tests.exe`, executado de `PS2Recomp\out\build` com
  `C:\msys64\ucrt64\bin` no PATH — necessário para os DLLs de runtime): **268/269 passed**.
  Única falha: `sceGsSyncV waits on VBlank and reports interlaced field parity` — o flake de
  VBlank conhecido citado no handoff, não relacionado a SIF/CD. **Nenhuma falha nova.**

## Relink

`10_link_partial_runner.bat fast` via PowerShell (não via `cmd.exe /c` do bash — ver nota
abaixo). Timestamp do exe:

- Antes: `work\link\partial\mc3_partial.exe` — 2026-08-13 03:01 (463.854.922 bytes)
- **Depois: 2026-08-17 18:56 (515.726.555 bytes)**

Nota operacional: `cmd.exe /c "<bat> <args>"` chamado de dentro do bash (git-bash) neste
ambiente não repassa os argumentos corretamente e também falha a resolver o `.bat` relativo
por CWD; funcionou de forma confiável via a ferramenta PowerShell com `Set-Location` +
`& ".\10_link_partial_runner.bat" fast`.

## Probe: antes (baseline 17/08) vs depois (cdvd_dispatch_v1)

Ambos com `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`,
`21_probe_repeat.bat 10 595 <label>` (mode `595` = `pollsid59c595`, o mesmo preset de
env-gates antigos usado no baseline — necessário para comparação como-igual, já que o
dispatcher novo roda incondicionalmente por cima dele).

| | Baseline (`repeat_baseline_20260817_20260817_181511.md`) | cdvd_dispatch_v1 (`repeat_cdvd_dispatch_v1_20260817_185656.md`) |
|---|---|---|
| Stable PCs distintos | 9 | 5 |
| PCs observados | `0x238924, 0x234614, 0x2469b0, 0x548cc8, 0x54e13c, 0x5494e0, 0x1a0d08, 0x54dc88, 0x54bcb0` | `0x1a0e84, 0x54a188, 0x3985f4, 0x54a0ac, 0x238930` |
| Sobreposição com o outro conjunto | — | **0 PCs em comum** |
| Classificações | `counters-moved` (4x), `semaphore` (6x) | `semaphore` (8x), `counters-moved` (2x) |
| Render real (gif/gsw>0) | 0/10 | 0/10 (esperado, fora de escopo deste passo) |
| Falhas de evidência determinística (marker ausente/timeout) | 3/10 | 2/10 |

A distribuição de PCs mudou por completo (nenhum PC do depois aparece no antes), confirmando
que a resposta escrita por `handleCdvdRpc` (fno=0) tem efeito causal observável no caminho de
execução — consistente com o handoff ("mudança na distribuição de PCs" como sinal esperado de
sucesso parcial). `gif=0/gsw=0` em ambos os lados, como esperado e explicitamente não cobrado
por este passo.

## `mc3-iop-response-unhandled`: antes vs depois

Agregado das 10 corridas de cada lado (arquivos `boot_trace_pollsid59c595_*.log` em
`work\boot_probe`):

| request/payload/size | Baseline (10 runs) | cdvd_dispatch_v1 (10 runs) |
|---|---:|---:|
| `0x0 payload=0x701b40 size=0x8` (fileio, fora de escopo) | 27 | 28 |
| `0x1 payload=0x6fc780 size=0x80` (não-cdvd, server não identificado) | 24 | 26 |
| `0x9 payload=0x701b40 size=0x4` (fora de escopo) | 19 | 20 |
| `0xff payload=0x700dc0 size=0x8` (fora de escopo) | 17 | 18 |
| `0x1 payload=0x6f9000 size=0x90` (server `0x80000211`, não cdvd — ver nota abaixo) | 16 | 18 |
| `0x22 payload=0x620d80 size=0x4` (fora de escopo) | 10 | 10 |
| `0x0 payload=0x700dc0 size=0x4` (fora de escopo) | 7 | 8 |
| `0x0 payload=0x620d80 size=0x10` (**cdvd init**) | **0 (era "handled" pelo experimento antigo, com valor errado — ver abaixo)** | **10 (agora logado como "unhandled" só nesta função antiga; ver nota)** |
| **Total (função `completeMc3IopResponseForExperiment`)** | **120** | **138** |

**Nota importante sobre a linha `0x0/0x620d80/0x10`:** o aumento de 0→10 nessa linha
específica **não é uma regressão**. `completeMc3IopResponseForExperiment` é uma função
separada e mais antiga que não foi removida (só perdeu o braço específico que tratava esse
caso com endereço fixo). No baseline, esse braço antigo capturava a chamada e escrevia
`0xFE` no byte `+0xC` (seleciona o ramo *verbose* de `sceCdInit`, não o ramo neutro
`0xFF`) — confirmado nos logs baseline via
`[boot-trace:mc3-iop-response-experiment] kind=request-592-payload ... value=0xfe`, 1x por
corrida. No lado novo, esse braço foi removido, então essa função antiga agora loga
"unhandled" para o mesmo evento — **mas o evento já foi tratado corretamente antes, pelo
novo `handleCdvdRpc`**, confirmado por:

```
[boot-trace:mc3-cdvd-rpc] kind=init sid=0x80000592 fno=0x0 payload=0x620d80 size=0x10 pc=0x546d60 ra=0x5489dc
```

presente exatamente **10/10 vezes** (uma por corrida), sempre com o mesmo `sid`, `fno` e
`payload` — ou seja, o dispatcher novo acerta o servidor/fno certo de forma determinística.
O byte `+0xC` agora é `0xFF` (não `0xFE`), o que é a leitura correta do decomp (ramo
"sem dado extra"), não um chute.

Nenhuma redução de `mc3-iop-response-unhandled` para requests `0x1` foi observada — porque
nenhuma das ocorrências de `request=0x1` observadas nesta janela de boot pertence ao servidor
cdvd N-cmd (`0x80000596`). São de um servidor diferente e ainda não identificado
(`0x80000211`, citado como "a identificar" em `docs/SIF_PROTOCOL.md`), fora do escopo deste
handoff. `handleCdvdRpc`'s ramo `fno=1` nunca disparou (`0/10` corridas) — o boot não chega a
emitir a chamada `sceSifCallRpc` real de `sceCdRead` (cliente `0x5d9110`) dentro do budget de
dispatch antes de travar mais cedo, então o ramo de leitura fica não-exercitado nesta medição.

## Contagem de `mc3-cdvd-rpc` (novo)

| kind | Antes (linha não existia) | Depois (10 runs) |
|---|---:|---:|
| `init` (fno=0) | — | **10/10** |
| `read` (fno=1) | — | **0/10** |

## Avaliação frente ao critério de "pronto" da Fase 1

`docs/SIF_PROTOCOL.md` define pronto como `mc3-iop-response-unhandled = 0` e `sid=5`
sinalizado via `coreFileSignalSema`. **Não alcançado neste passo** — e não esperado, já que
esse critério cobre toda a Fase 1 (todos os servidores), enquanto este passo cobre só cdvd
init/read. Nem gif nem gsw avançaram, como o próprio handoff antecipa
("`gif>0`/`gsw>0` seria vitória, mas não é esperado neste passo").

## Bloqueios / limitações documentados

1. **fno=1 (read) não exercitado nesta medição.** O código está no lugar (server sid
   `0x80000596` do `docs/SIF_PROTOCOL.md`, escreve `_sceCd_rd_intr_data`, limpa
   `_sceCd_c_cb_sem`, tenta `readCdSectors`), mas não há evidência de execução real ainda —
   o boot trava antes de o cliente N-cmd fazer a chamada. Não foi possível validar o byte a
   byte do `_sceCd_rd_intr_data` real (o handler `_sceCd_cd_read_intr @0x4f6018` está fora do
   export `sce*` decompilado); todos os 0x90 bytes ficam neutros (zero) + TODO no código, por
   regra do handoff.
2. **`kMc3CdvdNcmdSid = 0x80000596` não tem uma chamada de bind confirmada no decomp
   exportado** (o bind do cliente `0x5d9110` não aparece em `alpha_decomp_sce.txt`). O valor
   vem de `docs/SIF_PROTOCOL.md`, que o classifica como "protocolo público (ps2sdk
   libcdvd)". Recomendação para o próximo passo: confirmar via captura PCSX2 ou via decomp
   adicional do módulo de inicialização do N-cmd, antes de expandir o dispatcher para mais
   fnos desse servidor.
3. A causa raiz do bloqueio de boot (`sid=5` nunca sinalizado, `docs/
   ROOT_CAUSE_IOP_RESPONSE_LAYER_2026-08-13.md`) **não foi resolvida** por este passo — ela é
   maior que cdvd init/read sozinhos (fileio, servidor `0x80000211`, etc. também descartam
   respostas). Isso é esperado; é trabalho de fases seguintes.

## Commit

Commit local no branch `mc3`, sem push (o coordenador revisa e sobe).
