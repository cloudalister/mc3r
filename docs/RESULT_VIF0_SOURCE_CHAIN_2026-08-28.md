# RESULT - VIF0 source-chain - 2026-08-28

## Resultado

**ACEITE SATISFEITO para o transporte source-chain do canal DMA 0.** O runner
real consumiu duas transferencias VIF0 com `CHCR=0x144`; ambas terminaram com
`completed=1`, um DMAtag e 1032 bytes efetivamente entregues ao FIFO VIF0.

O lote parou assim que os contadores de render voltaram a crescer, conforme o
contrato. O log foi preservado e o processo foi encerrado. Nao houve trace
`mc3-gfx-*`, portanto o crescimento e evidencia nova de atividade grafica, mas
ainda nao prova carregamento ou desenho de modelo 3D.

## Implementacao

Arquivos alterados no submodulo:

- `PS2Recomp/ps2xRuntime/src/lib/ps2_memory.cpp`
- `PS2Recomp/ps2xTest/src/ps2_memory_tests.cpp`

O caminho VIF0 source-chain agora:

1. le `TADR`, `ASR0`, `ASR1`, `ASP`, `TTE` e `TIE`;
2. interpreta os IDs REFE, CNT, NEXT, REF, REFS, CALL, RET e END;
3. com TTE, entrega os 8 bytes superiores de cada DMAtag antes do payload;
4. copia exatamente `QWC * 16` bytes de RDRAM/SPR para um buffer transacional;
5. publica o buffer no FIFO VIF0 somente quando encontra termino valido;
6. atualiza TADR/ASR/ASP, zera QWC, limpa STR e levanta `D_STAT.CIS0` apenas
   depois de consumir a chain completa;
7. preserva STR e nao publica dados se a chain nao termina em ate 4096 tags ou
   se uma leitura falha.

Interpretacao de VIFcode e execucao de VU0 continuam fora deste lote.

## Testes, build e relink

- build do target de testes: verde;
- suite completa: **300/300 verde**;
- novos testes:
  - caso observado `TADR=0x006CCCE0`, `CHCR=0x144`, CNT -> END com TTE;
  - REFE com payload externo e TADR preservado no tag terminal;
- build oficial do runtime: verde, sem trabalho pendente depois do target de
  testes;
- `10_link_partial_runner.bat fast`: verde;
- `mc3_partial.exe`: `2026-08-28 13:45:27`;
- `missing_functions.partial.cpp`: somente cabecalho, sem stub novo.

## Probe wall-clock headless

Duas corridas de margem curta ficaram registradas como pre-gate:

- 720 s: `work/logs/gfx_probe_20260828_vif0_chain.log.stderr`, tick final 32760;
- 780 s: `work/logs/gfx_probe_20260828_vif0_chain_confirm.log.stderr`, tick
  final 33960.

Nenhuma das duas atingiu o DMA VIF0 por variacao de agendamento. A corrida
final usou margem de 900 s:

```bat
work\scratch\run_gfx_probe.bat 900 20260828_vif0_chain_final headless
```

Ela foi interrompida manualmente no primeiro crescimento sustentado de render,
com o stderr preservado em:

`work/logs/gfx_probe_20260828_vif0_chain_final.log.stderr`

Transferencias reais capturadas:

```text
[boot-trace:dmac-vif0-chain] tadr=0x006ccce0 nextTadr=0x006ccce0 tags=1 bytes=1032 chcr=0x00000144 completed=1 qw0=000000000040406c0800000000000000 qw1=00000000000000000800000000000000
[boot-trace:dmac-vif0-chain] tadr=0x006ccd00 nextTadr=0x006ccd00 tags=1 bytes=1032 chcr=0x00000144 completed=1 qw0=000000004040406c4bb01bc600000000 qw1=00000000402e01cbf30e10c400000000
```

Comparacao contra o plateau anterior:

| Contador | Antes | Depois | Delta |
|---|---:|---:|---:|
| `gifPk1` | 348558 | 348560 | +2 |
| `gifPk2` | 136612 | 136981 | +369 |
| `gifPk3` | 0 | 0 | 0 |
| `gsPrims` | 703599 | 703668 | +69 |
| `gsPixels` | 256036663 | 257216311 | +1179648 |
| `dma` | 29420 | 29435 | +15 |

Depois do crescimento, os contadores permaneceram nesse novo plateau ate a
parada. O PC amostrado ficou em `0x41D188`, nao no antigo gate VIF0. O runner
foi encerrado e nao permaneceu processo `mc3_partial.exe` ativo.

## Limites e sinais preservados

- `mc3-gfx-*`: zero;
- `first-bad-pc`: uma ocorrencia em `0x5CCE60`, regiao Ghidra ja excluida;
- warnings de funcoes ausentes em regioes excluidas, incluindo `0x5BF1F0`,
  `0x587E50` e `0x5C5718`; nenhuma foi alterada;
- sem SignalSema injetado, sem env-gate novo, sem mudanca de scheduler,
  dispatcher ou SIF, sem janela visivel e sem push.

## Proxima fronteira

O transporte DMA VIF0 normal e source-chain esta atravessado. A proxima etapa
causal dentro do canal e interpretar os VIFcodes entregues e conectar MPG/
UNPACK ao VU0. O crescimento de render deve ser preservado como evidencia
separada; ele ainda nao autoriza afirmar que um modelo foi carregado.

