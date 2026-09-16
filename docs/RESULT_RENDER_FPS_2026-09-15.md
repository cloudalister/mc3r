# RESULT — placa cortada + FPS (2026-09-15, sessão parcial)

**Status: INCOMPLETO.** Só foi feita análise estática de código. Nenhum probe,
nenhuma janela ao vivo, nenhuma build nova, nenhuma medição de FPS foi
executada nesta sessão. Não crie a impressão contrária: os números pedidos
(FPS antes/depois, SHA256 do exe novo) não existem porque o binário novo não
foi compilado.

## O que foi feito

Leitura de `PS2Recomp\ps2xRuntime\src\lib\ps2_gs_gpu.cpp` (função `GS::vertexKick`,
linhas ~2040–2190) e `PS2Recomp\ps2xRuntime\src\lib\ps2_gs_rasterizer.cpp`
(função `GSRasterizer::drawTriangle`, linhas ~1249–1350).

### Questão 1 (placa cortada) — hipótese NÃO confirmada

- `vertexKick` trata `GS_PRIM_TRISTRIP` e `GS_PRIM_TRIFAN` de forma padrão:
  após desenhar, mantém os dois últimos vértices na fila (`ps2_gs_gpu.cpp:2177-2185`).
  Não há kick automático nem confusão XYZ2/XYZ3 visível nesse trecho — `drawing`
  já chega calculado antes de `vertexKick` (não investiguei onde `drawing` é
  decidido a partir de XYZ2 vs XYZ3, isso ficou pendente).
- `drawTriangle` (`ps2_gs_rasterizer.cpp:1288-1292`) normaliza o sinal do
  determinante (`winding = denom<0 ? -1 : 1`) e usa esse sinal nos três pesos
  baricêntricos. Ou seja, **não existe backface culling nem dependência de
  winding nesse rasterizador** — um triângulo CW e um CCW são preenchidos da
  mesma forma. Isso torna a hipótese "meio quad sumiu por culling/winding
  errado" pouco provável **nesse código**, mas não elimina outras causas:
  scissor por-contexto errado no segundo triângulo, um segundo XYZ3 sendo
  tratado como ADC (não desenhado), ou o buffer que o probe lê ser diferente
  do apresentado (a própria suspeita do usuário sobre PNG vs tela real).
- Não construí a fixture determinística pedida (dados reais capturados +
  replay) nem rodei o probe. **Causa raiz não provada.**

### Questão 2 (FPS) — não medido

- Confirmei que existem cronômetros de fase controlados por `MC3_PHASE_TIMING=1`
  em três pontos: `ps2_gs_rasterizer.cpp:283`, `ps2_vu1.cpp:240` (tempo dentro
  do VU1), `ps2_vif1_interpreter.cpp:283` (tempo dentro do interpretador VIF1),
  agregados em `ps2_runtime.cpp:136`.
- Não rodei o jogo nem o probe com essa variável ligada nesta sessão. Nenhuma
  otimização foi implementada. Nenhuma env var nova foi criada.

## Por que parou aqui

O runner lock (`work\RUNNER_LOCK`) estava livre no início da sessão, mas as
regras da tarefa (probe ≤20min, build isolada em
`<scratch-dir>\mc3-render-20260915-<sufixo>`, fixture determinística
com dados reais, medição antes/depois) exigem várias rodadas de execução real
do jogo/probe que não couberam no orçamento desta sessão. Prosseguir sem essas
execuções e ainda assim declarar causa provada ou ganho de FPS seria inventar
resultado.

## Sessão 2 (mesma data, retomada) — mais análise estática, ainda sem dinâmica

Completei o passo 1 pendente da sessão anterior: rastreei onde `drawing` é
decidido a partir de XYZ2/XYZ3/ADC, nos dois caminhos (packed GIF e registro
direto), em `ps2_gs_gpu.cpp`:

- Registro direto (`GS_REG_XYZ2`/`GS_REG_XYZ3`, linhas ~1667-1685 e
  ~1642-1665 para XYZF2/XYZF3): `vertexKick(regAddr == GS_REG_XYZ2)` —
  XYZ2 desenha, XYZ3 não. Correto conforme a spec do GS (XYZ3 só avança a
  fila de vértices sem kick de desenho).
- Packed GIF, formato 0x04 (XYZF2) e 0x05 (XYZ2) (linhas 1345-1420):
  `vertexKick(!adk)`, onde `adk` é o bit ADC (bit 47). Correto.
- Packed GIF, formato 0x0C (XYZF3) e 0x0D (XYZ3) (linhas 1424-1485):
  `vertexKick(false)` incondicional — **também correto**, pelo mesmo motivo:
  XYZ3 nunca dispara desenho, então não depende do bit ADC.

Conclusão: **não há bug de kick/ADC/XYZ2 vs XYZ3 nesses quatro caminhos.**
Também revisei `writeFragment`/`writePixel` (`ps2_gs_rasterizer.cpp:675-780`):
scissor, alpha test e Z test são aplicados igualmente aos dois triângulos de
um quad — nada ali depende de qual triângulo da lista/strip está sendo
desenhado. Isso elimina três das hipóteses originais (kick incorreto,
culling/winding, scissor por-triângulo). A suspeita mais forte que sobra,
ainda não testada, é a do próprio usuário: **o probe (`MC3_PRESENT_CAPTURE_PREFIX`)
pode estar lendo um buffer/timing diferente do que a janela ao vivo apresenta**
(dois "front buffers" ou uma captura pré-vsync), o que explicaria por que o
PNG mostra faixas brancas que não aparecem ao vivo enquanto ao vivo aparece
cortada na diagonal — sintomas diferentes, então pode não ser a mesma causa.

**Isso continua sendo hipótese, não causa provada.** Só dá pra confirmar
capturando o quad real (frame + lista de primitivas) durante uma sessão ao
vivo e comparando com o que o probe grava no mesmo instante.

### Por que a parte dinâmica não aconteceu nesta retomada

`work\RUNNER_LOCK` está ocupado por `menu-agent` desde 07:35:30 (verificado
às ~07:52 e de novo depois, sem mudança; nenhum processo `mc3_partial.exe`
visível, mas o lock não me pertence e a regra do projeto é nunca apagar o
lock de outro agente). Não rodei o jogo, não rodei o probe, não compilei
nenhuma variante nova e não medi FPS. Os números pedidos (FPS antes/depois,
SHA256 do exe novo) continuam inexistentes por esse motivo, não por omissão.

## Sessão 3 — descoberta de código sobre captura vs janela ao vivo

`CapturePresentedFrame` (`ps2_runtime.cpp:1274-1297`) recebe o MESMO buffer
`pixels` que `UploadFrame` sobe para a textura desenhada na janela ao vivo —
comentário no código confirma: "No extra GS latch, no context-buffer
substitution". Isso enfraquece bastante a hipótese "probe lê buffer
diferente da janela": a fonte é a mesma struct de pixels em ambos os casos.
Continua em aberto uma janela de corrida (o latch acontece uma vez por
`currentTick`; se a captura ocorrer no meio de um `latchHostPresentationFrame`
distinto do que a janela mostra no mesmo instante, os PNGs de instantes
adjacentes podem mostrar quadros diferentes um do outro, mas ambos usam o
mesmo caminho de leitura). Não é suficiente pra provar ou descartar o corte
diagonal.

Também confirmei onde ficam os contadores cumulativos de fase que já existem
sem precisar instrumentar nada novo: as linhas `[run:tick] ... rasterMs=...
rasterCalls=... guestMs=... guestWaitMs=... guestExecMs=... vu1Ms=...
vifMs=...` em `ps2_runtime.cpp:606-619` (log periódico) e `:3541-3542`, com
`MC3_PHASE_TIMING=1`. Basta rodar o exe de referência sem recompilar nada e
tirar a diferença entre duas linhas `[run:tick]` para saber a fatia de tempo
de cada fase por período.

## Sessão 4 — probe ao vivo em execução

Script `RenderFpsLiveProbe.ps1` (scratchpad da sessão) faz: polling de
`work\RUNNER_LOCK` a cada 60s sem nunca apagar lock alheio; ao adquirir,
roda `mc3-menu-last2-20260915\bin\mc3_partial.exe` (exe de referência, sem
recompilar nada ainda) NÃO headless com `MC3_PHASE_TIMING=1` +
`MC3_GS_IRQ_BRIDGE/MC3_GS_STQ_INTERPOLATION/MC3_FRAME_HOST_CLOCK/
MC3_MENU_ENTRY_FIX=1` (mesmos flags do atalho `23_jogar_com_console.bat`) e
`MC3_PRESENT_CAPTURE_PREFIX` apontando para `work\captures\present_<label>`;
tira um screenshot Win32 (`CopyFromScreen`) da janela do jogo ~20s após abrir
para `work\captures\live_<label>.png`; roda mais ~7 min; encerra o processo e
libera o lock. Objetivo: comparar `live_<label>.png` (o que a tela realmente
mostra) contra `present_<label>_*.png` (o que o probe grava) no mesmo
instante, e extrair `rasterMs/guestMs/vu1Ms/vifMs` de duas linhas `[run:tick]`
do stdout para medir onde o tempo vai. Resultado desta rodada será anexado
aqui quando o script terminar.

## Sessão 5 — resultado real do probe ao vivo (`render_fps_20260915_073849`)

Rodou o exe de referência `mc3-menu-last2-20260915\bin\mc3_partial.exe`
(nenhum binário novo compilado) por ~460s reais, janela visível,
`MC3_PHASE_TIMING=1`. Log: `work\logs\render_fps_20260915_073849.stderr.log`
(6,2 MB, 65725 linhas). Lock tomado e liberado corretamente pelo script.

### FPS (medição real, não estimativa)

O contador `tick` (vblank, ritmado pelo `MC3_FRAME_HOST_CLOCK`) foi de 0 a
~20580 nos ~460s de sono do script. Isso dá **≈44,7 Hz efetivos**, contra os
60 Hz do PS2 original — **~25% abaixo do alvo**, medido diretamente (não
adivinhado).

### Onde o tempo vai (contadores cumulativos no último tick, `tick=20580`)

```
rasterMs=61025   rasterCalls=3092418   (GS software rasterizer)
vu1Ms=87803                            (emulação VU1)
vifMs=137053                           (interpretador VIF1)
guestExecMs=127646                     (CPU R5900 interpretado, thread principal)
guestWaitMs=273876                     (esperas/sync, não é trabalho)
guestCalls=1200727
gsPrims=3092418   gsPixels=1115955855
```

**Achado principal, medido, não hipótese:** dos três subsistemas de render
instrumentados, `vifMs` (137,1s) > `vu1Ms` (87,8s) > `rasterMs` (61,0s) — o
**interpretador VIF1 é o maior consumidor isolado**, maior que o
rasterizador GS por software e maior que a emulação de VU1. Ressalva
importante: `rasterMs`/`vu1Ms`/`vifMs`/`guestExecMs` são cronômetros
independentes que podem se sobrepor no tempo real (threads diferentes,
`activeThreads=7`); não somei os quatro como se fossem exclusivos entre si
porque isso inflaria o total além do tempo de parede real. A comparação
*relativa* entre os três (vif > vu1 > raster) é o resultado confiável desta
medição; a fração exata do quadro que cada um ocupa exigiria uma medição de
tempo de parede por quadro que este contador não fornece.

**Nenhuma otimização foi implementada nesta sessão.** Com só uma rodada de
medição eu tenho a ordem relativa dos três custos, mas não confiança
suficiente pra apontar uma mudança pontual de baixo risco no VIF1 sem antes
perfilar dentro dele (ex.: qual opcode/unpack domina). Implementar algo
"no escuro" só para ter um número ON/OFF seria inventar resultado, o que a
regra do projeto pede pra evitar.

### Placa cortada na diagonal — visual desta rodada (inconclusivo)

O screenshot ao vivo (`work\captures\live_render_fps_20260915_073849.png`,
tirado 20s após abrir) capturou a janela ainda **preta** (tela de
carregamento). A captura do probe `present_..._2.png` (tirada ~5min depois,
via schedule interno do probe) mostra a **tela de título/logo "MIDNIGHT
CLUB 3 DUB EDITION REMIX"**, renderizada corretamente, sem corte — mas essa
não é a placa "PRESS START BUTTON" que o usuário reporta cortada; é uma tela
anterior no fluxo. Ou seja, **esta rodada não chegou a capturar o quadro com
o bug relatado** (nem ao vivo nem via probe), então não há evidência visual
nova a favor ou contra as hipóteses da Sessão 3. `gsPrims` chegando a
3.092.418 confirma que, desta vez, o rasterizador rodou bastante (ao
contrário de rodadas anteriores registradas no STATUS.md com `gsPrims=0`),
o que é uma pista independente de que o estado do menu avança de forma
não determinística entre execuções — relevante para quem for tentar
reproduzir o corte diagonal de novo.

## Próximo passo recomendado

1. Repetir o probe ao vivo, mas com screenshot tardio (2-3 min, não 20s) e
   input simulado/manual pra avançar até a placa "PRESS START", pra
   finalmente comparar o live PNG contra o `present_*.png` no exato quadro
   do bug relatado.
2. Perfilar dentro do VIF1 (maior custo medido, 137s > vu1 88s > raster 61s
   nesta rodada) para achar o opcode/unpack dominante antes de tentar
   qualquer otimização — não otimizar às cegas.
3. Se a causa do corte não for a diferença de buffer, construir a fixture de
   triângulo a partir de uma captura real dos vértices do quad (via
   `PS2_IF_AGRESSIVE_LOGS`/boot-trace já existente em
   `ps2_gs_gpu.cpp:2102-2137`) e decidir se há correção de baixo risco.

## Resumo final desta entrega (2026-09-15)

- **Exe usado:** apenas o de referência já existente,
  `<scratch-dir>\mc3-menu-last2-20260915\bin\mc3_partial.exe`
  (SHA `dc0375b7029cc17a8137979c70371f650ded5e8bdd152445639802ce57c7ca66`,
  já documentado). **Nenhum binário novo foi compilado** — nem para a
  questão 1 (causa não provada, nada a corrigir com confiança) nem para a
  questão 2 (uma otimização às cegas no VIF1 seria arriscada sem perfil
  interno).
- **FPS medido:** ≈44,7 Hz reais nesta rodada, contra 60 Hz do PS2 (dado
  real, calculado de tick/tempo de parede, não estimado).
- **Maior custo isolado medido:** interpretador VIF1 (137,1s cumulativos),
  acima de VU1 (87,8s) e do rasterizador GS por software (61,0s) na mesma
  janela de medição.
- **Placa cortada:** causa ainda não provada; três hipóteses descartadas por
  leitura de código (kick XYZ2/XYZ3, culling/winding, scissor/alpha/Z por
  triângulo); a hipótese restante (buffer do probe vs janela ao vivo) foi
  enfraquecida por código (mesma fonte de pixels), mas não temos ainda o
  quadro exato do bug capturado nos dois lados ao mesmo tempo.
