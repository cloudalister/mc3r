# MC3 — textura antes da cópia, 2026-09-13

Estado: teste concluído. As faixas já existem na textura de origem antes da cópia
CT24->CT16. Nas seis amostras, sampler, combinação e escrita conferem. Gráficos
continuam incorretos; nenhuma correção funcional foi aplicada.

## Pergunta e fronteira observada

A captura anterior atribuiu branco/ciano no framebuffer CT16 a duas cópias de
textura CT24, em prim2227445 e2407292. Isso não dizia onde a faixa nasceu.
Cloud autorizou o próximo teste com "gogo": observar a textura antes da cópia.

O novo diagnóstico captura somente a geometria já observada: contexto0, sprite
texturizado FST, FRAME0/FBW8/CT16, TEX0 TBP2048/TBW8/CT24/TW10/TH10,
retângulo inteiro256,0,32,447 e UV brutos4096,0 até4608,7152. São três amostras
de destino:256,84..86; o campo entrelaçado e a composição de CRTs envolvem essas
linhas. As coordenadas de amostragem são4104,1352/1368/1384; filtro linear com
fração zero seleciona efetivamente texels256,84..86. Vizinhos também registrados.

Antes de qualquer escrita do sprite: snapshot RGB de512x64, origem0,72 na textura,
três amostras da textura, cor após TEXA/combinação e destino antes. Depois: destino
CT16, TEST/ALPHA/TEX1/CLAMP/ZBUF/FBMSK/TCC/TFX/TEXA/PABE/FBA e geometria.
ZBUF é registrado como estado; `writePixel` atual não compara Z nesse caminho.
Capturas só são emitidas se uma das três amostras mudar para branco/ciano.
Máximo4 arquivos PPM com criação exclusiva. Nenhum membro GS/PS2Memory novo,
nenhum hook dentro do laço de pixels, nenhuma escrita do observador na VRAM.

O observador físico anterior foi apontado para a textura de entrada, FBP64/FBW8/
PSM1 em256,85, equivalente a TBP2048. Ele pode atribuir draw, IMAGE, HWREG,
local-copy e clear mesmo quando o escritor usa outra interpretação da VRAM.
Threshold2M; antes disso há apenas o primeiro candidato por tipo de escritor.
O limite32 e a seleção por mudança branco/ciano continuam valendo. Resultado
negativo não exclui escritas antes do threshold ou estados intermediários.
Os registros de apresentação agora comparam outro endereço; igualdade de cor
nesses registros não significa que textura e apresentação são a mesma superfície.

## Preservação e implementação

Artifacts: `<scratch-dir>/mc3-copy-source-20260913`.
`baseline/sources.csv` e17 fontes conferidos por SHA256; biblioteca/testes C do
diagnóstico anterior copiados e conferidos. Backup integral anterior de16202
arquivos permanece em `mc3-surface-20260913/baseline_v2`. O executável anterior
C e o original E continuam preservados. A árvore de build C foi reutilizada;
sua biblioteca mutável foi substituída após backup. Cada executável novo usa
sua própria cópia da biblioteca em `bin` para preservar a proveniência.

- `ps2_copy_source_probe.h`: gate `MC3_COPY_SOURCE_PROBE`, padrão OFF.
- `ps2_gs_rasterizer.cpp`: amostras antes/depois do sprite específico.
- `Probe-FrontendWrites.ps1`: flags opcionais e prefixo de captura C; padrões antigos preservados.
- `copy_source_tests.cpp`, `Test-CopySource.ps1`: fixtures e regressão.
- `Analyze-CopySource.js`, `Test-AnalyzeCopySource.js`: decodificação, contagem de linhas e comparação independente de cores.
- `Relink-CopySource.ps1`: executável separado, hashes e recusa de sobrescrita.

## Validação já concluída

`tests/PASS_20260913_041932.json`:331/331 OFF e331/331 ON com bridge/STQ e probes.
Fixture:100128 pixels conferidos contra conversão RGB->CT16, entrada limpa e com
faixa branca/ciano, textura preservada e digest da VRAM inteira idêntico OFF/ON.
Quatro PPMs emitidos; segunda execução recusa os mesmos nomes e preserva bytes.
Parser conferiu todas as amostras, faixa de512 pixels na linha85 e rejeição de
estados não suportados pelo cálculo de blending. Esses testes não constituem
aceitação visual do jogo.

Problemas de preparação resolvidos: PowerShell exigiu ExecutionPolicy Bypass
somente no processo filho; fixture precisava incluir a definição de GSRegisters;
asserção auxiliar foi corrigida para preservar o bit alpha do destino preto.
Nenhum desses ajustes mudou a renderização.

## Reprodução real

Label `copy_source_20260913_0423`; início real04:21:54 Brasília, PID6376,
limite900s, headless/quiet, bridge/STQ ON, Start30s/30s após45s. Captura de
apresentação e entry trace ON. Nenhuma janela aberta.

Exe SHA256 `63bff17189f7e5d5d77fd2eba72800ae304b323dcb2dc6e73682ab5d7c3066c7`.
Lib SHA256 `ded873571d0f31c7d800201fc7b68dd20b32933dac2cc5cb9d863b6940e3eee9`.
Proveniência completa em `bin/VERIFIED.json`; logs/ambiente em `run/logs`.

Parada deliberada04:33:17 após critério atingido; harness fechou04:33:20,
wall686.2189376s, CPU638.296875s. PID/path/start conferidos antes da parada;
`stop.json` registra intenção. Exit-1 corresponde à parada solicitada, não crash.
Não há runner ativo.

Três PNGs de apresentação:60.005s/prim389935,360.018s/prim1265975 e
660.024s/prim2743953. O segundo mostra fundo deformado; o terceiro reproduz
as faixas brancas/cianas. Duas PPMs de origem vistas e convertidas para PNG
sem alterar nenhum byte RGB. Parser final:2 capturas completas,6 amostras,
0 registros rejeitados; todas as comparações sampler/shading/blend/storage PASS.

| Cópia | Linha | RGB fonte (R,G,B) | Amostrado RGBA hexadecimal | Cor combinada | Destino CT16 antes->depois |
|---|---:|---|---|---|---|
| prim2227445 |84,85,86|255,255,255|00ffffff|80ffffff|8000->ffff|
| prim2407292 |84,85|4,255,255|00ffff04|80ffff04|8000->ffe0|
| prim2407292 |86|136,255,255|00ffff88|80ffff88|8000->fff1|

TCC=0,TFX=0,TEXA=0,0,128: alpha zero da textura CT24 é substituído pelo alpha128
do vértice na combinação. ALPHA44 dá peso integral à fonte. A redução do canal
R=4 para0 é a quantização esperada de CT16. A linha86 diferente explica por que
composição/entrelaçamento pode clarear a borda; não é uma cor inventada pela cópia.
O censo de linhas do JSON conta branco/ciano exatos de24 bits; não conte `ffff04`
como ciano exato antes da quantização. A imagem da fonte2 já contém as faixas.

![Fonte antes da segunda cópia, linhas72..135](<scratch-dir>/mc3-copy-source-20260913/run/captures/source_copy_source_20260913_0423_2.ppm.png)

![Terceira apresentação, ainda defeituosa](<scratch-dir>/mc3-copy-source-20260913/run/captures/present_copy_source_20260913_0423_3.png)

## Produtor identificado e próximo limite

O endereço da fonte é690312 (`0xA8888`), confirmado no arm do runtime em2M.
32 eventos/32 geometrias válidos, todos draw/GIFpath1 em FRAME64,FBW8,CT32;
primeiroprim2225038, últimoregistradoprim2693909. O limite32 foi atingido: a lista
não é exaustiva depois dele. Há1 early draw em1147340 e0 registros rejeitados.
O último snapshot de contadores é anterior, em2500183 (13 candidatos naquele
momento); não usar seu `capped=0` como contagem de encerramento.

Antes da primeira cópia, a fonte observada progride:
2225038 `000000->fbfbfb`;2225044 `000000->fdfdfd`;2225467 `fdfdfd->fefefe`;
2225685 `fefefe->ffffff`. Antes da segunda:2404667 `000000->fdfd00`,
2405053 `fdfd00->fefe01`,2405306 `fefe01->ffff04`.

Os primeiros produtores são triangle strips (`type4`): textura7425,TBW1,CT32,
8x8; depois textura7449,TBW1,PSM19,64x64,CLUT7445. Exemplo2225038: coordenadas
de tela(1142.8125,-1425),(70.25,922.4375),(-553.3125,-1400.4375), Q respectivamente
-1.502499,6.787076,-0.260500. Em2225467/2225685 os três Q são negativos, com
Z próximo2^32. Isso prova quais triângulos alteraram a fonte; não prova ainda
qual produtor de vértices, textura ou regra de rejeição está incorreto.

Auditoria local evita dois atalhos incorretos: `fabsQ` preserva o sinal de Q;
o decoder packed XYZF2/XYZ2 já extrai o bit47 de `hi` e chama `vertexKick(!adk)`.
Portanto não afirmar que ADC é descartado ou que Q negativo vira módulo.
Há uma hipótese concreta a validar: `vertexKick(false)` incrementa a contagem
e retorna antes do avanço da fila de triangle strip. Os vértices entram em uma
fila de6 posições, enquanto o rasterizador usa os primeiros3. Próximo teste:
sequência mínima com kicks suprimidos, seguida de rastreio dos mesmos packets
GIFpath1 antes de2225038/2404667. Conferir montagem da fila e flags reais antes
de alterar clipping ou descartar triângulos com Q negativo.

Não houve fix visual, publicação ou mudança de flags padrão. A etapa concluída
isola a fronteira: desenho da textura de origem -> cópia final validada nas
amostras -> apresentação ainda defeituosa.

## Reversão

Não definir `MC3_COPY_SOURCE_PROBE` desativa a captura. O executável E original
não foi substituído. Para voltar ao diagnóstico anterior, usar o executável C
anterior com a biblioteca preservada em `mc3-copy-source-20260913/baseline`.
Não restaurar patches amplos: ambos os repositórios já continham trabalho local.
