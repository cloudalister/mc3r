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


## 8. O sono esta correto; a conta que fecha e outra

### Hipotese morta: "o `ipcSleep` volta cedo demais"

Contadores novos no trace de quadro (`delayThreadCalls`, `setTimerAlarmCalls`), sobre
`DelayThread@0x547608` e `SetTimerAlarm@0x54D6A0` — as duas confirmadas como registradas na
tabela de funcoes antes de confiar na contagem.

Corrida `probe_sleepcount_20260905`:

| tick | `delayThreadCalls` | `setTimerAlarmCalls` |
|---:|---:|---:|
| 1.560 | 365 | 365 |
| 1.800 | 406 | 406 |
| 1.860 | 413 | 413 |
| 2.040 | 455 | 455 |

Noventa chamadas em 480 ticks, ou seja **cerca de 9 por segundo no processo inteiro**. A
`netManagerThread` sozinha pediria ~100/s se o sono de 10 ms estivesse voltando na hora, e
milhares/s se voltasse cedo. Nove por segundo e o oposto do sintoma procurado.

As duas contagens sao **identicas em toda amostra**: todo pedido de sono arma exatamente um
alarme. O mecanismo (`CreateSema` -> `TimerUSec2BusClock` -> `SetTimerAlarm` -> `WaitSema` ->
`DeleteSema`) esta integro. **Nao reabrir.**

### A conta que fecha

Corrida `probe_isocache_20260905`, 900 s, **13 voltas do laco principal**:

| medida | total | por volta do laco |
|---|---:|---:|
| `vifMs` | 134.876 ms | **10,4 s** |
| `gsPrims` | 881.956 | **67.843** |
| `gifPk1` (PATH1, XGKICK do VU1) | 504.570 | 38.813 |
| `gifPk2` (PATH2, DIRECT do VIF1) | 175.249 | 13.481 |
| `dma` (chutes de canal) | 31.160 | 2.397 |

`vifMs` dividido pelas voltas da **10,4 s por quadro**, e 13 x 10,4 s = 135 s, que e o `vifMs`
inteiro. Ou seja: **o custo de uma volta do laco principal E o envio do quadro.** Nao sobra
tempo em outro lugar do laco.

E o volume por quadro e a anomalia: **67.843 primitivas e 38.813 pacotes PATH1 para uma tela de
titulo parada.** Uma arte vetorial de Flash gasta alguns milhares de triangulos, nao setenta mil.
O `swfSHAPE::Draw`/`swfINSTANCE::Update` aparecem no perfil, entao o desenho e mesmo do filme de
titulo — a duvida e por que ele custa vinte vezes o esperado.

### Alvo seguinte, com numero

Descobrir se o convidado realmente emite 68 mil primitivas por quadro ou se o nosso lado
reprocessa o mesmo pacote. O caminho PATH1 (XGKICK dentro do VU1) domina, e
`docs/RESULT_VIF1_VU1_PERF_2026-08-30.md` ja registra que o escopo do VU1 inclui o `resume` do
MSCNT sem cronometra-lo — e exatamente o tipo de lugar onde um microprograma reexecutado
apareceria como volume extra sem aparecer como bug.

Medicao barata que separa as duas: contar quantas vezes o mesmo endereco de microprograma VU1 e
iniciado por quadro. Se um punhado de microprogramas responde por dezenas de milhares de
execucoes, e reprocessamento nosso; se a contagem acompanha a variedade de pacotes, o jogo esta
mesmo mandando tudo isso.


## 9. Um inicio de microprograma VU1 por primitiva

Contadores `vu1Mscal` e `vu1Mscnt` incrementados nos dois pontos de `ps2_vif1_interpreter.cpp`
onde o VIF1 decodifica esses comandos. Corrida `probe_vu1kick_20260905`, 600 s, headless.

| medida | valor |
|---|---:|
| `vu1Mscal` | 121.950 |
| `vu1Mscnt` | **0** |
| `gifPk1` (PATH1) | 60.795 |
| `gifPk2` (PATH2) | 23.802 |
| `gsPrims` | 122.715 |

Razoes, estaveis ao longo da corrida (conferidas tambem em amostras intermediarias, 2,006):

- `vu1Mscal / gifPk1` = **2,006** — dois inicios de microprograma por pacote PATH1 entregue.
- `gsPrims / vu1Mscal` = **1,006** — **uma primitiva por inicio de microprograma.**

### Hipotese morta: o `resume` do MSCNT

`vu1Mscnt = 0` na corrida inteira. O caminho de retomada que
`docs/RESULT_VIF1_VU1_PERF_2026-08-30.md` aponta como nao cronometrado **nao e usado por este
jogo nesta tela**. Nao reabrir.

### O que sobra, e e grande

Um microprograma de VU1 existe para transformar um **lote** de vertices — dezenas a centenas de
primitivas por `MSCAL`. Aqui ele e iniciado uma vez por primitiva desenhada, 121.950 vezes em
600 s. Todo o custo fixo de uma invocacao (setup de TOP/ITOP, troca de buffer, entrada e saida
do interpretador) esta sendo pago para desenhar **um triangulo**.

Isso explica a aritmetica da secao 8 sem precisar de mais nada: 10,4 s por quadro divididos por
~38.800 pacotes dao ~268 us por pacote, na mesma ordem dos 92 us/primitiva que a otimizacao de
30/08 ja tinha medido para o escopo VIF1. O gargalo nao e por pixel nem por bit de dado: e
**por chute**.

### Como separar as duas explicacoes restantes

1. **O jogo emite mesmo um `MSCAL` por primitiva.** Plausivel para um renderizador 2D de Flash
   que troca estado por forma, ainda que extremo.
2. **O nosso VIF1 decodifica `MSCAL` a mais.** Se o parser dessincroniza, dados de `UNPACK`
   viram comandos.

Medicao que decide, uma contagem so: total de comandos VIF1 decodificados por opcode. Num fluxo
real a maioria esmagadora e `UNPACK`/`STCYCL`, com `MSCAL` esporadico. Se `MSCAL` for perto de
metade de tudo que o parser ve, o defeito e nosso e esta na sincronizacao do fluxo.


## 10. O parser esta certo: o jogo chuta o VU1 uma vez por primitiva

Contadores `vif1Cmds` (todo comando VIF1 decodificado) e `vif1Unpacks` (grupo UNPACK,
`opcode & 0x60`). Corrida `probe_vifmix_20260905`:

| medida | valor |
|---|---:|
| `vif1Cmds` | 414.976 |
| `vif1Unpacks` | 114.100 |
| `vu1Mscal` | 37.940 |
| `vu1Mscnt` | 0 |

- `MSCAL / total` = **9,1%** — longe dos ~50% que denunciariam dessincronizacao.
- `UNPACK / total` = 27,5%.
- `UNPACK / MSCAL` = **3,0 unpacks por chute**.

**Hipotese morta: "o nosso VIF1 decodifica MSCAL a mais".** A mistura tem a cara de um fluxo VIF
real. O jogo emite mesmo um `MSCAL` por primitiva, com tres unpacks de dados cada — e o
comportamento de um renderizador 2D de Flash que troca estado por forma desenhada. **Nao
reabrir.**

## 11. Modelo de custo do quadro, fechado

As reguas de fase sao inclusivas (`vifMs` contem `vu1Ms`, que contem o raster do XGKICK), entao
as fatias exclusivas saem por subtracao. Corrida `probe_isocache_20260905`, 900 s, 13 voltas:

| fatia exclusiva | total | por quadro | do custo do quadro |
|---|---:|---:|---:|
| rasterizador | 76,1 s | 5,9 s | **56%** |
| VU1 fora do raster | 30,8 s | 2,4 s | 23% |
| VIF1 fora do VU1 | 28,0 s | 2,2 s | 21% |
| **total (= `vifMs`)** | **134,9 s** | **10,4 s** | 100% |

Custos unitarios, para orientar otimizacao:

- **~86 us por primitiva** no rasterizador (881.956 primitivas em 76,1 s).
- **~100 ns por pixel** (768 milhoes de pixels em 76,1 s). Um rasterizador em software afinado
  fica em poucos ns por pixel; aqui ha uma a duas ordens de grandeza de folga.
- **~253 us por chute de VU1** fora do raster (121.950 chutes). Um microprograma pequeno deveria
  custar poucos microssegundos.

### Correcao de uma leitura anterior

Na secao 6 eu disse que o rasterizador era "9% do tempo" e portanto nao valia a pena. Os 9% eram
sobre os 900 s de parede, que incluem tudo o que as outras threads fazem. **Sobre o custo de um
quadro — que e o que trava o jogo — o rasterizador e 56%.** A conclusao anterior estava certa nos
numeros e errada no denominador.

## 12. Alvos, em ordem de retorno

1. **Rasterizador, ~100 ns/pixel.** Maior fatia (56% do quadro) e a mais folgada em relacao ao
   que a tecnica permite. Aqui esta o ganho de uma ordem de grandeza.
2. **Custo fixo por chute de VU1, ~253 us.** Com 121.950 chutes por corrida, cada microssegundo
   economizado vale 0,12 s. O caminho e `VU1Interpreter::execute` -> `run`, com orcamento de
   65.536 ciclos por chute — medir quantos ciclos um chute realmente gasta diz se o
   microprograma termina no E-bit ou corre ate o teto.
3. **Numero de chutes.** E do jogo, nao nosso, entao so cai por batching no nosso lado — ideia
   valida mas de risco alto, deixar por ultimo.


## 13. O VU1 nao tem defeito: 88 ciclos por chute, zero estouros de orcamento

Contadores `vu1Cycles` (ciclos executados pelo interpretador) e `vu1CapHits` (chutes que
esgotaram os 65.536 ciclos de orcamento), acumulados localmente e somados uma vez por chute.
Corrida `probe_vu1cycles_20260905`, 480 s, `MC3_PHASE_TIMING=1`.

| medida | valor |
|---|---:|
| `vu1Mscal` | 92.140 |
| `vu1Cycles` | 8.130.318 |
| `vu1CapHits` | **0** |
| `vu1Ms` | 18.168 |
| `vifMs` | 30.351 |
| `rasterMs` / `rasterCalls` | 3.687 / 125.442 |
| `gsPixels` | 45.039.946 |

- **88,2 ciclos por chute.** E o tamanho de um microprograma pequeno de transformacao.
- **Zero estouros de orcamento.** Todo chute termina no E-bit.

**Hipotese morta: "o microprograma corre ate o teto em vez de parar".** Nao corre. O
interpretador do VU1 nao e o gargalo: 8,1 milhoes de ciclos, a algumas dezenas de nanossegundos
cada, dao menos de meio segundo dos 18,2 s de `vu1Ms`. **Nao reabrir.**

### Onde os 18,2 s de `vu1Ms` estao, entao

`vu1Ms` e inclusivo do que o XGKICK dispara. Subtraindo o que esta medido:

| fatia | valor | por chute |
|---|---:|---:|
| `vu1Ms` total | 18,2 s | 197 us |
| interpretacao do VU1 (8,1 M ciclos) | < 0,5 s | < 5 us |
| `rasterMs` (`drawPrimitive`) | 3,7 s | 40 us |
| **restante: GIF/GS entre o XGKICK e o `drawPrimitive`** | **~14 s** | **~152 us** |

Ou seja: o maior item dentro do escopo do VU1 nao e nem o interpretador nem o laco de pixels —
e o **tratamento do pacote GIF e a preparacao de estado do GS** entre um e outro.

### Ressalva honesta sobre a secao 11

O peso relativo do rasterizador varia com o conteudo da tela. Nas duas corridas medidas:

| corrida | `rasterMs / vifMs` | us por primitiva | ns por pixel |
|---|---:|---:|---:|
| `probe_isocache_20260905` (frontend) | 56% | 86 | 106 |
| `probe_vu1cycles_20260905` (mais cedo) | 12% | 29 | 82 |

A afirmacao da secao 11 de que o rasterizador e "56% do quadro" vale para a tela do frontend
medida la, nao como constante do motor. O que se repete nas duas e a **ordem de grandeza dos
custos unitarios**: dezenas de microssegundos por primitiva, ~100 ns por pixel, com ~120 mil
chutes por corrida.

## 14. Recomendacao final do encadeamento

O gargalo nao tem um culpado unico: e **custo por primitiva espalhado por tres estagios** —
parsing VIF1, tratamento de pacote GIF/estado GS, e rasterizacao — sobre um volume de ~120 mil
chutes de uma primitiva cada. Nenhum deles tem defeito logico; todos tem folga de otimizacao.

Ordem sugerida, por retorno medido:

1. **Caminho GIF/GS entre XGKICK e `drawPrimitive`** (~152 us por chute nesta corrida). Maior
   item dentro do escopo do VU1 e o menos investigado ate agora.
2. **Rasterizador** (~29-86 us por primitiva, ~80-106 ns por pixel). Maior item na tela do
   frontend; uma a duas ordens de grandeza de folga em relacao a tecnica.
3. **VIF1 fora do VU1** (12,2 s de 30,4 s nesta corrida). Ja recebeu uma passada de otimizacao
   em 30/08 que cortou 59%; ha precedente de que responde.

**Nao mexer**: interpretador do VU1 (88 ciclos/chute), terminacao por E-bit, sincronizacao do
parser VIF1, sono de thread, tabela de callbacks de input — todos medidos e limpos.


## 15. Bug encontrado no arbitro do GIF: varredura de debug sem gate, em todo pacote

`ps2_gif_arbiter.cpp`, em `submit()` e em `drain()`:

```cpp
if (s_debugCopyArbiterSubmitCount.load(...) < 24u) {
    const bool hasCopyFrame  = containsU64(data, sizeBytes, 0x0000000002080000ull);
    const bool hasCopySource = containsU64(data, sizeBytes, 0x00000002a8120800ull);
    if ((hasCopyFrame || hasCopySource) && counter.fetch_add(1u, ...) < 24u) { ... }
}
```

Parece limitado a 24 emissoes, mas **o contador so avanca quando ha acerto**. Sem acerto ele fica
em zero para sempre, e as duas varreduras lineares do pacote inteiro rodam em **todo** pacote,
indefinidamente — duas no `submit`, duas no `drain`, **quatro por pacote**, sobre ~120 mil a 350
mil pacotes por corrida, no caminho mais quente do render. Ninguem le o resultado.

Os nomes `MC3_COPY_ARB_SUBMIT` e `MC3_COPY_ARB_DRAIN` ja eram os das linhas emitidas e ja
constavam na lista de variaveis do runtime: **o gate estava previsto e faltando**. Agora os dois
blocos so entram com a variavel ligada, lida uma vez e guardada em `static const bool`.

### Medicao, mesma receita (480 s, headless, `MC3_PHASE_TIMING=1`)

| custo unitario | antes (`probe_vu1cycles`) | depois (`probe_arbgate`) | queda |
|---|---:|---:|---:|
| `vifMs` por primitiva | 242 us | **68 us** | 72% |
| GIF/GS por pacote PATH1 (`vu1Ms - rasterMs`) | 233 us | **44 us** | 81% |
| `rasterMs` por primitiva | 29,4 us | **21,5 us** | 27% |
| `rasterMs` por pixel | 81,9 ns | **59,0 ns** | 28% |

Trabalho realizado no mesmo tempo de parede, com o jogo no mesmo ponto de boot
(`gsState=7`, `frontendTickCalls=1`, tick 23.040 contra 24.660):

| medida | antes | depois |
|---|---:|---:|
| `gsPrims` | 125.442 | **703.599** |
| `gifPk1` | 62.146 | **348.558** |
| `gsPixels` | 45,0 M | **256,0 M** |

### Ressalva honesta sobre a comparacao

A variacao entre corridas neste projeto e grande: com binarios da mesma familia, a
`probe_isocache_20260905` custou 153 us por primitiva e a `probe_vu1cycles_20260905` custou 242
us. Medido contra a **melhor** base anterior em vez da imediatamente anterior, a queda fica em:

| custo unitario | melhor base anterior | depois | queda |
|---|---:|---:|---:|
| `vifMs` por primitiva | 153 us | 68 us | 56% |
| GIF/GS por pacote PATH1 | 61 us | 44 us | 28% |
| `rasterMs` por pixel | 106 ns | 59 ns | 44% |

Ou seja: o ganho e real e maior que a faixa de ruido observada, mas o numero honesto e
**"entre 28% e 81% conforme a regua e a base"**, nao o melhor caso isolado. Uma comparacao
definitiva exigiria relinkar o binario anterior e alternar as duas corridas, o que nao foi feito.

**O jogo continua parando no mesmo lugar.** Isto e ganho de throughput, nao destrave: `gsState`,
`frontendTickCalls` e a fase de boot sao identicos nas duas corridas.
