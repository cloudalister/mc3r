# RESULT - DMA VIF0 - 2026-08-28

## Resultado binario

**ACEITE SATISFEITO para o modo normal.** O PC amostrado nao reapareceu em
`0x3A01C8` e estabilizou em `0x3A0460` depois da transferencia VIF0 normal.
O novo bloqueio e uma transferencia VIF0 em modo chain (`CHCR=0x144`), deixada
ativa e registrada como TODO conforme o contrato.

Nao houve evidencia nova de modelo 3D: zero traces `mc3-gfx-*`, e os contadores
de render permaneceram congelados depois do teardown da tela legal.

## Implementacao

Arquivos do runtime/teste alterados neste lote:

- `PS2Recomp/ps2xRuntime/src/lib/ps2_memory.cpp`
- `PS2Recomp/ps2xRuntime/include/runtime/ps2_memory.h`
- `PS2Recomp/ps2xTest/src/ps2_memory_tests.cpp`

O canal `0x10008000` agora, em modo normal:

1. le `D0_MADR` e `D0_QWC`;
2. copia todas as `QWC * 16` bytes da RDRAM/SPR para um FIFO VIF0 explicito;
3. avanca `D0_MADR`, zera `D0_QWC` e somente entao limpa `CHCR.STR`;
4. levanta `D_STAT.CIS0` e recalcula o bit-resumo 31 contra a mascara;
5. emite ate 32 traces `[boot-trace:dmac-vif0]` com os dois primeiros qwords.

O FIFO ficou fora do layout de `PS2Memory`: os objetos gerados do partial runner
codificam offsets do runtime, portanto aumentar a classe quebraria a ABI dos
objetos ja compilados. O buffer process-local e limpo em `initialize()`.

Modo chain nao finge conclusao: mantem STR ativo e emite
`[boot-trace:dmac-vif0-chain-todo]` com TADR. Interpretacao de VIFcode e execucao
de VU0 nao foram implementadas.

## Referencia de hardware conferida

`PS2-Programming-Docs/EE_Users_Manual.pdf`, capitulos 5 e 6:

- canal 0 e VIF0, direcao memoria -> periferico, em qwords de 128 bits;
- modo normal e `MOD=00`; `STR=1` enquanto opera;
- ao terminar QWC, hardware limpa STR e levanta `D_STAT.CIS0`;
- o VIF e o destino que recebe e depois interpreta o pacote DMA.

## Build, suite e relink

- `work/scratch/build_runtime_watch.bat`: verde; `libps2_runtime.a` em
  `2026-08-28 01:50:54`.
- target `ps2x_tests`: relinkado com sucesso.
- suite, CWD oficial `PS2Recomp/out/build`: **299/299 verde** na repeticao de
  confirmacao. Uma corrida anterior deu 298/299 por flake nao reproduzido; os
  dois testes VIF0 passaram nas duas corridas.
- `10_link_partial_runner.bat fast`: verde.
- `mc3_partial.exe`: `2026-08-28 01:53:54`, mais novo que a biblioteca.
- `missing_functions.partial.manifest.csv`: somente cabecalho.

## Probe headless

Comando:

```bat
work\scratch\run_gfx_probe.bat 900 20260828_vif0 headless
```

Evidencia principal:

- `work/logs/gfx_probe_20260828_vif0.log.stderr`
- duracao: 02:25:16 -> 02:40:15, wall-clock headless;
- tick final amostrado: `49020`;
- PC estavel antes: `0x3A01C8` no probe anterior;
- PC estavel depois: `0x3A0460`, 532 amostras depois do trace VIF0;
- ocorrencias de `pc=0x3a01c8` depois do trace: zero;
- `missing-function=0`, `unimplemented=0`, `mc3-gfx-*=0`;
- um `first-bad-pc` preexistente em `0x5CCE60`, uma das regioes Ghidra
  explicitamente fora deste lote; o dispatcher recuperou para `ra=0x44A2B4`.

Trace normal capturado:

```text
[boot-trace:dmac-vif0] madr=0x005f29d0 qwc=0x00000034 chcr=0x00000100 qw0=000000000000674ab2000580ff020000 qw1=00380109ff0200000000002aff020000
```

Proxima transferencia capturada:

```text
[boot-trace:dmac-vif0-chain-todo] tadr=0x006ccce0 chcr=0x00000144
```

Contadores no plateau final, iguais ao teardown da legal:

- `gifPk1=348558`
- `gifPk2=136612`
- `gifPk3=0`
- `gsPrims=703599`
- `gsPixels=256036663`
- `dma=29420`

O helper tentou anexar `[probe] timeout reached` ao `.stdout` ainda aberto e
recebeu `IOException`; isso nao afetou o `.stderr`, o encerramento forcado do
processo nem a analise. `mc3_partial.exe` nao permaneceu rodando.

## Desvio de medicao declarado

Este lote nao usou `MC3_DETERMINISTIC=1 + MC3_DISPATCH_BUDGET=25000`. A tela
legal consome cerca de 490 iteracoes de script e o frontend so aparece perto do
tick 33000; o budget 25000 nao alcanca o corredor. A corrida longa wall-clock e
comparavel as duas corridas de 2026-08-28 que provaram o bloqueio.

## Pendencias explicitas

1. Implementar VIF0 source-chain, guiado por `TADR=0x006CCCE0` e `CHCR=0x144`.
2. Interpretar VIFcode do pacote VIF0 e conectar MPG/UNPACK ao VU0.
3. Tratar as regioes nao analisadas no Ghidra em lote separado, comecando por
   `0x5CCE60/68`; nenhuma foi alterada aqui.
4. Fazer corrida visivel com humano para pressionar Start; fora desta janela.

Sem SignalSema injetado, sem env-gate novo, sem mudanca de scheduler/dispatcher/
SIF, sem PCSX2, sem janela visivel e sem push.

## Commits locais e limite da arvore suja

- submodulo `mc3`: `8e5d233 fix(runtime): implement VIF0 normal DMA`;
- repositorio externo: `6ad930a docs(vif0): record normal DMA result`.

Os tres arquivos de runtime/teste e `PS2_PROJECT_STATE.md` ja continham mudancas
acumuladas anteriores ao lote. Como as mudancas VIF0 cairam nos mesmos hunks, os
commits locais tambem checkpointaram esse estado preexistente nesses quatro
caminhos. Isso explica os stats grandes e impede chamar os commits de pequenos.
Os demais arquivos modificados/untracked permaneceram fora do stage e nenhum
push foi feito.
