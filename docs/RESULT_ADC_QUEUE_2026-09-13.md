# MC3 — fila ADC/XYZ3, 2026-09-13

Estado: encerrado. Correção da fila comprovada nos testes e no jogo real.
As faixas brancas e a deformação do cenário permanecem; não houve aceitação
visual do jogo nem afirmação de correção gráfica completa.

## Falha reproduzida

Depois de demonstrar que as faixas já existem na textura antes da cópia final,
Cloud autorizou testar a fila de vértices com "go". O decoder packed já reconhece
ADC, e XYZ3/XYZF3 já enviam `drawing=false`; o defeito estava em `vertexKick`.

A função incrementava a contagem e retornava imediatamente quando o desenho era
suprimido. Não consumia/deslizava uma primitiva completa. Em triangle strip,
A,B,C(suprimido),D mantinha A/B/C na frente da fila; D acionava o desenho dos
vértices antigos. Sequências longas também podiam circular pelos6 slots.

A fixture envia coordenadas/cores distintas pela API real e compara toda a VRAM
com primitivas explícitas de referência. Para o strip acima, o controle contém
somente o triângulo B/C/D; para fan, A/C/D. Não há inspeção nem alteração de
campos privados no teste.

Referência semântica consultada: o caminho de primitiva suprimida em
[PCSX2 GSState.cpp, VertexKick](https://github.com/PCSX2/pcsx2/blob/master/pcsx2/GS/GSState.cpp#L5561)
consome listas e avança strips, mantendo a continuidade do fan. Consulta apenas;
nenhum código, biblioteca ou execução de PCSX2 foi incorporado ao projeto.

## Correção e testes

`GS::vertexKick` passa a separar duas decisões: desenhar/contar a primitiva
somente se `drawing=true`; consumir ou avançar a fila sempre que a primitiva
estiver completa. O switch de avanço já existente é reutilizado. Não muda
GS/PS2Memory, interpretação de Q, clipping, Z, shader, assets nem registradores.

`MC3_GS_ADC_TRACE` é observação opcional OFF por padrão, com primeiras4 ocorrências
e potências de2, sem hook por pixel. A correção da fila está ativa no novo binário,
independente do trace. Rollback pelo executável anterior preservado.

| Validação | Resultado |
|---|---|
| Biblioteca anterior imutável,44 casos ADC |36 FAIL,8 PASS|
| Biblioteca corrigida, mesmos44 casos |44 PASS,0 FAIL|
| Suite geral com probes desligados |331/331|
| Suite geral bridge/STQ/probes ligados |331/331|
| ADC trace ligado |44/44,stdout idêntico,10 registros|
| Cópia de textura |100128 pixels e preservação da fonte PASS|
| Observador de cinco escritores |VRAM/apresentação idênticas OFF/ON|
| Parser de origem/cópia |PASS|

Casos ADC: strip/fan/line strip, listas de triângulos/linhas/pontos, sprites,
supressão antes de completar a primeira primitiva, controles sem supressão e31
kicks suprimidos consecutivos; quatro entradas: XYZ2/XYZ3 direto, XYZF2/XYZF3
direto, packed XYZ2 com ADC e packed XYZF2 com ADC. Métricas excluem os desenhos
suprimidos, e a fixture verifica que esses kicks não escrevem VRAM.

Revisão de leitura com um subagente econômico não encontrou outro erro concreto
no delta. Não é teste de hardware nem prova de que todo defeito gráfico esteja
resolvido. O resultado visual do jogo depende da reprodução abaixo.

## Proveniência e reprodução

Artifacts `<scratch-dir>/mc3-adc-20260913`. Quatro arquivos de baseline
foram copiados e conferidos contra o checkpoint anterior. O executável e a
biblioteca anteriores permanecem em `mc3-copy-source-20260913/bin`; o binário E
original também permanece intacto. Build incremental usa a árvore C existente;
o novo binário recebe sua própria biblioteca imutável em `bin`.

Exe `51d5f876dbcdb474e647346c66a4fc9b72b87b81ba2e5e2bceaf6382662dbf19`.
Lib `ef6f14c88506e1bde829b795478b4b8f1d38daa1bef76727e512d5042635f2f1`.
`bin/VERIFIED.json`, `tests/baseline.json`, `tests/fixed.json` e
`tests/PASS_regression.json` guardam os recibos.

Run `adc_queue_20260913_0446`, início04:46:02 Brasília, PID59840, limite900s,
headless/quiet/bridge/STQ, Start30s/30s após45s. Watch da fonte FBP64/FBW8/CT24,
threshold2M, ADC trace, origem/cópia e apresentação ligados. Não houve janela.
Execução encerrada; resultado e limitações abaixo.

## Evidência real

O mesmo prim2225038/GIFpath1/FRAME64/CT32/TBP7425 permite comparar os vértices
diretamente, sem usar tempo de captura como equivalência de frame:

| Execução | v0 XY bruto decodificado | v1 | v2 |
|---|---|---|---|
| Antes |2934.8125,399 (A)|1862.25,2746.4375 (B)|1238.6875,423.5625 (C)|
| Corrigida |1862.25,2746.4375 (B)|1238.6875,423.5625 (C)|3527.5625,322.75 (D)|

Isso confirma a troca de ABC por BCD no jogo real. O novo triângulo ainda produz
branco na fonte; não concluir que a fila fosse a única causa gráfica. Também
há produtores anteriores da fonte branca:2173175,2173800,2173846; capturas da
origem em2175494 e2227445 mostram a cor antes da cópia. Não confundir índices
das novas capturas com os da execução anterior: compare `prims` e estado.

Nos registros observados, ADC é usado em triangle strips/GIFpath1 no mesmo
FRAME64. O trace avança por potências de2: o maior `n` é um limite inferior da
quantidade real, não um total exato. As entradas válidas mantêm `count=needed`.

### Encerramento e limite visual

Parada deliberada04:57:50 após o critério de captura; harness fechou04:57:55,
wall712.326443s, CPU694.46875s. PID/path/start conferidos, recibo `stop.json`.
Exit-1 corresponde à parada solicitada, não crash. Não há runner ativo.

24 registros ADC íntegros,0 rejeitados, maior `n=4194304`: pelo menos4.194.304
desenhos completos suprimidos tiveram a fila avançada. Todos os registros
observados mantêm o tamanho esperado. Watch da origem:9 eventos draw/9 geometrias,
1 early,1 arm,24 maps,13 apresentações/65 contadores,0 rejeitados.
Último snapshot em5500109 prims: draw9 candidatos,875 mudanças não candidatas,
3499225 operações sem mudança após2M,0 capped; IMAGE0 candidatos. O limite32
não foi atingido nesta execução, ao contrário da anterior. São contagens de um
endereço selecionado; não representam todos os defeitos ou todas as escritas.

Duas capturas da origem, em2175494 e2227445, continuam mostrando branco antes da
cópia. Seis amostras conferem sampler, combinação e CT16. Não houve captura
candidata de ciano no ponto escolhido durante este run. Isso não demonstra que
todo ciano foi eliminado de todas as superfícies/cenas.

Três PNGs:60.017s/prim458193,360.028s/prim2130853,660.055s/prim5372283.
O terceiro foi inspecionado: permanecem faixas brancas horizontais, cenário
deformado e pequenos grupos de triângulos. As capturas entre execuções têm
contagens de primitivas diferentes; não tratá-las como benchmark de FPS ou
comparação de frames idênticos. O casoABC->BCD acima é a evidência alinhada.

![Cena após correção da fila, ainda defeituosa](<scratch-dir>/mc3-adc-20260913/run/captures/present_adc_queue_20260913_0446_3.png)

Nenhum erro de função não implementada foi observado nos logs íntegros.
Accessor trace14 registros, maior chamada4096; STQ24 registros, maior4194304;
entry trace0 registros íntegros continua sendo ausência de observação.

### Próxima investigação e reversão

Manter a correção demonstrada. O próximo limite é a formação/rejeição dos
triângulos que ainda escrevem branco, começando por prim2225038 e2225467:
capturar seus packets/flags e estado de profundidade antes da rasterização,
separando coordenadas recebidas da montagem da fila agora validada. `writePixel`
atual não faz teste Z; isso é uma lacuna de implementação, mas este teste não
mediu a profundidade necessária para atribuir a faixa a ela. Não descartar
Q negativo arbitrariamente nem transformar essa hipótese em conclusão.

Fontes e executável corrigidos ficam neste checkpoint; o executável original E
não foi substituído. Para regressão comparativa usar o runner anterior em
`mc3-copy-source-20260913/bin`. `baseline/verified.csv`, `runtime-delta.patch` e
`closing/COMPLETE.json` guardam fontes anteriores, delta e fechamento. Não usar
reset/checkout amplo, pois havia alterações locais antes desta etapa.
