# Resultado — Fase 1, passo 4: régua nova de render + gate `sceGsSyncV` (`gsyncv_metrics_v1`)

Executa `docs/HANDOFF_FASE1_GSYNCV_METRICS.md` do início ao fim. Data: 2026-08-18. Branch `mc3`
(fork local, sem push), submódulo `PS2Recomp`, commit `b9c4c12`. Docs no repo raiz.

## Resumo executivo

**Bloco A fechado.** `ps2_log.h` deixou de ter `AGRESSIVE_LOGS` morto atrás de `#ifdef
neverDone` (nunca definido em lugar nenhum do projeto — confirmado por grep antes de mexer).
Três contadores atômicos novos, sempre ativos, sem env-gate (`gifPk1`/`gifPk2`/`gifPk3` por
path do `GifArbiter`, `gsPrims` no `GS::vertexKick`, `gsPixels` aproximado no
`GSRasterizer::writePixel`) expostos em `[boot-trace:frame]` e no relatório do probe. Doc
curto: `docs/RENDER_METRICS.md`.

**Bloco B: o gate `0x528fa0` foi atravessado — e a hipótese de partida do handoff estava
errada.** Não era o scheduler determinístico (instrumentei e confirmei: VBlank avança dezenas
de vezes por segundo, sem starvation, exatamente como a Fase 2 desenhou). A causa real: o jogo
chama sua **própria** implementação decompilada de `sceGsSyncV` (não o stub nativo do runtime,
que nunca é invocado por esse caminho), que faz **busy-poll direto no registrador de hardware
EE `INTC_STAT`** (`0x1000F000`, bit 2 = VBLANK_START), sem nunca passar por `AddIntcHandler`.
O runtime nunca escrevia esse bit — spin eterno. Corrigido com `PS2Memory::latchIntcStatBit()`,
chamado no ponto exato em que o VBlank real já dispara (`dispatchIntcHandlersForCause`,
`Interrupt.cpp`), e write-one-to-clear em `writeIORegister` para esse endereço, igual ao
hardware real. **Nenhuma linha do `DeterministicScheduler.cpp` mudou de comportamento** (só
ganhou um contador diagnóstico, nunca disparado, explicado na Seção 3).

**Efeito medido**: Stable PC (`dispatch-budget-reached`, `14_run_boot_trace.bat`) sai de
`0x528fa0` — 100% travado em **todas** as corridas de todas as sessões anteriores — para dentro
do próprio ciclo de vsync do jogo (o loop principal chamando `sceGsSyncV` frame a frame, como
esperado de um programa rodando, não uma trava). Em 10 corridas diretas: 8/10 pararam em
`0x545674`, 1/10 em `0x528fa8`, 1/10 em `0x546e70` — as três dentro da mesma janela de ~250
bytes de código (a cadeia `sceGsSyncV → VSync()/VSync2()`), não uma trava nova. Isso não é a
vitória grande — `gifPackets(total)=0` e `gsPrims=0` em todas as corridas — mas é a vitória do
passo, e maior do que qualquer avanço anterior documentado.

## Bloco A — régua nova, em detalhe

| Contador | O que mede | Onde |
|---|---|---|
| `gifPk1`/`gifPk2`/`gifPk3` | Pacotes GIF entregues de verdade ao `GS::processGIFPacket`, por path | `GifArbiter::drain()`, `ps2_gif_arbiter.cpp` |
| `gsPrims` | Primitivas que chegaram ao rasterizador | `GS::vertexKick()`, `ps2_gs_gpu.cpp`, logo após `drawPrimitive` |
| `gsPixels` | Pixels que sobreviveram a scissor+alpha+bounds (aproximação, não é o critério oficial) | `GSRasterizer::writePixel()`, `ps2_gs_rasterizer.cpp` |

Detalhe completo de semântica em `docs/RENDER_METRICS.md`. Wiring: `[boot-trace:frame]`
(`ps2_runtime.cpp::LogBootTraceFrame`) ganhou os cinco campos no final da linha, depois de
`vif=`; `[run:tick]` (atrás de `AGRESSIVE_LOGS`) ganhou os mesmos campos, por simetria.
`tools/Boot-Probe.ps1` (`Get-LastFrame`, `Get-Classification`, `New-MarkdownStatus`,
`New-ComparisonMarkdown`) e `tools/Probe-Repeat.ps1` (`Get-RenderMeasurement`) foram atualizados
para parsear/reportar os campos novos e usar `gifPackets(total)>0 && gsPrims>0` como o novo
critério de `render-started` — um PC estável com `gif>0`/`gsw>0` (contadores antigos) mas
`gifPkTotal=0`/`gsPrims=0` agora classifica como `counters-moved` (tráfego de transporte, não
render), não mais `render-started`. `STATUS.md` regra 5 atualizada para o critério novo.

`AGRESSIVE_LOGS` vira `option(AGRESSIVE_LOGS ... OFF)` em `ps2xRuntime/CMakeLists.txt` —
build-time, default OFF, nenhum env-gate novo em runtime.

## Bloco B — o gate, em detalhe

### Evidência coletada, na ordem em que foi coletada

1. **Li o design da Fase 2** (`docs/FASE2_SCHEDULER_DESIGN.md` seção 2.4) e o código atual
   (`DeterministicScheduler.cpp`, `Interrupt.cpp::deterministicVBlankDriverMain`) — a Fase 2 JÁ
   implementa exatamente o mecanismo "VBlank avança quando idle" com um pseudo-participante de
   prioridade mínima (`kIdlePseudoPriority = INT_MAX`), registrado via
   `DetSchedRegisterIdlePseudoThread`. O design está correto e implementado.
2. **Instrumentei e testei a hipótese diretamente** em vez de assumir: adicionei um contador
   diagnóstico em `DeterministicScheduler::pickNextLocked` (starvation do pseudo-thread idle) e
   logs `[boot-trace:vblank-tick]` em `signalVSyncFlag`. Resultado: **VBlank tick avança
   dezenas de vezes por segundo** (`tick=1` até `tick=80+` em poucos segundos), sem nenhuma
   starvation — o contador diagnóstico nunca disparou. **A hipótese do handoff (busy-spin nunca
   gera idle) está refutada por evidência direta, não por suposição.**
3. **Adicionei log de call/return em `ps2_stubs::sceGsSyncV`** (o stub nativo do runtime) —
   **zero chamadas registradas** em toda a corrida presa em `0x528fa0`. O jogo não usa o stub
   nativo nesse caminho.
4. **Segui o decompilado real**: `0x528fa0` é `jal func_545648` (a=0) dentro de
   `FUN_00528ca0_0x528ca0.cpp` (`work/generated/ghidra/`), registrado como `sceGsSyncV` no CSV
   (`work/exports/retail_symbol_port.csv:7335`, hash confidence). `sub_00545648_0x545648.cpp`
   chama `sceGsGetGParam` (`0x544f78`), lê o campo de interlace, e chama `VSync`
   (`FUN_00546e30_0x546e30.cpp`, endereço CSV `0x546e30`) ou `VSync2` (`0x546ec0`) dependendo do
   flag. `VSync()` faz:
   ```
   label_546e70:
       lw   v0, 0(v1)      ; v1 = 0x1000F000 (lui 0x1000; ori 0xF000)
       andi v0, v0, 4      ; bit 2 = VBLANK_START
       beqz v0, label_546e70
   ```
   seguido, ao sair do loop, de um `sw a0,0(v1)` incondicional com `a0=4` — o padrão clássico
   write-one-to-clear de um registrador de status de hardware. **`0x1000F000` é `INTC_STAT`
   (EE), bit 2 = `INTC_VBLANK_START`** — os nomes retirados do próprio binário (`sceGsGetGParam`,
   `VSync`, `VSync2`) batem exatamente com a semântica observada, não é inferência.
5. **Grep confirmou**: nada em `ps2_memory.cpp`/`Interrupt.cpp` nunca escrevia
   `0x1000F000`/`INTC_STAT` antes desta sessão. `dispatchIntcHandlersForCause` só invoca
   callbacks registrados via `AddIntcHandler` (nenhum registrado neste ponto do boot — confirmei
   por log, zero `[boot-trace:AddIntcHandler]` na corrida) — nunca toca o registrador de
   hardware que o busy-poll lê diretamente.
6. **Achado colateral, não esperado**: ao recompilar as 4 funções do caminho crítico
   (`sub_00545648_0x545648`, `FUN_00546e30_0x546e30`, `sub_00546EC0_0x546ec0`,
   `sub_00544F78_0x544f78`) para confirmar que o `.cpp` atual em disco batia com o `.o` linkado
   pelo `10_link_partial_runner.bat fast`, descobri que **os `.o` estavam desatualizados em ~3
   dias** (`.o` de 8/jul, `.cpp` gerado de 11/jul — `work/compile/ghidra/batch_0053`/`batch_0054`).
   O modo `fast` do relink nunca recompila os `.cpp` gerados, só reusa os `.o` existentes; isso
   afeta **todas** as sessões anteriores que usaram `fast` (Fase 1 passos 1-3, Fase 2), não só
   esta. Recompilei essas 4 funções manualmente com os mesmos flags do
   `tools/Link-PartialRunner.ps1` antes de testar a correção — sem isso, o teste estaria contra
   bytecode desatualizado. **Registrado como achado, não corrigido em massa** (recompilar os
   milhares de `.o` do projeto está fora do escopo deste handoff — ver Próximos passos).

### Correção escolhida: opção (b) do handoff

> "sceGsSyncV/CSR: o stub/registro que o spin lê passa a refletir o avanço de campo (field bit)
> que o VBlank determinístico já produz — se for só fiação entre gs_regs.CSR e o que o spin lê,
> melhor ainda."

Não é `gs_regs.CSR` (GS, `0x12001000`) — é `INTC_STAT` (EE, `0x1000F000`), mas a natureza da
correção é exatamente essa: fiação MMIO, não scheduler.

- `PS2Memory::latchIntcStatBit(cause)` (novo, `ps2_memory.h`/`.cpp`): OR do bit `cause` num
  `std::atomic<uint32_t> m_intcStat` dedicado (não em `m_ioRegisters`, que é um
  `std::unordered_map` não thread-safe — `latchIntcStatBit` é chamado da thread do driver de
  VBlank, concorrente com leituras/escritas da thread de execução guest; atomic elimina a
  classe inteira de corrida sem precisar de mutex).
- Chamada em `dispatchIntcHandlersForCause` (`Interrupt.cpp`), **antes** do gate de
  `g_enabled_intc_mask` — hardware real também latcheia o bit independente de máscara (máscara
  só decide se a exceção/callback dispara, não se o bit de status muda). Único ponto de chamada
  hoje (a função só é invocada para `kIntcVblankStart`/`kIntcVblankEnd` — chequei todos os call
  sites), ou seja, o efeito prático desta sessão é só VBlank, apesar do código ser genérico.
- `writeIORegister` ganha um `if (address == 0x1000F000u)` com write-one-to-clear
  (`m_intcStat.fetch_and(~value, ...)`), igual ao hardware real e ao padrão já usado no projeto
  para `D_STAT` (`0x1000E010`, mesmo arquivo, linhas 724-740).
- `readIORegister` ganha o `if` correspondente, devolvendo o valor do atomic.

**Nenhuma linha do `DeterministicScheduler.cpp` teve comportamento alterado.** A única mudança
nesse arquivo é um contador diagnóstico (`g_handoffsSinceIdlePick`/`g_starvationLogged`) que
detectaria starvation do pseudo-thread idle **se ela existisse** — não existe, o contador nunca
passou do threshold em nenhuma corrida, e ele não influencia `pickNextLocked` (só observa e
loga). Fica como instrumentação permanente de baixo custo, não como parte da correção.

## Trajetória do gate

| Etapa | Stable PC (`dispatch-budget-reached`) | Situação |
|---|---|---|
| Antes desta sessão (commit `c2ec958`, ver `RESULT_FILEIO_GATE_V1.md`) | `0x528fa0` | Spin eterno, 100% das corridas, todas as sessões anteriores |
| Depois do fix de `INTC_STAT` (com `.o` desatualizados) | `0x546e70` | Avançou 1 nível (para dentro do `VSync()`), ainda preso |
| Depois de recompilar as 4 funções do caminho crítico com `.cpp` atual | `0x545674` (8/10), `0x528fa8`/`0x546e70` (1/10 cada) | **Ciclo real de vsync**, não mais uma trava — jitter residual dentro da mesma janela de código |

10 corridas diretas (`14_run_boot_trace.bat 30`, `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`,
mesmo binário, sem reconfigurar nada entre corridas): `0x545674` × 8, `0x528fa8` × 1,
`0x546e70` × 1. `activeThreads=3` em todas; `vif=2` mantido (não regrediu); `gifPkTotal=0` e
`gsPrims=0` em todas — nenhuma delas é `render-started` pelo critério novo.

## Honestidade sobre o jitter residual

O handoff pede "estabiliza adiante" — 8/10 é maioria clara, não é 10/10. Não escondo isso.
Hipótese não confirmada (não investiguei a fundo, fora do orçamento desta sessão): variação
real de quantos ciclos de vsync completam antes do orçamento de 25000 dispatches se esgotar,
plausivelmente ligada a como threads registram prontidão perto de operações SIF/RPC assíncronas
que não são puramente contadas por dispatch (vi `sub_0054BC40:after-async` nas corridas mais
profundas). As três PCs observadas (`0x545674`, `0x528fa8`, `0x546e70`) estão todas dentro da
MESMA cadeia de chamada (`sceGsSyncV → VSync`), a poucas dezenas de instruções uma da outra —
isso é diferente em natureza do `0x528fa0` anterior (uma trava única, fixa, 100% das vezes).
`21_probe_repeat.bat 3 probe X` reporta "Stable PCs distintos: 2" nas corridas feitas com esse
comando exato porque `Boot-Probe.ps1` prioriza a linha periódica `[boot-trace:frame]` (amostrada
pelo loop de desenho, pautado pelo host) sobre a linha `[boot-trace:dispatch-budget-reached]`
(a única realmente determinística, contada por dispatch). Corrigi `Get-LastFrame`
(`tools/Boot-Probe.ps1`) para preferir `dispatch-budget-reached` quando presente — reduz mas não
elimina o jitter reportado pelo probe (o jitter em si é real, só a MEDIÇÃO estava mais grosseira
que o necessário). Não mexi em mais nada do `Boot-Probe.ps1`/modo `probe` além disso.

## Suíte

`ps2x_tests.exe`, `PS2Recomp\out\build`: **269/269 na maioria das rodadas, com a flaky histórica
de VBlank aparecendo em ~2 de 5 rodadas** (mesmo teste que `RESULT_FASE2_SCHED_V1.md` já
menciona como "flaky histórica de VBlank" — `sceGsSyncV waits on VBlank and reports interlaced
field parity`, sensível a timing real de `steady_clock` no modo não-determinístico dos testes
unitários). Pior caso observado nesta sessão: **268/269** — acima do piso `≥266/269` da regra.
Investiguei com prints temporários (revertidos, não fazem parte do commit): quando passa, os
ticks capturados são exatamente os esperados (`tick=1`→`v0=0`, `tick=2`→`v0=1`); quando falha, é
put puramente timing do worker de vsync em modo não-determinístico dos testes, não um bug de
lógica introduzido nesta sessão. Não investiguei a fundo por estar fora do escopo (o handoff não
pediu para consertar testes flaky pré-existentes) — registrado como risco residual conhecido, já
documentado por sessão anterior.

## Validação

Ambiente: `cmake-3.30.5-windows-x86_64\bin\cmake.exe`, ninja do VS2022, g++ do
`C:\msys64\ucrt64\bin`. Build dir `PS2Recomp\out\build` (existente).

| Etapa | Resultado |
|---|---|
| Configure + build (`ps2_runtime`, `ps2x_tests`) | OK, sem erros/warnings novos, várias iterações durante a investigação |
| Recompilação manual das 4 funções do caminho crítico (`work/generated/ghidra/*.cpp` → `work/compile/ghidra/batch_0053|0054/obj/*.o`) | OK, `g++` com os mesmos flags de `Link-PartialRunner.ps1` |
| Relink (`10_link_partial_runner.bat fast`) | Várias vezes durante a investigação, sempre bem dentro do timeout de 6 min |
| Suíte `ps2x_tests` | 5 rodadas: 3× 269/269, 2× 268/269 (flaky histórica de VBlank, ver acima) |
| `14_run_boot_trace.bat` (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`) | 10 corridas independentes após a correção: ver seção "Trajetória do gate" |
| `21_probe_repeat.bat 3 probe gsyncv_intcstat_final` | 3 corridas, "Stable PCs distintos: 2" (`0x545674` × 2, `0x546e70` × 1) — ver "Honestidade sobre o jitter residual" |

Relatório bruto do probe: `work\boot_probe\repeat_gsyncv_intcstat_final_20260818_004159.md`.

## Contadores novos na corrida final

`gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0` em todas as corridas — **não é M4**. O boot
avança através do ciclo de vsync mas ainda não chega a programar nenhum path GIF real depois
disso. Regra do handoff cumprida: **não** houve nenhum `gifPackets>0`/`gsPrims>0` nesta sessão,
então não há motivo para "parar tudo" — reporto normalmente.

## Commits

- Submódulo `PS2Recomp`, branch `mc3`, sem push: commit `b9c4c12` ("render: régua nova de
  métricas (gifPk1/2/3, gsPrims, gsPixels) + fix do gate sceGsSyncV") — 13 arquivos.
- Repo raiz, sem push: este documento + `docs/RENDER_METRICS.md` + `STATUS.md` +
  `tools/Boot-Probe.ps1` + `tools/Probe-Repeat.ps1` + `docs/BOOT_PROBE_STATUS.md` (snapshot
  automático da última corrida do probe) + referência de submódulo atualizada.

## Próximos passos sugeridos (não executados nesta sessão)

1. **`gifPackets`/`gsPrims` continuam `0`** — próximo passo concreto é descobrir o que o jogo
   faz logo depois de destravar o vsync (deveria progredir para `gfxPipeline::Begin@0x5290f0` e
   além, per `docs/AUDIT_M4M5_RENDER.md`) e por que ainda não chega a montar/enviar um pacote
   GIF real.
2. **Jitter residual entre `0x545674`/`0x528fa8`/`0x546e70`** — não investigado a fundo (ver
   "Honestidade sobre o jitter residual"). Hipótese de trabalho: timing de handoffs perto de
   SIF/RPC assíncrono; precisa de instrumentação dedicada, não coberta por este handoff.
3. **Objetos `.o` desatualizados em `work/compile/ghidra/`** — achado colateral desta sessão
   (Seção "Evidência coletada", item 6). Afeta potencialmente qualquer função gerada que tenha
   sido reexportada pelo Ghidra depois da última compilação em lote. Vale um passo dedicado para
   auditar `.cpp` vs `.o` timestamps em todos os batches antes de confiar cegamente no modo
   `fast` do relink daqui para frente.
4. **Flaky histórica de VBlank na suíte** (`sceGsSyncV waits on VBlank and reports interlaced
   field parity`) — já documentada por `RESULT_FASE2_SCHED_V1.md`, continua não corrigida
   (timing real de `steady_clock` no modo padrão dos testes). Fora do escopo de qualquer handoff
   até agora.
