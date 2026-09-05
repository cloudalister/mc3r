# Resultado: a tabela de callbacks é vazia de fábrica; a saída da tela legal é `mc3FeView::CanTransition`

Data: 2026-09-04

## 1. Hipótese morta: "ninguém está registrado para consumir o input"

`ioInput::Update@0x58EEB0` termina percorrendo quatro ponteiros a partir de `0x715D28`
(`lui $v0,0x71 ; addiu $s0,$v0,0x5D28 ; lw/beqz/jalr`, s1 = 3..0). A suspeita era que a
tabela estivesse vazia no nosso runtime. Está — e está no console também:

| evidência | resultado |
|---|---|
| Escritores no corpus (15.8k funções), qualquer forma de endereçar `0x715D28..0x715D37` (`lui 0x71`/`0x72` + offset, `ori`, base+deslocamento rastreado por registrador, `$gp`) | **zero**. Único leitor: `0x58EEB0`. |
| Ponteiro literal `0x715D28..34` no `.data` do ELF (`SLUS_213.55`, único `PT_LOAD`, `filesz=0x4D7074`) | **zero** ocorrências. |
| Seção | `0x715D28` está entre `p_vaddr+filesz` e `p_vaddr+memsz` → **BSS**. O crt0 (`0x1a0128..0x1a0150`) zera `0x677080..0x715D3C` e passa `0x715D3C` ao `SetupHeap` (syscall 0x3D). A tabela são os últimos 16 bytes da BSS. |
| Vizinho mais próximo que escreve: `FUN_00553618` (`sw $v0,0($s3)`, `$s3` desde `0x715CD0`, `$s4=0xE` → 15 entradas, até `0x715D0C`) | não alcança `0x715D28`. |
| Runtime, corrida `probe_inputcbs_20260904` (25 min, START automático) | `inputCbs=0x0,0x0,0x0,0x0` em 948 de 948 amostras limpas. |

Conclusão: o laço de callbacks do `ioInput::Update` é um no-op no retail também. Não explica
nada. **Não reabrir.**

A corrida repetiu o quadro conhecido: `enterFrontendCalls=1`, transições em `3/1/3/2/3`,
`ioPadPollCalls=576`, `uiInputUpdateCalls=90`, `ioInputUpdateCalls=31`, tela legal desenhada
(`work/captures/frame_inputcbs_20260904.png`).

## 2. Quem decide sair da tela legal (verificado no decomp)

A tela da foto é `mcMenuTitleScreen` (vtable `0x62AA70`; slot `+0x1C` = `Update@0x363320`,
confirmado lendo a vtable no ELF). É um filme `mcFlash` — o `Update` escreve as variáveis de
script `savegamescreen`, `PressStart`, `Press_Start` via `mcFlash::SetContextVariable`.

Bloco de saída em `0x3634AC..0x363568` (`FUN_00363320_0x363320.cpp`):

```
0x3634ac  lwc1 $f1, 0x130($s1)          ; acumulador
0x3634b0  lwc1 $f3, -0x71E0($v0)        ; *(float*)0x618E20 = delta de quadro
0x3634b8  add.s $f1, $f1, $f3
0x3634bc  lui $at, 0x41F0 ; mtc1 -> $f2 = 30.0f
0x3634c8  lw   $a0, 0x7980($s6)         ; *(0x617980) = mc3FeView
0x3634cc  c.lt.s $f2, $f1               ; 30.0 < acumulador ?
0x3634d0  swc1 $f1, 0x130($s1)
0x3634d4  bc1f -> sai                   ; ainda não passou 30 s: nada
0x3634dc  jal  func_3224F8              ; mc3FeView::CanTransition(feView)
0x3634e4  beqz $v0 -> sai               ; não pode: nada
          ...  this+0x130 = 0 ; this+0x12C = 0 ; this+0x198 = 1
          virtual +0xD4(this,0) ; virtual +0xE0(this,1)
0x363530  jal  func_4BE968(*(0x619B14), "mc3intro")
0x363540  sb   1 -> 0x619B06
0x363550  jalr mcGameState::PostCommand(*(0x619958), 8)
0x363564  jalr mcGameState::PostCommand(*(0x619958), 0x10)
```

`mc3FeView::CanTransition@0x3224F8` inteira:

```
0x3224f8  lbu  $v0, 0x49($a0)
0x3224fc  bnez $v0 -> return 0
0x322504  lw   $v0, 0x6AC($a0)
0x32250c  slti $v0, $v0, 0              ; return (s32)this+0x6AC < 0
```

`this+0x6AC` recebe `0` nos inicializadores (`0x321390`, `0x322428`) e só vira `-1` dentro de
`mc3FeView::Update@0x322668`: em `0x3226d8` (quando `this+0x680[this+0x6B0]` é nulo) e em
`0x322ca4` (fim da animação de câmera). Ou seja, **sem `mc3FeView::Update` rodar até o fim do
voo de câmera, a tela legal não sai nem por timeout nem por Start**.

Cadeia que deveria chamar isso todo quadro, no estado 7 (`mc3frontend`): despacho do laço
principal em `0x1A2718` → `func_1A32B0` → `func_322FD8(*(0x617980))` → `mc3FeView::Update`.

Observação: esse bloco é o **timeout de atrair** (volta ao filme `mc3intro` depois de 30 s
parado). Ele não lê botão nenhum. O Start deve chegar por outro caminho (receptores de evento da
`uiInput`, registrados por `AddEventReceiver@0x420C90`, chamado só virtualmente). Mas o timeout
não depende de input, e ele também não dispara — por isso é a medição mais barata.

Estruturas confirmadas de passagem:

- `*(0x619958)` = singleton `mcGameState` (vtable `0x623808`: `+0x0C PostCommand@0x1A5278`,
  `+0x10 Update@0x1A5340`, `+0x14 HasPending@0x1A5330`, `+0x20 EnterState@0x1A55D0`).
  `+0x04` estado atual, `+0x0C..+0x34` fila circular de 10 comandos, `+0x38` head, `+0x3C`
  contagem. `cmd 0x10` → `EnterState(4)`; `cmd 8` → fade.
- `*(0x617980)` = `mc3FeView`.

## 3. Instrumentação adicionada (`PS2Recomp/ps2xRuntime/src/lib/ps2_runtime.cpp`)

Campos novos no trace de quadro:

| campo | o que é |
|---|---|
| `feView`, `fe49`, `fe6AC`, `fe6B0`, `feAnim` | `*(0x617980)` e os campos que `CanTransition` e `mc3FeView::Update` consultam |
| `gsState`, `gsHead`, `gsCount`, `gsQ` | `mcGameState`: estado (esperado 7) e fila de comandos |
| `titleObj`, `title130`, `title12C`, `title198` | `mcMenuTitleScreen`, achado pela vtable `0x62AA70` na RAM; `title130` é o acumulador de 30 s |
| `titleUpdateCalls`, `feViewUpdateCalls`, `canTransitionCalls`, `frontendTickCalls` | entradas em `0x363320`, `0x322668`, `0x3224F8`, `0x1A32B0` (via `lookupFunction`; `jal` direto passa por lá, confirmado no código gerado) |

Leitura esperada:

- `title130` sobe ~1.0/s e passa de 30 → o timeout roda; aí `canTransitionCalls` sobe e a
  resposta está em `fe49`/`fe6AC`.
- `title130` parado ou subindo devagar → `mcMenuTitleScreen::Update` quase não roda; o alvo vira
  quem chama a árvore de UI.
- `fe6AC` preso em `>= 0` com `feViewUpdateCalls` subindo → o voo de câmera não termina.
- `fe6AC` preso e `feViewUpdateCalls=0` → `func_1A32B0` não chega em `mc3FeView::Update`.

## 4. Medição

Corrida `probe_titleexit_20260904`, headless, 1200 s, START automático, encerrada por timeout no
tick 50.760. Log em `work/logs/probe_titleexit_20260904.log.stderr` (857 linhas de frame).

| campo | valor final | leitura |
|---|---:|---|
| `gsState` | **7** | está mesmo em `mc3frontend`; o estado é o certo |
| `gsCount` | 0 | fila de comandos do `mcGameState` vazia — ninguém pediu transição |
| `feView` | `0x16d5ec0` | o objeto existe |
| `fe49` | 0 | passa na primeira checagem de `CanTransition` |
| `fe6AC` | **23** | precisa ser negativo. Assume 0, 6, 8, 15, 21, 23 ao longo da corrida: **está avançando**, não travado |
| `fe6B0` | alterna 0 e 10 | índice em uso |
| `frontendTickCalls` | **18** | `func_1A32B0`, a raiz da árvore do frontend |
| `feViewUpdateCalls` | **18** | `mc3FeView::Update@0x322668` |
| `titleUpdateCalls` | 18 | `0x363320` |
| `canTransitionCalls` | **0** | nunca chamada |
| `gsPrims` / `gsPixels` | 961.905 / 923.828.773 | o render segue normal o tempo todo |

Primeira entrada em `func_1A32B0` só no **tick 24.300**; depois, uma a cada ~1.400 ticks
(4 no tick 29.400, 8 no 35.100, 11 no 39.780, 15 no 45.000, 18 no 50.760).

### Qual das quatro previsões da seção 3 se realizou

A terceira, e sem ambiguidade: **a árvore de UI do frontend quase não roda.** Dezoito
atualizações em vinte minutos, contra 50.760 quadros de hospedeiro.

`fe6AC` subindo prova que o voo de câmera **progride** — não é um estado morto esperando algo
externo. Ele só não chega ao fim porque `mc3FeView::Update` roda 18 vezes onde deveria rodar
dezenas de vezes por segundo. `CanTransition` nunca é chamada porque o bloco de timeout dos 30 s
está atrás do mesmo gargalo.

Isso reproduz, num lugar diferente da árvore, exatamente o que
`docs/RESULT_M3_INPUT_GATE_2026-09-03.md` mediu no input (`uiInputUpdate` 90, `ioPadPoll` 576,
contra dezenas de milhares de ticks). **Não são dois problemas: é um só.** O lado convidado
inteiro avança a conta-gotas enquanto o laço do hospedeiro gira livre.

### Armadilha de medição nesta corrida

`titleObj=0x0` em 840 das 857 amostras: a varredura por vtable `0x62AA70` **não achou** o objeto
da tela de título. Portanto `title130`, `title12C` e `title198` desta corrida são valores default
de variável não preenchida, **não são leitura** — a mesma armadilha que `introActive`/`introExit`
já tinham criado (ver `RESULT_M3_INPUT_GATE_2026-09-03.md`). O acumulador de 30 s continua sem
medição. Quem for reaproveitar esses campos precisa achar o objeto por outro caminho.

## 5. Alvo seguinte

Por que `func_1A32B0` é alcançada uma vez a cada ~1.400 quadros do hospedeiro, e não uma vez por
quadro. Duas formas de o convidado chegar nisso, e elas se separam com uma medição barata:

1. **O laço principal itera raro** (convidado bloqueado/esfomeado a maior parte do tempo) — nesse
   caso todos os contadores do lado convidado sobem juntos, na mesma proporção.
2. **O laço itera rápido e o ramo do frontend é raro** (guarda de despacho em `0x1A2718`) — nesse
   caso `frontendTickCalls` fica muito abaixo de contadores de coisas que rodam todo quadro.

O dado de 03/09 já aponta para a segunda: `ioPadPollCalls=576` contra `frontendTickCalls=18` na
mesma ordem de grandeza de ticks. Confirmar contando uma entrada por iteração do laço principal
`sub_001A23A8` e comparando com os dois.



## 6. Perfil amostral do convidado (2026-09-05): quem come a maquina

Instrumentacao nova em `ps2_runtime.cpp`: a cada quadro do hospedeiro registra-se em qual funcao
esta o dono do token de execucao, por endereco de despacho, e as oito mais frequentes saem em
`[boot-trace:guest-profile]` a cada 1800 ticks. Passivo: so conta e imprime.

Resolucao de endereco para funcao pelo intervalo dos arquivos gerados
(`work/generated/ghidra/*_0xADDR.cpp`) cruzada com `work/exports/retail_symbol_port.csv`.

### Regime estavel, ja em `gsState=7` (corrida `probe_isocache_20260905`, 538 amostras)

| endereco | funcao | amostras | fatia |
|---|---|---:|---:|
| `0x42b8c8` | `FUN_0042b868` — servico de streaming de assets | 130 | 24% |
| `0x1f9610` | **`netManagerThread::MainLoop`** | 92 | 17% |
| `0x1faf30` | **`netManagerThread::UpdateStatistics`** | 33 | 6% |
| `0x20d284` | `swfINSTANCE::Update` | 28 | 5% |
| `0x4f94b4` | `zipHandle::Read` | 20 | 4% |
| `0x39923c` | `Stream::Open` | 20 | 4% |
| `0x1f9e98` | **`netManagerThread::Update`** | 14 | 3% |

`FUN_0042b868` nao tem simbolo, mas o que ela chama a identifica sem duvida:
`datStreamer::GetBaseSector` (3x), `datPage::Load`, `ipcWaitSema`, `ipcSignalSema`, `ipcSleep`,
`coreBootedFromDisc`.

**As tres funcoes de `netManagerThread` somam 26% do tempo de convidado — num jogo rodando
offline, sem rede.** Junto com o streamer, sao metade da maquina.

O laco de `netManagerThread::MainLoop@0x1F95C0` e:

```
0x1f95d0  jal ipcWaitSema(this+0x4158)
0x1f95dc  beqz this+0x4160 -> sai
0x1f9608  jalr vtable+0x7C
0x1f9610  jal ipcCriticalSection::Exit
0x1f9618  jal ipcSleep(0xA)          ; 10 -> DelayThread(10000 us)
0x1f9630  bnel this+0x4160, volta
```

Ele deveria dormir 10 ms por volta. Aparecer como **dono do token** em 17% das amostras
significa que nao esta dormindo de verdade — ou dorme sem ceder o token.

### O streaming avanca; nao e retentativa

Os setores lidos sobem em sequencia (`0x197fb5 -> 0x197ff6 -> 0x198037 -> 0x198078 ->
0x1980b9 -> 0x1980fa`, de 0x41 em 0x41). O jogo esta carregando de verdade. Cuidado com a
contagem: o `lsn=` do log tem teto (638 linhas nas duas corridas, identico), entao **nao serve
para estimar taxa de leitura**.

### Cache de handle da ISO: implementado, medido, sem ganho

`readHostRange` (`Kernel/Stubs/Helpers/Support.h`) abria e fechava a ISO de 3,4 GB a **cada**
leitura de setor. Trocado por um handle mantido aberto, com mutex e `clear()` antes de cada
`seekg` (sem isso uma leitura curta liga `eofbit` e a ISO passa a devolver zeros).

| regua (900 s, headless, `MC3_PHASE_TIMING=1`) | antes | depois |
|---|---:|---:|
| tick final | 43.200 | 41.460 |
| voltas do laco principal | 14 | **13** |
| `gsPrims` | 901.680 | 881.956 |
| `guestExecMs` | 510.117 | 513.684 |
| `vifMs` / `vu1Ms` / `rasterMs` | 146.313 / 119.878 / 85.307 | 134.876 / 106.898 / 76.056 |

**Sem ganho no que importa.** A correcao fica por ser desperdicio real no caminho mais quente,
mas nao e o gargalo — e coerente com o perfil, onde `sceCdRead` responde por ~6% das amostras.

### Defeito registrado de passagem: `cop0_count` nunca avanca

`ctx->cop0_count` (`ps2_runtime.h:102`) e declarado e lido pelo codigo gerado (`mfc0 $v0, Count`
vira `SET_GPR_S32(ctx, 2, ctx->cop0_count)`), mas **nenhum ponto do runtime escreve nele**. Logo
`mfc0 Count` devolve sempre a mesma coisa, e toda medicao de tempo decorrido feita pelo convidado
por esse caminho da zero — inclui `sub_0052A388` (o cronometro em volta do `ioInputUpdate`) e
`lowPsxGfx::SendBuffer`.

**Nao e a causa da lentidao**: nenhuma das funcoes quentes (`netManagerThread::MainLoop`,
`FUN_0042b868`, `UpdateStatistics`) le `Count`. Fica anotado como defeito proprio.

## 7. Alvo seguinte

`netManagerThread` come 26% da maquina dormindo mal. Verificar o que `ipcSleep(10)` ->
`DelayThread@0x547608` faz no nosso runtime: se ele cede o token de execucao do convidado
durante os 10 ms ou se fica de posse dele. Um `DelayThread` que nao cede explica, sozinho, tanto
o 17% de `MainLoop` quanto a fome do laco principal — e o arquivo gerado de `0x547608` ja tem
instrumentacao de timer de uma investigacao anterior, entao ha rastro para reaproveitar.
