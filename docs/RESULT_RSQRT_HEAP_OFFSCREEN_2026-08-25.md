# MC3 recomp - RSQRT, heap e framebuffer offscreen (2026-08-25)

## Resultado do lote

O erro profundo de heap foi fechado por uma correcao semantica no COP1 `RSQRT.S`.
O runner agora atravessa o ponto que antes pedia 116.815.248 bytes, sem funcao ausente
e sem heap overrun. Tambem foi obtida uma captura read-only do framebuffer offscreen:
ha desenho real na VRAM, embora ainda nao exista logo, menu ou carro reconhecivel.

## Causa exata do heap overrun

A instrucao retail em `0x004FEC4C` e:

```text
rsqrt.s $f4, $f0, $f4
```

O contrato R5900 e `fd = fs / sqrt(ft)`. O gerador emitia:

```cpp
ctx->f[4] = 1.0f / sqrtf(ctx->f[0]);
```

Portanto ignorava `ft`, fixava o numerador em 1 e usava `fs` como radicando. Nesse
algoritmo, `f0=1.0` e `f4=dx*dx+dy*dy`; o bug devolvia 1, deixando um vetor de milhares
de unidades sem normalizacao antes de multiplica-lo por 20.

Cadeia medida antes da correcao:

```text
caller=0x001BDC20 -> image routine 0x004FEB50
width=5742 height=5086 pixels=29203812 request=116815248
allocator wrapper=0x003B1630 allocator=0x003AFE40
```

Depois da correcao:

```text
width=144 height=128 pixels=18432 request=73728
heap overrun=0
missing function warnings=0
```

O gerador foi corrigido em `PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp`, recebeu
regressao em `code_generator_tests.cpp` e o objeto ativo `FUN_004feb50_0x4feb50.cpp`
foi atualizado e relincado.

## Validacao

- Suite completa: **290/290**.
- Runner parcial: **15.827 funcoes registradas**, 168.331 aliases, zero stub ausente.
- Boot deterministico headless de 1.200.000 dispatches: zero heap overrun e zero warning
  de funcao ausente.
- Pedido de imagem interno: **116.815.248 -> 73.728 bytes**.
- No corte comparavel de 1.200.000: `gifPk1=70752`, `gifPk2=38790`,
  `gsPrims=146998`, `gsPixels=67574456`, `DISPFB1=0x11000`.
- Nenhum `SignalSema` foi injetado, nenhum clamp/filtro foi adicionado e o scheduler
  permaneceu intacto.

## Evidencia visual

Captura apresentada:

- `work/evidence/mc3_rsqrt_ctx_800k.png`
- 512x448, cinza uniforme, SHA-256
  `1149f7dd8ec4a08ce910b061dd4d961bb27286ba353d646277d9d05390241c86`.

Captura read-only dos contextos GS:

- `work/evidence/mc3_rsqrt_ctx_800k_ctx0.png`
- `work/evidence/mc3_rsqrt_ctx_800k_ctx1.png`
- ambos 512x448, `FBP=64`, `FBW=8`, `PSM=CT32` e byte a byte identicos;
- SHA-256 `f3756120ec30784eee39c3663c07c009089f68d5b8f2e41c06b46a3de7e8af71`.
- cinco cores medidas; existem faixas cinzas e vermelhas na VRAM offscreen.

Isso e uma imagem tecnica real, nao uma imagem aceita do jogo. Prova que
vertice/GIF/GS/VRAM estao vivos, mas o conteudo ainda aparece como faixas.

## Estado da apresentacao

A rotina retail `0x0052A1B0` e chamada continuamente por `0x0052A080`. O trace mostrou:

1. chamada 1: `pending=0`, `page=0`;
2. chamada 2: `pending=1`, `page=1`, aplica `GsDispEnv` em `0x00715A40` com
   `DISPFB=0x11000`;
3. chamadas seguintes: `pending=1`, mas `page>=2` faz o gate inicial pular
   `0x00529BD0` (`PutDispEnv`).

Assim, a rotina nao esta morta; o proximo ponto causal e explicar por que o contador
em `0x00715A38` cresce sem voltar ao estado que permite a aplicacao e por que o modo
em `0x0061C39D` permanece no caminho de ambiente unico.

O cruzamento estatico deu nome ao entorno desse byte. `0x0061C39D` e lido por:

- `gfxPipeline::GetFBP(bool)` em `0x00528C20`;
- `gfxPipeline::BeginFrame()` em `0x005297C0`;
- `gfxPipeline::SubmitFrame(bool,bool)` em `0x0052A200`;
- `gfxPipeline::SetRenderTarget(...)` em `0x0052A8CC` e `0x0052AB00`.

No corpus gerado, a unica escrita direta encontrada e `sb $zero` em `0x00528048`,
dentro de `gfxPipeline::_SetRes(int,int)`. Isso prova inicializacao para zero e uso
compartilhado pela politica de framebuffer/render target; nao prova que o valor deveria
ser um, nem autoriza injecao. Escritas indiretas por ponteiro ainda nao estao excluidas.

A imagem retail fecha melhor esse ponto. No ELF original, `0x0061C39D` nasce como `1`,
enquanto o word em `0x0061C380` nasce como `2`. `_SetRes` le `0x0061C380` e, quando ele
e diferente de zero, executa exatamente o `sb $zero` em `0x00528048`. Portanto o zero
observado no boot recompilado e um caminho retail intencional para essa configuracao,
nao evidencia de que o runtime perdeu um writer que deveria liga-lo.

O caller fecha a intencao: `0x00527C40` chama
`gfxPipeline::SetCopyToFront(type=2, ...)` em `0x00527CAC` antes de chamar `_SetRes` em
`0x00527D74`. O byte funciona como selecao entre alternancia de buffers e backbuffer
fixo com copia para o front, embora o nome exato do global nao esteja simbolizado.

O elo seguinte tambem esta localizado. `gfxPipeline::BeginFrame` le o tipo em
`0x0052997C`; quando ele nao e zero, carrega o callback de `0x00715C78` e o executa em
`0x00529990`. `gfxPipeline::Begin` instala por padrao a funcao hidden `0x005282E8`,
que inicia chamando `SetRenderTarget` em `0x0052833C` com a textura de `0x00715C70`.
Esse e o passe CopyToFront real que deve ser auditado a seguir.

Com o modo zero, `gfxPipeline::GetFBP(true)` devolve o FBP fixo calculado por `_SetRes`
(`0x0070FBF8`), que no trace corresponde a `FBP=64`. Isso combina com o desenho
offscreen medido e desloca a investigacao: o gate de `PutDispEnv` nao e o bug principal;
falta explicar a composicao/copia final de `FBP=64` para o framebuffer exibido em `FBP=0`.

Tambem foi corrigida a leitura de `0x0052C360`: o port alpha o identifica como
`gfxTexture::UpdateAllStaticAddresses()`. A rotina percorre texturas e chama
`gfxTexture::UpdateStaticAddress`; nao e o produtor do contador de pagina nem o passe
de copy-to-front.

## Pendencia global do RSQRT

O snapshot gerado ainda contem **450 traducoes antigas** `1.0f / sqrtf(...)` em outros
caminhos. O gerador raiz esta correto, e o caminho ativo que causava o heap foi corrigido,
mas o corpus deve ser regenerado ou reescrito mecanicamente com os operandos `fs/ft`
antes de declarar o COP1 globalmente saneado.

## Proximo passo exato

1. instrumentar o callback hidden `0x005282E8` executado por `BeginFrame`, seguindo
   seu `SetRenderTarget@0x0052833C` e os pacotes de blit/copia ate provar onde o passe
   `FBP=64 -> FBP=0` deixa de produzir o front buffer esperado;
2. regenerar/corrigir as 450 emissoes antigas de `RSQRT.S`;
3. depois comparar a origem das faixas offscreen com FRAME/SCISSOR/XYOFFSET e os
   vertices 12.4. Ainda nao e a fase de localizar modelos/endereco dos carros.
