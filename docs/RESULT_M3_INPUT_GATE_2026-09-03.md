# Resultado: o gate de input já está aberto — e a UI começa a rodar tarde demais para as nossas corridas

Data: 2026-09-03

## Duas coisas: uma hipótese morta e uma pista viva

### Morta: "o frontend recusa um pad digital"

A suspeita vinha de `ioPadStates=4,4,0,0` (4 = `kPadTypeDigital` no runtime) contra
`ioPadAttachPhases=7,7,0,0`, somada à leitura de agosto de que `ioPad::Update` só entra no poll
quando o estado é 7. O decomp fecha a questão:

`ioPad::Update@0x238808` (`work/generated/ghidra/FUN_00238808_0x238808.cpp`):

```
0x238818  lw    $v0, 0x174($s0)      // campo interno do ioPad
0x23881c  beqz  $v0, ret -1          // se zero, nem tenta
0x238824  jal   func_238030          // ioPad::Attach
0x23882c  addiu $v1, $zero, 0x7
0x238830  bne   $v0, $v1, ret -1     // o 7 é o RETORNO do Attach
0x238838  jal   func_238368          // poll
```

O `7` que importa é o **valor de retorno do `Attach`**, não o campo `0x174`. E o campo `0x174` é
escrito pelo próprio `Attach` em três pontos (`0x238088`, `0x2380b4`, `0x2380c0`) — é estado
interno da máquina de anexação, e o `4` só coincide numericamente com `kPadTypeDigital`.

Prova empírica: `ioPadPollCalls=532` na corrida `probe_autostart_20260903`. O poll roda, logo o
`Attach` está devolvendo 7 e **o gate está aberto**. Não há nada a corrigir aqui.

### Viva: a camada de UI só começa a rodar no tick ~29100

Progressão medida na mesma corrida (38.280 ticks, com START sendo entregue o tempo todo):

| tick | `ioPadPollCalls` | `uiInputUpdateCalls` | `ioInputUpdateCalls` |
|---:|---:|---:|---:|
| 4.200 | 0 | 0 | 0 |
| 6.780 | 44 | 0 | 0 |
| 10.800 | 152 | 0 | 0 |
| 29.100 | 518 | 6 | 2 |
| 33.000 | 524 | 15 | 5 |
| 38.220 | 532 | 27 | 9 |

`uiInputUpdate@0x420F38` e `ioInputUpdate@0x58EEB0` ficam **zerados até cerca do tick 29100** —
uns 23 mil ticks depois de o frontend ter sido entrado (~6540) — e a partir dali sobem devagar e
de forma monotônica. A corrida foi morta no tick 38.280, com esses contadores ainda subindo.

**Leitura:** a hipótese "a máquina de estados congelou" pode estar errada. O que os números
descrevem é uma máquina **lentíssima**, que começou a mexer justamente quando o relógio do teste
acabou. Todas as nossas corridas até hoje (10, 15, 20 min) podem ter cortado o jogo bem no
começo do movimento.

## Corredor confirmado de propósito

- Laço principal: `sub_001A23A8` (`0x1a23a8`–`0x1a28a8`). O `pc` vivo do trace de quadro,
  `0x1a2760`, é o retorno logo depois do `jal func_52D7C0` em `0x1a2758` — dentro desse laço.
- Cadeia até o input da UI: `sub_001A23A8` → `func_52D680`/`func_52D6B8`/`func_52D7C0` →
  `sub_0052A388` → `func_58EEB0` (`ioInputUpdate`).

## Próximo teste

Corrida longa (45 min) com `MC3_PAD_AUTOSTART` ligado, para responder uma pergunta só:
`uiInputUpdateCalls` continua subindo e os cinco contadores de transição saem de `3/1/3/2/3`?

- Se saírem: não havia trava nenhuma; o jogo é lento e o teste é que era curto.
- Se não saírem com a UI rodando: aí sim a máquina de estados tem um bloqueio próprio, e o alvo
  passa a ser o que `ioInputUpdate` faz com o pacote de pad.


## Adendo: o portao do input existe, e esta no decomp

O laco principal `sub_001A23A8` nao le o pad todo quadro. Ele consulta um byte e decide:

```
0x1a2698  lbu  $v1, 0x405($v0)      ; flag do objeto de estado
0x1a269c  sltu $v1, $zero, $v1
0x1a26a0  beqz $v1, 0x1a26c0        ; ZERO  -> cai no jal func_52A388 (ioInputUpdate)
0x1a26a4  lw   $a0, -0x66A8($s2)    ; $s2 = 0x620000, logo *(0x619958)
0x1a26a8  lw   $v1, 0x0($a0)        ; vtable
0x1a26ac  lw   $v0, 0xC($v1)
0x1a26b0  jalr $v0                  ; NAO-ZERO -> metodo virtual +0xC, a1 = 0x11
0x1a26b8  b    ...                  ; e desvia POR CIMA do input
```

O alvo do `beqz` (`0x1a26a0 + 4 + (7<<2)`) e exatamente `0x1a26c0`, o `jal func_52A388`.

**Consequencia:** com esse byte diferente de zero o jogo nao le o controle. As 87 chamadas de
`uiInputUpdate` em 67 mil ticks nao sao lentidao — sao as poucas passagens em que o portao
estava aberto.

### Estavamos medindo o objeto errado

O trace de quadro ja lia `+0x404` e `+0x405`, mas do **controlador de intro** apontado por
`0x617BCC` — que e nulo desde que os filmes de abertura descarregaram
(`docs/RESULT_COPY_TO_FRONT_PIPELINE_2026-08-25.md:246`). Por isso `introActive=0 introExit=0`
aparecia em todo relatorio: nao era leitura, era o valor default de variavel nao preenchida.

O objeto sobre o qual o laco principal despacha esta em **`0x619958`**, nao em `0x617BCC`.

O trace de quadro ganhou tres campos novos: `stateObj`, `stateA404`, `stateBusy` (o byte
`+0x405`). A pergunta que a proxima corrida responde e binaria: **`stateBusy` alguma vez chega a
zero e fica?** Se ficar preso em nao-zero, o frontend esta parado numa transicao que nunca
termina, e o alvo passa a ser o que essa transicao espera — nao o input.
