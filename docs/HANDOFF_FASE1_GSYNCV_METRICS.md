# Handoff — passo 4: régua nova de render + gate `sceGsSyncV` (0x528fa0)

## Contexto mínimo

O passo 3 (`docs/RESULT_FILEIO_GATE_V1.md`) atravessou o provider e o boot agora para em
`0x528fa0` — spin em `sceGsSyncV` no init do `gfxPipeline`, com `vif=2` (primeiro tráfego VIF
do projeto). A auditoria GIF/GS descobriu que os contadores `gif`/`gsw` são estruturalmente
cegos (só PATH3/porta privilegiada) e que TODA a instrumentação `AGRESSIVE_LOGS` está morta
por um `#ifdef neverDone` (`ps2xRuntime/include/ps2_log.h:20`). Antes de atravessar o vsync,
precisamos enxergar o que flui.

## Bloco A — régua nova (fazer primeiro)

1. Corrigir `ps2_log.h`: `PS2_IF_AGRESSIVE_LOGS` compilável de verdade atrás de uma macro de
   build normal (ex.: `AGRESSIVE_LOGS` via CMake option, default OFF) — sem `neverDone`.
2. Contadores novos, atômicos, sempre ativos (baratos), expostos ao boot-trace/probe:
   - `gifPackets[path1/2/3]` incrementado em `GifArbiter::drain()` por path;
   - `gsPrims` incrementado em `GS::vertexKick` (ou equivalente em `drawPrimitive`);
   - `gsPixels` (writePixel) pode ser amostrado/aproximado se custo preocupar.
3. Logar os novos contadores na linha `[boot-trace:frame]` (junto de dma/gif/gsw/vif) e no
   relatório do probe. Atualizar `tools\Probe-Repeat.ps1`/classificador se ele parseia a linha.
4. **Critério de vitória visual passa a ser: `gifPackets(total)>0` e `gsPrims>0`** + dump.
   Atualizar a linha correspondente no `STATUS.md` ao final.

## Bloco B — o gate `sceGsSyncV`

Evidência a coletar primeiro (1 corrida com trace):
- `sceGsSyncV` decompilado (alpha) espera o quê exatamente? (bit de CSR? callback de vsync?
  semáforo de VSync via `AddIntcHandler`/`EnableIntc`?) Ver decomp + `Kernel/Stubs/GS.cpp`
  (`sceGsSyncV` já tem stub? o que ele faz?) e `Kernel/Syscalls/Interrupt.cpp`.
- No modo determinístico (Fase 2), o VBlank avança "por idle" (`docs/FASE2_SCHEDULER_DESIGN.md`).
  Hipótese principal: o spin de `sceGsSyncV` é busy-wait que nunca gera idle → VBlank nunca
  avança → spin eterno. Confirmar no design doc + trace (o watchdog de handoffs registra algo?).

Correção esperada (escolher com base na evidência, documentar a escolha):
- (a) o scheduler determinístico também avança VBlank após N dispatches de busy-spin na mesma
  região (contagem determinística, sem relógio) — mudança pequena e determinística no
  `DeterministicScheduler.cpp`; ou
- (b) `sceGsSyncV`/CSR: o stub/registro que o spin lê passa a refletir o avanço de campo
  (field bit) que o VBlank determinístico já produz — se for só fiação entre `gs_regs.CSR` e o
  que o spin lê, melhor ainda.
- NÃO usar tempo de host em nenhuma das opções. Scheduler continua determinístico: mesma
  corrida = mesmo resultado, 3x `21_probe_repeat.bat 3 probe sync_v1` para confirmar.

## Aceite

- Bloco A: contadores novos aparecem no boot-trace e no probe; suíte ≥266/269; doc curto do
  que cada contador mede em `docs/SIF_PROTOCOL.md` ou novo `docs/RENDER_METRICS.md`.
- Bloco B: Stable PC determinístico sai de `0x528fa0` e estabiliza adiante. Se os contadores
  novos do Bloco A registrarem `gifPackets>0` ou `gsPrims>0` — **PARAR TUDO**, anotar commit/
  env/comando e reportar imediatamente (é o momento M4 do projeto).

## Regras

As de sempre (`STATUS.md`): sem env-gate novo (a CMake option de logs é build-time, ok), sem
SignalSema injetado, sem tempo de host no caminho determinístico, medição no modo `probe`
limpo (595 aposentado), commits locais no fork `mc3` sem push, resultado honesto em
`docs/RESULT_GSYNCV_METRICS_V1.md`. Ambiente de build no `STATUS.md`. Relink timeout ≥6 min.
Poll ativo em toda espera longa.
