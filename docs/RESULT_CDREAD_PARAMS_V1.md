# Resultado — passo 20: parsing correto do payload de sceCdRead

Continuação do handoff `docs/RESULT_BIND_COMPLETION_V1.md` (marco: `sceCdRead`
fno=1 disparou ao vivo pela primeira vez, mas com `lsn`/`sectors`/`buf` implausíveis
e `readOk=0`). Data: 19/08/2026. Repo raiz `mc3recomp` (branch `main`) + submódulo
`PS2Recomp` (branch `mc3`).

## Resumo (3 linhas)

O parsing do payload de envio de `sceCdRead` (`SIF.cpp:1110-1177`) usava o
endereço `0x005D8040` (`_sceCd_ncmdsdata`), copiado direto do `MC.MAP` do build
**alpha** (`work/exports/alpha_decomp_sce.txt`), sem portar para o build
**retail** (`SLUS_213.55`, o ELF real recompilado) — alpha e retail têm segmentos
de dados completamente diferentes (funções já se sabia que se moviam, ~0x50000
bytes; globais nunca tinham sido conferidos). Reli o código de máquina retail
real de `FUN_005422c8_0x5422c8.cpp` (== `sceCdRead` retail, confirmado por
`retail_symbol_port.csv`: alpha `0x4F6AF8` → retail `0x5422C8`) e recalculei os
endereços a partir das instruções `lui`/`addiu`/`sw`/`sb` que constroem o
struct. Endereço certo do struct: `0x0061FC80` (não `0x5D8040`). Após corrigir,
`sceCdRead` leu `lsn=0x10 sectors=0x1 buf=0x19f380 readOk=1`, e os 16 primeiros
bytes escritos no buffer do guest batem **byte a byte** com o LBA 16 do ISO real
(`01 43 44 30 30 31 01 00 50 4c 41 59 53 54 41 54` — Primary Volume Descriptor
ISO9660, `CD001`/"PLAYSTAT...").

## Layout real do payload (campo a campo, evidência do decomp retail)

Fonte: `work/generated/ghidra/FUN_005422c8_0x5422c8.cpp` (código de máquina
retail desmontado, não um nome hipotético — cada campo abaixo é uma instrução
`sw`/`sb` real endereçando `$s2`).

```
0x5422cc/0x5422d4: lui  $v1,0x62         -> v1 = 0x00620000
0x5422f4:          addiu $s2,$v1,-0x380  -> $s2 = 0x0061FC80   (base do struct de envio)
0x542330:          lui  $t0,0x62         -> t0 = 0x00620000
0x54233c:          lui  $s3,0x62         -> s3 = 0x00620000 (reaproveitado, ver abaixo)
```

| Offset (`$s2` + N) | Campo | Instrução retail | Fonte (registrador na entrada) |
|---|---|---|---|
| `+0x00` | `lsn` | `0x542334: sw $s3,0x0($s2)` | `$s3` = `$a0` original = `param_1` (lsn) |
| `+0x04` | `sectors` | `0x542338: sw $s1,0x4($s2)` | `$s1` = `$a1` original = `param_2` (sectors) |
| `+0x08` | `buf` | `0x542340: sw $s4,0x8($s2)` | `$s4` = `$a2` original = `param_3` (endereço do buffer guest, 32 bits) |
| `+0x0C` | mode byte0 | `0x542354: sb $v0,0xC($s2)` | `param_4[0]` |
| `+0x0D` | mode byte1 | `0x54235c: sb $v1,0xD($s2)` | `param_4[1]` |
| `+0x0E` | mode/datapattern byte2 | `0x542368: sb $v0,0xE($s2)` | `param_4[2]` — seletor de tamanho de setor: `==1` → 0x918B/setor, `==2` → 0x924B/setor, senão `sectors<<0xb` (2048B/setor), confirmado em `0x542374-0x54239c` |
| `+0x10` | ponteiro intr-data | `0x542364: sw $a0,0x10($s2)`, `$a0 = $s3+0xC80 = 0x00620C80` | constante retail (equivalente a `&_sceCd_rd_intr_data` do alpha) |
| `+0x14` | ponteiro cur_pos | `0x54236c: sw $a1,0x14($s2)`, `$a1 = $t0+0xD40 = 0x00620D40` | constante retail (equivalente a `&_sceCd_Read_cur_pos` do alpha) |

Tamanho total: `0x18` bytes, confirmado pela própria chamada
`0x542440: jal func_549488` (`sceSifCallRpc`) com `$a3=$s2` (send=`0x61FC80`) e
`$t0=0x18` (sendsize) — mesmo `client=0x620D50` já trace-confirmado no handoff
anterior (`RESULT_DISKREADY_059C_V1.md`).

Flags de sincronização (também localizadas na mesma varredura, fora do struct
de envio mas escritas pela mesma função antes da chamada):
- `sceCdCbfunc_num` (retail): `0x61FBD8` (`0x54240c: sw $v0,-0x428($s0)`, `$s0=0x620000`)
- `_sceCd_c_cb_sem` (retail, a flag que `sceCdSync` faz busy-wait em `!=0`):
  `0x61FBB4` (`0x54241c: sw $v0,-0x44C($s1)`, `$s1=0x620000`)

## Erro do parsing antigo

`SIF.cpp` usava, sem porte, os três endereços do `MC.MAP` **alpha**:

| Constante | Valor antigo (alpha, errado) | Valor novo (retail, decomp-verificado) |
|---|---|---|
| `kMc3CdvdNcmdSendDataAddr` | `0x005D8040` | `0x0061FC80` |
| `kMc3CdvdRdIntrDataAddr` | `0x005D9040` | `0x00620C80` |
| `kMc3CdvdCbSemAddr` | `0x005D7F74` | `0x0061FBB4` |

Os *offsets relativos* dentro do struct (`+0x0`, `+0x4`, `+0x8` para
lsn/sectors/buf) já estavam certos — só a base estava errada, por isso o
handler lia memória de guest não relacionada (não inicializada/lixo:
`lsn=0x3c16aaaa`, `sectors=0x3c1700ff`, `buf=0x36f7ffff` no trace anterior —
valores que coincidentemente parecem instruções MIPS `lui`, evidência de que
o handler estava lendo uma região de código ou memória não escrita pelo
cliente, não o struct real).

Também adicionei leitura do byte de modo (`+0x0E`) ao trace (`mode=0x...`) para
visibilidade — o `readCdSectors` de backend continua fixo em 2048B/setor (igual
ao caminho já usado por `CD.cpp`); os tamanhos alternativos 0x918/0x924 (modos
1/2) ficam como TODO explícito, não modelados, já que a leitura observada usa
`mode=0x0` (2048B, caminho padrão).

## Bytes conferidos

Uma corrida determinística (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=100000`,
90s, `MC3_BOOT_TRACE=1`, `work/logs/14_run_boot_trace.log`):

```
[boot-trace:mc3-cdvd-rpc] kind=read-bytes lsn=0x10 first16=01 43 44 30 30 31 01 00 50 4c 41 59 53 54 41 54
[boot-trace:mc3-cdvd-rpc] kind=read sid=0x80000595 fno=0x1 lsn=0x10 sectors=0x1 buf=0x19f380 mode=0x0 readOk=1 intr_data=0x620c80 pc=0x546d60 ra=0x5489dc
```

LBA 16 (`lsn=0x10`), offset `16*2048 = 0x8000` bytes no ISO. Conferido com
Python lendo `Midnight Club 3 - DUB Edition Remix.iso` no mesmo offset:

```python
with open("Midnight Club 3 - DUB Edition Remix.iso","rb") as f:
    f.seek(16*2048)
    print(f.read(16).hex())
# -> 01434430303101005041594445415f...  (bate byte a byte com o trace)
```

**Bate byte a byte**: `01 43 44 30 30 31 01 00 50 4c 41 59 53 54 41 54` é o
Primary Volume Descriptor ISO9660 padrão (`type=1`, `"CD001"`, versão `1`,
seguido do identificador de sistema `"PLAYSTAT..."`), exatamente o que se
espera no LBA 16 de qualquer disco PS1/PS2. `readOk=1`.

## Trajetória do gate

`sceCdRead` agora lê corretamente e retorna sucesso (`readOk=1`,
`gateC@0x542448` `bgezl` tomado). A cadeia avança bem além do gate anterior:

- Corrida determinística de 90s (mesma acima): o boot avança da fase
  `sceCdRead`/ncmd (sid `0x80000595`) para um novo estágio que faz *bind retry*
  no cliente de `diskready-status` (sid `0x8000059c`, `aux=0x6faed0`,
  `cmd=0x8000000a`), ficando estabilizado em torno de `pc=0x245718` (mesma
  vizinhança do laço antigo `sub_00245680`, mas não idêntico ao PC exato do
  handoff anterior — `0x5a8908` não foi reproduzido nesta corrida
  determinística).
- `21_probe_repeat.bat 3 595 cdreadfix` (modo rápido, wall-clock, 8s por
  corrida, **sem** `MC3_DETERMINISTIC`): **3 PCs distintos** entre as 3
  corridas (`0x1a0138` unknown-loop; `0x42a004` e `0x3afec8`
  missing-function, ambas batendo em `bad=0x4fa368`) — mais adiante no boot
  que os gates anteriores (`0x245720`/`0x5a8908`), mas **não estável 3x**.
  Isto é consistente com o tema já documentado em handoffs recentes
  (`8e5447d`, `90523a9`): separar lentidão/timing de não-determinismo real
  seria o próximo passo — não investigado aqui, fora do escopo deste passo
  (que era estritamente corrigir o parsing do payload).

**Honestidade**: não consigo confirmar "Probe-Repeat 3x" estável neste passo —
a correção do parsing é confirmada e comprovada byte a byte (bytes do ISO
certos), mas o próximo gate na cadeia de boot não estabilizou em um único PC
nas 3 corridas rápidas. A corrida determinística de 90s (a única comparável
ao método usado no handoff anterior) mostra avanço real: `sceCdRead` completo
com sucesso onde antes falhava.

## Régua de render (M0-M6)

Sem M4. `gsPrims=0 gsPixels=0 gifPk1=0` em toda a corrida determinística de 90s
(92 amostras de frame, todas zeradas). Nenhum `gsPixels` isolado observado
desta vez (diferente do handoff anterior, que via 1 ocorrência isolada não
confirmada). M4 não alcançado.

## Suíte

`ps2x_tests.exe` (272 testes), rebuild completo via `ninja ps2x_tests`
(MSYS2 ucrt64 no PATH): **272 passed, 0 failed**. A falha isolada do handoff
anterior (`VU0 macro mappings cover all S1/S2 enums`) não se repetiu — confirma
que era ruído/flake pré-existente, não relacionado a `SIF.cpp`.

## Build

- `find_stale.py` antes do rebuild: `Missing: 0, Stale (mtime): 0`.
- `SIF.cpp` recompilado via `ninja ps2x_tests` (CMake/Ninja do VS2022 em
  `PS2Recomp/out/build`, g++ MSYS2 `ucrt64` no PATH) — reconstruiu
  `libps2_runtime.a` e `ps2x_tests.exe`. Build limpo, sem warnings novos.
- `mc3_partial.exe`: relink via `10_link_partial_runner.bat fast` (usa a mesma
  `libps2_runtime.a` recém-reconstruída, `Link-PartialRunner.ps1` linha 80).
  Relink não concorrente, sequencial após o `ninja`.

## Corridas

- `14_run_boot_trace.bat 90` (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=100000
  MC3_BOOT_TRACE=1`): log completo em `work/logs/14_run_boot_trace.log`.
- `21_probe_repeat.bat 3 595 cdreadfix`: relatório em
  `work/boot_probe/repeat_cdreadfix_20260819_060743.md`, `Stable PCs
  distintos: 3` (ver seção "Trajetória do gate" acima para leitura honesta
  disso).

## Commits

- Submódulo `PS2Recomp` (branch `mc3`): `ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`
  (endereços do payload de `sceCdRead` corrigidos para retail + trace de modo/
  bytes) — commit local, sem push.
- Repo raiz (`mc3recomp`, branch `main`): ponteiro do submódulo atualizado +
  este RESULT doc — commit local, sem push.

## Próximo passo recomendado

1. O novo estágio de bind-retry em `pc≈0x245718` (cliente `0x6faed0`, sid
   `0x8000059c`) é o próximo gate a investigar — mesma metodologia (ler
   decomp retail honesto, achar a condição de saída, instrumentar 1 ponto,
   tracear 1 corrida determinística).
2. A instabilidade entre as 3 corridas rápidas do Probe-Repeat (PCs
   `0x1a0138`/`0x42a004`/`0x3afec8`, todas mais adiante que antes) sugere que
   o boot agora depende de timing/quantidade de leituras de CD antes de um
   próximo gate — vale medir se isso é "lentidão" (mais leituras precisam
   completar antes do próximo estágio) ou não-determinismo real (tema já
   citado em `8e5447d`), antes de investigar o gate em si.
