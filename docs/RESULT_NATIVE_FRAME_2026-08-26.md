# Resultado: primeira tela nativa reconhecivel

Data: 2026-08-26

## Resultado

O runner parcial completou o budget deterministico de 600000 despachos e voltou a
percorrer naturalmente o corredor de input e render:

```text
PADMAN OPEN
  -> inicializacao normal do jogo
  -> ioPad::Attach phase 7
  -> ioPad::Poll
  -> scePadRead
  -> GIF path 1/2
  -> primitivas e pixels GS
  -> framebuffer reconhecivel
```

Metricas do probe causal completo:

```text
tick                 = 7172
ioPadAttachCalls     = 10
ioPadPollCalls       = 8
guestPadReadCalls    = 8
padmanPublishes      = 20
ioPadAttachPhases    = 7,7,0,0
gifPk1               = 6642
gifPk2               = 2601
gsPrims              = 13427
gsPixels             = 4443861
```

O gate de render do projeto, `gifPkTotal > 0 && gsPrims > 0`, esta fechado.

## Correcao do diagnostico de 45 segundos

Os probes A/B anteriores eram encerrados pelo timeout de 45 s no tick 2580, antes de
consumirem o budget de 600000. A telemetria nova, somente leitura, capturou os primeiros
despachos apos os OPENs e mostrou `0x432AA0` repetido. O decomp prova que esse endereco e
o laco de copia de um `memset` chamado por `0x526744`, zerando 0x80000 bytes a partir de
0x00100000. Era trabalho legitimo de inicializacao, nao uma espera do PADMAN.

Uma janela esparsa ate 250000 despachos mostrou a thread principal continuando por varios
PCs enquanto as threads auxiliares aguardavam seus semaforos normais. Com tempo de parede
suficiente, o mesmo budget chegou ao Attach e ao render sem mudanca de scheduler, sem
SignalSema artificial e sem gate semantico.

## Captura

O segundo probe salvou automaticamente a apresentacao quando `gsPrims >= 5000`:

- `work/frames/mc3_native_600k.png`
- `work/frames/mc3_native_600k_ctx0.png`
- `work/frames/mc3_native_600k_ctx1.png`

A apresentacao mostra o logo `Midnight Club 3 DUB Edition Remix` e o aviso ESRB. A imagem
ainda esta escura, mas e reconhecivel e foi extraida do framebuffer do runner nativo.

## Validacao

- build incremental: OK
- fast relink: OK
- budget deterministico 600000: concluido
- frame dump: `ok=1`, 512x448
- suite: primeira e segunda execucoes pegaram flakes temporais ja conhecidos; retry sem
  carga concorrente passou **293/293**

## Proxima fronteira

Isolar por que a luminancia/alpha da apresentacao esta muito baixa e depois executar o
runner visivel ate o frontend para provar START publicado, lido pelo guest e seguido por
uma transicao de estado.

## Atualizacao: fade isolado e apresentacao visivel

Um segundo dump foi condicionado a `gsPrims >= 10000`. Ele ocorreu com 10908 primitivas:

- `work/frames/mc3_native_600k_late.png`
- apresentacao RGBA 512x448, alpha 255 em todos os pixels
- maximo RGB subiu de 16 para 70
- contexto 1 chegou a RGB 118

O frame tardio mostra o mesmo logo e o texto legal com muito mais contraste. Em seguida,
um runner nativo visivel com budget 900000 mostrou a tela completa, clara e colorida,
continuando a redesenhar ate `gsPrims=177255` e `gsPixels=64014311` no ultimo frame
telemetrado. Logo, a baixa luminancia da primeira captura era o instante do fade da
abertura; nao ha evidencia para alterar PMODE, alpha ou o compositor.

O proximo gate ficou restrito ao input: provar um START capturado pelo host, publicado no
PADMAN e consumido pelo guest antes de exigir a transicao ao menu.
