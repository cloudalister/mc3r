# MC3 recomp - VU1 I-bit e destino FTOI (2026-08-25)

## Estado honesto

- Simbolos retail nomeados por port alpha -> retail: **8.815 / 15.812 (55,7%)**.
- Isso mede identificacao de funcoes, nao percentual do jogo pronto.
- O runner registra aproximadamente 15.811 funcoes, mas a imagem reconhecivel do jogo ainda nao foi atingida.

## Causa provada

O PATH1 em `VU1[0x1530..0x1600]` recebia dados plausiveis do VIF, mas o microprograma
sobrescrevia os vertices com zero/infinito. O trace fechou a cadeia:

1. `DIV` em `pc=0x1100/0x1168/0x11c8` calculava `1.0 / VF20.w`;
2. `VF20.w` era zero;
3. `Q` virava `0x7f7fffff`;
4. `MULq` produzia zero/infinito e o pacote XYZ degenerava.

A origem nao era o `DIV`: o executor confundia o I-bit do upper com o lower literal
`0x8000033C`. Esse lower comum fazia o runtime pular a operacao upper emparelhada,
incluindo os `MULA/MADDA/MADD` que constroem `VF20.w`.

## Correcoes

1. I-bit agora vem de `upper.bit31`.
2. Com I-bit ativo, a operacao upper continua executando e o lower bruto alimenta o registrador I.
3. `0x8000033C` volta a ser tratado como lower normal e nao suprime o upper.
4. Operacoes unary upper `ITOF0/4/12/15`, `FTOI0/4/12/15` e `ABS` escrevem no campo FT,
   nao no campo FD que participa do seletor secundario do opcode.
5. Branches VU1 agora executam o delay slot antes de aplicar o destino.
6. O despacho upper SPECIAL usa o seletor composto e deixa de perder `MULAw` e operacoes vizinhas.

Nao houve SignalSema injetado, clamp/filtro de vertices, gate por jogo ou alteracao do scheduler.

## Evidencia causal

Depois do fix do I-bit:

```text
DIV pc=0x1100 num=0x3f800000 den=0x3f800000 q=0x3f800000
VF20 pc=0x10f0 ... after=be800000,be800000,0,3f800000
```

Antes, o mesmo `DIV` tinha `den=0` e `q=0x7f7fffff`.

O fix FT tambem mudou os vertices PATH1, confirmando efeito no empacotamento. Ainda assim,
as coordenadas consumidas pelo GS permanecem majoritariamente fora da tela e a captura final
continua cinza uniforme. Nao e uma imagem aceita do jogo.

## Validacao

- Build incremental `ps2_runtime` e `ps2x_tests`: OK.
- Regressao nova para lower `0x8000033C` + upper: passou.
- Regressao nova para I-bit carregar I e ainda executar upper: passou.
- Regressao nova para FTOI escrever em FT: passou.
- Suite final: **288/288**.
- Fast relink: OK.
- Boot deterministico headless: `MC3_DISPATCH_BUDGET=600000`.
- Ultimo frame observado: `gifPk1=3168`, `gifPk2=1734`, `gsPrims=6582`,
  `gsPixels=145383438`, `DISPFB1=0x11000`.

## Artefatos visuais

- `work/evidence/mc3_vu1_ibit_fix.png` - 9.460 bytes,
  SHA-256 `1149f7dd8ec4a08ce910b061dd4d961bb27286ba353d646277d9d05390241c86`.
- `work/evidence/mc3_vu1_ft_fix.png` - 9.466 bytes,
  SHA-256 `218f5a4cefe9777a32369ac0dab4f468b38f57f19af887c307873f5f79980773`.

Ambas sao evidencias tecnicas, nao sucesso visual.

## Proxima fronteira exata

Seguir um vertice finito do resultado `FTOI` ate o qword gravado por `SQ` e depois ate o
decode `XYZ2` no GS. Comparar bits, escala 12.4 e `XYOFFSET` em cada fronteira. O alvo atual
e fechar conversao/empacotamento de vertices; localizar enderecos de carros e reconstruir
modelos vem depois que o pipeline generico desenhar geometria reconhecivel.
