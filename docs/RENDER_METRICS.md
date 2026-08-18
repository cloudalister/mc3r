# RENDER_METRICS — a régua nova de render (Bloco A, `docs/HANDOFF_FASE1_GSYNCV_METRICS.md`)

Curto, de propósito. Contexto completo: `docs/AUDIT_M4M5_RENDER.md` (por que a régua antiga é
cega) e `docs/HANDOFF_FASE1_GSYNCV_METRICS.md` (o handoff que pediu isto).

## Por que uma régua nova

Os contadores antigos (`PS2Memory::dmaStartCount()/gifCopyCount()/gsWriteCount()/
vifWriteCount()`, `ps2_memory.h`/`.cpp`) só enxergam cópias no canal DMA 2 e escritas em
registradores privilegiados do GS (`PMODE`/`DISPFB`/...). Eles são **estruturalmente cegos** a
pacotes GIF reais (path1/2/3) e a primitivas de GS de verdade — a auditoria M4-M5 confirmou que
o caminho DMA→VIF1→VU1→GIF→GS já está ligado ponta a ponta no runtime, mas nenhum contador
existente prova isso.

## Os contadores novos

Sempre ativos, atômicos (`std::memory_order_relaxed`), sem env-gate, definidos em
`PS2Recomp/ps2xRuntime/include/runtime/ps2_render_metrics.h` /
`src/lib/ps2_render_metrics.cpp` (namespace `ps2_render_metrics`).

| Contador | O que mede exatamente | Onde é incrementado |
|---|---|---|
| `gifPk1`/`gifPk2`/`gifPk3` (`gifPacketsPath1/2/3()`) | Pacotes GIF **entregues de verdade** ao `GS::processGIFPacket`, por path (1/2/3). Não conta o que foi só enfileirado em `GifArbiter::submit()` — só o que saiu da fila em `drain()` e foi de fato despachado. | `GifArbiter::drain()`, `PS2Recomp/ps2xRuntime/src/lib/ps2_gif_arbiter.cpp` — um incremento por pacote não-vazio, logo antes de `m_processFn(...)`. |
| `gifPkTotal` | `gifPk1+gifPk2+gifPk3` (soma, calculada nos scripts/relatório, não é um atômico próprio). | — |
| `gsPrims` (`gsPrims()`) | Primitivas de GS que **de fato chegaram ao rasterizador** — um incremento por `POINT`/`LINE`/`LINESTRIP`/`TRIANGLE`/`TRISTRIP`/`TRIFAN`/`SPRITE` que atingiu o número de vértices necessário e foi passado para `GSRasterizer::drawPrimitive()`. Vértices enfileirados que nunca completam a primitiva (`m_vtxCount < needed`) não contam. | `GS::vertexKick()`, `PS2Recomp/ps2xRuntime/src/lib/ps2_gs_gpu.cpp`, logo após a chamada a `m_rasterizer.drawPrimitive(this)`. |
| `gsPixels` (`gsPixels()`) | Aproximação do número de pixels escritos: incrementado depois que scissor test, alpha test e o teste de limite de VRAM **já passaram** — ou seja, right before a escrita real em VRAM. Aproximado no sentido de que não é o critério de vitória oficial (esse é `gifPkTotal>0` + `gsPrims>0`); serve para dar volume/escala quando os outros dois já forem `>0`. | `GSRasterizer::writePixel()`, `PS2Recomp/ps2xRuntime/src/lib/ps2_gs_rasterizer.cpp`, imediatamente antes da escrita em `m_vram`. |

## Onde aparecem

- Linha `[boot-trace:frame]` (stderr, `MC3_BOOT_TRACE=1`), campos `gifPk1=`/`gifPk2=`/`gifPk3=`/
  `gsPrims=`/`gsPixels=` acrescentados ao final da linha existente (depois de `vif=`) —
  `ps2_runtime.cpp::LogBootTraceFrame`. Também no log `[run:tick]` (atrás de `AGRESSIVE_LOGS`,
  ver seção abaixo).
- Relatório do probe (`tools/Boot-Probe.ps1` → `latest_status.md`, campo "Render counters"; e
  `tools/Probe-Repeat.ps1` → relatório agregado, coluna "Counters").
- Critério de classificação `render-started` em `Get-Classification` (`Boot-Probe.ps1`) — ver
  próxima seção.

## Novo critério de vitória visual

`docs/HANDOFF_FASE1_GSYNCV_METRICS.md` Bloco A, item 4: a partir desta sessão, **vitória visual
= `gifPackets(total) > 0` E `gsPrims > 0`** (+ dump de framebuffer para conferência visual), não
mais `gif>0`/`gsw>0` isolados — porque esses dois são cegos ao caminho de GIF/GS real (ver acima).
`STATUS.md` (regra 5) foi atualizado para refletir isto. `gif=`/`gsw=`/`dma=`/`vif=` continuam
sendo logados (não foram removidos — ainda são úteis para depurar o transporte DMA/VIF), mas
deixaram de ser, sozinhos, evidência de render: `Boot-Probe.ps1` agora classifica um PC estável
com `gif>0`/`gsw>0` mas `gifPkTotal=0`/`gsPrims=0` como `counters-moved` (tráfego de transporte
sem prova de GIF/GS real), não mais `render-started`.

## `AGRESSIVE_LOGS` (bônus do Bloco A: `ps2_log.h` deixou de estar morto)

`PS2_IF_AGRESSIVE_LOGS(...)`/`PS_LOG_ENTRY` (`ps2xRuntime/include/ps2_log.h`) estavam atrás de
`#ifdef neverDone` — uma macro nunca definida em lugar nenhum do projeto, ou seja, código morto
permanente independentemente de qualquer env var. Trocado por `#if PS2_AGRESSIVE_LOGS_ENABLED`,
que é `1` quando a macro de compilação `AGRESSIVE_LOGS` está definida. Nova opção de CMake
(`PS2Recomp/ps2xRuntime/CMakeLists.txt`): `option(AGRESSIVE_LOGS ... OFF)` — **default OFF**,
build-time only (não é env-gate em runtime, não muda o binário padrão). Ligar com
`-DAGRESSIVE_LOGS=ON` na configuração do CMake.
