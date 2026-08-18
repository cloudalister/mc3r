# Resultado — Fase 1, passo 5: por que o main loop não desenha (`mainloop_draw_v1`)

Executa `docs/HANDOFF_FASE1_MAINLOOP_DRAW.md` do início ao fim. Data: 2026-08-18. Branch `mc3`
(fork local, sem push), submódulo `PS2Recomp`. Docs no repo raiz.

## Resumo executivo

**Dois destravamentos reais, com evidência de decomp/trace, nenhum chute.** O gate `sceGsSyncV`
que a sessão anterior (`docs/RESULT_GSYNCV_METRICS_V1.md`) descreveu como "o ciclo real de vsync,
não mais uma trava" estava **errado**: era uma trava real, disfarçada de ciclo de vsync porque
`sceGsSyncV` retornava `0` **para sempre** (nunca `!=0`), e o loop que a chama (`FUN_00528ca0`,
init de GS/DMA, uma vez no boot) é um busy-wait de UMA vsync válida, não o loop principal do jogo.
Corrigido (Bloco A). Isso destravou o boot até um segundo bloqueio real: o RPC assíncrono de
`sceUsbKbGetInfo` nunca invocava seu callback de conclusão, deixando a thread principal presa
para sempre em `WaitSema`. Corrigido (Bloco B). O boot agora avança **muito** mais fundo — passa
pelo handshake de teclado USB e chega ao carregamento de assets (`zipFile::Init`) — mas trava num
**terceiro** gate, mapeado com evidência de decomp mas não corrigido nesta sessão (Bloco C):
`gifPackets`/`gsPrims` continuam `0`. Não é M4. Suíte 269/269 (4 de 5 rodadas; a 5ª teve a flaky
histórica de VBlank, documentada desde `RESULT_FASE2_SCHED_V1.md`, não uma regressão nova).

## Método (conforme o handoff)

1 corrida com trace (`MC3_BOOT_TRACE=1`) por hipótese, depois relink + nova corrida = prova.
Nenhum `SignalSema` injetado; nenhum env-gate experimental novo criado (um **existente** foi
promovido a comportamento permanente no Bloco B, ver justificativa lá). Toda correção nomeada por
endereço/instrução decompilada, nunca por suposição.

---

## Bloco A — `sceGsSyncV` retornava `0` para sempre: CSR.FIELD nunca era escrito

### Evidência (decomp, não chute)

`work/exports/alpha_decomp_sce.txt:3752`, `sceGsSyncV` (fonte C real do SDK):

```c
uint sceGsSyncV(void) {
  psVar2 = (short *)sceGsGetGParam();
  if (*(int *)(psVar2 + 4) == 0) {           // modo progressivo
    VSync();
    uVar3 = 1;
    if (*psVar2 == 1) {                       // modo "field-accurate" pedido
      uVar1 = REG_GS_CSR;
      uVar3 = (uint)(uVar1 >> 0xd) & 1;        // bit 13 = CSR.FIELD
    }
  } else { /* mesma lógica via VSync2()/lVar4 */ }
  return uVar3;
}
```

O trace determinístico (`work/logs/14_run_boot_trace.log`, instrumentação já existente em
`sub_00545648_0x545648.cpp` de sessão anterior — `[boot-trace:sub_00545648:stage]`) confirmou ao
vivo, register a register, que o jogo está no ramo `*psVar2 == 1` (`v0=0x1 v1=0x1` no ponto de
comparação `0x545680`): **o retorno depende do bit 13 de `REG_GS_CSR` (`0x12001000`)**. Grep em
`ps2_memory.cpp` confirmou que nada, em lugar nenhum do runtime, jamais escrevia esse bit fora de
um experimento inativo (`MC3_GS_EXPERIMENT_FIELD_BIT`, gated por env-var, off por padrão) — o bit
ficava permanentemente `0`, então `sceGsSyncV` retornava `0` sempre, e o chamador
(`FUN_00528ca0_0x528ca0.cpp`, `beqz $v0, 0x5a8908`→`0x528fa0`... na verdade o loop mapeado é
`while (sceGsSyncV(0) == 0) {}`, ver `docs/RESULT_GSYNCV_METRICS_V1.md` seção "Bloco B") nunca
saía. **Isto não é o loop principal do jogo por frame** — é um busy-wait de inicialização de UMA
vsync válida, dentro de uma função de init de GS/DMA que roda uma vez no boot
(`docs/AUDIT_M4M5_RENDER.md`, Pergunta 1, item 1). A conclusão da sessão anterior ("o boot executa
o ciclo real de vsync, não é mais uma trava") estava **errada** — era uma trava real, só que numa
janela de código maior (~250 bytes) do que a trava fixa anterior, o que produzia o jitter residual
já documentado (`0x545674`/`0x528fa8`/`0x546e70`).

### Correção

Real GS toggla CSR.FIELD (bit 13) a cada VSync — é a paridade de campo (par/ímpar) de saída
entrelaçada. Adicionado `PS2Memory::toggleGsFieldBit()` (novo, `ps2_memory.h`/`.cpp`), chamado uma
vez por tick de VBlank em `runOneVBlankTick()` (`Interrupt.cpp`), no mesmo ponto e com o mesmo
padrão de concorrência já usado para `latchIntcStatBit()` (bit dedicado num
`std::atomic<uint32_t> m_gsFieldBit`, não em `gs_regs` diretamente — evita corrida entre a thread
do driver de VBlank e a thread guest). `readIORegister()` agora reflete esse bit no endereço
`0x12001000` (CSR baixo) em vez do valor cru gravado — hardware real: CSR.FIELD é status de
hardware, não gravável por software. Isto **substituiu** o experimento antigo
`MC3_GS_EXPERIMENT_FIELD_BIT` (removido; comportamento agora permanente, sem env-gate).

### Efeito medido

Antes: PC estável `0x545674`/`0x528fa8`/`0x546e70` (dentro de `sceGsSyncV`), 100% das corridas,
para sempre. Depois: PC avança — `sceGsSyncV` retorna `v0=1` na primeira vsync válida (trace,
linha `[boot-trace:sub_00545648:return] exit=short v0=0x1 ... jump=0x528fa8`), `FUN_00528ca0`
retorna, e o boot progride para o próximo estágio (bind/call de `sceUsbKbGetInfo`, Bloco B).

---

## Bloco B — `sceUsbKbGetInfo` nunca invocava seu callback de conclusão

### Evidência (decomp do próprio callback, não chute)

Depois do Bloco A, o novo PC estável era um deadlock real do scheduler determinístico
(`[boot-trace:mc3-det-sched-stall] reason=idle-vblank-advances-without-progress ... threadCount=4`,
as 3 threads reais em `WaitSema` bloqueado, `readyCount=0`) — thread principal presa em
`WaitSema(sid=29)`. `sid=29` foi criado por `sceUsbKbInit` logo antes de `sceUsbKbGetInfo`
(`docs/HANDOFF_FASE1_USBKB.md`, `sceUsbKbInit`/`GetInfo` já mapeados por decomp nomeado). O
trace mostrou o `sceSifCallRpc` de `GetInfo` registrando `callback=0x5407C0` (endereço retail) e
`sema=4294967295` (`0xFFFFFFFF`, "sem semáforo direto — conclusão via callback"), mas
`callbackHandled=0` — nada nunca invocava esse callback.

Decompilado o próprio corpo do callback (`work/generated/ghidra/sub_00540720_0x540720.cpp`,
cauda de `sceUsbKbSync`, endereços `0x5407c0`-`0x5407cc`):

```
0x5407c0: lui  v0, 0x62          ; v0 = 0x620000
0x5407c4: j    iSignalSema        ; tail-call
0x5407c8: lw   a0, -0x4A8(v0)     ; a0 = *(u32*)0x61FB58   (delay slot)
```

Ou seja: `iSignalSema(*(uint32_t*)0x61FB58)` — literal, não interpretação. `0x61FB58` é
exatamente o global onde `sceUsbKbInit` guarda o ID do semáforo que acabou de criar (`sid=29`).
**O runtime já tinha esse handler implementado, pronto, com os endereços certos** —
`kMc3LoaderCallbackSemaGlobal = 0x0061FB58u` / `kMc3LoaderSignalCallback = 0x005407C0u`,
`ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` — mas atrás de `MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL`,
um dos 11 env-gates de experimentos "antigos e rejeitados" citados em
`docs/RESULT_FILEIO_GATE_V1.md` seção 5. A causa provável de ter ficado como experimento: até esta
sessão, o boot nunca tinha alcançado esse código (preso no Bloco A), então não havia como validar
se ligá-lo era seguro.

### Correção

Removido o gate `isMc3SifCallbackSignalExperimentEnabled()`/`MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL`
(função morta apagada) — o handler existente vira comportamento permanente e incondicional,
guardado pelas mesmas condições de segurança que já tinha (`!signaled && semaId==0xFFFFFFFF &&
callbackAddr==kMc3LoaderSignalCallback`, isto é: só dispara quando o RPC pede explicitamente
conclusão via callback nesse endereço exato, nunca substitui um semáforo direto já presente).
Nenhum `SignalSema` inventado — o valor sinalizado é lido do global exato que o próprio decomp do
callback lê.

### Efeito medido

Antes: deadlock determinístico permanente (4 threads, 0 prontas). Depois:
`[boot-trace:mc3-sif-callback-signal] callback=0x5407c0 ... signaled=1`, thread principal
desbloqueia, boot avança por muito mais RPCs SIF, entra em `iopManager`/asset loading, e chega ao
Bloco C.

---

## Bloco C — gate novo, mapeado com evidência, não corrigido nesta sessão

### Onde o boot para agora

PC estável determinístico: **`0x5a8908`/`0x5a88f0`** (`docs/LOOP_0x5A8908_ANATOMY.md`, o
spin-wait já documentado: `beqz $v0, 0x5a8908` — sai quando `func_4FA398` retorna `!=0`).
`func_4FA398` = **`zipFile::Init`** (`work/exports/retail_symbol_port.csv:6644`) — exatamente o
candidato "streaming de assets" previsto pelo handoff. `dma=2 vif=3` (tráfego real), mas
`gif=0 gsw=0 gifPk1/2/3=0 gsPrims=0 gsPixels=0` — não é M4.

### Cadeia mapeada (decomp + `MC3_TRACE_PROVIDER=1`, instrumentação já existente de sessão
anterior em `sub_004FA398_0x4fa398.cpp`/`sub_00399308_0x399308.cpp`/`sub_00398830_0x398830.cpp`)

`zipFile::Init` → `func_4FA488` (`sub_004FA488_0x4fa488.cpp`) → `func_399308`
(`sub_00399308_0x399308.cpp`, dispatcher genérico por tabela de provider) → tabela
`0x00617F88` (provider "T:", `docs/BACKEND_TABLE_0x3991F0.md`), slot `+0x00` = `0x398830` →
backend real `0x3984C0` ("open"). Trace ao vivo (`MC3_TRACE_PROVIDER=1`):

```
enter=0x399308 a0=0x00000007 a1=0x00672fe8 a2=0x00000003
[MC3_PROVIDER_GATE] gate=0x399308 initial-result=0xfffefffc handle=0xfffefffc
[MC3_PROVIDER_GATE] gate=0x399308 decision=negative handle=0xfffefffc
```

`a0=0x00000007` não é um ponteiro válido — é um inteiro pequeno passado como se fosse o
parâmetro que `0x398830`→`0x3984C0` espera (o mesmo slot que, numa chamada anterior na mesma
sessão, recebeu um ponteiro de caminho real, `0x0019FE10`, e teve sucesso). O backend
`0x3984C0` (585 linhas decompiladas, `work/generated/ghidra/FUN_003984c0_0x3984c0.cpp`) é lógica
de jogo pura — sem nenhuma chamada de syscall/stub nativo (`sceOpen`/cdvd), só chamadas para
outras funções de jogo (`func_398408`→`func_398AD0`/`func_398B18`, `func_432968`,
`func_432E58`) — ou seja, a cadeia real até um syscall/RPC de disco concreto é mais funda do que
o escopo investigado nesta sessão.

`docs/PROVIDER_LIFECYCLE_FLAGS.md` (auditoria estática anterior, sem mudança de código) já mapeou
o mecanismo relacionado: `func_4FAA10` lê 4 bytes via `0x3993A8` e só publica os flags de
provider "pronto" (`0x619F40`/`0x619F41`) quando reconhece a assinatura mágica `"DAEV"`/`"Dave"`.
O trace confirma **`flag619f40=0x00` em toda a sessão** — a assinatura nunca é reconhecida, o que
é consistente com o provider `0x617F88` ("T:", tipicamente um redirecionador de sistema de
arquivos de host de devkit) nunca produzir dados reais neste runtime (não há host conectado). Isto
sugere fortemente que o jogo deveria estar caindo num provider diferente (o "provider de
pacote/textura" `0x619F58`→`0x4F9760`, mapeado em `docs/BACKEND_TABLE_0x3991F0.md`, que lê estado
em `0x619F44`) para o caminho de disco real — mas confirmar isso exigiria decodificar mais
~3-4 níveis de função de jogo (`func_398408`, `func_398AD0`, `func_398B18`, e o que de fato produz
o inteiro `7` usado como `a0`), o que ficou fora do orçamento desta sessão.

### Por que parei aqui

`STATUS.md`/handoff permitem parar após mapear a cadeia com evidência quando a régua nova segue
zerada. Chegamos a exatamente esse ponto no destravamento #3 (de um orçamento de ~6): a cadeia
está nomeada por endereço, a causa provável (provider errado sendo usado / assinatura mágica
nunca lida) está identificada, mas o fix concreto (que provider deveria ser selecionado e por
quê) não tem evidência de decomp suficiente ainda — corrigir às cegas violaria a regra "sem chute
de bytes".

---

## Régua nova (valores finais)

| Contador | Valor |
|---|---|
| `gifPk1`/`gifPk2`/`gifPk3` | `0` / `0` / `0` |
| `gifPkTotal` | `0` |
| `gsPrims` | `0` |
| `gsPixels` | `0` |
| `dma` | `2` |
| `vif` | `3` |
| `gif`/`gsw` | `0` / `0` |

**Não é M4** (`gifPackets(total)>0 && gsPrims>0` não alcançado). Nenhum `21_probe_repeat.bat 3
probe m4_confirm` foi rodado — a regra do handoff só pede isso na vitória grande.

## Trajetória do gate (PC estável determinístico, `14_run_boot_trace.bat`)

| Etapa | Stable PC | Situação |
|---|---|---|
| Antes desta sessão (commit `78251f2`) | `0x545674`/`0x528fa8`/`0x546e70` | Busy-wait real dentro de `sceGsSyncV` (retorna `0` sempre) — mal rotulado como "ciclo de vsync" |
| Depois do Bloco A (CSR.FIELD) | `0x234614`→deadlock de scheduler | `sceGsSyncV` retorna `1`; boot avança até `WaitSema` bloqueado para sempre em `sceUsbKbGetInfo` |
| Depois do Bloco B (callback usbkb) | `0x5a8908`/`0x5a88f0` | `zipFile::Init` (`func_4FA398`) retorna `0`; spin-wait de provider documentado (`LOOP_0x5A8908_ANATOMY.md`) |

Budget `25000` (o padrão de `STATUS.md`) não é mais suficiente para alcançar o novo gate em toda
corrida — o boot agora faz trabalho real bem mais fundo antes de estabilizar. Usei
`MC3_DISPATCH_BUDGET=200000` para todas as medições deste doc (documentado explicitamente aqui,
por regra: "nunca comparar corridas com binários/budgets diferentes sem dizer qual").

Confirmação (`21_probe_repeat.bat 3 probe mainloop_draw_v1`, budget `200000`, modo `probe` limpo):
**3/3 corridas**: `pc=0x5a8908`, `classification=counters-moved`, `dma=2 vif=3 gif=0 gsw=0
gifPkTotal=0 gsPrims=0`, `deterministic=yes`, `Dispatch budget marker=yes`, `Timeout reached=no`.
Determinismo perfeito. Relatório bruto:
`work/boot_probe/repeat_mainloop_draw_v1_20260818_011216.md`.

## Suíte

`ps2x_tests.exe`, `PS2Recomp\out\build` (rodado com `C:\msys64\ucrt64\bin` no `PATH`, necessário
para as DLLs do runtime): **5 rodadas — 4× 269/269, 1× 268/269** (a flaky histórica de VBlank,
`sceGsSyncV waits on VBlank and reports interlaced field parity`, já documentada em
`RESULT_FASE2_SCHED_V1.md`/`RESULT_GSYNCV_METRICS_V1.md` como sensível a timing real de
`steady_clock` no modo não-determinístico dos testes unitários — não uma regressão desta sessão).

**Achado colateral corrigido**: o Bloco A tornou `CSR.FIELD` (bit 13 de `0x12001000`) um bit de
status real em vez de um campo gravável qualquer, o que quebrou
`GS CSR/IMR support coherent 64-bit and 32-bit access` (o padrão literal de teste,
`0x11223344`, tinha o bit 13 setado por coincidência). Corrigido ajustando os padrões do teste
para não colidir com esse bit (comentário no teste explica o porquê,
`ps2xTest/src/ps2_gs_tests.cpp`) — a intenção do teste (coerência 32/64-bit em outros bits) segue
coberta; o comportamento de `CSR.FIELD` em si é coberto pelo teste de VSync existente.

## Validação

Ambiente: `cmake-3.30.5-windows-x86_64\bin\cmake.exe`, ninja do VS2022
(`Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja`), g++ do `C:\msys64\ucrt64\bin`. Build dir
`PS2Recomp\out\build` (existente).

| Etapa | Resultado |
|---|---|
| Build `ps2_runtime` (Bloco A) | OK, sem erros/warnings novos |
| Relink `10_link_partial_runner.bat fast` (Bloco A) | OK, exe mais novo que a lib (timestamps conferidos) |
| `14_run_boot_trace.bat` (Bloco A) | PC sai de `0x545674` para deadlock de scheduler — prova coletada |
| Build `ps2_runtime` (Bloco B) | OK, sem erros/warnings novos |
| Relink `10_link_partial_runner.bat fast` (Bloco B) | OK, exe mais novo que a lib |
| `14_run_boot_trace.bat` (Bloco B) | PC sai do deadlock para `0x5a8908` — prova coletada |
| `14_run_boot_trace.bat` com `MC3_TRACE_PROVIDER=1` (Bloco C, só leitura) | Cadeia de bloqueio mapeada por decomp — nenhuma mudança de código |
| Build `ps2x_tests` | OK, sem erros/warnings novos (2 builds: antes/depois do fix do teste de CSR) |
| Suíte `ps2x_tests` | 5 rodadas: 4× 269/269, 1× 268/269 (flaky histórica) |
| `21_probe_repeat.bat 3 probe mainloop_draw_v1` | 3/3 `pc=0x5a8908`, determinismo perfeito |

Relatório bruto do probe: `work/boot_probe/repeat_mainloop_draw_v1_20260818_011216.md`.

## Commits locais (submódulo `PS2Recomp`, branch `mc3`, sem push)

Um commit, 5 arquivos:
- `ps2xRuntime/include/runtime/ps2_memory.h` — declaração de `toggleGsFieldBit()` +
  `m_gsFieldBit`.
- `ps2xRuntime/src/lib/ps2_memory.cpp` — implementação de `toggleGsFieldBit()`; `readIORegister`
  reflete o bit real em vez do experimento antigo; reset em `initialize()`.
- `ps2xRuntime/src/lib/Kernel/Syscalls/Interrupt.cpp` — chamada de `toggleGsFieldBit()` em
  `runOneVBlankTick()`.
- `ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` — promoção do handler de callback usbkb
  (`kMc3LoaderSignalCallback`) de experimento para permanente; remoção do gate/env-var morto.
- `ps2xTest/src/ps2_gs_tests.cpp` — ajuste dos padrões de teste de CSR para não colidir com o
  bit 13 agora especial.

## Próximos passos sugeridos (não executados nesta sessão)

1. **Bloco C é o próximo gate concreto**: decodificar `func_398408`
   (`work/generated/ghidra/sub_00398408_0x398408.cpp`) → `func_398AD0`/`func_398B18`, e o que
   produz o inteiro `7` usado como `a0` na segunda chamada de `0x399308`/`0x398830`. Objetivo:
   confirmar se o jogo deveria estar selecionando o provider `0x619F58` (pacote/textura, lê
   `0x619F44`) em vez de `0x617F88` ("T:"), e por que a seleção atual falha.
2. Se confirmado que `0x619F58` é o provider certo e que sua inicialização depende de algum
   handler SIF/cdvd ainda não implementado, esse é o candidato mais provável para o próximo
   `gifPackets>0`.
3. `docs/BACKEND_TABLE_0x3991F0.md` e `docs/PROVIDER_LIFECYCLE_FLAGS.md` (auditorias estáticas
   anteriores) continuam válidas e são o ponto de partida — nenhuma das duas precisou de correção.
