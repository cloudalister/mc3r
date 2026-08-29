# Resultado: input host publicado no DMA PADMAN

Data: 2026-08-26

## Resultado

O estado de controle que o runtime ja produz em `Pad.cpp` agora alimenta o mesmo
`pad_data_new` double-buffered que a implementacao guest de `scePadRead@0x543ED8` le.

```text
teclado/gamepad/backend host
  -> samplePadInputPacket
  -> bloco PADMAN mais antigo
  -> frame = max(frame0, frame1) + 1
  -> scePadRead guest
```

Os bytes de botoes continuam active-low. Enter e
`GAMEPAD_BUTTON_MIDDLE_RIGHT` retiram o bit `1 << 3`, correspondente a START.

## Implementacao

- O OPEN PADMAN registra a mesma porta no produtor de input host.
- Cada lookup real de `ioPad::Attach@0x238030` publica um pacote novo no bloco com frame
  mais antigo, preservando `length=32`, `state=6`, `reqState=0` e `currentTask=1`.
- O runtime ganhou telemetria passiva `padmanPublishes` e `padmanStartPublishes`.
- Um START publicado tambem gera `[boot-trace:mc3-padman-input]` quando o boot trace esta
  ativo.
- Nao houve mudanca de scheduler, semaforo, RPC completion ou estado guest artificial.

## Prova automatizada

O teste `PADMAN input bridge preserves active-low START` abre uma area PADMAN real de
0x100 bytes, injeta START somente pelo override de teste, executa o publisher e comprova:

```text
buttons bit 3 = 0
packet id      = 0x73
frame          = 3 (buffers iniciais 1/2)
length         = 32
state          = 6
publishes      = 1
startPublishes = 1
```

Build incremental OK, fast relink OK e suite completa limpa **293/293**. A falha
intermitente de `sceGsSyncV waits on VBlank` desapareceu quando o PCSX2 foi pausado;
nao pertence ao teste PADMAN. O PCSX2 retail foi pausado e retomado pelo MCP, sem fechar
a sessao.

## Limite da prova atual

O probe deterministico atual, mesmo com budget de 600000, nao repetiu a profundidade do
checkpoint anterior dentro da janela de 45 s: executou GET_MODVER/INIT/OPEN, mas nao
chegou novamente a `ioPad::Attach`. Um segundo teste visivel ficou vivo ate o tick 10320,
com `frameMode=0`, `ioPadAttachCalls=0`, `gifPkTotal=0` e `gsPrims=0`; portanto o Enter
manual ainda nao tinha consumidor guest. Este lote comprova o transporte host -> DMA em
regressao real, mas ainda nao comprova uma transicao visual do frontend causada por START.

## Proximo gate

Executar o runner nativo visivel ate o frontend, pressionar START uma vez e exigir no
mesmo trace:

```text
padmanStartPublishes > 0
guestPadReadCalls    > 0
e uma mudanca de estado/frontend posterior ao frame do START
```

Sem esses tres sinais, nao declarar a transicao fechada.

## A/B causal: registro host antes do Attach

Foi executado um A/B deterministico com o PCSX2 pausado, budget 600000 e janela de
45 s. O A removeu somente os efeitos host que ocorrem antes de `ioPad::Attach`
(`resetPadInputPorts` e `openPadInputPort`), preservando o dispatcher PADMAN e a area DMA
guest. O B restaurou a ponte completa.

| Metrica final | A: sem registro host | B: ponte completa |
|---|---:|---:|
| tick | 2580 | 2580 |
| guestPadPortOpenCalls | 2 | 2 |
| ioPadAttachCalls | 0 | 0 |
| ioPadPollCalls | 0 | 0 |
| guestPadReadCalls | 0 | 0 |
| padmanPublishes | 0 | 0 |
| frameMode | 0 | 0 |
| gifPk1/2/3 | 0/0/0 | 0/0/0 |
| gsPrims / gsPixels | 0/0 | 0/0 |

Logs preservados:

- `work/logs/padman_ab_A_no_host_registration.log`
- `work/logs/padman_ab_B_host_bridge.log`

Conclusao comprovada: os efeitos de registro/reset da ponte host antes do Attach nao
causam o bloqueio atual. As duas variantes concluem os dois OPENs e param no mesmo gate,
antes de `ioPad::Attach`; por isso o publisher dinamico nem chega a executar. O bloqueio
atual deve ser isolado no corredor entre o retorno dos OPENs e o primeiro update/Attach.
O comportamento dinamico da ponte durante um Attach vivo continua comprovado apenas pela
regressao automatizada ate esse corredor voltar a ser atingido no runner.

## Atualizacao: budget completo

O limite acima era da janela de parede de 45 s, nao um bloqueio do guest. Um probe com o
mesmo budget 600000 e timeout suficiente terminou naturalmente com `ioPadAttachCalls=10`,
`ioPadPollCalls=8`, `guestPadReadCalls=8`, `padmanPublishes=20`, fases `7,7,0,0` e render
ativo. A captura nativa reconhecivel esta documentada em
`docs/RESULT_NATIVE_FRAME_2026-08-26.md`.

## A/B visivel: tap curto de START

O runner nativo visivel foi executado com budget 900000. A tela legal ficou clara e
animada enquanto o corredor PADMAN permaneceu ativo:

```text
padmanPublishes      = 260
guestPadReadCalls    = 128
gsPrims              = 177255
gsPixels             = 64014311
padmanStartPublishes = 0
```

Depois de observar a tela completa, um unico Enter real foi enviado para a janela do
runner. A imagem continuou normalmente, mas o trace terminou com
`padmanStartPublishes=0` e sem `[boot-trace:mc3-padman-input]`. Portanto o tap nao chegou
ao pacote PADMAN e nenhuma transicao pode ser atribuida a ele.

O codigo explica o resultado: o teclado usa `IsKeyDown(KEY_ENTER)` somente quando
`samplePadInputPacket()` e chamado pelo publisher PADMAN. No runner instrumentado, um tap
host curto pode terminar entre duas dessas amostras. O proximo passo correto e preservar
o evento host ate a proxima amostragem real; nao e injetar estado guest, semaforo ou gate
semantico.

## Prova manual completa: dois apertos de START

Depois que o backend host passou a preservar a borda do Enter ate a proxima amostragem
PADMAN real, Cloud pressionou Enter duas vezes no runner nativo visivel. O trace
`work/logs/14_run_boot_trace.log` fechou a cadeia inteira:

```text
host Enter
  -> PADMAN active-low START
  -> scePadRead guest @ 0x543ED8
  -> ioPad::Poll @ 0x238368
```

Leituras guest observadas:

```text
read=69  data2=0xf7 data3=0xff start=1
read=73  data2=0xf7 data3=0xbf start=1
read=74  data2=0xf7 data3=0xbf start=1
```

O byte `0xF7` comprova o bit active-low de START limpo. O PADMAN publicou START cinco
vezes (`padmanStartPublishes=5`) e `scePadRead` terminou com 132 chamadas. A traducao de
`ioPad::Poll` tambem esta comprovada estaticamente: os bytes sao armazenados em
`ioPad+0x142/+0x143`, combinados e invertidos, produzindo o bit ativo `0x0800` em
`ioPad+0x17C`.

Nao houve transicao posterior ao input: `frameMode=3`, `enterFrontendCalls=1`,
`setFrontendCalls=2` e `layerTransitionCalls=3` permaneceram iguais. O render continuou
vivo e forte (`gsPrims=182696`, `gsPixels=65940218`). Portanto teclado, fila host,
PADMAN, DMA, `scePadRead` e conversao basica de `ioPad` deixaram de ser o bloqueio.

Proxima fronteira causal: identificar o consumidor do bit `0x0800` durante a primeira
tela legal do frontend e provar por que ele nao solicita a transicao. Nao controlar o PC
do usuario; quando outro A/B manual for necessario, abrir somente o runner autorizado e
pedir a Cloud para pressionar a tecla.

## Instrumentacao preparada para o proximo A/B

A analise estatica fechou o primeiro consumidor direto do estado produzido por
`ioPad::Poll`: `uiInput::Update@0x420F38` chama
`uiInput::CheckKeysAndPadsForBasicNavigation@0x4215A0`, e esta funcao le
`ioPad+0x17C`. O leitor raw `uiInput::IsKeyPressedRaw@0x421278` opera depois, sobre o
estado mantido por `uiInput`.

Foram adicionadas somente tres sondas passivas e limitadas:

```text
[boot-trace:mc3-iopad-state]    produtor de ioPad+0x17C
[boot-trace:mc3-uiinput-update] entrada de uiInput::Update
[boot-trace:mc3-uiinput-pad]    leitura de ioPad+0x17C por 0x4215A0
```

Os tres objetos foram recompilados, o fast relink passou, `find_stale.py` terminou com
`Missing=0` e `Stale=0`, e a suite oficial passou **293/293**. Nenhuma janela foi aberta
nesta etapa. O proximo runner visivel deve ser iniciado somente com autorizacao, e Cloud
deve pressionar Enter quando solicitado.

O trace resultante resolve o ramo causal sem chute: ausencia de
`mc3-uiinput-update` prova que a tela nao chama esse pipeline; update sem leitura START
isola filtragem/desvio anterior; leitura `mc3-uiinput-pad start=1` sem transicao move a
fronteira para os consumidores posteriores ou para um gate legitimo do frontend.

## Correcao de rota: frontend action translator

O A/B visivel e uma captura retail no PCSX2 provaram que a tela legal/titulo nao usa
`uiInput::Update@0x420F38` para START. O primeiro leitor real depois do filme e
`sub_00234D58@0x234D58`, chamado por `sub_0020BA88@0x20BA88`:

```text
ioPad+0x17C
  -> 0x234F68: le estado agregado do controle
  -> binding offset 0x18, mask 0x0800
  -> 0x2356BC: publica intensidade 255 no byte da acao
  -> 0x20BBDC: compara estado atual/anterior
  -> 0x20BBF4: publica borda no frontend, indice 6
```

No retail, um watchpoint de leitura em `0x006BB57C` parou primeiro em `0x234F68`, com
backtrace `0x234D58 -> 0x20BA88 -> 0x20ACD0 -> 0x320B38 -> 0x1AB188`. O objeto de acao
retail continha a mascara START em seu binding 6 e o output correspondente em
`0x007D6140`. O leitor seguinte foi `0x20BBDC`, que detecta a mudanca do bit alto e
publica o evento no byte `frontend+0x0C`.

O runner nativo confirmou a mesma cadeia em uma unica amostra real:

```text
[mc3-padman-input] buttons=0xfff7 start=1
[mc3-iopad-state]  buttons=0x00000800 start=1
[mc3-frontend-action] mask=0x00000800 buttons=0x00000800
[mc3-frontend-action-output] bindingOffset=0x18 old=0 new=255
[mc3-frontend-action-edge] state=frontend+0x0C index=6 current=255 previous=0
```

Portanto START nao para mais em PADMAN, `ioPad` ou no tradutor de acoes: ele e
reconhecido e convertido em uma borda de frontend real. Mesmo assim o runner terminou
com `frameMode=3`, `layerTransitionCalls=3` e `uiInputUpdateCalls=0`, sem transicao. A
nova fronteira e o consumidor legitimo de `frontend+0x0C` na tela legal/titulo.

Validacao do lote: exatamente dois objetos de telemetria passiva foram recompilados,
fast relink OK, suite oficial **293/293**, `Missing=0` e render valido
(`gsPrims=171801`, `gsPixels=62003494`). Nenhum scheduler, semaforo, RPC, input guest ou
gate semantico foi alterado.

## Segunda correcao de rota: START nao e o gate da tela legal

A tela `PRESS START BUTTON` existe depois da tela legal. No retail ela foi observada e
um Enter avancou normalmente, mas um breakpoint condicional no consumidor
`frontend+0x0C` nao disparou nessa passagem. Assim, a borda START comprovada acima e
real, porem nao explica a permanencia anterior na tela legal.

As strings retail `StartOfTransitionOut` (`0x006394C8`) e
`EndOfTransitionOut` (`0x006394DD`) fecharam o gate automatico correto:

```text
0x1AAB90 -> 0x1AAC70 -> 0x1AC238
  startRequested != 0 -> 0x320848 grava StartOfTransitionOut
  0x320A88 le EndOfTransitionOut
  retorno final = (EndOfTransitionOut == 1)
```

No mesmo `0x1AC238`, com o mesmo slot `0x01EA6040` e objeto `0x01EA6310`, o
retail entrou com `startRequested=1`; o nativo entrou repetidamente com
`startRequested=0`. Portanto o nativo nem chega a armar o evento, e nao esta esperando
incorretamente o retorno de `EndOfTransitionOut`.

O carregador legal nativo tambem foi comprovado: `FUN_001aadb8@0x1AADB8` terminou com
workers validos (`0xD5`/`0xD4`) e screen `0x01EA6040`, imediatamente antes de publicar
o byte `loadPending` em `state+0x4005`.

Uma segunda captura retail fechou a rota automatica correta. O retorno salvo na pilha
provou o chamador exato:

```text
FUN_001a5b08 @ 0x1A5FD0
  -> sub_001AAB08
  -> sub_001AA9B8: le loadPending == 1
  -> FUN_001AAE80: publica startRequested = 1 e encerra os workers
  -> 0x1AC238: arma StartOfTransitionOut
```

No retail, imediatamente antes de `FUN_001AAE80`, os bytes eram
`startRequested=0/loadPending=1`, e o retorno era `0x1AA9E4`. A rotina
`sub_001AAE28` e outra escrita legitima de `startRequested`, mas nao participou dessa
passagem automatica.

No nativo longo, `mc3-legal-load-ready` apareceu uma vez e `startRequested=0` apareceu
em todas as 64 amostras limitadas, mas nao houve nenhuma entrada em `sub_001AA9B8`,
`FUN_001AAE80` ou `sub_001AAE28`. A nova fronteira e, portanto, anterior: provar por que
o ciclo de vida nativo nao chega ao cleanup `0x1A5FC0/0x1A5FD0` de
`FUN_001a5b08`. Isso substitui a hipotese anterior de START ignorado, sem mudar
scheduler, semaforo, input guest ou gate semantico.

O probe de estagios seguinte estreitou esse lifecycle. `FUN_001a5b08` entra uma vez com
`a1=7` e percorre:

```text
0x1A5E18 -> 0x1A5E4C
  -> FUN_001AAA38 cria/carrega legal
  -> 0x1A5E54 -> 0x1A5E6C -> 0x1A5E74 -> 0x1A5E88
```

O loader termina entre `0x1A5E4C` e `0x1A5E54`, mas nenhuma amostra alcanca
`0x1A5ECC`, `0x1A5F08` ou `0x1A5FC0`. A fronteira atual ficou reduzida ao corredor
`0x1A5E88..0x1A5ECC`: retorno booleano de um metodo virtual, possivel caminho por
`sub_001A97D0`, lookup por `FUN_001A97C0`, outro metodo virtual e
`FUN_001A9828`. O proximo A/B deve comparar os valores/targets desse corredor no retail
e no nativo; ainda nao existe base para forcar nenhum retorno.

Validacao final deste lote: suite oficial **293/293**, fast relink com **15.827**
funcoes registradas e `find_stale.py` com `Missing: 0` / `Stale: 0`. O ultimo run
nativo longo manteve render real (`gifPk1=87815`, `gifPk2=34382`,
`gsPrims=177255`, `gsPixels=64014311`). O PCSX2 retail ficou pausado em
`0x001AAE80`, sem breakpoints nem watchpoints restantes.

## A/B interno do lifecycle legal - 11:30

A leitura 128-bit do debugger foi corrigida: o low word aparece primeiro. Retail e
nativo retornam `0` no metodo virtual `0x5B9080` e seguem o mesmo ramo alternativo.
Ambos usam a vtable `0x006238F8`, cujo slot `+0x10` aponta para `0x001A8EC0`.

No retail, breakpoints fecharam a passagem inteira por **42 continuations** de
`0x1A8EC0`, retornando normalmente a `0x1A5EBC`. No nativo, o prefixo coincide ate
`0x1A9010`; a chamada seguinte segue:

```text
0x1A9020 -> 0x42E810 -> 0x430CF8
  -> 0x430D4C -> 0x430D64 -> 0x430D74
  -> 0x430D98 chama 0x42E668
```

O nativo nao retorna de `0x42E668` para `0x430DA0`. Essa rotina e o wrapper de
alocacao alinhada: quando o callback global em `0x006D59CC` e nulo, ela usa
`0x3B1630`; caso contrario, chama o callback indireto. O proximo A/B deve limitar o
trace ao caller `ra=0x430DA0` para distinguir esses dois caminhos sem alterar a
semantica.

Fast relink OK, `find_stale.py` com **15.827 objetos**, `Missing: 0` e `Stale: 0`.
O probe de 600k manteve render real (`gifPk1=5828`, `gifPk2=2561`,
`gsPrims=11797`, `gsPixels=4435515`). Uma nova captura do runner nativo foi salva em
`work/captures/native_legal_2026-08-26_1130.jpg`.

## Fechamento headless do allocator e aliases 0x5C

O trace condicionado ao caller `ra=0x430DA0` confirmou `0x006D59CC=0` e o
caminho fallback `0x42E668 -> 0x3B1630 -> 0x3AFE40`. A aparente falta de retorno
era o limite curto do probe: `0x42E6F0` preenchia `0x0087C6F0` bytes com o padrao
`0xCDCDCDCD`. Com 2.000.000 despachos, o caminho retornou por
`0x3B01D8 -> 0x3B0244 -> 0x3B027C -> 0x3B16B4 -> 0x42E68C -> 0x42E6AC ->`
`0x430DA0`, seguido por outras alocacoes legais completas.

Depois desse retorno, o runner revelou dois alvos indiretos ausentes no registro:
`0x5C3A40` e `0x5C5720`. Ambos ja existiam como instrucoes reais no owner
`sub_005C2880`; faltavam somente cases de entrada e aliases no registro parcial.
Os cases reais foram adicionados, o registro foi regenerado e o fast relink passou.

O probe posterior de 2.000.000 despachos nao produziu warning/erro para
`0x5C3A40`, `0x5C5720` ou `0xCDCDCDCD`. O ultimo frame completo registrou
`gifPk1=349909`, `gifPk2=137141`, `gifPkTotal=487050`, `gsPrims=706326` e
`gsPixels=256961446`, satisfazendo o gate estrutural de render real.

O snapshot final ficou repetidamente em `0x322FFC`, continuation de
`FUN_00322fd8` logo apos a chamada a `0x3451E8`, com sete threads ativas. Isso
ainda pode ser uma fronteira normal de frame, nao uma falta de retorno comprovada.
O proximo probe deve contar entradas/retornos esparsos em `0x322FD8`, `0x322FFC`,
`0x32300C` e `0x3451E8`, preservando scheduler e sem forcar resultado.

Validacao final: suite oficial **293/293**; `find_stale.py` com **15.827 objetos**,
`Missing: 0` e `Stale: 0`; fast relink OK. Todo este lote foi executado headless,
sem controlar desktop, PCSX2 ou runner visivel.

## 0x322FFC descartado e proxima continuation isolada

A telemetria passiva posterior provou a sequencia
`0x322FD8 -> 0x3451E8 -> 0x3454C4 -> 0x322FFC -> 0x323010`. Assim,
`0x3451E8` retorna normalmente ao caller e o snapshot repetido em `0x322FFC` nao
representava um travamento. Os calls virtuais observados nesse caminho resolveram
para `0x33A5A0`, `0x41F550` e `0x33A4B0`.

Durante tres probes longos foram encontrados e expostos **22** PCs que ja eram
instrucoes reais dentro de owners gerados, sem criar stubs ou alterar semantica:

```text
0x5CCC98
0x2B9908 0x31EDE0 0x4D92E0 0x519528 0x5B9380 0x5B9390
0x5BEF98 0x5CC948 0x5CC958 0x5CC968 0x5E5BF8 0x5E9080
0x209008 0x33A4B0 0x383C88 0x586218 0x5BA5C0
0x5CC950 0x5CCE58 0x5CCE70 0x5E8850
```

O registro parcial passou de **168.333** para **168.355 aliases**. Na validacao
consolidada solicitada para 2.000.000 despachos, o wrapper atingiu o timeout de
600 s antes do budget; ate o encerramento houve zero `first-bad-pc`, `recover-pc`
ou alvo ausente. O resultado nao deve ser descrito como conclusao dos 2 milhoes.

O ultimo frame completo registrou `gifPk1=348558`, `gifPk2=136612`,
`gifPkTotal=485170`, `gsPrims=703599` e `gsPixels=256036663`. Suite oficial
**293/293**, fast relink OK, `Missing: 0`, `Stale: 0` e `git diff --check` limpo.

A proxima duvida causal e se a chamada `0x323024 -> 0x320B38` retorna a
`0x32302C`. Contadores passivos nas continuations seguintes ate `0x3230E8` ja
foram compilados, mas ainda nao executados em novo probe longo. Nao houve retorno
forcado, gate semantico, mudanca no scheduler ou uso do desktop/PCSX2.

## Fronteira interna de 0x320B38 preparada

Um novo probe deterministico, solicitado para 2.000.000 despachos e limitado a
600 s, alcancou novamente `0x323010`, mas nenhuma continuation em `0x32302C` ou
posterior. O wrapper encerrou pelo timeout, sem concluir o budget. Nao houve
`first-bad-pc`, `recover-pc` ou alvo ausente; o render permaneceu em
`gifPkTotal=485170`, `gsPrims=703599` e `gsPixels=256036663`.

Isso move a fronteira causal para dentro da chamada direta
`0x323024 -> 0x320B38`. A auditoria estatica mostrou que `0x320B38` entra primeiro
em `0x320C60`; a primeira cadeia interna relevante deste callee e
`0x42CC80 -> 0x42CA90 -> 0x42AAF8`. Os calls seguintes tambem sao diretos e tem
continuations locais conhecidas.

Foi compilada telemetria passiva de entrada/continuation em `FUN_00320b38`,
`FUN_00320c60`, `FUN_0042cc80`, `FUN_0042ca90` e `sub_0042AAF8`. O proximo probe
longo podera distinguir qual call deixa de voltar, sem mudar o resultado guest.
Essa nova telemetria ainda nao foi exercitada.

Validacao: cinco objetos compilados, fast relink com **15.827 funcoes**,
**168.355 aliases** e **0 stubs ausentes**, suite oficial **293/293** e
`git diff --check` limpo. Execucao inteiramente headless, sem PCSX2 ou controle do
desktop, sem SignalSema injetado, retorno forcado ou mudanca no scheduler.

## A espera de 10 ms que nao desperta

O probe condicionado ao caller real fechou a cadeia posterior em termos de
subsistemas:

```text
objeto do frontend
  -> cleanup do objeto e DeleteSema OK
  -> destruidor do pool encontra uma pendencia
  -> pede uma espera de 10 ms
  -> gerenciador interno de alarmes arma callback
  -> WaitSema nao recebe o despertar
```

Tecnicamente, a passagem foi
`0x323024 -> 0x320B38 -> 0x320C60 -> 0x42E8A0 -> 0x430C90 -> 0x4323E8`.
`PollSema(0x2E8)` e `DeleteSema(0x2E8)` retornaram, descartando o semaforo do
objeto como causa. O pool em `0x006771E0` resolveu o bloco `1`, cuja entrada
`0x006771F0` tinha `+0x0C = 1`.

Ao encontrar essa pendencia, `0x4323E8` chama `0x398C60(10)`. A espera cria o
semaforo temporario `0x2EB`, agenda o callback `0x5476D0` pelo gerenciador
`0x54D6A0` e entra em `WaitSema` a partir de `0x5476A8`. O callback, que deveria
chamar `iSignalSema`, nao foi observado, e a continuation `0x432458` nunca foi
alcancada. Uma segunda thread bloqueou na mesma familia com `0x2ED`.

Isso ainda nao prova que o contador do pool esta errado: o bloqueio imediato e
anterior a nova consulta do contador, no mecanismo de timer/despertar. Tambem nao
e uma operacao direta de GS, video, audio ou input. A cadeia de filme continua
posterior; os contadores permaneceram em `enterMovieCalls=3`, `setMovieCalls=3` e
`introActive=0`.

O run de 720 s foi headless, com prioridade `BelowNormal`, e terminou pelo timeout
do wrapper antes do budget pedido de 2.000.000. Render permaneceu positivo:
`gifPkTotal=485170`, `gsPrims=703599`, `gsPixels=256036663`. O proximo teste deve
seguir o agendamento/tick/interrupt de `0x54D6A0` ate a entrega de `0x5476D0`,
sem SignalSema manual, sem retorno forcado e sem mudanca do scheduler.

## Timer2 e pool de semaforos liberam o frontend legal

O corredor de espera foi fechado. Timer2 pertence ao kernel da EE/CPU: ele mede o
tempo guest e gera a interrupcao `INTC_TIM2` (cause 11); nao renderiza imagem e nao
decodifica filme. A implementacao passou a expor COUNT/MODE/COMP, avancar o
BUSCLK/256 por VBlank e despachar o handler quando compare/overflow vence. Threads
novas herdam o bit EIE do COP0, que autoriza a entrega da interrupcao.

O A/B registrou a cadeia real repetidamente:

```text
wait-enter status=0x00010000
alarm-armed sema=N
Timer2 IRQ
callback sema=N
wait-woke sema=N
```

Depois desse avanco, a request SIF 4 revelou outro problema independente. IDs de
semaforo cresciam ate `87077`, e a resposta assincrona nao encontrava mais o
objeto para acordar a thread (`signaled=0`). O kernel PS2 tem pool finito de 256;
`CreateSema` agora procura um ID livre em `1..256`, reciclando entradas removidas
por `DeleteSema`. O teste de regressao executa 1.024 ciclos de create/delete,
mantem todos os IDs dentro do limite e confirma que o sinal de compatibilidade
alcanca o ultimo objeto vivo. A mesma request passou a registrar `signaled=1`.

Em termos de subsistema, esses semaforos sao IDs do kernel da EE que conectam
produtores assincronos (timer ou resposta RPC/SIF) a threads guest em espera. Eles
nao sao memoria de video; a GS so aparece depois, como consumidora do trabalho que
essas threads finalmente conseguem continuar.

## Imagem comprovada e nova fronteira

O jogo passou a criar 5/7 threads, enviar DMA/VIF e alimentar a GS. A captura
`work/captures/mc3_timer2_sema_render_20260826.png` mostra a tela legal/logo de
Midnight Club 3 DUB Edition Remix. No dump exato: `gifPk1=16212`, `gifPk2=6345`,
`gifPkTotal=22557`, `gsPrims=32724`, `gsPixels=11351546`; portanto o gate
`gifPkTotal>0 && gsPrims>0` foi satisfeito visual e numericamente.

O lifecycle agora completa todas as etapas internas de `FUN_001A9828`, retorna a
`0x1A5F88`, chega a `0x1A5FB4` e executa cleanup em `0x1A5FC0`. Em seguida,
`StartOfTransitionOut` retorna `3`, mas `EndOfTransitionOut` permanece `0`.
`0x320A88` e apenas o consumidor/consulta: chama `0x20B1D0` e devolve o estado do
objeto. O proximo bloqueio e descobrir qual updater por frame deveria publicar o
estado final e por que ele nao o faz.

Instrumentacao minima seguinte: registrar objeto/slot e `startRequested` em
`0x1AC238`, retornos de `0x320848/0x320A88` e objeto/valor produzido em
`0x20B1D0`. Se o start continuar em `3` e o objeto nao mudar entre frames, seguir
o produtor/worker do estado; nao alterar o consumidor nem forcar conclusao.

Validacao consolidada: **297/297 em cinco execucoes consecutivas**, fast relink
OK, **15.827 objetos**, `Missing: 0`, `Stale: 0`. A suite tambem foi endurecida
contra o atraso legitimo do worker wall-clock de VBlank: SyncV agora e testado
contra a janela de ticks que realmente pode ter acordado a chamada, e o runtime
captura o tick de entrada antes de iniciar um worker novo. Sem `SignalSema`
injetado, retorno forcado, gate semantico ou mudanca do scheduler.

## Comparacao exata do estado de transicao

Dois probes adicionais reduziram a fronteira. No nativo, a busca de
`EndOfTransitionOut` resolve sempre para o mesmo registro:

```text
object   = 0x01EBB660
property = 0x01ECB164
raw      = 0
type     = 3
converted= 0
```

Enquanto isso, o unico setter observado no objeto foi o proprio pedido de inicio:

```text
name     = 0x006394C8  (StartOfTransitionOut)
property = 0x01ECB154
old/new  = 1 -> 1
type     = 3
caller   = 0x00320864
```

Portanto a propriedade final nao esta ausente, com tipo errado ou sendo lida do
objeto errado. Ela existe e permanece zero; nenhuma chamada ao setter generico do
mesmo objeto a atualizou durante a janela observada.

Para comparar com o oraculo, o savestate retail de 26/08/2026 foi carregado no
PCSX2 via Pine, somente leitura. O layout bateu nos enderecos relevantes:

```text
slot retail 0x01EA6040 -> 0x01EA6310
0x01ECB154 StartOfTransitionOut = 1, type 3
0x01ECB164 EndOfTransitionOut   = 1, type 3
```

Essa e agora a diferenca comprovada: no retail o produtor publica End=1; no
nativo ele nao roda ou nao conclui. O PCSX2 instalado expoe Pine, mas nao o
DebugServer 21512, entao o PC exato do writer retail ainda nao foi capturado.
Proximo passo: encontrar o update/script por frame dono desse objeto e comparar a
chamada que grava `0x01ECB164`; nao mexer em `0x320A88` e nao escrever `1`
manualmente.

Evidencia: `work/logs/14_run_boot_trace_transition_property_read_20260826.log` e
`work/logs/14_run_boot_trace_transition_setters_20260826.log`. O run mais recente
continuou renderizando ate `gifPk1=137802`, `gifPk2=53955`, `gsPrims=278154` e
`gsPixels=101075598`.

## Estrutura do estado e proximo owner

O probe seguinte mostrou que Start e End sao dois nos consecutivos de 16 bytes
na mesma tabela do contexto de UI/script. Start esta em `0x01ECB154` e End em
`0x01ECB164`; ambos tem tipo 3 e links validos. O cabecalho do contexto
`0x01EBB660` tambem continua mudando entre frames, enquanto seus ponteiros
internos permanecem estaveis. Em linguagem direta: a tela e seu sistema de
script estao vivos; falta uma acao especifica sinalizar que a transicao acabou.

A busca de callers nao encontrou segundo setter direto para End. O metodo virtual
de `FUN_001AB130` tambem nao foi chamado na janela em que a transicao foi armada.
O menor proximo corredor agora e o ramo alternativo de update carregado de
`state+0x4008`: `0x1AC348 -> 0x3A1400` e o alvo virtual chamado em `0x1AC384`.
Esse ramo conversa com o objeto visual/script antes da consulta de End; capturar
seu alvo e suas continuations deve revelar o callback faltante sem escrever o
valor manualmente.

Evidencia: `work/logs/14_run_boot_trace_transition_layout_20260826.log`. O run foi
headless e em prioridade `BelowNormal`; no ultimo frame amostrado havia
`gifPk1=60795`, `gifPk2=23802` e `gsPrims=122715`.

## Por que o updater da tela nao chega a rodar

O campo `state+0x4008` nulo nao e defeito. A tela foi criada em `mode=4`, e os
modos 3/4/5 deliberadamente nao recebem esse overlay opcional. O objeto real da
tela permanece em `state+0x4014` e deveria ser atualizado por `0x1AB130`.

O bloqueio acontece antes: ao armar a saida, `0x1AAE80` termina corretamente a
liberacao opcional em `0x1AB078`, mas para em `0x398B18`, um `WaitSema` do
worker0. O retorno `0x1AAEA8` nunca aparece, logo o dispatcher da tela nao recebe
controle e o script nao tem oportunidade de publicar `EndOfTransitionOut=1`.

Esse semaforo pertence a thread loader iniciada em `0x1AAB60`. O corpo do worker
e `0x1AAB90`; seu final normal chama `0x1AAC54 -> 0x398B40 -> SignalSema`.
Portanto o proximo alvo e localizar a ultima continuation alcancada dentro de
`0x1AAB90`, especialmente o loop `0x1AABE0..0x1AABF4`. Nao sinalizar o semaforo
manualmente: primeiro provar qual dependencia impede o worker de chegar ao fim.

Evidencia principal:
`work/logs/14_run_boot_trace_transition_worker0_wait_20260826.log`.

## Update da tela legal: timeline e acoes comprovadas

A hipotese de que o updater da tela nao rodava foi corrigida com evidencia
dinamica. O worker legal esta vivo e usa este caminho:

```text
1AAB90 -> 1AAD28 -> 1AC2A0 -> 320B38
       -> 20ACD0 -> 20B538 -> 20D260
       -> 20FA18 -> 20D3A8 -> 20C248
```

A arvore de update visita 26 nos. Onze containers estao ativos e todos chamam
`0x20C248`. Cada um possui uma animacao valida de um unico quadro
(`frame=0`, `frameCount=1`), logo nao existe um segundo quadro para avancar.
Isso explica por que a rota de troca `20C190 -> 20FA88 -> 211660` nao aparece;
nao prova travamento do relogio.

As acoes do quadro zero rodam por `20FA18 -> 211610`. Os targets observados
foram `0x212D70`, `0x212F60`, `0x213058` e o no-op retail `0x5BA3D0`. Eles
manipulam a apresentacao/nos, mas nao chamam o setter de propriedades e nao
tocam `EndOfTransitionOut`. Em termos simples: a tela e suas animacoes estao
vivas; o item logico que deveria anunciar "terminei" nao esta na lista
executada.

O proximo alvo e a montagem/avaliacao dessa acao logica na raiz
`0x01EBB660`. A diferenca de controle mais estreita esta em `0x320B38`: o
worker passa `a2=0`, atualiza a arvore e pula `0x20B290`; os callers normais do
frontend passam `a2=1` e atravessam esse processamento. Isso deve ser medido,
nao invertido por chute.

Logs: `work/logs/14_run_boot_trace_transition_timeline_20260826.log` e
`work/logs/14_run_boot_trace_transition_action_routes_20260826.log`.
Instrumentacao somente passiva; sem sinal de semaforo, retorno forcado, gate
semantico ou alteracao do scheduler.

## Comparacao retail/native e vigia do End (2026-08-27)

O corredor `a2=0` foi descartado como causa. `0x20B290` consulta
`readyformenu` e devolve um booleano ao controle de UI; nao publica End. A
comparacao offline com `resume.p2s` mostrou algo mais forte: antes da transicao,
retail e nativo possuem a mesma lista de acoes nos mesmos enderecos. Inclusive
ambos possuem zero instancias da vtable de `InitAction` (`0x00624B48`). Portanto
o elemento faltante nao e um modelo, frame ou acao visual que deixou de carregar.

Tambem foram varridas as instrucoes do ELF que constroem os enderecos das
strings `StartOfTransitionOut` e `EndOfTransitionOut`. Todas ficam em
`0x1AC25C..0x1AC274`: essa funcao escreve Start e somente le End. A mudanca de
End no retail precisa vir de uma escrita indireta/VM.

Para testar isso sem alterar a semantica guest, o runtime foi compilado
temporariamente com sua vigia generica apontada para
`0x01ECB164..0x01ECB167`. Em 165 segundos, com a transicao ativa e End lido
varias vezes como zero, houve **zero escrita** no intervalo. O render permaneceu
valido e forte (`gifPkTotal>0` e `gsPrims>0`; amostra intermediaria:
`gifPk1=59444`, `gifPk2=23360`, `gsPrims=120020`). A configuracao da vigia foi
restaurada depois da captura.

Conclusao causal: o produtor de End nao esta executando. O proximo owner e o
callback/VM de ciclo de vida que recebe Start e inicia a conclusao/teardown da
tela, fora das listas de acoes visuais ja comprovadas iguais ao retail.

Evidencia: `work/logs/14_run_boot_trace_end_watch_20260827.log` e
`work/captures/mc3_legal_native_heap_20260827.bin`.

## Fechamento da transicao legal e nova fronteira (2026-08-27)

O suposto produtor ausente foi localizado dentro dos scripts ActionScript do
proprio `ASSETS.DAT`, executados pelo interpretador AVM1 em `0x211770`. A tela
usa dois scripts de frame em sequencia:

```text
0x01EBAA24: n++ -> rola texto -> scrollstatus=1 perto de n=490
0x01EBAB7C: Start=1 + scrollstatus=1 -> 27 ciclos de fade -> End=1
```

Os valores ativos explicam o tempo: `increment=1.1`, `siseoftext=650`, logo a
condicao e `1.1 * (n - 3) > 535`. Um probe passivo e esparso acompanhou os
marcos do contador. `scrollstatus` mudou de zero para um sem intervencao e,
depois do fade, `EndOfTransitionOut` tambem mudou para um. A conclusao anterior
de produtor ausente vinha de testes curtos demais para a velocidade atual do
runner parcial; VM, script e publicacao de End estao funcionais.

Ao concluir a tela, o programa progrediu e parou na primeira ausencia nova:
`0x5B92E0`, alcancada por `0x201120` com retorno em `0x442CB4`. Este endereco,
nao mais a tela legal ou o renderer, e o proximo bloco causal.

Evidencia principal: `work/logs/targeted_transition_probe_20260827.log`.
Instrumentacao apenas passiva; sem sinal de semaforo, retorno forcado, gate
semantico ou alteracao do scheduler.
