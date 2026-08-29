# Resultado: corredor PADMAN ate scePadRead

Data: 2026-08-26

## Resultado

O runner parcial agora percorre naturalmente:

```text
PADMAN bind/init/open
  -> ioPad::Attach
  -> ioPad::Poll
  -> scePadRead guest
```

Sem SignalSema injetado, sem env-gate semantico e sem alteracao do scheduler.

## Evidencia PCSX2-MCP

O registro MCP e a configuracao local ainda apontavam para drives antigos. Ambos foram
religados ao checkout `E:\Games\Emuladores\Sony\mc3recomp`; o PCSX2-MCP abriu a ISO
retail e confirmou via DebugServer + PINE:

```text
Game: Midnight Club 3 - DUB Edition Remix (SLUS-21355)
pad 0 object base:       0x006BB400
pad 0 internal phase:   7
pad 0 DMA area:         0x006BB440
pad 0 packet id:        0x79
padlib base:            0x006FC590
last live PADMAN cmd:   0x08
```

A captura tambem mostrou o layout completo de `pad_data_new`: frame em `+0x58`, length
em `+0x60`, `modeCurId=0x79`, state `6`, reqState `0` e currentTask `1`.

## Causas corrigidas

1. A telemetria anterior lia `0x0070C590`; a base correta e `0x006FC590`. Os dois ports
   ja publicavam `0x006BB440/0x006BB600` e `open=1`.
2. O fallback generico zerava `GET_MODVER 0x12`; o retail recusava `padman.irx = 0.0`.
   A resposta correta e `0x0400`.
3. `SET_MMODE 0x06` usa resultado em `+0x14`. Escrever apenas `+0x0C` fazia a fase
   interna permanecer em `1`.
4. Comandos assíncronos marcam reqState BUSY no EE e PADMAN o conclui por DMA. O runtime
   agora publica COMPLETE antes da proxima leitura de `ioPad::Attach`.

Os comandos e offsets implementados seguem o protocolo libpad novo:

```text
0x01 OPEN          result +0x0C
0x06 SET_MMODE     result +0x14
0x07 SET_ACTDIR    result +0x14
0x08 SET_ACTALIGN  result +0x14
0x09 GET_BTNMASK   result +0x0C
0x0A SET_BTNINFO   result +0x10
0x10 INIT          result +0x0C
0x12 GET_MODVER    result +0x0C = 0x0400
```

## Prova no runner

Probe headless deterministico, budget de 600000 despachos:

```text
command 0x12 result 0x0400
command 0x10 result 1
command 0x01 port 0 result 1 dmaReady 1
command 0x01 port 1 result 1 dmaReady 1
command 0x06 port 0 result 1 resultOffset 0x14
command 0x06 port 1 result 1 resultOffset 0x14

ioPadAttachPhases = 7,7,0,0
ioPadPollCalls     = 10
guestPadReadCalls  = 10
gsPrims            = 13848
gsPixels           = 5335404
```

Validacao complementar: build incremental OK, fast relink OK, suite **292/292**.

## Proxima fronteira

O transporte guest de controle esta ativo. O proximo gate e alimentar esse pacote com o
estado real do controle host e provar, por trace, uma transicao do frontend causada por
START. `uiInputUpdate/ioInputUpdate` ainda nao foram observados neste budget.
