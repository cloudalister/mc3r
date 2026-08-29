# MC3 recomp - CopyToFront ate o limite MFIFO/VIF1 (2026-08-25)

## Resultado do lote

O callback retail de copia foi identificado e provado em execucao. Ele nao esta morto,
nao usa flip de `DISPFB` e nao perdeu seus enderecos de origem/destino. O lote tambem
provou que o buffer enviado nasce contendo o render target frontal e a referencia da
textura traseira. A falha restante foi estreitada para o consumo desse lote depois de
`lowPsxGfx::SendBuffer`, antes de ele reaparecer como sprite no rasterizador GS.

Nenhuma mudanca semantica foi feita: somente logs limitados e hashes observacionais.
Nao houve injecao de `SignalSema`, filtro/clamp ou mudanca do scheduler.

## Mapa comprovado

- `0x005282E8` e `gfxPipeline::SimpleBackToFrontBlit(void)`.
- `0x00715C70` aponta para o render target de destino.
- `0x00715C74` aponta para a textura-fonte.
- `0x00715C78` guarda o callback chamado por `BeginFrame`.
- O modo retail observado e `CopyToFront type=2`.
- O ramo tipo 2 chama `gfxPipeline::Blit2D@0x0052AFB8` em tiras verticais de 32 px.
- A submissao usa `lowPsxGfx::SendBuffer@0x00526900`; o caller medido foi
  `0x00526C30`.

## Enderecos e formatos medidos

Em todas as amostras dos primeiros frames:

```text
copy = 512x448
target texture = 0x00792140
target BP/BW/PSM = 0 / 8 / CT16
source texture = 0x007922C0
source TBP0/TBW/PSM = 2048 / 8 / CT24
source guest FBP = 64
```

Isso fecha a intencao `FBP64 -> FBP0`. O destino ocupa o front em CT16; a origem
offscreen e amostrada como textura CT24 com `TBP0=2048` (`64 * 32`).

## Prova de execucao do callback

O callback entrou continuamente no ramo tipo 2. Cada frame medido:

```text
[MC3_COPY_TO_FRONT] begin ... type=2 copy=512x448
[MC3_COPY_TO_FRONT] branch ... path=type2 stripWidth=32
[MC3_COPY_TO_FRONT] end ... dma=+2 gif=+0 gs=+0 vif=+0
```

O `+2 DMA` dentro da chamada prova que o passe fecha/submete trabalho. Os deltas GIF,
GS e VIF permanecem zero dentro da mesma chamada porque o consumo e assincrono; eles
nao foram usados isoladamente como prova de perda.

## Prova do buffer antes do runtime DMA

O `SendBuffer` recebeu repetidamente o mesmo lote estrutural:

```text
caller=0x00526C30
start=0x70002800
current=0x70003FC0
bytes=6080
sourceRef=1
frame0=1
```

`sourceRef=1` significa que existe no chain uma tag DMA `REF` apontando para
`sourceTexture + 0x10`. `frame0=1` significa que o lote contem a configuracao FRAME do
destino `FBP0/FBW8/PSMCT16`. O descritor TEX0 nao aparece inline porque mora justamente
no payload externo referenciado pela tag `REF`; isso e esperado e nao evidencia falta.

Portanto, a montagem do `SimpleBackToFrontBlit` e o fechamento do ring nao sao mais o
blocker principal.

## Limite encontrado no rasterizador

Foi adicionado um marcador limitado em `GSRasterizer::drawPrimitive` para qualquer
sprite texturizado que:

1. escrevesse `FRAME.FBP=0`; ou
2. lesse `TEX0.TBP0=2048`.

Apos mais de 30 callbacks completos, houve **zero** `MC3_COPY_RASTER`, inclusive com a
condicao ampliada (nao apenas o par perfeito). Assim, o lote correto visto em
`SendBuffer` nao reaparece no rasterizador com nenhum dos dois lados do estado esperado.

Isso nao prova ainda qual componente descarta ou altera o lote. Prova apenas o intervalo
causal:

```text
SimpleBackToFrontBlit correto
  -> SendBuffer correto
  -> fromSPR/MFIFO/VIF1/REF/DIRECT ainda aberto
  -> nenhum sprite frontal/traseiro relacionado no rasterizador
```

## Validacao executada

- objeto `sub_005280A0_0x5280a0.o`: compilou;
- objeto `sub_00526900_0x526900.o`: compilou;
- target incremental `ps2_runtime`: compilou e gerou `libps2_runtime.a`;
- fast relink: OK;
- quatro probes deterministicas; as tres relevantes chegaram ao CopyToFront sem crash
  ou funcao ausente observada;
- a suite completa 290/290 nao foi repetida neste lote porque as mudancas foram apenas
  diagnosticas.

## Proximo passo exato

Marcar a tag `REF` reconhecida no lote de 6.080 bytes e segui-la em tres checkpoints:

1. copia `fromSPR -> MFIFO`;
2. parse da tag `REF` pelo drain VIF1, incluindo TTE e endereco externo;
3. `DIRECT` entregue ao GIF Path2.

O primeiro checkpoint em que `sourceTexture+0x10` ou seu payload deixa de existir sera
o novo endereco causal. Ainda nao ha autorizacao tecnica para alterar o pacote, forcar
flip, injetar sincronizacao ou pular a fila.

## Atualizacao - REF, Path2 e defeito real do IMAGE continuation

Os tres checkpoints seguintes passaram:

```text
[MC3_COPY_REF_PARSE] id=3 qwc=6 addr=007922d0 tte=1 desc=00000002a8120800
[MC3_COPY_REF_CHAIN] bytes=19256 descOff=00003ae8 frameOff=00003918 completes=0
[MC3_COPY_REF_DIRECT] opcode=50 ... truncated=0
```

O mesmo conteudo tambem passou por `GifArbiter::submit`, `drain` e chegou ao GS. O GS
aplicou `FRAME_1/2=0x02080000` e `TEX0_1=0x2A8120800`. Portanto, `fromSPR`, MFIFO,
REF externo, TTE, VIF DIRECT, arbiter e escrita de estado GS estao fechados para este
lote.

Durante essa auditoria apareceu um defeito independente e causal no parser VIF1. Ele
so detectava `GIF IMAGE` quando ela era a primeira tag de um `DIRECT`. Os pacotes reais
fazem setup A+D, colocam a tag IMAGE no final e enviam os pixels em outro DIRECT. O
runtime perdia essa tag final e reinterpretava pixels RGBA (`00ffffff`, `08ffffff`,
...) como uma nova tag IMAGE de 32.767 QWs. Com isso, blocos VIF seguintes inteiros
eram consumidos como pixels Path2.

O parser agora:

- percorre todas as GIF tags do payload DIRECT;
- detecta IMAGE final incompleta;
- conserva o numero exato de QWs pendentes;
- consome somente o payload do proximo DIRECT como continuacao IMAGE;
- continua interpretando NOPs e comandos VIF entre os dois DIRECTs.

Foi adicionada regressao para `setup A+D -> IMAGE final -> NOP -> DIRECT de pixels`.
A suite final passou **291/291**. Houve uma rodada anterior 290/291 pela flaky historica;
a repeticao limpa e a rodada final ficaram em 291/291.

No probe real, desapareceram tanto o falso `pending=32764` quanto a alternancia que
enviava o chain de 19.264 bytes cru ao GS. Uploads reais de 4, 16, 64, 512, 1.024 e
2.048 QWs passaram a ser reconhecidos com continuacao delimitada.

## Nova fronteira exata

O chain especifico do CopyToFront agora termina limpo:

```text
[MC3_COPY_VIF_SUMMARY] size=19256 end=19256 commands=220 direct=87 unpack=11 kicks=0 pendingImage=0
```

Assim, o proximo blocker nao e mais transporte nem IMAGE pendente. O lote contem 87
DIRECTs e 11 UNPACKs, mas nenhum `MSCAL`, `MSCALF` ou `MSCNT`; durante a chamada ainda
nao nasce nenhuma primitiva (`gs=+0`) e nao ha `MC3_COPY_GS_KICK`.

Proximo passo: inventariar os 87 DIRECTs do lote por GIF tag/registrador e comparar a
ordem com os 11 UNPACKs para descobrir se as tiras deveriam ser emitidas diretamente
ao GS ou acionadas por um kick que o construtor `Blit2D/SendBuffer` nao fechou.

## Fechamento - DIRECTs, PRMODECONT e primeira imagem reconhecivel

A auditoria estatica de `gfxPipeline::Blit2D@0x52AFB8` confirmou que este caminho monta
sprites GIF diretamente. Nao depende de `MSCAL`, `MSCNT` ou `XGKICK`; portanto,
`kicks=0` era esperado e nao representava perda de trabalho VU1.

O inventario runtime dos 87 DIRECTs fechou sem truncamento:

```text
[MC3_COPY_DRAW_SUMMARY] directPayloads=87 tags=103 pk=87 rl=16 img=0
eop=87 pre=32 prim=0 rgbaq=32 uv=32 xyzf2=32 xyz2=32 ad=102
consumed=4304 truncated=0
```

As 16 tiras existem: cada uma possui dois vertices texturizados (`UV`/`XYZF2`) e dois
vertices auxiliares (`XYZ2`). O parser GS recebia e rasterizava os sprites, mas o
estado efetivo ficava com `TME=0`.

A causa foi provada na semantica geral do GS:

1. o jogo grava `PRMODECONT.AC=0`;
2. grava `PRMODE=0x158`, que fornece `TME=1`, `FST=1` e os demais atributos;
3. o GIFtag seguinte usa `PRE=1` com `PRIM=0x006`, contendo apenas o tipo SPRITE;
4. o runtime aplicava PRMODE corretamente e depois sobrescrevia todos os atributos com
   os zeros de PRIM.

O runtime agora conserva os valores crus de `PRIM` e `PRMODE` e seleciona a fonte dos
atributos por `PRMODECONT.AC`, inclusive quando AC muda. A regressao nova desenha um
sprite texturizado com `AC=0`, PRMODE contendo TME/FST e PRIM contendo apenas o tipo.

Validacao:

- suite completa: **292/292**;
- fast relink: OK;
- segundo CopyToFront real: `TME=1`, `FST=1`, `MC3_COPY_GS_KICK` presente;
- frame intermediario: `gifPk1=290`, `gifPk2=431`, `gsPrims=613`,
  `gsPixels=688128`;
- frame de dump: `gifPk1=2702`, `gifPk2=1055`, `gsPrims=5454`,
  `gsPixels=1722560`.

Primeira evidencia visual aceita do projeto:

```text
work/evidence/mc3_prmode_frame.png
512x448
SHA-256 57153e099948829d5189bf274d17738af4cc28576593c553589e21a5f9b2f7c9
```

O frame mostra de forma reconhecivel o logo **Midnight Club 3 DUB Edition Remix** e a
tela de aviso/EULA. A imagem ainda esta escura, mas nao e mais geometria abstrata,
faixa, cinza uniforme ou falso positivo estrutural.

Proxima fronteira: medir por que o framebuffer apresentado fica escuro e seguir a
transicao dessa tela ate o menu, preservando a semantica PRMODE/PRIM agora corrigida.

## Corredor de boot e local exato da tela inicial

Correcao: o texto lido em `0x00619B14 + 0xE8` e o nome da transicao carregada, nao o
estado vivo do jogo. Ele fica em `mc3intro` mesmo depois da mudanca de estado.

Contadores passivos fecharam o corredor real:

```text
mcLayerMovie Load/ctor/clear = 3/3/3
EnterStateMovie             = 3
EnterStateMC3Frontend       = 1
SetFrameModeFrontend        = 2
frameMode@0x619B00          = 3
```

Logo, os tres filmes (`rockstar`, `sdlogo`, `mc3intro`) sao criados e descarregados. O
ponteiro `0x617BCC` aparece durante cada filme e e limpo pelo unload esperado. A entrada
em `mcGameState::EnterStateMC3Frontend@0x1A5B08` ocorre por volta do tick 6540. A imagem
reconhecida de logo MC3 + aviso legal e a primeira tela do frontend, mas ainda nao prova
que o menu principal interativo apareceu.

Tambem foi corrigida a leitura estatica anterior: `0x398C80` corresponde a
`ipcTime(void)` e `0x614444` recebe um timestamp; nao e um objeto de frontend.

## Fronteira registrada neste lote: abertura PADMAN

O contador original do stub host `scePadRead` media a camada errada. O retail registra
uma implementacao guest recompilada em `scePadRead@0x543ED8`. A cadeia real foi medida
sem alterar input:

```text
ioPad::UpdateAll       = 6
ioPad::Update          = 12
ioPad::Attach          = 12
scePadGetState         = 12
scePadPortOpen         = 2
ioPad states           = 5,5,0,0
ioPad poll/read        = 0
guest scePadRead       = 0
padlib slot0 pointers  = 0,0
padlib open pointers   = 0,0
```

`ioPad::Update@0x238808` so entra no poll `0x238368` quando `ioPad::Attach@0x238030`
devolve estado `7`. Hoje os dois pads abertos ficam no estado `5`. O decomp de
`scePadPortOpen` mostra que os ponteiros da padlib so sao publicados depois de
`sceSifCallRpc@0x549488` retornar sem erro; esse commit nao acontece no runner.

Esse era o bloqueio medido em 2026-08-25. Ele foi corrigido no lote seguinte: a auditoria
usava uma base deslocada em `+0x10000`; os ports ja abriam em `0x006FC590`. O dispatcher
PADMAN dedicado e o contrato DMA levaram `ioPad::Attach` a `7`, `ioPad::Poll` a `10` e
`scePadRead` guest a `10`. Ver `docs/RESULT_PADMAN_CORRIDOR_2026-08-26.md`.

Correcao de auditoria: `0x01E21914` pertence ao override RECVX registrado para
`slus_201.84`; nao e um estado de filme do MC3 e foi descartado como marcador.

Validacao final deste lote: suite **292/292**, build incremental e fast relink OK.
