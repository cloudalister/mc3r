# MC3 recomp - GS reserved registers / stable display (2026-08-25)

## Resultado

O `DISPFB1` nao e mais corrompido depois que o render PATH1 entra em carga.
Antes, ele mudava de `0x11000` para `0x5fbdbdbd00070707` e depois para
`0x43a11cc178040156`. Depois da correcao, permaneceu em `0x11000` ate
`gsPrims=104588` em uma corrida deterministica de 800000 dispatches.

Isso e progresso estrutural, nao aceitacao visual. A nova captura ainda mostra
poligonos grandes e incorretos (fundo vermelho com faixas diagonais azul, verde e
preta), sem logo ou menu legivel.

## Causa causal

O probe separou todos os caminhos capazes de alterar o display:

- nenhuma escrita `DISPFB1` veio de MMIO guest no instante da corrupcao;
- nenhuma veio de `applyGsDispEnv`;
- nenhuma veio do decode GIF PACKED A+D observado;
- a unica mutacao restante era o alias nao-hardware de `GS::writeRegister` para
  os enderecos A+D reservados `0x59..0x5f`.

Esses enderecos nao sao `DISPFB/DISPLAY`: os registradores de display sao
privilegiados e vivem no espaco MMIO `0x12000070..0x120000e0`. Aceitar `0x59`
como `DISPFB1` fazia dados de draw malformados virarem estado de apresentacao.

O mesmo erro existia no stub `sceGsResetGraph`: ele construia um pacote GIF A+D
com `0x59/0x5a/0x5b/0x5c/0x5f` para tentar configurar registradores
privilegiados.

## Correcao

- `sceGsResetGraph` agora escreve PMODE, SMODE2, DISPFB1/2, DISPLAY1/2 e BGCOLOR
  pelos enderecos MMIO privilegiados reais.
- `GS::writeRegister` voltou a ignorar `0x59..0x5f` como enderecos A+D
  reservados.
- os testes antigos que canonizavam o alias incorreto foram trocados por
  regressao que exige que A+D reservado nao altere `GSRegisters`.
- `MC3_HEADLESS=1` apenas adiciona `FLAG_WINDOW_HIDDEN` ao harness host; nao
  muda scheduler, DMA, GIF, VU ou GS e permite provas longas sem roubar foco.

Nao houve clamp de valor, filtro por jogo, SignalSema injetado nem gate semantico.

## Validacao

- build `ps2x_tests`: OK;
- suite: `282/282` no retry limpo;
- a primeira passada teve somente a intermitencia ja conhecida de paridade em
  `sceGsSyncV` (`281/282`);
- fast relink do runner parcial: OK;
- boot deterministico 800000 dispatches: `DISPFB1=0x11000` ainda em
  `gsPrims=104588`, `gsPixels=10368572`;
- captura deterministica 730000 dispatches: dump em `gsPrims=52514`, final em
  `gsPrims=80402`, sempre com `DISPFB1=0x11000`.

## Evidencia visual

- Arquivo: `work/evidence/mc3_reserved_gs_fix_50k.png`
- Resolucao: `512x448`
- Tamanho: `14029` bytes
- SHA-256: `f2ef9fb3154562cbebe67e242974e217a07540729327e04907ed569fc7f10e65`
- Leitura honesta: imagem produzida e diferente do poligono roxo anterior, mas
  ainda corrompida e sem conteudo reconhecivel.

## Proxima fronteira

O display esta estavel; o defeito seguinte esta no estado de draw/vertices.
O proximo lote deve capturar o primeiro triangulo de tela inteira incorreto e
correlacionar PRIM, XYZ/XYZF, XYOFFSET, SCISSOR, FRAME e contexto do PATH1 que o
gerou. Nao mascarar coordenadas e nao descartar primitivas por heuristica.
