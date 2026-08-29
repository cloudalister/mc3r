# RESULT — corrida com `-skipintro -garage` — 2026-08-29

## Resultado

**Os argumentos chegam ao guest e mudam o comportamento, mas a corrida NÃO alcança a
garagem — ela trava mais cedo que a corrida sem argumentos.** É divergência real de
caminho, não avanço.

Nenhum trace `mc3-gfx-*` disparou. **Continua sem prova de modelo 3D de carro.**

## Comando

```
mc3_partial.exe "extracted_iso\SLUS_213.55" -skipintro -garage
```

Headless, `MC3_BOOT_TRACE=1`, 900 s, binário `-O2` de 2026-08-29 07:40.
Driver: `work/scratch/Run-ProbeArgs.ps1`.
Log: `work/logs/probe_20260829_garage.log.stderr`.

## Entrega dos argumentos: confirmada

`argc=3 argv=0x01ffff98` no trace. O mecanismo do crt0 entregou os três argumentos
(ELF, `-skipintro`, `-garage`) como projetado.

## Comparação direta contra a corrida sem argumentos

Mesmo binário, mesma duração, mesma configuração; só mudam os argumentos.

| | sem argumentos (`gfx_probe_20260829_O2`) | com `-skipintro -garage` |
|---|---|---|
| PC final | `0x41D188` | **`0x322FFC`** |
| Estabilidade do PC | 200/200 últimos frames | 200/200 últimos frames |
| Funções ausentes | 5 distintas (72 ocorrências) | **zero** |
| `gifPk1` | 348.988 | **348.558** |
| `gifPk2` | 138.800 | **136.612** |
| `gsPrims` | 704.397 | **703.599** |
| `gsPixels` | 257.216.311 | **256.036.663** |
| `mc3-gfx-*` | 0 | 0 |
| `End=1` (tela legal) | sim | sim |

Os contadores da corrida com argumentos são **exatamente** o platô do teardown da tela
legal — os mesmos valores de `gfx_probe_20260828_gfx1`. Ou seja: ela para antes de
executar as transferências VIF0 e o trabalho de render que a corrida sem argumentos faz
depois.

`-skipintro` não pulou a tela legal: `End=1` continua acontecendo.

## Onde para

PC estável em `0x322FFC`, dentro de `FUN_00322fd8_0x322fd8`:

```
0x322fe8: lbu   $v0, 0xC($s0)      ; flag do objeto
0x322fec: bnez  $v0, +5            ; se setada, pula a chamada
0x322ff4: jal   func_3451E8        ; <- fica aqui
0x322ff8: lw    $a0, 0x7ADC($v0)   ; (delay slot)
0x322ffc: b     +4                 ; PC amostrado
```

`0x322FFC` é o branch logo após `jal func_3451E8`, então o tempo está sendo gasto dentro
de `0x3451E8` (ou no retorno dele). Os traces `mc3-3451e8-stage` / `mc3-3451e8-target` com
`ra=0x00322ffc` já apareciam em corridas anteriores, mas ali o fluxo seguia adiante.

Último progresso registrado antes do travamento:

```
mc3-322fd8-progress stage=0x00323010 object=0x016d5fc0 flag=0x00 v0=0x00000001 ra=0x00322ffc
mc3-322fd8-progress stage=0x00323024 object=0x016d5fc0 flag=0x01 v0=0x00000001 ra=0x0032302c
```

## Leitura honesta

O que ficou **provado**:

1. A entrega de boot args funciona de ponta a ponta — `argc=3` chega ao guest.
2. Os argumentos **mudam o comportamento do jogo**. Dois PCs de travamento diferentes,
   com zero funções ausentes num caso e cinco no outro, não é ruído.

O que **não** ficou provado, e não se deve afirmar:

1. Que `PARAM_skipintro`/`PARAM_garage` ficaram verdadeiros. Não foi lido o valor final
   dessas globais. A divergência de caminho é evidência **indireta** de que o parser
   consumiu algo, não prova de que essas duas flags específicas foram setadas.
2. Que o jogo tentou entrar na garagem. `mcGameState::SetFrameModeGarage` (`0x001A7150`)
   não foi instrumentado; não há trace dele.
3. Que este travamento é causado pelo modo garagem. Pode ser um caminho de código que
   simplesmente ainda não funciona, e que os argumentos apenas passaram a alcançar.

**Não é avanço.** A corrida com argumentos chega menos longe em termos de render que a
corrida sem eles. Tratar isso como progresso seria enganoso.

## Próximos passos concretos

1. Ler os valores finais de `PARAM_skipintro` e `PARAM_garage` na memória guest depois do
   parser rodar. Sem isso não se sabe se as flags pegaram. É a medição que falta.
2. Instrumentar `mcGameState::SetFrameModeGarage` (`0x001A7150`) e
   `mcGameState::SetFrameModeFrontend` (`0x001A71C8`) para ver qual modo o jogo escolhe.
3. Investigar `0x3451E8` chamado de `0x322FF4`: por que não retorna aqui e retorna na
   corrida sem argumentos.
4. Testar os argumentos isoladamente (`-skipintro` sozinho, `-garage` sozinho) para saber
   qual dos dois causa a divergência.

## Notas de processo

Duas falhas minhas nesta sessão, registradas para não se repetirem:

- O primeiro driver de probe (`work/scratch/run_probe_args.bat`) montava o array do
  PowerShell sem vírgulas (`@( '-skipintro' '-garage')`), o que é erro de parser. O
  processo nunca subiu, mas o `.bat` ainda imprimiu `[OK]`. Se eu tivesse confiado no
  `[OK]`, teria concluído que `-garage` fazia o jogo sair imediatamente — e isso viraria
  "descoberta". Só apareceu ao conferir que o stderr estava vazio. Substituído por
  `work/scratch/Run-ProbeArgs.ps1`, com `[string[]]$GuestArgs` tipado.
- Um relink anterior foi momentaneamente dado como falho porque verifiquei o executável
  cedo demais (0 bytes, com `ld` ainda escrevendo). A espera correta é por `ld.exe` **e**
  `collect2.exe`.

Sem SignalSema injetado, sem env-gate novo, sem mudança de scheduler/dispatcher/SIF, sem
escrita direta em `PARAM_*`, sem PCSX2, sem janela visível e sem push.
